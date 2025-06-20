-- @SCREEN

local screenWidth, screenHeight = render.get_viewport_size();

local screenCenter = vec2(screenWidth / 2, screenHeight / 2);

-- @FONTS

local ESPFont = render.create_font("Minecraftia.ttf", 11, 400);

-- @ATTACH

local attach = proc.attach_by_name("GTA5.exe");

if (proc.is_attached()) then
    gameBaseAddress = proc.base_address();

    if (not gameBaseAddress or gameBaseAddress == 0) then
        engine.log("Failed to find base address", 255, 75, 75, 255);

        return;
    end;
else
    engine.log("Failed to find GTAV", 255, 75, 75, 255);

    return;
end;

-- @GAME

local gameOffsets = {
    world = 0x25B14B0,

    replay = 0x1FBD4F0,

    viewport = 0x201DBA0,

    localPlayer = 0x8,

    playerInfo = 0x10A8,

    playerPosition = 0x90,

    playerHealth = 0x280,

    playerMaxHealth = 0x284,

    playerArmor = 0x150C,

    playerReplay = 0x18,

    playerList = 0x100,

    viewmatrix = 0x24C,

    boneManager = 0x410,

    boneMatrix = 0x60
};

local boneData = {
    { name = "head", id = 0 },

    { name = "neck", id = 7 },

    { name = "pelvis", id = 8, offset = vec3(0, 0, -0.1) },

    { name = "leftHand", id = 5 },

    { name = "rightHand", id = 6 },

    { name = "leftFoot", id = 1, offset = vec3(0, 0, 0.1) },

    { name = "rightFoot", id = 2, offset = vec3(0, 0, 0.1) },

    { name = "leftShoulder", id = 7, offset = vec3(-0.2, 0, -0.05) },

    { name = "rightShoulder", id = 7, offset = vec3(0.175, 0, -0.05) },

    { name = "leftHip", id = 8, offset = vec3(0.15, 0, -0.2) },

    { name = "rightHip", id = 8, offset = vec3(-0.15, 0, -0.2) }
};

-- @MENU

do
    menu = { };

    menu.visualsTab = gui.get_tab("visuals");

    menu.playersPanel = menu.visualsTab:create_panel("Players", true);

    menu.playersEnabled = menu.playersPanel:add_checkbox("Enabled");

    menu.playersEnabledKeybind = menu.playersPanel:add_keybind("Enabled Keybind", 0, key_mode.always_on);

    menu.playersName = menu.playersPanel:add_checkbox("Name");

    menu.playersNameColor = menu.playersPanel:add_color_picker("Name Color", 255, 255, 255, 255);

    menu.playersBox = menu.playersPanel:add_checkbox("Box");

    menu.playersBoxColor = menu.playersPanel:add_color_picker("Box Color", 255, 255, 255, 255);

    menu.playersSkeleton = menu.playersPanel:add_checkbox("Skeleton");

    menu.playersSkeletonColor = menu.playersPanel:add_color_picker("Skeleton Color", 255, 255, 255, 255);

    menu.playersHealth = menu.playersPanel:add_checkbox("Health");

    menu.playersHealthColor = menu.playersPanel:add_color_picker("Health Color", 255, 125, 125, 255);

    menu.playersArmor = menu.playersPanel:add_checkbox("Armor");

    menu.playersArmorColor = menu.playersPanel:add_color_picker("Armor Color", 125, 125, 255, 255);

    menu.playersDistance = menu.playersPanel:add_checkbox("Distance");

    menu.aimbotTab = gui.get_tab("aimbot");

    menu.aimbotPanel = menu.aimbotTab:create_panel("Aimbot", true);

    menu.aimbotEnabled = menu.aimbotPanel:add_checkbox("Enabled");

    menu.aimbotEnabledKeybind = menu.aimbotPanel:add_keybind("Enabled Keybind", 6, key_mode.onhotkey);

    menu.aimbotDrawFOV = menu.aimbotPanel:add_checkbox("Draw FOV");

    menu.aimbotDrawFOVColor = menu.aimbotPanel:add_color_picker("Draw FOV Color", 255, 255, 255, 255);

    menu.aimbotFOV = menu.aimbotPanel:add_slider_int("FOV", 1, 90, 15);

    menu.aimbotHitbox = menu.aimbotPanel:add_single_select("Hitbox", {"Head", "Body"}, 0);

    menu.aimbotSmoothing = menu.aimbotPanel:add_slider_int("Smoothing", 0, 100, 50);

    menu.settingsTab = gui.get_tab("settings");

    menu.configPanel = menu.settingsTab:create_panel("Config", true);

    menu.configSave = menu.configPanel:add_button("Save", function()
        local configData = gui.get_state();

        fs.write_to_file("RAGE.cfg", configData);
    end);

    menu.configLoad = menu.configPanel:add_button("Load", function()
        if (fs.does_file_exist("RAGE.cfg")) then
            local configData = fs.read_from_file("RAGE.cfg");

            if (configData) then
                gui.load_state(configData);
            end;
        end;
    end);
end;

-- @MEMORY

local safeReadInt64 = function(address)
    local readValue;
    
    if (proc.is_attached() and address and address ~= 0) then
        readValue = proc.read_int64(address);
    end;

    return readValue;
end;

local safeReadInt32 = function(address)
    local readValue;
    
    if (proc.is_attached() and address and address ~= 0) then
        readValue = proc.read_int32(address);
    end;

    return readValue;
end;

local safeReadInt16 = function(address)
    local readValue;
    
    if (proc.is_attached() and address and address ~= 0) then
        readValue = proc.read_int16(address);
    end;

    return readValue;
end;

local safeReadInt8 = function(address)
    local readValue;
    
    if (proc.is_attached() and address and address ~= 0) then
        readValue = proc.read_int8(address);
    end;

    return readValue;
end;

local safeReadFloat = function(address)
    local readValue;
    
    if (proc.is_attached() and address and address ~= 0) then
        readValue = proc.read_float(address);
    end;

    return readValue;
end;

local safeReadString = function(address, size)
    local readValue;
    
    if (proc.is_attached() and address and address ~= 0 and size and size ~= 0) then
        pcall(function()
            readValue = proc.read_string(address, size);
        end);
    end;

    return readValue;
end;

local safeReadVector2 = function(address)
    local readValue;
    
    if (proc.is_attached() and address and address ~= 0) then
        readValue = vec2.read_float(address);
    end;

    return readValue;
end;

local safeReadVector3 = function(address)
    local readValue;
    
    if (proc.is_attached() and address and address ~= 0) then
        readValue = vec3.read_float(address);
    end;

    return readValue;
end;

local safeReadMatrix = function(address)
    local readValue;

    if (proc.is_attached() and address and address ~= 0) then
        readValue = mat4.read(address);
    end;

    return readValue;
end;

-- @SDK

function transformVector(vector, matrix)
    return {
        x = vector.x * matrix:get(1, 1) + vector.y * matrix:get(2, 1) + vector.z * matrix:get(3, 1) + matrix:get(4, 1),

        y = vector.x * matrix:get(1, 2) + vector.y * matrix:get(2, 2) + vector.z * matrix:get(3, 2) + matrix:get(4, 2),

        z = vector.x * matrix:get(1, 3) + vector.y * matrix:get(2, 3) + vector.z * matrix:get(3, 3) + matrix:get(4, 3),

        w = vector.x * matrix:get(1, 4) + vector.y * matrix:get(2, 4) + vector.z * matrix:get(3, 4) + matrix:get(4, 4)
    };
end;

local worldToScreen = function(world, viewmatrix)
    if (world and world ~= 0 and viewmatrix and viewmatrix ~= 0) then
        local quaternionX = ((viewmatrix:get(1, 2) * world.x) + (viewmatrix:get(2, 2) * world.y) + (viewmatrix:get(3, 2) * world.z) + viewmatrix:get(4, 2));

        local quaternionY = ((viewmatrix:get(1, 3) * world.x) + (viewmatrix:get(2, 3) * world.y) + (viewmatrix:get(3, 3) * world.z) + viewmatrix:get(4, 3));

        local quaternionW = ((viewmatrix:get(1, 4) * world.x) + (viewmatrix:get(2, 4) * world.y) + (viewmatrix:get(3, 4) * world.z) + viewmatrix:get(4, 4));

        local width = (1 / quaternionW);
        
        if (quaternionW > 0.1) then
            local vectorX = (quaternionX * width);

            local vectorY = (quaternionY * width);

            local screenX = ((screenWidth / 2) + (0.5 * vectorX * screenWidth + 0.5));

            local screenY = ((screenHeight / 2) - (0.5 * vectorY * screenHeight + 0.5));

            return vec2(screenX, screenY);
        end;
    end;

    return;
end;

local getDistance3D = function(firstVector, secondVector)
    local distanceX = (firstVector.x - secondVector.x);

    local distanceY = (firstVector.y - secondVector.y);

    local distanceZ = (firstVector.z - secondVector.z);

    return math.sqrt(distanceX * distanceX + distanceY * distanceY + distanceZ * distanceZ);
end;

local getDistance2D = function(firstVector, secondVector)
    local distanceX = (firstVector.x - secondVector.x);

    local distanceY = (firstVector.y - secondVector.y);

    return math.sqrt(distanceX * distanceX + distanceY * distanceY);
end;

local getWorld = function()
    return safeReadInt64(gameBaseAddress + gameOffsets.world);
end;

local getReplay = function()
    return safeReadInt64(gameBaseAddress + gameOffsets.replay);
end;

local getViewport = function()
    return safeReadInt64(gameBaseAddress + gameOffsets.viewport);
end;

local getViewmatrix = function(viewportAddress)
    return safeReadMatrix(viewportAddress + gameOffsets.viewmatrix);
end;

local getPlayerReplay = function(replayAddress)
    return safeReadInt64(replayAddress + gameOffsets.playerReplay);
end;

local getPlayerList = function(playerReplayAddress)
    return safeReadInt64(playerReplayAddress + gameOffsets.playerList);
end;

local getLocalPlayer = function(worldAddress)
    return safeReadInt64(worldAddress + gameOffsets.localPlayer);
end;

local getPlayerInfo = function(playerAddress)
    return safeReadInt64(playerAddress + gameOffsets.playerInfo);
end;

local getPlayerArmor = function(playerAddress)
    return safeReadFloat(playerAddress + gameOffsets.playerArmor);
end;

local getPlayerHealth = function(playerAddress)
    return safeReadFloat(playerAddress + gameOffsets.playerHealth);
end;

local getPlayerMaxHealth = function(playerAddress)
    return safeReadFloat(playerAddress + gameOffsets.playerMaxHealth);
end;

local getPlayerPosition = function(playerAddress)
    return safeReadVector3(playerAddress + gameOffsets.playerPosition);
end;

local getBonePosition = function(playerAddress, boneId, vectorOffset)
    local matrix = safeReadMatrix(playerAddress + gameOffsets.boneMatrix);

    local bone = safeReadVector3(playerAddress + (gameOffsets.boneManager + (boneId * 0x10)));

    if (vectorOffset and vectorOffset ~= 0) then
        bone = (bone + vectorOffset);
    end;

    if (bone and bone ~= 0) then
        local transform = transformVector(bone, matrix);

        if (transform and transform ~= 0) then
            return vec3(transform.x, transform.y, transform.z);
        end;
    end;

    return;
end;

-- @UPDATE

local menuCache = { };

local updateMenuRelated = function()
    menuCache.playersEnabled = menu.playersEnabled:get();

    menuCache.playersEnabledKeybind = menu.playersEnabledKeybind:is_active();

    menuCache.playersName = menu.playersName:get();

    menuCache.playersNameColorR, menuCache.playersNameColorG, menuCache.playersNameColorB, menuCache.playersNameColorA = menu.playersNameColor:get();

    menuCache.playersBox = menu.playersBox:get();

    menuCache.playersBoxColorR, menuCache.playersBoxColorG, menuCache.playersBoxColorB, menuCache.playersBoxColorA = menu.playersBoxColor:get();

    menuCache.playersSkeleton = menu.playersSkeleton:get();

    menuCache.playersSkeletonColorR, menuCache.playersSkeletonColorG, menuCache.playersSkeletonColorB, menuCache.playersSkeletonColorA = menu.playersSkeletonColor:get();

    menuCache.playersHealth = menu.playersHealth:get();

    menuCache.playersHealthColorR, menuCache.playersHealthColorG, menuCache.playersHealthColorB, menuCache.playersHealthColorA = menu.playersHealthColor:get();

    menuCache.playersArmor = menu.playersArmor:get();

    menuCache.playersArmorColorR, menuCache.playersArmorColorG, menuCache.playersArmorColorB, menuCache.playersArmorColorA = menu.playersArmorColor:get();

    menuCache.playersDistance = menu.playersDistance:get();

    menuCache.aimbotEnabled = menu.aimbotEnabled:get();

    menuCache.aimbotEnabledKeybind = menu.aimbotEnabledKeybind:is_active();

    menuCache.aimbotDrawFOV = menu.aimbotDrawFOV:get();

    menuCache.aimbotDrawFOVColorR, menuCache.aimbotDrawFOVColorG, menuCache.aimbotDrawFOVColorB, menuCache.aimbotDrawFOVColorA = menu.aimbotDrawFOVColor:get();

    menuCache.aimbotFOV = menu.aimbotFOV:get();

    menuCache.aimbotHitbox = menu.aimbotHitbox:get();

    menuCache.aimbotSmoothing = menu.aimbotSmoothing:get();

    return;
end;

local gameCache = { };

local updateGameRelated = function()
    gameCache.world = getWorld();

    if (gameCache.world == nil or gameCache.world == 0) then
        gameCache.isValid = false;

        return;
    end;

    gameCache.replay = getReplay();

    if (gameCache.replay == nil or gameCache.replay == 0) then
        gameCache.isValid = false;

        return;
    end;

    gameCache.viewport = getViewport();

    if (gameCache.viewport == nil or gameCache.viewport == 0) then
        gameCache.isValid = false;

        return;
    end;

    gameCache.viewmatrix = getViewmatrix(gameCache.viewport);

    if (gameCache.viewmatrix == nil or gameCache.viewmatrix == 0) then
        gameCache.isValid = false;

        return;
    end;

    gameCache.playerReplay = getPlayerReplay(gameCache.replay);

    if (gameCache.playerReplay == nil or gameCache.playerReplay == 0) then
        gameCache.isValid = false;

        return;
    end;

    gameCache.localPlayer = getLocalPlayer(gameCache.world);

    if (gameCache.localPlayer == nil or gameCache.localPlayer == 0) then
        gameCache.isValid = false;
        
        return;
    end;

    gameCache.localPlayerPosition = getPlayerPosition(gameCache.localPlayer);

    if (gameCache.localPlayerPosition == nil or gameCache.localPlayerPosition == 0) then
        gameCache.isValid = false;
        
        return;
    end;

    gameCache.playerList = getPlayerList(gameCache.playerReplay);

    if (gameCache.playerList == nil or gameCache.playerList == 0) then
        gameCache.isValid = false;
        
        return;
    end;

    gameCache.isValid = true;

    return;
end;

local updateEntityRelated = function()
    if (not gameCache.isValid) then
        return;
    end;

    local closestScreenDistance = 10000;

    for i = 0, 256 do
        local player = safeReadInt64(gameCache.playerList + (i * 0x10));
        
        if (not player or player == 0) then
            goto skipPlayer;
        end;

        if (player ~= gameCache.localPlayer) then
            local playerInfo = getPlayerInfo(player);

            if (playerInfo == nil or playerInfo == 0) then
                goto skipPlayer;
            end;

            local playerHealth = getPlayerHealth(player);

            if (playerHealth == nil or playerHealth == 0) then
                goto skipPlayer;
            end;

            local playerMaxHealth = getPlayerMaxHealth(player);

            if (playerMaxHealth == nil or playerMaxHealth == 0) then
                goto skipPlayer;
            end;

            local playerArmor = getPlayerArmor(player);

            if (playerArmor == nil) then
                goto skipPlayer;
            end;

            local playerPosition = getPlayerPosition(player);

            if (playerPosition == nil or playerPosition == 0) then
                goto skipPlayer;
            end;

            local playerScreenPosition = worldToScreen(playerPosition, gameCache.viewmatrix);

            if (playerScreenPosition == nil or playerScreenPosition == 0) then
                goto skipPlayer;
            end;

            local playerDistance = getDistance3D(playerPosition, gameCache.localPlayerPosition);

            if (playerDistance == nil or playerDistance >= 190) then
                goto skipPlayer;
            end;

            local playerScreenDistance = getDistance2D(playerScreenPosition, screenCenter);

            if (playerScreenDistance == nil) then
                goto skipPlayer;
            end;

            if (closestScreenDistance > playerScreenDistance and (not menuCache.aimbotEnabledKeybind or gameCache.closestPlayer == 0)) then
                gameCache.closestPlayer = player;

                closestScreenDistance = playerScreenDistance;
            end;

            local bonePositionCache = { };

            local boneScreenPositionCache = { };

            for i, bone in pairs(boneData) do
                local bonePosition = getBonePosition(player, bone.id, (bone.offset ~= nil and bone.offset or vec3(0, 0, 0)));

                if (bonePosition == nil or bonePosition == 0) then
                    goto skipPlayer;
                end;

                local boneScreenPosition = worldToScreen(bonePosition, gameCache.viewmatrix);

                if (boneScreenPosition == nil or boneScreenPosition == 0) then
                    goto skipPlayer;
                end;

                bonePositionCache[bone.name] = bonePosition;

                boneScreenPositionCache[bone.name] = boneScreenPosition;
            end;

            if (not menuCache.playersEnabled or not menuCache.playersEnabledKeybind) then
                goto skipPlayer;
            end;

            local playerFeetCenterPosition = vec3((bonePositionCache.leftFoot.x + bonePositionCache.rightFoot.x) / 2, (bonePositionCache.leftFoot.y + bonePositionCache.rightFoot.y) / 2, (bonePositionCache.leftFoot.z + bonePositionCache.rightFoot.z) / 2);

            local playerScreenTopPosition = worldToScreen(bonePositionCache.head + vec3(0, 0, 0.25), gameCache.viewmatrix);

            if (playerScreenTopPosition == nil or playerScreenTopPosition == 0) then
                goto skipPlayer;
            end;

            local playerScreenBottomPosition = worldToScreen(playerFeetCenterPosition - vec3(0, 0, 0.25), gameCache.viewmatrix);

            if (playerScreenBottomPosition == nil or playerScreenBottomPosition == 0) then
                goto skipPlayer;
            end;
            
            if (menuCache.playersName) then
                local text = ("ID: " .. tostring(i));

                if (menuCache.playersDistance) then
                    text = (text .. " [" .. tostring(math.floor(playerDistance)) .. "M]");
                end;
                
                local textWidth, textHeight = render.measure_text(ESPFont, text);

                local textX, textY = math.floor(playerScreenTopPosition.x - (textWidth / 2)), math.floor(playerScreenTopPosition.y - textHeight + 1);

                render.draw_text(ESPFont, text, textX, textY, menuCache.playersNameColorR, menuCache.playersNameColorG, menuCache.playersNameColorB, menuCache.playersNameColorA, 1, 0, 0, 0, 255);
            end;

            if (menuCache.playersBox or menuCache.playersHealth or menuCache.playersArmor) then
                local boxHeight = math.floor(math.max((playerScreenBottomPosition.y - playerScreenTopPosition.y), 6));

                local boxWidth = math.floor(boxHeight / 1.8);
                
                local boxX, boxY = math.floor(playerScreenTopPosition.x - (boxWidth / 2)), math.floor(playerScreenTopPosition.y);

                if (menuCache.playersBox) then
                    render.draw_rectangle(boxX, boxY, boxWidth, boxHeight, 0, 0, 0, 75, 1, true);
                    
                    render.draw_rectangle(boxX, boxY, boxWidth, boxHeight, 0, 0, 0, 255, 3, false);
                                                                
                    render.draw_rectangle(boxX, boxY, boxWidth, boxHeight, menuCache.playersBoxColorR, menuCache.playersBoxColorG, menuCache.playersBoxColorB, menuCache.playersBoxColorA, 1, false);
                end;

                if (menuCache.playersHealth and playerHealth > 0 and playerHealth <= playerMaxHealth) then
                    local healthBarX, healthBarY = math.floor(boxX), math.floor(boxY + boxHeight + 3);

                    local healthBarWidth, healthBarHeight = math.floor(boxWidth + 2), math.floor(4);

                    local healthBarFillWidth = math.floor(math.min(math.max(((playerHealth - 100) / (playerMaxHealth - 100)) * (healthBarWidth - 2), 0), (healthBarWidth - 2)));

                    render.draw_rectangle(healthBarX - 1, healthBarY, healthBarWidth, healthBarHeight, 0, 0, 0, 255, 0, true);

                    render.draw_rectangle(healthBarX, healthBarY + 1, healthBarFillWidth, 2, menuCache.playersHealthColorR, menuCache.playersHealthColorG, menuCache.playersHealthColorB, menuCache.playersHealthColorA, 0, true);
                end;

                if (menuCache.playersArmor and playerArmor > 0 and playerArmor <= 200) then
                    local armorBarX, armorBarY = math.floor(boxX - 1), math.floor(boxY + boxHeight + 3 + (menuCache.playersHealthToggle and 5 or 0));

                    local armorBarWidth, armorBarHeight = math.floor(boxWidth + 2), math.floor(4);
                        
                    local armorBarFillWidth = math.floor(math.min(math.max((playerArmor / 200) * (armorBarWidth - 2), 0), (armorBarWidth - 2)));

                    render.draw_rectangle(armorBarX - 1, armorBarY, armorBarWidth, armorBarHeight, 0, 0, 0, 255, 0, true);

                    render.draw_rectangle(armorBarX, armorBarY + 1, armorBarFillWidth, 2, menuCache.playersArmorColorR, menuCache.playersArmorColorG, menuCache.playersArmorColorB, menuCache.playersArmorColorA, 0, true);
                end;
            end;

            if (menuCache.playersSkeleton) then
                local skeletonPath = {
                    { firstPosition = boneScreenPositionCache.head, secondPosition = boneScreenPositionCache.neck },

                    { firstPosition = boneScreenPositionCache.neck, secondPosition = boneScreenPositionCache.leftShoulder },

                    { firstPosition = boneScreenPositionCache.neck, secondPosition = boneScreenPositionCache.rightShoulder },

                    { firstPosition = boneScreenPositionCache.neck, secondPosition = boneScreenPositionCache.pelvis },

                    { firstPosition = boneScreenPositionCache.leftShoulder, secondPosition = boneScreenPositionCache.leftHand },

                    { firstPosition = boneScreenPositionCache.rightShoulder, secondPosition = boneScreenPositionCache.rightHand },

                    { firstPosition = boneScreenPositionCache.pelvis, secondPosition = boneScreenPositionCache.leftHip },

                    { firstPosition = boneScreenPositionCache.pelvis, secondPosition = boneScreenPositionCache.rightHip },

                    { firstPosition = boneScreenPositionCache.leftHip, secondPosition = boneScreenPositionCache.rightFoot },

                    { firstPosition = boneScreenPositionCache.rightHip, secondPosition = boneScreenPositionCache.leftFoot }
                };

                for i, part in pairs(skeletonPath) do
                    render.draw_line(part.firstPosition.x, part.firstPosition.y, part.secondPosition.x, part.secondPosition.y, menuCache.playersSkeletonColorR, menuCache.playersSkeletonColorG, menuCache.playersSkeletonColorB, menuCache.playersSkeletonColorA, 1);
                end;
            end;
        end;

        ::skipPlayer::
    end;

    return;
end;

local aimbotResidualX, aimbotResidualY = 0, 0;

local updateCheatRelated = function()
    if (not gameCache.isValid) then
        return;
    end;

    if (menuCache.aimbotEnabled) then
        local baseSmoothing = (menuCache.aimbotSmoothing / 100);

        local baseFOV = (menuCache.aimbotFOV * 5);

        if (menuCache.aimbotDrawFOV) then
            render.draw_circle(screenCenter.x, screenCenter.y, baseFOV - 1, menuCache.aimbotDrawFOVColorR, menuCache.aimbotDrawFOVColorG, menuCache.aimbotDrawFOVColorB, menuCache.aimbotDrawFOVColorA, 1, false);
        end;

        if (gameCache.closestPlayer == nil or gameCache.closestPlayer == 0) then
            gameCache.closestPlayer = 0;

            goto skipAimbot;
        end;

        local closestPlayer = gameCache.closestPlayer;

        if (menuCache.aimbotEnabledKeybind) then
            local closestPlayerInfo = getPlayerInfo(closestPlayer);

            if (closestPlayerInfo == nil or closestPlayerInfo == 0) then
                gameCache.closestPlayer = 0;
                
                goto skipAimbot;
            end;

            local closestPlayerHealth = getPlayerHealth(closestPlayer);

            if (closestPlayerHealth == nil or closestPlayerHealth == 0) then
                gameCache.closestPlayer = 0;
                
                goto skipAimbot;
            end;

            local boneScreenPositionCache = { };

            for i, bone in pairs(boneData) do
                local bonePosition = getBonePosition(closestPlayer, bone.id, (bone.offset ~= nil and bone.offset or vec3(0, 0, 0)));

                if (bonePosition == nil or bonePosition == 0) then
                    gameCache.closestPlayer = 0;
                    
                    goto skipAimbot;
                end;

                local boneScreenPosition = worldToScreen(bonePosition, gameCache.viewmatrix);

                if (boneScreenPosition == nil or boneScreenPosition == 0) then
                    gameCache.closestPlayer = 0;
                    
                    goto skipAimbot;
                end;

                boneScreenPositionCache[bone.name] = boneScreenPosition;
            end;

            local closestPlayerHitboxScreenPosition = (menuCache.aimbotHitbox == 0 and boneScreenPositionCache["head"] or boneScreenPositionCache["pelvis"]);

            if (closestPlayerHitboxScreenPosition == nil or closestPlayerHitboxScreenPosition == 0) then
                gameCache.closestPlayer = 0;

                goto skipAimbot;
            end;

            local closestPlayerHitboxScreenDistance = getDistance2D(closestPlayerHitboxScreenPosition, screenCenter);

            if (closestPlayerHitboxScreenDistance == nil or closestPlayerHitboxScreenDistance > baseFOV) then
                gameCache.closestPlayer = 0;

                goto skipAimbot;
            end;

            local closestPlayerDeltaX, closestPlayerDeltaY = (closestPlayerHitboxScreenPosition.x - screenCenter.x), (closestPlayerHitboxScreenPosition.y - screenCenter.y);

            if (math.abs(closestPlayerDeltaX) < 1 and math.abs(closestPlayerDeltaY) < 1) then
                goto skipAimbot;
            end;

            local closestPlayerLerpDistance = math.clamp(closestPlayerHitboxScreenDistance / 500, 0.3, 1);

            local closestPlayerLerpCurve = (closestPlayerLerpDistance ^ 0.6);

            local closestPlayerLerpFactor = math.clamp((1 - (baseSmoothing * 2)) * closestPlayerLerpCurve, 0.02, 0.2);

            local closestPlayerMoveX, closestPlayerMoveY = math.lerp(0, closestPlayerDeltaX, closestPlayerLerpFactor), math.lerp(0, closestPlayerDeltaY, closestPlayerLerpFactor);

            aimbotResidualX = (aimbotResidualX + closestPlayerMoveX);

            aimbotResidualY = (aimbotResidualY + closestPlayerMoveY);

            local closestPlayerSendX, closestPlayerSendY = math.floor(aimbotResidualX), math.floor(aimbotResidualY);

            aimbotResidualX = ((aimbotResidualX - closestPlayerSendX) * 0.9);

            aimbotResidualY = ((aimbotResidualY - closestPlayerSendY) * 0.9);

            input.simulate_mouse(closestPlayerSendX, closestPlayerSendY, 1);
        end;
    end;

    ::skipAimbot::

    return;
end;

local updateAll = function()
    if (proc.is_attached()) then
        updateMenuRelated();
        
        updateGameRelated();

        updateEntityRelated();

        updateCheatRelated();
    end;

    return;
end;

-- @REGISTER

engine.register_on_engine_tick(updateAll);