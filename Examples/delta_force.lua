--- @class render
--- @field render_aligned_text fun(font: any, text: string, x: number, y: number, r: number, g: number, b: number, a: number, outline_thickness: number, o_r: number, o_g: number, o_b: number, o_a: number): any
render = render or {}

-- Constants
local PROCESS_NAME = "DeltaForceClient-Win64-Shipping.exe"
local DEBUG = false
local BASE_INFO_OFFSET = 100
local PERCEPTION_HANDSHAKE = "WzQjY7hVKtGc"
local PRE_INIT_DELAY = 3000
local PACKET_SEND_INTERVAL = 50

-- Memory offsets
local OFFSETS = {
    GWORLD = 0x10417B58, -- => Base
    GameState = 0x0158, -- => Base => UWorld
    PlayerArray = 0x3A0, -- => UWorld => AGameStateBase
    PlayerArraySize = 0x3A0 + 8, -- => UWorld => AGameStateBase
    bDead = 0x04C4, -- => AGameStateBase => APlayerState : AGPPlayerState
    bDeadBox = 0x0948, -- => AGameStateBase => APlayerState : AGPPlayerState
    ExitState = 0xd30, -- => Escaped = 3, InEscaping = 5, WaitingToEscape = 2. AGameStateBase => APlayerState : ADFMPlayerState
    DeathWaitRescueTime = 0x4cc, -- => APlayerState : AGPPlayerState
    TeamId = 0x65c, -- => AGameStateBase => APlayerState : AGPPlayerState
    PawnPrivate = 0x0408, -- => AGameStateBase => APlayerState
    Controller = 0x03B8, -- => AGameStateBase => APlayerState => APawn
    -- Mesh = 0x03E8, -- => AGameStateBase => APlayerState => APawn : ACHARACTER
    ComponentToWorld = 0x220, -- => AGameStateBase => APlayerState => APawn : ACHARACTER => USkeletalMeshComponent : USceneComponent (FTransform)
    PlayerName = 0x0488, -- => AGameStateBase => APlayerState
    MapConfig = 0x618, -- => AGameStateBase : ADFMGameState
    LevelName = 0x30, -- => AGameStateBase : ADFMGameState + FMapConfig
    AActor__USceneComponent = 0x0190 -- => AActor
}

-- State management
local AppState = {
    UNLOADED = "UNLOADED",
    AGREEMENT = "AGREEMENT", 
    CONNECTING = "CONNECTING",
    PRE_INITIALIZE = "PRE-INITIALIZE",
    INITIALIZED = "INITIALIZED",
    FAILED = "FAILED"
}

local ConnectionState = {
    AWAITING_LOCAL = "AWAITING_LOCAL_SERVER_ANSWER",
    AWAITING_CLIENT_DECISION = "AWAITING_CLIENT_DECISION",
    ALLOWED_CLOUD = "ALLOWED_CLOUD_SERVER_CONNECTION",
    AWAITING_CLOUD = "AWAITING_CLOUD_SERVER_ANSWER",
    CONNECTED = "CONNECTED",
    FAILED = "FAILED_TO_REACH_ANY_SERVER"
}

-- Global variables
local currentState = AppState.CONNECTING
local connectionState = nil
local lastSentPacketTime = winapi.get_tickcount64()
local preInitDelayStart = nil
local pingRequestSentTime = nil
local lastKnownMap = nil
local isConnected = false
local host = "http://localhost:9999/"
local username = string.lower(engine.get_username())
local baseModule, baseModuleSize = proc.get_base_module()
local font = render.create_font("Verdana", 15, 700)

-- Global game state variables
local CachedLocalPlayerTeamID = nil

-- Initialize process attachment
if not proc.attach_by_name(PROCESS_NAME) then
    return engine.log("Failed to attach to Delta Force!", 255, 50, 50, 255)
end

-- Utility functions
local function getSafeString(input)
    -- return "NaN"
    if input == nil or input == "" then return "NaN" end

    if not input:match("^[a-zA-Z0-9А-Яа-яЁё]+$") then
        return "NaN"
    end

    return input
end

local function readFString(address)
    local data = proc.read_int64(address) or 0x0
    local count = proc.read_int32(address + 0x8) or 0x0
    local max = proc.read_int32(address + 0xC) or 0x0

    if data == 0 or data < 0 or count <= 0 or count > 32 or max <= 0 or max > 32 then
        return nil
    end
    
    return proc.read_wide_string(data, count)
end

local function renderAlignedText(font, text, x, y, r, g, b, a, outline_thickness, o_r, o_g, o_b, o_a)
    local mx, my = render.measure_text(font, text)
    return render.draw_text(font, text, x - (mx / 2), y - (my / 2), r, g, b, a, outline_thickness, o_r, o_g, o_b, o_a)
end
render.render_aligned_text = renderAlignedText

local function readFTransform(address)
    local rotation = vec4.read_float(address) or vec4(0,0,0,0)
    local translation = vec3.read_float(address + 0x10) or vec3(0,0,0)
    local scale = vec3.read_float(address + 0x20) or vec3(0,0,0)
    
    return {
        rot = rotation,
        translation = translation,
        scale = scale
    }
end

local function atan2(y, x)
    if x > 0 then
        return math.atan(y / x)
    elseif x < 0 then
        return math.atan(y / x) + (y >= 0 and math.pi or -math.pi)
    elseif x == 0 then
        if y > 0 then return math.pi / 2
        elseif y < 0 then return -math.pi / 2
        else return 0 end
    end
end

local function getYawFromQuat(x, y, z, w)
    local siny_cosp = 2.0 * (w * z + x * y)
    local cosy_cosp = 1.0 - 2.0 * (y * y + z * z)
    return atan2(siny_cosp, cosy_cosp) * (180.0 / math.pi)
end

-- Networking functions
local function invokeUpdate(updateType, data)
    local jsonData = {
        update_type = updateType,
        PERCEPTION_HANDSHAKE = PERCEPTION_HANDSHAKE
    }
    
    if updateType == "SWITCH_MAP" then
        jsonData.new_map = data
        CachedLocalPlayerTeamID = nil
    elseif updateType == "GAME_DATA" then
        jsonData.players = data
        jsonData.items = {}
    end

    local endpoint = string.format("api/df/game-data/%s", username)
    local headers = "User-Agent: Delta Force Radar ROOT/1.0\r\nContent-Type: application/json"
    net.send_request(host .. endpoint, headers, json.stringify(jsonData))
end

local function getPlayerArray()
    local gworld = proc.read_int64(baseModule + OFFSETS.GWORLD) or 0x0
    local gameState = proc.read_int64(gworld + OFFSETS.GameState) or 0x0
    local playerArray = proc.read_int64(gameState + OFFSETS.PlayerArray) or 0x0
    local playerArrayCount = proc.read_int16(gameState + OFFSETS.PlayerArraySize) or 0x0

    -- engine.log(string.format("0x%X | 0x%X | 0x%X | 0x%X", gworld, gameState, playerArray, playerArrayCount), 255, 255, 255, 255)

    -- -- Сохраняем начальный адрес при первом вызове
    -- if initialPlayerArray == nil then
    --     initialPlayerArray = playerArray
    -- elseif playerArray ~= initialPlayerArray and xorKey == nil then
    --     -- Вычисляем XOR-ключ
    --     xorKey = playerArray ~ initialPlayerArray
    --     engine.log(string.format("XOR Key: 0x%X", xorKey), 255, 255, 255, 255)
    -- end

    -- -- Расшифровываем адрес, если XOR-ключ известен
    -- local decryptedPlayerArray = playerArray
    -- if xorKey ~= nil then
    --     decryptedPlayerArray = playerArray ~ xorKey
    --     engine.log(string.format("Decrypted PlayerArray: 0x%X | XOR: 0x%X", decryptedPlayerArray, xorKey), 255, 255, 255, 255)
    -- end

    return {
        Array = playerArray,
        Count = playerArrayCount
    }
end

-- -- Memory reading functions
-- local initialPlayerArray = nil
-- local xorKey = nil

-- local function getPlayerArray()
--     local gworld = proc.read_int64(baseModule + OFFSETS.GWORLD) or 0x0
--     local gameState = proc.read_int64(gworld + OFFSETS.GameState) or 0x0
--     local playerArray = proc.read_int64(gameState + OFFSETS.PlayerArray) or 0x0
--     local playerArrayCount = proc.read_int16(gameState + OFFSETS.PlayerArraySize) or 0x0

--     engine.log(string.format("0x%X | 0x%X | 0x%X | 0x%X", gworld, gameState, playerArray, playerArrayCount), 255, 255, 255, 255)

--     -- Сохраняем начальный адрес при первом вызове
--     if initialPlayerArray == nil then
--         initialPlayerArray = playerArray
--     elseif playerArray ~= initialPlayerArray and xorKey == nil then
--         -- Вычисляем XOR-ключ
--         xorKey = playerArray ~ initialPlayerArray
--         engine.log(string.format("XOR Key: 0x%X", xorKey), 255, 255, 255, 255)
--     end

--     -- Расшифровываем адрес, если XOR-ключ известен
--     local decryptedPlayerArray = playerArray
--     if xorKey ~= nil then
--         decryptedPlayerArray = playerArray ~ xorKey
--         engine.log(string.format("Decrypted PlayerArray: 0x%X | XOR: 0x%X", decryptedPlayerArray, xorKey), 255, 255, 255, 255)
--     end

--     return {
--         Array = decryptedPlayerArray,
--         Count = playerArrayCount
--     }
-- end

local function getMapName()
    local gworld = proc.read_int64(baseModule + OFFSETS.GWORLD) or 0x0
    local gameState = proc.read_int64(gworld + OFFSETS.GameState) or 0x0
    local levelName = string.match(readFString(gameState + OFFSETS.MapConfig + OFFSETS.LevelName) or "Lobby", "^[^_]+")

    -- Handle map change
    if levelName ~= lastKnownMap then
        if DEBUG then
            engine.log(string.format("Map Change: %s => %s", lastKnownMap, levelName), 255, 255, 255, 255)
        end
        
        local mapName = levelName
        if mapName == "Lobby" then mapName = "lobby" end
        if mapName == "Dam" then mapName = "zerodam" end
        if mapName == "Forrest" then mapName = "layaligrove" end
        if mapName == "SpaceCenter" then mapName = "spacecity" end
        
        invokeUpdate("SWITCH_MAP", mapName)
        lastKnownMap = levelName
    end

    return levelName
end

-- Player state class
local PlayerState = {}
PlayerState.__index = PlayerState

function PlayerState:new(pos, team, isSelf, status, name, yaw)
    local self = setmetatable({}, PlayerState)
    self.pos = pos or {x = -480000, y = -480000, z = -480000}
    self.team = team or "enemy"
    self.is_self = isSelf or false
    self.status = status or "deadboxed"
    self.name = name or "NO_NAME"
    self.yaw = yaw
    return self
end

-- Connection management
local function determineServer()
    local currentTime = winapi.get_tickcount64()
    
    if connectionState == ConnectionState.AWAITING_CLOUD then
        if currentTime - pingRequestSentTime >= 2000 then
            if DEBUG then
                engine.log("Cloud server connection failed!", 255, 255, 255, 255)
            end

            connectionState = ConnectionState.FAILED
            currentState = AppState.FAILED
        end
    elseif connectionState == ConnectionState.ALLOWED_CLOUD then
        if DEBUG then
            engine.log("Connecting to cloud server...", 255, 255, 255, 255)
        end
        
        host = "https://riuji.org/"
        invokeUpdate("PING")
        pingRequestSentTime = currentTime
        connectionState = ConnectionState.AWAITING_CLOUD
    elseif connectionState == ConnectionState.AWAITING_LOCAL then
        if currentTime - pingRequestSentTime >= 2000 then

            if DEBUG then
                engine.log("Local server failed! Requesting cloud permission...", 255, 255, 255, 255)
            end

            connectionState = ConnectionState.AWAITING_CLIENT_DECISION
            currentState = AppState.AGREEMENT
        end
    elseif connectionState == nil then
        if DEBUG then
            engine.log("Trying local server...", 255, 255, 255, 255)
        end

        invokeUpdate("PING")
        pingRequestSentTime = currentTime
        connectionState = ConnectionState.AWAITING_LOCAL
    end
end

-- Main update function
local function update()
    local mapName = getMapName()
    local players = getPlayerArray()
    local playerStateArray = {}

    if DEBUG then
        render.draw_text(font, string.format('Map: %s', tostring(mapName)), 40, BASE_INFO_OFFSET, 255, 255, 255, 255, 1, 0, 0, 0, 255)
    end

    -- Process all players
    for i = 0, players.Count - 1 do
        local playerState = proc.read_int64(players.Array + (0x8 * i)) or 0x0
        local playerName = readFString(playerState + OFFSETS.PlayerName)
        local pawn = proc.read_int64(playerState + OFFSETS.PawnPrivate) or 0x0
        local controller = proc.read_int64(pawn + OFFSETS.Controller) or 0x0
        local isDead = proc.read_int8(playerState + OFFSETS.bDead) or 0x0
        local isDeadBox = proc.read_int8(playerState + OFFSETS.bDeadBox) or 0x0
        local teamId = proc.read_int32(playerState + OFFSETS.TeamId) or nil
        local ExitState = proc.read_int8(playerState + OFFSETS.ExitState) or 1
        -- local DeathWaitRescueTime = proc.read_float(playerState + OFFSETS.DeathWaitRescueTime)
        
        local isSelf = controller ~= 0x0
        if isSelf then CachedLocalPlayerTeamID = teamId end

        local team = (CachedLocalPlayerTeamID == teamId and teamId ~= nil) and "ally" or "enemy"
        -- local status = isDeadBox == 1 and "deadboxed" or (isDead == 1 and "injured" or "alive")
        local status = "alive"

        if ExitState == 3 then
            status = "escaped"
        elseif isDeadBox == 1 then -- Impossible to revive
            status = "deadboxed"
        elseif isDead == 1 then -- knockout
            status = "injured"
        end
        
        local sceneComponent = proc.read_int64(pawn + OFFSETS.AActor__USceneComponent) or 0x0
        local transform = readFTransform(sceneComponent + OFFSETS.ComponentToWorld)
        local pos = transform.translation
        local quat = transform.rot
        local yaw = getYawFromQuat(quat.x, quat.y, quat.z, quat.w)
        
        if playerName and playerName ~= "DefaulName" then
            local player = PlayerState:new(
                {x = pos.x, y = pos.y, z = pos.z},
                team,
                isSelf,
                status,
                getSafeString(playerName),
                yaw
            )
            table.insert(playerStateArray, player)
        end
        
        if DEBUG then
            if isSelf then
                render.draw_text(font, string.format('%d - %s | rot: %.1f | pos: %f %f %f', i, getSafeString(playerName), yaw, pos.x, pos.y, pos.z), 40, BASE_INFO_OFFSET + 20 + (20 * i), 255, 214, 161, 255, 1, 0, 0, 0, 255)
            else
                render.draw_text(font, string.format('%d - %s | rot: %.1f | pos: %f %f %f', i, getSafeString(playerName), yaw, pos.x, pos.y, pos.z), 40, BASE_INFO_OFFSET + 20 + (20 * i), 255, 255, 255, 255, 1, 0, 0, 0, 255)
            end
        end
    end

    -- Send game data if not in lobby
    if lastKnownMap ~= "Lobby" then
        if winapi.get_tickcount64() - lastSentPacketTime >= PACKET_SEND_INTERVAL then
            lastSentPacketTime = winapi.get_tickcount64()
            invokeUpdate("GAME_DATA", playerStateArray)
        end
    end
end

-- UI drawing function
local function drawUI()
    local w, h = render.get_viewport_size()
    local mx, my = input.get_mouse_position()
    local leftClick = input.is_key_pressed(0x01)

    if currentState == AppState.INITIALIZED then return end

    -- Draw background
    local bgSize = vec2(math.floor(w * 0.15), math.floor(h * 0.15))
    local bgX, bgY = (w / 2) - (bgSize.x / 2), (h / 2) - (bgSize.y / 2)
    render.draw_rectangle(bgX, bgY, bgSize.x, bgSize.y, 30, 30, 30, 255, 0, true)

    local frontSize = vec2(math.floor(w * 0.1425), math.floor(h * 0.135))
    local frontX, frontY = (w / 2) - (frontSize.x / 2), (h / 2) - (frontSize.y / 2)
    render.draw_rectangle(frontX, frontY, frontSize.x, frontSize.y, 20, 20, 20, 255, 0, true)

    if currentState == AppState.AGREEMENT then
        render.render_aligned_text(font, "Local server not found.", w / 2, h / 2 - frontSize.y * 0.175, 255, 255, 255, 255, 1, 0, 0, 0, 255)
        render.render_aligned_text(font, "Connect to cloud server?", w / 2, h / 2 - frontSize.y * 0.1, 255, 255, 255, 255, 1, 0, 0, 0, 255)
        
        local btnSize = vec2(frontSize.x * 0.15, frontSize.y * 0.15)
        local btnYesPos = vec2((w / 2) - btnSize.x - (btnSize.x * 0.1), (h / 2) - (btnSize.y / 2) + frontSize.y * 0.1)
        local btnNoPos = vec2((w / 2) + (btnSize.x * 0.1), (h / 2) - (btnSize.y / 2) + frontSize.y * 0.1)

        local isInYes = mx >= btnYesPos.x and mx <= btnYesPos.x + btnSize.x and my >= btnYesPos.y and my <= btnYesPos.y + btnSize.y
        local isInNo = mx >= btnNoPos.x and mx <= btnNoPos.x + btnSize.x and my >= btnNoPos.y and my <= btnNoPos.y + btnSize.y

        if leftClick then
            if isInNo then
                currentState = AppState.UNLOADED
            elseif isInYes then
                currentState = AppState.CONNECTING
                connectionState = ConnectionState.ALLOWED_CLOUD
            end
        end

        -- Draw buttons
        local yesColor = isInYes and 35 or 30
        local noColor = isInNo and 35 or 30
        render.draw_rectangle(btnYesPos.x, btnYesPos.y, btnSize.x, btnSize.y, yesColor, yesColor, yesColor, 255, 0, true)
        render.draw_rectangle(btnNoPos.x, btnNoPos.y, btnSize.x, btnSize.y, noColor, noColor, noColor, 255, 0, true)

        render.render_aligned_text(font, "YES", btnYesPos.x + btnSize.x / 2, btnYesPos.y + btnSize.y / 2, 255, 255, 255, 255, 1, 0, 0, 0, 255)
        render.render_aligned_text(font, "NO", btnNoPos.x + btnSize.x / 2, btnNoPos.y + btnSize.y / 2, 255, 255, 255, 255, 1, 0, 0, 0, 255)

    elseif currentState == AppState.CONNECTING then
        render.render_aligned_text(font, "Connecting...", w / 2, h / 2 - frontSize.y * 0.15, 255, 255, 255, 255, 1, 0, 0, 0, 255)
    
    elseif currentState == AppState.FAILED then
        render.render_aligned_text(font, "No server available.", w / 2, h / 2 - frontSize.y * 0.15, 255, 255, 255, 255, 1, 0, 0, 0, 255)
    
    elseif currentState == AppState.PRE_INITIALIZE then
        if winapi.get_tickcount64() - preInitDelayStart >= PRE_INIT_DELAY then 
            currentState = AppState.INITIALIZED 
        end
        
        local remainingTime = math.floor((PRE_INIT_DELAY / 1000) + 1 - (winapi.get_tickcount64() - preInitDelayStart) / 1000)
        render.render_aligned_text(font, "Link copied to clipboard!", w / 2, h / 2 - frontSize.y * 0.175, 255, 255, 255, 255, 1, 0, 0, 0, 255)
        render.render_aligned_text(font, string.format("Closing in %d seconds...", remainingTime), w / 2, h / 2 - frontSize.y * 0.1, 255, 255, 255, 255, 1, 0, 0, 0, 255)
    end
end

-- Main core function
local function core()
    if not isConnected and currentState ~= AppState.FAILED then
        determineServer()
    end
    
    if currentState ~= AppState.INITIALIZED then
        drawUI()
        return
    end
    
    update()
end

-- Network callback handler
local function handlePong(responseData, url)
    if isConnected then return end
    
    local serverResponse = m.read_string(responseData, 0)
    if serverResponse ~= "PONG" then return end

    isConnected = true
    currentState = AppState.PRE_INITIALIZE
    preInitDelayStart = winapi.get_tickcount64()
    
    local clipboardUrl = host .. string.format("df/%s", username)
    input.set_clipboard(clipboardUrl)
    
    if connectionState == ConnectionState.AWAITING_CLOUD then
        host = "https://riuji.org/"
    end
end

-- -- Register callbacks
engine.register_on_network_callback(handlePong)
engine.register_on_engine_tick(function()
    if currentState == AppState.UNLOADED then return end
    core()
end)

-- engine.register_on_engine_tick(function()
--     update()
-- end)