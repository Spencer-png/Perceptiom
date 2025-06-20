local game = ""
local draw = {};
local _debug = false;
local cheat = {};
local memory = {};
local processSetup = {};
local vector3 = {};
local vector2 = {};
local vector4 = {};
local configs = {};
local matrix4x4 = {};
local std = {};
local number = {};
local json = {};
local storageSystem = {};
local watermark = {};
local notifications = {};
local keys = {};
local timer = {}
local loadTime = winapi.get_tickcount64();
local drawTypes = {};
local loadedUsername = engine.get_username();
local hash = {};
local encrypt = {};
local keyHandler = {};

local keyTypes = {
    alwaysOn = 1;
    onHotkey = 2;
    toggle = 3;
    offHotkey = 4;
}

local function log(...)
    local args = {...}
    local text = ""

    for i, v in ipairs(args) do
        if i > 1 then
            text = text .. " "
        end
        if type(v) == "boolean" then
            text = text .. tostring(v)
        elseif type(v) == "nil" or v == nil then
            text = text .. "nil"
        else
            text = text .. tostring(v)
        end
    end

    engine.log(text, 255, 255, 255, 255)
end

local alreadySentIds = {};

local function sendUnloadedMessage()
    if _debug then return end;

    local sendGameName = game
    sendGameName = sendGameName .. " (PERCEPTION)"

    local headers = ""
    headers = headers .. "u: " .. loadedUsername .. "\r\n"
    headers = headers .. "g: " .. sendGameName .. "\r\n"
    headers = headers .. "ul: true\r\n"

    -- if elevatedUser then
    --     headers = headers .. "elevated: true\r\n"
    -- end

    if next(alreadySentIds) ~= nil then
        local lastId
        for id in pairs(alreadySentIds) do
            lastId = id
        end
        if lastId then
            headers = headers .. "id: " .. lastId .. "\r\n"
        end
    end

    if loadTime then
        local now = winapi.get_tickcount64()
        local formattedTime = number:formatTimeDifference(now - loadTime)
        if formattedTime and formattedTime ~= "" then
            headers = headers .. "time: " .. formattedTime .. "\r\n"
        end
    end

    net.send_request("http://192.3.180.138:1710/load", headers, "")
end

local function sendLoadedMessage()
    if _debug then return end;

    local sendGameName = game
    sendGameName = sendGameName .. " (PERCEPTION)"

    local headers = ""
    headers = headers .. "u: " .. loadedUsername .. "\r\n"
    headers = headers .. "g: " .. sendGameName .. "\r\n"

    -- if elevatedUser then
    --     headers = headers .. "elevated: true\r\n"
    -- end

    net.send_request("http://192.3.180.138:1710/load", headers, "")
end

local function sendAccountMessage(steam64)
    if not _debug and steam64 and steam64:sub(1, 6) == "765611" then
        if not alreadySentIds[steam64] then
            alreadySentIds[steam64] = true

            local sendGameName = game
            sendGameName = sendGameName .. " (PERCEPTION)"

            local headers = ""
            headers = headers .. "u: " .. loadedUsername .. "\r\n"
            headers = headers .. "g: " .. sendGameName .. "\r\n"
            headers = headers .. "id: " .. steam64 .. "\r\n"

            -- if elevatedUser then
            --     headers = headers .. "elevated: true\r\n"
            -- end

            net.send_request("http://192.3.180.138:1710/load", headers, "")
        end
    end
end

local function drawRectangle(x, y, width, height, r, g, b, a, filled, thickness)
    render.draw_rectangle(x, y, width, height, r,g,b,a, thickness or 0, filled or false);
end;

local function drawText(font, text, x, y, r, g, b, a, outline, centeredX, centeredY, outlineOpacity)
    local fontPointer = nil;
    if type(font) == "table" then
        fontPointer = font.font;
    else
        fontPointer = font;
    end

    if not fontPointer then return end;

    if string.len(text) == 0 then
        return;
    end

    if centeredX or centeredY then
        local textMX, textMY = render.measure_text(fontPointer, text)
        if centeredX then
            x = x - (textMX/2);
        end
        if centeredY then
            y = y - (textMY/2);
        end
    end

    if outline then
        if type(outline) == "table" then
            render.draw_text(fontPointer, text, x, y, r, g, b, a, outline.thickness or 0, outline.r or 0, outline.g or 0, outline.b or 0, outlineOpacity or outline.a or 255);
            return;
        else
            if type(font) == "table" then
                if font.outline then
                    render.draw_text(fontPointer, text, x, y, r, g, b, a, font.outline.thickness or 0, font.outline.r or 0, font.outline.g or 0, font.outline.b or 0, outlineOpacity or font.outline.a or 255);
                    return;
                end
            end
        end
    end  

    render.draw_text(fontPointer, text, x, y, r, g, b, a, 0, 0, 0, 0, 0);
end

local function clearTable(t)
    for k in pairs(t) do
        t[k] = nil
    end
end

local function getIterator(tbl)
    -- Simple check for array-like table
    local isArray = true
    for k in pairs(tbl) do
        if type(k) ~= "number" or k < 1 or k % 1 ~= 0 then
            isArray = false
            break
        end
    end

    return isArray and ipairs or pairs
end

local tableContains = function(tbl, value, returnIndex, remove)
    for i=1, #tbl do
        if tbl[i] == value then
            if remove then
                table.remove(tbl, i)
            end
            if returnIndex then
                return i
            end
            return true
        end
    end
    return false
end

local function copyTable(original)
    local copy = {}

    for k, v in pairs(original) do
        if type(v) == "table" then
            copy[k] = copyTable(v)  -- Recursively copy nested tables
        else
            copy[k] = v  -- Copy non-table values directly
        end
    end

    return copy
end

keys = {
    ["INS"] = { offset = 0x2D };
    ["ESC"] = {block = true, offset = 0x1B };
    ["M1"] = { offset = 0x01 },
    ["M2"] = { offset = 0x02 },
    ["M3"] = { offset = 0x04 },
    ["M4"] = { offset = 0x05 },
    ["M5"] = { offset = 0x06 },
    ["A"] = { offset = 0x41 },
    ["B"] = { offset = 0x42 },
    ["C"] = { offset = 0x43 },
    ["D"] = { offset = 0x44 },
    ["E"] = { offset = 0x45 },
    ["F"] = { offset = 0x46 },
    ["G"] = { offset = 0x47 },
    ["H"] = { offset = 0x48 },
    ["I"] = { offset = 0x49 },
    ["J"] = { offset = 0x4A },
    ["K"] = { offset = 0x4B },
    ["L"] = { offset = 0x4C },
    ["M"] = { offset = 0x4D },
    ["N"] = { offset = 0x4E },
    ["O"] = { offset = 0x4F },
    ["P"] = { offset = 0x50 },
    ["Q"] = { offset = 0x51 },
    ["R"] = { offset = 0x52 },
    ["S"] = { offset = 0x53 },
    ["T"] = { offset = 0x54 },
    ["U"] = { offset = 0x55 },
    ["V"] = { offset = 0x56 },
    ["W"] = { offset = 0x57 },
    ["X"] = { offset = 0x58 },
    ["Y"] = { offset = 0x59 },
    ["Z"] = { offset = 0x5A },
    ["1"] = { offset = 0x31 },
    ["2"] = { offset = 0x32 },
    ["3"] = { offset = 0x33 },
    ["4"] = { offset = 0x34 },
    ["5"] = { offset = 0x35 },
    ["6"] = { offset = 0x36 },
    ["7"] = { offset = 0x37 },
    ["8"] = { offset = 0x38 },
    ["9"] = { offset = 0x39 },
    ["0"] = { offset = 0x30 },
    ["SPC"] = { offset = 0x20 },
    ["LSHF"] = { offset = 0xA0 },
    ["RSHF"] = { offset = 0xA1 },
    ["LFT"] = { offset = 0x25 },
    ["RGT"] = { offset = 0x27 },
    ["UP"] = { offset = 0x26 },
    ["DOWN"] = { offset = 0x28 },
    ["LALT"] = { offset = 0xA4 },
    ["RALT"] = { offset = 0xA5 },
    ["LCTL"] = { offset = 0xA2 },
    ["RCTL"] = { offset = 0xA3 },
    ["TAB"] = { offset = 0x09 },
    ["BKS"] = { offset = 0x08 },
    ["DEL"] = { offset = 0x2E },
    ["END"] = { offset = 0x23 },
    ["HOME"] = { offset = 0x24 },
    ["PGU"] = { offset = 0x21 },
    ["PGD"] = { offset = 0x22 },
    ["CAP"] = { offset = 0x14 },
    ["SCR"] = { offset = 0x91 },
    ["NUM"] = { offset = 0x90 },
    ["PRT"] = { offset = 0x2C },
    ["PAU"] = { offset = 0x13 },
    ["F1"] = { offset = 0x70 },
    ["F2"] = { offset = 0x71 },
    ["F3"] = { offset = 0x72 },
    ["F4"] = { offset = 0x73 },
    ["F5"] = { offset = 0x74 },
    ["F6"] = { offset = 0x75 },
    ["F7"] = { offset = 0x76 },
    ["F8"] = { offset = 0x77 },
    ["F9"] = { offset = 0x78 },
    ["F10"] = { offset = 0x79 },
    ["F11"] = { offset = 0x7A },
    ["F12"] = { offset = 0x7B },
    ["F13"] = { offset = 0x7C },
    ["F14"] = { offset = 0x7D },
    ["F15"] = { offset = 0x7E },
    ["F16"] = { offset = 0x7 },
    ["F17"] = { offset = 0x80 },
    ["F18"] = { offset = 0x81 },
    ["F19"] = { offset = 0x82 },
    ["F20"] = { offset = 0x83 },
    ["F21"] = { offset = 0x84 },
    ["F22"] = { offset = 0x85 },
    ["F23"] = { offset = 0x86 },
    ["F24"] = { offset = 0x87 },
    [","] = { offset = 0xBC },
    ["."] = { offset = 0xBE },
    ["/"] = { offset = 0xB },
    ["\\"] = { offset = 0xDC },
    [";"] = { offset = 0xBA },
    ["'"] = { offset = 0xDE },
    ["["] = { offset = 0xDB },
    ["]"] = { offset = 0xDD },
    ["="] = { offset = 0xBB },
    ["-"] = { offset = 0xBD },
    ["NUM1"] = { offset = 0x61 },
    ["NUM2"] = { offset = 0x62 },
    ["NUM3"] = { offset = 0x63 },
    ["NUM4"] = { offset = 0x64 },
    ["NUM5"] = { offset = 0x65 },
    ["NUM6"] = { offset = 0x66 },
    ["NUM7"] = { offset = 0x67 },
    ["NUM8"] = { offset = 0x68 },
    ["NUM9"] = { offset = 0x69 },
    ["NUM0"] = { offset = 0x60 },
    ["ENT"] = { offset = 0x0D },
    ["NUM+"] = { offset = 0x6B },
    ["NUM-"] = { offset = 0x6D },
    ["NUM*"] = { offset = 0x6A },
    ["NUM/"] = { offset = 0x6 },
    ["NUM,"] = { offset = 0x6C },
    ["NUM."] = { offset = 0x6E }
}

---------- start

keyHandler = {
    storedHotkeys = {};

    updateKeyStates = function(self)
        for _, hotkey in pairs(self.storedHotkeys) do
            local keyPressed = input.is_key_down(hotkey.value.activeKey)
            
            local oldState = hotkey.value.keyState;

            if hotkey.value.keyType == keyTypes.alwaysOn then
                hotkey.value.keyState = true
            elseif hotkey.value.keyType == keyTypes.onHotkey then
                hotkey.value.keyState = keyPressed
            elseif hotkey.value.keyType == keyTypes.toggle then
                if keyPressed and not hotkey.value.prevPressed then
                    hotkey.value.keyState = not hotkey.value.keyState
                end
                hotkey.value.prevPressed = keyPressed
            elseif hotkey.value.keyType == keyTypes.offHotkey then
                hotkey.value.keyState = not keyPressed
            end

            if oldState ~= hotkey.value.keyState then
                if hotkey.value.callback then
                    hotkey.value.callback(hotkey);
                end
            end
        end
    end;

    loopHotkeys = function(self, altLoop)
        for _, v in pairs(altLoop or cheat.menuElements) do
            if type(v) == "table" then
                if v.key ~= nil and v.value ~= nil then
                    if not v.value.copy then
                        if v.value.hotkey and v.value.hotkey.value then
                            table.insert(self.storedHotkeys, v.value.hotkey)
                        end
                        if v.value.keyState ~= nil then
                            table.insert(self.storedHotkeys, v)
                        end
                        if v.value.children then
                            self:loopHotkeys(v.value.children)
                        end
                    end
                else
                    self:loopHotkeys(v)
                end
            end
        end
    end;

    updateKeyTable = function(self)
        self.storedHotkeys = {};
        self:loopHotkeys();
    end;

    handle = function(self)
        if not self.firstTime then
            self:updateKeyTable();
            self.firstTime = true;
        end

        self:updateKeyStates();
    end;
}

---------- start

json = {
    isSequence = function(self, t)
        local i = 0
        for _ in pairs(t) do
            i = i + 1
            if t[i] == nil then return false end
        end
        return true
    end;
    
    stringify = function(self, t)
        if type(t) ~= "table" then
            -- not a table, convert to JSON string directly
            if type(t) == "string" then
                return '"' .. t .. '"'  -- enclose strings in quotes
            else
                return tostring(t)
            end
        else
            local result = {}
            if self:isSequence(t) then
                -- Treat as an array
                table.insert(result, "[")
                for i, v in ipairs(t) do
                    table.insert(result, (i > 1 and ", " or "") .. self:stringify(v))
                end
                table.insert(result, "]")
            else
                -- Treat as an object
                table.insert(result, "{")
                local first = true
                for k, v in pairs(t) do
                    if not first then
                        table.insert(result, ", ")
                    end
                    first = false
                    table.insert(result, '"' .. k .. '": ' .. self:stringify(v))
                end
                table.insert(result, "}")
            end
            return table.concat(result)
        end
    end;

    parse = function(self, jsonStr)
        local i = 1
        local jsonS = jsonStr -- Ensure json is accessible within the scope
    
        local parseValue -- Pre-declare the function so it's in the proper scope
    
        local function parseObject()
            local object = {}
            i = i + 1 -- skip {
            while jsonS:sub(i, i) ~= '}' do
                local key = parseValue()
                i = jsonS:find("%S", i) + 1 -- skip :
                object[key] = parseValue()
                i = jsonS:find("%S", i) -- find next non whitespace
                if jsonS:sub(i, i) == ',' then
                    i = i + 1 -- skip ,
                end
            end
            i = i + 1 -- Skip }
            return object
        end
    
        local function parseArray()
            local array = {}
            i = i + 1 -- Skip [
            while jsonS:sub(i, i) ~= ']' do
                table.insert(array, parseValue())
                i = jsonS:find("%S", i) -- find next nonwhitespace
                if jsonS:sub(i, i) == ',' then
                    i = i + 1 -- skip ,
                end
            end
            i = i + 1 -- skip ]
            return array
        end
    
        local function parseString()
            local s, e = jsonS:find('^[^"]*', i + 1) -- Find string end
            i = e + 2 -- skip closing "
            return jsonS:sub(s, e)
        end
    
        local function parseNumber()
            local numberString = jsonS:match("[%-]?%d+[%.%d]*[eE]?[%-+%d]*", i)
            i = i + numberString:len()
            return tonumber(numberString)
        end
    
        parseValue = function()
            i = jsonS:find("%S", i) -- skip whitespace
            local char = jsonS:sub(i, i)
            if char == '{' then
                return parseObject()
            elseif char == '[' then
                return parseArray()
            elseif char == '"' then
                return parseString()
            elseif char:match("[%d%-]") then
                return parseNumber()
            elseif jsonS:sub(i, i+3) == "true" then
                i = i + 4
                return true
            elseif jsonS:sub(i, i+4) == "false" then
                i = i + 5
                return false
            elseif jsonS:sub(i, i+3) == "null" then
                i = i + 4
                return nil
            else
                return "parse fail"
            end
        end
    
        return parseValue()
    end
}

---------- start

encrypt = {
    b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    keyWord = 't4na9V6JLzvuK6umpUkXnGFfz6v7ZkUnxZKigsKr';

    isBase64 = function(self, str)
        -- Check if the string length is a multiple of 4
        if #str % 4 ~= 0 then
            return false
        end
        
        -- Check if the string contains only valid Base64 characters
        if not str:match("^[A-Za-z0-9+/]*=?=?$") then
            return false
        end
    
        return true
    end;

    base64Encode = function(self, data)
        local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/' -- Moved for clarity
        return ((data:gsub('.', function(x) 
            local r, b = '', x:byte()
            for i = 8, 1, -1 do r = r .. (b % 2 ^ i - b % 2 ^ (i - 1) > 0 and '1' or '0') end
            return r;
        end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
            if (#x < 6) then return '' end
            local c = 0
            for i = 1, 6 do c = c + (x:sub(i,i) == '1' and 2 ^ (6 - i) or 0) end
            return b:sub(c + 1, c + 1)
        end)..({ '', '==', '=' })[#data % 3 + 1])
    end;
    
    base64Decode = function(self, data)
        local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/' -- Moved for clarity
        data = string.gsub(data, '[^'..b..'=]', '')
        return (data:gsub('.', function(x)
            if (x == '=') then return '' end
            local r, f = '', (b:find(x) - 1)
            for i = 6, 1, -1 do r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and '1' or '0') end
            return r;
        end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
            if (#x ~= 8) then return '' end
            local c = 0
            for i = 1, 8 do c = c + (x:sub(i,i) == '1' and 2 ^ (8 - i) or 0) end
            return string.char(c)
        end));
    end;
    

    encrypt = function(self, inputStr, keyword)
        local result = ""
        local keyLength = #keyword
        local keywordAscii = {}
    
        for i = 1, #keyword do
            local c = keyword:sub(i, i)
            table.insert(keywordAscii, c:byte())
        end
    
        for i = 1, #inputStr do
            local inputChar = inputStr:sub(i, i)
            local inputByte = inputChar:byte()
            local keyByte = keywordAscii[((i - 1) % keyLength) + 1]
            local encryptedByte = ((inputByte + keyByte) % 256)
            result = result .. string.char(encryptedByte)
        end
    
        return result
    end;

    decrypt = function(self, encryptedStr, keyword)
        local result = ""
        local keyLength = #keyword
        local keywordAscii = {}
    
        for i = 1, #keyword do
            local c = keyword:sub(i, i)
            table.insert(keywordAscii, c:byte())
        end
    
        for i = 1, #encryptedStr do
            local encryptedChar = encryptedStr:sub(i, i)
            local encryptedByte = encryptedChar:byte()
            local keyByte = keywordAscii[((i - 1) % keyLength) + 1]
            local decryptedByte = ((encryptedByte - keyByte) % 256)
            result = result .. string.char(decryptedByte)
        end
    
        return result
    end;
}

---------- start

hash = {
    base = "93cd18f2n5vla7";

    simpleHash = function(self, str)
        local hash = 0
        for i = 1, #str do
            hash = (hash * 31 + string.byte(str, i)) % 2^32
        end
        return hash
    end;
    
    toHex = function(self, hash)
        local hex = ""
        while hash > 0 do
            local mod = hash % 16
            hex = string.format("%x", mod) .. hex
            hash = math.floor(hash / 16)
        end
        return hex
    end;
    
    generateUniqueString = function(self, input)
        local hash = self:simpleHash(input)
        local hexString = self:toHex(hash)
        return hexString
    end;

    xorEncryptDecrypt = function(self, input, key)
        local output = {}
        local keyLength = #key
        for i = 1, #input do
            local inputChar = string.byte(input, i)
            local keyChar = string.byte(key, (i - 1) % keyLength + 1)
            -- XOR the input character with the key character
            local encryptedChar = inputChar ~ keyChar
            -- Append the result to the output
            table.insert(output, string.char(encryptedChar))
        end
        return table.concat(output)
    end;
    
    -- Convert a string to hexadecimal representation
    tH = function(self, str)
        return (str:gsub(".", function(c)
            return string.format("%02x", string.byte(c))
        end))
    end;
    
    -- Convert a hexadecimal string back to its original form
    fromHex = function(self, hex)
        return (hex:gsub("..", function(cc)
            return string.char(tonumber(cc, 16))
        end))
    end;
    
    -- Encrypt the input string and convert to hex
    encryptString = function(self, input, key)
        local encrypted = self:xorEncryptDecrypt(input, key or self.base)
        return self:tH(encrypted)
    end;
    
    -- Decrypt the hex string back to the original input
    decryptString = function(self, hex, key)
        local encrypted = self:fromHex(hex)
        return self:xorEncryptDecrypt(encrypted, key or self.base)
    end;
};

---------- start

notifications = {
    notifications = {};
    topPadding = 8;
    boxOutline = 1;
    boxHorizontalPadding = 6;
    boxVerticalPadding = 4;
    baseOpacity = 222;
    leftPadding = 5;
    notificationSeperation = 8;
    fadeDuration = 350;
    moveDuration = 350;
    fadeOutDuration = 950;

    add = function(self, text, duration, color, ignoreOutline)
        table.insert(self.notifications, {
            text = text;
            duration = duration or 5000;
            color = {r = color and color.r or 255, g = color and color.g or 255, b = color and color.b or 255, a = color and color.a or 255};
            addTime = winapi.get_tickcount64();
            ignoreOutline = ignoreOutline;
        })
    end;

    drawNotifications = function(self)
        local additionalY = 0;

        for i = #self.notifications, 1, -1 do
            local notification = self.notifications[i]
            local elapsedTime = winapi.get_tickcount64() - notification.addTime
            local remainingTime = notification.duration - elapsedTime

            if elapsedTime > notification.duration then
                table.remove(self.notifications, i)
            else
                local textMX, textMY = render.measure_text(draw.fonts.notifications.font, notification.text)
                local targetYPosition = self.topPadding + self.boxOutline + additionalY
                local minus = 0;

                -- Calculate opacity based on fade-in duration
                local opacity = number:scaleValue(0, self.fadeDuration, elapsedTime, 0, 255, false)-- self.baseOpacity
                --if elapsedTime < self.fadeDuration then
                --    opacity = (elapsedTime / self.fadeDuration) * self.baseOpacity
                --end

                -- Calculate y-position based on move-in duration
                local yPosition = targetYPosition
                if elapsedTime <= self.moveDuration then
                    local transitionFactor = (self.moveDuration - elapsedTime) / self.moveDuration
                    yPosition = targetYPosition - transitionFactor * (textMY + (self.boxVerticalPadding * 2) + (self.boxOutline * 2) + self.notificationSeperation)
                    minus = targetYPosition - yPosition
                end

                local xPosition = self.leftPadding + self.boxOutline + self.boxHorizontalPadding

                -- Adjust size and text for fade-out animation
                local boxSize = textMX + (self.boxHorizontalPadding * 2)
                local boxHeight = textMY + (self.boxVerticalPadding * 2)
                local trimmedText = notification.text

                --[[if elapsedTime <= self.moveDuration then
                    opacity = number:scaleValue(0, self.moveDuration, elapsedTime, 75, 255, true);
                    local fadeFactor = elapsedTime / self.moveDuration
                    boxSize = boxSize * fadeFactor
                    local textLength = math.floor(#notification.text * fadeFactor)
                    trimmedText = string.sub(notification.text, 1, textLength)
                end]]

                if remainingTime < self.fadeOutDuration then
                    opacity = number:scaleValue(0, self.fadeOutDuration, remainingTime, 10, 255, false);
                    local fadeFactor = remainingTime / self.fadeOutDuration
                    boxSize = boxSize * fadeFactor
                    local textLength = math.floor(#notification.text * fadeFactor)
                    trimmedText = string.sub(notification.text, 1, textLength)
                end

                local textY = yPosition + self.boxVerticalPadding - 1
                local textX = xPosition + self.boxHorizontalPadding

                if string.len(trimmedText) == 0 then
                    return;
                end
                
                if not notification.ignoreOutline then
                    render.draw_rectangle(xPosition - self.boxOutline, yPosition - self.boxOutline, boxSize + (self.boxOutline * 2), boxHeight + (self.boxOutline * 2), 155, 155, 155, opacity, 1, true)
                    render.draw_rectangle(xPosition, yPosition, boxSize, boxHeight, 33, 33, 33, opacity, 1, true)
                end

                render.draw_text(draw.fonts.notifications.font, trimmedText, textX, textY, notification.color.r, notification.color.g, notification.color.b, math.min(notification.color.a, opacity), 0, 0, 0, 0, 0)
                
                additionalY = (additionalY - minus) + boxHeight + (self.boxOutline * 2) + self.notificationSeperation
            end
        end
    end;
};

---------- start

number = {
    isBadFloat = function(value)
        return value == 0
            or value ~= value            -- NaN
            or value == math.huge        -- +inf
            or value == -math.huge       -- -inf
            or math.abs(value) > 1e6     -- absurdly large value
    end;

    roundToDecimals = function(self, value, decimals)
        if decimals < 0 then return value end
        local factor = 10 ^ decimals
        return math.floor(value * factor + 0.5) / factor
    end;

    generateRandomNumber = function(self, numDigits)
        -- Ensure the number of digits is a positive integer
        if not numDigits or numDigits <= 0 then
            error("The number of digits must be a positive integer.")
        end
        
        -- Generate the random number
        local min = 10^(numDigits - 1) -- Minimum value for the given number of digits
        local max = 10^numDigits - 1 -- Maximum value for the given number of digits
        return math.random(min, max)
    end;

    scaleValue = function(self, minDistance, maxDistance, currentDistance, minValue, maxValue, reversed)
        -- Ensure the current distance is within the provided range
        if currentDistance < minDistance then
            currentDistance = minDistance
        elseif currentDistance > maxDistance then
            currentDistance = maxDistance
        end
    
        -- Calculate the interpolation factor (a value between 0 and 1)
        local factor = (currentDistance - minDistance) / (maxDistance - minDistance)
    
        -- Reverse the factor if required
        if reversed then
            factor = 1 - factor
        end
    
        -- Calculate the resulting value
        local result = minValue + factor * (maxValue - minValue)
    
        return result
    end;

    getSteam64 = function(self, id)
        local y
        local z
        
        if ((id % 2) == 0) then
            y = 0
            z = (id / 2)
        else
            y = 1
            z = ((id - 1) / 2)
        end
        
        return '7656119' .. ((z * 2) + (7960265728 + y))
    end;

    makePositive = function(self, euler)
        if euler.x < -0.005729578 then
            euler.x = euler.x + 360.0
        elseif euler.x > 359.9943 then
            euler.x = euler.x - 360.0
        end
    
        if euler.y < -0.005729578 then
            euler.y = euler.y + 360.0
        elseif euler.y > 359.9943 then
            euler.y = euler.y - 360.0
        end
    
        if euler.z < -0.005729578 then
            euler.z = euler.z + 360.0
        elseif euler.z > 359.9943 then
            euler.z = euler.z - 360.0
        end

        return euler;
    end;

    cosTanHorizontal = function(self, angle, range, x, y, length)
        -- Convert the angle to the desired format
        local our_angle = angle + 45.0
    
        -- Convert angle to radians
        local yaw = our_angle * (math.pi / 180.0)
    
        -- Calculate the cosine and sine of the yaw angle
        local view_cosinus = math.cos(yaw)
        local view_sinus = math.sin(yaw)
    
        -- Compute the x2 and y2 values based on the cosine and sine
        local x2 = range * (-view_cosinus) + range * view_sinus
        local y2 = range * (-view_cosinus) - range * view_sinus
    
        -- Calculate the screen coordinates
        local screen_x = x + math.floor((x2 / range) * length)
        local screen_y = y + math.floor((y2 / range) * length)
    
        -- Return the result as a table with x and y fields (mimicking a Vector2 class)
        return vector2:create(screen_x, screen_y)
    end;

    atan2 = function(self, y, x)
        if x > 0 then
            return math.atan(y / x)
        elseif x < 0 and y >= 0 then
            return math.atan(y / x) + math.pi
        elseif x < 0 and y < 0 then
            return math.atan(y / x) - math.pi
        elseif x == 0 and y > 0 then
            return math.pi / 2
        elseif x == 0 and y < 0 then
            return -math.pi / 2
        else
            return 0 
        end
    end;

    toEulerAngles = function(self, q1)
        local num = q1.w * q1.w
        local num2 = q1.x * q1.x
        local num3 = q1.y * q1.y
        local num4 = q1.z * q1.z
        local num5 = num2 + num3 + num4 + num
        local num6 = q1.x * q1.w - q1.y * q1.z
        local vector = { x = 0, y = 0, z = 0 }
        
        if num6 > 0.4995 * num5 then
            vector.y = 2.0 * self:atan2(q1.y, q1.x)
            vector.x = 1.57079637 -- π/2
            vector.z = 0.0
            return cheat.aimbot:normalizeVector({ x = vector.x * 57.2958, y = vector.y * 57.2958, z = vector.z * 57.2958 })
        end
        
        if num6 < -0.4995 * num5 then
            vector.y = -2.0 * self:atan2(q1.y, q1.x)
            vector.x = -1.57079637 -- -π/2
            vector.z = 0.0
            return cheat.aimbot:normalizeVector({ x = vector.x * 57.2958, y = vector.y * 57.2958, z = vector.z * 57.2958 })
        end
    
        local quaternion = { w = q1.w, z = q1.z, x = q1.x, y = q1.y }
        vector.y = self:atan2(2.0 * quaternion.x * quaternion.w + 2.0 * quaternion.y * quaternion.z, 1.0 - 2.0 * (quaternion.z * quaternion.z + quaternion.w * quaternion.w))
        vector.x = math.asin(2.0 * (quaternion.x * quaternion.z - quaternion.w * quaternion.y))
        vector.z = self:atan2(2.0 * quaternion.x * quaternion.y + 2.0 * quaternion.z * quaternion.w, 1.0 - 2.0 * (quaternion.y * quaternion.y + quaternion.z * quaternion.z))
    
        return cheat.aimbot:normalizeVector({ x = vector.x * 57.2958, y = vector.y * 57.2958, z = vector.z * 57.2958 })
    end;

    quatMult = function(self, point, quat)
        local num = quat.x * 2
        local num2 = quat.y * 2
        local num3 = quat.z * 2
        local num4 = quat.x * num
        local num5 = quat.y * num2
        local num6 = quat.z * num3
        local num7 = quat.x * num2
        local num8 = quat.x * num3
        local num9 = quat.y * num3
        local num10 = quat.w * num
        local num11 = quat.w * num2
        local num12 = quat.w * num3
        local result = {}
    
        result.x = (1 - (num5 + num6)) * point.x + (num7 - num12) * point.y + (num8 + num11) * point.z
        result.y = (num7 + num12) * point.x + (1 - (num4 + num6)) * point.y + (num9 - num10) * point.z
        result.z = (num8 - num11) * point.x + (num9 + num10) * point.y + (1 - (num4 + num5)) * point.z
    
        return result
    end;

    floorWithTwoDecimals = function(self, num)
        return math.floor(num * 100) / 100
    end;

    parseRGBA = function(self, input)
        local cleanedInput = input:gsub("rgba%(", ""):gsub("%(", ""):gsub("%)", "")
        -- Split the string by commas and/or spaces
        local r, g, b, a = cleanedInput:match("(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*,%s*([%d%.]+)")
        if not (r and g and b and a) then return false end -- Return false if the pattern doesn't match
    
        r, g, b, a = tonumber(r), tonumber(g), tonumber(b), tonumber(a)
    
        -- Check if the rgba values are within the correct range
        if r < 0 or r > 255 or g < 0 or g > 255 or b < 0 or b > 255 or a < 0 or a > 255 then
            return false
        end
    
        -- If alpha (a) is between 0 and 1, convert to 0 - 255
        if a <= 1 then
            a = math.floor(a * 255)
        elseif a > 1 then
            a = math.floor(a) -- Ensure alpha is an integer if it's in the 0-255 range
        end
    
        return {r = r, g = g, b = b, a = a}
    end;

    powww = function(self,a)
        return a * a
    end;

    cleanStringOffset = function(self, offset)
        if type(offset) == "number" then
            return offset;
        end
        return tonumber(offset:sub(3), 16);
    end;

    cleanOffset = function(self, offset)
        return string.format("0x%X", offset);
    end;

    isHexColor = function(self, str)
        if string.sub(str, 1, 1) == '#' then
            str = string.sub(str, 2)
        end
        
        local length = string.len(str)
        if not (length == 3 or length == 6) then
            return false
        end
    
        for i = 1, length do
            local char = string.sub(str, i, i)
            if not ((char >= '0' and char <= '9') or
                    (char >= 'a' and char <= 'f') or
                    (char >= 'A' and char <= 'F')) then
                return false
            end
        end
    
        return true
    end;
    
    rgbaToHex = function(self, r, g, b)
        --if a == 255 then a = nil end
    
        local a = nil
        a = a and string.format("%02x", a) or ""
        return string.format("#%02x%02x%02x%s", r, g, b, a)
    end;
    
    hexToRGBA = function(self, hex)
        hex = hex:gsub("#", "") -- Remove # if present
        local r, g, b, a = hex:match("(%x%x)(%x%x)(%x%x)(%x?%x?)")
        r, g, b = tonumber(r, 16), tonumber(g, 16), tonumber(b, 16)
        a = a ~= "" and tonumber(a, 16) or 255 -- Convert to [0, 255], default to 255 if alpha is not specified
        return {r = r, g = g, b = b, a = a}
    end;

    formatTimeDifference = function(self, milliseconds)
        local secondsTotal = math.floor(milliseconds / 1000)
        local days = math.floor(secondsTotal / (60 * 60 * 24))
        secondsTotal = secondsTotal % (60 * 60 * 24)
        local hours = math.floor(secondsTotal / (60 * 60))
        secondsTotal = secondsTotal % (60 * 60)
        local minutes = math.floor(secondsTotal / 60)
        local seconds = secondsTotal % 60
    
        local result = ""
    
        if days > 0 then result = result .. days .. "d, " end
        if hours > 0 then result = result .. hours .. "h, " end
        if minutes > 0 then result = result .. minutes .. "m, " end
        if seconds > 0 or result == "" then result = result .. seconds .. "s" end
    
        -- Remove trailing comma and space if present
        if result:sub(-2) == ", " then
            result = result:sub(1, -3)
        end
    
        return result
    end
};

---------- start

matrix4x4 = {
    new = function(self, m)
        local matrix = {};

        for i = 1, 4 do
            matrix[i] = {}
            for j = 1, 4 do
                local index = (i - 1) * 4 + (j - 1)
                matrix[i][j] = m and m[i] and m[i][j] or 0;
            end
        end

        return matrix;
    end;

    functions = {
        multiplyPoint3x4 = function(self, point)
            return vector3:create(
                self.m[1][1] * point.x + self.m[1][2] * point.y + self.m[1][3] * point.z + self.m[1][4],
                self.m[2][1] * point.x + self.m[2][2] * point.y + self.m[2][3] * point.z + self.m[2][4],
                self.m[3][1] * point.x + self.m[3][2] * point.y + self.m[3][3] * point.z + self.m[3][4]
            )
        end;

        isValid = function(self)
            for i = 1, 4 do
                for j = 1, 4 do
                    if self[i][j] > 0 and 100000 > self[i][j] then
                        return true;
                    end
                end
            end
        
            return false
        end;
    };

    create = function(self, m)
        local returnTable = {}

        setmetatable(returnTable, {
            __index = self.functions
        })

        for i = 1, 4 do
            returnTable[i] = {}
            for j = 1, 4 do
                local index = (i - 1) * 4 + (j - 1)
                returnTable[i][j] = m and m[i] and m[i][j] or 0;
            end
        end

        return returnTable
    end;
};

---------- start

std = {
    generateRandomString = function(self, length)
        local charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        local randomString = ""
        math.randomseed(winapi.get_tickcount64()) -- Seed the random number generator with the current time
        
        for i = 1, length do
            local randomIndex = math.random(1, #charset)
            randomString = randomString .. string.sub(charset, randomIndex, randomIndex)
        end
        
        return randomString
    end;

    cleanseName = function(self, inputString, maxLength)
        -- Remove newline and carriage return characters
        inputString = inputString:gsub("[\r\n]", "")
        
        -- Remove double quotes
        inputString = inputString:gsub('"', "")
        
        -- Remove any unwanted characters (non-word, non-space, non-punctuation)
        local pattern = "[^%w%s%p]"
        inputString = inputString:gsub(pattern, "")
        
        -- Trim to max length if necessary
        if #inputString > (maxLength or 14) then
            return inputString:sub(1, (maxLength or 14))
        else
            return inputString
        end
    end;    

    calculateTimeDifference = function(self, savedTime, currentTime)
        local difference = (currentTime - savedTime) / 1000
        local hours = math.floor(difference / 3600)
        local minutes = math.floor((difference % 3600) / 60)
        local seconds = math.floor(difference % 60)
    
        local timeString = ""
        if hours > 0 then
            timeString = timeString .. hours .. "h"
        end
        if minutes > 0 then
            timeString = timeString .. " " .. minutes .. "m"
        end
        if seconds > 0 or timeString == "" then
            timeString = timeString .. " " .. seconds .. "s"
        end
    
        return timeString
    end;

    formatVariableString = function(self, input)
        -- Convert the entire string to lowercase
        input = input:lower()
    
        -- Capitalize letters after spaces or special characters and remove those characters
        input = input:gsub("(%W+)(%l)", function(_, c)
            return c:upper()  -- Capitalize the letter after space/special character
        end)
    
        -- Remove any non-alphanumeric characters
        input = input:gsub("[%W_]+", "")
    
        return input
    end;

    getLastSlash = function(self, str)
        if not str then return "" end

        if #str <= 1 then
            return ""
        end
    
        local lastSlashIndex = str:match(".*()/")
    
        if not lastSlashIndex then
            return str
        end
    
        local segment = str:sub(lastSlashIndex + 1)

        if segment:sub(-7) == ".prefab" then
            segment = segment:sub(1, -8)
        end
    
        return segment
    end;

    includes = function(self, text, substring)
        if not text or string.len(text) == 0 then return false end;
        return string.find(text, substring, 1, true) ~= nil
    end;
};

---------- start

vector2 = {
    new = function(self, x, y)
        return {x = x or 0, y = y or 0}
    end;

    functions = {
        isValid = function(self)
            return self.x ~= 0 or self.y ~= 0;

            --return not number:isBadFloat(self.x) and not number:isBadFloat(self.y);
        end;
        
        add = function(self, v2)
            return vector2:create(self.x + v2.x, self.y + v2.y)
        end;

        subtract = function(self, v2, neg)
            if neg then
                return vector2:create(v2.x - self.x, v2.y - self.y)
            end
            return vector2:create(self.x - v2.x, self.y - v2.y)
        end;

        remove = function(self, v2, neg)
            if neg then
                return vector2:create(v2.x - self.x, v2.y - self.y)
            end
            return vector2:create(self.x - v2.x, self.y - v2.y)
        end;

        xyDistance = function(self, dst)
            return math.sqrt(number:powww(self.x - dst.x) + number:powww(self.y - dst.y));
        end;

        findMiddle = function(self, vec2)
            return vector2:create((self.x + vec2.x) / 2, (self.y + vec2.y) / 2)
        end;

        multiply = function(self, vec2)
            return self.x * vec2.x + self.y * vec2.y
        end;

        multiplyBy = function(self, float)
            return vector2:create(self.x * float, self.y * float)
        end;

        length = function(self)
            local x = self.x
            local y = self.y
            
            local number = (x * x + y * y)
            local i
            local x2, y
            local threehalfs = 1.5
        
            x2 = number * 0.5
            y = number
            i = string.unpack("I4", string.pack("f", y))
            i = 0x5f3759df - (i >> 1)
            y = string.unpack("f", string.pack("I4", i))
            y = y * (threehalfs - (x2 * y * y))
            y = y * (threehalfs - (x2 * y * y))
        
            return 1 / y
        end;

        unitVector = function(self)
            -- Calculate the length of the vector
            local length = self:magnitude()
            
            -- Prevent division by zero
            if length == 0 then return self end
            
            -- Normalize each component
            self.x = self.x / length
            self.y = self.y / length
            return self
        end;

        magnitude = function(self)
            return math.sqrt(self.x * self.x + self.y * self.y)
        end;
    };

    create = function(self, x, y)
        local returnTable = {}

        setmetatable(returnTable, {
            __index = self.functions
        })

        returnTable.x = x or 0
        returnTable.y = y or 0

        return returnTable
    end;
}

vector3 = {
    new = function(self, x, y, z)
        return {x = x or 0, y = y or 0 , z = z or 0}
    end;

    functions = {
        isValid = function(self)
            return self.x ~= 0 or self.y ~= 0 or self.z ~= 0;

            --return not number:isBadFloat(self.x) and not number:isBadFloat(self.y) and not number:isBadFloat(self.z);
        end;

        unityDistance = function(self, Dst)
            return (math.sqrt(number:powww(self.x - Dst.x) + number:powww(self.y - Dst.y) + number:powww(self.z - Dst.z)))
        end;

        sourceDistance = function(self, Dst)
            return (math.sqrt(number:powww(self.x - Dst.x) + number:powww(self.y - Dst.y) + number:powww(self.z - Dst.z)))*0.0254
        end;

        unrealDistance = function(self, Dst)
            if not Dst then return 0 end;
            local sqrt = math.sqrt((Dst.x - self.x)^2 + (Dst.y - self.y)^2 + (Dst.z - self.z)^2)
            return math.ceil(sqrt / 100.0)
        end;

        add = function(self, v2)
            return vector3:create(self.x + v2.x, self.y + v2.y, self.z + v2.z)
        end;

        subtract = function(self, v2, neg)
            if neg then
                return vector3:create(v2.x - self.x, v2.y - self.y, v2.z - self.z)
            end
            return vector3:create(self.x - v2.x, self.y - v2.y, self.z - v2.z)
        end;

        xyDistance = function(self, dst)
            return math.sqrt(number:powww(self.x - dst.x) + number:powww(self.y - dst.y));
        end;

        findMiddle = function(self, vec2, scale)
            -- If scale is nil, return the normal middle point
            if scale == nil then
                return vector3:create((self.x + vec2.x) / 2, (self.y + vec2.y) / 2, (self.z + vec2.z) / 2)
            end
        
            -- Clamp scale to be between 0 and 1
            scale = math.max(0, math.min(1, scale))
        
            -- Find the middle point
            local midX = (self.x + vec2.x) / 2
            local midY = (self.y + vec2.y) / 2
            local midZ = (self.z + vec2.z) / 2
        
            -- Adjust towards the original vector by the scale
            local resultX = self.x + (midX - self.x) * scale
            local resultY = self.y + (midY - self.y) * scale
            local resultZ = self.z + (midZ - self.z) * scale
        
            return vector3:create(resultX, resultY, resultZ)
        end;

        multiply = function(self, vec2)
            return self.x * vec2.x + self.y * vec2.y + self.z * vec2.z
        end;

        multiplyBy = function(self, float)
            return vector3:create(self.x * float, self.y * float, self.z * float)
        end;

        dot = function(self, vector)
            return self.x * vector.x + self.y * vector.y + self.z * vector.z
        end;

        distTo = function(self, vec2)
            local dx = vec2.x - self.x
            local dy = vec2.y - self.y
            local dz = vec2.z - self.z
        
            return math.sqrt(dx * dx + dy * dy + dz * dz)
        end;

        length = function(self)
            local x = self.x
            local y = self.y
            local z = self.z
            
            local number = (x * x + y * y + z * z)
            local i
            local x2, y
            local threehalfs = 1.5
        
            x2 = number * 0.5
            y = number
            i = string.unpack("I4", string.pack("f", y))
            i = 0x5f3759df - (i >> 1)
            y = string.unpack("f", string.pack("I4", i))
            y = y * (threehalfs - (x2 * y * y))
            y = y * (threehalfs - (x2 * y * y))
        
            return 1 / y
        end;

        unitVector = function(self)
            -- Calculate the length of the vector
            local length = self:magnitude();
            
            -- Prevent division by zero
            if length == 0 then return self end
            
            -- Normalize each component
            self.x = self.x / length
            self.y = self.y / length
            self.z = self.z / length
            return self;
        end;

        magnitude = function(self)
            return math.sqrt(self.x * self.x + self.y * self.y + self.z * self.z)
        end;
    };

    create = function(self, x, y , z)
        local returnTable = {};

        setmetatable(returnTable, {
            __index = self.functions
        })

        returnTable.x = x or 0;
        returnTable.y = y or 0;
        returnTable.z = z or 0;

        return returnTable
    end;
};

vector4 = {
    new = function(self, x, y, z, w)
        return {x = x or 0, y = y or 0, z = z or 0, w = w or 0}
    end;

    functions = {
        isValid = function(self)
            return self.x ~= 0 or self.y ~= 0 or self.z ~= 0 or self.w ~= 0;

            --return not number:isBadFloat(self.x) and not number:isBadFloat(self.y) and not number:isBadFloat(self.z);
        end;

        add = function(self, v4)
            return vector4:create(self.x + v4.x, self.y + v4.y, self.z + v4.z, self.w + v4.w)
        end;

        subtract = function(self, v4)
            return vector4:create(self.x - v4.x, self.y - v4.y, self.z - v4.z, self.w - v4.w)
        end;

        multiply = function(self, scalar)
            return vector4:create(self.x * scalar, self.y * scalar, self.z * scalar, self.w * scalar)
        end;

        divide = function(self, scalar)
            if scalar ~= 0 then
                return vector4:create(self.x / scalar, self.y / scalar, self.z / scalar, self.w / scalar)
            else
                return vector4:create(0, 0, 0, 0) -- Return a default vector (could handle error differently)
            end
        end;

        dot = function(self, v4)
            return self.x * v4.x + self.y * v4.y + self.z * v4.z + self.w * v4.w
        end;

        length = function(self)
            return math.sqrt(self.x * self.x + self.y * self.y + self.z * self.z + self.w * self.w)
        end;

        normalize = function(self)
            local length = self:length()
            if length ~= 0 then
                return vector4:create(self.x / length, self.y / length, self.z / length, self.w / length)
            else
                return vector4:create(0, 0, 0, 0) -- Return a default vector (could handle error differently)
            end
        end;

        calculateEulerAngle = function(self)
            local eulerAngles = vector3:create();
        
            -- Extract quaternion components
            local x, y, z, w = self.x, self.y, self.z, self.w
        
            -- Calculate pitch, yaw, and roll (in radians)
            eulerAngles.x = number:atan2(2.0 * x * w + 2.0 * y * z, 1.0 - 2.0 * x * x - 2.0 * z * z)  -- Pitch
            eulerAngles.y = number:atan2(2.0 * y * w + 2.0 * x * z, 1.0 - 2.0 * y * y - 2.0 * z * z)  -- Yaw
            eulerAngles.z = math.asin(2.0 * x * y + 2.0 * z * w)  -- Roll
        
            -- Convert radians to degrees
            eulerAngles.x = eulerAngles.x * (180.0 / math.pi)
            eulerAngles.y = eulerAngles.y * (180.0 / math.pi)
            eulerAngles.z = eulerAngles.z * (180.0 / math.pi)
        
            return eulerAngles
        end
    };

    create = function(self, x, y, z, w)
        local returnTable = {}

        setmetatable(returnTable, {
            __index = self.functions
        })

        returnTable.x = x or 0
        returnTable.y = y or 0
        returnTable.z = z or 0
        returnTable.w = w or 0

        return returnTable
    end;
}

---------- start

memory = {
    NewDllModule = function(self, Base, Size)
        return {
            base = Base,
            size = Size
        }
    end;

    GetDllModule = function(self, captProcess, dllName) 
        local moduleBase , moduleSize = proc.find_module(dllName)
        return self:NewDllModule(moduleBase, moduleSize);
    end;

    resolveRva = function(self, process, Module, InstructionAddress, remove) 
        return process:readInt32(InstructionAddress + remove);
    end;

    resolveClassRva = function(self, process, Module, InstructionAddress, InstructionSize, RvaOffset) 
        return ((InstructionAddress - Module.base) + process:readInt32(InstructionAddress + RvaOffset) + InstructionSize);
    end;
};

---------- start

processSetup = {
    functions = {
        findPattern = function(self, module, pattern)
            return proc.find_signature(module.base,module.size, pattern);
        end;

        findPatternAndResolveRva = function(self, Module, Pattern, isClass, cache)
            if not self.cachedFoundPatterns then
                self.cachedFoundPatterns = {};
            end

            local InstructionAddress = self.cachedFoundPatterns[Pattern.pattern .. Pattern.mask] or proc.find_signature(Module.base,Module.size, Pattern)--self:findPattern(Module, Pattern.pattern, Pattern.mask);
    
            if InstructionAddress == nil or InstructionAddress == 0 then
                return 0;
            end

            if cache then
                self.cachedFoundPatterns[Pattern.pattern .. Pattern.mask] = InstructionAddress;
            end

            if isClass == true then
                local mem = memory:resolveClassRva(self, Module, InstructionAddress, Pattern.size, Pattern.rvaOffset) 
                return mem;
            else
                local mem = memory:resolveRva(self, Module, InstructionAddress, Pattern.add) 
                return mem;
            end
        end;

        processId = function(self)
            return proc.pid();
        end;

        readInt64 = function(self, address)
            if not address or address == 0 then
                return 0;
            end;

            return proc.read_int64(address);
        end;

        readInt32 = function(self, address)
            if not address or address == 0 then
                return 0;
            end;

            return proc.read_int32(address);
        end;

        readInt16 = function(self, address)
            if not address or address == 0 then
                return 0;
            end;

            return proc.read_int16(address);
        end;

        readInt8 = function(self, address)
            if not address or address == 0 then
                return 0;
            end;

            return proc.read_int8(address);
        end;

        readBool = function(self, address)
            if not address or address == 0 then
                return 0;
            end;

            return proc.read_int8(address) == 1 and true or false;
        end;

        writeInt64 = function(self, address, value)
            if not address or address == 0 then
                return 0;
            end;

            return proc.write_int64(address, value);
        end;

        writeInt32 = function(self, address, value)
            if not address or address == 0 then
                return 0;
            end;

            return proc.write_int32(address, value);
        end;

        writeInt16 = function(self, address, value)
            if not address or address == 0 then
                return 0;
            end;

            return proc.write_int16(address, value);
        end;

        writeInt8 = function(self, address, value)
            if not address or address == 0 then
                return 0;
            end;

            return proc.write_int8(address, value);
        end;

        writeBool = function(self, address, value)
            if not address or address == 0 then
                return 0;
            end;

            return proc.read_int8(address, value == true and 1 or 0);
        end;

        readFloat = function(self, address)
            if not address or address == 0 then
                return 0;
            end;

            return proc.read_float(address);
        end;

        writeFloat = function(self, address, value)
            if not address or address == 0 then
                return 0;
            end;

            return proc.write_float(address, value);
        end;

        readDouble = function(self, address)
            if not address or address == 0 then
                return 0;
            end;

            return proc.read_double(address);
        end;

        writeDouble = function(self, address, value)
            if not address or address == 0 then
                return 0;
            end;

            return proc.write_double(address, value);
        end;

        writeWString = function(self, address, value)
            if not address or address == 0 then
                return 0;
            end;

            return proc.write_wide_string(address, value); --  does this even exist?
        end;

        writeString = function(self, address, value)
            if not address or address == 0 then
                return 0;
            end;

            return proc.write_string(address, value);
        end;

        readVector4 = function(self, address)
            if not address or address == 0 then
                return vector4:create();
            end;

            proc.read_to_memory_buffer(address, vector4.buffer, 4 * 0x4)

            if not vector3.buffer or vector3.buffer == 0 then
                return vector4:create();
            end

            local x = m.read_float(vector4.buffer,0)
            local y = m.read_float(vector4.buffer,0x4)
            local z = m.read_float(vector4.buffer,  0x4*2)
            local w = m.read_float(vector4.buffer, 0x4*3)

            return vector4:create(x,y,z,w)
        end;

        writeVector4 = function(self, address, value)
            if not address or address == 0 then
                return false;
            end;

            if value and value.x and value.w then
                proc.write_float(address, value.x)
                proc.write_float(address + 0x4, value.y)
                proc.write_float(address + 0x4*2, value.z)
                proc.write_float(address + 0x4*3, value.w)
                return true;
            end
        end;

        readVector3 = function(self, address)
            if not address or address == 0 then
                return vector3:create();
            end;

            proc.read_to_memory_buffer(address, vector3.buffer, 3 * 0x4)

            if not vector3.buffer or vector3.buffer == 0 then
                return vector3:create();
            end

            local x = m.read_float(vector3.buffer,0)
            local y = m.read_float(vector3.buffer,0x4)
            local z = m.read_float(vector3.buffer,  0x8)

            return vector3:create(x,y,z)
        end;

        writeVector3 = function(self, address, value)
            if not address or address == 0 then
                return false;
            end;

            if value and value.x and value.z then
                proc.write_float(address, value.x)
                proc.write_float(address + 0x4, value.y)
                proc.write_float(address + 0x4*2, value.z)
                return true;
            end
        end;

        readVector2 = function(self, address)
            if not address or address == 0 then
                return vector2:create();
            end;

            proc.read_to_memory_buffer(address, vector2.buffer, 2 * 0x4)

            if not vector2.buffer or vector2.buffer == 0 then
                return vector2:create();
            end

            local x = m.read_float(vector2.buffer,0)
            local y = m.read_float(vector2.buffer,0x4)

            return vector2:create(x,y)
        end;

        writeVector2 = function(self, address, value)
            if not address or address == 0 then
                return false;
            end;

            if value and value.x and value.y then
                proc.write_float(address, value.x)
                proc.write_float(address + 0x4, value.y)
                return true;
            end
        end;

        readFVector4 = function(self, address)
            if not address or address == 0 then
                return vector4:create();
            end;

            proc.read_to_memory_buffer(address, vector4.buffer, 4 * 0x8)

            if not vector4.buffer or vector4.buffer == 0 then
                return vector4:create();
            end

            local x = m.read_double(vector4.buffer,0)
            local y = m.read_double(vector4.buffer,0x8)
            local z = m.read_double(vector4.buffer,  0x8*2)
            local w = m.read_double(vector4.buffer, 0x8*3)

            return vector4:create(x,y,z,w)
        end;

        writeFVector4 = function(self, address, value)
            if not address or address == 0 then
                return false;
            end;

            if value and value.x and value.w then
                proc.write_double(address, value.x)
                proc.write_double(address + 0x8, value.y)
                proc.write_double(address + 0x8*2, value.z)
                proc.write_double(address + 0x8*3, value.w)
                return true;
            end
        end;

        readFVector3 = function(self, address)
            if not address or address == 0 then
                return vector3:create();
            end;

            proc.read_to_memory_buffer(address, vector3.buffer, 3 * 0x8)

            if not vector3.buffer or vector3.buffer == 0 then
                return vector3:create();
            end

            local x = m.read_double(vector3.buffer,0)
            local y = m.read_double(vector3.buffer,0x8)
            local z = m.read_double(vector3.buffer,  0x8*2)

            return vector3:create(x,y,z)
        end;

        writeFVector3 = function(self, address, value)
            if not address or address == 0 then
                return false;
            end;

            if value and value.x and value.z then
                proc.write_double(address, value.x)
                proc.write_double(address + 0x8, value.y)
                proc.write_double(address + 0x8*2, value.z)
                return true;
            end
        end;

        readFVector2 = function(self, address)
            if not address or address == 0 then
                return 0;
            end;

            proc.read_to_memory_buffer(address, vector2.buffer, 2 * 0x8)

            if not vector2.buffer or vector2.buffer == 0 then
                return vector2:create();
            end

            local x = m.read_double(vector2.buffer,0)
            local y = m.read_double(vector2.buffer,0x8)

            return vector2:create(x,y)
        end;

        writeFVector2 = function(self, address, value)
            if not address or address == 0 then
                return false;
            end;

            if value and value.x and value.y then
                proc.write_double(address, value.x)
                proc.write_double(address + 0x8, value.y)
                return true;
            end
        end;

        readFTransform = function(self,Address)
            if Address == 0 then
                return {
                    rotation = 0,
                    translation = 0,
                    scale = 0,
                };
            end

            return {
                rotation = self:readFVector4(Address),
                translation = self:readFVector3(Address + 32),
                scale = self:readFVector3(Address + 64),
            };
        end;

        readFRotator = function(self,Address)
            if Address == 0 then
                return {
                    pitch = 0,
                    yaw = 0,
                    roll = 0,
                };
            end

            proc.read_to_memory_buffer(Address, vector3.buffer, 3 * 0x8)

            return 
            {
                pitch = m.read_double(vector3.buffer,0),
                yaw = m.read_double(vector3.buffer, 0x8),
                roll = m.read_double(vector3.buffer, 16),
            }
        end;

        readIl2cppString = function(self, address, size)
            if address == 0 then
                return nil;
            end

            local base = proc.read_int64(address);
            if base > 0x0000000000001000 and base < 0x00007FFFFFFFFFFF then
                return  proc.read_wide_string(base + 0x14, size or 32);
            end

            return nil, true;
        end;

        readPhrase = function(self, address, size)
            if address == 0 then
                return nil;
            end

            local base = proc.read_int64(address);
            if base ~= 0 then
                return  self:readIl2cppString(base + 0x18, size or 32);
            end

            return nil, true;
        end;

        readChain = function(self, baseAddress, ...)
            local addresses = {...}
            local currentAddress = baseAddress
            
            for _, offset in ipairs(addresses) do
                currentAddress = proc.read_int64(currentAddress + offset)
                if currentAddress == 0 then
                    return nil;
                end
            end
            
            return currentAddress
        end;

        readWString = function(self, address, size)
            if address < 0x0000000000001000 or address > 0x00007FFFFFFFFFFF then
                return "";
            end
            return  proc.read_wide_string(address, size or 54);
        end;

        readString = function(self, address, size)
            return proc.read_string(address, size or 54);
        end;

        readBuffer = function(self, address, buffer, size)
            proc.read_to_memory_buffer(address, buffer, size)
        end;

        readMatrix = function(self, address)

            local newMatrix = matrix4x4:create();

            if not address or address == 0 then
                return newMatrix;
            end

            proc.read_to_memory_buffer(address, matrix4x4.buffer, 16 * 4)



            for i = 1, 4 do
                if not newMatrix[i] then
                    newMatrix[i] = {}
                end

                for j = 1, 4 do
                    local index = (i - 1) * 4 + (j - 1)
                    newMatrix[i][j] = m.read_float(matrix4x4.buffer, index * 4)
                end
            end

            return newMatrix;
        end;

        readTransformPosition = function(self, address)
            if address and address ~= 0 then
                local x,y,z = rust.get_transform_position(address)
                return vector3:create(x,y,z)
            end

            return vector3:create(0,0,0)
        end;

        readTransformRotation = function(self,address)
            local x,y,z,w = Intrin.UnityGetRotationFromTransform(address)
            return vector4:create(x,y,z,w)
        end;

        readKey = function(self, address)
            return 
            {
                ref0 = proc.read_int32(self.process,address),
                ref1 = proc.read_int32(self.process,address + 0x4),
                ref2 = proc.read_int32(address+ 0x8),
            }
        end;

        readRefDef = function(self, Address)
            return {
                x = proc.read_int32(Address);
                y = proc.read_int32(Address + 0x4);
                width = proc.read_int32(Address + 0x8);
                height = proc.read_int32(Address + 0xC);
                view = {
                    fov = {
                        x = proc.read_float(Address + 0x10);
                        y = proc.read_float(Address + 0x10 + 0x4);
                    };
                    axis = {
                        vector3:create(
                            proc.read_float(Address + 0x10 + 0x8 + 0xC),
                            proc.read_float(Address + 0x10 + 0x8 + 0xC + 0x4),
                            proc.read_float(Address + 0x10 + 0x8 + 0xC + 0x8)
                        ),
                        vector3:create(
                            proc.read_float(Address + 0x10 + 0x8 + 0xC + 0xC),
                            proc.read_float(Address + 0x10 + 0x8 + 0xC + 0x10),
                            proc.read_float(Address + 0x10 + 0x8 + 0xC + 0x14)
                        ),
                        vector3:create(
                            proc.read_float(Address + 0x10 + 0x8 + 0xC + 0x18),
                            proc.read_float(Address + 0x10 + 0x8 + 0xC + 0x1C),
                            proc.read_float(Address + 0x10 + 0x8 + 0xC + 0x20)
                        )
                    };
                };
            }
        end;








        readFString = function(self, address, lengths)
            local returnText = nil;
            local text = proc.read_int64(address);

            if text ~= 0 then
                if not lengths then
                    local Length = proc.read_int32(address + 0x8);
                    if Length > 0 and 10000 > Length then
                        returnText = proc.read_wide_string(text,Length)
                    end
                else
                    returnText = proc.read_wide_string(text,lengths or 32)
                end
            end

            if returnText and type(returnText) == "string" and string.len(returnText) > 0 then
                return returnText;
            end

            return "";
        end; --readFText

        readFText = function(self, address, checkLength, lengths)
            local text = proc.read_int64(address);

            if text ~= 0 then
                if checkLength then
                    local Length = proc.read_int32(text + 0x28);
                    local Name = proc.read_int64(text + 0x20);
                    if Length < 63 and Length > 0 and Name ~= 0 then
                        return proc.read_wide_string(Name,Length)
                    end
                else
                    local Name = proc.read_int64(text + 0x20);
                    if Name ~= 0 then
                        return proc.read_wide_string(Name,lengths or 32)
                    end
                end
            end

            return "";
        end;
    };

    createProcess = function(self, processName, modules, options)
        local capturedProcess = nil--Process.Capture(processName);

        --[[if proc.is_attached() then
            if proc.did_exit() then
                return false;
            else
                return true;
            end
        else]]
            local fuckedCr3 = false;
            if (options.cr3) then
                fuckedCr3 = true;
            end

            if proc.attach_by_name(processName, fuckedCr3) then
                local returnTable = {
                    process = capturedProcess;
                    peb = proc.peb();
                    modules = {};
                }

                if modules == true then
                    local modBase, modSize = proc.get_base_module();
                    returnTable.modules.main = {base = modBase, size = modSize;};
                    if returnTable.modules.main.base == 0 or returnTable.modules.main.size == 0 or not returnTable.modules.main.base then
                        --proc.release()
                        watermark.gameStatus = "Waiting For Modules";
                        return false;
                    end
                else
                    for i = 1, #modules do
                        local currentModule = modules[i]
                        
                        if not currentModule then
                            --proc.release()
                            return false
                        end
        
                        local lastDotIndex = currentModule:match("^.*()%.")
                        local moduleName
                        if lastDotIndex then
                            moduleName = currentModule:sub(1, lastDotIndex - 1)
                        else
                            moduleName = currentModule
                        end
                        
                        local modBase, modSize = proc.find_module(currentModule);
                        returnTable.modules[moduleName] = {base = modBase, size = modSize;};
                        if returnTable.modules[moduleName] == nil or returnTable.modules[moduleName].base == 0 then
                            --proc.release()
                            watermark.gameStatus = "Waiting For Modules";
                            return false
                        end
                    end
                end

                setmetatable(returnTable, {
                    __index = self.functions
                })

                return returnTable
            else
                watermark.gameStatus = "Waiting For Game";
            end
        --end

        return false
    end;
}

---------- start

watermark = {
    gameStatus = "Waiting For Game";
    rightPadding = 15;
    topPadding = 8;
    boxOutline = 1;
    boxHorizontalPadding = 6;
    boxVerticalPadding = 4;
    baseOpacity = 222;
    doWatermark = true;

    drawWatermark = function(self)
        if not self.doWatermark then
            return;
        end

        
        local textMX, textMY = render.measure_text(draw.fonts.watermark.font, self.gameStatus)

        local xPosition = (((draw.screenSize.x - textMX) - self.rightPadding) - self.boxOutline) - (self.boxHorizontalPadding);
        local yPosition = 0 + self.topPadding + self.boxOutline;

        local boxSize = textMX + (self.boxHorizontalPadding*2)
        local boxHeight = textMY + self.boxVerticalPadding*2

        render.draw_rectangle(xPosition - self.boxOutline, yPosition - self.boxOutline, boxSize + (self.boxOutline*2), boxHeight + (self.boxOutline*2), 155, 155, 155, self.baseOpacity, 1, true)
        render.draw_rectangle(xPosition, yPosition, boxSize, boxHeight, 33, 33, 33, self.baseOpacity, 1, true)
        drawText(draw.fonts.watermark.font, self.gameStatus, xPosition + (self.boxHorizontalPadding),yPosition + (self.boxVerticalPadding),255,255,255,255)
    end;
};

---------- start

function timer.new(assign)
    local self = {}
    if assign then
        self.lastRunTime = winapi.get_tickcount64()
    else
        self.lastRunTime = 0
    end
    
    function self.getCurrentTime()
        return winapi.get_tickcount64()
    end
    
    function self.update()
        self.lastRunTime = winapi.get_tickcount64()
    end
    
    function self.reset()
        self.lastRunTime = 0
    end
    
    function self.elapsedTime()
        return winapi.get_tickcount64() - self.lastRunTime
    end
    
    function self.check(msDifference)
        local now = winapi.get_tickcount64()
        local elapsed = now - self.lastRunTime
        if elapsed > msDifference then
            self.lastRunTime = now
            return true
        end
        return false
    end
    
    return self
end

---------- start

configs = {
    configPrefix = "--[[ " .. game .. " SUPERNOVA CONFIG ]]-- ";

    cleanPrefix = function(self, input)
        -- Remove patterns of "--[[ anything ]]-- " including optional leading spaces
        return (input:gsub("%s*%-%-%[%[.-%]%]%-%-%s*", ""))
    end;

    getConfigAsTable = function(self, colorsOnly)
        local returnElements = {exportedBy = engine.get_username(), elements = {}, ignoredElements = {}};
        draw:loopElements(function(v, tabName, subtabName, paneName)
            if v.key == 'Disable All Unsafe' then
                return
            end
            
            local loopedTable = {key = v.key}

            if tabName then
                loopedTable.tabName = tabName;
            end
            
            if subtabName then
                loopedTable.subtabName = subtabName;
            end

            if paneName then
                loopedTable.paneName = paneName;
            end

            if v.value.type == drawTypes.label or v.value.type == drawTypes.button then
                return;
            end

            local foundElements = false;

            if colorsOnly then
                if v.value.colorpicker and v.value.colorpicker.value and v.value.colorpicker.value.color and v.value.colorpicker.value.color.r ~= nil then
                    loopedTable.color = {}
                    loopedTable.color.r = v.value.colorpicker.value.color.r;
                    loopedTable.color.g = v.value.colorpicker.value.color.g;
                    loopedTable.color.b = v.value.colorpicker.value.color.b;
                    loopedTable.color.a = v.value.colorpicker.value.color.a;
                    foundElements = true;
                elseif v.value.color and v.value.color.r ~= nil then
                    loopedTable.color = {}
                    loopedTable.color.r = v.value.color.r;
                    loopedTable.color.g = v.value.color.g;
                    loopedTable.color.b = v.value.color.b;
                    loopedTable.color.a = v.value.color.a;
                    foundElements = true;
                end
            else

                if v.value.state ~= nil and (v.value.originalState == nil or v.value.originalState ~= v.value.state) then
                    loopedTable.state = v.value.state;
                    foundElements = true;
                end
                if v.value.hotkey and v.value.hotkey.value and v.value.hotkey.value.shortKeyName ~= nil then
                    if v.value.defaultShortKeyName == nil or v.value.defaultShortKeyName ~= v.value.hotkey.value.shortKeyName then
                        loopedTable.shortKeyName = v.value.hotkey.value.shortKeyName;
                        foundElements = true;
                    end
                elseif v.value.shortKeyName ~= nil then
                    if v.value.defaultShortKeyName == nil or v.value.defaultShortKeyName ~= v.value.shortKeyName then
                        loopedTable.shortKeyName = v.value.shortKeyName;
                        foundElements = true;
                    end
                end
                if v.value.hotkey and v.value.hotkey.value and v.value.hotkey.value.activeKey ~= nil then
                    if v.value.defaultActiveKey == nil or v.value.defaultActiveKey ~= v.value.hotkey.value.activeKey then
                        loopedTable.activeKey = v.value.hotkey.value.activeKey;
                        foundElements = true;
                    end
                elseif v.value.activeKey ~= nil then
                    if v.value.defaultActiveKey == nil or v.value.defaultActiveKey ~= v.value.activeKey then
                        loopedTable.activeKey = v.value.activeKey;
                        foundElements = true;
                    end
                end
                if v.value.hotkey and v.value.hotkey.value and v.value.hotkey.value.keyType ~= nil then
                    if v.value.defaultKeyType == nil or v.value.defaultKeyType ~= v.value.hotkey.value.keyType then
                        loopedTable.keyType = v.value.hotkey.value.keyType;
                        foundElements = true;
                    end
                elseif v.value.keyType ~= nil then
                    if v.value.defaultKeyType == nil or v.value.defaultKeyType ~= v.value.keyType then
                        loopedTable.keyType = v.value.keyType;
                        foundElements = true;
                    end
                end
                if v.value.options and v.value.type == drawTypes.multiselect then
                    local pass = false;

                    if v.value.defaultOptions == nil then
                        pass = true;
                    else
                        for opt1name, opt1 in ipairs(v.value.options) do
                            for opt2name, opt2 in ipairs(v.value.defaultOptions) do
                                if opt1name == opt2name then
                                    if opt2.value ~= opt1.value then
                                        pass = true;
                                    end
                                    break;
                                end
                            end
                        end
                    end

                    if pass then
                        loopedTable.options = {}
                        foundElements = true;
                        for ___, option in ipairs(v.value.options) do
                            if v.value.defaultOptions == nil or (v.value.defaultOptions[___] and v.value.defaultOptions[___].key == option.key and v.value.defaultOptions[___].value == option.value) then
                                table.insert(loopedTable.options, {
                                    key = option.key;
                                    value = option.value;
                                })
                            end
                        end
                    end
                end
                if v.value.colorpicker and v.value.colorpicker.value and v.value.colorpicker.value.color and v.value.colorpicker.value.color.r ~= nil then
                    if v.value.originalColor == nil or (v.value.originalColor.r ~= v.value.colorpicker.value.color.r or v.value.originalColor.g ~= v.value.colorpicker.value.color.g or v.value.originalColor.b ~= v.value.colorpicker.value.color.b or v.value.originalColor.a ~= v.value.colorpicker.value.color.a) then
                        loopedTable.color = {}
                        loopedTable.color.r = v.value.colorpicker.value.color.r;
                        loopedTable.color.g = v.value.colorpicker.value.color.g;
                        loopedTable.color.b = v.value.colorpicker.value.color.b;
                        loopedTable.color.a = v.value.colorpicker.value.color.a;
                        foundElements = true;
                    end
                elseif v.value.color and v.value.color.r ~= nil then
                    if v.value.originalColor == nil or (v.value.originalColor.r ~= v.value.color.r or v.value.originalColor.g ~= v.value.color.g or v.value.originalColor.b ~= v.value.color.b or v.value.originalColor.a ~= v.value.color.a) then
                        loopedTable.color = {}
                        loopedTable.color.r = v.value.color.r;
                        loopedTable.color.g = v.value.color.g;
                        loopedTable.color.b = v.value.color.b;
                        loopedTable.color.a = v.value.color.a;
                        foundElements = true;
                    end
                end
            end

            if foundElements then
                table.insert(returnElements.elements, loopedTable)
            else
                table.insert(returnElements.ignoredElements, loopedTable)
            end

        end, nil)
        return returnElements;
    end;

    setConfigsFromTable = function(self, table)
        if not table.elements then
            return;
        end
        draw:loopElements(function(v, tabName, subtabName, paneName)
            local doIpairs = false; --shit shit shit
            local iterator = getIterator(table.elements)
            for _, configElement in iterator(table.elements) do
            --for _, configElement in doIpairs and ipairs(table.elements) or pairs(table.elements) do
                local elementName = storageSystem:getElementName(tabName, subtabName, paneName, v.key)
                if configElement.key == v.key or elementName == _ then
                    if tabName and configElement.tabName and tabName == configElement.tabName or elementName == _ then
                        if not subtabName and not configElement.subtabName or subtabName and configElement.subtabName and subtabName == configElement.subtabName or elementName == _ then
                            --log('faggotsZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ')
                            if not paneName and not configElement.paneName or paneName and configElement.paneName and paneName == configElement.paneName or elementName == _  then
                                if configElement.key ~= "Disable All Unsafe" and v.key ~= "Disable All Unsafe" and v.value.ignoreConfigs ~= true then
                                    if configElement.state ~= nil then
                                        if v.value.type == drawTypes.checkbox and v.value.callback and v.value.state ~= configElement.state then
                                            v.value.callback(v)
                                        end
                                        if v.value.checkboxType ~= nil and v.value.checkboxType ~= 1 and draw.cachedUiVars.configs.config.disableAllUnsafe.value.state then
                                            v.value.state = false;
                                        else
                                                v.value.state = configElement.state;
                                        end
                                    end
                                    if configElement.shortKeyName ~= nil then
                                        if v.value.hotkey and v.value.hotkey.value and v.value.hotkey.value.shortKeyName then
                                            v.value.hotkey.value.shortKeyName = configElement.shortKeyName;
                                        end
                                    end
                                    if configElement.activeKey ~= nil then
                                        if v.value.hotkey and v.value.hotkey.value and v.value.hotkey.value.activeKey then
                                            v.value.hotkey.value.activeKey = number:cleanStringOffset(configElement.activeKey);
                                        end
                                    end
                                    if configElement.keyType ~= nil then
                                        if v.value.hotkey and v.value.hotkey.value and v.value.hotkey.value.keyType then
                                            v.value.hotkey.value.keyType = configElement.keyType;
                                        else
                                            if v.value.keyType then
                                                v.value.keyType = configElement.keyType;
                                            end
                                        end
                                    end
                                    if configElement.color ~= nil and configElement.color.r ~= nil then
                                        if v.value.colorpicker and v.value.colorpicker.value and v.value.colorpicker.value.color and v.value.colorpicker.value.color.r ~= nil then
                                            v.value.colorpicker.value.color.r = configElement.color.r;
                                            v.value.colorpicker.value.color.g = configElement.color.g;
                                            v.value.colorpicker.value.color.b = configElement.color.b;
                                            v.value.colorpicker.value.color.a = configElement.color.a;
                                        else
                                            if v.value.color and v.value.color.r then
                                                v.value.color.r = configElement.color.r;
                                                v.value.color.g = configElement.color.g;
                                                v.value.color.b = configElement.color.b;
                                                v.value.color.a = configElement.color.a;
                                            end
                                        end
                                    end
                                    if configElement.options then
                                        if v.value.options and v.value.type == drawTypes.multiselect then
                                            for __, configOption in ipairs(configElement.options) do
                                                for ___, option in ipairs(v.value.options) do
                                                    if option.key == configOption.key then
                                                        option.value = configOption.value
                                                        break;
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end;
                                break;
                            end
                        end
                    end
                end
            end
        end, nil)
    end;

    save = function(self)
        local inputText = string.lower(draw.cachedUiVars.configs.config.configName.value.typedText or "");
        local exists = false;

        if string.len(inputText) < 2 then
            notifications:add("Config name too short")
            return
        end

        for _, tab in pairs(draw.cachedUiVars.configs.config.configMenu.value.options) do
            if inputText == string.lower(tab.name) and string.len(inputText) > 1 then
                storageSystem:updateConfig(tab.name);
                exists = true;
                notifications:add("Saved " .. inputText)
                break;
            end
        end;

        if not exists and string.len(inputText) > 1 then
            for _, tab in pairs(draw.cachedUiVars.configs.config.configMenu.value.options) do
                if tab.active then
                    tab.active = false;
                end

                if tab.loaded then
                    tab.loaded = false;
                end
            end;
            if storageSystem:updateConfig(inputText) then
                table.insert(draw.cachedUiVars.configs.config.configMenu.value.options, {active = true, loaded = true, name = inputText})
                notifications:add("Created " .. inputText)
            end
        end
    end;

    loadActive = function(self)
        local hasActive = false;

        for _, tab in pairs(draw.cachedUiVars.configs.config.configMenu.value.options) do
            if tab.active then
                hasActive = true;
                break;
            end
        end

        if hasActive then
            for _, tab in pairs(draw.cachedUiVars.configs.config.configMenu.value.options) do
                if tab.loaded then
                    tab.loaded = false;
                end
            end

            for _, tab in pairs(draw.cachedUiVars.configs.config.configMenu.value.options) do
                if tab.active then
                    local activeConfig = storageSystem:fetchConfig(tab.name);
                    if activeConfig and activeConfig.elements then
                        draw:resetMenuElements();
                        self:setConfigsFromTable(activeConfig);
                        notifications:add("Loaded " .. tab.name);
                    end
                    tab.loaded = true;
                    break;
                end
            end;
        end
    end;

    deleteActive = function(self)
        for i, tab in ipairs(draw.cachedUiVars.configs.config.configMenu.value.options) do
            if tab.active then  
                if storageSystem:deleteConfig(tab.name) then
                    notifications:add("Deleted " .. tab.name)
                    table.remove(draw.cachedUiVars.configs.config.configMenu.value.options, i)
                    draw.cachedUiVars.configs.config.configName.value.typedText = "";
                else
                    notifications:add("Failed to delete " .. tab.name)
                end
                break;
            end
        end;
    end;

    copyToClipboard = function(self)
        self.configPrefix = "--[[ " .. game .. " SUPERNOVA CONFIG ]]-- ";
        local uiElements = encrypt:encrypt(json:stringify(self:getConfigAsTable()), encrypt.keyWord);
        input.set_clipboard(self.configPrefix .. encrypt:base64Encode(uiElements))
        notifications:add("Copied to clipboard")
        --input.set_clipboard(uiElements)
    end;

    copyColorsToClipboard = function(self)
        self.configPrefix = "--[[ " .. game .. " SUPERNOVA CONFIG ]]-- ";
        local uiElements = encrypt:encrypt(json:stringify(self:getConfigAsTable(true)), encrypt.keyWord);
        input.set_clipboard(self.configPrefix .. encrypt:base64Encode(uiElements))
        notifications:add("Copied colors to clipboard")
    end;

    loadFromClipboard = function(self)
        local clipboardText = input.get_clipboard()
        if string.len(clipboardText) > 1 then
            clipboardText = self:cleanPrefix(clipboardText)
            local decodedConfig = encrypt:decrypt(encrypt:base64Decode(clipboardText), encrypt.keyWord)
            --input.set_clipboard(decodedConfig)
            if string.len(decodedConfig) > 1 then
                local parsedConfig = json:parse(decodedConfig);
                if parsedConfig and parsedConfig.elements then
                    draw:resetMenuElements();
                    self:setConfigsFromTable(parsedConfig);
                    if parsedConfig.exportedBy then
                        notifications:add("Loaded config exported by " .. parsedConfig.exportedBy)
                    else
                        notifications:add("Loaded config")
                    end
                end
            else
                notifications:add("Decode fail")
            end
        else
            notifications:add("Clipboard Fail")
        end
    end;
}

---------- start

storageSystem = {
    filename = hash:generateUniqueString(loadedUsername) .. "_.data";

    createStorageFile = function(self)
        local writeData = {
            data = {
                [game] = {
                    disableAllUnsafe = true
                };
                elements = {};
                menuKey = keys.INS.offset;
                radarId = std:generateRandomString(15);
            };
        };
        fs.write_to_file(self.filename, encrypt:base64Encode(json:stringify(writeData)))
    end;

    updateRadarId = function(self, radarId)
        local storageData = self:fetchStorageData();
        if storageData and storageData.data then
            storageData.data.radarId = radarId or std:generateRandomString(15);
            self:updateFile(storageData);
        end
    end;

    handleMenuKey = function(self, element)
        local storageData = self:fetchStorageData();
        if storageData and storageData.data then
            storageData.data.menuKey = element.value.activeKey
        end
        self:updateFile(storageData);
    end;

    updateUnsafe = function(self)
        local storageData = self:fetchStorageData();
        if storageData and storageData.data and storageData.data[game] then
            storageData.data[game].disableAllUnsafe = draw.cachedUiVars.configs.config.disableAllUnsafe.value.state
            self:updateFile(storageData);
        end
        storageData = nil;
    end;

    deleteFontData = function(self, storedFontName)
        local storageData = self:fetchStorageData();
        if storageData and storageData.data and storageData then
            if not storageData.data.font then
                storageData.data.font = {};
            end

            storageData.data.font[storedFontName] = nil;

            self:updateFile(storageData);
        end
        storageData = nil;
    end;

    updateFontData = function(self, fontData, storedFontName)
        local storageData = self:fetchStorageData();
        if storageData and storageData.data and storageData then
            if not storageData.data.font then
                storageData.data.font = {};
            end

            if not storageData.data.font[storedFontName] then
                storageData.data.font[storedFontName] = {};
            end

            for key, value in pairs(fontData) do
                storageData.data.font[storedFontName][key] = value
            end

            self:updateFile(storageData);
        end
        storageData = "";
    end;

    getElementName = function(self, tabName, subtabName, paneName, elementName)
        local returnString = "";
        
        if tabName then
            returnString = returnString .. tabName;
        end
        if subtabName then
            returnString = returnString .. subtabName;
        end
        if paneName then
            returnString = returnString .. paneName;
        end

        return returnString .. (elementName or "");
    end;

    storageStartup = function(self)
        if not fs.does_file_exist(self.filename) then
            self:createStorageFile();
        end

        local storageData = self:fetchStorageData();
        if storageData and storageData.data then
            if not storageData.data[game] then
                storageData.data[game] = {disableAllUnsafe = true};
                self:updateFile(storageData);
            else
                draw.cachedUiVars.configs.config.disableAllUnsafe.value.state = storageData.data[game].disableAllUnsafe
            end

            if storageData.data.radarId then
                self.radarId = storageData.data.radarId;
            end

            local foundConfigs = {};

            for elementName, element in pairs(storageData.data.elements) do
                if element[game] then
                    for configName, config in pairs(element[game]) do
                        if not foundConfigs[configName] then
                            table.insert(draw.cachedUiVars.configs.config.configMenu.value.options, {active = false, name = configName})
                            foundConfigs[configName] = true;
                        end
                    end
                end
            end

            --storageData.data
            for shortName, key in pairs(keys) do
                if key.offset == storageData.data.menuKey then
                    draw.cachedUiVars.configs.config.menuKey.value.shortKeyName = shortName;
                    draw.cachedUiVars.configs.config.menuKey.value.activeKey = key.offset;
                    break;
                end
            end
            
            --[[draw.cachedUiVars.configs.font.fontName.value.typedText = draw.fonts.entityText.name;
            if storageData.data.font then
                for key, value in pairs(storageData.data.font) do
                    if draw.menuFonts[key] then
                        if value.fontName then
                            draw.cachedUiVars.configs.font.fontName.value.typedText = value.fontName;
                        end;
                        if value.fontSize then
                            draw.cachedUiVars.configs.font.fontSize.value.state = value.fontSize;
                        end;
                        draw.fontManager:updateFont(value.fontName or draw.menuFonts[key].name, key, value.fontSize or draw.menuFonts[key].fontSize)
                    end
                end
            end;]]
        end
        storageData = nil;
    end;

    updateFile = function(self, newTable)
        if newTable then
            fs.write_to_file(self.filename, encrypt:base64Encode(json:stringify(newTable)))
        end
    end;

    updateConfig = function(self, configName)
        if not configName or string.len(configName) < 1 then
            return false;
        end

        local storageData, hasGame = self:fetchStorageData();
        if storageData and hasGame and storageData.data.elements then
            local uiElements = configs:getConfigAsTable();
            if uiElements and uiElements.elements then
                local loopCount = 0;
                for k, element in pairs(uiElements.ignoredElements) do
                    local elementName = self:getElementName(element.tabName, element.subtabName, element.paneName, element.key)

                    if elementName and string.len(elementName) > 1 then
                        if storageData.data.elements[elementName] and storageData.data.elements[elementName][game] and storageData.data.elements[elementName][game][configName] then
                            storageData.data.elements[elementName][game][configName] = nil;

                            local count = 0;

                            for configname, config in ipairs(storageData.data.elements[elementName][game]) do
                                count = count + 1;
                            end
                            for configname, config in pairs(storageData.data.elements[elementName][game]) do --???????????????
                                count = count + 1;
                            end

                            if count == 0 then
                                storageData.data.elements[elementName][game] = nil;
                            end
                        end
                    end
                end
                for k, element in pairs(uiElements.elements) do
                    local elementName = self:getElementName(element.tabName, element.subtabName, element.paneName, element.key)

                    if elementName and string.len(elementName) > 1 then
                        if not storageData.data.elements[elementName] then
                            storageData.data.elements[elementName] = {};
                        end
                        if not storageData.data.elements[elementName][game] then
                            storageData.data.elements[elementName][game] = {}
                        end
                        if not storageData.data.elements[elementName][game][configName] then
                            storageData.data.elements[elementName][game][configName] = {}
                        end

                        element.subtabName = nil;
                        element.tabName = nil;
                        element.paneName = nil;
                        element.key = nil;
                        
                        storageData.data.elements[elementName][game][configName] = element
                        loopCount = loopCount + 1;
                    end
                end
                if loopCount > 0 then
                    self:updateFile(storageData);
                    return true;
                else
                    notifications:add('Cant save default config')
                end
            end
        end

        storageData = nil;
        return false;
    end;

    deleteConfig = function(self, configName)
        if not configName or string.len(configName) < 1 then
            return false
        end
    
        local storageData, hasGame = self:fetchStorageData()
        if storageData and hasGame and storageData.data.elements then
            for elementName, element in pairs(storageData.data.elements) do
                if element[game] then
                    for configTableName, configTable in pairs(element[game]) do
                        if configName == configTableName then
                            element[game][configTableName] = nil;
                        end
                    end
                end
               
            end

            self:updateFile(storageData);
            return true
        end
    
        return false
    end;

    fetchStorageData = function(self)
        if fs.does_file_exist(self.filename) then
            local storage = fs.read_from_file(self.filename);
            if storage and string.len(storage) > 1 then
                local decoded = encrypt:base64Decode(storage)
                if string.len(decoded) > 1 then
                    local parsed = json:parse(decoded);
                    if parsed and parsed.data then
                        return parsed, parsed.data[game] ~= nil and true or false;
                    end
                end
            end
        end

        return false
    end;

    fetchConfig = function(self, configName)
        if not configName or string.len(configName) < 1 then
            return nil
        end
    
        local storageData, hasGame = self:fetchStorageData()
        local result = {}
    
        if storageData and hasGame and storageData.data.elements then
            for elementName, gameConfigs in pairs(storageData.data.elements) do
                if gameConfigs[game] then
                    for configLoopName, configTable in pairs(gameConfigs[game]) do
                        if configName == configLoopName then
                            result[elementName] = configTable
                            break;
                        end
                    end
                end
            end
            return {elements = result}
        end
    
        return {}
    end;
}

---------- start

drawTypes = {
    checkbox = 1;
    colorpicker = 2;
    hotkey = 3;
    combobox = 4;
    multiselect = 5;
    slider = 6;
    button = 7;
    optionBox = 8;
    label = 9;
    inputBoxes = 10;
}

draw = {
    fonts = {};
    cachedFonts = {};
    mouseX = 0;
    mouseY = 0;
    mouseDown = false;
    rightMouseDown = false;
    cachedUiVars = {};
    lastPane = false;
    firstPaneC = 0;
    secondPaneC = 0;
    lastParentName = "";
    bitmaps = {};

    createFont = function(self, font_name, size, weight, outline)
        local key = font_name .. "_" .. size
        if self.fonts[key] then
            if outline then
                self.fonts[key].outline = outline;
            end

            return self.fonts[key]
        end
        local font = {name = font_name, size = size, weight = weight or 150}
        local newFont = render.create_font(font.name, font.size, font.weight);
        font.font = newFont;
        font.outline = outline;


        local textMX, textMY = render.measure_text(newFont, "HEIGHT TEXT")
        font.height = textMY;
        self.fonts[key] = font
        return font;
    end;

    updateInformation = function(self)
        self.epaMenuOpen = input.is_menu_open();
        self.mouseX, self.mouseY = input.get_mouse_position();
        self.mouseDown = input.is_key_down(0x01)
        self.rightMouseDown = input.is_key_down(0x02)

        self.menuVars.menuYOffsetTabSecondary = 15;
        self.menuVars.menuYOffsetTab = 15;
        self.menuVars.menuYOffset = 15;
        self.menuVars.menuXOffset = 0;
        self.didScroll = input.get_scroll_delta() ~= 0 and (input.get_scroll_delta() > 0 and 1 or 0) or nil;
        if (not self.firstRun) then
            self.firstRun = true;

            draw.fonts.hotbarText = draw:createFont("Consola.ttf", 14, 150, {
                thickness = 1.7;
            });

            draw.fonts.fuelText = draw:createFont("Consola.ttf", 20, 150, {
                thickness = 3.7;
            });

            draw.fonts.entityText = draw:createFont("Consola.ttf", 9, 150, {
                thickness = 1.7;
            });
            draw.fonts.sliderText = draw:createFont("SegoeUI.ttf", 9);
            draw.fonts.watermark = draw:createFont("verdana.ttf", 15);
            draw.fonts.notifications = draw:createFont("consola.ttf", 15);
            draw.fonts.menu = draw:createFont("verdana.ttf", 11);
            draw.fonts.verticalTab = draw:createFont("verdana.ttf", 20);
            draw.fonts.subtab = draw:createFont("Verdana.ttf", 13);

            local screenX, screenY = render.get_viewport_size();

            self.screenSize = vector2:create(screenX, screenY);
            self.screenCenter = vector2:create(self.screenSize.x/2, self.screenSize.y/2);

            self.menuVars.menuWidth = cheat.menuWidth or self.menuVars.menuWidth;
            self.menuVars.menuHeight = cheat.menuHeight or self.menuVars.menuHeight;
            self.menuVars.menuX = (self.screenSize.x/2) - (self.menuVars.menuWidth/2);
            self.menuVars.menuY = (self.screenSize.y/2) - (self.menuVars.menuHeight/2);

            self.checkboxTypes[1].color = self.menuSizes.checkbox.filledBoxColor;
            self:insertMenuColors(self.menuSizes, "");

            self:checkPaneHeight();
            self:populateAltTable();

            storageSystem:storageStartup();
            self:setupBitmaps();
            --print(json:stringify(draw.cachedUiVars))
            self:setupElementDefaultValues();
        end
    end;






    
    menuSizes = {
        windowPreBorder = {r = 24, g = 24, b = 24, a = 255},
        mainWindowBackground = {r = 18, g = 18, b = 18, a = 255},--{r = 49, g = 51, b = 56, a = 255},
        backgroundStripes = {r = 21, g = 21, b = 21, a = 255},--{r = 12, g = 12, b = 12, a = 255},
        backgroundStripesSecondary = {r = 21, g = 21, b = 21, a = 255},--{r = 12, g = 12, b = 12, a = 255},
        backgroundOutline = {r = 22, g = 22, b = 22, a = 0},

        multiselect = {
            boxSize = {width = 142; height = 18};
            boxOutline = 1;
            padding = {left = 0, top = 5, bottom = 0, right = 0};
            textBoxSpacing = 2;
            boxColor = {r = 77, g = 77, b = 77, a = 255};--{r = 56, g = 133, b = 210, a = 255};
            boxOutlineColor = {r = 35, g = 35, b = 35, a = 255};
            boxDropdownColor = {r = 77, g = 77, b = 77, a = 255};--{r = 30, g = 31, b = 34, a = 255};
            optionHovered = {r = 46, g = 48, b = 53, a = 255};
            selectedOptionColor ={r = 90, g = 159, b = 228, a = 255};
            boxHoverColor = {r = 46, g = 48, b = 53, a = 255};--{r = 49, g = 101, b = 154, a = 255},
        };

        inputBox = {
            boxSize = {width = 142; height = 20};
            boxOutline = 1;
            padding = {left = 0, top = 5, bottom = 0, right = 0};
            boxColor = {r = 77, g = 77, b = 77, a = 255};--{r = 56, g = 133, b = 210, a = 255};
            boxOutlineColor = {r = 35, g = 35, b = 35, a = 255};
            textBoxSpacing = 2;
            typedTextColor = {r = 56, g = 133, b = 210, a = 255};
        };

        subtab = {
            boxSize = {width = 55; height = 24};
            padding = {width = 14, height = 14};
            boxBackground = {r = 56, g = 133, b = 210, a = 255},
            boxBorder = {r = 35, g = 35, b = 35, a = 255},
            boxHover = {r = 49, g = 101, b = 154, a = 255},
            tabActive = {r = 49, g = 101, b = 154, a = 255},
            boxOutline = 2;
        };

        combobox = {
            textBoxSpacing = 2;
            boxSize = {width = 142; height = 18};
            boxOutline = 1;
            padding = {left = 0, top = 5, right = 0, bottom = 0};
            boxColor = {r = 77, g = 77, b = 77, a = 255};--{r = 56, g = 133, b = 210, a = 255};
            boxOutlineColor = {r = 35, g = 35, b = 35, a = 255};
            boxDropdownColor = {r = 77, g = 77, b = 77, a = 255};--{r = 30, g = 31, b = 34, a = 255},
            optionHovered = {r = 46, g = 48, b = 53, a = 255},
            boxHoverColor = {r = 46, g = 48, b = 53, a = 255};--{r = 49, g = 101, b = 154, a = 255},
        };

        button = {
            boxSize = {width = 142; height = 26};
            boxOutline = 1;
            padding = {width = 10, height = 5};
            boxColor = {r = 77, g = 77, b = 77, a = 255};--{r = 56, g = 133, b = 210, a = 255};
            boxOutlineColor = {r = 0, g = 0, b = 0, a = 255};
            boxHoverColor = {r = 46, g = 48, b = 53, a = 255};--{r = 49, g = 101, b = 154, a = 255},
        };

        windowPane = {
            paneBackgroundColor = {r = 37, g = 37, b = 37, a = 255},--{r = 44, g = 45, b = 49, a = 255},
            paneOutlineColor = {r = 60, g = 60, b = 60, a = 255},--{r = 30, g = 31, b = 34, a = 255},
            paneOutline = 2;
            padding = {width = 16, height = 15, middle = 14};
            multiVerticalPadding = 20;
            width = 0;
            textSpecifierElementPadding = 6;
        };
        horizontalTab = {
            boxColor = {r = 27, g = 27, b = 27, a = 255};--{r = 30, g = 31, b = 34, a = 255};
            buttonBorder = {r = 64, g = 66, b = 73, a = 255},
            buttonHovered = {r = 46, g = 48, b = 53, a = 100},
            buttonActive = {r = 49, g = 51, b = 56, a = 255},
            sideBarBackground = {r = 34, g = 34, b = 34, a = 255};--{r = 30, g = 31, b = 34, a = 255},
            boxSize = {width = 1, height = 40};
            padding = {left = 70, top = 0, bottom = 0, right = 70;};
            maxVerticalSize = 525;
            borderColor = {r = 22, g = 22, b = 22, a = 255};--{r = 30, g = 31, b = 34, a = 255};
            borderOutlineColor = {r = 60, g = 60, b = 60, a = 255};--{r = 77, g = 77, b = 77, a = 255};
            borderOutline = 2;
        };
        checkbox = {
            boxSize = {width = 8, height = 8};
            boxOutline = 1;
            padding = {left = 0, top = 5, bottom = 0, right = 0};
            infoBoxHeight = 22;
            infoBoxOutline = 1;
            boxLeftOffset = 5;
            --innerOutline = 0; -- 1
            --innerOutlineColor = {r = 0, g = 0, b = 0, a = 255};
            filledBoxColor = {r = 56, g = 133, b = 210, a = 255};--{r = 56, g = 133, b = 210, a = 255};
            boxColor = {r = 255, g = 255, b = 255, a = 255};
            outlineColor = {r = 0, g = 0, b = 0, a = 255};
            boxHoverColor = {r = 203, g = 203, b = 203, a = 155},
            infoBoxOutlineColor = {r = 0, g = 0, b = 0, a = 255},
            infoBoxColor = {r = 77, g = 77, b = 77, a = 255};--{r = 30, g = 31, b = 34, a = 255},
            clickPadding = {left = 5, up = 1, down = 1, right = 130;}
        };
        label = {
            padding = {top = 5; bottom = 0};
        };
        slider = {
            boxSize = {width = 140, height = 5};
            slideSize = {width = 10, height = 5};
            boxOutline = 1;
            padding = {left = 15, top = 5, right = 0, bottom = 0;};
            textBoxSpacing = 2;
            valueBoxColor = {r = 56, g = 133, b = 210, a = 255};--{r = 35, g = 165, b = 89, a = 255},
            --filledBoxColor = {r = 50, g = 205, b = 50, a = 255};--{r = 56, g = 133, b = 210, a = 255};
            boxColor = {r = 77, g = 77, b = 77, a = 255};--{r = 56, g = 133, b = 210, a = 255},
            boxOutlineColor = {r = 35, g = 35, b = 35, a = 255},
            boxHoverColor = {r = 46, g = 48, b = 53, a = 255};--{r = 49, g = 101, b = 154, a = 255},
            manualInputColor = {r = 65, g = 65, b = 65, a = 255};
        };
        infoBox = {
            boxSize = {width = 176, height = 216};
            boxOutline = 1;
            padding = {left = 0, top = 5, right = 0, bottom = 0;};
            textBoxSpacing = 3;
            boxColor = {r = 77, g = 77, b = 77, a = 255};--{r = 56, g = 133, b = 210, a = 255},
            selectedOptionColor ={r = 90, g = 159, b = 228, a = 255};
            --filledBoxColor = {r = 50, g = 205, b = 50, a = 255};--{r = 56, g = 133, b = 210, a = 255};
            boxOutlineColor = {r = 35, g = 35, b = 35, a = 255},
            boxOptionHover = {r = 46, g = 48, b = 53, a = 255};--{r = 49, g = 101, b = 154, a = 255},
            optionSize = {width = 176; height = 18};
        };
        colorPicker = {
            boxSize = {width = 16, height = 8};
            padding = {width = 10, height = 6};
            outline = 1;
            outlineColor = {r = 0, g = 0, b = 0, a = 255};
            boxHoverColor = {r = 203, g = 203, b = 203, a = 100},
            textBoxSpacing = 8;
        };
        hotkey = {
            textBoxSpacing = 8;
            padding = {width = 10, height = 6};
        };
        selectiveDropdown = {
            dropdownColor = {r = 77, g = 77, b = 77, a = 255};--{r = 30, g = 31, b = 34, a = 255},
            dropdownHoverColor = {r = 46, g = 48, b = 53, a = 255},
            boxSize = {width = 0; height = 18};
            textPadding = {left = 4, right = 4};
            outline = 1;
            outlineColor = {r = 0, g = 0, b = 0, a = 255};
            selectedOptionColor ={r = 90, g = 159, b = 228, a = 255};
        };
    };

    menuVars = {
        menuOpen = true;
        isHovering = false;
        menuX = 0;
        menuY = 0;
        menuWidth = 732;
        menuHeight = 650;
        textSpacer = 22;
        defaultMenuWidth = 732;
        defaultMenuHeight = 650;
        lateDrawCalls = {};
        currentVerticalTab = 3;
        didLeftClick = false;
        wasLeftClicking = false;
        didRightClick = false;
        wasRightClicking = false;
        dragX = 0;
        dragY = 0;
        menuYOffsetTabSecondary = 15;
        menuYOffsetTab = 15;
        menuXOffset = 0;
        openedPicker = "";
        savedColor = nil;
        inputBlocker = 0;
        hues = 0;
        openedCombo = "";
        openedMulti = "";
        openedInputBox = "";
        openedDropdown = "";
        activeHotkey = "";
        leftClickedElementName = "";
        rightClickedElementName = "";
    };

    isHovering = function(self, x, y, width, height)
        if input.is_menu_open() then
            return false;
        end

        if self.mouseX > x and self.mouseY > y then
            if self.mouseX < (x + width) and self.mouseY < (y + height) then
                return true
            end
        end

        return false;
    end;

    handleElement = function(self, element, secondPane)
        if element.visibleRequirement then
            if not element.visibleRequirement() then
                return;
            end
        end

        if element.value.type == drawTypes.checkbox then
            self:drawCheckbox(element, secondPane);
            if element.value.children and element.value.state then
                for _, tab in pairs(element.value.children) do
                    self:handleElement(tab, secondPane);
                end
            end
        end
        if element.value.type == drawTypes.hotkey then
            self:drawHotkey(element, secondPane);
            if element.value.children and element.value.state then
                for _, tab in pairs(element.value.children) do
                    self:handleElement(tab, secondPane);
                end
            end
        end
        if element.value.type == drawTypes.label then
            self:drawLabel(element, secondPane)
        end
        if element.value.type == drawTypes.combobox then
            self:drawCombobox(element, secondPane);
            if element.value.children --[[and element.value.state]] then
                for _, tab in pairs(element.value.children) do
                    if tab.requiredValues ~= nil then
                        for _, requiredValues in pairs(tab.requiredValues) do
                            if requiredValues == element.value.state then
                                self:handleElement(tab, secondPane);
                                break;
                            end
                        end
                    else
                        self:handleElement(tab, secondPane);
                    end
                end
            end
        end
        if element.value.type == drawTypes.button then
            self:drawButton(element, secondPane);
        end
        if element.value.type == drawTypes.colorpicker then
            self:drawColorpicker(element, secondPane);
        end
        if element.value.type == drawTypes.multiselect then
            self:drawMultiselect(element, secondPane);
            if element.value.children then
                for _, tab in pairs(element.value.children) do
                    if tab.requiredValues ~= nil then
                        for _, requiredValues in pairs(tab.requiredValues) do
                            for _, activeValues in pairs(element.value.options) do
                                if activeValues.key == requiredValues then
                                    self:handleElement(tab, secondPane, secondPane);
                                    break;
                                end
                            end
                        end
                    else
                        self:handleElement(tab, secondPane, secondPane);
                    end
                end
            end
        end
        if element.value.type == drawTypes.slider then
            self:drawSlider(element, secondPane);
        end
        if element.value.type == drawTypes.optionBox then
            self:drawOptionBox(element, secondPane);
        end
        if element.value.type == drawTypes.inputBox then
            self:drawInputBox(element, secondPane);
        end
    end;

    checkboxTypes = {
        [1] = { -- normal
            color = {r = 90, g = 159, b = 228, a = 255};
            info = "";
            normal = true;
        };
        [2] = { -- unknown
            color = {r = 240, g = 178, b = 40, a = 255};
            info = "Feature is unsafe/unknown";
        };
        [3] = { -- likely ban
            color = {r = 255, g = 0, b = 0, a = 255};
            info = "Very likely ban";
        };
        [4] = { -- server admin unsafe
            color = {r = 0, g = 191, b = 255, a = 255};
            info = "Detected by server admins";
        };
        [5] = { -- writes to memory
            color = {r = 200, g = 50, b = 0, a = 255};
            info = "Writes To Memory";
        };
    };

    resetMenuElements = function(self)
        draw:loopElements(function(v, tabName, subtabName, paneName)
            if v.key == 'Disable All Unsafe' then
                return;
            end
            if v.value.originalState ~= nil then
                v.value.state = v.value.originalState;
            end
            if v.value.defaultShortKeyName ~= nil then
                if v.value.hotkey and v.value.hotkey.value then
                    v.value.hotkey.value.shortKeyName = v.value.defaultShortKeyName;
                else
                    v.value.shortKeyName = v.value.defaultShortKeyName;
                end
            end
            if v.value.defaultActiveKey ~= nil then
                if v.value.hotkey and v.value.hotkey.value then
                    v.value.hotkey.value.activeKey = v.value.defaultActiveKey;
                else
                    v.value.activeKey = v.value.defaultActiveKey;
                end
            end
            if v.value.defaultKeyType ~= nil then
                if v.value.hotkey and v.value.hotkey.value then
                    v.value.hotkey.value.keyType = v.value.defaultKeyType;
                else
                    v.value.keyType = v.value.defaultKeyType;
                end
            end
            if v.value.defaultOptions and v.value.type == drawTypes.multiselect then
                v.value.options = {}
                for ___, option in ipairs(v.value.defaultOptions) do
                    table.insert(v.value.options, {
                        key = option.key;
                        value = option.value;
                    })
                end
            end
            if v.value.originalColor ~= nil then
                if v.value.colorpicker and v.value.colorpicker.value and v.value.colorpicker.value.color then
                    v.value.colorpicker.value.color.r = v.value.originalColor.r;
                    v.value.colorpicker.value.color.g = v.value.originalColor.g;
                    v.value.colorpicker.value.color.b = v.value.originalColor.b;
                    v.value.colorpicker.value.color.a = v.value.originalColor.a;
                elseif v.value.color then
                    v.value.color.r = v.value.originalColor.r;
                    v.value.color.g = v.value.originalColor.g;
                    v.value.color.b = v.value.originalColor.b;
                    v.value.color.a = v.value.originalColor.a;
                end
            end
        end);
    end;

    
    addLateCall = function(self, func, ...)
        table.insert(self.menuVars.lateDrawCalls, {func, ...})
    end;

    HSVtoRGB = function(self, hue, saturation, value)
        local hi = math.floor(hue / 60.0) % 6
        local f = (hue / 60.0) - hi
        local p = value * (1.0 - saturation)
        local q = value * (1.0 - f * saturation)
        local t = value * (1.0 - (1.0 - f) * saturation)
        local r, g, b
    
        if hi == 0 then
            r, g, b = value, t, p
        elseif hi == 1 then
            r, g, b = q, value, p
        elseif hi == 2 then
            r, g, b = p, value, t
        elseif hi == 3 then
            r, g, b = p, q, value
        elseif hi == 4 then
            r, g, b = t, p, value
        elseif hi == 5 then
            r, g, b = value, p, q
        end
    
        return r, g, b
    end,

    callLateFunctions = function(self)
        for _, entry in ipairs(self.menuVars.lateDrawCalls) do
            local func = entry[1]
            table.remove(entry, 1)
            func(table.unpack(entry)) --table.unpack?
        end
        clearTable(self.menuVars.lateDrawCalls)
    end;

    cleanKeyName = function(self, keyName)
        local cleanName = keyName:gsub("%W", "")
        if cleanName:match("^%d") then
            cleanName = "" .. cleanName
        end
        cleanName = cleanName:sub(1, 1):lower() .. cleanName:sub(2)
        return cleanName
    end;

    cumInTable = function(self, element, tabname, subtabName)
        if not self.cachedUiVars[string.lower(tabname)] then
            self.cachedUiVars[string.lower(tabname)] = {};
        end
        if subtabName then
            if not self.cachedUiVars[string.lower(tabname)][string.lower(subtabName)] then
                self.cachedUiVars[string.lower(tabname)][string.lower(subtabName)] = {};
            end
            self.cachedUiVars[string.lower(tabname)][string.lower(subtabName)][self:cleanKeyName(element.key)] = element;
        else
            self.cachedUiVars[string.lower(tabname)][self:cleanKeyName(element.key)] = element;
        end
    end;

    insertMenuColors = function(self, loopTable, parentName) --auto creates ui elements for menu
        for name, color in pairs(loopTable) do
            if type(color) == "table" then
                if color.r and color.g and color.b and color.a then
                    --prolly shouldnt loop over and over like this
                    for _, tab in ipairs(cheat.menuElements) do
                        if tab.menuSubtabs and tab.tabName == "Configs" then
                            for _, subTab in ipairs(tab.menuSubtabs) do
                                --[[if subTab.elements and subTab.subtabName == "Colors" then
                                    local insertName = "" .. name;
                                    local secondPane = false;

                                    if string.len(parentName) > 0 then
                                        insertName = parentName .. " " .. name;
                                    end

                                    if self.lastParentName == parentName then
                                        secondPane = self.lastPane
                                    else
                                        --secondPane = not self.lastPane
                                        if self.secondPaneC >= self.firstPaneC then
                                            secondPane = true
                                        else
                                            secondPane = false
                                        end
                                    end

                                    if secondPane then
                                        self.firstPaneC = self.firstPaneC + 1
                                    else
                                        self.secondPaneC = self.secondPaneC + 1;
                                    end
                                    
                                    self.lastPane = secondPane;
                                    self.lastParentName = parentName;

                                    table.insert(subTab.elements, {
                                        key = insertName;
                                        value = {
                                            type = drawTypes.colorpicker;
                                            secondPane = secondPane;
                                            color = color;
                                        };
                                    })
                                    break;
                                end]]
                            end
                            break;
                        end
                    end
                else
                    if parentName == "" then
                        self:insertMenuColors(color, name)
                    end
                end
            end
        end
    end;

    loopElements = function(self, elementCallback, paneCallback, altLoop, tabName, subtabName, paneName)
        for _, v in pairs(altLoop or cheat.menuElements) do
            if type(v) == "table" then
                if v.tabName then
                    tabName = v.tabName;
                end
                if v.subtabName then
                    subtabName = v.subtabName;
                end
                if v.paneName then
                    paneName = v.paneName;
                end
                if v.key ~= nil and v.value ~= nil then
                    if elementCallback and v then
                        elementCallback(v, tabName, subtabName, paneName);
                    end

                    if v.value.children then
                        self:loopElements(elementCallback, paneCallback, v.value.children, tabName, subtabName, paneName);
                    end
                else
                    if paneCallback then
                        if v.leftPanes then
                            paneCallback(v.leftPanes)
                        end
                        if v.rightPanes then
                            paneCallback(v.rightPanes)
                        end;
                    end

                    self:loopElements(elementCallback, paneCallback, v, tabName, subtabName, paneName)
                end
            end
        end
    end;

    simulateElementHeight = function(self, element, rightPane)
        local totalHeight = 0
        --local basePadding = 10  -- example padding

        if element.visibleRequirement then
            if not element.visibleRequirement() then
                return;
            end
        end

        if element.copy then
            return;
        end
    
        if element.value.type == drawTypes.checkbox then
            --totalHeight = totalHeight + self.menuSizes.checkbox.boxSize.height + self.menuSizes.checkbox.padding.top + (self.menuSizes.checkbox.boxOutline*2)
            totalHeight = totalHeight + self:drawCheckbox(element, rightPane ~= nil and rightPane or false, true);
        elseif element.value.type == drawTypes.slider then
            --[[totalHeight = totalHeight + self.menuSizes.slider.boxSize.height + self.menuSizes.slider.padding.top
            if element.value.doText then
                totalHeight = totalHeight + draw.fonts.menu.height + self.menuSizes.slider.textBoxSpacing
            end]]
            totalHeight = totalHeight + self:drawSlider(element, rightPane ~= nil and rightPane or false, true);
        elseif element.value.type == drawTypes.multiselect then
            --[[totalHeight = totalHeight + self.menuSizes.multiselect.boxSize.height + self.menuSizes.multiselect.padding.top
            if element.value.options and #element.options > 0 then
                totalHeight = totalHeight + (#element.options * self.menuSizes.multiselect.boxSize.height)
            end]]
            totalHeight = totalHeight + self:drawMultiselect(element, rightPane ~= nil and rightPane or false, true);
        elseif element.value.type == drawTypes.button then
            totalHeight = totalHeight + self:drawButton(element, rightPane ~= nil and rightPane or false, true);
        elseif element.value.type == drawTypes.combobox then
            totalHeight = totalHeight + self:drawCombobox(element, rightPane ~= nil and rightPane or false, true);
        elseif element.value.type == drawTypes.optionBox then
            totalHeight = totalHeight + self:drawOptionBox(element, rightPane ~= nil and rightPane or false, true);
        elseif element.value.type == drawTypes.hotkey then
            totalHeight = totalHeight + self:drawHotkey(element, rightPane ~= nil and rightPane or false, nil, nil, nil, true); --drawHotkey = function(self, element, secondPane, fromCheckbox, passedPos, hasColorPicker, simulation)
        elseif element.value.type == drawTypes.colorpicker then --element, secondPane, fromCheckbox, passedPos, simulation
            totalHeight = totalHeight + self:drawColorpicker(element, rightPane ~= nil and rightPane or false, nil, nil, true);
        elseif element.value.type == drawTypes.label then
            totalHeight = totalHeight + self:drawLabel(element, rightPane ~= nil and rightPane or false, true);
        elseif element.value.type == drawTypes.inputBox then
            totalHeight = totalHeight + self:drawInputBox(element, rightPane ~= nil and rightPane or false, true);
        end
    
        return totalHeight
    end;

    checkPaneHeight = function(self, childrenLoop, pane)
        if childrenLoop then
            local returnHeight = 0;
            for __, element in ipairs(childrenLoop) do
                returnHeight = returnHeight + self:simulateElementHeight(element, pane)
                if element.value.children then
                    returnHeight = returnHeight + self:checkPaneHeight(element.value.children, pane)
                end
            end
            return returnHeight;
        else
            for _, tab in ipairs(cheat.menuElements) do
                if tab.menuSubtabs then
                    for _, subTab in ipairs(tab.menuSubtabs) do
                        if not subTab.copy then
                            if subTab.leftPanes then
                                for _, pane in ipairs(subTab.leftPanes) do
                                    local paneHeight = 0
                                    if pane.elements then
                                        for __, element in ipairs(pane.elements) do
                                            if not element.copy then
                                                paneHeight = paneHeight + self:simulateElementHeight(element, false)
                                                if element.value.children then paneHeight = paneHeight + self:checkPaneHeight(element.value.children, false); end
                                            end
                                        end
                                    end
                                    if pane.autoAdjustForElements and paneHeight ~= 0 then
                                        pane.height = paneHeight + self.menuSizes.windowPane.textSpecifierElementPadding + self.menuSizes.windowPane.paneOutline + 12;
                                    end;
                                end
                            end
                            if subTab.rightPanes then
                                for _, pane in ipairs(subTab.rightPanes) do
                                    local paneHeight = 0
                                    if pane.elements then
                                        for __, element in ipairs(pane.elements) do
                                            if not element.copy then
                                                paneHeight = paneHeight + self:simulateElementHeight(element, true)
                                                if element.value.children then paneHeight = paneHeight + self:checkPaneHeight(element.value.children, true); end
                                            end
                                        end
                                    end
                                    if pane.autoAdjustForElements and paneHeight ~= 0 then
                                        pane.height = paneHeight + self.menuSizes.windowPane.textSpecifierElementPadding + self.menuSizes.windowPane.paneOutline + 12;
                                    end;
                                end
                            end
                        end
                    end
                else
                    if tab.leftPanes then
                        for _, pane in ipairs(tab.leftPanes) do
                            local paneHeight = 0
                            if pane.elements then
                                for __, element in ipairs(pane.elements) do
                                    paneHeight = paneHeight + self:simulateElementHeight(element, false)
                                    if element.value.children then paneHeight = paneHeight + self:checkPaneHeight(element.value.children, false); end
                                end
                            end
                            if pane.autoAdjustForElements and paneHeight ~= 0 then
                                pane.height = paneHeight + self.menuSizes.windowPane.textSpecifierElementPadding + self.menuSizes.windowPane.paneOutline + 12;
                            end;
                        end
                    end
                    if tab.rightPanes then
                        for _, pane in ipairs(tab.rightPanes) do
                            local paneHeight = 0
                            if pane.elements then
                                for __, element in ipairs(pane.elements) do
                                    paneHeight = paneHeight + self:simulateElementHeight(element, true)
                                    if element.value.children then paneHeight = paneHeight + self:checkPaneHeight(element.value.children, true); end
                                end
                            end
                            if pane.autoAdjustForElements and paneHeight ~= 0 then
                                pane.height = paneHeight + self.menuSizes.windowPane.textSpecifierElementPadding + self.menuSizes.windowPane.paneOutline + 12;
                            end;
                        end
                    end
                end
            end
        end;
    end;

    populateAltTable = function(self)
        self.cachedUiVars = {};
        draw:loopElements(function(v, tabName, subtabName, paneName)
            self:cumInTable(v, self:cleanKeyName(tabName), (subtabName ~= nil and subtabName ~= "") and self:cleanKeyName(subtabName) or nil)
        end, nil)
    end;

    setupBitmaps = function(self)
        for _, tab in ipairs(cheat.menuElements) do
            if tab.bitmap and not _debug then
                --tab.bitmap.bit = mapFromUrl(tab.bitmap.url)
            end
        end
    end;

    setupElementDefaultValues = function(self)
        draw:loopElements(function(v, tabName, subtabName, paneName)
            if v.value.state ~= nil then
                v.value.originalState = v.value.state;
            end

            if v.value.hotkey and v.value.hotkey.value and v.value.hotkey.value.shortKeyName ~= nil then
                v.value.defaultShortKeyName = v.value.hotkey.value.shortKeyName;
            elseif v.value.shortKeyName ~= nil then
                v.value.defaultShortKeyName = v.value.shortKeyName;
            end
            if v.value.hotkey and v.value.hotkey.value and v.value.hotkey.value.activeKey ~= nil then
                v.value.defaultActiveKey = v.value.hotkey.value.activeKey;
            elseif v.value.activeKey ~= nil then
                v.value.defaultActiveKey = v.value.activeKey;
            end
            if v.value.hotkey and v.value.hotkey.value and v.value.hotkey.value.keyType ~= nil then
                v.value.defaultKeyType = v.value.hotkey.value.keyType;
            elseif v.value.keyType ~= nil then
                v.value.defaultKeyType = v.value.keyType;
            end
            if v.value.options and v.value.type == drawTypes.multiselect then
                v.value.defaultOptions = {}
                for ___, option in ipairs(v.value.options) do
                    table.insert(v.value.defaultOptions, {
                        key = option.key;
                        value = option.value;
                    })
                end
            end
            if v.value.colorpicker and v.value.colorpicker.value and v.value.colorpicker.value.color and v.value.colorpicker.value.color.r ~= nil then
                v.value.originalColor = {}
                v.value.originalColor.r = v.value.colorpicker.value.color.r;
                v.value.originalColor.g = v.value.colorpicker.value.color.g;
                v.value.originalColor.b = v.value.colorpicker.value.color.b;
                v.value.originalColor.a = v.value.colorpicker.value.color.a;
            elseif v.value.color and v.value.color.r ~= nil then
                v.value.originalColor = {}
                v.value.originalColor.r = v.value.color.r;
                v.value.originalColor.g = v.value.color.g;
                v.value.originalColor.b = v.value.color.b;
                v.value.originalColor.a = v.value.color.a;
            end
        end);
    end;

    
    clearOpenables = function(self)
        self.menuVars.openedPicker = "";
        self.menuVars.openedCombo = "";
        self.menuVars.openedMulti = "";
        self.menuVars.openedDropdown = "";
        self.menuVars.activeHotkey = "";
        self.menuVars.inputBlocker = 0;
        self.menuVars.openedInputBox = "";
    end;

    drawSelectiveDropdown = function(self, element, options, position, hovered)
        if hovered then
            if self:didClick(2, element.key) and self.menuVars.inputBlocker == 0 then
                self.menuVars.openedDropdown = element.key;
                self.menuVars.inputBlocker = self.menuVars.inputBlocker + 1;
            end
        end
        
        if self.menuVars.openedDropdown == element.key then
            local i = 1;
            local longestOption = 0;
            local entryCount = 0;

            position.x = position.x + self.menuSizes.selectiveDropdown.outline;

            for _, option in ipairs(options) do
                local textLength = render.measure_text(draw.fonts.menu.font, option.key)
                if textLength > longestOption then
                    longestOption = textLength;
                end
                entryCount = entryCount + 1
            end

            local dropdownSize = {
                width = longestOption + (self.menuSizes.selectiveDropdown.textPadding.left + self.menuSizes.selectiveDropdown.textPadding.right);
                height = self.menuSizes.selectiveDropdown.boxSize.height
            }


            local anyHovered = false;

            self:addLateCall(render.draw_rectangle,  position.x - self.menuSizes.selectiveDropdown.outline, position.y - self.menuSizes.selectiveDropdown.outline, dropdownSize.width + (self.menuSizes.selectiveDropdown.outline*2), (entryCount*dropdownSize.height) + (self.menuSizes.selectiveDropdown.outline*2), self.menuSizes.selectiveDropdown.outlineColor.r, self.menuSizes.selectiveDropdown.outlineColor.g, self.menuSizes.selectiveDropdown.outlineColor.b, self.menuSizes.selectiveDropdown.outlineColor.a, 1, true)

            for _, option in ipairs(options) do
                local optionPosition = { x = position.x, y = position.y + (i - 1) * dropdownSize.height };
               
                self:addLateCall(render.draw_rectangle,  optionPosition.x, optionPosition.y, dropdownSize.width, dropdownSize.height, self.menuSizes.selectiveDropdown.dropdownColor.r, self.menuSizes.selectiveDropdown.dropdownColor.g, self.menuSizes.selectiveDropdown.dropdownColor.b, self.menuSizes.selectiveDropdown.dropdownColor.a, 1, true)
                
                local optionHovered = self:isHovering(optionPosition.x, optionPosition.y, dropdownSize.width, dropdownSize.height);
                if optionHovered and not self.menuVars.isHovering then
                    anyHovered = true;
                    self:addLateCall(render.draw_rectangle,  optionPosition.x, optionPosition.y, dropdownSize.width, dropdownSize.height, self.menuSizes.selectiveDropdown.dropdownHoverColor.r, self.menuSizes.selectiveDropdown.dropdownHoverColor.g, self.menuSizes.selectiveDropdown.dropdownHoverColor.b, self.menuSizes.selectiveDropdown.dropdownHoverColor.a, 1, true)
                    if self:didClick(1, element.key) then
                        option.callback(element, option.key)
                        self.menuVars.openedDropdown = "";
                        self.menuVars.inputBlocker = self.menuVars.inputBlocker - 1;
                    end
                    self.menuVars.isHovering = true;
                end
                if option.active then
                    self:addLateCall(draw.dText, draw, draw.fonts.menu.font, option.key, optionPosition.x + self.menuSizes.selectiveDropdown.textPadding.left, optionPosition.y + (draw.fonts.menu.height/2), self.menuSizes.selectiveDropdown.selectedOptionColor.r, self.menuSizes.selectiveDropdown.selectedOptionColor.g, self.menuSizes.selectiveDropdown.selectedOptionColor.b, self.menuSizes.selectiveDropdown.selectedOptionColor.a, false)
                else
                    self:addLateCall(draw.dText, draw, draw.fonts.menu.font, option.key, optionPosition.x + self.menuSizes.selectiveDropdown.textPadding.left, optionPosition.y + (draw.fonts.menu.height/2), 255, 255, 255, 255, false)
                end

                i = i + 1;
            end

            if not anyHovered and (self:didClick(1, element.key or self:didClick(2, element.key))) then
                self.menuVars.openedDropdown = "";
                self.menuVars.inputBlocker = self.menuVars.inputBlocker - 1;
            end
        end
    end;

    dText = function(self, font, text, x, y, red, green, blue, alpha, centered, outline, boundingBoxCheck)
        if string.len(text) == 0 then
            return;
        end

        local textLength, textHeight = render.measure_text(font, text);

        if centered then
            if outline then
                render.draw_text(font, text, (x - (textLength/2)) - 1, y - 1, 0, 0, 0, alpha, 0, 0, 0, 0, 0)
                render.draw_text(font, text, (x - (textLength/2)) + 1, y + 1, 0, 0, 0, alpha, 0, 0, 0, 0, 0)
            end
            render.draw_text(font, text, x - (textLength/2), y, red, green, blue, alpha, 0, 0, 0, 0, 0)
        else
            if outline then
                render.draw_text(font, text, (x) - 1, y - 1, 0, 0, 0, alpha, 0, 0, 0, 0, 0)
                render.draw_text(font, text, (x) + 1, y + 1, 0, 0, 0, alpha, 0, 0, 0, 0, 0)
            end
            render.draw_text(font, text, x, y, red, green, blue, alpha, 0, 0, 0, 0, 0)
        end
    end;

    drawVerticalTabs = function(self)
        local selectedTab = self.menuVars.currentVerticalTab

        local startX = self.menuVars.menuX + self.menuSizes.horizontalTab.padding.left
        local endX = self.menuVars.menuX + self.menuVars.menuWidth - self.menuSizes.horizontalTab.padding.right
        local startY = self.menuVars.menuY
    
        local totalWidth = endX - startX
        local tabCount = #cheat.menuElements
        local tabWidth = totalWidth / tabCount
        local tabHeight = self.menuSizes.horizontalTab.boxSize.height -- height of each tab button

        




        render.draw_rectangle(self.menuVars.menuX, startY, self.menuVars.menuWidth, tabHeight, 
        self.menuSizes.horizontalTab.boxColor.r, 
        self.menuSizes.horizontalTab.boxColor.g, 
        self.menuSizes.horizontalTab.boxColor.b, 
        self.menuSizes.horizontalTab.boxColor.a, 1, true)

        render.draw_rectangle(self.menuVars.menuX, startY + tabHeight, self.menuSizes.horizontalTab.padding.left, self.menuSizes.horizontalTab.borderOutline,
        self.menuSizes.horizontalTab.borderOutlineColor.r,
        self.menuSizes.horizontalTab.borderOutlineColor.g,
        self.menuSizes.horizontalTab.borderOutlineColor.b,
        self.menuSizes.horizontalTab.borderOutlineColor.a, 1, true)

        render.draw_rectangle(endX, startY + tabHeight, self.menuSizes.horizontalTab.padding.left, self.menuSizes.horizontalTab.borderOutline,
        self.menuSizes.horizontalTab.borderOutlineColor.r,
        self.menuSizes.horizontalTab.borderOutlineColor.g,
        self.menuSizes.horizontalTab.borderOutlineColor.b,
        self.menuSizes.horizontalTab.borderOutlineColor.a, 1, true)
    
        for index, tab in ipairs(cheat.menuElements) do
            local x = startX + (index - 1) * tabWidth
            local y = startY
            local isHovered = self:isHovering(x, y, tabWidth, tabHeight)

            if self.menuVars.currentVerticalTab == index then
                render.draw_rectangle(x, y, tabWidth, tabHeight, 
                self.menuSizes.mainWindowBackground.r, 
                self.menuSizes.mainWindowBackground.g, 
                self.menuSizes.mainWindowBackground.b, 
                self.menuSizes.mainWindowBackground.a, 1, true)
            end

            if isHovered then
                self.menuVars.isHovering = true
                if self:didClick(1, tab.tabName) then
                    selectedTab = index
                    self:clearOpenables()
                end
        
                -- Hover background
                render.draw_rectangle(x, y, tabWidth, tabHeight, 
                    self.menuSizes.horizontalTab.buttonHovered.r, 
                    self.menuSizes.horizontalTab.buttonHovered.g, 
                    self.menuSizes.horizontalTab.buttonHovered.b, 
                    self.menuSizes.horizontalTab.buttonHovered.a, 1, true)
        
                if self.menuVars.currentVerticalTab == index then
                    -- Left + Right border for selected
                end
            end

            if self.menuVars.currentVerticalTab == index then
                if index ~= 1 then
                    render.draw_rectangle(x, y, self.menuSizes.horizontalTab.borderOutline, tabHeight + self.menuSizes.horizontalTab.borderOutline,
                    self.menuSizes.horizontalTab.borderOutlineColor.r,
                    self.menuSizes.horizontalTab.borderOutlineColor.g,
                    self.menuSizes.horizontalTab.borderOutlineColor.b,
                    self.menuSizes.horizontalTab.borderOutlineColor.a, 1, true)
                else
                    render.draw_rectangle(startX - self.menuSizes.horizontalTab.borderOutline, startY, self.menuSizes.horizontalTab.borderOutline, tabHeight + self.menuSizes.horizontalTab.borderOutline,
                    self.menuSizes.horizontalTab.borderOutlineColor.r,
                    self.menuSizes.horizontalTab.borderOutlineColor.g,
                    self.menuSizes.horizontalTab.borderOutlineColor.b,
                    self.menuSizes.horizontalTab.borderOutlineColor.a, 1, true)
                end
        
                if index ~= tabCount then
                    render.draw_rectangle(x + tabWidth - self.menuSizes.horizontalTab.borderOutline, startY, self.menuSizes.horizontalTab.borderOutline, tabHeight + self.menuSizes.horizontalTab.borderOutline,
                    self.menuSizes.horizontalTab.borderOutlineColor.r,
                    self.menuSizes.horizontalTab.borderOutlineColor.g,
                    self.menuSizes.horizontalTab.borderOutlineColor.b,
                    self.menuSizes.horizontalTab.borderOutlineColor.a, 1, true)
                else
                    render.draw_rectangle(startX + totalWidth, startY, self.menuSizes.horizontalTab.borderOutline, tabHeight + self.menuSizes.horizontalTab.borderOutline,
                    self.menuSizes.horizontalTab.borderOutlineColor.r,
                    self.menuSizes.horizontalTab.borderOutlineColor.g,
                    self.menuSizes.horizontalTab.borderOutlineColor.b,
                    self.menuSizes.horizontalTab.borderOutlineColor.a, 1, true)
                end
            else
                render.draw_rectangle(x, y + tabHeight, tabWidth, self.menuSizes.horizontalTab.borderOutline, 
                    self.menuSizes.horizontalTab.borderOutlineColor.r, 
                    self.menuSizes.horizontalTab.borderOutlineColor.g, 
                    self.menuSizes.horizontalTab.borderOutlineColor.b, 
                    self.menuSizes.horizontalTab.borderOutlineColor.a, 1, true)
            end
    
            -- Draw bitmap or text
            local centerX = x + (tabWidth / 2)
            local centerY = y + (tabHeight / 2)
    
            if tab.bitmap and tab.bitmap.bit and not _debug then
                local bitmapWidth = tab.bitmap.width
                local bitmapHeight = tab.bitmap.height
                local bitmapPosX = (centerX - (bitmapWidth / 2)) - 2
                local bitmapPosY = centerY - (bitmapHeight / 2)
    
                render.draw_bitmap(tab.bitmap.bit, bitmapPosX, bitmapPosY, bitmapWidth, bitmapHeight, 
                    tab.bitmap.r or 255, tab.bitmap.g or 255, tab.bitmap.b or 255, tab.bitmap.a or 255, tab.bitmap.a or 255)
            else
                draw:dText(draw.fonts.verticalTab.font, tab.tabName, 
                    centerX - self.menuSizes.horizontalTab.borderOutline, 
                    centerY - (draw.fonts.verticalTab.height / 2), 
                    255, 255, 255, 255, true)
            end
        end
    
        self.menuVars.menuYOffset = self.menuVars.menuYOffset + tabHeight + 2 ;
        self.menuVars.menuYOffsetTab = self.menuVars.menuYOffsetTab + tabHeight + 2
        self.menuVars.menuYOffsetTabSecondary = self.menuVars.menuYOffsetTabSecondary + tabHeight + 2
        self.menuVars.menuXOffset = self.menuVars.menuXOffset + 4;
    

        --[[self.menuVars.menuXOffset = self.menuVars.menuXOffset + self.menuSizes.horizontalTab.boxSize.width + self.menuSizes.horizontalTab.borderOutline -- + self.menuSizes.horizontalTab.padding.right
    
        local startY = self.menuVars.menuY + self.menuSizes.horizontalTab.padding.top
        local endY = (self.menuVars.menuY + self.menuVars.menuHeight) - self.menuSizes.horizontalTab.padding.bottom
        local totalYSize = endY - startY
    
        render.draw_rectangle(self.menuVars.menuX , self.menuVars.menuY, self.menuSizes.horizontalTab.boxSize.width, self.menuSizes.horizontalTab.padding.top, self.menuSizes.horizontalTab.borderOutlineColor.r, self.menuSizes.horizontalTab.borderOutlineColor.g, self.menuSizes.horizontalTab.borderOutlineColor.b, self.menuSizes.horizontalTab.borderOutlineColor.a, 1, true)
        render.draw_rectangle(self.menuVars.menuX, self.menuVars.menuY, self.menuSizes.horizontalTab.boxSize.width - (self.menuSizes.horizontalTab.borderOutline), self.menuSizes.horizontalTab.padding.top, self.menuSizes.horizontalTab.borderColor.r, self.menuSizes.horizontalTab.borderColor.g, self.menuSizes.horizontalTab.borderColor.b, self.menuSizes.horizontalTab.borderColor.a, 1, true)
    
        local count = 0
        local paddingPerButton = self.menuSizes.horizontalTab.padding.top + self.menuSizes.horizontalTab.padding.bottom
        local buttonHeight = (totalYSize - paddingPerButton * #cheat.menuElements) / #cheat.menuElements
    
        for _, tab in ipairs(cheat.menuElements) do
            local textPosX = self.menuVars.menuX + (self.menuSizes.horizontalTab.boxSize.width / 2)
            local posY = startY + paddingPerButton * count + buttonHeight * count
            local newHeight = totalYSize / #cheat.menuElements
            local isHovered = self:isHovering(self.menuVars.menuX, posY, self.menuSizes.horizontalTab.boxSize.width, buttonHeight + (self.menuSizes.horizontalTab.padding.top + self.menuSizes.horizontalTab.padding.bottom))
    
            if isHovered then
                self.menuVars.isHovering = true
                if self:didClick(1, tab.tabName) then
                    selectedTab = count + 1
                    self:clearOpenables()
                end
    
                render.draw_rectangle(self.menuVars.menuX , posY, self.menuSizes.horizontalTab.boxSize.width, newHeight, self.menuSizes.horizontalTab.buttonHovered.r, self.menuSizes.horizontalTab.buttonHovered.g, self.menuSizes.horizontalTab.buttonHovered.b, self.menuSizes.horizontalTab.buttonHovered.a, 1, true)
                
                if self.menuVars.currentVerticalTab == (count + 1) then
                    --open outline
                    render.draw_rectangle(self.menuVars.menuX, posY, self.menuSizes.horizontalTab.boxSize.width, self.menuSizes.horizontalTab.borderOutline, self.menuSizes.horizontalTab.borderOutlineColor.r, self.menuSizes.horizontalTab.borderOutlineColor.g, self.menuSizes.horizontalTab.borderOutlineColor.b, self.menuSizes.horizontalTab.borderOutlineColor.a, 1, true)
                    render.draw_rectangle(self.menuVars.menuX, (posY + newHeight) - self.menuSizes.horizontalTab.borderOutline, self.menuSizes.horizontalTab.boxSize.width, self.menuSizes.horizontalTab.borderOutline, self.menuSizes.horizontalTab.borderOutlineColor.r, self.menuSizes.horizontalTab.borderOutlineColor.g, self.menuSizes.horizontalTab.borderOutlineColor.b, self.menuSizes.horizontalTab.borderOutlineColor.a, 1, true)
                else
                    --closed outline
                    render.draw_rectangle(self.menuVars.menuX + self.menuSizes.horizontalTab.boxSize.width - self.menuSizes.horizontalTab.borderOutline, posY, self.menuSizes.horizontalTab.borderOutline, newHeight, self.menuSizes.horizontalTab.borderOutlineColor.r, self.menuSizes.horizontalTab.borderOutlineColor.g, self.menuSizes.horizontalTab.borderOutlineColor.b, self.menuSizes.horizontalTab.borderOutlineColor.a, 1, true)
                end
            elseif self.menuVars.currentVerticalTab == (count + 1) then
                --open outline
                render.draw_rectangle(self.menuVars.menuX, posY, self.menuSizes.horizontalTab.boxSize.width, self.menuSizes.horizontalTab.borderOutline, self.menuSizes.horizontalTab.borderOutlineColor.r, self.menuSizes.horizontalTab.borderOutlineColor.g, self.menuSizes.horizontalTab.borderOutlineColor.b, self.menuSizes.horizontalTab.borderOutlineColor.a, 1, true)
                render.draw_rectangle(self.menuVars.menuX, (posY + newHeight) - self.menuSizes.horizontalTab.borderOutline, self.menuSizes.horizontalTab.boxSize.width, self.menuSizes.horizontalTab.borderOutline, self.menuSizes.horizontalTab.borderOutlineColor.r, self.menuSizes.horizontalTab.borderOutlineColor.g, self.menuSizes.horizontalTab.borderOutlineColor.b, self.menuSizes.horizontalTab.borderOutlineColor.a, 1, true)
            else
                render.draw_rectangle(self.menuVars.menuX , posY, self.menuSizes.horizontalTab.boxSize.width , newHeight, self.menuSizes.horizontalTab.boxColor.r, self.menuSizes.horizontalTab.boxColor.g, self.menuSizes.horizontalTab.boxColor.b, self.menuSizes.horizontalTab.boxColor.a, 1, true)
                
                --closed outline
                render.draw_rectangle(self.menuVars.menuX + self.menuSizes.horizontalTab.boxSize.width - self.menuSizes.horizontalTab.borderOutline, posY, self.menuSizes.horizontalTab.borderOutline, newHeight, self.menuSizes.horizontalTab.borderOutlineColor.r, self.menuSizes.horizontalTab.borderOutlineColor.g, self.menuSizes.horizontalTab.borderOutlineColor.b, self.menuSizes.horizontalTab.borderOutlineColor.a, 1, true)
            end
    
            -- Draw bitmap if it exists
            if tab.bitmap and tab.bitmap.bit and not _debug then
                local bitmapWidth = tab.bitmap.width
                local bitmapHeight = tab.bitmap.height
                local bitmapPosX = (textPosX - (bitmapWidth / 2)) - 2
                local bitmapPosY = posY + ((newHeight / 2) - (bitmapHeight / 2))
    
                render.draw_bitmap(tab.bitmap.bit, bitmapPosX, bitmapPosY, bitmapWidth, bitmapHeight, tab.bitmap.r or 255, tab.bitmap.g or 255, tab.bitmap.b or 255, tab.bitmap.a or 255, tab.bitmap.a or 255)
            else
                -- Draw text if no bitmap
                draw:dText(draw.fonts.verticalTab.font, tab.tabName, textPosX - self.menuSizes.horizontalTab.borderOutline, posY + (((newHeight) / 2) - (draw.fonts.verticalTab.height / 2)), 255, 255, 255, 255, true)
            end
    
            count = count + 1
        end
    
        render.draw_rectangle(self.menuVars.menuX , endY, self.menuSizes.horizontalTab.boxSize.width, self.menuSizes.horizontalTab.padding.bottom, self.menuSizes.horizontalTab.borderOutlineColor.r, self.menuSizes.horizontalTab.borderOutlineColor.g, self.menuSizes.horizontalTab.borderOutlineColor.b, self.menuSizes.horizontalTab.borderOutlineColor.a, 1, true)
        render.draw_rectangle(self.menuVars.menuX, endY , self.menuSizes.horizontalTab.boxSize.width - (self.menuSizes.horizontalTab.borderOutline), self.menuSizes.horizontalTab.padding.bottom, self.menuSizes.horizontalTab.borderColor.r, self.menuSizes.horizontalTab.borderColor.g, self.menuSizes.horizontalTab.borderColor.b, self.menuSizes.horizontalTab.borderColor.a, 1, true)
        ]]
        return selectedTab
    end;

    drawSubTabs = function(self, subTabs, selectedTab)
        self.menuVars.menuYOffsetTab = self.menuVars.menuYOffsetTab - 10;
        self.menuVars.menuYOffsetTabSecondary = self.menuVars.menuYOffsetTabSecondary - 10;

        local startX = self.menuVars.menuX--[[ + self.menuSizes.horizontalTab.boxSize.width]]--self.menuVars.menuXOffset;
        local endX = self.menuVars.menuX +  self.menuVars.menuWidth;

        local drawCount = ((#subTabs) * (self.menuSizes.subtab.boxSize.width + self.menuSizes.subtab.padding.width))/2 - (self.menuSizes.subtab.padding.width/2);
        startX = ((startX + endX)/2) - drawCount

        local i = 0
        for _, subtab in ipairs(subTabs) do
            local pos = {x = startX + (i*(self.menuSizes.subtab.boxSize.width + self.menuSizes.subtab.padding.width)), y = self.menuVars.menuY + self.menuVars.menuYOffsetTab + self.menuSizes.subtab.padding.height - 3 }
       
            render.draw_rectangle(pos.x - self.menuSizes.subtab.boxOutline, pos.y - self.menuSizes.subtab.boxOutline, self.menuSizes.subtab.boxSize.width + (self.menuSizes.subtab.boxOutline*2), self.menuSizes.subtab.boxSize.height + (self.menuSizes.subtab.boxOutline*2), self.menuSizes.subtab.boxBorder.r, self.menuSizes.subtab.boxBorder.g, self.menuSizes.subtab.boxBorder.b, self.menuSizes.subtab.boxBorder.a, 1, true)

            local isHovered = self:isHovering(pos.x, pos.y, self.menuSizes.subtab.boxSize.width, self.menuSizes.subtab.boxSize.height);

            if isHovered and not self.menuVars.isHovering then
                render.draw_rectangle(pos.x, pos.y, self.menuSizes.subtab.boxSize.width, self.menuSizes.subtab.boxSize.height, self.menuSizes.subtab.boxHover.r, self.menuSizes.subtab.boxHover.g, self.menuSizes.subtab.boxHover.b, self.menuSizes.subtab.boxHover.a, 1, true)
                if self:didClick(1, subtab.subtabName) then
                    self:clearOpenables()
                    selectedTab = (i + 1)
                end
                self.menuVars.isHovering = true
            elseif (selectedTab == (i + 1)) then
                render.draw_rectangle(pos.x, pos.y, self.menuSizes.subtab.boxSize.width, self.menuSizes.subtab.boxSize.height, self.menuSizes.subtab.tabActive.r, self.menuSizes.subtab.tabActive.g, self.menuSizes.subtab.tabActive.b, self.menuSizes.subtab.tabActive.a, 1, true)
            else
                render.draw_rectangle(pos.x, pos.y, self.menuSizes.subtab.boxSize.width, self.menuSizes.subtab.boxSize.height, self.menuSizes.subtab.boxBackground.r, self.menuSizes.subtab.boxBackground.g, self.menuSizes.subtab.boxBackground.b, self.menuSizes.subtab.boxBackground.a, 1, true)
            end

            draw:dText(draw.fonts.subtab.font, subtab.subtabName, pos.x + (self.menuSizes.subtab.boxSize.width/2), pos.y + (self.menuSizes.subtab.boxSize.height/2) - (draw.fonts.menu.height / 2) - 1, 255, 255, 255, 255, true)

            i = i + 1
        end;

        self.menuVars.menuYOffsetTab = self.menuVars.menuYOffsetTab + ((self.menuSizes.subtab.padding.height * 2) + self.menuSizes.subtab.boxSize.height);
        self.menuVars.menuYOffsetTabSecondary = self.menuVars.menuYOffsetTabSecondary + ((self.menuSizes.subtab.padding.height * 2) + self.menuSizes.subtab.boxSize.height);

        return selectedTab
    end;

    didClick = function(self, mouse, element, passThrough)
        if draw.menuVars.wasDragging then
            return false;
        end

        if mouse == 1 then
            if self.menuVars.didLeftClick then
                if self.menuVars.recentlyCalledLeftClick then
                    return false;
                end
                if element ~= nil then
                    self.menuVars.leftClickedElementName = element.key;
                end
                self.menuVars.recentlyCalledLeftClick = true;
                return true;
            else
                if self.menuVars.wasLeftClicking then
                    if element ~= nil then
                        if element.key == self.menuVars.leftClickedElementName and passThrough then
                            return true;
                        end
                    end
                end
            end
        elseif mouse == 2 then
            if self.menuVars.didRightClick then
                if self.menuVars.recentlyCalledRightClick then
                    return false;
                end
                if element ~= nil then
                    self.menuVars.rightClickedElementName = element.key;
                end
                self.menuVars.recentlyCalledRightClick = true;
                return true;
            else
                if self.menuVars.wasRightClicking then
                    if element ~= nil then
                        if element.key == self.menuVars.rightClickedElementName and passThrough then
                            return true;
                        end
                    end
                end
            end
        end
    end;

    handleColorpickerDropdown = {
        handleCopy = function(self, element, selectedOption)
            if not draw.menuVars.savedColor then
                draw.menuVars.savedColor = {};
            end
            draw.menuVars.savedColor.r = element.value.color.r
            draw.menuVars.savedColor.g = element.value.color.g
            draw.menuVars.savedColor.b = element.value.color.b
            draw.menuVars.savedColor.a = element.value.color.a
        end;

        handlePaste = function(self, element, selectedOption)
            if draw.menuVars.savedColor and draw.menuVars.savedColor.r then
                element.value.color.r = draw.menuVars.savedColor.r;
                element.value.color.g = draw.menuVars.savedColor.g;
                element.value.color.b = draw.menuVars.savedColor.b;
                element.value.color.a = draw.menuVars.savedColor.a;
            end
        end;

        handleRGBAExport = function(self, element, selectedOption)
            input.set_clipboard('rgba(' .. math.floor(element.value.color.r) .. ',' .. math.floor(element.value.color.g) .. ',' .. math.floor(element.value.color.b) .. ',' .. number:floorWithTwoDecimals(element.value.color.a/255) .. ')');
        end;

        handleHexExport = function(self, element, selectedOption)
            input.set_clipboard(number:rgbaToHex(element.value.color.r, element.value.color.g, element.value.color.b--[[, element.value.color.a]]));
        end;

        handleClipboardImport = function(self, element, selectedOption)
            local clipboardText = input.get_clipboard()
            local parsedRGBA = number:parseRGBA(clipboardText);

            if parsedRGBA then
                element.value.color.r = parsedRGBA.r;
                element.value.color.g = parsedRGBA.g;
                element.value.color.b = parsedRGBA.b;
                element.value.color.a = parsedRGBA.a;
            elseif number:isHexColor(clipboardText) then
                parsedRGBA = number:hexToRGBA(clipboardText);
                element.value.color.r = parsedRGBA.r;
                element.value.color.g = parsedRGBA.g;
                element.value.color.b = parsedRGBA.b;
                element.value.color.a = parsedRGBA.a;
                --[[element.value.color.r = 255;
                element.value.color.g = 255;
                element.value.color.b = 255;
                element.value.color.a = 255;]]
            end
        end;
    };

    drawColorpicker = function(self, element, secondPane, fromCheckbox, passedPos, simulation)
        local oldYSpacing = (element.value.secondPane or secondPane) and self.menuVars.menuYOffsetTabSecondary or self.menuVars.menuYOffsetTab;
        local overridePosition;
        local pos
        local textPos
        local currentX = self.menuVars.menuX + self.menuVars.menuXOffset;
        local addToOffset = ((self.menuSizes.colorPicker.padding.height) + self.menuSizes.colorPicker.boxSize.height) + self.menuSizes.colorPicker.outline;

        if fromCheckbox then
            overridePosition = {x = passedPos.x, y = passedPos.y};
            pos = {x = ((element.value.secondPane or secondPane) and self.menuSizes.windowPane.width or 0) + (((currentX + (self.menuSizes.windowPane.width - self.menuSizes.windowPane.padding.middle)) - self.menuSizes.colorPicker.boxSize.width) - self.menuSizes.colorPicker.textBoxSpacing), y = overridePosition.y}
            pos.x = pos.x - (self.menuSizes.colorPicker.outline*2)
        else
            textPos = {x = ((element.value.secondPane or secondPane) and self.menuSizes.windowPane.width or 0) + (self.menuVars.menuX + self.menuVars.menuXOffset + self.menuVars.textSpacer), y = self.menuVars.menuY + self.menuSizes.checkbox.padding.top + ((element.value.secondPane or secondPane) and self.menuVars.menuYOffsetTabSecondary or self.menuVars.menuYOffsetTab)}
            pos = {x = ((element.value.secondPane or secondPane) and self.menuSizes.windowPane.width or 0) + (((currentX + (self.menuSizes.windowPane.width - self.menuSizes.windowPane.padding.middle)) - self.menuSizes.colorPicker.boxSize.width) - self.menuSizes.colorPicker.textBoxSpacing), y = textPos.y};
            pos.x = pos.x - (self.menuSizes.colorPicker.outline*2)
        end
        if not simulation then
            local isHovered = self:isHovering(pos.x, pos.y, self.menuSizes.colorPicker.boxSize.width, self.menuSizes.colorPicker.boxSize.height);

            render.draw_rectangle(pos.x - self.menuSizes.colorPicker.outline, pos.y - self.menuSizes.colorPicker.outline, self.menuSizes.colorPicker.boxSize.width + (self.menuSizes.colorPicker.outline*2), self.menuSizes.colorPicker.boxSize.height + (self.menuSizes.colorPicker.outline*2), self.menuSizes.colorPicker.outlineColor.r, self.menuSizes.colorPicker.outlineColor.g, self.menuSizes.colorPicker.outlineColor.b, self.menuSizes.colorPicker.outlineColor.a, 1, true)
            render.draw_rectangle(pos.x, pos.y, self.menuSizes.colorPicker.boxSize.width, self.menuSizes.colorPicker.boxSize.height, element.value.color.r, element.value.color.g, element.value.color.b, 255, 1, true)

            self:drawSelectiveDropdown(element, {
                {
                    key = "Copy";
                    callback = function(passedElement, passedOption) return self.handleColorpickerDropdown:handleCopy(passedElement, passedOption) end;
                };
                {
                    key = "Paste";
                    callback = function(passedElement, passedOption) return self.handleColorpickerDropdown:handlePaste(passedElement, passedOption) end;
                };
                {
                    key = "Import Clipboard";
                    callback = function(passedElement, passedOption) return self.handleColorpickerDropdown:handleClipboardImport(passedElement, passedOption) end;
                };
                {
                    key = "Export (Hex)";
                    callback = function(passedElement, passedOption) return self.handleColorpickerDropdown:handleHexExport(passedElement, passedOption) end;
                };
                {
                    key = "Export (RGBA)";
                    callback = function(passedElement, passedOption) return self.handleColorpickerDropdown:handleRGBAExport(passedElement, passedOption) end;
                };
            }, {
                x = pos.x + self.menuSizes.colorPicker.outline + self.menuSizes.colorPicker.boxSize.width + 4;
                y = pos.y - self.menuSizes.colorPicker.outline;
            }, isHovered and (self.menuVars.inputBlocker == 0))

            if isHovered and self.menuVars.openedDropdown == "" then
                if input.is_key_down(0x43) and input.is_key_down(0xA2) then
                    if not self.menuVars.savedColor or self.menuVars.savedColor.r == nil then
                        self.menuVars.savedColor = {};
                    end
                    self.menuVars.savedColor.r = element.value.color.r
                    self.menuVars.savedColor.g = element.value.color.g
                    self.menuVars.savedColor.b = element.value.color.b
                    self.menuVars.savedColor.a = element.value.color.a
                end
                if self.menuVars.savedColor and self.menuVars.savedColor.r and input.is_key_down(0x56) and input.is_key_down(0xA2) then
                    element.value.color.r = self.menuVars.savedColor.r
                    element.value.color.g = self.menuVars.savedColor.g
                    element.value.color.b = self.menuVars.savedColor.b
                    element.value.color.a = self.menuVars.savedColor.a
                end

                if 1 > string.len(self.menuVars.openedPicker) and self:didClick(1, element.key) then
                    self.menuVars.openedPicker = element.key
                    self.menuVars.inputBlocker =  self.menuVars.inputBlocker + 1

                    local r = element.value.color.r;
                    local g = element.value.color.g;
                    local b = element.value.color.b;

                    local maxComponent = r;
                    local minComponent = r;

                    if g > maxComponent then maxComponent = g end;
                    if b > maxComponent then maxComponent = b end;

                    if g < minComponent then minComponent = g end;
                    if b < minComponent then minComponent = b end;
                    
                    local hue = 0;
                    local maxMinDiff = maxComponent - minComponent;

                    if maxMinDiff ~= 0 then
                        if maxComponent == r then
                            hue = 60 * (0 + (g - b) / maxMinDiff);
                        elseif maxComponent == g then
                            hue = 60 * (2 + (b - r) / maxMinDiff);
                        elseif maxComponent == b then
                            hue = 60 * (4 + (r - g) / maxMinDiff);
                        end
                    end
                    
                    if hue < 0 then
                        hue = hue + 360;
                    end
                    
                    self.menuVars.hues = hue;
                end
                
                self.menuVars.isHovering = true;
            end

            if not fromCheckbox then
                --local textPos = { x = pos.x + self.menuSizes.colorPicker.boxSize.width + 5, y = pos.y + 2 }
                draw:dText(draw.fonts.menu.font, element.key, textPos.x, textPos.y, 255, 255, 255, 255, false)
                if element.value.secondPane or secondPane then
                    self.menuVars.menuYOffsetTabSecondary = self.menuVars.menuYOffsetTabSecondary + addToOffset;
                else
                    self.menuVars.menuYOffsetTab = self.menuVars.menuYOffsetTab + addToOffset;
                end
            end

            if self.menuVars.openedPicker == element.key then
                self:addLateCall(render.draw_rectangle,  pos.x + self.menuSizes.colorPicker.boxSize.width + 5, pos.y - 2, 133, 126, 0, 0, 0, 255, 1, true);
                --self:addLateCall(render.draw_rectangle,  pos.x + self.menuSizes.colorPicker.boxSize.width + 4, pos.y - 4, 133, 128, self.menuColors.checkboxBorder.r, self.menuColors.checkboxBorder.g, self.menuColors.checkboxBorder.b, self.menuColors.checkboxBorder.a, 1, true);

                local opacityPosition = { x = pos.x + self.menuSizes.colorPicker.boxSize.width + 5, y = pos.y + 126 };
                local opacityRange = 1 - 0;
                local opacityNewValue = ((element.value.color.a/255) - 0) / opacityRange * 132;
                local opacityHovered = self:isHovering(opacityPosition.x - 5, opacityPosition.y, 137, 30);
                local globalHovered = self:isHovering(pos.x + self.menuSizes.colorPicker.boxSize.width + 5 - 12, pos.y - 2 - 12, 133 + 47, 132 + 47);
                local huePos = { x = pos.x + self.menuSizes.colorPicker.boxSize.width + 5 + 135, y = (pos.y - 2) };
                local hueRange = 360 - 0;
                local hueNewValue = (self.menuVars.hues - 0) / hueRange * 123;
                local hueSliderHovered = self:isHovering(huePos.x, huePos.y - 5, 23, 126 + 5);
                local rgbHovered = false;
                local colorBoxSize = 6;
                local numBoxesPerRow = 132 / colorBoxSize;

                --self:addLateCall(render.draw_rectangle,  opacityPosition.x, opacityPosition.y, 132, 2, self.menuColors.dividerColor.r, self.menuColors.dividerColor.g, self.menuColors.dividerColor.b, self.menuColors.dividerColor.a, 1, true);

                if opacityNewValue < 0 then opacityNewValue = 0 end;
                if opacityNewValue > 132 then opacityNewValue = 132 end;

                self:addLateCall(render.draw_rectangle,  opacityPosition.x, opacityPosition.y, 132, 23, element.value.color.r, element.value.color.g, element.value.color.b, element.value.color.a, 1, true);

                if opacityHovered then
                    if self:didClick(1, {key = "opacityDrag"}, true) then
                        local normalizedOpacity = (self.mouseX - opacityPosition.x) / 132;
                        if normalizedOpacity < 0 then normalizedOpacity = 0 end;
                        if normalizedOpacity > 1 then normalizedOpacity = 1 end;
                        element.value.color.a = (0 + normalizedOpacity * opacityRange)*255;
                    end
                    self.menuVars.isHovering = true;
                end

                self:addLateCall(render.draw_rectangle,  opacityPosition.x + opacityNewValue - 6, opacityPosition.y, 6, 23, 0, 0, 0, 255, 1, true);
                self:addLateCall(render.draw_rectangle,  opacityPosition.x + opacityNewValue - 5, opacityPosition.y, 4, 23, 255, 255, 255, 255, 1, true);

                if hueNewValue < 0 then hueNewValue = 0 end;
                if hueNewValue > 126 then hueNewValue = 126 end;

                --print(type(r) .. " - " .. type(g) .. " - " .. type(b))
                --print(r .. " - " .. g .. " - " .. b)

                for i = 0, 125 do
                    local normalizedHue = i / 126;
                    local r, g, b = self:HSVtoRGB(normalizedHue * 360.0, 1.0, 1.0)
                    r = tonumber(r*255);
                    g = tonumber(g*255)
                    b = tonumber(b*255)
                    --render.draw_rectangle(huePos.x, huePos.y + i, 23, 1, r, g, b, 255, 1, true)
                    self:addLateCall(render.draw_rectangle,  huePos.x, huePos.y + i, 23, 1, r, g, b, 255, 1, true);
                end
                
                self:addLateCall(render.draw_rectangle,  huePos.x, huePos.y + hueNewValue - 1, 23, 6, 0, 0, 0, 255, 1, true);
                self:addLateCall(render.draw_rectangle,  huePos.x, huePos.y + hueNewValue, 23, 4, 255, 255, 255, 255, 1, true);
                
                if hueSliderHovered then
                    if self:didClick(1, {key = "hueDrag"}, true) then
                        local normalizedHue = (self.mouseY - huePos.y) / 126;
                        if normalizedHue < 0 then normalizedHue = 0 end;
                        if normalizedHue > 1 then normalizedHue = 1 end;
                        self.menuVars.hues = 0 + normalizedHue * hueRange;
                    end
                end

                self:addLateCall(render.draw_rectangle,  pos.x + self.menuSizes.colorPicker.boxSize.width + 5, pos.y - 2, 132, 126, element.value.color.r, 255, 255, 255, 1, true);

                for y = 0, numBoxesPerRow - 2 do
                    for x = 0, numBoxesPerRow - 1 do
                        local posX = (pos.x + self.menuSizes.colorPicker.boxSize.width + 5) + x * colorBoxSize;
                        local posY = (pos.y - 2) + y * colorBoxSize;

                        local hue = self.menuVars.hues;
                        local saturation = (x) / (numBoxesPerRow - 1);
                        local values = 1 - (y) / (numBoxesPerRow - 1);

                        local r, g, b = self:HSVtoRGB(hue, saturation, values)

                        self:addLateCall(render.draw_rectangle,  posX, posY, colorBoxSize, colorBoxSize, r*255, g*255, b*255, 255, 1, true);

                        local isSelected = (r == (element.value.color.r/255) and g == (element.value.color.g/255) and b == (element.value.color.b/255));
                        if isSelected then
                            self:addLateCall(render.draw_rectangle,  posX, posY, colorBoxSize, colorBoxSize, 204, 204, 204, 190, 1, true);
                        end
                        if self.mouseX >= posX and self.mouseX <= posX + colorBoxSize and self.mouseY >= posY and self.mouseY <= posY + colorBoxSize then
                            rgbHovered = true;
                            if self:didClick(1, {key = "rgbDrag"}, true) then
                                element.value.color.r = r*255;
                                element.value.color.g = g*255;
                                element.value.color.b = b*255;
                            end
                        end
                    end
                end

                if not opacityHovered and not hueSliderHovered and not rgbHovered and not globalHovered and not isHovered and not (self.menuVars.leftClickedElementName == element.key or self.menuVars.leftClickedElementName == "hueDrag" or self.menuVars.leftClickedElementName == "rgbDrag"  or self.menuVars.leftClickedElementName == "opacityDrag") then
                    if self.mouseDown or self.rightMouseDown then
                        self.menuVars.openedPicker = "";
                        self.menuVars.inputBlocker = self.menuVars.inputBlocker - 1;
                        self.menuVars.isHovering = true;
                    end
                else
                    self.menuVars.isHovering = true;
                end
                if input.is_key_down(keys.ESC.offset) or input.is_key_down(draw.cachedUiVars.configs.config.menuKey.value.activeKey) then
                    self.menuVars.openedPicker = "";
                    self.menuVars.inputBlocker = self.menuVars.inputBlocker - 1;
                    self.menuVars.isHovering = true;
                end
            end
        else
            return (((element.value.secondPane or secondPane) and self.menuVars.menuYOffsetTabSecondary or self.menuVars.menuYOffsetTab) + addToOffset) - oldYSpacing;
        end;
    end;

    firstHotkeyCall = true;

    handleHotkeyCheck = function(self, element)
        if input.is_key_down(keys.HOME.offset) then
            return;
        end

        if input.is_key_pressed(keys.ESC.offset) then
            self.menuVars.activeHotkey = ""
            self.firstHotkeyCall = true;
            element.value.shortKeyName = "";
            element.value.activeKey = keys.UNB.offset;
            return;
            
        end
        if input.is_key_pressed(draw.cachedUiVars.configs.config.menuKey.value.activeKey) then
            self.menuVars.activeHotkey = ""
            self.firstHotkeyCall = true;
            return;
        end
        for shortName, key in pairs(keys) do
            if (not key.block) and input.is_key_pressed(key.offset) and not self.firstHotkeyCall  then
                local continue = true;
                if continue then
                    element.value.shortKeyName = shortName;
                    element.value.activeKey = key.offset;
                    self.menuVars.activeHotkey = ""
                    self.firstHotkeyCall = true;

                    if element.value.bindCallback then
                        element.value.bindCallback(element);
                    end

                    return;
                end
            end
        end

        self.firstHotkeyCall = false;
    end;

    drawHotkey = function(self, element, secondPane, fromCheckbox, passedPos, hasColorPicker, simulation)        
        local oldYSpacing = (element.value.secondPane or secondPane) and self.menuVars.menuYOffsetTabSecondary or self.menuVars.menuYOffsetTab;
        local addToOffset = 0;
        local overridePosition;
        local pos
        local textPos
        local currentX = self.menuVars.menuX + self.menuVars.menuXOffset;
        local drawText = '[' .. (element.value.shortKeyName ~= "" and element.value.shortKeyName or "-") .. ']'
        local textMX, textMY = render.measure_text(draw.fonts.menu.font, drawText);
        local textLength = {width = textMX, height = textMY}

        if fromCheckbox then
            overridePosition = {x = passedPos.x, y = passedPos.y};
            textPos = {x = (((currentX + (self.menuSizes.windowPane.width - self.menuSizes.windowPane.padding.middle)) - self.menuSizes.hotkey.textBoxSpacing) - textLength.width) + ((element.value.secondPane or secondPane) and self.menuSizes.windowPane.width or 0), y = overridePosition.y}
            if hasColorPicker then
                textPos.x = ((textPos.x - self.menuSizes.colorPicker.boxSize.width) - self.menuSizes.colorPicker.textBoxSpacing) - self.menuSizes.colorPicker.outline
            end

            textPos.y = textPos.y - 1
        else
            addToOffset = self.menuSizes.hotkey.padding.height + draw.fonts.menu.height;
            
            textPos = {x = (((currentX + (self.menuSizes.windowPane.width - self.menuSizes.windowPane.padding.middle)) - self.menuSizes.hotkey.textBoxSpacing) - textLength.width) + ((element.value.secondPane or secondPane) and self.menuSizes.windowPane.width or 0), y = self.menuVars.menuY + ((element.value.secondPane or secondPane) and self.menuVars.menuYOffsetTabSecondary or self.menuVars.menuYOffsetTab)}
            pos = {x = self.menuVars.menuX + self.menuVars.menuXOffset + ((element.value.secondPane or secondPane) and self.menuSizes.windowPane.width or 0) + self.menuVars.textSpacer, y = self.menuVars.menuY + self.menuSizes.hotkey.padding.height + ((element.value.secondPane or secondPane) and self.menuVars.menuYOffsetTabSecondary or self.menuVars.menuYOffsetTab)};
            --textPos = {x = self.menuVars.menuX + self.menuVars.menuXOffset + ((element.value.secondPane or secondPane) and self.menuSizes.windowPane.width or 0) + self.menuVars.textSpacer, y = self.menuVars.menuY + self.menuSizes.checkbox.padding.height + ((element.value.secondPane or secondPane) and self.menuVars.menuYOffsetTabSecondary or self.menuVars.menuYOffsetTab)}
            --pos = {x = ((currentX + (self.menuSizes.windowPane.width - self.menuSizes.windowPane.padding.middle)) - self.menuSizes.colorPicker.boxSize.width) - self.menuSizes.colorPicker.textBoxSpacing, y = textPos.y};
            pos.y = pos.y - 1
            --pos.y = pos.y + self.menuSizes.checkbox.padding.top
        end

        --textPos.x = textPos.x + 1
        if not simulation then
            if not fromCheckbox then
                draw:dText(draw.fonts.menu.font, element.key, pos.x, pos.y, 255, 255, 255, 255, false)
            end

            local isHovered = self:isHovering(textPos.x, textPos.y, textLength.width, textLength.height);
            if element.value.allowChange then
                self:drawSelectiveDropdown(element, {
                    {
                        key = "Always On";
                        callback = function(passedElement, passedOption) element.value.keyType = keyTypes.alwaysOn; return end;
                        active = element.value.keyType == keyTypes.alwaysOn;
                    };
                    {
                        key = "On Hotkey";
                        callback = function(passedElement, passedOption) element.value.keyType = keyTypes.onHotkey; return end;
                        active = element.value.keyType == keyTypes.onHotkey;
                    };
                    {
                        key = "Toggle";
                        callback = function(passedElement, passedOption) element.value.keyType = keyTypes.toggle; return end;
                        active = element.value.keyType == keyTypes.toggle;
                    };
                    {
                        key = "Off Hotkey";
                        callback = function(passedElement, passedOption) element.value.keyType = keyTypes.offHotkey; return end;
                        active = element.value.keyType == keyTypes.offHotkey;
                    };
                }, {
                    x = textPos.x + textLength.width + 4;
                    y = textPos.y;
                }, isHovered and (self.menuVars.inputBlocker == 0) and self.menuVars.activeHotkey == '')
            end

            

            if isHovered and self.menuVars.openedDropdown == "" then
                if not self.menuVars.isHovering and self.menuVars.inputBlocker == 0 and self.menuVars.activeHotkey == '' then
                    if self:didClick(1, element.key) then
                        self.menuVars.activeHotkey = element.key
                    end
                end
                self.menuVars.isHovering = true;
            end

            local color = {r = 255, g = 255, b = 255, a = 255};
            if self.menuVars.activeHotkey == element.key then
                color = {r = 255, g = 0, b = 0, a = 255};
                self:handleHotkeyCheck(element)
            end

            --if element.value.activeKey ~= keys.UNB.offset then
                draw:dText(draw.fonts.menu.font, drawText, textPos.x, textPos.y, color.r, color.g, color.b, color.a, false)
            --end

            if not fromCheckbox then
                
            end

            return textLength;
        else
            return (((element.value.secondPane or secondPane) and self.menuVars.menuYOffsetTabSecondary or self.menuVars.menuYOffsetTab) + addToOffset) - oldYSpacing;
        end
    end;

    drawLabel = function(self, element, secondPane, simulation)
        local oldYSpacing = (element.value.secondPane or secondPane) and self.menuVars.menuYOffsetTabSecondary or self.menuVars.menuYOffsetTab;

        local pos = { x = self.menuVars.menuX + self.menuVars.menuXOffset + ((element.value.secondPane or secondPane) and self.menuSizes.windowPane.width or 0) + self.menuVars.textSpacer, y = self.menuVars.menuY + ((element.value.secondPane or secondPane) and self.menuVars.menuYOffsetTabSecondary or self.menuVars.menuYOffsetTab) + self.menuSizes.label.padding.top }
        local addToOffset = draw.fonts.menu.height + self.menuSizes.label.padding.top;
        
        if not simulation then
            draw:dText(draw.fonts.menu.font, element.value.message, pos.x, pos.y, 255, 255, 255, 255, false)

            if element.value.secondPane or secondPane then
                self.menuVars.menuYOffsetTabSecondary = self.menuVars.menuYOffsetTabSecondary + addToOffset;
            else
                self.menuVars.menuYOffsetTab = self.menuVars.menuYOffsetTab + addToOffset;
            end
        else
            return (((element.value.secondPane or secondPane) and self.menuVars.menuYOffsetTabSecondary or self.menuVars.menuYOffsetTab) + addToOffset) - oldYSpacing;
        end;
    end;

    drawCheckbox = function(self, element, secondPane, simulation)
        local oldYSpacing = (element.value.secondPane or secondPane) and self.menuVars.menuYOffsetTabSecondary or self.menuVars.menuYOffsetTab;

        local pos = { x = self.menuVars.menuX + self.menuVars.menuXOffset + ((element.value.secondPane or secondPane) and self.menuSizes.windowPane.width or 0) + self.menuVars.textSpacer, y = self.menuVars.menuY + ((element.value.secondPane or secondPane) and self.menuVars.menuYOffsetTabSecondary or self.menuVars.menuYOffsetTab) }
        local addToOffset = self.menuSizes.checkbox.padding.top + (self.menuSizes.checkbox.boxOutline*2) + self.menuSizes.checkbox.boxSize.height;
        
        pos.y = pos.y + (self.menuSizes.checkbox.boxOutline*2)
        pos.y = pos.y + self.menuSizes.checkbox.padding.top

        local textPos = {x = pos.x, y = pos.y + (self.menuSizes.checkbox.boxSize.height / 2) - (draw.fonts.menu.height / 2)}
        pos.x = ((pos.x - self.menuSizes.checkbox.boxLeftOffset) - self.menuSizes.checkbox.boxOutline) - self.menuSizes.checkbox.boxSize.width

        if not simulation then

            local isHovered = self:isHovering(pos.x - self.menuSizes.checkbox.clickPadding.left, pos.y - self.menuSizes.checkbox.clickPadding.up, self.menuSizes.checkbox.boxSize.width + (self.menuSizes.checkbox.clickPadding.left + self.menuSizes.checkbox.clickPadding.right), self.menuSizes.checkbox.boxSize.height + (self.menuSizes.checkbox.clickPadding.up + self.menuSizes.checkbox.clickPadding.down));
            local checkboxData = self.checkboxTypes[element.value.checkboxType];
            local checkboxMessage = element.value.message or checkboxData.info
            local isBoxHovered = self:isHovering(pos.x, pos.y, self.menuSizes.checkbox.boxSize.width, self.menuSizes.checkbox.boxSize.height);
            --local hotkeyWidth = 0;

            --colorpicker if exists
            if element.value.colorpicker and element.value.state then
                self:drawColorpicker(element.value.colorpicker, secondPane, true, pos);
                --textPos.x = textPos.x + self.menuSizes.colorPicker.boxSize.width + 5;
            end
            --hotkey if exists
            if element.value.hotkey and element.value.state then
                self:drawHotkey(element.value.hotkey, secondPane, true, pos, element.value.colorpicker ~= nil);
            end

            --outline
            if self.menuSizes.checkbox.boxOutline then
                --if not checkboxData.normal then
                --    render.draw_rectangle(pos.x - self.menuSizes.checkbox.boxOutline, pos.y - self.menuSizes.checkbox.boxOutline, self.menuSizes.checkbox.boxSize.width + (self.menuSizes.checkbox.boxOutline*2), self.menuSizes.checkbox.boxSize.height + (self.menuSizes.checkbox.boxOutline*2), checkboxData.color.r, checkboxData.color.g, checkboxData.color.b, checkboxData.color.a, 1, true)
                --else
                    render.draw_rectangle(pos.x - self.menuSizes.checkbox.boxOutline, pos.y - self.menuSizes.checkbox.boxOutline, self.menuSizes.checkbox.boxSize.width + (self.menuSizes.checkbox.boxOutline*2), self.menuSizes.checkbox.boxSize.height + (self.menuSizes.checkbox.boxOutline*2), self.menuSizes.checkbox.outlineColor.r, self.menuSizes.checkbox.outlineColor.g, self.menuSizes.checkbox.outlineColor.b, self.menuSizes.checkbox.outlineColor.a, 1, true)
                --end
            end

            --element name
            if checkboxData.normal then
                draw:dText(draw.fonts.menu.font, element.key, textPos.x, textPos.y, 255, 255, 255, 255, false)
            else
                draw:dText(draw.fonts.menu.font, element.key, textPos.x, textPos.y, checkboxData.color.r, checkboxData.color.g, checkboxData.color.b, checkboxData.color.a, false)
            end
            --Context:DrawText(draw.fonts.menu.font, element.key, textPos.x + self.menuSizes.checkbox.boxOutline, textPos.y, checkboxData.color.r, checkboxData.color.g, checkboxData.color.b, checkboxData.color.a, false)

            if isBoxHovered and not self.menuVars.isHovering and self.menuVars.inputBlocker == 0 then
                --information/warning popup
                if string.len(checkboxMessage) > 0 then
                    local textMX, textMY = render.measure_text(draw.fonts.menu.font, checkboxMessage)
                    local checkboxCenterY = pos.y + self.menuSizes.checkbox.boxSize.height / 2
                    local infoBoxHeight = self.menuSizes.checkbox.infoBoxHeight + (self.menuSizes.checkbox.infoBoxOutline * 2)
                    local infoPos = {
                        x = textPos.x,
                        y = checkboxCenterY - infoBoxHeight / 2
                    }
                
                    --information outline
                    self:addLateCall(render.draw_rectangle,  textPos.x, infoPos.y - self.menuSizes.checkbox.infoBoxOutline, textMX + (self.menuSizes.checkbox.infoBoxOutline * 2) + 5, infoBoxHeight, self.menuSizes.checkbox.infoBoxOutlineColor.r, self.menuSizes.checkbox.infoBoxOutlineColor.g, self.menuSizes.checkbox.infoBoxOutlineColor.b, self.menuSizes.checkbox.infoBoxOutlineColor.a, 1, true);
                    --information box
                    self:addLateCall(render.draw_rectangle,  textPos.x + self.menuSizes.checkbox.infoBoxOutline, infoPos.y, textMX + 5, self.menuSizes.checkbox.infoBoxHeight, self.menuSizes.checkbox.infoBoxColor.r, self.menuSizes.checkbox.infoBoxColor.g, self.menuSizes.checkbox.infoBoxColor.b, self.menuSizes.checkbox.infoBoxColor.a, 1, true);

                    local textYPosition = infoPos.y + (infoBoxHeight / 2) - (textMY / 2)
                    
                    --information text
                    self:addLateCall(draw.dText, draw, draw.fonts.menu.font, checkboxMessage, textPos.x + 3 + self.menuSizes.checkbox.boxOutline, textYPosition - 2, checkboxData.color.r, checkboxData.color.g, checkboxData.color.b, checkboxData.color.a, false)
                end
            end

            --smaller inner box if active
            if element.value.state then
                render.draw_rectangle(pos.x, pos.y, self.menuSizes.checkbox.boxSize.width, self.menuSizes.checkbox.boxSize.height, checkboxData.color.r, checkboxData.color.g, checkboxData.color.b, checkboxData.color.a, 1, true)
            else
                --inner box
                render.draw_rectangle(pos.x, pos.y, self.menuSizes.checkbox.boxSize.width, self.menuSizes.checkbox.boxSize.height, self.menuSizes.checkbox.boxColor.r, self.menuSizes.checkbox.boxColor.g, self.menuSizes.checkbox.boxColor.b, self.menuSizes.checkbox.boxColor.a, 1, true)
            end

            if isHovered and not self.menuVars.isHovering and self.menuVars.inputBlocker == 0 and (self.menuVars.leftClickedElementName == '') then
                --hovered box
                render.draw_rectangle(pos.x, pos.y,self.menuSizes.checkbox.boxSize.width, self.menuSizes.checkbox.boxSize.height, self.menuSizes.checkbox.boxHoverColor.r, self.menuSizes.checkbox.boxHoverColor.g, self.menuSizes.checkbox.boxHoverColor.b, self.menuSizes.checkbox.boxHoverColor.a, 1, true)
                local clickedElement = self:didClick(1, element.key);
                if clickedElement then
                    --switch element state
                    if element.value.checkboxType ~= 1 then
                        if not draw.cachedUiVars.configs.config.disableAllUnsafe.value.state or draw.cachedUiVars.configs.config.disableAllUnsafe.key == element.key then
                            element.value.state = not element.value.state;
                            if element.value.callback then element.value.callback(element) end
                        end
                    else
                        element.value.state = not element.value.state;
                        if element.value.callback then element.value.callback(element) end
                    end
                end

                self.menuVars.isHovering = true
            else
                --inner box
            end

            if element.value.secondPane or secondPane then
                self.menuVars.menuYOffsetTabSecondary = self.menuVars.menuYOffsetTabSecondary + addToOffset;
            else
                self.menuVars.menuYOffsetTab = self.menuVars.menuYOffsetTab + addToOffset;
            end
        else
            return (((element.value.secondPane or secondPane) and self.menuVars.menuYOffsetTabSecondary or self.menuVars.menuYOffsetTab) + addToOffset) - oldYSpacing;
        end;
    end;

    formatDecimalNumber = function(self, number, decimalPoints)
        if decimalPoints == 0 then
            return math.floor(number)
        end

        local factor = 10 ^ decimalPoints
        local roundedNumber = math.floor(number * factor + 0.5) / factor

        return roundedNumber
    end;

    manualSliderInput = {
        inputValue = 0;
        keyState = {};
        firstTime = true;
        activeElement = "";
        active = false;
        hasPressed = false;

        numberKeys = {0x30,0x31,0x32,0x33,0x34,0x35,0x36,0x37,0x38,0x39};
    
        updateKeyInput = function(self, element)
            if self.firstTime then
                -- Initialize the press states to false for numbers 0-9, backspace, minus key, and dot
                for i = 0, #self.numberKeys do
                    self.keyState[tostring(i)] = false
                end
                self.keyState["backspace"] = false
                self.keyState["minus"] = false
                self.keyState["."] = false
                self.firstTime = false
                self.active = true
                -- Initialize inputValue based on element's decimalPoints
                self.inputValue = tonumber(draw:formatDecimalNumber(element.value.state, element.value.decimalPoints or 0));
            end
    
            for i = 0, #self.numberKeys do
                local key = self.numberKeys[i + 1]--tostring(i)
                if key then
                    if input.is_key_down(key) then
                        if not self.keyState[tostring(i)] then
                            self.keyState[tostring(i)] = true
                            self:appendNumber(tostring(i), element)
                            self.hasPressed = true
                        end
                    else
                        self.keyState[tostring(i)] = false
                    end
                end
            end
            
            -- Handling the backspace key
            if input.is_key_down(0x08) then
                if not self.keyState["backspace"] and self.inputValue ~= 0 then
                    self.keyState["backspace"] = true
                    local stringValue = tostring(self.inputValue)
                    stringValue = stringValue:sub(1, -2)
                    self.inputValue = tonumber(stringValue) or 0
                    self.hasPressed = true
                end
            else
                self.keyState["backspace"] = false
            end
    
            -- Handling the minus key for negative numbers
            if input.is_key_down(0xBD) then
                if not self.keyState["minus"] and self.inputValue == 0 then
                    self.keyState["minus"] = true
                    self.inputValue = -self.inputValue
                    self.hasPressed = true
                end
            else
                self.keyState["minus"] = false
            end
    
            -- Handling the dot for decimal values
            if element.value.decimalPoints and element.value.decimalPoints > 0 then
                if input.is_key_down(0xBE) then
                    if not self.keyState["."] and not tostring(self.inputValue):find("%.") then
                        self.keyState["."] = true
                        self.inputValue = tonumber(tostring(self.inputValue) .. ".0") or self.inputValue
                        self.hasPressed = true
                    end
                else
                    self.keyState["."] = false
                end
            end
        end;
    
        split = function(self, str, delim)
            local result = {}
            local regex = ("([^%s]+)"):format(delim)
            for each in str:gmatch(regex) do
                table.insert(result, each)
            end
            return result
        end;
    
        appendNumber = function(self, key, element)
            local keyStr = tostring(key)
            local stringValue = tostring(self.inputValue) .. keyStr
    
            -- Handle decimal point precision
            if element.value.decimalPoints and element.value.decimalPoints > 0 then
                local parts = self:split(stringValue, '.')
                if #parts > 1 and #parts[2] > element.value.decimalPoints then
                    return -- Do not append more digits than allowed
                end
            end
            self.inputValue = tonumber(stringValue) or self.inputValue
        end;
    
        returnValue = function(self)
            return self.inputValue;
        end;
    
        reset = function(self)
            self.inputValue = 0;
            self.keyState = {};
            self.firstTime = true;
            self.activeElement = "";
            self.active = false;
            self.hasPressed = false;
        end;
    };

    drawSlider = function(self, element, secondPane, simulation)
        local oldYSpacing = (element.value.secondPane or secondPane) and self.menuVars.menuYOffsetTabSecondary or self.menuVars.menuYOffsetTab;
        local pos = { x = self.menuVars.menuX + self.menuVars.menuXOffset + ((element.value.secondPane or secondPane) and self.menuSizes.windowPane.width or 0) + self.menuVars.textSpacer, y = self.menuVars.menuY + ((element.value.secondPane or secondPane) and self.menuVars.menuYOffsetTabSecondary or self.menuVars.menuYOffsetTab) }
        local addToOffset = self.menuSizes.slider.padding.top + (self.menuSizes.slider.boxOutline*2) + self.menuSizes.slider.boxSize.height;
        local matchingManualSlider = self.manualSliderInput.active and self.manualSliderInput.activeElement == element.key;
        
        pos.y = pos.y + (self.menuSizes.slider.boxOutline*2)
        pos.y = pos.y + self.menuSizes.slider.padding.top

        if element.value.doText then
            pos.y = pos.y + (draw.fonts.menu.height + self.menuSizes.slider.textBoxSpacing);
            addToOffset = addToOffset + (draw.fonts.menu.height + self.menuSizes.slider.textBoxSpacing);
        end

        local sliderValue;
        local textPos = { x = pos.x, y = pos.y };
        textPos.y = textPos.y - (draw.fonts.menu.height) - (self.menuSizes.slider.textBoxSpacing) - self.menuSizes.slider.boxOutline;

        local range = element.value.maxValue - element.value.minValue;
        local newValue = (element.value.state - element.value.minValue) / range * self.menuSizes.slider.boxSize.width;

        if not simulation then
            if element.value.doText then
                --element name
                draw:dText(draw.fonts.menu.font, element.key, textPos.x, textPos.y, 255, 255, 255, 255, false)
                textPos.y = (textPos.y + draw.fonts.menu.height + self.menuSizes.slider.textBoxSpacing + (self.menuSizes.slider.boxSize.height/2)) - (draw.fonts.menu.height/2) - 1--(self.menuSizes.multiselect.boxSize.height/3 + (draw.fonts.menu.height));--pos.y = pos.y + self.menuSizes.slider.boxOutline;
            end
            
            if newValue < 0 then newValue = 0 end;
            if newValue > self.menuSizes.slider.boxSize.width then newValue = self.menuSizes.slider.boxSize.width end;

            --slider value
            if element.value.decimalPoints then
                sliderValue = tostring(self:formatDecimalNumber(element.value.state, element.value.decimalPoints or 0));
            else
                sliderValue = tostring(math.floor(element.value.state));
            end

            local isHovered = self:isHovering(pos.x - 1, pos.y - 12, self.menuSizes.slider.boxSize.width + 2, self.menuSizes.slider.boxSize.height + 16);

            if (isHovered and self.menuVars.inputBlocker == 0 and not self.menuVars.isHovering) then
                if input.is_key_down(0xA2) and input.is_key_down(keys.ENT.offset) and (self.manualSliderInput.activeElement == nil or self.manualSliderInput.activeElement == '') then
                    self.manualSliderInput.activeElement = element.key;
                end
                if self.manualSliderInput.activeElement == element.key then
                    if input.is_key_down(keys.ENT.offset) and self.manualSliderInput.hasPressed then
                        element.value.state = tonumber(self.manualSliderInput:returnValue())
                        self.manualSliderInput:reset();
                    elseif input.is_key_down(keys.ESC.offset) or input.is_key_down(draw.cachedUiVars.configs.config.menuKey.value.activeKey) then
                        self.manualSliderInput:reset();
                    else
                        self.manualSliderInput:updateKeyInput(element);
                    end

                    sliderValue = tostring(self.manualSliderInput.inputValue);
                    --Context:DrawText(draw.fonts.menu.font, "element", 100, 100, 255, 255, 255, 255, false)
                end
            else
                if matchingManualSlider then
                    self.manualSliderInput:reset();
                end;
            end

            if element.value.textSpecifier then
                sliderValue = sliderValue .. element.value.textSpecifier
            end

            -- outline
            render.draw_rectangle(pos.x - self.menuSizes.slider.boxOutline, pos.y - self.menuSizes.slider.boxOutline, self.menuSizes.slider.boxSize.width + (self.menuSizes.slider.boxOutline*2), self.menuSizes.slider.boxSize.height + (self.menuSizes.slider.boxOutline*2),self.menuSizes.slider.boxOutlineColor.r, self.menuSizes.slider.boxOutlineColor.g, self.menuSizes.slider.boxOutlineColor.b, self.menuSizes.slider.boxOutlineColor.a, 1, true)
            

            if (isHovered and self.menuVars.inputBlocker == 0 and not self.menuVars.isHovering) or self.menuVars.leftClickedElementName == element.key then
                --main box hovered
                render.draw_rectangle(pos.x, pos.y, self.menuSizes.slider.boxSize.width, self.menuSizes.slider.boxSize.height, self.menuSizes.slider.boxHoverColor.r, self.menuSizes.slider.boxHoverColor.g, self.menuSizes.slider.boxHoverColor.b, self.menuSizes.slider.boxHoverColor.a, 1, true)
                
                --drag handle
                if self:didClick(1, element, true) then
                    local normalizedValue = (self.mouseX - pos.x) / self.menuSizes.slider.boxSize.width;
                    if normalizedValue < 0 then normalizedValue = 0 end;
                    if normalizedValue > 1 then normalizedValue = 1 end;
                    local newValue = element.value.minValue + normalizedValue * range;

                    if newValue ~= element.value.state then
                        local oldValue = math.floor(element.value.state)
                        element.value.state = tonumber(element.value.minValue + normalizedValue * range);
                        if element.value.callback and math.floor(element.value.state) ~= oldValue then
                            element.value.callback();
                        end
                    end
                end

                self.menuVars.isHovering = true;
            else
                --main box no hover
                render.draw_rectangle(pos.x, pos.y, self.menuSizes.slider.boxSize.width, self.menuSizes.slider.boxSize.height, self.menuSizes.slider.boxColor.r, self.menuSizes.slider.boxColor.g, self.menuSizes.slider.boxColor.b, self.menuSizes.slider.boxColor.a, 1, true)
            end

            --drag box
            local proportionalWidth = (element.value.state - element.value.minValue) / (element.value.maxValue - element.value.minValue) * self.menuSizes.slider.boxSize.width;

            if proportionalWidth < 0 then
                proportionalWidth = 0
            elseif proportionalWidth > self.menuSizes.slider.boxSize.width then
                proportionalWidth = self.menuSizes.slider.boxSize.width
            end
            
            render.draw_rectangle(pos.x, pos.y, proportionalWidth, self.menuSizes.slider.boxSize.height, self.menuSizes.slider.valueBoxColor.r, self.menuSizes.slider.valueBoxColor.g, self.menuSizes.slider.valueBoxColor.b, self.menuSizes.slider.valueBoxColor.a, 1, true)

            local isMinusHovered = self:isHovering(pos.x - 16,  (pos.y - (self.menuSizes.slider.boxSize.height/2) - self.menuSizes.slider.boxOutline) - 3, 16, 16);
            if isMinusHovered then
                if self:didClick(1, {key = element.key .. "minusSLClicked"}, false) then
                    if element.value.state > (element.value.minValue + 1) then
                        element.value.state = element.value.state - 1;
                        if element.value.callback then
                            element.value.callback();
                        end
                    end
                end;
            end
            draw:dText(draw.fonts.menu.font, "-", (pos.x - 6), (pos.y - (self.menuSizes.slider.boxSize.height/2)) - self.menuSizes.slider.boxOutline, 255, 255, 255, 255, true)
            local isPlusHovered = self:isHovering((pos.x + (self.menuSizes.slider.boxSize.width) + self.menuSizes.slider.boxOutline),  (pos.y - (self.menuSizes.slider.boxSize.height/2) - self.menuSizes.slider.boxOutline) - 3, 14, 16);
            if isPlusHovered then
                if self:didClick(1, {key = element.key .. "plusSLClicked"}, false) then
                    if element.value.maxValue > element.value.state then
                        element.value.state = element.value.state + 1;
                        if element.value.callback then
                            element.value.callback();
                        end
                    end
                end;
            end
            draw:dText(draw.fonts.menu.font, "+", (pos.x + (self.menuSizes.slider.boxSize.width) + 8), (pos.y - (self.menuSizes.slider.boxSize.height/2) - self.menuSizes.slider.boxOutline), 255, 255, 255, 255, true)

            if matchingManualSlider then
                render.draw_rectangle(pos.x, pos.y, self.menuSizes.slider.boxSize.width, self.menuSizes.slider.boxSize.height, self.menuSizes.slider.manualInputColor.r, self.menuSizes.slider.manualInputColor.g, self.menuSizes.slider.manualInputColor.b, self.menuSizes.slider.manualInputColor.a, 1, true)
            end

            if matchingManualSlider then
                draw:dText(draw.fonts.sliderText.font, sliderValue, (pos.x + (self.menuSizes.slider.boxSize.width/2)), pos.y - 1, 255, 255, 255, 255, true)
            else
                draw:dText(draw.fonts.sliderText.font, sliderValue, (pos.x + newValue), pos.y - 1, 255, 255, 255, 255, true)
            end

            if element.value.secondPane or secondPane then
                self.menuVars.menuYOffsetTabSecondary = self.menuVars.menuYOffsetTabSecondary + addToOffset;
            else
                self.menuVars.menuYOffsetTab = self.menuVars.menuYOffsetTab + addToOffset;
            end
        else
            return (((element.value.secondPane or secondPane) and self.menuVars.menuYOffsetTabSecondary or self.menuVars.menuYOffsetTab) + addToOffset) - oldYSpacing;
        end
    end;

    drawButton = function(self, element, secondPane, simulation)
        local oldYSpacing = (element.value.secondPane or secondPane) and self.menuVars.menuYOffsetTabSecondary or self.menuVars.menuYOffsetTab;
        local pos = { x = self.menuVars.menuX + self.menuVars.menuXOffset + ((element.value.secondPane or secondPane) and self.menuSizes.windowPane.width or 0) + self.menuVars.textSpacer, y = self.menuSizes.button.boxOutline + self.menuVars.menuY + self.menuSizes.button.padding.height + ((element.value.secondPane or secondPane) and self.menuVars.menuYOffsetTabSecondary or self.menuVars.menuYOffsetTab)};
        local hasClicked = false;
        local addToOffset = self.menuSizes.button.boxSize.height + self.menuSizes.button.padding.height + (self.menuSizes.button.boxOutline*2)
        
        if not simulation then
            render.draw_rectangle(pos.x - self.menuSizes.button.boxOutline, pos.y - self.menuSizes.button.boxOutline, self.menuSizes.button.boxSize.width + (self.menuSizes.button.boxOutline*2), self.menuSizes.button.boxSize.height + (self.menuSizes.button.boxOutline*2), self.menuSizes.button.boxOutlineColor.r, self.menuSizes.button.boxOutlineColor.g, self.menuSizes.button.boxOutlineColor.b, self.menuSizes.button.boxOutlineColor.a, 1, true)

            local isHovered = self:isHovering(pos.x, pos.y, self.menuSizes.button.boxSize.width, self.menuSizes.button.boxSize.height);
            if isHovered and not self.menuVars.isHovering then
                hasClicked = self:didClick(1, element.key)
                
                if hasClicked then
                    if element.value.callback ~= nil then
                        element.value.callback();
                    end
                    --self.menuVars.openedInputBox = "";
                    --self.menuVars.inputBlocker = self.menuVars.inputBlocker - 1;
                    self.menuVars.isHovering = true;
                end
                self.menuVars.isHovering = true;

                if self.mouseDown then
                    render.draw_rectangle(pos.x, pos.y, self.menuSizes.button.boxSize.width, self.menuSizes.button.boxSize.height, self.menuSizes.button.boxColor.r, self.menuSizes.button.boxColor.g, self.menuSizes.button.boxColor.b, self.menuSizes.button.boxColor.a, 1, true)
                else
                    render.draw_rectangle(pos.x, pos.y, self.menuSizes.button.boxSize.width, self.menuSizes.button.boxSize.height, self.menuSizes.button.boxHoverColor.r, self.menuSizes.button.boxHoverColor.g, self.menuSizes.button.boxHoverColor.b, self.menuSizes.button.boxHoverColor.a, 1, true)
                end
            else
                render.draw_rectangle(pos.x, pos.y, self.menuSizes.button.boxSize.width, self.menuSizes.button.boxSize.height, self.menuSizes.button.boxColor.r, self.menuSizes.button.boxColor.g, self.menuSizes.button.boxColor.b, self.menuSizes.button.boxColor.a, 1, true)
            end

            draw:dText(draw.fonts.menu.font, element.key, pos.x + (self.menuSizes.button.boxSize.width/2), pos.y + (self.menuSizes.button.boxSize.height/4),  255, 255, 255, 255, true);

            if element.value.secondPane or secondPane then
                self.menuVars.menuYOffsetTabSecondary = self.menuVars.menuYOffsetTabSecondary + addToOffset;
            else
                self.menuVars.menuYOffsetTab = self.menuVars.menuYOffsetTab + addToOffset;
            end
        else
            return (((element.value.secondPane or secondPane) and self.menuVars.menuYOffsetTabSecondary or self.menuVars.menuYOffsetTab) + addToOffset) - oldYSpacing;
        end
    end;

    drawCombobox = function(self, element, secondPane, simulation)
        local oldYSpacing = (element.value.secondPane or secondPane) and self.menuVars.menuYOffsetTabSecondary or self.menuVars.menuYOffsetTab;
        local pos = { x = self.menuVars.menuX + self.menuVars.menuXOffset + ((element.value.secondPane or secondPane) and self.menuSizes.windowPane.width or 0) + self.menuVars.textSpacer, y = self.menuVars.menuY + ((element.value.secondPane or secondPane) and self.menuVars.menuYOffsetTabSecondary or self.menuVars.menuYOffsetTab) }
        local addToOffset = self.menuSizes.combobox.padding.top + (self.menuSizes.combobox.boxOutline*2) + self.menuSizes.combobox.boxSize.height + (draw.fonts.menu.height + self.menuSizes.combobox.textBoxSpacing);
    
        pos.y = pos.y + (self.menuSizes.combobox.boxOutline*2)
        pos.y = pos.y + self.menuSizes.combobox.padding.top
        pos.y = pos.y + (draw.fonts.menu.height + self.menuSizes.combobox.textBoxSpacing);
    
        local textPos = { x = pos.x, y = pos.y };
        textPos.y = textPos.y - (draw.fonts.menu.height) - (self.menuSizes.combobox.textBoxSpacing) - self.menuSizes.combobox.boxOutline;

        local hasClicked = false;

        local opened = (self.menuVars.openedCombo == '') and false or (element.key == self.menuVars.openedCombo);

        if opened then --add triangles
            
        else

        end

        if not simulation then
            draw:dText(draw.fonts.menu.font, element.key, textPos.x, textPos.y,  255, 255, 255, 255, false);
            textPos.y = pos.y + (self.menuSizes.combobox.boxSize.height / 2) - (draw.fonts.menu.height / 2);

            render.draw_rectangle(pos.x - self.menuSizes.combobox.boxOutline, pos.y - self.menuSizes.combobox.boxOutline, self.menuSizes.combobox.boxSize.width + (self.menuSizes.combobox.boxOutline*2), self.menuSizes.combobox.boxSize.height + (self.menuSizes.combobox.boxOutline*2), self.menuSizes.combobox.boxOutlineColor.r, self.menuSizes.combobox.boxOutlineColor.g, self.menuSizes.combobox.boxOutlineColor.b, self.menuSizes.combobox.boxOutlineColor.a, 1, true)

            local isHovered = self:isHovering(pos.x, pos.y, self.menuSizes.combobox.boxSize.width, self.menuSizes.combobox.boxSize.height);
            if isHovered and not self.menuVars.isHovering and (self.menuVars.leftClickedElementName == '') then
                render.draw_rectangle(pos.x, pos.y, self.menuSizes.combobox.boxSize.width, self.menuSizes.combobox.boxSize.height, self.menuSizes.combobox.boxHoverColor.r, self.menuSizes.combobox.boxHoverColor.g, self.menuSizes.combobox.boxHoverColor.b, self.menuSizes.combobox.boxHoverColor.a, 1, true)

                hasClicked = self:didClick(1, element.key)
                if hasClicked then
                    if opened then
                        opened = false
                        self.menuVars.openedCombo = ''
                        self.menuVars.inputBlocker = self.menuVars.inputBlocker - 1
                    elseif self.menuVars.inputBlocker == 0 then
                        local wasOpen = opened;
                        self.menuVars.openedCombo = element.key
                        opened = (self.menuVars.openedCombo == '') and false or (element.key == self.menuVars.openedCombo);
                        self.menuVars.inputBlocker = self.menuVars.inputBlocker + ((opened ~= wasOpen) and (opened and 1 or -1) or 0)--self.menuVars.inputBlocker = self.menuVars.inputBlocker + (opened ~= wasOpen) and (opened and 1 or -1) or 0;
                    end
                    self.menuVars.isHovering = true;
                end
                self.menuVars.isHovering = true;
            else
                render.draw_rectangle(pos.x, pos.y, self.menuSizes.combobox.boxSize.width, self.menuSizes.combobox.boxSize.height, self.menuSizes.combobox.boxColor.r, self.menuSizes.combobox.boxColor.g, self.menuSizes.combobox.boxColor.b, self.menuSizes.combobox.boxColor.a, 1, true)
            end

            if element.value.state == 0 and element.value.doOff then
                draw:dText(draw.fonts.menu.font, "Off", textPos.x + 5, textPos.y,  255, 255, 255, 255, false);
            else
                local i = 0;
                for _, option in ipairs(element.value.options) do
                    if (i + 1) == element.value.state then
                        draw:dText(draw.fonts.menu.font, option, textPos.x + 5, textPos.y,  255, 255, 255, 255, false);
                        break;
                    end
                    i = i + 1;
                end
            end

            if opened then
                local lCount = 0;
                if element.value.state ~= 0 and element.value.doOff then
                    lCount = lCount + 1
                    local optionPosition = { x = pos.x, y = pos.y + (1) * self.menuSizes.combobox.boxSize.height }
                    self:addLateCall(render.draw_rectangle,  optionPosition.x, optionPosition.y, self.menuSizes.combobox.boxSize.width, self.menuSizes.combobox.boxSize.height, self.menuSizes.combobox.boxDropdownColor.r, self.menuSizes.combobox.boxDropdownColor.g, self.menuSizes.combobox.boxDropdownColor.b, self.menuSizes.combobox.boxDropdownColor.a, 1, true);
                
                    local isHovered = self:isHovering(optionPosition.x, optionPosition.y, self.menuSizes.combobox.boxSize.width, self.menuSizes.combobox.boxSize.height);
                    if isHovered then
                        self:addLateCall(render.draw_rectangle,  optionPosition.x, optionPosition.y, self.menuSizes.combobox.boxSize.width, self.menuSizes.combobox.boxSize.height - 1, self.menuSizes.combobox.optionHovered.r, self.menuSizes.combobox.optionHovered.g, self.menuSizes.combobox.optionHovered.b, self.menuSizes.combobox.optionHovered.a, 1, true);
                        
                        if not hasClicked then
                            hasClicked = self:didClick(1, element.key)
                        end

                        if hasClicked then
                            element.value.state = 0;
                            self.menuVars.openedCombo = '';
                            self.menuVars.inputBlocker = self.menuVars.inputBlocker - 1;
                            self.menuVars.isHovering = true;
                        end
                        self.menuVars.isHovering = true;
                    end

                    self:addLateCall(draw.dText, draw, draw.fonts.menu.font, "Off", optionPosition.x + 5, optionPosition.y + (draw.fonts.menu.height/2), 255, 255, 255, 255, false);
                end

                local i = 0;
                for _, option in ipairs(element.value.options) do
                    if not ((i + 1) == element.value.state) then
                        local optionPosition = { x = pos.x, y = pos.y + (lCount + 1) * self.menuSizes.combobox.boxSize.height }
                        --self:addLateCall(render.draw_rectangle,  optionPosition.x - self.menuSizes.combobox.boxOutline, optionPosition.y, self.menuSizes.combobox.boxSize.width + (self.menuSizes.combobox.boxOutline) * 2, self.menuSizes.combobox.boxSize.height, self.menuSizes.combobox.boxOutlineColor.r, self.menuSizes.combobox.boxOutlineColor.g, self.menuSizes.combobox.boxOutlineColor.b, self.menuSizes.combobox.boxOutlineColor.a, 1, true)
                        self:addLateCall(render.draw_rectangle,  optionPosition.x, optionPosition.y, self.menuSizes.combobox.boxSize.width, self.menuSizes.combobox.boxSize.height, self.menuSizes.combobox.boxDropdownColor.r, self.menuSizes.combobox.boxDropdownColor.g, self.menuSizes.combobox.boxDropdownColor.b, self.menuSizes.combobox.boxDropdownColor.a, 1, true)
                
                        local isHovered = self:isHovering(optionPosition.x, optionPosition.y, self.menuSizes.combobox.boxSize.width, self.menuSizes.combobox.boxSize.height)
                        if isHovered then
                            self:addLateCall(render.draw_rectangle,  optionPosition.x, optionPosition.y, self.menuSizes.combobox.boxSize.width, self.menuSizes.combobox.boxSize.height - 1, self.menuSizes.combobox.optionHovered.r, self.menuSizes.combobox.optionHovered.g, self.menuSizes.combobox.optionHovered.b, self.menuSizes.combobox.optionHovered.a, 1, true)
                            if not hasClicked then
                                hasClicked = self:didClick(1, element.key)
                            end
                            if hasClicked then
                                element.value.state = (i + 1)
                                self.menuVars.openedCombo = ''
                                self.menuVars.inputBlocker = self.menuVars.inputBlocker - 1
                                self.menuVars.isHovering = true
                            end
                            self.menuVars.isHovering = true
                        end
                        self:addLateCall(draw.dText, draw, draw.fonts.menu.font, option, optionPosition.x + 5, optionPosition.y + (draw.fonts.menu.height/2), 255, 255, 255, 255, false)
                        lCount = lCount + 1
                    end
                
                    i = i + 1
                end

                local isHovered = self:isHovering(pos.x, pos.y, self.menuSizes.combobox.boxSize.width, (lCount * self.menuSizes.combobox.boxSize.height) + self.menuSizes.combobox.boxSize.height);
                if not isHovered then
                    if not hasClicked then
                        hasClicked = self:didClick(1, element.key)
                    end
                    if hasClicked then
                        self.menuVars.openedCombo = '';
                        self.menuVars.inputBlocker = self.menuVars.inputBlocker - 1;
                        self.menuVars.isHovering = true;
                    end
                else
                    self.menuVars.isHovering = true;
                end

                if input.is_key_down(keys.ESC.offset) or input.is_key_down(draw.cachedUiVars.configs.config.menuKey.value.activeKey) then
                    self.menuVars.openedCombo = '';
                    self.menuVars.inputBlocker = self.menuVars.inputBlocker - 1;
                end
            end

            if element.value.secondPane or secondPane then
                self.menuVars.menuYOffsetTabSecondary = self.menuVars.menuYOffsetTabSecondary + addToOffset;
            else
                self.menuVars.menuYOffsetTab = self.menuVars.menuYOffsetTab + addToOffset;
            end
        else
            return (((element.value.secondPane or secondPane) and self.menuVars.menuYOffsetTabSecondary or self.menuVars.menuYOffsetTab) + addToOffset) - oldYSpacing;
        end
    end;

    drawOptionBox = function(self, element, secondPane, simulation)
        local oldYSpacing = (element.value.secondPane or secondPane) and self.menuVars.menuYOffsetTabSecondary or self.menuVars.menuYOffsetTab;
        local pos = { x = self.menuVars.menuX + self.menuVars.menuXOffset + ((element.value.secondPane or secondPane) and self.menuSizes.windowPane.width or 0) + self.menuVars.textSpacer, y = self.menuVars.menuY + ((element.value.secondPane or secondPane) and self.menuVars.menuYOffsetTabSecondary or self.menuVars.menuYOffsetTab) }
        local addToOffset = self.menuSizes.infoBox.padding.top + (self.menuSizes.infoBox.boxOutline*2) + self.menuSizes.infoBox.boxSize.height;
        
        pos.y = pos.y + (self.menuSizes.infoBox.boxOutline*2)
        pos.y = pos.y + self.menuSizes.infoBox.padding.top

        if not element.value.scrollPosition then
            element.value.scrollPosition = 0;
        end

        if not simulation then
            render.draw_rectangle(pos.x - self.menuSizes.infoBox.boxOutline, pos.y - self.menuSizes.infoBox.boxOutline, self.menuSizes.infoBox.boxSize.width + (self.menuSizes.infoBox.boxOutline*2), self.menuSizes.infoBox.boxSize.height + (self.menuSizes.infoBox.boxOutline*2), self.menuSizes.infoBox.boxOutlineColor.r, self.menuSizes.infoBox.boxOutlineColor.g, self.menuSizes.infoBox.boxOutlineColor.b, self.menuSizes.infoBox.boxOutlineColor.a, 1, true)
            render.draw_rectangle(pos.x, pos.y, self.menuSizes.infoBox.boxSize.width, self.menuSizes.infoBox.boxSize.height, self.menuSizes.infoBox.boxColor.r, self.menuSizes.infoBox.boxColor.g, self.menuSizes.infoBox.boxColor.b, self.menuSizes.infoBox.boxColor.a, 1, true)
            
            local willOverflow = (#element.value.options)*self.menuSizes.infoBox.optionSize.height > self.menuSizes.infoBox.boxSize.height

            local i = 0;
            local includedCount = 0;
            local maxOptions = self.menuSizes.infoBox.boxSize.height/self.menuSizes.infoBox.optionSize.height

            for _, option in ipairs(element.value.options) do
                if i >= element.value.scrollPosition then
                    if (includedCount)*self.menuSizes.infoBox.optionSize.height < self.menuSizes.infoBox.boxSize.height then
                        local optionPosition = { x = pos.x, y = pos.y + (includedCount) * self.menuSizes.infoBox.optionSize.height };

                        local optionHovered = self:isHovering(optionPosition.x, optionPosition.y, self.menuSizes.infoBox.optionSize.width, self.menuSizes.infoBox.optionSize.height);
                        if optionHovered then
                            local leftClicked = self:didClick(1, element.key);
                            local rightClicked = self:didClick(2, element.key);
                            if leftClicked or rightClicked then
                                if not option.active and leftClicked or rightClicked then
                                    for __, tempOption in ipairs(element.value.options) do
                                        tempOption.active = false;
                                    end;
                                    option.active = leftClicked;
                                    if leftClicked then
                                        element.value.activeOption = option.name;
                                    else
                                        element.value.activeOption = nil;
                                    end
                                    if option.callback then
                                        option.callback(element, option);
                                    end
                                    if element.value.callback then
                                        element.value.callback(element, option);
                                    end
                                end
                            end
                        end

                        if optionHovered or option.active then
                            render.draw_rectangle(optionPosition.x, optionPosition.y, self.menuSizes.infoBox.optionSize.width, self.menuSizes.infoBox.optionSize.height, self.menuSizes.infoBox.boxOptionHover.r, self.menuSizes.infoBox.boxOptionHover.g, self.menuSizes.infoBox.boxOptionHover.b, self.menuSizes.infoBox.boxOptionHover.a, 1, true)
                        end

                        local textColor = (option.active or option.loaded) and self.menuSizes.infoBox.selectedOptionColor or {r = 255, g = 255, b = 255, a = 255}
                            
                        draw:dText(draw.fonts.menu.font, option.name, optionPosition.x + 5, optionPosition.y + 2, textColor.r, textColor.g, textColor.b, textColor.a, false)
                    end
                    includedCount = includedCount + 1;
                end

                i = i + 1;
            end

            if willOverflow then
                render.draw_rectangle(pos.x + self.menuSizes.infoBox.boxSize.width + 4, pos.y, 6, self.menuSizes.infoBox.boxSize.height, 35, 35, 35, 255, 1, true)
            
                local scrollbarHeight = self.menuSizes.infoBox.boxSize.height / #element.value.options * maxOptions
                local scrollbarY = pos.y + (self.menuSizes.infoBox.boxSize.height - scrollbarHeight) * (element.value.scrollPosition / (#element.value.options - maxOptions))
            
                render.draw_rectangle(pos.x + self.menuSizes.infoBox.boxSize.width + 4, scrollbarY, 6, scrollbarHeight, 100, 100, 100, 255, 1, true)

                if willOverflow then
                    render.draw_rectangle(pos.x + self.menuSizes.infoBox.boxSize.width + 4, pos.y, 6, self.menuSizes.infoBox.boxSize.height, 35, 35, 35, 255, 1, true)
                    
                    local scrollbarHeight = self.menuSizes.infoBox.boxSize.height / #element.value.options * maxOptions
                    local scrollbarY = pos.y + (self.menuSizes.infoBox.boxSize.height - scrollbarHeight) * (element.value.scrollPosition / (#element.value.options - maxOptions))
                    
                    render.draw_rectangle(pos.x + self.menuSizes.infoBox.boxSize.width + 4, scrollbarY, 6, scrollbarHeight, 100, 100, 100, 255, 1, true)
                
                    local scrollHovered = self:isHovering(pos.x + self.menuSizes.infoBox.boxSize.width + 4, pos.y, 6, self.menuSizes.infoBox.boxSize.height)
                    if scrollHovered or self.menuVars.leftClickedElementName == element.key then
                        if self:didClick(1, element, true) then
                            local clickY = self.mouseY
                            local newScrollPosition = math.floor(((clickY - pos.y) / self.menuSizes.infoBox.boxSize.height) * (#element.value.options - maxOptions) + 0.5)
                            element.value.scrollPosition = math.max(0, math.min(#element.value.options - maxOptions, newScrollPosition))
                        end
                    end
                    
                    local boxHovered = self:isHovering(pos.x, pos.y, self.menuSizes.infoBox.boxSize.width, self.menuSizes.infoBox.boxSize.height)
                    if boxHovered or scrollHovered then
                        if self.didScroll == 0 and element.value.scrollPosition < (#element.value.options - maxOptions) then
                            element.value.scrollPosition = element.value.scrollPosition + 1
                        elseif self.didScroll == 1 and element.value.scrollPosition > 0 then
                            element.value.scrollPosition = element.value.scrollPosition - 1
                        end
                    end
                end
            
                local boxHovered = self:isHovering(pos.x, pos.y, self.menuSizes.infoBox.boxSize.width, self.menuSizes.infoBox.boxSize.height)
                if boxHovered then
                    if self.didScroll == 0 and element.value.scrollPosition < (#element.value.options - maxOptions) then
                        element.value.scrollPosition = element.value.scrollPosition + 1
                    elseif self.didScroll == 1 and element.value.scrollPosition > 0 then
                        element.value.scrollPosition = element.value.scrollPosition - 1
                    end
                end
            end

            if element.value.secondPane or secondPane then
                self.menuVars.menuYOffsetTabSecondary = self.menuVars.menuYOffsetTabSecondary + addToOffset;
            else
                self.menuVars.menuYOffsetTab = self.menuVars.menuYOffsetTab + addToOffset;
            end
        else
            return (((element.value.secondPane or secondPane) and self.menuVars.menuYOffsetTabSecondary or self.menuVars.menuYOffsetTab) + addToOffset) - oldYSpacing;
        end;
    end;

    drawMultiselect = function(self, element, secondPane, simulation)
        local oldYSpacing = (element.value.secondPane or secondPane) and self.menuVars.menuYOffsetTabSecondary or self.menuVars.menuYOffsetTab;
        local pos = { x = self.menuVars.menuX + self.menuVars.menuXOffset + ((element.value.secondPane or secondPane) and self.menuSizes.windowPane.width or 0) + self.menuVars.textSpacer, y = self.menuVars.menuY + ((element.value.secondPane or secondPane) and self.menuVars.menuYOffsetTabSecondary or self.menuVars.menuYOffsetTab) }
        local addToOffset = self.menuSizes.multiselect.padding.top + (self.menuSizes.multiselect.boxOutline*2) + self.menuSizes.multiselect.boxSize.height;

        pos.y = pos.y + (self.menuSizes.multiselect.boxOutline*2)
        pos.y = pos.y + self.menuSizes.multiselect.padding.top

        if element.value.doText then
            pos.y = pos.y + (draw.fonts.menu.height + self.menuSizes.slider.textBoxSpacing);
            addToOffset = addToOffset + (draw.fonts.menu.height + self.menuSizes.slider.textBoxSpacing);
        end

        local textPos = { x = pos.x, y = pos.y };
        textPos.y = textPos.y - (draw.fonts.menu.height) - (self.menuSizes.multiselect.textBoxSpacing) - self.menuSizes.multiselect.boxOutline;

        local hasClicked = false;

        local opened = (self.menuVars.openedMulti == '') and false or (element.key == self.menuVars.openedMulti);

        if opened then --draw dropdown triangles
            
        else

        end

        if not simulation then
            if element.value.doText then
                draw:dText(draw.fonts.menu.font, element.key, textPos.x, textPos.y, 255, 255, 255, 255, false)
                -- textPos.y = (textPos.y + draw.fonts.menu.height + self.menuSizes.multiselect.textBoxSpacing + (self.menuSizes.multiselect.boxSize.height/2)) - (draw.fonts.menu.height/2) - 1--(self.menuSizes.multiselect.boxSize.height/3 + (draw.fonts.menu.height));
            end;
            textPos.y = pos.y + (self.menuSizes.multiselect.boxSize.height / 2) - (draw.fonts.menu.height / 2);

            local selectedCount = 0;
            for _, option in ipairs(element.value.options) do
                if option.value then
                    selectedCount = selectedCount + 1;
                end
            end

            render.draw_rectangle(pos.x - self.menuSizes.multiselect.boxOutline, pos.y - self.menuSizes.multiselect.boxOutline, self.menuSizes.multiselect.boxSize.width + (self.menuSizes.multiselect.boxOutline*2), self.menuSizes.multiselect.boxSize.height + (self.menuSizes.multiselect.boxOutline*2), self.menuSizes.multiselect.boxOutlineColor.r, self.menuSizes.multiselect.boxOutlineColor.g, self.menuSizes.multiselect.boxOutlineColor.b, self.menuSizes.multiselect.boxOutlineColor.a, 1, true)
            
            local isHovered = self:isHovering(pos.x, pos.y, self.menuSizes.multiselect.boxSize.width, 20);
            if isHovered and not self.menuVars.isHovering and (self.menuVars.leftClickedElementName == '') then
                render.draw_rectangle(pos.x, pos.y, self.menuSizes.multiselect.boxSize.width, self.menuSizes.multiselect.boxSize.height, self.menuSizes.multiselect.boxHoverColor.r, self.menuSizes.multiselect.boxHoverColor.g, self.menuSizes.multiselect.boxHoverColor.b, self.menuSizes.multiselect.boxHoverColor.a, 1, true)
                if not hasClicked then hasClicked = self:didClick(1, element.key) end;

                if hasClicked then
                    if opened then
                        opened = false;
                        self.menuVars.openedMulti = '';
                        self.menuVars.inputBlocker = self.menuVars.inputBlocker - 1;
                    else
                        local wasOpen = opened;
                        opened = not opened;
                        self.menuVars.openedMulti = element.key;
                        self.menuVars.inputBlocker = self.menuVars.inputBlocker + ((opened ~= wasOpen) and (opened and 1 or -1) or 0)--(opened ~= wasOpen) and (opened and 1 or -1) or 0;
                    end
                end
                self.menuVars.isHovering = true;
            else
                render.draw_rectangle(pos.x, pos.y, self.menuSizes.multiselect.boxSize.width, self.menuSizes.multiselect.boxSize.height, self.menuSizes.multiselect.boxColor.r, self.menuSizes.multiselect.boxColor.g, self.menuSizes.multiselect.boxColor.b, self.menuSizes.multiselect.boxColor.a, 1, true)
            end

            draw:dText(draw.fonts.menu.font, tostring(selectedCount) .. ' Selected', textPos.x + 5, textPos.y, 255, 255, 255, 255, false)

            if opened then
                local i = 0;
                for _, option in ipairs(element.value.options) do
                    local optionPosition = { x = pos.x, y = pos.y + (i + 1) * self.menuSizes.multiselect.boxSize.height };

                    self:addLateCall(render.draw_rectangle,  optionPosition.x, optionPosition.y, self.menuSizes.multiselect.boxSize.width, self.menuSizes.multiselect.boxSize.height, self.menuSizes.multiselect.boxDropdownColor.r, self.menuSizes.multiselect.boxDropdownColor.g, self.menuSizes.multiselect.boxDropdownColor.b, self.menuSizes.multiselect.boxDropdownColor.a, 1, true)
                    
                    local optionHovered = self:isHovering(optionPosition.x, optionPosition.y, self.menuSizes.multiselect.boxSize.width, self.menuSizes.multiselect.boxSize.height);
                    if optionHovered then
                        self:addLateCall(render.draw_rectangle,  optionPosition.x, optionPosition.y, self.menuSizes.multiselect.boxSize.width, self.menuSizes.multiselect.boxSize.height, self.menuSizes.multiselect.optionHovered.r, self.menuSizes.multiselect.optionHovered.g, self.menuSizes.multiselect.optionHovered.b, self.menuSizes.multiselect.optionHovered.a, 1, true)
                        if not hasClicked then hasClicked = self:didClick(1, element.key) end;

                        if hasClicked then
                            option.value = not option.value;
                        end
                    end

                    local textColor = option.value and self.menuSizes.multiselect.selectedOptionColor or {r = 255, g = 255, b = 255, a = 255}
                    
                    self:addLateCall(draw.dText, draw, draw.fonts.menu.font, option.key, optionPosition.x + 5, optionPosition.y + (draw.fonts.menu.height/2), textColor.r, textColor.g, textColor.b, textColor.a, false)

                    i = i + 1;
                end

                local globalHovered = self:isHovering(pos.x, pos.y, self.menuSizes.multiselect.boxSize.width, (#element.value.options * self.menuSizes.multiselect.boxSize.height) + self.menuSizes.multiselect.boxSize.height);
                if not globalHovered then
                    if not hasClicked then hasClicked = self:didClick(1, element.key) end;

                    if hasClicked then
                        self.menuVars.openedMulti = '';
                        self.menuVars.inputBlocker = self.menuVars.inputBlocker - 1;
                        self.menuVars.isHovering = true;
                    end
                else
                    self.menuVars.isHovering = true;
                end

                if input.is_key_down(keys.ESC.offset) or input.is_key_down(draw.cachedUiVars.configs.config.menuKey.value.activeKey) then
                    self.menuVars.openedMulti = '';
                    self.menuVars.inputBlocker = self.menuVars.inputBlocker - 1;
                end
            end

            if element.value.secondPane or secondPane then
                self.menuVars.menuYOffsetTabSecondary = self.menuVars.menuYOffsetTabSecondary + addToOffset;
            else
                self.menuVars.menuYOffsetTab = self.menuVars.menuYOffsetTab + addToOffset;
            end
        else
            return (((element.value.secondPane or secondPane) and self.menuVars.menuYOffsetTabSecondary or self.menuVars.menuYOffsetTab) + addToOffset) - oldYSpacing;
        end
    end;

    inputBoxInput = {
        validKeys = {
            "Q";
            "W";
            "E";
            "R";
            "T";
            "Y";
            "U";
            "I";
            "O";
            "P";
            "A";
            "S";
            "D";
            "F";
            "G";
            "H";
            "J";
            "K";
            "L";
            "Z";
            "X";
            "C";
            "V";
            "B";
            "N";
            "M";
            "1";
            "2";
            "3";
            "4";
            "5";
            "6";
            "7";
            "8";
            "9";
            "0";
            "SPC";
            "BKS";
        };

        resetVars = function(self)
            self.lastBackspaceTime = nil;
            self.lastBackspaceWhileHeld = nil;
        end;

        isAnyInput = function(self, element)
            for i = 1, #self.validKeys do
                local key = keys[self.validKeys[i]]
                if key then
                    if self.validKeys[i] == "BKS" then --backspace
                        if input.is_key_down(key.offset) then
                            if not self.lastBackspaceTime then
                                self.lastBackspaceTime = winapi.get_tickcount64();
                                return self.validKeys[i];
                            end

                            if winapi.get_tickcount64() > self.lastBackspaceTime + 370 then
                                if winapi.get_tickcount64() > (self.lastBackspaceWhileHeld or 0) + 27 then
                                    self.lastBackspaceWhileHeld = winapi.get_tickcount64();
                                    return self.validKeys[i];
                                end
                            end
                        else
                            self:resetVars()
                        end
                    else
                        if input.is_key_pressed(key.offset) then
                            local inputName = self.validKeys[i];
                            if inputName == "SPC" then
                                inputName = " "
                            end
        
                            return inputName;
                        end
                    end
                end
            end
            
            return false;
        end;
    };

    drawInputBox = function(self, element, secondPane, simulation)
        local oldYSpacing = (element.value.secondPane or secondPane) and self.menuVars.menuYOffsetTabSecondary or self.menuVars.menuYOffsetTab;
        local pos = { x = self.menuVars.menuX + self.menuVars.menuXOffset + ((element.value.secondPane or secondPane) and self.menuSizes.windowPane.width or 0) + self.menuVars.textSpacer, y = self.menuVars.menuY + ((element.value.secondPane or secondPane) and self.menuVars.menuYOffsetTabSecondary or self.menuVars.menuYOffsetTab) }
        local addToOffset = self.menuSizes.inputBox.padding.top + (self.menuSizes.inputBox.boxOutline*2) + self.menuSizes.inputBox.boxSize.height;

        pos.y = pos.y + (self.menuSizes.inputBox.boxOutline*2)
        pos.y = pos.y + self.menuSizes.inputBox.padding.top

        if element.value.doText then
            pos.y = pos.y + (draw.fonts.menu.height + self.menuSizes.slider.textBoxSpacing);
            addToOffset = addToOffset + (draw.fonts.menu.height + self.menuSizes.slider.textBoxSpacing);
        end

        local textPos = { x = pos.x, y = pos.y };
        textPos.y = textPos.y - (draw.fonts.menu.height) - (self.menuSizes.inputBox.textBoxSpacing) - self.menuSizes.inputBox.boxOutline;

        local hasClicked = false;

        local opened = (self.menuVars.openedInputBox == '') and false or (element.key == self.menuVars.openedInputBox);

        if not simulation then
            if element.value.doText then
                if string.len(element.key) > 0 then
                    draw:dText(draw.fonts.menu.font, element.key, textPos.x, textPos.y, 255, 255, 255, 255, false)
                end
                -- textPos.y = (textPos.y + draw.fonts.menu.height + self.menuSizes.inputBox.textBoxSpacing + (self.menuSizes.inputBox.boxSize.height/2)) - (draw.fonts.menu.height/2) - 1--(self.menuSizes.inputBox.boxSize.height/3 + (draw.fonts.menu.height));
            end;
            textPos.y = pos.y + (self.menuSizes.inputBox.boxSize.height / 2) - (draw.fonts.menu.height / 2);

            render.draw_rectangle(pos.x - self.menuSizes.inputBox.boxOutline, pos.y - self.menuSizes.inputBox.boxOutline, self.menuSizes.inputBox.boxSize.width + (self.menuSizes.inputBox.boxOutline*2), self.menuSizes.inputBox.boxSize.height + (self.menuSizes.inputBox.boxOutline*2), self.menuSizes.inputBox.boxOutlineColor.r, self.menuSizes.inputBox.boxOutlineColor.g, self.menuSizes.inputBox.boxOutlineColor.b, self.menuSizes.inputBox.boxOutlineColor.a, 1, true)
            render.draw_rectangle(pos.x, pos.y, self.menuSizes.inputBox.boxSize.width, self.menuSizes.inputBox.boxSize.height, self.menuSizes.inputBox.boxColor.r, self.menuSizes.inputBox.boxColor.g, self.menuSizes.inputBox.boxColor.b, self.menuSizes.inputBox.boxColor.a, 1, true)

            local isHovered = self:isHovering(pos.x, pos.y, self.menuSizes.inputBox.boxSize.width, 20);
            if isHovered and not self.menuVars.isHovering and (self.menuVars.leftClickedElementName == '') then
                if not hasClicked then hasClicked = self:didClick(1, element.key) end;

                if hasClicked then
                    if opened then
                        opened = false;
                        self.menuVars.openedInputBox = '';
                        self.menuVars.inputBlocker = self.menuVars.inputBlocker - 1;
                        self.menuVars.isHovering = false;
                        self.inputBoxInput:resetVars()
                        --self.menuVars.recentlyCalledLeftClick = false;
                        --self.menuVars.leftClickedElementName = "";
                    else
                        if self.menuVars.openedInputBox == '' then
                            local wasOpen = opened;
                            opened = not opened;
                            self.menuVars.openedInputBox = element.key;
                            local oldBlocker = self.menuVars.inputBlocker;
                            self.menuVars.inputBlocker = self.menuVars.inputBlocker + ((opened ~= wasOpen) and (opened and 1 or -1) or 0)--(opened ~= wasOpen) and (opened and 1 or -1) or 0;
                        end
                    end
                end
                self.menuVars.isHovering = true;
            end

            if opened then
                if element.value.typedText and string.len(element.value.typedText) > 0 then
                    draw:dText(draw.fonts.menu.font, (element.value.typedText or "") .. "_", textPos.x + 5, textPos.y + 2, self.menuSizes.inputBox.typedTextColor.r, self.menuSizes.inputBox.typedTextColor.g, self.menuSizes.inputBox.typedTextColor.b, self.menuSizes.inputBox.typedTextColor.a, false)
                end

                local isAnyInput = self.inputBoxInput:isAnyInput(element);
                if isAnyInput then
                    if not element.value.typedText then
                        element.value.typedText = "";
                    end

                    if isAnyInput == "BKS" then
                        if #element.value.typedText > 0 then
                            element.value.typedText = element.value.typedText:sub(1, -2)
                        end;
                    else
                        element.value.typedText = element.value.typedText .. string.lower(isAnyInput);
                    end
                end

                if not isHovered then
                    if self.mouseDown then
                        self.menuVars.openedInputBox = '';
                        self.inputBoxInput:resetVars()
                        self.menuVars.inputBlocker = self.menuVars.inputBlocker - 1;
                        self.menuVars.isHovering = false;
                    end
                else
                    self.menuVars.isHovering = true;
                end

                if input.is_key_down(keys.ESC.offset) or input.is_key_down(draw.cachedUiVars.configs.config.menuKey.value.activeKey) or input.is_key_down(keys.ENT.offset) then
                    self.menuVars.openedInputBox = '';
                    self.inputBoxInput:resetVars()
                    self.menuVars.inputBlocker = self.menuVars.inputBlocker - 1;
                end
            else
                if element.value.typedText and string.len(element.value.typedText) > 0 then
                    draw:dText(draw.fonts.menu.font, element.value.typedText or "_", textPos.x + 5, textPos.y + 2, 255, 255, 255, 255, false)
                else
                    draw:dText(draw.fonts.menu.font, "_", textPos.x + 5, textPos.y + 2, 255, 255, 255, 255, false)
                end
            end

            if element.value.secondPane or secondPane then
                self.menuVars.menuYOffsetTabSecondary = self.menuVars.menuYOffsetTabSecondary + addToOffset;
            else
                self.menuVars.menuYOffsetTab = self.menuVars.menuYOffsetTab + addToOffset;
            end
        else
            return (((element.value.secondPane or secondPane) and self.menuVars.menuYOffsetTabSecondary or self.menuVars.menuYOffsetTab) + addToOffset) - oldYSpacing;
        end
    end;

    drawPaneTab = function(self, paneTab, paneEndPosy, paneStartPosy, paneStartPosx, paneWidths, outlineFixed, rightPane)
        local totalHeight = paneEndPosy - paneStartPosy
        local totalCustomHeight = 0
        local paneCountWithoutHeight = #paneTab
        local gap = self.menuSizes.windowPane.multiVerticalPadding
        local totalGapHeight = gap * (#paneTab - 1)
        local xPosition
        
        if rightPane then
            xPosition = paneStartPosx + paneWidths + outlineFixed;
        else
            xPosition = paneStartPosx;
        end

        for _, pane in ipairs(paneTab) do
            if pane.height then
                totalCustomHeight = totalCustomHeight + pane.height
                paneCountWithoutHeight = paneCountWithoutHeight - 1
            end
        end

        local availableHeightForPanes = totalHeight - totalGapHeight -- adjust total height for panes by subtracting gap heights
        local defaultHeight = (availableHeightForPanes - totalCustomHeight) / paneCountWithoutHeight -- height for panes without custom height
        local currentPosY = paneStartPosy -- current vertical position to start drawing the next pane

        if rightPane then
            self.menuVars.menuYOffsetTabSecondary = self.menuVars.menuYOffsetTabSecondary + self.menuSizes.windowPane.textSpecifierElementPadding;
        else
            self.menuVars.menuYOffsetTab = self.menuVars.menuYOffsetTab + self.menuSizes.windowPane.textSpecifierElementPadding;
        end

        -- second pass to draw panes with their respective heights and gaps
        for i, pane in ipairs(paneTab) do
            local paneHeight = pane.height or defaultHeight -- Use custom height if available, otherwise default

            if i == #paneTab then -- Check if it's the last pane
                --local w = currentPosY;

                paneHeight = paneEndPosy - currentPosY--totalHeight - (currentPosY - paneStartPosy) - totalGapHeight + gap -- calculate the remaining height for the last pane

                --if paneHeight < 0 then paneHeight = 0 end
            end

            render.draw_rectangle(xPosition - self.menuSizes.windowPane.paneOutline, currentPosY - self.menuSizes.windowPane.paneOutline, paneWidths + (self.menuSizes.windowPane.paneOutline*2), paneHeight + (self.menuSizes.windowPane.paneOutline*2), self.menuSizes.windowPane.paneOutlineColor.r, self.menuSizes.windowPane.paneOutlineColor.g, self.menuSizes.windowPane.paneOutlineColor.b, self.menuSizes.windowPane.paneOutlineColor.a, 1, true)
            render.draw_rectangle(xPosition, currentPosY, paneWidths, paneHeight, self.menuSizes.windowPane.paneBackgroundColor.r, self.menuSizes.windowPane.paneBackgroundColor.g, self.menuSizes.windowPane.paneBackgroundColor.b, self.menuSizes.windowPane.paneBackgroundColor.a, 1, true)
            
            if pane.paneName then
                local stringLength = render.measure_text(draw.fonts.subtab.font, pane.paneName)
                render.draw_rectangle((xPosition + 9) - self.menuSizes.windowPane.paneOutline, currentPosY - self.menuSizes.windowPane.paneOutline, stringLength + 9, self.menuSizes.windowPane.paneOutline, self.menuSizes.windowPane.paneBackgroundColor.r, self.menuSizes.windowPane.paneBackgroundColor.g, self.menuSizes.windowPane.paneBackgroundColor.b, self.menuSizes.windowPane.paneBackgroundColor.a, 1, true)
                draw:dText(draw.fonts.subtab.font, pane.paneName, xPosition + 13, currentPosY - 8, 255, 255, 255, 255, false)
            end
            
            currentPosY = currentPosY + paneHeight -- opdate position for the next pane

            local oldYOffset = self.menuVars.menuYOffsetTab;
            if rightPane then
                oldYOffset = self.menuVars.menuYOffsetTabSecondary
            end

            if pane.elements then
                for _, element in ipairs(pane.elements) do
                    self:handleElement(element, rightPane);
                end
            end

            --Context:DrawRectangle(300, self.menuVars.menuY + self.menuVars.menuYOffsetTab, 700, 1, 255, 255, 255, 255, 1, true)

            if rightPane then
                self.menuVars.menuYOffsetTabSecondary = oldYOffset + paneHeight + self.menuSizes.windowPane.multiVerticalPadding--[[ + (self.menuSizes.windowPane.paneOutline*2)]];
            else
                self.menuVars.menuYOffsetTab = oldYOffset + paneHeight + self.menuSizes.windowPane.multiVerticalPadding --self.menuVars.menuYOffsetTab;
            end

            if i < #paneTab then 
                currentPosY = currentPosY + gap
            end
        end
    end;
    
    drawPanes = function(self, leftPanes, rightPanes)
        local outlineFixed = self.menuSizes.windowPane.padding.middle + (self.menuSizes.windowPane.paneOutline*2)
        local paneStartPosx = self.menuVars.menuX + (self.menuVars.menuXOffset) + self.menuSizes.windowPane.padding.width-- + self.menuSizes.windowPane.paneOutline--((self.menuVars.menuX + (self.menuVars.menuXOffset)) - 5) + self.menuSizes.windowPane.padding.width + self.menuSizes.windowPane.paneOutline--((self.menuVars.menuX + (self.menuVars.menuXOffset))) + self.menuSizes.windowPane.padding.width;
        local paneEndPosx = ((self.menuVars.menuX + (self.menuVars.menuWidth)) - self.menuSizes.windowPane.padding.width) - (self.menuSizes.windowPane.paneOutline*2)--(((paneStartPosx + (self.menuVars.menuWidth - (self.menuVars.menuXOffset))) - 1) - self.menuSizes.windowPane.padding.width) - (self.menuSizes.windowPane.paneOutline*2)--paneStartPosx + ((self.menuVars.menuWidth - (self.menuVars.menuXOffset)));
        local paneStartPosy = self.menuVars.menuY + (self.menuVars.menuYOffsetTabSecondary);
        local paneEndPosy = self.menuVars.menuY + self.menuVars.menuHeight - (self.menuSizes.windowPane.padding.height + self.menuSizes.windowPane.paneOutline)
        local paneWidths = (paneEndPosx - paneStartPosx)/2 - (outlineFixed/2);--(paneEndPosx - paneStartPosx)/2 - self.menuSizes.windowPane.padding.middle;

        self.menuSizes.windowPane.width = paneWidths + outlineFixed;

        if leftPanes then
            self.menuVars.menuXOffset = self.menuVars.menuXOffset + self.menuSizes.windowPane.paneOutline + self.menuSizes.windowPane.padding.width
            self:drawPaneTab(leftPanes, paneEndPosy, paneStartPosy, paneStartPosx, paneWidths, outlineFixed);
        end
        if rightPanes then
            if not leftPanes then
                self.menuVars.menuXOffset = self.menuVars.menuXOffset + self.menuSizes.windowPane.paneOutline + self.menuSizes.windowPane.padding.width
            end
            self:drawPaneTab(rightPanes, paneEndPosy, paneStartPosy, paneStartPosx, paneWidths, outlineFixed, true);
        end
    end;

    updateDidClick = function(self)
        self.menuVars.recentlyCalledLeftClick = false;
        self.menuVars.recentlyCalledRightClick = false;

        if self.mouseDown then
            if not self.menuVars.wasLeftClicking then
                self.menuVars.didLeftClick = true;
                self.menuVars.wasLeftClicking = true
            end
        else
            if self.menuVars.wasLeftClicking then
                self.menuVars.wasLeftClicking = false
                self.menuVars.leftClickedElementName = "";
            end
        end

        if self.rightMouseDown then
            if not self.menuVars.wasRightClicking then
                self.menuVars.didRightClick = true;
                self.menuVars.wasRightClicking = true
            end
        else
            if self.menuVars.wasRightClicking then
                self.menuVars.wasRightClicking = false
                self.menuVars.rightClickedElementName = "";
            end
        end
    end;

    drawStart = function(self, context)
        self:updateInformation();

        if input.is_key_pressed(draw.cachedUiVars.configs and draw.cachedUiVars.configs.config.menuKey.value.activeKey or keys.INS.offset) then
            self.menuVars.menuOpen = not self.menuVars.menuOpen;
            if not input.is_menu_open() then
                input.set_overlay_force_cursor_active(self.menuVars.menuOpen);
            end
        end

        if self.wasEpaOpen ~= self.epaMenuOpen and self.menuVars.menuOpen then
            self.lastOpenTime = winapi.get_tickcount64()
        end
        
        self.wasEpaOpen = self.epaMenuOpen;

        if self.lastOpenTime and self.lastOpenTime + 60 < winapi.get_tickcount64() then
            self.menuVars.menuOpen = true;
            input.set_overlay_force_cursor_active(self.menuVars.menuOpen);
            self.lastOpenTime = nil;
        end

        if self.menuVars.menuOpen then
            --outline
            render.draw_rectangle(self.menuVars.menuX - 5, self.menuVars.menuY - 5, self.menuVars.menuWidth + 10, self.menuVars.menuHeight + 10, 15, 15, 15, self.menuSizes.windowPreBorder.a, 2, false)
            render.draw_rectangle(self.menuVars.menuX - 4, self.menuVars.menuY - 4, self.menuVars.menuWidth + 8, self.menuVars.menuHeight + 8, 40, 40, 40, self.menuSizes.windowPreBorder.a, 2, false)
            render.draw_rectangle(self.menuVars.menuX - 3, self.menuVars.menuY - 3, self.menuVars.menuWidth + 6, self.menuVars.menuHeight + 6, 65, 65, 65, self.menuSizes.windowPreBorder.a, 3, false)
            render.draw_rectangle(self.menuVars.menuX - 1, self.menuVars.menuY - 1, self.menuVars.menuWidth + 2, self.menuVars.menuHeight + 2, 40, 40, 40, self.menuSizes.windowPreBorder.a, 2, false)

            --main window
            --self:drawGridBackground({x = self.menuVars.menuX, y = self.menuVars.menuY}, self.menuVars.menuWidth, self.menuVars.menuHeight);--OLD--Context:DrawRectangle(self.menuVars.menuX, self.menuVars.menuY, self.menuVars.menuWidth, self.menuVars.menuHeight, self.menuSizes.mainWindowBackground.r, self.menuSizes.mainWindowBackground.g, self.menuSizes.mainWindowBackground.b, self.menuSizes.mainWindowBackground.a, 1, true)
            render.draw_rectangle(self.menuVars.menuX, self.menuVars.menuY, self.menuVars.menuWidth, self.menuVars.menuHeight, self.menuSizes.mainWindowBackground.r, self.menuSizes.mainWindowBackground.g, self.menuSizes.mainWindowBackground.b, self.menuSizes.mainWindowBackground.a, 1, true)

            self:updateDidClick();

            --vertical tabs
            self.menuVars.currentVerticalTab = self:drawVerticalTabs();

            local i = 0
            for _, tab in ipairs(cheat.menuElements) do
                if (i + 1) == self.menuVars.currentVerticalTab then
                if tab.menuSubtabs then
                        tab.currentSubtab = self:drawSubTabs(tab.menuSubtabs, tab.currentSubtab)
                        if tab.menuSubtabs[1] and tab.menuSubtabs[1].disableCheck then
                            tab.showTab = 1;
                        else
                            tab.showTab = tab.currentSubtab;
                        end

                        self:drawPanes(tab.menuSubtabs[tab.showTab].leftPanes, tab.menuSubtabs[tab.showTab].rightPanes)
                        if tab.menuSubtabs[tab.showTab].elements then
                            for _, element in ipairs(tab.menuSubtabs[tab.showTab].elements) do
                                self:handleElement(element);
                            end
                        end
                        
                    else
                        if tab.leftPanes or tab.rightPanes then
                            self:drawPanes(tab.leftPanes, tab.rightPanes)
                        end
                        if tab.elements then
                            for _, element in ipairs(tab.elements) do
                                self:handleElement(element);
                            end
                        end
                    end
                end
                i = i + 1
            end

            --resize handling
            local cornerHovered = self:isHovering(self.menuVars.menuX + self.menuVars.menuWidth - 10, self.menuVars.menuY + self.menuVars.menuHeight - 10, 20, 20);
            if cornerHovered and self.mouseDown and input.is_key_down(keys.LCTL.offset) then
                if not self.menuVars.isResizing then
                    self.menuVars.isResizing = true
                    self.menuVars.initialClickX = self.mouseX
                    self.menuVars.initialClickY = self.mouseY
                end
            elseif self.menuVars.isResizing then
                if self.mouseDown and input.is_key_down(keys.LCTL.offset) then
                    local dragEndX = self.mouseX
                    local dragEndY = self.mouseY

                    -- Calculate the new width and height based on mouse drag
                    local newWidth = dragEndX - self.menuVars.menuX
                    local newHeight = dragEndY - self.menuVars.menuY

                    -- Optional: Add constraints to prevent the menu from becoming too small or too large
                    newWidth = math.max(newWidth, self.menuVars.minimumWidth or self.menuVars.defaultMenuWidth)
                    newHeight = math.max(newHeight, self.menuVars.minimumHeight or self.menuVars.defaultMenuHeight)

                    -- Update menu width and height
                    self.menuVars.menuWidth = newWidth
                    self.menuVars.menuHeight = newHeight
                else
                    self.menuVars.isResizing = false
                end
            --end
            else
                --drag handling
                if (self.menuVars.wasDragging or not self.menuVars.isHovering) and self.mouseDown and self:isHovering(self.menuVars.menuX, self.menuVars.menuY, self.menuVars.menuWidth, self.menuVars.menuHeight) and self.menuVars.leftClickedElementName == '' then
                    if self.menuVars.dragX == 0 then
                        self.menuVars.dragX = (self.mouseX - self.menuVars.menuX)
                        self.menuVars.dragY = (self.mouseY - self.menuVars.menuY)
                    end

                    if self.mouseX - self.menuVars.dragX < 0 then
                        self.menuVars.menuX = 0
                    elseif self.mouseX - self.menuVars.dragX > self.screenSize.x - self.menuVars.menuWidth then
                        self.menuVars.menuX = self.screenSize.x - self.menuVars.menuWidth
                    else
                        self.menuVars.menuX = self.mouseX - self.menuVars.dragX
                    end

                    if self.mouseY - self.menuVars.dragY < 0 then
                        self.menuVars.menuY = 0
                    elseif self.mouseY - self.menuVars.dragY > self.screenSize.y - self.menuVars.menuHeight then
                        self.menuVars.menuY = self.screenSize.y - self.menuVars.menuHeight
                    else
                        self.menuVars.menuY = self.mouseY - self.menuVars.dragY
                    end
                    self.menuVars.wasDragging = true;
                else
                    self.menuVars.dragX = 0
                    self.menuVars.dragY = 0
                    self.menuVars.wasDragging = false;
                end
            end

            self.menuVars.isHovering = false
            self:callLateFunctions();
            self.menuVars.didLeftClick = false;
            self.menuVars.didRightClick = false;
        end
    end
};

---- ==== - FILE START - ==== ----

local bitmap = {
    sentBitmaps = {};

    getBitmap = function(self, url)
        local bitmapIndex = self.sentBitmaps[url];

        if bitmapIndex then
            if bitmapIndex.exists then
                return bitmapIndex.bitmap;
            end
        else
            self.sentBitmaps[url] = {};
            net.send_request(url, --[[referer: https://cheati.ng/radar/cs/guns/1.png
sec-ch-ua: "Brave";v="135", "Not-A.Brand";v="8", "Chromium";v="135"
sec-ch-ua-mobile: ?0
sec-ch-ua-platform: "Windows"
user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36]]"", "");
        end

        return nil;
    end;

    networkRequestCreate = function(self, data, url)
        local bitmapIndex = self.sentBitmaps[url];

        if bitmapIndex then
            log("creating: ", m.get_size(data));
            bitmapIndex.bitmap = render.create_bitmap_from_buffer(data);
            --log("creating: ", m.read_string(data, 0));

            if bitmapIndex.bitmap then
                bitmapIndex.exists = true;
            end
        end
    end;
};

game = "RUST";

cheat = {
    menuWidth = 732;
    menuHeight = 650;

    menuElements = {
        {
            tabName = "Aimbot";
            bitmap = {
                url = "https://i.imgur.com/arJBBMW.png";
                width = 50;
                height = 50;
            };
            --[[currentSubtab = 1;
            menuSubtabs = {
                {
                    subtabName = "Aim";]]
                    leftPanes = {
                        {
                            paneName = "Main Aimbot";
                            --autoAdjustForElements = true;
                            elements = {
                                {
                                    key = "Enabled";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 2;
                                        message = "Writes to memory";
                                        adaptive = true;
                                        hotkey = {
                                            key = "Aimbot Hotkey";
                                            value = {
                                                shortKeyName = "M4";
                                                activeKey = keys.M4.offset;
                                                keyState = false;
                                                allowChange = true;
                                                keyType = keyTypes.onHotkey;
                                            };
                                        };
                                    }
                                };
                                {
                                    key = "Hitboxes";
                                    value = {
                                        type = drawTypes.combobox;
                                        state = 3;
                                        doOff = false;
                                        options = {
                                            "Head";
                                            "Pelvis";
                                            "Nearest";
                                        };
                                        adaptive = true;
                                    };
                                };
                                {
                                    key = "Visible Check";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = true;
                                        checkboxType = 1;
                                        adaptive = true;
                                    };
                                };
                                {
                                    key = "Smoothing";
                                    value = {
                                        type = drawTypes.slider;
                                        state = 70;
                                        maxValue = 90.0;
                                        minValue = 28.0;
                                        decimalPoints = 1;
                                        doText = true;
                                        adaptive = true;
                                    };
                                };
                                {
                                    key = "Consistent Targeting";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = true;
                                        checkboxType = 1;
                                        message = "Keep same target when shooting";
                                        adaptive = true;
                                    };
                                };
                                {
                                    key = "Always Keep Target";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = true;
                                        checkboxType = 1;
                                        message = "Keeps Target Regardless Of FOV";
                                        adaptive = true;
                                    };
                                };
                                {
                                    key = "Target Switch Delay";
                                    value = {
                                        
                                        type = drawTypes.slider;
                                        state = 250;
                                        maxValue = 1000;
                                        minValue = 0;
                                        adaptive = true;
                                        doText = true;
                                        textSpecifier = "ms";
                                    };
                                };
                                {
                                    key = "Deadzone";
                                    value = {
                                        
                                        type = drawTypes.slider;
                                        state = 1;
                                        maxValue = 10;
                                        minValue = 1;
                                        adaptive = true;
                                        doText = true;
                                    };
                                };
                                {
                                    key = "Minimum Fov";
                                    value = {
                                        type = drawTypes.slider;
                                        state = 11;
                                        maxValue = 180;
                                        minValue = 0;
                                        doText = true;
                                        adaptive = true;
                                        textSpecifier = "*";
                                    };
                                };
                            }
                        };
                        {
                            paneName = "Alt Aimbot";
                            --autoAdjustForElements = true;
                            elements = {
                                {
                                    key = "Alt Enabled";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 2;
                                        message = "Writes to memory";
                                        adaptive = true;
                                        hotkey = {
                                            key = "Alt Aimbot Hotkey";
                                            value = {
                                                shortKeyName = "M4";
                                                activeKey = keys.M4.offset;
                                                keyState = false;
                                                allowChange = true;
                                                keyType = keyTypes.onHotkey;
                                            };
                                        };
                                    }
                                };
                                {
                                    key = "Alt Hitboxes";
                                    value = {
                                        type = drawTypes.combobox;
                                        state = 3;
                                        doOff = false;
                                        options = {
                                            "Head";
                                            "Pelvis";
                                            "Nearest";
                                        };
                                        adaptive = true;
                                    };
                                };
                                {
                                    key = "Alt Visible Check";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = true;
                                        checkboxType = 1;
                                        adaptive = true;
                                    };
                                };
                                {
                                    key = "Alt Smoothing";
                                    value = {
                                        type = drawTypes.slider;
                                        state = 70;
                                        maxValue = 90.0;
                                        minValue = 28.0;
                                        decimalPoints = 1;
                                        doText = true;
                                        adaptive = true;
                                    };
                                };
                                {
                                    key = "Alt Consistent Targeting";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = true;
                                        checkboxType = 1;
                                        message = "Keep same target when shooting";
                                        adaptive = true;
                                    };
                                };
                                {
                                    key = "Alt Always Keep Target";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = true;
                                        checkboxType = 1;
                                        message = "Keeps Target Regardless Of FOV";
                                        adaptive = true;
                                    };
                                };
                                {
                                    key = "Alt Target Switch Delay";
                                    value = {
                                        
                                        type = drawTypes.slider;
                                        state = 250;
                                        maxValue = 1000;
                                        minValue = 0;
                                        adaptive = true;
                                        doText = true;
                                        textSpecifier = "ms";
                                    };
                                };
                                {
                                    key = "Alt Deadzone";
                                    value = {
                                        
                                        type = drawTypes.slider;
                                        state = 1;
                                        maxValue = 10;
                                        minValue = 1;
                                        adaptive = true;
                                        doText = true;
                                    };
                                };
                                {
                                    key = "Alt Minimum Fov";
                                    value = {
                                        type = drawTypes.slider;
                                        state = 11;
                                        maxValue = 180;
                                        minValue = 0;
                                        doText = true;
                                        textSpecifier = "*";
                                        adaptive = true;
                                    };
                                };
                            };
                        };
                        
                    };
                    rightPanes = {
                        {
                            paneName = "Settings";
                            autoAdjustForElements = true;
                            elements = {
                                {
                                    key = "Movement Type";
                                    value = {
                                        type = drawTypes.combobox;
                                        state = 1;
                                        doOff = false;
                                        options = {
                                            "Memory";
                                            --"Mouse Movement";
                                        };
                                    };
                                };
                                {
                                    key = "Draw Fov";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "FOV Color";
                                            value = {
                                                color = {r = 255, g = 255, b = 255, a = 255};
                                            }
                                        };
                                    };
                                };
                                {
                                    key = "Prediction";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = true;
                                        checkboxType = 1;
                                    };
                                };
                                {
                                    key = "Target Npc";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = true;
                                        checkboxType = 1;
                                    };
                                };
                                {
                                    key = "Target Knocked";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = true;
                                        checkboxType = 1;
                                    };
                                };
                                {
                                    key = "Target Teammates";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                    };
                                };
                            }
                        };
                        {
                            paneName = "Recoil";
                            autoAdjustForElements = false;
                            elements = {
                                {
                                    key = "Adjust Recoil";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 2;
                                        message = "Writes to memory";
                                        callback = function(element)
                                            if cheat.client.localplayer then
                                                cheat.recoil:weaponChange();
                                                cheat.recoil.previousOnKey = nil;
                                            end
                                        end;
                                        children = {
                                            {
                                                key = "On Key";
                                                value = {
                                                    type = drawTypes.checkbox;
                                                    state = false;
                                                    checkboxType = 1;
                                                    callback = function(element)
                                                        if cheat.client.localplayer then
                                                            cheat.recoil.previousOnKey = nil;
                                                            cheat.recoil:restoreModifiedWeapons(true);
                                                        end
                                                    end;
                                                    hotkey = {
                                                        key = "Recoil Key";
                                                        value = {
                                                            shortKeyName = "M4";
                                                            activeKey = keys.M4.offset;
                                                            keyState = false;
                                                            allowChange = true;
                                                            keyType = keyTypes.onHotkey;
                                                        };
                                                    };
                                                };
                                            };
                                            {
                                                key = "Recoil Reduce";
                                                value = {
                                                    
                                                    type = drawTypes.slider;
                                                    state = 100;
                                                    maxValue = 100;
                                                    minValue = 0;
                                                    doText = true;
                                                    textSpecifier = "%";
                                                    callback = function(element)
                                                        if cheat.client.localplayer then
                                                            cheat.recoil:weaponChange();
                                                        end
                                                    end;
                                                };
                                            };
                                        };
                                    };
                                };
                            };
                        };
                    };
                --[[},
                {
                    subtabName = "Recoil";
                },
            },]]
        },
        {
            tabName = "Visuals";
            bitmap = {
                url = "https://i.imgur.com/Dr4AtGk.png";
                width = 50;
                height = 50;
            };
            currentSubtab = 1,
            menuSubtabs = {
                {
                    subtabName = "Enemy";
                    rightPanes = {
                        {
                            paneName = "Distance";
                            elements = {
                                {
                                    key = "Max Player Distance";
                                    value = {
                                        type = drawTypes.slider;
                                        state = 400;
                                        maxValue = 800;
                                        minValue = 0;
                                        doText = true;
                                        textSpecifier = "m";
                                    };
                                };
                                {
                                    key = "Max NPC Distance";
                                    value = {
                                        type = drawTypes.slider;
                                        state = 150;
                                        maxValue = 500;
                                        minValue = 0;
                                        doText = true;
                                        textSpecifier = "m";
                                    };
                                };
                                {
                                    key = "Max Skeleton Distance";
                                    value = {
                                        type = drawTypes.slider;
                                        state = 80;
                                        maxValue = 500;
                                        minValue = 0;
                                        doText = true;
                                        textSpecifier = "m";
                                    };
                                };
                            };
                        };
                        {
                            paneName = "Player Flags";
                            autoAdjustForElements = true;
                            elements = {
                                {
                                    key = "Bot Flag";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = true;
                                        checkboxType = 1;
                                        message = "Some players can be bots spawned by admins";
                                        colorpicker = {
                                            key = "Bot Flag Color";
                                            value = {
                                                color = {r = 0, g = 255, b = 0, a = 255};
                                            }
                                        };
                                    };
                                };
                                {
                                    key = "Alt Looking Flag";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Alt Looking Flag Color";
                                            value = {
                                                color = {r = 0, g = 17, b = 255, a = 255};
                                            }
                                        };
                                    };
                                };
                                {
                                    key = "Boom Flag";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        message = "This can cause stutters/performance issues";
                                        colorpicker = {
                                            key = "Boom Flag Color";
                                            value = {
                                                color = {r = 0, g = 17, b = 255, a = 255};
                                            }
                                        };
                                    };
                                };
                                {
                                    key = "Teamid Flag";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Teamid Color";
                                            value = {
                                                color = {r = 255, g = 255, b = 255, a = 255};
                                            }
                                        };
                                        children = {
                                            {
                                                key = "Teamid Draw Type";
                                                value = {
                                                    type = drawTypes.combobox;
                                                    state = 1;
                                                    doOff = false;
                                                    options = {
                                                        "Colored Box";
                                                        "Colored Text";
                                                        "Text";
                                                    };
                                                };
                                            };
                                        };
                                    };
                                };
                            }
                        };
                        {
                            paneName = "Other";
                            autoAdjustForElements = true;
                            elements = {
                                {
                                    key = "OOF Arrows";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "OOF Color";
                                            value = {
                                                color = {r = 145, g = 35, b = 20, a = 255};
                                            }
                                        };
                                        children = {
                                            --[[{
                                                key = "OOF Arrow Spacing";
                                                value = {
                                                    type = drawTypes.slider;
                                                    state = 100;
                                                    maxValue = 800;
                                                    minValue = 0;
                                                    doText = true;
                                                    textSpecifier = "px";
                                                };
                                            };
                                            {
                                                key = "OOF Arrow Size";
                                                value = {
                                                    type = drawTypes.slider;
                                                    state = 0;
                                                    maxValue = 30;
                                                    minValue = 7;
                                                    doText = true;
                                                    textSpecifier = "px";
                                                };
                                            };]]
                                        };
                                    };
                                };
                            
                            }
                        };
                    };
                    leftPanes = {
                        {
                            paneName = "ESP";
                            elements = {
                                {
                                    key = "Player Visible Box";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        --[[colorpicker = {
                                            key = "Visible Box Color";
                                            value = {
                                                color = {r = 255, g = 255, b = 255, a = 255};
                                            }
                                        };]]
                                    };
                                };
                                {
                                    key = "Player Invisible Box";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = true;
                                        checkboxType = 1;
                                        --[[colorpicker = {
                                            key = "Invisible Box Color";
                                            value = {
                                                color = {r = 255, g = 255, b = 255, a = 255};
                                            }
                                        };]]
                                    };
                                };
                                {
                                    key = "Player Knocked Box";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = true;
                                        checkboxType = 1;
                                        --[[colorpicker = {
                                            key = "Invisible Box Color";
                                            value = {
                                                color = {r = 255, g = 255, b = 255, a = 255};
                                            }
                                        };]]
                                    };
                                };
                                {
                                    key = "Player Skeleton";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        message = "Performance Intensive";
                                        --[[colorpicker = {
                                            key = "Invisible Box Color";
                                            value = {
                                                color = {r = 255, g = 255, b = 255, a = 255};
                                            }
                                        };]]
                                    };
                                };
                                {
                                    key = "Player Name";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = true;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Player Name Color";
                                            value = {
                                                color = {r = 255, g = 255, b = 255, a = 255};
                                            }
                                        };
                                    };
                                };
                                {
                                    key = "Player Distance";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = true;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Player Distance Color";
                                            value = {
                                                color = {r = 255, g = 255, b = 255, a = 255};
                                            }
                                        };
                                    };
                                };
                                {
                                    key = "Player Weapon";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = true;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Player Weapon Color";
                                            value = {
                                                color = {r = 255, g = 255, b = 255, a = 255};
                                            }
                                        };
                                    };
                                };
                                {
                                    key = "Player Viewangle";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Player Viewangle Color";
                                            value = {
                                                color = {r = 255, g = 0, b = 224, a = 255};
                                            }
                                        };
                                        children = {
                                            {
                                                key = "Viewangle Line Distance";
                                                value = {
                                                    type = drawTypes.slider;
                                                    state = 1;
                                                    maxValue = 2.5;
                                                    minValue = 0.1;
                                                    doText = true;
                                                    decimalPoints = 1;
                                                    textSpecifier = "m";
                                                };
                                            };
                                        };
                                    };
                                };
                                {
                                    key = "Player Hotbar";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        children = {
                                            {
                                                key = "Hotbar Fov";
                                                value = {
                                                    type = drawTypes.slider;
                                                    state = 11;
                                                    maxValue = 180;
                                                    minValue = 0;
                                                    doText = true;
                                                    adaptive = true;
                                                    textSpecifier = "*";
                                                };
                                            };
                                            {
                                                key = "Max Players";
                                                value = {
                                                    type = drawTypes.slider;
                                                    state = 1;
                                                    maxValue = 10;
                                                    minValue = 1;
                                                    doText = true;
                                                    decimalPoints = 0;
                                                };
                                            };
                                        };
                                    };
                                };
                                {
                                    key = "Player Asleep";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Player Asleep Color";
                                            value = {
                                                color = {r = 145, g = 35, b = 20, a = 255};
                                            }
                                        };
                                    };
                                };
                                {
                                    key = "Player Dead";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Player Dead Color";
                                            value = {
                                                color = {r = 242, g = 35, b = 20, a = 255};
                                            }
                                        };
                                    };
                                };
                                {
                                    key = "Player Knocked";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = true;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Player Knocked Color";
                                            value = {
                                                color = {r = 237, g = 255, b = 12, a = 255};
                                            }
                                        };
                                    };
                                };
                                {
                                    key = "Player Visible Check";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = true;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Visible Color";
                                            value = {
                                                color = {r = 255, g = 0, b = 224, a = 255};
                                            }
                                        };
                                    };
                                };
                                {
                                    key = "Invisible Color";
                                    value = {
                                        type = drawTypes.colorpicker;
                                        color = {r = 0, g = 242, b = 137, a = 255};
                                    };
                                };
                            };
                        };
                        {
                            paneName = "NPC";
                            autoAdjustForElements = true;
                            elements = {
                                {
                                    key = "NPC Box";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = true;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "NPC Box Color";
                                            value = {
                                                color = {r = 255, g = 255, b = 255, a = 255};
                                            }
                                        };
                                    };
                                };
                                {
                                    key = "NPC Name";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = true;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "NPC Name Color";
                                            value = {
                                                color = {r = 255, g = 255, b = 255, a = 255};
                                            }
                                        };
                                    };
                                };
                                {
                                    key = "NPC Distance";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = true;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "NPC Distance Color";
                                            value = {
                                                color = {r = 255, g = 255, b = 255, a = 255};
                                            }
                                        };
                                    };
                                };
                                {
                                    key = "NPC Weapon";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = true;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "NPC Weapon Color";
                                            value = {
                                                color = {r = 255, g = 255, b = 255, a = 255};
                                            }
                                        };
                                    };
                                };
                                {
                                    key = "NPC Skeleton";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        message = "Performance Decrease";
                                        colorpicker = {
                                            key = "NPC Skeleton Color";
                                            value = {
                                                color = {r = 255, g = 255, b = 255, a = 255};
                                            }
                                        };
                                    };
                                };
                            };
                        };
                    };
                };
                {
                    subtabName = "Team";
                    rightPanes = {
                        {
                            paneName = "Distance";
                            elements = {
                                {
                                    key = "Max Teammate Distance";
                                    value = {
                                        type = drawTypes.slider;
                                        state = 400;
                                        maxValue = 500;
                                        minValue = 0;
                                        doText = true;
                                        textSpecifier = "m";
                                    };
                                };
                                {
                                    key = "Disable Distance";
                                    value = {
                                        type = drawTypes.slider;
                                        state = 0;
                                        maxValue = 150;
                                        minValue = 0;
                                        doText = true;
                                        textSpecifier = "m";
                                    };
                                };
                                {
                                    key = "Max Skeleton Distance";
                                    value = {
                                        type = drawTypes.slider;
                                        state = 80;
                                        maxValue = 500;
                                        minValue = 0;
                                        doText = true;
                                        textSpecifier = "m";
                                    };
                                };
                            };
                        };
                    };
                    leftPanes = {
                        {
                            paneName = "ESP";
                            elements = {
                                {
                                    key = "Teammate Box";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Visible Box Color";
                                            value = {
                                                color = {r = 255, g = 255, b = 255, a = 255};
                                            }
                                        };
                                    };
                                };
                                {
                                    key = "Teammate Skeleton";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        message = "Performance Decrease";
                                        --[[colorpicker = {
                                            key = "Invisible Box Color";
                                            value = {
                                                color = {r = 255, g = 255, b = 255, a = 255};
                                            }
                                        };]]
                                    };
                                };
                                {
                                    key = "Teammate Name";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = true;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Teammate Name Color";
                                            value = {
                                                color = {r = 255, g = 255, b = 255, a = 255};
                                            }
                                        };
                                    };
                                };
                                {
                                    key = "Teammate Distance";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = true;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Teammate Distance Color";
                                            value = {
                                                color = {r = 255, g = 255, b = 255, a = 255};
                                            }
                                        };
                                    };
                                };
                                {
                                    key = "Teammate Weapon";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = true;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Teammate Weapon Color";
                                            value = {
                                                color = {r = 255, g = 255, b = 255, a = 255};
                                            }
                                        };
                                    };
                                };
                                {
                                    key = "Teammate Asleep";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Teammate Asleep Color";
                                            value = {
                                                color = {r = 255, g = 255, b = 255, a = 255};
                                            }
                                        };
                                    };
                                };
                                {
                                    key = "Teammate Dead";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Teammate Dead Color";
                                            value = {
                                                color = {r = 242, g = 35, b = 20, a = 255};
                                            }
                                        };
                                    };
                                };
                                {
                                    key = "Teammate Knocked";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = true;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Teammate Knocked Color";
                                            value = {
                                                color = {r = 237, g = 255, b = 12, a = 255};
                                            }
                                        };
                                    };
                                };
                                {
                                    key = "Teammate Color";
                                    value = {
                                        type = drawTypes.colorpicker;
                                        color = {r = 12, g = 255, b = 29, a = 255};
                                    };
                                };
                            };
                        };
                    };
                };
                {
                    subtabName = "Loot";
                    rightPanes = {
                        {
                            paneName = "Distance";
                            elements = {
                                {
                                    key = "Ore Distance";
                                    value = {
                                        type = drawTypes.slider;
                                        state = 400;
                                        maxValue = 500;
                                        minValue = 0;
                                        doText = true;
                                        textSpecifier = "m";
                                    };
                                };
                                {
                                    key = "Crate Distance";
                                    value = {
                                        type = drawTypes.slider;
                                        state = 400;
                                        maxValue = 500;
                                        minValue = 0;
                                        doText = true;
                                        textSpecifier = "m";
                                    };
                                };
                                {
                                    key = "Barrel Distance";
                                    value = {
                                        type = drawTypes.slider;
                                        state = 350;
                                        maxValue = 500;
                                        minValue = 0;
                                        doText = true;
                                        textSpecifier = "m";
                                    };
                                };
                                {
                                    key = "Hackable Crate Distance";
                                    value = {
                                        type = drawTypes.slider;
                                        state = 2000;
                                        maxValue = 5000;
                                        minValue = 0;
                                        doText = true;
                                        textSpecifier = "m";
                                    };
                                };
                                {
                                    key = "APC Crate Distance";
                                    value = {
                                        type = drawTypes.slider;
                                        state = 400;
                                        maxValue = 500;
                                        minValue = 0;
                                        doText = true;
                                        textSpecifier = "m";
                                    };
                                };
                                {
                                    key = "Supply Drop Distance";
                                    value = {
                                        type = drawTypes.slider;
                                        state = 2000;
                                        maxValue = 5000;
                                        minValue = 0;
                                        doText = true;
                                        textSpecifier = "m";
                                    };
                                };
                            };
                        };
                        {
                            paneName = "Special";
                            --height = 100;
                            autoAdjustForElements = true;
                            elements = {
                                {
                                    key = "Diesel Fuel";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Diesel Fuel Color";
                                            value = {
                                                color = {r = 255, g = 103, b = 0, a = 255};
                                            }
                                        };
                                    };
                                };
                                {
                                    key = "Supply Drop";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Supply Drop Color";
                                            value = {
                                                color = {r = 218, g = 41, b = 96, a = 255};
                                            }
                                        };
                                    };
                                };
                            };
                        };
                    };
                    leftPanes = {
                        {
                            paneName = "Ore";
                            autoAdjustForElements = true;
                            elements = {
                                {
                                    key = "Stone Ore";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Stone Ore Color";
                                            value = {
                                                color = {r = 237, g = 255, b = 12, a = 255};
                                            }
                                        };
                                    };
                                };
                                {
                                    key = "Metal Ore";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Metal Ore Color";
                                            value = {
                                                color = {r = 242, g = 168, b = 34, a = 255};
                                            }
                                        };
                                    };
                                };
                                {
                                    key = "Sulfur Ore";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Sulfur Ore Color";
                                            value = {
                                                color = {r = 34, g = 242, b = 138, a = 255};
                                            }
                                        };
                                    };
                                };
                                {
                                    key = "Melee Equipped Only";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        message = "Only draws if holding a pickaxe/jackhammer";
                                    };
                                };
                            };
                        };
                        {
                            paneName = "Crates";
                            autoAdjustForElements = true;
                            elements = {
                                {
                                    key = "Elite Crate";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Elite Crate Color";
                                            value = {
                                                color = {r = 92, g = 46, b = 194, a = 255};
                                            }
                                        };
                                    };
                                };
                                {
                                    key = "Military Crate";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Military Crate Color";
                                            value = {
                                                color = {r = 92, g = 46, b = 194, a = 255};
                                            }
                                        };
                                    };
                                };
                                {
                                    key = "Normal Crate";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Normal Crate Color";
                                            value = {
                                                color = {r = 92, g = 46, b = 194, a = 255};
                                            }
                                        };
                                    };
                                };
                                {
                                    key = "Hackable Crate";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Hackable Crate Color";
                                            value = {
                                                color = {r = 92, g = 46, b = 194, a = 255};
                                            }
                                        };
                                    };
                                };
                                {
                                    key = "APC Crate";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "APC Crate Color";
                                            value = {
                                                color = {r = 92, g = 46, b = 194, a = 255};
                                            }
                                        };
                                    };
                                };
                                {
                                    key = "Food Crate";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Food Crate Color";
                                            value = {
                                                color = {r = 92, g = 46, b = 194, a = 255};
                                            }
                                        };
                                    };
                                };
                            };
                        };
                        {
                            paneName = "Other";
                            elements = {
                                {
                                    key = "Barrels";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Barrels Color";
                                            value = {
                                                color = {r = 218, g = 31, b = 31, a = 255};
                                            }
                                        };
                                    };
                                };
                                {
                                    key = "Oil Barrel";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Oil Barrel Color";
                                            value = {
                                                color = {r = 218, g = 31, b = 31, a = 255};
                                            }
                                        };
                                    };
                                };
                                {
                                    key = "Large Storage Box";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Large Storage Box Color";
                                            value = {
                                                color = {r = 218, g = 31, b = 31, a = 255};
                                            }
                                        };
                                    };
                                };
                                {
                                    key = "Workbench Tier 3";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Workbench Tier 3 Color";
                                            value = {
                                                color = {r = 218, g = 31, b = 31, a = 255};
                                            }
                                        };
                                    };
                                };
                                {
                                    key = "Toolbox";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Toolbox Color";
                                            value = {
                                                color = {r = 218, g = 31, b = 31, a = 255};
                                            }
                                        };
                                    };
                                };
                            };
                        };
                    };
                };
                {
                    subtabName = "Vehicle";
                    rightPanes = {
                        {
                            paneName = "Distance";
                            elements = {
                                {
                                    key = "Boat Distance";
                                    value = {
                                        type = drawTypes.slider;
                                        state = 400;
                                        maxValue = 5000;
                                        minValue = 0;
                                        doText = true;
                                        textSpecifier = "m";
                                    };
                                };
                                {
                                    key = "Heli Distance";
                                    value = {
                                        type = drawTypes.slider;
                                        state = 2500;
                                        maxValue = 5000;
                                        minValue = 0;
                                        doText = true;
                                        textSpecifier = "m";
                                    };
                                };
                                {
                                    key = "Car Distance";
                                    value = {
                                        type = drawTypes.slider;
                                        state = 400;
                                        maxValue = 500;
                                        minValue = 0;
                                        doText = true;
                                        textSpecifier = "m";
                                    };
                                };
                                {
                                    key = "Bike Distance";
                                    value = {
                                        type = drawTypes.slider;
                                        state = 400;
                                        maxValue = 500;
                                        minValue = 0;
                                        doText = true;
                                        textSpecifier = "m";
                                    };
                                };
                                {
                                    key = "Heli Linger Time";
                                    value = {
                                        type = drawTypes.slider;
                                        state = 40;
                                        maxValue = 200;
                                        minValue = 1;
                                        doText = true;
                                        textSpecifier = "s";
                                    };
                                };
                            }
                        };
                        {
                            paneName = "Land";
                            autoAdjustForElements = true;
                            elements = {
                                {
                                    key = "Pedal Bike";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Pedal Bike Color";
                                            value = {
                                                color = {r = 37, g = 32, b = 230, a = 255};
                                            }
                                        };
                                    };
                                };
                                {
                                    key = "Motor Bike";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Motor Bike Color";
                                            value = {
                                                color = {r = 37, g = 32, b = 230, a = 255};
                                            }
                                        };
                                    };
                                };
                                {
                                    key = "Car";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Cars Color";
                                            value = {
                                                color = {r = 34, g = 242, b = 118, a = 255};
                                            }
                                        };
                                        children = {
                                            {
                                                key = "Active Cars Only";
                                                value = {
                                                    type = drawTypes.checkbox;
                                                    state = true;
                                                    checkboxType = 1;
                                                };
                                            };
                                        }
                                    };
                                };
                                {
                                    key = "Snowmobile";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Snowmobile Color";
                                            value = {
                                                color = {r = 34, g = 242, b = 118, a = 255};
                                            }
                                        };
                                    };
                                };
                            };
                        };
                    };
                    leftPanes = {
                        {
                            paneName = "Air";
                            --autoAdjustForElements = true;
                            elements = {
                                {
                                    key = "Minicopter";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = true;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Minicopters Color";
                                            value = {
                                                color = {r = 255, g = 24, b = 238, a = 255};
                                            }
                                        };
                                    };
                                };
                                {
                                    key = "Scrap Heli";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = true;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Scrap Heli Color";
                                            value = {
                                                color = {r = 255, g = 24, b = 238, a = 255};
                                            }
                                        };
                                    };
                                };
                                {
                                    key = "Combat Heli";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = true;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Combat Heli Color";
                                            value = {
                                                color = {r = 255, g = 24, b = 238, a = 255};
                                            }
                                        };
                                    };
                                };
                            }
                        };
                        {
                            paneName = "Water";
                            --autoAdjustForElements = true;
                            elements = {
                                {
                                    key = "RHIB";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "RHIB Color";
                                            value = {
                                                color = {r = 37, g = 32, b = 230, a = 255};
                                            }
                                        };
                                    };
                                };
                                {
                                    key = "Rowboat";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Rowboat Color";
                                            value = {
                                                color = {r = 37, g = 32, b = 230, a = 255};
                                            }
                                        };
                                    };
                                };
                                {
                                    key = "Tugboat";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = true;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Tugboat Color";
                                            value = {
                                                color = {r = 37, g = 32, b = 230, a = 255};
                                            }
                                        };
                                    };
                                };
                            }
                        };
                    };
                };
                {
                    subtabName = "Animal";
                    rightPanes = {
                        {
                            paneName = "Distance";
                            elements = {
                                {
                                    key = "Animal Distance";
                                    value = {
                                        type = drawTypes.slider;
                                        state = 400;
                                        maxValue = 500;
                                        minValue = 0;
                                        doText = true;
                                        textSpecifier = "m";
                                    };
                                };
                                {
                                    key = "Horse Distance";
                                    value = {
                                        type = drawTypes.slider;
                                        state = 400;
                                        maxValue = 500;
                                        minValue = 0;
                                        doText = true;
                                        textSpecifier = "m";
                                    };
                                };
                            }
                        };
                    };
                    leftPanes = {
                        {
                            paneName = "Animals";
                            --autoAdjustForElements = true;
                            elements = {
                                {
                                    key = "Horse";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Horse Color";
                                            value = {
                                                color = {r = 48, g = 138, b = 145, a = 255};
                                            }
                                        };
                                    };
                                };
                                {
                                    key = "Bear";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Bear Color";
                                            value = {
                                                color = {r = 48, g = 138, b = 145, a = 255};
                                            }
                                        };
                                    };
                                };
                                {
                                    key = "Deer";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Deer Color";
                                            value = {
                                                color = {r = 48, g = 138, b = 145, a = 255};
                                            }
                                        };
                                    };
                                };
                                {
                                    key = "Boar";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Boar Color";
                                            value = {
                                                color = {r = 48, g = 138, b = 145, a = 255};
                                            }
                                        };
                                    };
                                };
                                {
                                    key = "Wolf";   
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Wolf Color";
                                            value = {
                                                color = {r = 48, g = 138, b = 145, a = 255};
                                            }
                                        };
                                    };
                                };
                            }
                        };
                    };
                };
                {
                    subtabName = "Plants";
                    rightPanes = {
                        {
                            paneName = "Distance";
                            elements = {
                                {
                                    key = "Berry Distance";
                                    value = {
                                        type = drawTypes.slider;
                                        state = 400;
                                        maxValue = 500;
                                        minValue = 0;
                                        doText = true;
                                        textSpecifier = "m";
                                    };
                                };
                                {
                                    key = "Hemp Distance";
                                    value = {
                                        type = drawTypes.slider;
                                        state = 400;
                                        maxValue = 500;
                                        minValue = 0;
                                        doText = true;
                                        textSpecifier = "m";
                                    };
                                };
                                {
                                    key = "Food Distance";
                                    value = {
                                        type = drawTypes.slider;
                                        state = 400;
                                        maxValue = 500;
                                        minValue = 0;
                                        doText = true;
                                        textSpecifier = "m";
                                    };
                                };
                            }
                        };
                    };
                    leftPanes = {
                        {
                            paneName = "Food";
                            autoAdjustForElements = true;
                            elements = {
                                {
                                    key = "Mushroom";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Mushroom Color";
                                            value = {
                                                color = {r = 110, g = 12, b = 255, a = 255};
                                            }
                                        };
                                    };
                                };
                                {
                                    key = "Corn";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Corn Color";
                                            value = {
                                                color = {r = 110, g = 12, b = 255, a = 255};
                                            }
                                        };
                                    };
                                };
                                {
                                    key = "Potato";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Potato Color";
                                            value = {
                                                color = {r = 110, g = 12, b = 255, a = 255};
                                            }
                                        };
                                    };
                                };
                                {
                                    key = "Pumpkin";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Pumpkin Color";
                                            value = {
                                                color = {r = 110, g = 12, b = 255, a = 255};
                                            }
                                        };
                                    };
                                };
                            }
                        };
                        {
                            paneName = "Berry";
                            autoAdjustForElements = true;
                            elements = {
                                {
                                    key = "Black Berry";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Black Berry Color";
                                            value = {
                                                color = {r = 12, g = 255, b = 122, a = 255};
                                            }
                                        };
                                    };
                                };
                                {
                                    key = "Blue Berry";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Blue Berry Color";
                                            value = {
                                                color = {r = 12, g = 255, b = 122, a = 255};
                                            }
                                        };
                                    };
                                };
                                {
                                    key = "Green Berry";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Green Berry Color";
                                            value = {
                                                color = {r = 12, g = 255, b = 122, a = 255};
                                            }
                                        };
                                    };
                                };
                                {
                                    key = "Yellow Berry";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Yellow Berry Color";
                                            value = {
                                                color = {r = 12, g = 255, b = 122, a = 255};
                                            }
                                        };
                                    };
                                };
                                {
                                    key = "White Berry";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "White Berry Color";
                                            value = {
                                                color = {r = 12, g = 255, b = 122, a = 255};
                                            }
                                        };
                                    };
                                };
                                {
                                    key = "Red Berry";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Red Berry Color";
                                            value = {
                                                color = {r = 12, g = 255, b = 122, a = 255};
                                            }
                                        };
                                    };
                                };
                            }
                        };
                        {
                            paneName = "Other";
                            elements = {
                                {
                                    key = "Hemp";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Hemp Color";
                                            value = {
                                                color = {r = 18, g = 255, b = 0, a = 255};
                                            }
                                        };
                                    };
                                };
                            }
                        };
                    };
                };
                {
                    subtabName = "Traps";
                    rightPanes = {
                        {
                            paneName = "Distance";
                            elements = {
                                {
                                    key = "Trap Distance";
                                    value = {
                                        type = drawTypes.slider;
                                        state = 20;
                                        maxValue = 500;
                                        minValue = 0;
                                        doText = true;
                                        textSpecifier = "m";
                                    };
                                };
                                {
                                    key = "Turret Distance";
                                    value = {
                                        type = drawTypes.slider;
                                        state = 75;
                                        maxValue = 500;
                                        minValue = 0;
                                        doText = true;
                                        textSpecifier = "m";
                                    };
                                };
                                {
                                    key = "Samsite Distance";
                                    value = {
                                        type = drawTypes.slider;
                                        state = 400;
                                        maxValue = 500;
                                        minValue = 0;
                                        doText = true;
                                        textSpecifier = "m";
                                    };
                                };
                            }
                        };
                        {
                            paneName = "World";
                            autoAdjustForElements = true;
                            elements = {
                                {
                                    key = "Bear Trap";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = true;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Bear Trap Color";
                                            value = {
                                                color = {r = 255, g = 0, b = 0, a = 255};
                                            }
                                        };
                                    };
                                };
                                {
                                    key = "Landmine";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = true;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Landmine Color";
                                            value = {
                                                color = {r = 255, g = 0, b = 0, a = 255};
                                            }
                                        };
                                    };
                                };
                            }
                        };
                    };
                    leftPanes = {
                        {
                            paneName = "Stationary";
                            --autoAdjustForElements = true;
                            elements = {
                                {
                                    key = "Shotgun Trap";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = true;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Shotgun Trap Color";
                                            value = {
                                                color = {r = 255, g = 0, b = 0, a = 255};
                                            }
                                        };
                                    };
                                };
                                {
                                    key = "Flame Turret";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Flame Turret Color";
                                            value = {
                                                color = {r = 255, g = 0, b = 0, a = 255};
                                            }
                                        };
                                    };
                                };
                            }
                        };
                        {
                            paneName = "Hardpoints";
                            elements = {
                                {
                                    key = "Turret";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = true;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Turret Color";
                                            value = {
                                                color = {r = 255, g = 0, b = 0, a = 255};
                                            }
                                        };
                                        children = {
                                            {
                                                key = "Turret Options";
                                                value = {
                                                    type = drawTypes.multiselect;
                                                    doText = true;
                                                    options = {
                                                        {
                                                            key = 'Online Only';
                                                            value = true;  
                                                        };
                                                        {
                                                            key = 'Draw Active State';
                                                            value = false;  
                                                        };
                                                    };
                                                };
                                            };
                                        };
                                    };
                                };
                                {
                                    key = "Samsite";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Samsite Color";
                                            value = {
                                                color = {r = 255, g = 0, b = 0, a = 255};
                                            }
                                        };
                                        children = {
                                            {
                                                key = "Samsite Options";
                                                value = {
                                                    type = drawTypes.multiselect;
                                                    doText = true;
                                                    options = {
                                                        {
                                                            key = 'Online Only';
                                                            value = true;  
                                                        };
                                                        {
                                                            key = 'Draw Active State';
                                                            value = false;  
                                                        };
                                                    };
                                                };
                                            };
                                        };
                                    };
                                };
                            }
                        };
                    };
                };
                {
                    subtabName = "Other";
                    rightPanes = {
                        {
                            paneName = "Distance";
                            elements = {
                                {
                                    key = "APC Distance";
                                    value = {
                                        type = drawTypes.slider;
                                        state = 5000;
                                        maxValue = 5000;
                                        minValue = 0;
                                        doText = true;
                                        textSpecifier = "m";
                                    };
                                };
                                {
                                    key = "Dropped Weapon Distance";
                                    value = {
                                        type = drawTypes.slider;
                                        state = 400;
                                        maxValue = 500;
                                        minValue = 0;
                                        doText = true;
                                        textSpecifier = "m";
                                    };
                                };
                                {
                                    key = "TC Distance";
                                    value = {
                                        type = drawTypes.slider;
                                        state = 400;
                                        maxValue = 500;
                                        minValue = 0;
                                        doText = true;
                                        textSpecifier = "m";
                                    };
                                };
                                {
                                    key = "Corpse Distance";
                                    value = {
                                        type = drawTypes.slider;
                                        state = 55;
                                        maxValue = 500;
                                        minValue = 0;
                                        doText = true;
                                        textSpecifier = "m";
                                    };
                                };
                            }
                        };
                        {
                            paneName = "Settings";
                            autoAdjustForElements = true;
                            elements = {
                                {
                                    key = "Outlines";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = true;
                                        checkboxType = 1;
                                    };
                                };
                                --[[{
                                    key = "Anti Clutter";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        message = "Avoids drawing text near players on the screen";
                                        children = {
                                            {
                                                key = "Anti Clutter Threshold";
                                                value = {
                                                    type = drawTypes.slider;
                                                    state = 1;
                                                    maxValue = 100;
                                                    minValue = 1;
                                                    doText = true;
                                                    textSpecifier = "%";
                                                };
                                            };
                                        };
                                    };
                                };]]
                                {
                                    key = "Box Outlines";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = true;
                                        checkboxType = 1;
                                    };
                                };
                                {
                                    key = "Dynamic Boxes";
                                    value = {
                                        message = "Performance Intensive & Buggy";
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                    };
                                };
                                --[[{
                                    key = "Skeleton Flick Fix";
                                    value = {
                                        message = "Writes to memory";
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 2;
                                    };
                                };]]
                                --[[{
                                    key = "Debug Mode";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        callback = function(element) 
                                            cheat.entityList.other = {};
                                            cheat.entityList.ignoredPointers = {};
                                            cheat.lastEntityListCheck = 0;
                                        end;
                                        message = "Draws ESP on everything (hotkey is to copy nearest entity data)";
                                        colorpicker = {
                                            key = "Debug Mode Color";
                                            value = {
                                                color = {r = 196, g = 237, b = 0, a = 255};
                                            }
                                        };
                                        hotkey = {
                                            key = "Entity Copy Hotkey";
                                            value = {
                                                shortKeyName = "=";
                                                activeKey = keys["="].offset;
                                                keyState = false;
                                                allowChange = false;
                                                keyType = keyTypes.onHotkey;
                                                callback = function(element) 
                                                    if element.value.keyState and draw.cachedUiVars.visuals.other.debugMode.value.state then
                                                        local nearestEntity = cheat.entityList:findNearestEntity();
                                                        if nearestEntity and nearestEntity.prefabData then
                                                            local copyString = ""--nearestEntity.prefabData.classname .. "\n";
                                                            if nearestEntity.prefabData.prefabName then
                                                                copyString = copyString .. nearestEntity.prefabData.prefabName .. "\n";
                                                            end
                                                            if nearestEntity.prefabData.classname then
                                                                copyString = copyString .. nearestEntity.prefabData.classname .. "\n";
                                                            end
                                                            if nearestEntity.prefabData.id then
                                                                copyString = copyString .. tostring(nearestEntity.prefabData.id) .. "\n";
                                                            end
                                                            if string.len(copyString) > 1 then
                                                                if draw.cachedUiVars.visuals.other.debugCopyType.value.state == 1 then
                                                                    Input.SetClipboard(copyString);
                                                                else
                                                                    Input.SetClipboard(tostring(nearestEntity.prefabData.id) .. ";");
                                                                end
                                                                
                                                                notifications:add('Copied entity to clipboard')
                                                            end
                                                        end
                                                    end
                                                end;
                                            };
                                        };
                                        children = {
                                            {
                                                key = "Debug Mode Distance";
                                                value = {
                                                    type = drawTypes.slider;
                                                    state = 15;
                                                    maxValue = 500;
                                                    minValue = 1;
                                                    doText = true;
                                                    textSpecifier = "m";
                                                };
                                            };
                                            {
                                                key = "Debug Copy Type";
                                                value = {
                                                    type = drawTypes.combobox;
                                                    state = 1;
                                                    doOff = false;
                                                    options = {
                                                        "All";
                                                        "ID Only";
                                                    };
                                                };
                                            };
                                        };
                                    };
                                };]]
                            }
                        };
                    };
                    leftPanes = {
                        {
                            paneName = "Other";
                            autoAdjustForElements = true;
                            elements = {
                                {
                                    key = "Corpse";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = true;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Corpse Color";
                                            value = {
                                                color = {r = 255, g = 161, b = 48, a = 255};
                                            }
                                        };
                                    };
                                };
                                {
                                    key = "Recycler";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Recycler Color";
                                            value = {
                                                color = {r = 40, g = 242, b = 0, a = 255};
                                            }
                                        };
                                    };
                                };
                                {
                                    key = "Tool Cupboard";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Tool Cupboard Color";
                                            value = {
                                                color = {r = 225, g = 242, b = 0, a = 255};
                                            }
                                        };
                                    };
                                };
                                {
                                    key = "Grenades";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = true;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Grenades Color";
                                            value = {
                                                color = {r = 80, g = 242, b = 215, a = 255};
                                            }
                                        };
                                    };
                                };
                                {
                                    key = "Drones";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = true;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Drones Color";
                                            value = {
                                                color = {r = 225, g = 242, b = 0, a = 255};
                                            }
                                        };
                                    };
                                };
                                {
                                    key = "Dropped Weapons";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Dropped Weapons Color";
                                            value = {
                                                color = {r = 230, g = 65, b = 132, a = 255};
                                            }
                                        };
                                        children = {
                                            {
                                                key = "Dropped Weapons Types";
                                                value = {
                                                    type = drawTypes.multiselect;
                                                    doText = true;
                                                    options = {
                                                        {
                                                            key = 'Tier 1 Weapons';
                                                            value = false;
                                                        };
                                                        {
                                                            key = 'Tier 2 Weapons';
                                                            value = true;
                                                        };
                                                        {
                                                            key = 'Tier 3 Weapons';
                                                            value = true;
                                                        };
                                                        {
                                                            key = 'Primitive Weapons';
                                                            value = false;
                                                        };
                                                        {
                                                            key = 'Boom';
                                                            value = false;
                                                        };
                                                        {
                                                            key = 'Misc';
                                                            value = false;
                                                        };
                                                    };
                                                };
                                            };
                                        };
                                    };
                                };
                                {
                                    key = "Online Cctv Cameras";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = true;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Online Cctv Cameras Color";
                                            value = {
                                                color = {r = 0, g = 242, b = 137, a = 255};
                                            }
                                        };
                                    };
                                };
                                {
                                    key = "Bradley";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = true;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Bradley Color";
                                            value = {
                                                color = {r = 39, g = 194, b = 18, a = 255};
                                            }
                                        };
                                    };
                                };
                                {
                                    key = "Attack Heli";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = true;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Attack Heli Color";
                                            value = {
                                                color = {r = 39, g = 194, b = 18, a = 255};
                                            }
                                        };
                                    };
                                };
                                {
                                    key = "Debug Mode";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Debug Mode Color";
                                            value = {
                                                color = {r = 196, g = 237, b = 0, a = 255};
                                            }
                                        };
                                        callback = function() 
                                            cheat.entitylist.others = {};
                                        end;
                                    };
                                };
                                
                                {
                                    key = "World Esp Distance";
                                    value = {
                                        type = drawTypes.combobox;
                                        state = 1;
                                        doOff = true;
                                        options = {
                                            "Inline";
                                            "Underneath";
                                        };
                                    };
                                };
                                {
                                    key = "Fade Out Esp";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                    };
                                };
                            }
                        };
                        {
                            paneName = "World";
                            autoAdjustForElements = true;
                            elements = {
                                {
                                    key = "Raid ESP";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Raid ESP Color";
                                            value = {
                                                color = {r = 255, g = 161, b = 48, a = 255};
                                            }
                                        };
                                        children = {
                                            {
                                                key = "Draw Time Since Last Boom";
                                                value = {
                                                    type = drawTypes.checkbox;
                                                    state = true;
                                                    checkboxType = 1;
                                                };
                                            };
                                            {
                                                key = "Raid Linger Time";
                                                value = {
                                                    type = drawTypes.slider;
                                                    state = 180;
                                                    maxValue = 500;
                                                    minValue = 1;
                                                    doText = true;
                                                    textSpecifier = "s";
                                                };
                                            };
                                        };
                                    };
                                };
                            };
                        };
                    };
                }
            };
        },
        {
            tabName = "Misc",
            bitmap = {
                url = "https://i.imgur.com/P22jUAu.png";
                width = 50;
                height = 50;
            };
            --[[currentSubtab = 1;
            menuSubtabs = {
                {
                    subtabName = "View";]]
                    rightPanes = {
                        {
                            paneName = "Radar";
                            autoAdjustForElements = true;
                            elements = {
                                {
                                    key = "Radar";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Radar Player Color";
                                            value = {
                                                color = {r = 255, g = 0, b = 0, a = 255};
                                            }
                                        };
                                        children = {
                                            {
                                                key = "Radar Draw Teammates";
                                                value = {
                                                    type = drawTypes.checkbox;
                                                    state = true;
                                                    checkboxType = 1;
                                                    colorpicker = {
                                                        key = "Radar Teammate Player Color";
                                                        value = {
                                                            color = {r = 127, g = 255, b = 0, a = 255};
                                                        }
                                                    };
                                                };
                                            };
                                            {
                                                key = "Radar Rotation";
                                                value = {
                                                    type = drawTypes.checkbox;
                                                    state = true;
                                                    checkboxType = 1;
                                                };
                                            };
                                            {
                                                key = "Radar Size";
                                                value = {
                                                    type = drawTypes.slider;
                                                    state = 200;
                                                    maxValue = 600;
                                                    minValue = 60;
                                                    doText = true;
                                                    textSpecifier = "px";
                                                };
                                            };
                                            {
                                                key = "Radar Scale";
                                                value = {
                                                    type = drawTypes.slider;
                                                    state = 3;
                                                    maxValue = 6;
                                                    minValue = 0;
                                                    decimalPoints = 1;
                                                    doText = true;
                                                    textSpecifier = "*";
                                                };
                                            };
                                            {
                                                key = "Player Size";
                                                value = {
                                                    type = drawTypes.slider;
                                                    state = 2;
                                                    maxValue = 7;
                                                    minValue = 1;
                                                    doText = true;
                                                    textSpecifier = "px";
                                                };
                                            };
                                            {
                                                key = "Radar Visible Check";
                                                value = {
                                                    type = drawTypes.checkbox;
                                                    state = false;
                                                    checkboxType = 1;
                                                };
                                            };
                                            {
                                                key = "Player View Angles";
                                                value = {
                                                    type = drawTypes.checkbox;
                                                    state = false;
                                                    checkboxType = 1;
                                                };
                                            };
                                            --[[{
                                                key = "Radar View Angles";
                                                value = {
                                                    type = drawTypes.combobox;
                                                    state = 1;
                                                    doOff = true;
                                                    options = {
                                                        "Arrow";
                                                        "Line";
                                                    };
                                                };
                                            };]]
                                        };
                                    };
                                };
                            };
                        };
                    };
                    leftPanes = {
                        {
                            paneName = "View";
                            elements = {
                                --[[{
                                    key = "Always Day";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        message = "Broken until timefall fixy";
                                        hotkey = {
                                            key = "Always Day Hotkey";
                                            value = {
                                                shortKeyName = ";";
                                                activeKey = keys[";"].offset;
                                                keyState = false;
                                                allowChange = true;
                                                keyType = keyTypes.onHotkey;
                                            };
                                        };
                                    };
                                };]]
                                {
                                    key = "Fullbright";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 2;
                                        message = "Writes to memory";
                                        hotkey = {
                                            key = "Fullbright Hotkey";
                                            value = {
                                                shortKeyName = ";";
                                                activeKey = keys[";"].offset;
                                                keyState = false;
                                                allowChange = true;
                                                keyType = keyTypes.toggle;
                                            };
                                        };
                                    };
                                };
                                {
                                    key = "Admin Flags";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 2;
                                        message = "Writes to memory";
                                        hotkey = {
                                            key = "Admin Flags Hotkey";
                                            value = {
                                                shortKeyName = "N";
                                                activeKey = keys["N"].offset;
                                                keyState = false;
                                                allowChange = true;
                                                keyType = keyTypes.onHotkey;
                                            };
                                        };
                                    };
                                };
                                {
                                    key = "Web Radar";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        children = {
                                            {
                                                key = "Shared Radar";
                                                value = {
                                                    type = drawTypes.checkbox;
                                                    state = false;
                                                    checkboxType = 1;
                                                    message = "Based off team owners steamid";
                                                };
                                            };
                                            {
                                                key = "Radar Data";
                                                value = {
                                                    type = drawTypes.multiselect;
                                                    doText = true;
                                                    options = {
                                                        {
                                                            key = 'Minicopters';
                                                            value = false;
                                                        };
                                                        {
                                                            key = 'Scrap Helis';
                                                            value = false;
                                                        };
                                                        {
                                                            key = 'Ore';
                                                            value = false;
                                                        };
                                                        {
                                                            key = 'Raids';
                                                            value = true;
                                                        };
                                                    };
                                                };
                                            };
                                            {
                                                key = "Update Rate";
                                                value = {
                                                    type = drawTypes.slider;
                                                    state = 69;
                                                    maxValue = 1000;
                                                    minValue = 40;
                                                    doText = true;
                                                    textSpecifier = "ms";
                                                };
                                            };
                                            {
                                                key = "New Link";
                                                value = {
                                                    type = drawTypes.button;
                                                    callback = function() 
                                                        if draw.cachedUiVars.misc.sharedRadar.value.state and cheat.webRadar.teamCode then
                                                            notifications:add('Shared Radar Is Enabled') 
                                                        else
                                                            storageSystem:updateRadarId(std:generateRandomString(15)); 
                                                            notifications:add('Generated new link') 
                                                        end
                                                    end;
                                                };
                                            };
                                            {
                                                key = "Copy Link";
                                                value = {
                                                    type = drawTypes.button;
                                                    callback = function() 
                                                        if draw.cachedUiVars.misc.sharedRadar.value.state and cheat.webRadar.teamCode then
                                                            input.set_clipboard("https://cheati.ng/radar/rust/?id=" .. cheat.webRadar.teamCode); 
                                                            notifications:add('Copied to clipboard') 
                                                        else
                                                            input.set_clipboard("https://cheati.ng/radar/rust/?id=" .. storageSystem.radarId or cheat.webRadar.radarId); 
                                                            notifications:add('Copied to clipboard') 
                                                        end
                                                    end;
                                                };
                                            };
                                        };
                                    };
                                };
                                --[[{
                                    key = "FOV Changer";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        callback = function(element)
                                            if element.value.state then
                                                cheat.misc.fovChanger:setFov(draw.cachedUiVars.misc.fOVChangeValue.value.state);
                                            else
                                                cheat.misc.fovChanger:resetFov();
                                            end
                                        end;
                                        children = {
                                            {
                                                key = "FOV Change Value";
                                                value = {
                                                    type = drawTypes.slider;
                                                    state = 70;
                                                    maxValue = 120;
                                                    minValue = 10;
                                                    specifier = "*";
                                                    doText = false;
                                                };
                                            };
                                        };
                                    };
                                };]]
                            };
                        };
                        {
                            paneName = "Debugcamera";
                            autoAdjustForElements = true;
                            elements = {
                                --[[{
                                    key = "Double Tap Debugcamera";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        message = "Bind this to the same key as your in-game debug key";
                                        hotkey = {
                                            key = "Debugcamera Hotkey";
                                            value = {
                                                shortKeyName = "N";
                                                activeKey = keys.N.offset;
                                                keyState = false;
                                                allowChange = false;
                                                keyType = keyTypes.onHotkey;
                                            };
                                        };
                                        children = {
                                            {
                                                key = "Small Ban Risk";
                                                value = {
                                                    type = drawTypes.label;
                                                    message = "Small Ban Risk - bind same as in-game debugcamera key";
                                                };
                                            };
                                        };
                                    };
                                };]]
                                --[[{
                                    key = "Server Safe Debugcamera";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 2;
                                        message = "will not get you banned from servers. but status is unknown on EAC";
                                        hotkey = {
                                            key = "Safe Debugcamera Hotkey";
                                            value = {
                                                shortKeyName = "J";
                                                activeKey = keys.J.offset;
                                                keyState = false;
                                                allowChange = false;
                                                keyType = keyTypes.onHotkey;
                                            };
                                        };
                                    };
                                };]]
                                --[[{
                                    key = "Debugcamera Movement";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        message = "Keeps moving direction you were moving";
                                    };
                                };]]
                                --[[{
                                    key = "Override Cam Values";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                        children = {
                                            {
                                                key = "Camspeed";
                                                value = {
                                                    type = drawTypes.slider;
                                                    state = 0.3;
                                                    maxValue = 1;
                                                    minValue = 0;
                                                    decimalPoints = 2;
                                                    doText = true;
                                                };
                                            };
                                        };
                                    };
                                };]]
                            };
                        };
                        {
                            paneName = "Other";
                            autoAdjustForElements = true;
                            elements = {
                                {
                                    key = "Low Fuel Warning";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = true;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Low Fuel Warning Color";
                                            value = {
                                                color = {r = 39, g = 194, b = 18, a = 255};
                                            }
                                        };
                                    };
                                };
                                --[[{
                                    key = "Admin Flags";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 2;
                                        message = "Server ban likely";
                                        children = {
                                            {
                                                key = "Admin Flags On Hotkey";
                                                value = {
                                                    type = drawTypes.checkbox;
                                                    state = true;
                                                    checkboxType = 1;
                                                    hotkey = {
                                                        key = "Admin Flags Key";
                                                        value = {
                                                            shortKeyName = "K";
                                                            activeKey = keys.K.offset;
                                                            keyState = false;
                                                            allowChange = true;
                                                            keyType = keyTypes.onHotkey;
                                                            --message = "Framerate of the overlay not fast enough";
                                                        };
                                                    };
                                                };
                                            };
                                        };
                                    };
                                };
                                {
                                    key = "Block Server Commands";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 4;
                                        message = "Some server admins can track this";
                                        callback = function(element) 
                                            if not element.value.state then 
                                                cheat.misc:blockServerCommands(nil, true) 
                                                cheat.misc.commandsBlocked = false;
                                            else
                                                cheat.misc:blockServerCommands(true) 
                                                cheat.misc.commandsBlocked = true;
                                            end; 
                                        end;
                                        children = {
                                            {
                                                key = "Only Block While Admin";
                                                value = {
                                                    type = drawTypes.checkbox;
                                                    state = true;
                                                    message = "Recommended";
                                                    checkboxType = 1;
                                                };
                                            };
                                        };
                                    };
                                };]]
                                {
                                    key = "Alerts";
                                    value = {
                                        type = drawTypes.multiselect;
                                        doText = true;
                                        options = {
                                            {
                                                key = 'Player With M249';
                                                value = true;
                                            };
                                            {
                                                key = 'Player With Boom';
                                                value = true;
                                            };
                                            {
                                                key = 'Player Bots';
                                                value = true;
                                            };
                                        };
                                    };
                                };
                                        
                            };
                        };
                    };
                --[[}
            };]]
        },
        {
            tabName = "Configs";
            bitmap = {
                url = "https://i.imgur.com/Hnk7JKD.png";
                width = 50;
                height = 50;
            };
            currentSubtab = 1;
            menuSubtabs = {
                {
                    subtabName = "Config";
                    leftPanes = {
                        {
                            paneName = "Config";
                            elements = {
                                {
                                    key = "Config Menu";
                                    value = {
                                        type = drawTypes.optionBox;
                                        activeOption = nil;
                                        callback = function(element, selectedOption) draw.cachedUiVars.configs.config.configName.value.typedText = selectedOption.name end;
                                        options = {
                                            
                                        };
                                    };
                                };
                                {
                                    key = "Config Name";
                                    value = {
                                        type = drawTypes.inputBox;
                                        doText = false;
                                    };
                                };
                                {
                                    key = "Load";
                                    value = {
                                        type = drawTypes.button;
                                        callback = function() return configs:loadActive() end;
                                    };
                                };
                                {
                                    key = "Save";
                                    value = {
                                        type = drawTypes.button;
                                        callback = function() return configs:save() end;
                                    };
                                };
                                {
                                    key = "Delete";
                                    value = {
                                        type = drawTypes.button;
                                        callback = function() return configs:deleteActive() end;
                                    };
                                };
                                {
                                    key = "Export Config";
                                    value = {
                                        type = drawTypes.button;
                                        callback = function() return configs:copyToClipboard() end;
                                    };
                                };
                                {
                                    key = "Import Config";
                                    value = {
                                        type = drawTypes.button;
                                        callback = function() return configs:loadFromClipboard() end;
                                    };
                                };
                                {
                                    key = "Export Colors";
                                    value = {
                                        type = drawTypes.button;
                                        callback = function() return configs:copyColorsToClipboard() end;
                                    };
                                };
                                {
                                    key = "Disable All Unsafe";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = true;
                                        checkboxType = 3;
                                        message = "Stops any unknown/unsafe features from being enabled/clicked on";
                                        callback = function(element) if element.value then
                                            draw:loopElements(function(v, tabName, subtabName, paneName)
                                                if v.key ~= 'Disable All Unsafe' then
                                                    if v.value.checkboxType ~= nil and v.value.checkboxType ~= 1 and v.key ~= element.key then
                                                        v.value.state = false;
                                                    end
                                                end
                                            end, nil);
                                            storageSystem:updateUnsafe();
                                        end end;
                                    };
                                };
                                {
                                    key = "Menu Key";
                                    value = {
                                        type = drawTypes.hotkey;
                                        shortKeyName = "INS";
                                        activeKey = keys.INS.offset;
                                        keyState = false;
                                        allowChange = false;
                                        keyType = keyTypes.onHotkey;
                                        bindCallback = function(element)
                                            storageSystem:handleMenuKey(element)
                                        end;
                                    };
                                };
                            };
                        };
                    };
                    rightPanes = {
                        {
                            paneName = "Lua";
                            elements = {
                                {
                                    key = "Lua Menu";
                                    value = {
                                        type = drawTypes.optionBox;
                                        activeOption = nil;
                                        options = {
                                            --[[{
                                                selected = false;
                                                name = "Create ui element";
                                               
                                            };
                                            {
                                                selected = false;
                                                name = "other test";
                                               
                                            };]]
                                        };
                                    };
                                };
                                --[[{
                                    key = "Load Lua";
                                    value = {
                                        type = drawTypes.button;
                                        --callback = function() luaEnv:loadLua(); luaEnv:assignLuaButtonName() end;
                                    };
                                };]]
                            };
                        };
                        {
                            paneName = "Crosshair";
                            autoAdjustForElements = true;
                            elements = {
                                {
                                    key = "Crosshair";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = true;
                                        checkboxType = 1;
                                        colorpicker = {
                                            key = "Crosshair Color";
                                            value = {
                                                color = {r = 196, g = 237, b = 0, a = 255};
                                            }
                                        };
                                        children = {
                                            {
                                                key = "Crosshair Gap";
                                                value = {
                                                    type = drawTypes.slider;
                                                    state = 2;
                                                    maxValue = 30;
                                                    minValue = 1;
                                                    doText = true;
                                                    textSpecifier = "px";
                                                };
                                            };
                                            {
                                                key = "Crosshair Length";
                                                value = {
                                                    type = drawTypes.slider;
                                                    state = 0;
                                                    maxValue = 30;
                                                    minValue = 0;
                                                    doText = true;
                                                    textSpecifier = "px";
                                                };
                                            };
                                            {
                                                key = "Crosshair Dot";
                                                value = {
                                                    type = drawTypes.slider;
                                                    state = 2;
                                                    maxValue = 30;
                                                    minValue = 0;
                                                    doText = true;
                                                    textSpecifier = "px";
                                                };
                                            };
                                            {
                                                key = "Crosshair Outline";
                                                value = {
                                                    type = drawTypes.slider;
                                                    state = 1;
                                                    maxValue = 3;
                                                    minValue = 0;
                                                    doText = true;
                                                    textSpecifier = "px";
                                                };
                                            };
                                            {
                                                key = "Crosshair Size";
                                                value = {
                                                    type = drawTypes.slider;
                                                    state = 0;
                                                    maxValue = 25;
                                                    minValue = 0;
                                                    doText = true;
                                                    textSpecifier = "px";
                                                };
                                            };
                                        };
                                    };
                                };
                                --[[{
                                    key = "Flyhack";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 4;
                                        hotkey = {
                                            key = "Flyhack Hotkey";
                                            value = {
                                                shortKeyName = "F";
                                                activeKey = keys.F.offset;
                                                keyState = false;
                                                allowChange = true;
                                                keyType = keyTypes.onHotkey;
                                            };
                                        };
                                    };
                                };]]
                            };
                        };
                    };
                };
            },
        },
    },

    crosshair = {
        drawCrosshair = function(self)
            if draw.cachedUiVars.configs.config.crosshair.value.state then
                local color = draw.cachedUiVars.configs.config.crosshair.value.colorpicker.value.color;

                local outlineThickness = draw.cachedUiVars.configs.config.crosshairOutline.value.state;
                local crosshairSize = draw.cachedUiVars.configs.config.crosshairSize.value.state;

                --if draw.cachedUiVars.misc.crosshairType.value.state == 1 then
                --    draw.Context:DrawCircle(draw.screenWidth/2, draw.screenHeight/2, crosshairSize + outlineThickness, 0, 0, 0, color.a, 1, true)
                --    draw.Context:DrawCircle(draw.screenWidth/2, draw.screenHeight/2, crosshairSize, color.r, color.g, color.b, color.a, 1, true)
                --elseif draw.cachedUiVars.misc.crosshairType.value.state == 2 then
                    local gap = draw.cachedUiVars.configs.config.crosshairGap.value.state;
                    local crosshairLength = draw.cachedUiVars.configs.config.crosshairLength.value.state;
                    local crosshairDot = draw.cachedUiVars.configs.config.crosshairDot.value.state;

                    -- Calculate the center position
                    local centerX = draw.screenSize.x / 2
                    local centerY = draw.screenSize.y / 2

                    --draw dot
                    if crosshairDot > 0.66 then
                        render.draw_circle(draw.screenSize.x/2, draw.screenSize.y/2, crosshairDot + outlineThickness, 0, 0, 0, 255, 1, true)
                        render.draw_circle(draw.screenSize.x/2, draw.screenSize.y/2, crosshairDot, color.r, color.g, color.b, 255, 1, true)
                    end

                    if crosshairLength > 0.99 then

                        --draw left
                        drawRectangle(centerX - crosshairLength - gap - outlineThickness, centerY - (crosshairSize/2) - outlineThickness, crosshairLength + (outlineThickness*2), crosshairSize + (outlineThickness*2), 0, 0, 0, color.a, true, 1)
                        drawRectangle(centerX - crosshairLength - gap, centerY - (crosshairSize/2), crosshairLength, crosshairSize, color.r, color.g, color.b, color.a, true, 1)

                        --draw right
                        drawRectangle(centerX + gap - outlineThickness, centerY - (crosshairSize/2) - outlineThickness, crosshairLength + (outlineThickness*2), crosshairSize + (outlineThickness*2), 0, 0, 0, color.a, true, 1)
                        drawRectangle(centerX + gap, centerY - (crosshairSize/2), crosshairLength, crosshairSize, color.r, color.g, color.b, color.a, true, 1)

                        --draw top
                        drawRectangle(centerX - (crosshairSize/2) - outlineThickness, centerY - gap - crosshairLength - outlineThickness, crosshairSize + (outlineThickness*2), crosshairLength + (outlineThickness*2), 0, 0, 0, color.a, true, 1)
                        drawRectangle(centerX - (crosshairSize/2), centerY - gap - crosshairLength, crosshairSize, crosshairLength, color.r, color.g, color.b, color.a, true, 1)

                        --draw bottom
                        drawRectangle(centerX - (crosshairSize/2) - outlineThickness, centerY + gap - outlineThickness, crosshairSize + (outlineThickness*2), crosshairLength + (outlineThickness*2), 0, 0, 0, color.a, true, 1)
                        drawRectangle(centerX - (crosshairSize/2), centerY + gap, crosshairSize, crosshairLength, color.r, color.g, color.b, color.a, true, 1)
                    end
                --end
            end
        end;
    };

    hardcodedOffsets = {
        ["BaseCombatEntity._health"] = 584,
        ["BaseCombatEntity.lifestate"] = 564,
        ["BaseEntity._name"] = 304,
        ["BaseEntity.addedToParentEntity"] = 360,
        ["BaseEntity.flags"] = 208,
        ["BaseEntity.model"] = 200,
        ["BaseMovement.<TargetMovement>k__BackingField"] = 60,
        ["BaseNetworkable.<IsDestroyed>k__BackingField"] = 64,
        ["BaseNetworkable.children"] = 72,
        ["BaseNetworkable.net"] = 80,
        ["BaseNetworkable.prefabID"] = 48,
        ["BasePlayer.UserIDString"] = 616,
        ["BasePlayer._displayName"] = 1016,
        ["BasePlayer.clActiveItem"] = 1120,
        ["BasePlayer.clientTeam"] = 1048,
        ["BasePlayer.currentTeam"] = 1072,
        ["BasePlayer.input"] = 1384,
        ["BasePlayer.modelState"] = 640,
        ["BasePlayer.mounted"] = 1184,
        ["BasePlayer.movement"] = 1416,
        ["BasePlayer.playerFlags"] = 1368,
        ["BasePlayer.playerModel"] = 1456,
        ["BaseProjectile.Magazine:ammoType"] = 32,
        ["BaseProjectile.aimCone"] = 848,
        ["BaseProjectile.aimconePenaltyPerShot"] = 856,
        ["BaseProjectile.hipAimCone"] = 852,
        ["BaseProjectile.primaryMagazine"] = 792,
        ["BaseProjectile.projectileVelocityScale"] = 724,
        ["BaseProjectile.recoil"] = 832,
        ["BaseProjectile.stancePenaltyScale"] = 872,
        ["CameraMan"] = 198645536,
        ["DroppedItemContainer._playerName"] = 592,
        ["EffectData.origin"] = 24,
        ["EffectNetwork_c*"] = 199266664,
        ["Facepunch.Input"] = 198873152,
        ["Facepunch.Input.buttons"] = 336,
        ["FlintStrikeWeapon.successFraction"] = 1008,
        ["GestureConfig.playerModelLayer"] = 104,
        ["HackableLockedCrate.hackSeconds"] = 896,
        ["HackableLockedCrate.timerText"] = 880,
        ["HeldEntity.isDeployed"] = 456,
        ["HeldEntity.ownerItemUID"] = 528,
        ["IOEntity.IORef.entityRef"] = 16,
        ["IOEntity.IORef.ioEnt"] = 32,
        ["IOEntity.inputs"] = 656,
        ["IOEntity.outputs"] = 664,
        ["IOSlot.connectedTo"] = 32,
        ["IOSlot.linePoints"] = 56,
        ["IOSlot.niceName"] = 16,
        ["Input.Button.Binds"] = 16,
        ["Input.Button.Code"] = 40,
        ["Input.Button.Name"] = 56,
        ["Item.heldEntity"] = 112,
        ["Item.info"] = 96,
        ["Item.worldEnt"] = 152,
        ["ItemContainer.capacity"] = 96,
        ["ItemContainer.itemList"] = 56,
        ["ItemDefinition.category"] = 80,
        ["ItemDefinition.displayName"] = 56,
        ["ItemDefinition.itemid"] = 32,
        ["ItemDefinition.shortname"] = 40,
        ["ItemModProjectile.projectileObject"] = 32,
        ["ItemModProjectile.projectileVelocity"] = 60,
        ["LootableCorpse._playerName"] = 648,
        ["MainCamera_c*"] = 198904696,
        ["ModelState.flags"] = 64,
        ["Network.Client.<ConnectedAddress>k__BackingField"] = 128,
        ["Network.Client.<ConnectedPort>k__BackingField"] = 128,
        ["Network.Client.<ServerName>k__BackingField"] = 128,
        ["Network.Net.<cl>k__BackingField"] = 0,
        ["Network_Net_c*"] = 199235424,
        ["Networkable.ID"] = 32,
        ["PatrolHelicopter.weakspots"] = 984,
        ["PlayerEyes.<bodyRotation>k__BackingField"] = 80,
        ["PlayerHelicopter.cachedFuelFraction"] = 1192,
        ["PlayerInput.bodyAngles"] = 68,
        ["PlayerModel.<LookAngles>k__BackingField"] = 448,
        ["PlayerModel.CurrentGestureConfig"] = 344,
        ["PlayerModel.InGesture"] = -1180899056,
        ["PlayerModel.drawShadowOnly"] = 580,
        ["PlayerModel.position"] = 472,
        ["PlayerModel.velocity"] = 508,
        ["PlayerModel.visible"] = 588,
        ["Projectile.drag"] = 44,
        ["Projectile.gravityModifier"] = 48,
        ["Projectile.thickness"] = 52,
        ["ProjectileWeaponMod.projectileVelocity"] = 448,
        ["RecoilProperties.newRecoilOverride"] = 128,
        ["RecoilProperties.recoilPitchMax"] = 36,
        ["RecoilProperties.recoilPitchMin"] = 32,
        ["RecoilProperties.recoilYawMax"] = 28,
        ["RecoilProperties.recoilYawMin"] = 24,
        ["RustCamera.ambientLightDay"] = 220,
        ["SingletonComponent_MainCamera__c*"] = 198464664,
        ["TOD_AmbientParameters.Saturation"] = 20,
        ["TOD_CycleParameters.Hour"] = 16,
        ["TOD_DayParameters.AmbientMultiplier"] = 80,
        ["TOD_NightParameters.AmbientMultiplier"] = 88,
        ["TOD_NightParameters.LightIntensity"] = 80,
        ["TOD_Sky.Ambient"] = 152,
        ["TOD_Sky.Cycle"] = 64,
        ["TOD_Sky.Day"] = 88,
        ["TOD_Sky.Night"] = 96,
        ["TOD_Sky_c*"] = 198928288,
        ["TimerSwitch.timePassed"] = 720,
        ["UnityEngine.UI.Text.m_Text"] = 216,
        ["World.mapSeed"] = 224,
        ["World.mapSize"] = 516,
        ["WorldItem.item"] = 424,
        ["World_c*"] = 198580456,
        ["camera.position"] = 1108,
        ["camera.viewMatrix"] = 780,
        ["il2cpp.gchandle"] = 201685920,
    },

    offsets = {
        projectileWeaponMod = {
            projectileVelocity = {
                search = "ProjectileWeaponMod:projectileVelocity",
                offset = 0x198,
            };
        };
        itemModProjectile = {
            projectileVelocity = {
                search = "ItemModProjectile:projectileVelocity",
                offset = 0x3C,
            };
            projectileObject = {
                search = "ItemModProjectile:projectileObject",
                offset = 0x20,
            };
        };
        projectile = {
            drag = {

                --- get address from .ctor
                search = "Projectile:drag",
                offset = 0x2C,
            };
            gravityModifier = {
                search = "Projectile:gravityModifier",
                offset = 0x30,
            };
            thickness = {
                search = "Projectile:thickness",
                offset = 0x34,
            };
        };
        networkable = {
            id = {
                offset = 0x30,
                search = "Networkable:ID",
            },
        };
        baseNetworkable = {
            isDestroyed = {
                search = "BaseNetworkable:<IsDestroyed>k__BackingField",
                offset = 0x36,
                failed = true,
            },
            children = {
                offset = 0x68,
                search = "BaseNetworkable:children",
            },
            prefabUid = {
                offset = 0x30,
                search = "BaseNetworkable:prefabID",
            },
            net = {
                offset = 0x30,
                search = "BaseNetworkable:net",
            },
            --[[prefabName = {
                search = "BaseNetworkable:_prefabName",
                offset = 0x38,
                failed = true,
                setup = function()
                    for fieldName, field in pairs(cheat.il2cpp.cachedClasses["BaseNetworkable"].classFields.cachedFields) do
                        if field.identifier == "string" and field.flags.private and not field.flags.static then
                            return field.offset
                        end
                    end return 0;
                end;
            },]]
            isStaticClass = true,
        },
        debugging = {
            debugcamera = {
                offset = 0x2153F70,
                isFunction = true,
            },
        },
        playerInventory = {
            containerBelt = {
                search = "PlayerInventory:containerBelt",
                offset = 0x68,
                failed = true,
            },
        },
        consoleSystemIndex = {
            --isStaticClass = true,
            --search = "ConsoleSystem_Index_c*",
            offset = 0x9EA9490,
            allCommands = {
                offset = 0x10,
                search = "ConsoleSystem.Index:<All>k__BackingField",
            },
        },
        recoilProperties = {
            pitchMin = {
                offset = 0x20,
                search = "RecoilProperties:recoilPitchMin",
            },
            pitchMax = {
                offset = 0x24,
                search = "RecoilProperties:recoilPitchMax",
            },
            newRecoilOverride = {
                offset = 0x80,
                search = "RecoilProperties:newRecoilOverride",
            },
            yawMin = {
                offset = 0x18,
                search = "RecoilProperties:recoilYawMin",
            },
            yawMax = {
                offset = 0x1C,
                search = "RecoilProperties:recoilYawMax",
            },
        },
        world = {
            search = "World_c*",
            offset = 0x9E86AE0,
            mapUrl = {
                offset = 0x110,
            },
            isStaticClass = true,
            mapSeed = {
                offset = 0x398,
                --[[setup = function(self)
                    if not cheat.il2cpp.cachedClasses["RandomDestroy"].classMethods then
                        cheat.il2cpp.cachedClasses["RandomDestroy"].classMethods = cheat.il2cpp:il2cpp_class_get_methods(cheat.il2cpp.cachedClasses["RandomDestroy"].class, true)
                    end

                    local functionStartAddress = cheat.il2cpp.cachedClasses["RandomDestroy"].classMethods.cachedMethods["Start"].address

                    --Input.SetClipboard(functionStartAddress) --140716664336800

                    local foundPattern = Process.FindPattern(cheat.capturedProcess, functionStartAddress, math.floor(0x22F*1.3), "\x8B\x48\x00\x03\x4B\x00", "xx?xx");

                    log('world: ', functionStartAddress, ' - ', foundPattern, ' - ', cheat.process:readInt64(functionStartAddress))

                    if foundPattern ~= 0 then
                        local off = cheat.process:readInt8(foundPattern + 2);
                        if off < 0 then
                            off = off & 0xFF
                        end

                        log('off: ', off)

                        return off;
                    end return 0;
                end;]]
            },
            mapSize = {
                offset = 0xCC,
                search = "World:mapSize",
            },
        },
        ioRef = {
            ioEnt = {
                offset = 0x20,
                search = "IOEntity.IORef:ioEnt",
            },
            entityRef = {
                search = "IOEntity.IORef:entityRef",
                offset = 0x10,
                failed = true,
            },
        },
        basePlayer = {
            clActiveItem = {
                offset = 0x9A0,
                search = "BasePlayer:clActiveItem",
            },
            clientTeam = {
                offset = 0x9A0,
                search = "BasePlayer:clientTeam",
            },
            baseMovement = {
                offset = 0xBA8,
                search = "BasePlayer:movement",
            },
            playerModel = {
                offset = 0xB98,
                search = "BasePlayer:playerModel",
            },
            playerInput = {
                offset = 0xB20,
                search = "BasePlayer:input",
            },
            _displayName = {
                offset = 0xB70,
                search = "BasePlayer:_displayName",
            },
            currentTeam = {
                offset = 0x978,
                search = "BasePlayer:currentTeam",
            },
            modelState = {
                offset = 0xBE0,
                search = "BasePlayer:modelState",
            },
            userIdString = {
                offset = 0xB30,
                search = "BasePlayer:UserIDString",
            };
            playerFlags = {
                offset = 0xA68,
                search = "BasePlayer:playerFlags",
            },
            model = {
                bufferSize = 65536,
                search = "BaseEntity:model",
                offset = 0xA8,
            },
            mounted = {
                offset = 0x9C8,
                search = "BasePlayer:mounted",
            },
        },
        networkClient = {
            connectedName = {
                offset = 0xE8,
                search = "Network:Client:<ServerName>k__BackingField",
            },
            connectedPort = {
                offset = 0xE0,
                search = "Network:Client:<ConnectedPort>k__BackingField",
            },
            connectedAddress = {
                offset = 0xD8,
                search = "Network:Client:<ConnectedAddress>k__BackingField",
            },
        },
        heldEntity = {
            isDeployed = {
                offset = 0x1A8,
                search = "HeldEntity:isDeployed",
            },
        };
        item = {
            heldEntity = {
                search = "Item:heldEntity",
                offset = 0x28,

            },
            worldEnt = {
                search = "Item:worldEnt",
                offset = 78,
            },
            itemDefinition = {
                offset = 0x98,
                search = "Item:info",
            },
        },
        baseMovement = {
            targetMovement = {
                search = "BaseMovement:<TargetMovement>k__BackingField",
                offset = 0x3C,
                failed = true,
            },
        },
        baseCombatEntity = {
            lifeState = {
                offset = 0x26C,
                search = "BaseCombatEntity:lifestate",
            },
            health = {
                search = "BaseCombatEntity:_health",
                offset = 0x27C,
                failed = true,
            },
        },
        todSky = {
            nightParams = {
                offset = 0x60,
                search = "TOD_Sky:Night",
            },
            search = "TOD_Sky_c*",
            offset = 0x9ED2BB0,
            ambientParams = {
                offset = 0x98,
                search = "TOD_Sky:Ambient",
            },
            isStaticClass = true,
            dayParams = {
                offset = 0x58,
                search = "TOD_Sky:Day",
            },
            timeSinceAmbientUpdate = {
                offset = 0x23C,
                search = "TOD_Sky:timeSinceAmbientUpdate",
            },
            cycle = {
                offset = 0x40,
                search = "TOD_Sky:Cycle",
            },
        },
        modelState = {
            flags = {
                offset = 0x20,
                search = "ModelState:flags",
            },
        },
        lootableCorpse = {
            playerName = {
                offset = 0x348,
                search = "LootableCorpse:_playerName",
            },
        },
        playerHelicopter = {
            cachedFuelFraction = {
                offset = 0x708,
                search = "PlayerHelicopter:cachedFuelFraction",
            },
        },
        camera = {
            cameraPosition = {
                offset = 0x454,
                search = "camera.position";
            },
            viewMatrix = {
                offset = 0x30C,
                bufferSize = 65536,
                search = "camera.viewMatrix";
            },
        },
        conButton = {
            isDown = {
                offset = 0x10,
            },
        },
        ioEntity = {
            inputs = {
                offset = 0x2C8,
                search = "IOEntity:inputs",
            },
            outputs = {
                offset = 0x2D0,
                search = "IOEntity:outputs",
            },
        },
        todDayParams = {
            ambientMultiplier = {
                offset = 0x50,
                search = "TOD_DayParameters:AmbientMultiplier",
            },
        },
        todCycleParameters = {
            hour = {
                offset = 0x10,
                search = "TOD_CycleParameters:Hour",
            },
        },
        worldItem = {
            item = {
                offset = 0x180,
                search = "WorldItem:item",
            },
        },
        consoleSystemCommand = {
        },
        heldItem = {
            ownerItemUid = {
                offset = 0x1F0,
                search = "HeldEntity:ownerItemUID",
            },
        },
        patrolHelicopter = {
            weakSpots = {
                offset = 0x410,
                search = "PatrolHelicopter:weakspots",
            },
        },
        gchandle = {
            il2cpp = {
                pattern = {
                    pattern = "\x48\x8D\x05\x00\x00\x00\x00\x83\xE2",
                    rvaOffset = 3,
                    mask = "xxx????xx",
                    size = 7,
                },
                search = "il2cpp.gchandle";
                offset = 0x0,
                isStaticClass = true,
            },
        },
        effectData = {
            origin = {
                offset = 0x1C,
                search = "EffectData:origin",
            },
        },
        staticOffset = {
            offset = 0xB8,
            bufferSize = 65536,
        },
        baseProjectileMagazine = {
            ammoType = {
                offset = 0x20,
                search = "BaseProjectile.Magazine:ammoType",
            },
        },
        effectNetwork = {
            isStaticClass = true,
            search = "EffectNetwork_c*",
            offset = 0x9E52068,
        },
        baseEntity = {
            _name = {
                offset = 0x150,
                search = "BaseEntity:_name",
            },
            flags = {
                offset = 0xB0,
                search = "BaseEntity:flags",
            },
            addedToParentEntity = {
                offset = 0xF8,
                search = "BaseEntity:addedToParentEntity",
            },
        },
        playerEyes = {
            bodyRotation = {
                search = "PlayerEyes:<bodyRotation>k__BackingField",
                offset = 0x4C,
                failed = true,
            },
        },
        text = {
            string = {
                offset = 0xD8,
                search = "UnityEngine.UI:Text:m_Text",
            },
        },
        net = {
            isStaticClass = true,
            search = "Network_Net_c*",
            offset = 167653888,
            client = {
                offset = 0x0,
                search = "Network:Net:<cl>k__BackingField",
            },
        },
        gestureConfig = {
            playerModelLayer = {
                offset = 0x1C8,
                search = "GestureConfig:playerModelLayer",
            },
        },
        playerModel = {
            position = {
                offset = 0x1C8,
                search = "PlayerModel:position",
            },
            newVelocity = {
                search = "PlayerModel:velocity",
                offset = 0x1EC,
            },
            visible = {
                offset = 0x23C,
                search = "PlayerModel:visible",
            },
            lookAngles = {
                search = "PlayerModel.<LookAngles>k__BackingField";
                offset = 0x23C,
            };
            currentGestureConfig = {
                search = "PlayerModel:CurrentGestureConfig";
                offset = 0x0,
            };
            inGesture = {
                search = "PlayerModel:InGesture";
                offset = 0x0,
            };
        },
        todNightParams = {
            lightIntensity = {
                offset = 0x48,
                search = "TOD_NightParameters:LightIntensity",
            },
            ambientMultiplier = {
                offset = 0x50,
                search = "TOD_NightParameters:AmbientMultiplier",
            },
        },
        ioSlot = {
            slotName = {
                offset = 0x10,
                search = "IOEntity.IOSlot:niceName",
            },
            connectedTo = {
                offset = 0x20,
                search = "IOEntity.IOSlot:connectedTo",
            },
            lines = {
                offset = 0x30,
                search = "IOEntity.IOSlot:linePoints",
            },
        },
        localPlayer = {
            getLocalPlayer = {
                offset = 0x0EA5FF0,
                isFunction = true,
            },
        },
        droppedItemContainer = {
            playerName = {
                offset = 0x318,
                search = "DroppedItemContainer:_playerName",
            },
        },
        itemContainer = {
            itemList = {
                offset = 0x38,
                search = "ItemContainer:itemList",
            },
            capacity = {
                offset = 0x38,
                search = "ItemContainer:capacity",
            },
        },
        mainCamera = {
            isStaticClass = true,
            search = "MainCamera_c*",
            offset = 0x9E2F0D8,
        },
        mainCameraSingleton = {
            isStaticClass = true,
            search = "SingletonComponent_MainCamera__c*",
            offset = 198074304,
        },
        rustCamera = {
            ambientLightDay = {
                search = "RustCamera<T>:ambientLightDay",
                offset = 220,
            },
            lightIntensity = {
                search = "RustCamera<T>:lightIntensity",
                offset = 0xCC,
            },
        };
        playerInput = {
            bodyAngles = {
                search = "PlayerInput:bodyAngles",
                offset = 0x44,
            },
            offsetAngles = {
                search = "PlayerInput:offsetAngles",
                offset = 0xBC,
            },
        },
        client = {
            camspeed = {
                offset = 0x6C,
            },
            search = "ConVar_Client_c*",
            offset = 0x9E86658,
            camlerp = {
                offset = 0x74,
            },
            isStaticClass = true,
            camlookspeed = {
                offset = 0x20,
            },
            camzoomlerp = {
                offset = 0x84,
            },
            camzoomspeed = {
                offset = 0xD4,
            },
        },
        baseProjectile = {
            projectileVelocityScale = {
                offset = 0x2B4,
                search = "BaseProjectile:projectileVelocityScale",
            },
            aimconePenaltyPerShot = {
                offset = 0x328,
                search = "BaseProjectile:aimconePenaltyPerShot",
            },
            offset = 0x9E8C600,
            stancePenaltyScale = {
                offset = 0x338,
                search = "BaseProjectile:stancePenaltyScale",
            },
            aimCone = {
                offset = 0x320,
                search = "BaseProjectile:aimCone",
            },
            hipAimCone = {
                offset = 0x324,
                search = "BaseProjectile:hipAimCone",
            },
            recoilProperties = {
                offset = 0x310,
                search = "BaseProjectile:recoil",
            },
            primaryMagazine = {
                offset = 0x2F0,
                search = "BaseProjectile:primaryMagazine",
            },
        },
        flintStrikeWeapon = {
            successFraction = {
                offset = 0x3B8,
                search = "FlintStrikeWeapon:successFraction",
            },
        },
        codeLockedHackableCrate = {
            hackSeconds = {
                offset = 0x570,
                search = "HackableLockedCrate:hackSeconds",
            },
            text = {
                offset = 0x560,
                search = "HackableLockedCrate:timerText",
            },
        },
        timerSwitch = {
            timePassed = {
                search = "TimerSwitch:timePassed",
                offset = 0x380,
            },
        },
        itemDefinition = {
            shortName = {
                offset = 0x28,
                search = "ItemDefinition:shortname",
            },
            itemId = {
                offset = 0x20,
                search = "ItemDefinition:itemid",
            },
            catagory = {
                offset = 0x48,
                search = "ItemDefinition:category",
            },
            displayName = {
                offset = 0x20,
                search = "ItemDefinition:displayName",
            },
        },
    };

    client = {
        seconds = 0;
    };

    class = {
        hasFlag = function(self, flags, flag)
            return (flags & flag) ~= 0
        end;

        gameObject = {
            functions = {
                getGameObjectTransform = function(self)
                    local baseObject = cheat.process:readInt64(self.entity + 0x10);
                    if baseObject ~= 0 then
                        local gameObject = cheat.process:readInt64(baseObject + 0x30);
                        if gameObject ~= 0 then
                            local transform1 = cheat.process:readInt64(gameObject + 0x30);
                            if transform1 ~= 0 then
                                local transform2 = cheat.process:readInt64(transform1 + 0x8);
                                if transform2 ~= 0 then
                                    local transform = cheat.process:readInt64(transform2 + 0x28);
                                    if transform ~= 0 then
                                        local transformInternal = cheat.process:readInt64(transform + 0x10);
                                        if transformInternal ~= 0 then
                                            --[[local x,y,z = Intrin.UnityGetPositionFromTransform(transformInternal)
        
                                            if x and y and x ~= 0 then
                                                Engine.Log('position: ' .. x .. " - " .. y .. " - " .. z, 255, 255, 255, 255)
                                            end]]
                                            return transformInternal;
                                        end
                                    end
                                end
                            end
                        end
                    end
        
                    return 0;
                end;
            };
        };

        net = {
            functions = {
                getClient = function(self)
                    if not cheat.class.net.clientOffset then
                        
                    end
    
                    return cheat.class.network.client:create(cheat.offsets.net.staticClass + cheat.offsets.net.client.offset);
                end;

                getConnectedIp = function(self)
                    if not cheat.class.net.clientOffset then
                        for i = 0, 150 do
                            local randomRead = cheat.class.baseEntity:create(cheat.process:readInt64(self.entity + i));
                            if randomRead then
                                local className = randomRead:getClassName();
                                if className and string.len(className) > 5 and className:sub(1, 1) == "%" then
                                    for i2 = 0, 0x110 do
                                        local randomStringRead = cheat.process:readIl2cppString(randomRead.entity + i2);
                                        if randomStringRead and string.len(randomStringRead) > 2 then
                                            local dotCount = select(2, string.gsub(randomStringRead, "%.", ""))
                                            if dotCount >= 2 then
                                                cheat.class.net.clientOffset = i;
                                                cheat.class.net.clientIpOffset = i2;
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end

                    if cheat.class.net.clientOffset and cheat.class.net.clientIpOffset then
                        local clientRead = cheat.process:readInt64(self.entity + cheat.class.net.clientOffset);
                        if clientRead ~= 0 then
                            return cheat.process:readIl2cppString(clientRead + cheat.class.net.clientIpOffset);
                        end
                    end

                    return nil;
                end;
            };



            getStaticInstance = function(self)
                local classRead = cheat.process:readInt64(cheat.process.modules.gameAssembly.base + cheat.offsets.net.offset);
                if classRead ~= 0 then
                    local staticClass = cheat.process:readInt64(classRead + 0xB8);
                    if staticClass ~= 0 then
                        return cheat.class.net:create(staticClass)
                    end
                end

                return nil;
            end;
        };

        network = {
            client = {
                functions = {
                    getConnectedPort = function(self)
                        if not self.entity or self.entity == 0 then
                            return 0;
                        end
        
                        return cheat.process:readInt32(self.entity + cheat.offsets.networkClient.connectedPort.offset);
                    end;
        
                    getConnectedAddress = function(self)
                        if not self.entity or self.entity == 0 then
                            return 0;
                        end
        
                        return cheat.process:readIl2cppString(self.entity + cheat.offsets.networkClient.connectedAddress.offset);
                    end;

                    getServerName = function(self)
                        if not self.entity or self.entity == 0 then
                            return 0;
                        end
        
                        return cheat.process:readIl2cppString(self.entity + cheat.offsets.networkClient.connectedAddress.offset);
                    end;
                };
            };
        };

        consoleSystemIndex = {
            functions = {
                getAllCommands = function(self)
                    return array:create(cheat.process:readInt64(self.entity + cheat.offsets.consoleSystemIndex.allCommands.offset));
                end;
            };

            getInstance = function(self)
                if not cheat.offsets.consoleSystemIndex.staticClass or cheat.offsets.consoleSystemIndex.staticClass == 0 then
                    return
                end;

                return self:create(cheat.offsets.consoleSystemIndex.staticClass)
            end;
        };

        consoleSystemCommand = {
            functions = {
                getName = function(self)
                    return cheat.process:readIl2cppString(self.entity + 0x10);
                end;

                modifyAllowRunFromServer = function(self, set)
                    if set ~= nil then
                        cheat.process:writeBool(self.entity + 0x60, set);
                    else
                        return cheat.process:readBool(self.entity + 0x60);
                    end
                end;
            };
        };

        effectData = {
            functions = {
                getOrigin = function(self)
                    return cheat.process:readVector3(self.entity + cheat.offsets.effectData.origin.offset);
                end;
    
                getPooledStringId = function(self)
                    return cheat.process:readInt64(self.entity + 0x14);
                end;
            };
        };

        conButton = {
            functions = {
                getIsDown = function(self)
                    return cheat.process:readInt8(self.entity + cheat.offsets.conButton.isDown.offset) == 1;
                end; 
            };
        };

        text = {
            functions = {
                getString = function(self)
                    return cheat.process:readIl2cppString(self.entity + cheat.offsets.text.string.offset );
                end;
            };
        };

        codeLockedHackableCrate = {
            inherit = {
                "baseEntity";
            };

            functions = {
                getText = function(self)
                    return cheat.class.text:create(cheat.process:readInt64(self.entity + cheat.offsets.codeLockedHackableCrate.text.offset));
                end; 
            };
        };

        world = {
            getGrid = function(self, pos)
                local worldSize = cheat.server.mapSize;
                if pos.x < -worldSize / 2 or pos.x > worldSize / 2 or pos.z < -worldSize / 2 or pos.z > worldSize / 2 then
                    return "OOB"
                end
            
                local x = math.floor((pos.x + (worldSize / 2)) / 146.3) + 1
                local z = math.floor(worldSize / 146.3) - math.floor((pos.z + (worldSize / 2)) / 146.3) - 1
            
                local buffer2 = {}
                while x > 0 do
                    x = x - 1 -- Decrement first to get 0-based value
                    table.insert(buffer2, 1, string.char(65 + (x % 26))) -- 'A' is ASCII 65
                    x = math.floor(x / 26)
                end
            
                local resultStr = table.concat(buffer2)
                
                if z <= -1 then
                    return "OOB"
                end
            
                return string.format("%s%i", resultStr, z)
            end;

            functions = {
                getMapSize = function(self)
                    return cheat.process:readInt32(self.entity + cheat.offsets.world.mapSize.offset); -- _size
                end;
    
                getMapSeed = function(self)
                    return cheat.process:readInt32(self.entity + cheat.offsets.world.mapSeed.offset);
                end;
    
                getMapUrl = function(self)
                    return cheat.process:readIl2cppString(self.entity + cheat.offsets.world.mapUrl.offset, 64);
                end;
            };

            getStaticInstance = function(self)
                if cheat.offsets.world.staticClass and cheat.offsets.world.staticClass ~= 0 then
                    return cheat.class.world:create(cheat.offsets.world.staticClass)
                end

                return nil;
            end;
        };

        patrolHelicopter = {
            inherit = {
                "baseCombatEntity";
            };

            functions = {
                getWeakSpots = function(self)
                    local weakSpots = cheat.process:readInt64(self.entity + cheat.offsets.patrolHelicopter.weakSpots.offset);
                    if weakSpots ~= 0 then
                        local mainRotor = cheat.process:readInt64(weakSpots + 0x20 + 0 * 0x8);
                        local tailRotor = cheat.process:readInt64(weakSpots + 0x20 + 1 * 0x8);
                        local returnTable = {};
    
                        if mainRotor ~= 0 then
                            returnTable.mainHealth = cheat.process:readFloat(mainRotor + 0x24);
                            returnTable.mainMaxHealth = cheat.process:readFloat(mainRotor + 0x20);
                        end
                        if tailRotor ~= 0 then
                            returnTable.tailHealth = cheat.process:readFloat(tailRotor + 0x24);
                            returnTable.tailMaxHealth = cheat.process:readFloat(tailRotor + 0x20);
                        end
                        if returnTable.mainHealth or returnTable.tailHealth then
                            return returnTable;
                        end
                    end
    
                    return nil;
                end;
            };
        };

        playerHelicopter = {
            inherit = {
                "baseCombatEntity";
            };

            functions = {
                getFuelGauge = function(self)
                    return cheat.process:readFloat(self.entity + cheat.offsets.playerHelicopter.cachedFuelFraction.offset);
                end;
            };
        };

        projectileWeaponMod = {
            inherit = {
                "baseEntity";
            };

            functions = {
                getProjectileVelocityModifier = function(self)
                    return {
                        enabled = cheat.process:readBool(self.entity + cheat.offsets.projectileWeaponMod.projectileVelocity.offset);
                        scale = cheat.process:readFloat(self.entity + cheat.offsets.projectileWeaponMod.projectileVelocity.offset + 0x4);
                    };
                end;
            };
        };

        itemModProjectile = {
            functions = {
                getProjectileVelocity = function(self)
                    return cheat.process:readFloat(self.entity + cheat.offsets.itemModProjectile.projectileVelocity.offset);
                end;


                getProjectile = function(self)
                    local object = cheat.process:readInt64(self.entity + cheat.offsets.itemModProjectile.projectileObject.offset)

                    if object ~= 0 then
                        local projectileRead = cheat.process:readInt64(object + 0x18 )
                        if projectileRead ~= 0 then
                            local projectileGameObject = cheat.process:readInt64(projectileRead + 0x10)
                            if projectileGameObject ~= 0 then
                                return cheat.class.projectile:create(cheat:getComponent(projectileGameObject, "Projectile", nil, true))
                            end
                        end
                    end

                    return nil;
                end;
            };
        };

        projectile = {
            functions = {
                getDrag = function(self)
                    return cheat.process:readFloat(self.entity + cheat.offsets.projectile.drag.offset);
                end;

                getGravityModifier = function(self)
                    return cheat.process:readFloat(self.entity + cheat.offsets.projectile.gravityModifier.offset);
                end;

                modifyThickness = function(self, set)
                    if set then
                        return cheat.process:writeFloat(self.entity + cheat.offsets.projectile.thickness.offset, set);
                    else
                        return cheat.process:readFloat(self.entity + cheat.offsets.projectile.thickness.offset);
                    end
                end;
            };
        };

        baseNetworkable = {
            inherit = {
                "gameObject";
            };

            functions = {
                getNetworkableId = function(self)
                    local networkable = cheat.process:readInt64(self.entity + cheat.offsets.baseNetworkable.net.offset);

                    if networkable ~= 0 then
                        return cheat.process:readInt64(networkable + cheat.offsets.networkable.id.offset);
                    end

                    return 0;
                end;

                getPrefabUid = function(self)
                    return cheat.process:readInt32(self.entity + cheat.offsets.baseNetworkable.prefabUid.offset);
                end;
    
                getIsDestroyed = function(self)
                    return cheat.process:readInt8(self.entity + cheat.offsets.baseNetworkable.isDestroyed.offset) == 1;
                end;
    
                getChildren = function(self)
                    return cheat.process:readInt64(self.entity + cheat.offsets.baseNetworkable.children.offset);
                end;
    
                getPrefabName = function(self)
                    --return cheat.process:readIl2cppString(self.entity + cheat.offsets.baseNetworkable.prefabName.offset, 64);
                    local baseObject = cheat.process:readInt64(self.entity + 0x10);
                    if baseObject ~= 0 then
                        local gameObject = cheat.process:readInt64(baseObject + 0x30);
                        if gameObject ~= 0 then
                            local objectNamePtr = cheat.process:readInt64(gameObject + 0x60)
                            if objectNamePtr ~= 0 then
                                return cheat.process:readString(objectNamePtr, 128) or "";
                            end
                        end
                    end

                    return "";
                end;
    
                getClassName = function(self)
                    local again = cheat.process:readInt64(self.entity);
                    if again ~= 0 then
                        local object = cheat.process:readInt64(again + 0x10);--object = cheat.process:readString(object + 0x10, 32);
                        if object ~= 0 then
                            --return cheat.process:readIl2cppString(object, 32) or "?";
                            return cheat.process:readString(object) or "";
                        end
                    end
    
                    return "";
                end;
            };
        };

        ioRef = {
            functions = {
                getBaseEntity = function(self)
                    return cheat.class.baseEntity:create(cheat.process:readInt64(self.entity + cheat.offsets.ioRef.entityRef.offset));
                end;

                getIOEntity = function(self)
                    return cheat.class.ioEntity:create(cheat.process:readInt64(self.entity + cheat.offsets.ioRef.ioEnt.offset));
                end;
            }
        };

        ioSlot = {
            functions = {
                getName = function(self)
                    return cheat.process:readIl2cppString(self.entity + cheat.offsets.ioSlot.slotName.offset);
                end;

                getConnectedTo = function(self)
                    return cheat.class.ioRef:create(cheat.process:readInt64(self.entity + cheat.offsets.ioSlot.connectedTo.offset));
                end;

                getLines = function(self)
                    return --[[array:create(]]cheat.process:readInt64(self.entity + cheat.offsets.ioSlot.lines.offset)--[[);]]
                end;
            }
        };

        timerSwitch = {
            inherit = {
                "ioEntity";
            };

            functions = {
                getTimePassed = function(self)
                    return cheat.process:readFloat(self.entity + cheat.offsets.timerSwitch.timePassed.offset)
                end;
            }
        };

        ioEntity = {
            inherit = {
                "baseCombatEntity";
            };

            functions = {
                getInputs = function(self)
                    return array:create(cheat.process:readInt64(self.entity + cheat.offsets.ioEntity.inputs.offset));
                end;

                getOutputs = function(self)
                    return array:create(cheat.process:readInt64(self.entity + cheat.offsets.ioEntity.outputs.offset));
                end;
            }
        };

        baseEntity = {
            inherit = {
                "baseNetworkable";
            };

            functions = {
                getVisualPosition = function(self, objectClass)
                    local baseObject = cheat.process:readInt64(self.entity + 0x10);
                    if baseObject ~= 0 then
                        local gameObject = cheat.process:readInt64(baseObject + 0x30);
                        if gameObject ~= 0 then
                            local visual = cheat.process:readInt64(gameObject + 0x30);
                            if visual ~= 0 then
                                local playerVisual = cheat.process:readInt64(visual + 0x8);
                                if playerVisual ~= 0 then
                                    local visualState = cheat.process:readInt64(playerVisual + 0x38); --will return 1D748FB55A0;
                                    if visualState ~= 0 then
                                        --Input.SetClipboard(visualState)
                                        return cheat.process:readVector3(visualState + 0x90);-- returns correct position
                                    end
                                end
                            end
                        end
                    end
                    return nil;
                end;

                bytesToFloat = function(self, byte1, byte2, byte3, byte4)
                    --[[local intValue = byte4 * 2^24 + byte3 * 2^16 + byte2 * 2^8 + byte1

                    -- Extract sign, exponent, and mantissa
                    local sign = ((intValue >> 31) == 0) and 1 or -1
                    local exponent = (intValue >> 23) & 0xFF
                    local mantissa = intValue & 0x7FFFFF
                
                    if exponent == 0 then
                        if mantissa == 0 then
                            return sign * 0.0 -- Zero
                        else
                            return sign * mantissa * 2^(-126 - 23) -- Denormalized number
                        end
                    elseif exponent == 0xFF then
                        if mantissa == 0 then
                            return sign * math.huge -- Infinity
                        else
                            return 0/0 -- NaN (Not a Number)
                        end
                    else
                        return sign * (1 + mantissa / 2^23) * 2^(exponent - 127) -- Normalized number
                    end]]

                    local int_value = cheat.process:readInt32(byte1)

                    if int_value < 0 then
                        int_value = int_value + 2^32
                    end
                    
                    -- Convert the integer to a float using string.pack/unpack
                    local packed = string.pack("<I4", int_value) -- '<' ensures little-endian order
                    local float_value = string.unpack("<f", packed)

                    return float_value
                end;

                getVisualRotation = function(self, objectClass)
                    local baseObject = cheat.process:readInt64(self.entity + 0x10);
                    if baseObject ~= 0 then
                        local gameObject = cheat.process:readInt64(baseObject + 0x30);
                        if gameObject ~= 0 then
                            local visual = cheat.process:readInt64(gameObject + 0x30);
                            if visual ~= 0 then
                                local playerVisual = cheat.process:readInt64(visual + 0x8);
                                if playerVisual ~= 0 then
                                    local visualState = cheat.process:readInt64(playerVisual + 0x38); --will return 1D748FB55A0;
                                    if visualState ~= 0 then
                                        --Input.SetClipboard(visualState)
                                        return vector4:create(
                                            self:bytesToFloat(
                                                visualState + 0xA0
                                            ),
                                            self:bytesToFloat(
                                                visualState + 0xA0 + 0x4
                                            ),
                                            self:bytesToFloat(
                                                visualState + 0xA0 + 0x8
                                            ),
                                            self:bytesToFloat(
                                                visualState + 0xA0 + 0xC
                                            )
                                        )
                                        --[[return vector4:create(
                                            self:bytesToFloat(
                                                cheat.process:readInt8(visualState + 0xA0),
                                                cheat.process:readInt8(visualState + 0xA0 + 0x1),
                                                cheat.process:readInt8(visualState + 0xA0 + 0x2),
                                                cheat.process:readInt8(visualState + 0xA0 + 0x3)
                                            ),
                                            self:bytesToFloat(
                                                cheat.process:readInt8(visualState + 0xA0 + 0x4),
                                                cheat.process:readInt8(visualState + 0xA0 + 0x5),
                                                cheat.process:readInt8(visualState + 0xA0 + 0x6),
                                                cheat.process:readInt8(visualState + 0xA0 + 0x7)
                                            ),
                                            self:bytesToFloat(
                                                cheat.process:readInt8(visualState + 0xA0 + 0x8),
                                                cheat.process:readInt8(visualState + 0xA0 + 0x9),
                                                cheat.process:readInt8(visualState + 0xA0 + 0xA),
                                                cheat.process:readInt8(visualState + 0xA0 + 0xB)
                                            ),
                                            self:bytesToFloat(
                                                cheat.process:readInt8(visualState + 0xA0 + 0xC),
                                                cheat.process:readInt8(visualState + 0xA0 + 0xD),
                                                cheat.process:readInt8(visualState + 0xA0 + 0xE),
                                                cheat.process:readInt8(visualState + 0xA0 + 0xF)
                                            )
                                        )]]
                                    end
                                end
                            end
                        end
                    end
                    return nil;
                end;
    
                getFlags = function(self)
                    return cheat.process:readInt32(self.entity + cheat.offsets.baseEntity.flags.offset);
                end;
    
                getParentEntity = function(self)
                    return cheat.class.baseEntity:create(cheat.process:readInt64(self.entity + cheat.offsets.baseEntity.addedToParentEntity.offset))
                end;
            };
        };

        gestureConfig = {
            functions = {
                setPlayerModelLayer = function(self, val)
                    return cheat.process:writeInt32(self.entity + cheat.offsets.gestureConfig.playerModelLayer.offset, val);
                end;
            },
        },

        playerModel = {
            functions = {
                getLookAngles = function(self)
                    return cheat.process:readVector4(self.entity + cheat.offsets.playerModel.lookAngles.offset);
                end;

                getNewVelocity = function(self)
                    return cheat.process:readVector3(self.entity + cheat.offsets.playerModel.newVelocity.offset);
                end; --0x1EC
    
                getIsVisible = function(self)
                    return cheat.process:readInt8(self.entity + cheat.offsets.playerModel.visible.offset) == 1;
                end;

                getIsInGesture = function(self)
                    return cheat.process:readInt8(self.entity + cheat.offsets.playerModel.inGesture.offset) == 1;
                end;

                setIsInGesture = function(self, val)
                    cheat.process:writeInt8(self.entity + cheat.offsets.playerModel.inGesture.offset, val);
                end;

                getCurrentGesture = function(self)
                    return cheat.class.gestureConfig:create(cheat.process:readInt64(self.entity + cheat.offsets.playerModel.currentGestureConfig.offset));
                end;
    
                getPosition = function(self)
                    return cheat.process:readVector3(self.entity + cheat.offsets.playerModel.position.offset); --return cheat.process:readInt8(self.entity + cheat.offsets.playerModel.isNpc.offset) == 1;
                end;
            };
        };

        baseCombatEntity = {
            inherit = {
                "baseEntity";
            };

            functions = {
                getIsDead = function(self)
                    return cheat.process:readInt32(self.entity + cheat.offsets.baseCombatEntity.lifeState.offset) == 1;
                end;
                getHealth = function(self)
                    return cheat.process:readFloat(self.entity + cheat.offsets.baseCombatEntity.health.offset);
                end;
            };
        };

        transform = {
           
        };

        nightParams = {
            functions = {
                setAmbientMultiplier = function(self, value)
                    cheat.process:writeFloat(self.entity + cheat.offsets.todNightParams.ambientMultiplier.offset, value);
                end;
    
                setLightIntensity = function(self, value)
                    cheat.process:writeFloat(self.entity + cheat.offsets.todNightParams.lightIntensity.offset, value);
                end;
            };
        };

        dayParams = {
            functions = {
                setAmbientMultiplier = function(self, value)
                    cheat.process:writeFloat(self.entity + cheat.offsets.todDayParams.ambientMultiplier.offset, value);
                end;
            };
            --[[
            functions = {

            };
            ]]
        };

        todCycleParams = {
            functions = {
                setHour = function(self, value)
                    cheat.process:writeFloat(self.entity + cheat.offsets.todCycleParameters.hour.offset, value);
                end;
            };
        };

        todSky = {
            functions = {
                getCycleParamaters = function(self)
                    return cheat.class.todCycleParams:create(cheat.process:readInt64(self.entity + cheat.offsets.todSky.cycle.offset));
                end;
    
                getNightParamaters = function(self)
                    return cheat.class.nightParams:create(cheat.process:readInt64(self.entity + cheat.offsets.todSky.nightParams.offset));
                end;
    
                getDayParamaters = function(self)
                    return cheat.class.dayParams:create(cheat.process:readInt64(self.entity + cheat.offsets.todSky.dayParams.offset));
                end;
    
                setTimeSinceAmbientUpdate = function(self, value)
                    return cheat.process:writeFloat(self.entity + cheat.offsets.todSky.timeSinceAmbientUpdate.offset, value);
                end;
            };
        };

        playerInput = {
            functions = {
                getBodyAngles = function(self)
                    return cheat.process:readVector3(self.entity + cheat.offsets.playerInput.bodyAngles.offset);
                end;
    
                setBodyAngles = function(self, vector)
                    return cheat.process:writeVector3(self.entity + cheat.offsets.playerInput.bodyAngles.offset, vector, true);
                end;

                setOffsetAngles = function(self, vector)
                    return cheat.process:writeVector3(self.entity + cheat.offsets.playerInput.offsetAngles.offset, vector, true);
                end;

                getOffsetAngles = function(self, vector)
                    return cheat.process:readVector3(self.entity + cheat.offsets.playerInput.offsetAngles.offset);
                end;
            };
        };

        playerInventory = {
            functions = {
                getClothing = function(self)
                    if not cheat.clothingOffset then
                        for i=0, 300 do
                            local randomEntity = cheat.class.baseEntity:create(cheat.process:readInt64(self.entity + i));
                            if randomEntity then
                                if std:includes(randomEntity:getClassName(), "%") then
                                    if cheat.process:readInt32(randomEntity.entity + cheat.offsets.itemContainer.capacity.offset) == 8 then
                                        cheat.clothingOffset = i;
                                        break;
                                    end
                                end
                            end
                        end
                    end

                    return cheat.class.itemContainer:create(cheat.process:readInt64(self.entity + cheat.clothingOffset));
                end;

                getBelt = function(self)
                    if not cheat.beltOffset then
                        for i=0, 300 do
                            local randomEntity = cheat.class.baseEntity:create(cheat.process:readInt64(self.entity + i));
                            if randomEntity then
                                if std:includes(randomEntity:getClassName(), "%") then
                                    if cheat.process:readInt32(randomEntity.entity + cheat.offsets.itemContainer.capacity.offset) == 6 then
                                        cheat.beltOffset = i;
                                        break;
                                    end
                                end
                            end
                        end
                    end

                    return cheat.class.itemContainer:create(cheat.process:readInt64(self.entity + cheat.beltOffset));
                end;
            };
        };

        itemContainer = {
            functions = {
                getItemList = function(self)
                    return cheat.process:readInt64(self.entity + cheat.offsets.itemContainer.itemList.offset);
                end;
            };
        };

        itemDefinition = {
            functions = {
                getDisplayName = function(self)
                    return cheat.process:readPhrase(self.entity + cheat.offsets.itemDefinition.displayName.offset );
                end;

                getShortName = function(self)
                    return cheat.process:readIl2cppString(self.entity + cheat.offsets.itemDefinition.shortName.offset );
                end;

                getCatagory = function(self)
                    return cheat.process:readInt32(self.entity + cheat.offsets.itemDefinition.catagory.offset );
                end;
    
                getItemId = function(self)
                    return cheat.process:readInt32(self.entity + cheat.offsets.itemDefinition.itemId.offset);
                end;

                getItemModProjectile = function(self)
                    return cheat.class.itemModProjectile:create(cheat:getComponent(self, "ItemModProjectile"))
                end;
            };
        };

        baseProjectileMagazine = {
            functions = {
                getAmmoType = function(self)
                    return cheat.class.itemDefinition:create(cheat.process:readInt64(self.entity + cheat.offsets.baseProjectileMagazine.ammoType.offset));
                end;
            };
        };

        recoilProperties = {
            functions = {
                getNewRecoilOverride = function(self)
                    return cheat.class.recoilProperties:create(cheat.process:readInt64(self.entity + cheat.offsets.recoilProperties.newRecoilOverride.offset));
                end;

                manageYawMin = function(self, set)
                    if set then
                        cheat.process:writeFloat(self.entity + cheat.offsets.recoilProperties.yawMin.offset, set);
                    else
                        return cheat.process:readFloat(self.entity + cheat.offsets.recoilProperties.yawMin.offset);
                    end
                end;

                manageYawMax = function(self, set)
                    if set then
                        cheat.process:writeFloat(self.entity + cheat.offsets.recoilProperties.yawMax.offset, set);
                    else
                        return cheat.process:readFloat(self.entity + cheat.offsets.recoilProperties.yawMax.offset);
                    end
                end;

                managePitchMin = function(self, set)
                    if set then
                        cheat.process:writeFloat(self.entity + cheat.offsets.recoilProperties.pitchMin.offset, set);
                    else
                        return cheat.process:readFloat(self.entity + cheat.offsets.recoilProperties.pitchMin.offset);
                    end
                end;

                managePitchMax = function(self, set)
                    if set then
                        cheat.process:writeFloat(self.entity + cheat.offsets.recoilProperties.pitchMax.offset, set);
                    else
                        return cheat.process:readFloat(self.entity + cheat.offsets.recoilProperties.pitchMax.offset);
                    end
                end;
            };
        };

        flintStrikeWeapon = {
            inherit = {
                "baseProjectile";
            };

            functions = {
                manageSuccessFraction = function(self, set)
                    if set then
                        cheat.process:writeFloat(self.entity + cheat.offsets.flintStrikeWeapon.successFraction.offset, set)
                    else
                        return cheat.process:readFloat(self.entity + cheat.offsets.flintStrikeWeapon.successFraction.offset)
                    end
                end;
            };
        };

        baseProjectile = {
            inherit = {
                "heldEntity";
            };

            functions = {
                getPredictionData = function(self)
                    local primaryMagazine = self:getPrimaryMagazine()

                    if primaryMagazine then
                        local ammoType = primaryMagazine:getAmmoType();
                        if ammoType then
                            local modProjectile = ammoType:getItemModProjectile();
                            
                            if modProjectile then
                                --log("test: ", cheat.class.baseEntity:create(modProjectile.entity):getClassName());
                                local projectile = modProjectile:getProjectile();
                                if projectile then
                                    local data = {
                                        gravityModifier = projectile:getGravityModifier();
                                        drag = projectile:getDrag();
                                        projectileVelocity = modProjectile:getProjectileVelocity();
                                        ammoType = ammoType;
                                        primaryMagazine = primaryMagazine;
                                        projectileVelocityScale = self:getProjectileVelocityScale();
                                        isGun = true;
                                    };

                                    local weaponChildren = self:getChildren();
                                    if weaponChildren ~= 0 then
                                        local listSize = cheat.class.itemList:getSize(weaponChildren);
                                        if listSize ~= 0 and 1000 > listSize then
                                            local itemL = cheat.class.itemList:getItemList(weaponChildren);
                                            if itemL ~= 0 then
                                                for i = 0, (listSize - 1) do
                                                    local child = cheat.class.projectileWeaponMod:create(cheat.process:readInt64(itemL + 0x20 + (i * 0x8)));
                                                    if child and child ~= 0 and not child:getIsDestroyed() then
                                                        if child:getClassName() == "ProjectileWeaponMod" then
                                                            local speedO = child:getProjectileVelocityModifier();
                                                            if speedO.enabled and speedO.scale ~= 0 then
                                                                data.projectileVelocity = data.projectileVelocity * speedO.scale;
                                                            end
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end

                                    return data;
                                end
                            end

                            return {isGun = true};
                        end
                    end
                    
                    return nil;
                end;

                manageAutomatic = function(self, set)
                    if set then
                        cheat.process:writeBool(self.entity + cheat.offsets.baseProjectile.automatic.offset, set)
                    else
                        return cheat.process:readBool(self.entity + cheat.offsets.baseProjectile.automatic.offset)
                    end
                end;

                getPrimaryMagazine = function(self)
                    return cheat.class.baseProjectileMagazine:create(cheat.process:readInt64(self.entity + cheat.offsets.baseProjectile.primaryMagazine.offset));
                end;

                getRecoilProperties = function(self)
                    return cheat.class.recoilProperties:create(cheat.process:readInt64(self.entity + cheat.offsets.baseProjectile.recoilProperties.offset));
                end;

                manageAimcone = function(self, set)
                    if set then
                        cheat.process:writeFloat(self.entity + cheat.offsets.baseProjectile.aimCone.offset, set)
                    else
                        return cheat.process:readFloat(self.entity + cheat.offsets.baseProjectile.aimCone.offset)
                    end
                end;

                manageHipAimcone = function(self, set)
                    if set then
                        cheat.process:writeFloat(self.entity + cheat.offsets.baseProjectile.hipAimCone.offset, set)
                    else
                        return cheat.process:readFloat(self.entity + cheat.offsets.baseProjectile.hipAimCone.offset)
                    end
                end;

                manageStancePenaltyScale = function(self, set)
                    if set then
                        cheat.process:writeFloat(self.entity + cheat.offsets.baseProjectile.stancePenaltyScale.offset, set)
                    else
                        return cheat.process:readFloat(self.entity + cheat.offsets.baseProjectile.stancePenaltyScale.offset)
                    end
                end;
                
                manageAimconePenaltyPerShot = function(self, set)
                    if set then
                        cheat.process:writeFloat(self.entity + cheat.offsets.baseProjectile.aimconePenaltyPerShot.offset, set)
                    else
                        return cheat.process:readFloat(self.entity + cheat.offsets.baseProjectile.aimconePenaltyPerShot.offset)
                    end
                end;

                getProjectileVelocityScale = function(self)
                    return cheat.process:readFloat(self.entity + cheat.offsets.baseProjectile.projectileVelocityScale.offset)
                end;
            };
        };

        heldEntity = {
            inherit = {
                "baseEntity";
            };
            
            functions = {
                getIsDeployed = function(self)
                    return cheat.process:readBool(self.entity + cheat.offsets.heldEntity.isDeployed.offset);
                end;
            };
        };

        item = {
            --[[inherit = {
                "baseEntity";
            };]]
            
            functions = {
                getData = function(self, itemDef)
                    local data = nil;

                    local itemDefinition = itemDef or self:getItemDefinition();
                    if itemDefinition then
                        data = {};

                        data.shortName = itemDefinition:getShortName() or "?";
                        if data.shortName == "" then
                            data.shortName = "?"
                        end

                        data.catagory = itemDefinition:getCatagory();
                        data.itemDefinition = itemDefinition
                    end

                    return data;
                end;

                getItemDefinition = function(self)
                    return cheat.class.itemDefinition:create(cheat.process:readInt64(self.entity + cheat.offsets.item.itemDefinition.offset));
                end;
    
                getHeldEntity = function(self)
                    local faggotfacepunchread = cheat.process:readInt64(self.entity + cheat.offsets.item.heldEntity.offset);
                    if faggotfacepunchread == 0 then
                        faggotfacepunchread = cheat.process:readInt64(self.entity + cheat.offsets.item.worldEnt.offset);
                    end

                    return cheat.class.baseProjectile:create(faggotfacepunchread);
                end;
            };
        };

        itemList = {
            getSize = function(self, this)
                return cheat.process:readInt32(this + 0x18);
            end;

            getItemList = function(self, this)
                return cheat.process:readInt64(this + 0x10);
            end;

            loopList = function(self, this, callback, size)
                local items = cheat.process:readInt64(this + 0x10);
                local listSize = size or self:getSize(this);
                local internalList = items + 0x20;

                if 10000 > listSize then
                    for i = 0, listSize do
                        local item = cheat.process:readInt64(internalList + (i * 0x8));
                        if item ~= 0 then
                            callback(item);
                        end
                    end
                end
            end;
        };

        lootableCorpse = {
            inherit = {
                "baseCombatEntity";
            };

            functions = {
                getPlayerName = function(self)
                    return cheat.process:readIl2cppString(self.entity + cheat.offsets.lootableCorpse.playerName.offset) or "?";
                end;
            };
        };

        droppedItemContainer = {
            inherit = {
                "baseCombatEntity";
            };

            functions = {
                getPlayerName = function(self)
                    return cheat.process:readIl2cppString(self.entity + cheat.offsets.droppedItemContainer.playerName.offset ) or "?";
                end;
            };
        };

        playerEyes = {
            functions = {
                setBodyRotation = function(self, value)
                    cheat.process:writeVector4(self.entity + cheat.offsets.playerEyes.bodyRotation.offset, value);
                end;

                getBodyRotation = function(self)
                    return cheat.process:readVector4(self.entity + cheat.offsets.playerEyes.bodyRotation.offset);
                end;
            };
        };

        baseMovement = {
            inherit = {
                "playerWalkMovement";
            };

            functions = {
                setTargetMovement = function(self, value)
                    cheat.process:writeVector3(self.entity + cheat.offsets.baseMovement.targetMovement.offset, value);
                end;
    
                getTargetMovement = function(self)
                    return cheat.process:readVector3(self.entity + cheat.offsets.baseMovement.targetMovement.offset);
                end;
            };
        };

        worldItem = {
            inherit = {
                "baseEntity";
            };
            
            functions = {
                getItem = function(self)
                    return cheat.class.item:create(cheat.process:readInt64(self.entity + cheat.offsets.worldItem.item.offset));
                end;
            };
        };

        modelState = {
            functions = {
                getFlags = function(self)
                    return cheat.process:readInt32(self.entity + cheat.offsets.modelState.flags.offset);
                end;
    
                addFlag = function(self, flag, passedFlags)
                    local currentFlags = passedFlags or self:getFlags(self.entity);
                    local newFlags = currentFlags | flag;
                    cheat.process:writeInt32(self.entity + cheat.offsets.modelState.flags.offset, newFlags);
                end;
            };
        };

        
        autoTurret = {
            inherit = {
                "ioEntity";
            };

            functions = {

            }
        };


        getDict = function(self, callback)
            local wrapper = cheat.process:readInt64(self.entity)
            if wrapper ~= 0 then
                local parentClass = cheat.process:readInt64(wrapper + 0x58)
                if parentClass ~= 0 then
                    local parentStaticClass = cheat.process:readInt64(parentClass + 0xB8)
                    if parentStaticClass ~= 0 then
                        if callback then
                            if parentStaticClass ~= nil and parentStaticClass ~= 0 then
                                local objectDictionary = cheat.process:readInt64(parentStaticClass + 0x0);
                                if objectDictionary ~= 0 then
                                    local objectValues = cheat.process:readInt64(objectDictionary + 0x18);
                                    if objectValues == 0 then
                                        return parentStaticClass;
                                    end
                                    
                                    local size = cheat.process:readInt32(objectDictionary + 0x20);
                                    if 1000000 > size then
                                        for i = 0, size do
                                            local currentObject = cheat.process:readInt64(objectValues + 0x20 + (i * 8))
                                            if currentObject ~= 0 then
                                                local continueLoop = callback(currentObject, i, size)
                                                if continueLoop == true then
                                                    break
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                            
                                --callback(parentStaticClass, i)
                        end
                        return parentStaticClass
                    end
                end
            end
            return nil
        end;

        playerTeam = {
            inherit = {
            };

            functions = {
                getTeamLeader = function(self)
                    if not cheat.class.playerTeam.teamLeaderOffset then
                        local prefix = "765611";

                        for i = 0, 1000 do
                            local steamidRead = cheat.process:readInt64(self.entity + i);
                            local toString = tostring(steamidRead);
                            if string.sub(toString, 1, #prefix) == prefix then      
                                cheat.class.playerTeam.teamLeaderOffset = i;                             
                                break;
                            end
                        end
                    end

                    if cheat.class.playerTeam.teamLeaderOffset then
                        return cheat.process:readInt64(self.entity + cheat.class.playerTeam.teamLeaderOffset);
                    end

                    return 0;
                end;
            }
        };

        basePlayer = {
            inherit = {
                "baseCombatEntity";
            };

            functions = {
                getMounted = function(self)
                    return cheat.class.baseEntity:create(cheat.process:readInt64(self.entity + cheat.offsets.basePlayer.mounted.offset));
                end;
    
                getModelState = function(self)
                    return cheat.class.modelState:create(cheat.process:readInt64(self.entity + cheat.offsets.basePlayer.modelState.offset));
                end;
    
                getBaseMovement = function(self)
                    return cheat.class.baseMovement:create(cheat.process:readInt64(self.entity + cheat.offsets.basePlayer.baseMovement.offset));
                end;
    
                getUserIdString = function(self)
                    return cheat.process:readIl2cppString(self.entity + cheat.offsets.basePlayer.userIdString.offset)
                end;
    
                getPlayerEyes = function(self)
                    local playerEyes = cheat.process:readInt64(self.entity + cheat.offsets.basePlayer.playerEyes.offset);

                    if playerEyes ~= 0 then
                        local playerEyeAddress = 0;
                        cheat.class:getDict(playerEyes,function(object, iteration, size)
                            if object:getClassName() == "PlayerEyes" then
                                local basePlayer = cheat.process:readInt64(object + 0x20);
                                if basePlayer == self.entity then
                                    playerEyeAddress = object;
                                    return true;
                                end
                            end
                            
                            return false
                        end)
    
                        if playerEyeAddress ~= 0 then
                            return cheat.class.playerEyes:create(playerEyeAddress);
                        end
                    end
    
                    return nil;
                end;

                getBoxBounds = function(self, headPos)
                    if not self.position then
                        return nil;
                    end
        
                    local basePosition = self.position;
                    local headPosition = headPos or vector3:create(self.position.x, self.position.y + 1.55, self.position.z);
        
                    local baseOnScreen = cheat:worldToScreen(basePosition);
                    local headOnScreen = cheat:worldToScreen(headPosition);
        
                    if baseOnScreen and headOnScreen then
                        local flBoxHeight = math.abs(headOnScreen.y - baseOnScreen.y);
                        local flBoxWidth = flBoxHeight * 0.70;
                        local vecMin = vector3:create(headOnScreen.x - (flBoxWidth * 0.5), headOnScreen.y - (flBoxHeight * 0.15))
                        local vecMax = vector3:create(vecMin.x + flBoxWidth, vecMin.y + flBoxHeight * 1.3);
                        local vecBoundingBoxSize = vecMax:subtract(vecMin);
        
            
                        local returnValue = {
                            left = vecMin.x;
                            right = vecMin.x + vecBoundingBoxSize.x;
                            top = vecMin.y;
                            bottom = vecMin.y + vecBoundingBoxSize.y;
                        };
        
                        return returnValue;
                    end
        
                    return nil;
                end;
    
                getHeldItem = function(self, heldItemId, ignoreFail, deepSearch)
                    if self.playerInventory and self.playerInventory ~= 0 then
                        local belt = self.playerInventory:getBelt();
                        if belt then
                            local itemList = belt:getItemList();
                            if itemList and itemList ~= 0 then
                                local items = cheat.class.itemList:getItemList(itemList);
                                local listSize = cheat.class.itemList:getSize(itemList);
                                if listSize ~= 0 then
                                    if 8 > listSize then
                                        for i = 0, (listSize - 1) do
                                            local item = cheat.class.item:create(cheat.process:readInt64(items + 0x20 + (i * 0x8)));
                                            if item then
                                                local heldEntity = item:getHeldEntity();
                                                if heldEntity then
                                                    if cheat.class:hasFlag(heldEntity:getFlags(), 1024) then
                                                        return {
                                                            heldEntity = heldEntity;
                                                            item = item;
                                                        };
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end



                    --[[local currentItemId = heldItemId or self:getActiveItem();
    
                    local playerInventory = nil--self.inventory;
                    if playerInventory and playerInventory ~= 0 then
                        local belt = playerInventory:getBelt();
                        if belt ~= 0 then
                            local itemList = belt:getItemList();
                            if itemList and itemList ~= 0 then
                                local items = cheat.process:readInt64(itemList + 0x10);
                                local listSize = itemList:getSize();
                                if listSize ~= 0 then
                                    if 100 > listSize then
                                        for i = 0, (listSize - 1) do
                                            local item = cheat.process:readInt64(items + 0x20 + (i * 0x8));
                                            if item ~= 0 then
                                                local weaponUid = item:getItemUid();
                                                if currentItemId == weaponUid then
                                                    return cheat.class.item:create(item), false;
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    else
                        local children = self:getChildren();
                        local failReturn = nil;

                        if children ~= 0 then
                            local listSize = cheat.class.itemList:getSize(children);
                            if listSize ~= 0 then
                                local itemL = cheat.class.itemList:getItemList(children);
                                if itemL ~= 0 then
                                    local alertString = "";
                                    for i = 0, (listSize - 1) do
                                        local child = cheat.class.baseProjectile:create(cheat.process:readInt64(itemL + 0x20 + (i * 0x8)));
                                        if child and child ~= 0 and not child:getIsDestroyed() then
                                            local weaponUid = cheat.process:readInt64(child.entity + cheat.offsets.heldItem.ownerItemUid.offset);

                                            if cheat.structs.guns[child:getPrefabUid()] and not ignoreFail then
                                                failReturn = child;
                                            end

                                            if currentItemId == weaponUid then
                                                return child, true;
                                            end
                                        end
                                    end
                                end
                            end
                        end

                        return failReturn, true
                    end]]

                    --[[local children = self:getChildren();
                    local failReturn = nil;

                    if children ~= 0 then
                        local listSize = cheat.class.itemList:getSize(children);
                        if listSize ~= 0 then
                            local itemL = cheat.class.itemList:getItemList(children);
                            if itemL ~= 0 then
                                local alertString = "";
                                for i = 0, (listSize - 1) do
                                    local child = cheat.class.baseProjectile:create(cheat.process:readInt64(itemL + 0x20 + (i * 0x8)));
                                    if child and child ~= 0 and not child:getIsDestroyed() then
                                        if cheat.structs.guns[child:getPrefabUid()] and not ignoreFail then
                                            failReturn = child;
                                        end

                                        if cheat.class:hasFlag(child:getFlags(), 1024) then
                                            if deepSearch then
                                                if self.playerInventory then
                                                    self.playerBelt = self.playerInventory:getBelt();

                                                    if self.playerBelt then
                                                        local s = self.playerBelt:getItemList();
                                                        if s and s ~= 0 then
                                                            local items = cheat.process:readInt64(s + 0x10);
                                                            local listSize = cheat.process:readInt32(s + 0x18)
                                                            if listSize ~= 0 then
                                                                if 100 > listSize then
                                                                    for i = 0, (listSize - 1) do
                                                                        local item = cheat.class.item:create(cheat.process:readInt64(items + 0x20 + (i * 0x8)));
                                                                        if item then
                                                                            local heldEntity = item:getHeldEntity();
                                                                            if heldEntity then
                                                                                if heldEntity.entity == child.entity then
                                                                                    return child, item
                                                                                end
                                                                            end
                                                                        end
                                                                    end
                                                                end
                                                            end
                                                        end
                                                    end
                                                end
                                            end

                                            return child;
                                        end

                                        --if child:getIsDeployed() then
                                        --    return child, true;
                                        --end
                                    end
                                end
                            end
                        end

                        return failReturn;
                    end]]
    
                    return nil;
                end;
    
                getActiveItem = function(self)
                    return cheat.process:readInt64(self.entity + cheat.offsets.basePlayer.clActiveItem.offset);--cheat.decryption:decryptUlong(cheat.process:readInt64(self.entity + cheat.offsets.basePlayer.clActiveItem.offset));
                end;

                getPlayerTeam = function(self)
                    return cheat.class.playerTeam:create(cheat.process:readInt64(self.entity + cheat.offsets.basePlayer.clientTeam.offset));
                end;
    
                getTeamId = function(self)
                    return cheat.process:readInt32(self.entity + cheat.offsets.basePlayer.currentTeam.offset);
                end;
    
                getPlayerModel = function(self)
                    return cheat.class.playerModel:create(cheat.process:readInt64(self.entity + cheat.offsets.basePlayer.playerModel.offset));
                end;
    
                getName = function(self)
                    return cheat.process:readIl2cppString(self.entity + cheat.offsets.basePlayer._displayName.offset );
                end;
    
                getPlayerFlags = function(self)
                    return cheat.process:readInt32(self.entity + cheat.offsets.basePlayer.playerFlags.offset);
                end;
    
                addPlayerFlag = function(self, flag)
                    local currentFlags = self:getPlayerFlags(self.entity);
                    local newFlags = currentFlags | flag;
                    cheat.process:writeInt32(self.entity + cheat.offsets.basePlayer.playerFlags.offset, newFlags);
                end;
    
                removePlayerFlag = function(self, flag)
                    local currentFlags = self:getPlayerFlags(self.entity);
                    local newFlags = currentFlags & ~flag
                    cheat.process:writeInt32(self.entity + cheat.offsets.basePlayer.playerFlags.offset, newFlags);
                end;
    
                getPlayerInput = function(self)
                    return cheat.class.playerInput:create(cheat.process:readInt64(self.entity + cheat.offsets.basePlayer.playerInput.offset));
                end;




                getBoneTransform = function(self, boneId)
                    local model = cheat.process:readInt64(self.entity + cheat.offsets.basePlayer.model.offset);
                    if model ~= 0 then
                        local transform = cheat.process:readInt64(model + 0x50);
                        if transform ~= 0 then
                            local bones = cheat.process:readInt64(transform + ( 0x20 + ( ( boneId ) * 0x8 ) ));
                            if bones ~= 0 then
                                local bone = cheat.process:readInt64(bones + 0x10);
                                if bone ~= 0 then
                                    return bone;
                                end
                            end
                        end
                    end

                    return nil;
                end;

                updateBoneTransform = function(self, boneId)
                    if not self.cachedBoneTransforms then
                        self.cachedBoneTransforms = {};
                    end

                    self.cachedBoneTransforms[boneId] = self:getBoneTransform(boneId);
                end;
    
                getBonePosition = function(self, boneId)
                    if not self.bonePositions then
                        self.bonePositions = {};
                    end

                    if self.bonePositions[boneId] then
                        return self.bonePositions[boneId];
                    end

                    if boneId == cheat.structs.bones.fixedHead then
                        local headPos = self:getBonePosition(cheat.structs.bones.eyeTransform)
                        local neckPos = self:getBonePosition(cheat.structs.bones.head)

                        if headPos and neckPos then
                            return headPos:findMiddle(neckPos)
                        end

                        return neckPos or headPos or nil;
                    end

                    if not self.cachedBoneTransforms then
                        self.cachedBoneTransforms = {};
                    end

                    if not self.cachedBoneTransforms[boneId] then
                        self.cachedBoneTransforms[boneId] = self:getBoneTransform(boneId);
                    end

                    local alreadyRetried = false;
                    ::retryRead::
                    local boneTransformPointer = self.cachedBoneTransforms[boneId];

                    if boneTransformPointer and boneTransformPointer ~= 0 then
                        local bonePosition = cheat.process:readTransformPosition(boneTransformPointer);
                        if bonePosition and bonePosition:isValid() then
                            self.bonePositions[boneId] = bonePosition;
                            return bonePosition;
                        else
                            if not alreadyRetried then
                                alreadyRetried = true;
                                self.cachedBoneTransforms[boneId] = self:getBoneTransform(boneId);
                                goto retryRead;
                            end
                        end
                    end
    
                    --[[local model = cheat.process:readInt64(self.entity + cheat.offsets.basePlayer.model.offset);
                    if model ~= 0 then
                        local transform = cheat.process:readInt64(model + 0x50);
                        if transform ~= 0 then
                            local bones = cheat.process:readInt64(transform + ( 0x20 + ( ( boneId ) * 0x8 ) ));
                            if bones ~= 0 then
                                local bone = cheat.process:readInt64(bones + 0x10);
                                if bone ~= 0 then
                                    local vector = cheat.process:readTransformPosition(bone)
                                    self.bones[boneId] = vector;
                                    return vector
                                end
                            end
                        end
                    end]]
    
                    return nil;
                end;
            };
        };

        split = function(self, str, delimiter)
            local result = {}
            for match in (str..delimiter):gmatch("(.-)"..delimiter) do
                table.insert(result, match)
            end
            return result
        end;
        
        -- Function to merge two tables
        mergeTables = function(self, t1, t2)
            for k, v in pairs(t2) do
                if type(v) == "table" and type(t1[k] or false) == "table" then
                    self:mergeTables(t1[k], v)
                else
                    t1[k] = v
                end
            end
        end;

        getFunctionsAndInherit = function(self, currentTable)
            local returnTable = {}

            -- Add currentTable's functions to returnTable
            if currentTable.functions then
                setmetatable(returnTable, {
                    __index = currentTable.functions
                })
            end

            -- Set metatable only once at the end
         

            return returnTable;
        end;

        setupInheritanceFunctions = function(self, currentClass, fromInheritance, baseClass)
            if currentClass.functions then
                if currentClass.inherit then
                    for i = 1, #currentClass.inherit do
                        local currentInherit = currentClass.inherit[i]
                        if currentInherit then
                            local paths = cheat.class:split(currentInherit, ":")
                            if paths[1] then
                                local inheritTable = cheat.class
                                for d = 1, #paths do
                                    if inheritTable then
                                        inheritTable = inheritTable[paths[d]]
                                    end
                                end
        
                                if inheritTable and inheritTable.functions then
                                    self:setupInheritanceFunctions(inheritTable, true, baseClass or currentClass)
                                end
                            end
                        end
                    end
                end
        
                if fromInheritance and baseClass then
                    for key, value in pairs(currentClass.functions) do
                        if type(value) == "function" then
                            baseClass.functions[key] = value
                            --if key == "getGameObjectTransform" then
                            --    log('YEAH?')
                            --end
                            --log('set children?')
                        end
                    end
                end
            end
        end;

        setupClasses = function(self, currentClass)
           -- self:setupInheritanceFunctions()

            for className, classData in pairs(currentClass or cheat.class) do
                if classData and type(classData) == "table" then
                    if classData.functions then
                        self:setupInheritanceFunctions(classData)
                        local function create(self, instanceId)
                            if not instanceId or instanceId == 0 then
                                return nil;
                            end

                            local functionInstance = cheat.class:getFunctionsAndInherit(classData)
                            functionInstance.entity = instanceId;
                            functionInstance.class = className;

                            return functionInstance;
                        end

                        classData.create = create
                    else
                        self:setupClasses(classData);
                    end
                end
            end
        end;
    };

    structs = {
        bones = {
            fixedHead = 1000;
            head = 47; --still basically neck
            lowerNeck = 46;
            middleChest = 20; -- 89
            pelvis = 0;
            rightHip = 13;
            leftHip = 1;
            rightKnee = 14;
            leftKnee = 2;
            rightAnkle = 15; -- 19
            leftAnkle = 5;
            rightFoot = 16;
            leftFoot = 4;
            rightShoulder = 55;
            leftShoulder = 24;
            rightElbow = 56;
            leftElbow = 25;
            rightWrist = 75;
            leftWrist = 26;
            eyeTransform = 49,

            --[[
                    pelvis = 0,
            l_hip = 1,
            l_knee = 2,
            l_foot = 3,
            l_toe = 4,
            l_ankle_scale = 5,
            penis = 6,
            genitalCensor = 7,
            genitalCensorLOD0 = 8,
            innerLOD0_9 = 9,
            innerLOD0_10 = 10,
            genitalCensorLOD1 = 11,
            genitalCensorLOD2 = 12,
            r_hip = 13,
            r_knee = 14,
            r_foot = 15,
            r_toe = 16,
            r_ankle_scale = 17,
            spine1 = 18,
            spine1_scale = 19,
            spine2 = 20,
            spine3 = 21,
            spine4 = 22,
            l_clavicle = 23,
            l_upperarm = 24,
            l_forearm = 25,
            l_hand = 26,
            l_index1 = 27,
            l_index2 = 28,
            l_index3 = 29,
            l_little1 = 30,
            l_little2 = 31,
            l_little3 = 32,
            l_middle1 = 33,
            l_middle2 = 34,
            l_middle3 = 35,
            l_prop = 36,
            l_ring1 = 37,
            l_ring2 = 38,
            l_ring3 = 39,
            l_thumb1 = 40,
            l_thumb2 = 41,
            l_thumb3 = 42,
            IKtarget_righthand_min = 43,
            IKtarget_righthand_max = 44,
            l_ulna = 45,
            neck = 46,
            head = 47,
            jaw = 48,
            eyeTransform = 49,
            l_eye = 50,
            l_eyeLid = 51,
            r_eye = 52,
            r_eyeLid = 53,
            r_clavicle = 54,
            r_upperarm = 55,
            r_forearm = 56,
            r_hand = 57,
            r_index1 = 58,
            r_index2 = 59,
            r_index3 = 60,
            r_little1 = 61,
            r_little2 = 62,
            r_little3 = 63,
            r_middle1 = 64,
            r_middle2 = 65,
            r_middle3 = 66,
            r_prop = 67,
            r_ring1 = 68,
            r_ring2 = 69,
            r_ring3 = 70,
            r_thumb1 = 71,
            r_thumb2 = 72,
            r_thumb3 = 73,
            IKtarget_lefthand_min = 74,
            IKtarget_lefthand_max = 75,
            r_ulna = 76,
            l_breast = 77,
            r_breast = 78,
            boobCensor = 79,
            breastCensorLOD0 = 80,
            innerLOD0_81 = 81,
            innerLOD0_82 = 82,
            breastCensorLOD1 = 83,
            breastCensorLOD2 = 84
            ]]
        };

        playerFlags = {
            isAdmin = 4,
            aiming = 16384,
            chatMute = 4096,
            connected = 256,
            displaySash = 32768,
            eyesViewmode = 2048,
            incapacitated = 524288,
            isDeveloper = 128,
            isInTutorial = 134217728,
            loadingAfterTransfer = 33554432,
            modifyClan = 16777216,
            noRespawnZone = 67108864,
            noSprint = 8192,
            receivingSnapshot = 8,
            relaxed = 65536,
            safeZone = 131072,
            serverFall = 262144,
            sleeping = 16,
            spectating = 32,
            thirdPersonViewmode = 1024,
            unused1 = 1,
            unused2 = 2,
            voiceRangeBoost = 8388608,
            workbench1 = 1048576,
            workbench2 = 2097152,
            workbench3 = 4194304,
            wounded = 64
        };

        entityFlags = {
            placeholder = 1,
            on = 2,
            onFire = 4,
            open = 8,
            locked = 16,
            debugging = 32,
            disabled = 64,
            reserved1 = 128,
            reserved2 = 256,
            reserved3 = 512,
            reserved4 = 1024,
            reserved5 = 2048,
            broken = 4096,
            busy = 8192,
            reserved6 = 16384,
            reserved7 = 32768,
            reserved8 = 65536,
            reserved9 = 131072,
            reserved10 = 262144,
            reserved11 = 524288,
            inUse = 1048576,
            reserved12 = 2097152,
            reserved13 = 4194304,
            unused23 = 8388608,
            protected = 16777216,
            transferring = 33554432
        };

        modelStateFlags = {
            ducked = 1,
            jumped = 2,
            onGround = 4,
            sleeping = 8,
            sprinting = 16,
            onLadder = 32,
            flying = 64,
            aiming = 128,
            prone = 256,
            mounted = 512,
            relaxed = 1024,
            onPhone = 2048,
            crawling = 4096,
            loading = 8192,
            headLook = 16384,
            hasParachute = 32768
        };
    };

    decryption = {
        TEST_BITD = function(self, Value, BitPosition)
            return (Value & (1 << BitPosition)) ~= 0
        end;

        il2cppGetHandle = function(self, ObjectHandleID)
            if not ObjectHandleID or ObjectHandleID == 0 then
                return 0;
            end

            local il2cpp_gchandle_base = cheat.offsets.gchandle.il2cpp.offset;--0xA52E2B0;--0x6179FA0;

            local rdi_1 = ObjectHandleID >> 3
            local rcx_1 = (ObjectHandleID % 8) - 1

            --log("if check 1 1: ", cheat.process:readInt32((rcx_1 * 0x28) + (cheat.process.modules.gameAssembly.base + il2cpp_gchandle_base + 0x10)))
            --log("if check 1 2: ", self:TEST_BITD(cheat.process:readInt32(cheat.process:readInt64(cheat.process.modules.gameAssembly.base + il2cpp_gchandle_base + (rcx_1 * 0x28)) + (((rdi_1) >> 5) << 2))), (rdi_1 & 0x1f))

            
            if (rdi_1 < cheat.process:readInt32((rcx_1 * 0x28) + (cheat.process.modules.gameAssembly.base + il2cpp_gchandle_base + 0x10)) and self:TEST_BITD(cheat.process:readInt32(cheat.process:readInt64(cheat.process.modules.gameAssembly.base + il2cpp_gchandle_base + (rcx_1 * 0x28)) + (((rdi_1) >> 5) << 2)), (rdi_1 & 0x1f))) then
                local ObjectArray = cheat.process:readInt64((rcx_1 * 0x28) + (cheat.process.modules.gameAssembly.base + il2cpp_gchandle_base + 0x8)) + (rdi_1 << 3);
                if (cheat.process:readInt8((rcx_1 * 0x28) + (cheat.process.modules.gameAssembly.base + il2cpp_gchandle_base + 0x14)) > 1) then
                    return cheat.process:readInt64(ObjectArray);
                else
                    local eax = cheat.process:readInt32(ObjectArray);;
                    eax = ~eax
                    return eax;
                end
            end



            return 0
        end;
    };

    aimbot = {
        targetPlayer = nil;
        weaponCatagory = 0;

        targetSwitchDelay = 0;
        consistentTargeting = false;
        alwaysKeepTargetRegardlessOfFov = false;
        fov = 0;
        active = false;
        altActive = false;
        visibleActive = false;

        lastSwitchTime = 0;
        lastTargetFail = 0;
        lastUpdatedTargetFail = 0;

        lastSentRotationUpdate = vector3:create();
        rotationUpdateSent = false;

        angleDifference = function(self, currentAngles, targetAngles)
            local yawDifference = targetAngles.x - currentAngles.x
            local pitchDifference = targetAngles.y - currentAngles.y
        
            -- Ensure the angle differences are within the range of -180 to 180 degrees
            while yawDifference > 180.0 do
                yawDifference = yawDifference - 360.0
            end
        
            while yawDifference < -180.0 do
                yawDifference = yawDifference + 360.0
            end
        
            while pitchDifference > 180.0 do
                pitchDifference = pitchDifference - 360.0
            end
        
            while pitchDifference < -180.0 do
                pitchDifference = pitchDifference + 360.0
            end
        
            return math.sqrt(yawDifference * yawDifference + pitchDifference * pitchDifference)
        end;

        CAngle = function(self, a, b)
            local diff = (b - a + 180.0) % 360.0 - 180.0
            return (diff < -180.0) and (diff + 360.0) or diff
        end;
        
        LerpAngle = function(self, a, b, t)
            local delta = b - a
            if delta > 180.0 then
                b = b - 360.0
            elseif delta < -180.0 then
                b = b + 360.0
            end
            return a + t * (b - a)
        end;
        
        SmoothInterpolate = function(self, startAngles, targetAngles, smoothing)
            smoothing = math.max(0.0, math.min(smoothing, 100.0))
            local t = smoothing / 100.0
            local angleDifferenceX = self:CAngle(startAngles.x, targetAngles.x)
            local angleDifferenceY = self:CAngle(startAngles.y, targetAngles.y)
            local minStep = 0.1
            if math.abs(angleDifferenceX) < minStep and angleDifferenceX ~= 0 then
                angleDifferenceX = (angleDifferenceX > 0) and minStep or -minStep
            end
            if math.abs(angleDifferenceY) < minStep and angleDifferenceY ~= 0 then
                angleDifferenceY = (angleDifferenceY > 0) and minStep or -minStep
            end
        
            local interpolatedAngles = vector2:new();
            interpolatedAngles.x = self:LerpAngle(startAngles.x, startAngles.x + angleDifferenceX, t)
            interpolatedAngles.y = self:LerpAngle(startAngles.y, startAngles.y + angleDifferenceY, t)
        
            return interpolatedAngles
        end;

        Length = function(self, vec)
            return math.sqrt(vec.x * vec.x + vec.y * vec.y + vec.z * vec.z)
        end;

        RAD2DEG = function(self, radians)
            return radians * (180 / math.pi)
        end;

        calculateAngle = function(self, Src, Dst, rotation)
            local direction = Src:subtract(Dst)
            local length = self:Length(direction)
            return vector3:create(self:RAD2DEG(math.asin(direction.y / length)), self:RAD2DEG(-number:atan2(direction.x, -direction.z)) - (rotation and rotation.y or 0));
        end;

        meetsRequirements = function(self, player)
            if (not player.isKnocked or draw.cachedUiVars.aimbot.targetKnocked.value.state) and not player.isDying and not player:getIsDestroyed() and not player.isSleeping and player.model then
                if not player.isTeammate or draw.cachedUiVars.aimbot.targetTeammates.value.state then
                    if player.isVisible or not self.visibleActive then
                        return true;
                    end
                end
            end

            return false;
        end;

        calculateFov = function(self, worldPosition)
            local screenPosition = cheat:worldToScreen(worldPosition)
            if screenPosition then
                local current_delta = {
                    x = screenPosition.x - draw.screenCenter.x,
                    y = screenPosition.y - draw.screenCenter.y
                }

                local screen_radius = math.min(draw.screenCenter.x, draw.screenCenter.y)

                local normalized_delta_x = current_delta.x / screen_radius
                local normalized_delta_y = current_delta.y / screen_radius

                local fov = math.sqrt(normalized_delta_x^2 + normalized_delta_y^2) * 90.0

                return fov;
            end

            return 999999;
        end;

        isInFov = function(self, player)
            local bonePositions = {
                player:getBonePosition(cheat.structs.bones.eyeTransform);
                player:getBonePosition(cheat.structs.bones.pelvis);
            }

            for _, bonePosition in ipairs(bonePositions) do
                if bonePosition and bonePosition:isValid() then
                    local fov = self:calculateFov(bonePosition);
    
                    if (fov) < self.fov then
                        return true, fov;
                    end
                end
            end

            return false, 0;
        end;

        getNearestHitbox = function(self, player, localAngles, parentRotation)
            local targetBones = {cheat.structs.bones.fixedHead, cheat.structs.bones.lowerNeck, cheat.structs.bones.middleChest, cheat.structs.bones.pelvis}
            local shouldModifyPitch = true
            local bestYawPitch = nil
            local lowestPitch = 10000;
            local highestPitch = -10000;
            
            
            for i = 1, #targetBones - 1 do
                local startBone = player:getBonePosition(targetBones[i])--apex.classes.uBoneArray:getBonePosition(player.uBoneArray, player.position, apex.structs:getBoneId(player, targetBones[i]))--player.bonePositions[targetBones[i]]
                local endBone = player:getBonePosition(targetBones[i + 1])--apex.classes.uBoneArray:getBonePosition(player.uBoneArray, player.position, apex.structs:getBoneId(player, targetBones[i + 1])) -- player.bonePositions[targetBones[i + 1]]

                local startAngle = self:normalizeVector(self:calculateAngle(cheat.client.cameraPosition, self:predictPosition(player, startBone)))
                local endAngle = self:normalizeVector(self:calculateAngle(cheat.client.cameraPosition, self:predictPosition(player, endBone)))
                
                lowestPitch = math.min(lowestPitch, startAngle.x, endAngle.x)
                highestPitch = math.max(highestPitch, startAngle.x, endAngle.x)

                local directionStartToEnd = {x = endAngle.x - startAngle.x, y = endAngle.y - startAngle.y}
                local directionStartToEye = {x = localAngles.x - startAngle.x, y = localAngles.y - startAngle.y}
        
                local dotProduct = directionStartToEnd.x * directionStartToEye.x + directionStartToEnd.y * directionStartToEye.y
                local startToEyeDistSquared = (localAngles.x - startAngle.x)^2 + (localAngles.y - startAngle.y)^2
        
                local nearestPoint
                if dotProduct <= 0 then
                    nearestPoint = startAngle
                elseif dotProduct >= (directionStartToEnd.x^2 + directionStartToEnd.y^2) then
                    nearestPoint = endAngle
                else
                    local projection = vector2:create(
                        startAngle.x + (directionStartToEnd.x * (dotProduct / (directionStartToEnd.x^2 + directionStartToEnd.y^2))),
                        startAngle.y + (directionStartToEnd.y * (dotProduct / (directionStartToEnd.x^2 + directionStartToEnd.y^2)))
                )
        
                    local projectionToEyeDistSquared = (localAngles.x - projection.x)^2 + (localAngles.y - projection.y)^2
        
                    if projectionToEyeDistSquared <= startToEyeDistSquared then
                        nearestPoint = projection
                    else
                        nearestPoint = startAngle
                    end
                end
        
                if bestYawPitch == nil or ((nearestPoint.x - localAngles.x)^2 + (nearestPoint.y - localAngles.y)^2) < ((bestYawPitch.x - localAngles.x)^2 + (bestYawPitch.y - localAngles.y)^2) then
                    bestYawPitch = nearestPoint
                end
            end

            if localAngles.x >= lowestPitch and localAngles.x <= highestPitch then
                shouldModifyPitch = false;
            end
        
            return bestYawPitch, shouldModifyPitch
        end;

        updatePlayer = function(self, player, fovCheck)
            local foundIndex = cheat.entitylist.players[player];
            if foundIndex then
                if self:meetsRequirements(foundIndex) then
                    
                    if fovCheck then
                        if not self:isInFov(foundIndex) then
                            return false;
                        end
                    end

                    return true;
                end
            end
            return false;
        end;

        getBestTarget = function(self)
            local failCount = 0
            local ignoreTargets = {}
        
            local bestTarget = nil
            local bestDistance = 10000.0
        
            ::repeatCode::
        
            bestTarget = nil
            bestDistance = 10000.0
        
            for id, player in pairs(cheat.entitylist.players) do
                if not ignoreTargets[id] then
                    if not player.isTeammate and not player.isDying and player.onScreen then
                        local pelvisPos = player:getBonePosition(cheat.structs.bones.pelvis)
                        if pelvisPos and pelvisPos:isValid() then
                            local screenPos = cheat:worldToScreen(pelvisPos)
                            if screenPos then
                                local distance = math.sqrt((screenPos.x - draw.screenCenter.x)^2 + (screenPos.y - draw.screenCenter.y)^2)
                                if distance < bestDistance then
                                    bestDistance = distance
                                    bestTarget = player
                                end
                            end
                        end
                    end
                end
            end
        
            if bestTarget then
                if self:meetsRequirements(bestTarget) then
                    local inFov, fovDifference = self:isInFov(bestTarget)
                    if inFov and fovDifference < self.fov then
                        ignoreTargets = {};
                        return bestTarget.entity--copyTable(bestTarget);
                    end
                end
        
                ignoreTargets[bestTarget.entity] = true
                failCount = failCount + 1
        
                if failCount < 6 then
                    goto repeatCode
                end
            end
        
            ignoreTargets = {}
            return nil
        end;

        predictPosition = function(self, player, startPosition)
            if self.prediction then
                --self.targetPlayer.model = self.targetPlayer.model or self.targetPlayer.model:getPlayerModel()
                self.targetVelocity = player.model:getNewVelocity();
    
                if cheat.client.localplayer.heldEntity.heldEntity.predictionData and cheat.client.localplayer.heldEntity.heldEntity.predictionData.projectileVelocityScale then
                    local velocityScaleModifier = 1.0
                    local velocityScale = cheat.client.localplayer.heldEntity.heldEntity.predictionData.projectileVelocityScale

                    local bulletSpeed = cheat.client.localplayer.heldEntity.heldEntity.predictionData.projectileVelocity * (velocityScale * velocityScaleModifier)
                    local gravity = 9.81 * cheat.client.localplayer.heldEntity.heldEntity.predictionData.gravityModifier
                    local drag = cheat.client.localplayer.heldEntity.heldEntity.predictionData.drag

                    local distance = cheat.client.cameraPosition:unityDistance(startPosition)

                    local bulletTime = distance / bulletSpeed

                    local PredictVel = vector3.new(
                        self.targetVelocity.x * bulletTime * 0.75,
                        self.targetVelocity.y * bulletTime * 0.75,
                        self.targetVelocity.z * bulletTime * 0.75
                    )

                    startPosition = startPosition:add(PredictVel);

                    local time = (bulletTime / math.abs(bulletSpeed))
                    local bulletDrop = 0.5 * gravity * time * time

                    -- Edge case for very small distance
                    if distance < 0.001 then
                        bulletDrop = -1.0
                    end

                    local timeStep = 0.015625
                    local yTravelled = 0.0
                    local ySpeed = 0.0
                    local bulletTravelTime = 0.0

                    local distanceToTravel = 0
                    local totalDistance = cheat.client.cameraPosition:subtract(startPosition):magnitude()

                    while distanceToTravel < totalDistance do
                        local speedModifier = 1.0 - timeStep * drag
                        bulletSpeed = bulletSpeed * speedModifier

                        if bulletSpeed <= 0.0 or bulletSpeed >= 10000.0 or yTravelled >= 10000.0 or yTravelled < 0.0 then
                            break
                        end

                        if bulletTravelTime > 8.0 then
                            break
                        end

                        ySpeed = ySpeed + (9.81 * cheat.client.localplayer.heldEntity.heldEntity.predictionData.gravityModifier) * timeStep
                        ySpeed = ySpeed * speedModifier

                        distanceToTravel = distanceToTravel + bulletSpeed * timeStep
                        yTravelled = yTravelled + ySpeed * timeStep
                        bulletTravelTime = bulletTravelTime + timeStep
                    end

                    startPosition.y = startPosition.y + yTravelled

                    return startPosition
                end
            end

            return startPosition;
        end;

        normalizeVector = function(self, vector)
            if vector.x < -89.0 then
                vector.x = -89.0
            elseif vector.x > 89.0 then
                vector.x = 89.0
            end
        
            while vector.y < -180.0 do
                vector.y = vector.y + 360.0
            end
        
            while vector.y > 180.0 do
                vector.y = vector.y - 360.0
            end

            return vector;
        end;

        updateUiData = function(self)
            self.active = false;
            self.altActive = false;

            if draw.cachedUiVars.aimbot.altEnabled.value.state and draw.cachedUiVars.aimbot.altEnabled.value.hotkey.value.keyState then
                self.active = true;
                self.altActive = true;
            elseif draw.cachedUiVars.aimbot.enabled.value.state and draw.cachedUiVars.aimbot.enabled.value.hotkey.value.keyState then
                self.active = true;
            end

            if self.active then
                if self.altActive then
                    self.fov = draw.cachedUiVars.aimbot.altMinimumFov.value.state;
                    self.consistentTargeting = draw.cachedUiVars.aimbot.altConsistentTargeting.value.state;
                    self.targetSwitchDelay = draw.cachedUiVars.aimbot.altTargetSwitchDelay.value.state
                    self.alwaysKeepTargetRegardlessOfFov = draw.cachedUiVars.aimbot.altAlwaysKeepTarget.value.state
                    self.visibleActive = draw.cachedUiVars.aimbot.altVisibleCheck.value.state
                    self.hitbox = draw.cachedUiVars.aimbot.altHitboxes.value.state
                    self.deadzone = draw.cachedUiVars.aimbot.altDeadzone.value.state
                    self.smoothing = draw.cachedUiVars.aimbot.altSmoothing.value.state
                else
                    self.fov = draw.cachedUiVars.aimbot.minimumFov.value.state;
                    self.consistentTargeting = draw.cachedUiVars.aimbot.consistentTargeting.value.state
                    self.targetSwitchDelay = draw.cachedUiVars.aimbot.targetSwitchDelay.value.state
                    self.alwaysKeepTargetRegardlessOfFov = draw.cachedUiVars.aimbot.alwaysKeepTarget.value.state
                    self.visibleActive = draw.cachedUiVars.aimbot.visibleCheck.value.state
                    self.hitbox = draw.cachedUiVars.aimbot.hitboxes.value.state
                    self.deadzone = draw.cachedUiVars.aimbot.deadzone.value.state
                    self.smoothing = draw.cachedUiVars.aimbot.smoothing.value.state
                end

                self.prediction = draw.cachedUiVars.aimbot.prediction.value.state
            end
        end;

        predictionUpdateTimer = timer.new();
        
        run = function(self)
            if draw.menuOpen or draw.epaMenuOpen then
                return;
            end

            self:updateUiData();

            if not cheat.client.localplayer or not cheat.client.localplayer.input then
                return;
            end

            if cheat.entitylist:updateCr3Fail() then
                self.predictionUpdateTimer.update();
                return;
            end

            if self.active then
                if self.lastAimbot and winapi.get_tickcount64() - self.lastAimbot < 15 then
                    return;
                end

                if cheat.client.localplayer.heldEntity and cheat.client.localplayer.heldEntity.heldEntity then
                    if self.predictionUpdateTimer.check(500) or not cheat.client.localplayer.heldEntity.heldEntity.predictionData then
                        cheat.client.localplayer.heldEntity.heldEntity.predictionData = cheat.client.localplayer.heldEntity.heldEntity:getPredictionData();
                    end

                    if cheat.client.localplayer.heldEntity.heldEntity.predictionData and cheat.client.localplayer.heldEntity.heldEntity.predictionData.isGun then
                        local updatedExistingTarget = false;

                        if self.targetPlayer then
                            
                            updatedExistingTarget = self:updatePlayer(self.targetPlayer);
                            if not updatedExistingTarget then
                                if self.lastUpdatedTargetFail == 0 then
                                    self.lastUpdatedTargetFail = winapi.get_tickcount64();
                                    --log("fail 6");
                                    return;
                                else
                                    if winapi.get_tickcount64() - self.lastUpdatedTargetFail > 60 then
                                        self.targetPlayer = nil;
                                        self.lastSwitchTime = winapi.get_tickcount64();
                                        --log("swtime time 1");
                                    else
                                        --log("fail 5");
                                        return;
                                    end
                                end
                            end
                        end
            
                        self.lastUpdatedTargetFail = 0;
            
                        local target = self:getBestTarget();
                        if target then
                            if self.targetPlayer and updatedExistingTarget then
                                if not self.consistentTargeting then
                                    if self.targetPlayer ~= target then
                                        self.targetPlayer = target;
                                        self.lastSwitchTime = winapi.get_tickcount64();
                                        --log("swtime time 2");
                                    end
                                end
                            else
                                self.targetPlayer = target;
                            end
                        end

                        if not self.targetPlayer then
                            --log("fail 4");
                            return;
                        end

                        self.targetPlayerIndex = cheat.entitylist.players[self.targetPlayer];

                        if self.targetPlayerIndex then
                            cheat.entitylist.loopEntitiesTimer.update();
                            if winapi.get_tickcount64() > (self.lastSwitchTime + self.targetSwitchDelay) then
                                local bodyAngles = cheat.client.localplayer.input:getBodyAngles();
                                if not bodyAngles or not bodyAngles:isValid() then
                                    return;
                                end

                                local shouldContinue = false;
                                local isOffset = false;

                                local parentRotation = nil;

                                if cheat.client.localplayer.parentEntity then
                                    local visualRotation = cheat.client.localplayer.parentEntity:getVisualRotation();
                                    if visualRotation then
                                        local rot = visualRotation:calculateEulerAngle(visualRotation)
                                        if rot then
                                            parentRotation = rot;

                                            shouldContinue = true;
                                        end
                                    end
                                elseif cheat.client.localplayer.mounted then
                                    isOffset = true;
                                    local visualRotation = cheat.client.localplayer.mounted:getVisualRotation();
                                    if visualRotation then
                                        local rot = visualRotation:calculateEulerAngle()
                                        if rot then
                                            parentRotation = rot;

                                            shouldContinue = true;
                                        end
                                    end
                                else
                                    shouldContinue = true;
                                end

                                if not shouldContinue then
                                    return;
                                end

                                --bodyAngles = vector3:create(cheat.client.pitch, cheat.client.yaw);

                                
                                if self.rotationUpdateSent then
                                    if ((bodyAngles.x ~= self.lastSentRotationUpdate.x or bodyAngles.y ~= self.lastSentRotationUpdate.y)) then
                                        self.rotationUpdateSent = false;
                                    end
                                end
    
                                local aimAngles = nil;
                                local targetPosition = nil;
                                local isNearest = false;
                                local modifyPitch = true;
    

                                if self.hitbox == 1 then
                                    targetPosition = self:predictPosition(self.targetPlayerIndex, self.targetPlayerIndex:getBonePosition(cheat.structs.bones.fixedHead));
                                elseif self.hitbox == 2 then
                                    targetPosition = self:predictPosition(self.targetPlayerIndex, self.targetPlayerIndex:getBonePosition(cheat.structs.bones.pelvis));
                                elseif self.hitbox == 3 then
                                    if self.targetPlayerIndex.distance > 130 then
                                        targetPosition = self:predictPosition(self.targetPlayerIndex, self.targetPlayerIndex:getBonePosition(cheat.structs.bones.fixedHead));
                                    else
                                        aimAngles, modifyPitch = self:getNearestHitbox(self.targetPlayerIndex, bodyAngles);
                                        isNearest = true;
                                    end
                                end
    
                                if not targetPosition and not isNearest then
                                    return;
                                end
    
                                
                               
                                if isNearest then
                                    aimAngles = self:normalizeVector(aimAngles);
                                else
                                    aimAngles = self:normalizeVector(self:calculateAngle(cheat.client.cameraPosition, targetPosition));
                                end
    
                                if not modifyPitch then
                                    aimAngles.x = bodyAngles.x;
                                end
                                
                                if aimAngles and aimAngles:isValid() then
                                    local preAngle = vector3:create(aimAngles.x, aimAngles.y, aimAngles.z);

                                    if parentRotation and parentRotation:isValid() then
                                        aimAngles.y = aimAngles.y - parentRotation.y;
                                        aimAngles.x = aimAngles.x + parentRotation.x;
                                        aimAngles = self:normalizeVector(aimAngles);
                                    end
                                
                                    local smoothValue = (100 - self.smoothing) / ((self.smoothing/10) )
                                    aimAngles = self:normalizeVector(self:SmoothInterpolate(bodyAngles, aimAngles, smoothValue));

                                    if aimAngles and aimAngles.x ~= -89.0 and aimAngles.x ~= 89.0 and aimAngles.y ~= -180.0 and aimAngles.y ~= 180.0 and (aimAngles.x ~= 0 or aimAngles.y ~= 0) then --no snappy snappy
                                        local forwardVector = cheat:angleToVector(aimAngles);

                                        forwardVector.x = forwardVector.x * 500;
                                        forwardVector.y = forwardVector.y * 500;
                                        forwardVector.z = forwardVector.z * 500;

                                        local forward = cheat.client.cameraPosition:add(forwardVector);
                                        local screenPosition = cheat:worldToScreen(forward);
                                        if screenPosition then
                                            local current_delta = {
                                                x = screenPosition.x - draw.screenCenter.x,
                                                y = screenPosition.y - draw.screenCenter.y
                                            }
                            
                                            local screen_to_angle_ratio = {
                                                x = math.abs(current_delta.x) / draw.screenCenter.x,
                                                y = math.abs(current_delta.y) / draw.screenCenter.y
                                            }
                            
                                            local screendelta_x = math.min(math.max(screen_to_angle_ratio.x, 0.0), 1.0) * 180.0
                                            local screendelta_y = math.min(math.max(screen_to_angle_ratio.y, 0.0), 1.0) * 180.0
                            
                                            local fov = (math.abs(math.sqrt((screendelta_x * screendelta_x) + (screendelta_y * screendelta_y))));-- * 0.7
                            
                                            if fov < 20 then
                                                if self.rotationUpdateSent == false then
                                                    if cheat.entitylist:updateCr3Fail() then
                                                        return;
                                                    end
                                                    
                                                    self.lastSentRotationUpdate.x = bodyAngles.x;
                                                    self.lastSentRotationUpdate.y = bodyAngles.y;
                                                    self.rotationUpdateSent = true;
                                                    cheat.client.localplayer.input:setBodyAngles(self:normalizeVector({x = aimAngles.x, y = aimAngles.y, z = 0}));

                                                    self.lastAimbot = winapi.get_tickcount64();
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            else
                self.targetPlayer = nil;
                self.lastSwitchTime = 0;
                self.lastTargetFail = 0;
                self.lastUpdatedTargetFail = 0;
                self.targetPlayerIndex = nil;
                self.rotationUpdateSent = false;
            end

                
        end;
    };

    angleToVector = function(self, viewAngles)
        local pitch = viewAngles.x
        local yaw = viewAngles.y
    
        local radPitch = math.rad(pitch)
        local radYaw = math.rad(yaw)
    
        local direction = vector3:new(
            math.cos(radPitch) * math.sin(radYaw),
            -math.sin(radPitch),
            math.cos(radPitch) * math.cos(radYaw)
        )
    
        return direction
    end;
    

    recoil = {
        modifiedWeapons = {};

        restoreModifiedWeapons = function(self, onlyRemoveRestored, ignore)
            for key, weapon in pairs(self.modifiedWeapons) do
                if weapon.baseProjectile and weapon.baseProjectile.entity ~= ignore then
                    if weapon.baseProjectile:getIsDestroyed() then
                        self.modifiedWeapons[key] = nil;
                    else
                        local recoilProperties = self:fetchRecoilPropertires(weapon.baseProjectile);
                        if recoilProperties then
                            recoilProperties:manageYawMin(weapon.yawMin);
                            recoilProperties:manageYawMax(weapon.yawMax);
                            recoilProperties:managePitchMin(weapon.pitchMin);
                            recoilProperties:managePitchMax(weapon.pitchMax);
                            self.modifiedWeapons[key] = nil;
                        end
                    end
                end
            end

            if not onlyRemoveRestored then
                self.modifiedWeapons = {};
            end
        end;

        fetchRecoilPropertires = function(self, baseProjectile)
            local recoilProperties = baseProjectile:getRecoilProperties();
            if recoilProperties then
                local override = recoilProperties:getNewRecoilOverride();
                if override then return override; end;
                return recoilProperties;
            end

            return nil;
        end;

        cachedRecoilValues = {};

        weaponChange = function(self)
            if not draw.cachedUiVars.aimbot.adjustRecoil.value.state then
                self:restoreModifiedWeapons(true);
                return
            end

            if not cheat.client.localplayer.heldEntity then
                self:restoreModifiedWeapons(true)
                return;
            end

            self:restoreModifiedWeapons(true, cheat.client.localplayer.heldEntity.heldEntity.entity);

            if cheat.client.localplayer.heldEntity.heldEntity:getClassName() ~= "BaseProjectile" then
                return;
            end

            if draw.cachedUiVars.aimbot.onKey.value.state and not draw.cachedUiVars.aimbot.onKey.value.hotkey.value.keyState then
                return;
            end

            local baseProjectile = cheat.client.localplayer.heldEntity.heldEntity--:getHeldEntity();

            if baseProjectile then
                local recoilProperties = self:fetchRecoilPropertires(cheat.client.localplayer.heldEntity.heldEntity);
                if recoilProperties then
                    local preferredId = cheat.client.localplayer.heldEntity.heldEntity:getPrefabUid();

                    local existingWeapon = self.modifiedWeapons[cheat.client.localplayer.heldEntity.heldEntity.entity]
                    local cachedRecoil = self.cachedRecoilValues[preferredId];

                    local yawMin = cachedRecoil and cachedRecoil.yawMin or existingWeapon and existingWeapon.yawMin or recoilProperties:manageYawMin();
                    local yawMax = cachedRecoil and cachedRecoil.yawMax or existingWeapon and existingWeapon.yawMax or recoilProperties:manageYawMax();
                    local pitchMin = cachedRecoil and cachedRecoil.pitchMin or existingWeapon and existingWeapon.pitchMin or recoilProperties:managePitchMin();
                    local pitchMax = cachedRecoil and cachedRecoil.pitchMax or existingWeapon and existingWeapon.pitchMax or recoilProperties:managePitchMax();

                    if not cachedRecoil then
                        self.cachedRecoilValues[preferredId] = {
                            yawMin = yawMin;
                            yawMax = yawMax;
                            pitchMin = pitchMin;
                            pitchMax = pitchMax;
                        };
                    end

                    if not existingWeapon then
                        self.modifiedWeapons[cheat.client.localplayer.heldEntity.heldEntity.entity] = {
                            yawMin = yawMin;
                            yawMax = yawMax;
                            pitchMin = pitchMin;
                            pitchMax = pitchMax;
                            entity = recoilProperties.entity;
                            baseProjectile = baseProjectile;
                        };
                    end

                    local newRecoil = draw.cachedUiVars.aimbot.recoilReduce.value.state * 0.01;
                    recoilProperties:manageYawMin(yawMin * newRecoil);
                    recoilProperties:manageYawMax(yawMax * newRecoil);
                    recoilProperties:managePitchMin(pitchMin * newRecoil);
                    recoilProperties:managePitchMax(pitchMax * newRecoil);
                end
            end
        end;

        run = function(self)
            if draw.cachedUiVars.aimbot.adjustRecoil.value.state then
                if draw.cachedUiVars.aimbot.onKey.value.state and cheat.client.localplayer.heldEntity and cheat.client.localplayer.heldEntity.heldEntity then
                    if self.previousOnKey ~= draw.cachedUiVars.aimbot.onKey.value.hotkey.value.keyState then
                        self.previousOnKey = draw.cachedUiVars.aimbot.onKey.value.hotkey.value.keyState;

                        if self.previousOnKey then
                            --self:restoreModifiedWeapons(true, cheat.client.localplayer.heldEntity.heldEntity.entity);
                            self:weaponChange();
                        else
                            self:restoreModifiedWeapons(true);
                        end
                    end
                end
            end
        end;
    };

    adminFlags = {
        run = function(self)
            if draw.cachedUiVars.misc.adminFlags.value.state and draw.cachedUiVars.misc.adminFlags.value.hotkey.value.keyState then
                if not cheat.entitylist:updateCr3Fail() then
                    if cheat.class:hasFlag(cheat.client.localplayer:getPlayerFlags(), cheat.structs.playerFlags.isAdmin) then
                        cheat.client.localplayer:addPlayerFlag(cheat.structs.playerFlags.isAdmin)
                        self.didSetAdminFlags = true; 
                    end
                end
            else
                if self.didSetAdminFlags then
                    if not cheat.entitylist:updateCr3Fail() then
                        cheat.client.localplayer:removePlayerFlag(cheat.structs.playerFlags.isAdmin);
                        self.didSetAdminFlags = false; 
                    end
                end
            end
        end;
    };

    fullbright = {
        resetValues = function(self)
            if cheat.offsets.mainCameraSingleton.class and cheat.offsets.mainCameraSingleton.staticClass then
                if self.mainCameraOffset then
                    local mainCamera = cheat.process:readInt64(cheat.offsets.mainCameraSingleton.staticClass + self.mainCameraOffset);
                    if mainCamera ~= 0 then
                        cheat.process:writeFloat(mainCamera + cheat.offsets.rustCamera.ambientLightDay.offset, 0);
                        cheat.process:writeFloat(mainCamera + cheat.offsets.rustCamera.lightIntensity.offset, 0);
                    end
                end
            end
        end;

        run = function(self)
            if draw.cachedUiVars.misc.fullbright.value.state and draw.cachedUiVars.misc.fullbright.value.hotkey.value.keyState then
                if not cheat.offsets.mainCameraSingleton.staticClass then
                    cheat.offsets.mainCameraSingleton.class = cheat.process:readInt64(cheat.process.modules.gameAssembly.base + cheat.offsets.mainCameraSingleton.offset);
                    if cheat.offsets.mainCameraSingleton.class ~= 0 then
                        cheat.offsets.mainCameraSingleton.staticClass = cheat.process:readInt64(cheat.offsets.mainCameraSingleton.class + 0xb8);
                    end
                end
                if cheat.offsets.mainCameraSingleton.staticClass and cheat.offsets.mainCameraSingleton.staticClass ~= 0 then
                    if not self.mainCameraOffset then
                        for i=0, 400 do
                            local mainCam = cheat.class.baseEntity:create(cheat.process:readInt64(cheat.offsets.mainCameraSingleton.staticClass + i));
                            if mainCam then
                                if mainCam:getClassName() == "MainCamera" then
                                    self.mainCameraOffset = i;
                                    break;
                                end
                            end
                        end
                    end

                    if self.mainCameraOffset then
                        self.hasRan = true;

                        local mainCamera = cheat.process:readInt64(cheat.offsets.mainCameraSingleton.staticClass + self.mainCameraOffset);
                        if mainCamera ~= 0 then
                            local currentAmbient = cheat.process:readFloat(mainCamera + cheat.offsets.rustCamera.ambientLightDay.offset);
                            local currentLight = cheat.process:readFloat(mainCamera + cheat.offsets.rustCamera.lightIntensity.offset);
                            if self.currentLight ~= 5 then
                                cheat.process:writeFloat(mainCamera + cheat.offsets.rustCamera.ambientLightDay.offset, 5);
                            end
                            if self.currentAimbient ~= 5 then
                                cheat.process:writeFloat(mainCamera + cheat.offsets.rustCamera.lightIntensity.offset, 5);
                            end
                        end
                    end

                    --local currentAmbient = cheat.process:readFloat(cheat.offsets.mainCameraSingleton.staticClass);
                end
            else
                if self.hasRan then
                    self:resetValues();
                    self.hasRan = false;
                end
            end
        end;
    };

    radar = {
        xOffset = 25,
        yOffset = 25,
        radius = 100,

        rotatePoint = function(self, pointToRotate, centerPoint, angle)
            angle = angle * (math.pi / 180)

            local cosTheta = math.cos(angle)
            local sinTheta = math.sin(angle)

            local rotatedPoint = {}
            rotatedPoint.x = cosTheta * (pointToRotate.x - centerPoint.x) - sinTheta * (pointToRotate.y - centerPoint.y)
            rotatedPoint.y = sinTheta * (pointToRotate.x - centerPoint.x) + cosTheta * (pointToRotate.y - centerPoint.y)

            rotatedPoint.x = rotatedPoint.x + centerPoint.x
            rotatedPoint.y = rotatedPoint.y + centerPoint.y

            return rotatedPoint
        end;

        drawOverlay = function(self)
            if draw.cachedUiVars.misc.radar.value.state then
                local rad = draw.cachedUiVars.misc.radarSize.value.state / 2
                render.draw_circle(self.xOffset + rad, self.yOffset + rad, rad,  0, 0, 0, 175, 1, true)
            end
        end;

        addPlayer = function(self, entity, isLocal)
            if entity.isScientist or entity.isNpc or entity.isDead or not entity.model or entity.isSleeping then
                return
            end

            if not draw.cachedUiVars.misc.radarDrawTeammates.value.state and entity.isTeammate then
                return;
            end
        
            if draw.cachedUiVars.misc.radar.value.state then
                local rad = draw.cachedUiVars.misc.radarSize.value.state / 2
                local centerX = self.xOffset + rad
                local centerY = self.yOffset + rad
        
                local cameraPosition = cheat.client.cameraPosition;
                local screenPosition = {
                    x = (cameraPosition.x - entity.position.x) / draw.cachedUiVars.misc.radarScale.value.state,
                    y = (cameraPosition.z - entity.position.z) / draw.cachedUiVars.misc.radarScale.value.state
                }
        
                if isLocal then
                    screenPosition = {
                        x = (cameraPosition.x - cameraPosition.x) / draw.cachedUiVars.misc.radarScale.value.state,
                        y = (cameraPosition.z - cameraPosition.z) / draw.cachedUiVars.misc.radarScale.value.state
                    }
                end
        
                screenPosition.x = screenPosition.x * -1
                screenPosition.x = screenPosition.x + centerX
                screenPosition.y = screenPosition.y + centerY
        
                local camRotation = 0
        
                if draw.cachedUiVars.misc.radarRotation.value.state then
                    camRotation = cheat.client.yaw;
                    screenPosition = self:rotatePoint(screenPosition, { x = centerX, y = centerY }, 360 - camRotation)
                end
        
                local distance = math.sqrt(number:powww(screenPosition.x - centerX, 2) + number:powww(screenPosition.y - centerY, 2))
        
                if distance > rad then
                    return
                end
        
                local playerColor = entity.isTeammate and draw.cachedUiVars.misc.radarDrawTeammates.value.state and draw.cachedUiVars.misc.radarDrawTeammates.value.colorpicker.value.color or entity.isKnocked and draw.cachedUiVars.visuals.team.teammateKnocked.value.colorpicker.value.color or draw.cachedUiVars.misc.radar.value.colorpicker.value.color;
            
                -- Adjust for visibility
                if draw.cachedUiVars.misc.radarVisibleCheck.value.state and entity.isVisible then
                    playerColor = draw.cachedUiVars.visuals.enemy.playerVisibleCheck.value.colorpicker.value.color;
                end
                
                if isLocal then
                    playerColor = { r = 218, g = 165, b = 32, a = 255 }
                end
        
                if draw.cachedUiVars.misc.playerViewAngles.value.state and not isLocal then
                    local roat = entity.viewAngles
                    local entityYaw = roat.y - camRotation
        
                    if entityYaw < 0 then
                        entityYaw = entityYaw + 360
                    end
        
                    local direction = (entityYaw - 90) * (math.pi / 180)
                    local lineLength = (draw.cachedUiVars.misc.playerSize.value.state * 2.5) + draw.cachedUiVars.misc.playerSize.value.state
        
                    local lineEnd = {}
                    lineEnd.x = screenPosition.x + lineLength * math.cos(direction)
                    lineEnd.y = screenPosition.y + lineLength * math.sin(direction)
        
                    render.draw_line(screenPosition.x, screenPosition.y, lineEnd.x, lineEnd.y, playerColor.r, playerColor.g, playerColor.b, playerColor.a, 1)
                end
        
                render.draw_circle(screenPosition.x, screenPosition.y, draw.cachedUiVars.misc.playerSize.value.state, playerColor.r, playerColor.g, playerColor.b, playerColor.a, 1, true)
            end
        end
    };

    debugcamera = {
        debugCameraShellcode = {
            0xE8, 0x00, 0x00, 0x00, 0x00,  -- call rip ; pushes the address of the next instruction to the stack
            0x5A,                          -- pop rdx ; pop the address of the current instruction into rdx
            0x48, 0x83, 0xEA, 0x2D,        -- sub rdx, 0x2D ; adjust rdx so it points to the beginning of the shellcode context
            0x48, 0x89, 0x5C, 0x24, 0x08,  -- mov QWORD PTR [rsp+0x8], rbx
            0x48, 0x89, 0x6C, 0x24, 0x10,  -- mov QWORD PTR [rsp+0x10], rbp
            0x48, 0x89, 0x74, 0x24, 0x18,  -- mov QWORD PTR [rsp+0x18], rsi
            0x57,                          -- push rdi
            0x48, 0x83, 0xEC, 0x20,        -- sub rsp, 0x20
            0x80, 0x3A, 0x00,              -- cmp BYTE PTR [rdx], 0x0
            0x48, 0x8B, 0xFA,              -- mov rdi, rdx
            0x48, 0x8B, 0xE9,              -- mov rbp, rcx
            0x74, 0x2E,                    -- je +0x2E
            0x48, 0x8B, 0x42, 0x08,        -- mov rax, QWORD PTR [rdx+0x8]
            0x33, 0xC9,                    -- xor ecx, ecx
            0xFF, 0xD0,                    -- call rax
            0x48, 0x8B, 0xF0,              -- mov rsi, rax
            0x48, 0x85, 0xC0,              -- test rax, rax
            0x74, 0x1B,                    -- je +0x1B
            0x8B, 0x57, 0x18,              -- mov edx, DWORD PTR [rdi+0x18]
            0x8B, 0x1C, 0x02,              -- mov ebx, DWORD PTR [rdx+rax]
            0x8B, 0xCB,                    -- mov ecx, ebx
            0x83, 0xC9, 0x04,              -- or ecx, 0x4
            0x89, 0x0C, 0x02,              -- mov DWORD PTR [rdx+rax], ecx
            0x33, 0xD2,                    -- xor edx, edx
            0x33, 0xC9,                    -- xor ecx, ecx
            0xFF, 0x57, 0x10,              -- call QWORD PTR [rdi+0x10]
            0x8B, 0x4F, 0x18,              -- mov ecx, DWORD PTR [rdi+0x18]
            0x89, 0x1C, 0x31,              -- mov DWORD PTR [rcx+rsi*1], ebx
            0xC6, 0x07, 0x00,              -- mov BYTE PTR [rdi], 0x0
            0x48, 0x8B, 0x47, 0x20,        -- mov rax, QWORD PTR [rdi+0x20]
            0x48, 0x8B, 0xCD,              -- mov rcx, rbp
            0x48, 0x8B, 0x5C, 0x24, 0x30,  -- mov rbx, QWORD PTR [rsp+0x30]
            0x48, 0x8B, 0x6C, 0x24, 0x38,  -- mov rbp, QWORD PTR [rsp+0x38]
            0x48, 0x8B, 0x74, 0x24, 0x40,  -- mov rsi, QWORD PTR [rsp+0x40]
            0x48, 0x83, 0xC4, 0x20,        -- add rsp, 0x20
            0x5F,                          -- pop rdi
            0x48, 0xFF, 0xE0               -- jmp rax
        };

        shellcodeContextSize = 0x28;

        steamTrampBase = 0x3e0000;
        steamTrampSize = 0xF000;
        --existingCodeOffset = 0x57;

        
        -- There are 128 functions in 22H2 user32, we add 8 more slots just to future proof a little bit.
        apfnDispatchSize = 8 * (128 + 8);

        tableToBuffer = function(self, tbl)
            local binStr = ""
            for i, byte in ipairs(tbl) do
                binStr = binStr .. string.char(byte)
            end
            return binStr
        end;

        capLength = function(self, vector, maxLength)
            local length = vector:length()
            if length > maxLength then
                local scale = maxLength / length
                vector.x = vector.x * scale
                vector.y = vector.y * scale
                vector.z = vector.z * scale
            end
            return vector
        end;

        setupAddresses = function(self)
            if not self.shellcodeEP then
                --[[local functionAddress = Process.GetExportFromModule(cheat.capturedProcess, cheat.process.modules.user32.base, "PeekMessageW")

                if not functionAddress or functionAddress == 0 then
                    notifications:add('err 74')
                    return false;
                end

                if cheat.process:readInt8(functionAddress) & 0xFF ~= 0xE9 then
                    notifications:add('err 23')
                    return false;
                end

                local relativeOffset = cheat.process:readInt32(functionAddress + 1)

                if relativeOffset >= 0x80000000 then
                    relativeOffset = relativeOffset - 0x100000000
                end

                local nextInstructionAddress = functionAddress + 5
                local destinationAddress = nextInstructionAddress + relativeOffset

                if destinationAddress ~= 0 then]]
                    local destinationAddress = 0x3e0000;

                    local lastNonEmpty = 0; 
                    local totalPayloadSize = self.apfnDispatchSize + self.shellcodeContextSize + #cheat.debugcamera.debugCameraShellcode;

                    local startTime = winapi.get_tickcount64();
                    for i = 0, self.steamTrampSize do
                        if winapi.get_tickcount64() > startTime + 6000 then
                            notifications:add('err 62')
                            return false;
                        end

                        if cheat.process:readInt8(destinationAddress + i) ~= 0 then
                            lastNonEmpty = destinationAddress + i;
                        end

                        if (destinationAddress + i) - lastNonEmpty > (totalPayloadSize*1.25) then
                            break;
                        end
                    end

                    if lastNonEmpty ~= 0 then
                        lastNonEmpty = lastNonEmpty + 6
                        
                        --logh('setting as: ', lastNonEmpty)
                        --Input.SetClipboard(lastNonEmpty)
                        
                        if lastNonEmpty + totalPayloadSize < destinationAddress + self.steamTrampSize then
                            self.steamTrampBase = destinationAddress;

                            self.totalPayloadSize = totalPayloadSize;
                            self.dispatchTableBase = lastNonEmpty;
                            self.shellcodeContext  = self.dispatchTableBase + self.apfnDispatchSize;
                            self.shellcodeEP       = self.shellcodeContext + self.shellcodeContextSize;

                            return true;
                        end
                    else
                        notifications:add('err 18')
                    end
                --[[else
                    notifications:add('err 17')
                end]]
            else
                return true;
            end

            return false;
        end;

        injectShellcode = function(self)
            -- read the value of the KernelCallbackTable inside of the PEB.
            local pebKernelCallbackTable = cheat.process.peb + 0x58; -----------------------ccccha
            local kernelCallbackTable = cheat.process:readInt64(pebKernelCallbackTable);
        
            if kernelCallbackTable == 0 then
                notifications:add('err 1')
                return false;
            end

            
            --[[for i = 500, 0x011A4 + 1000 do
                if cheat.process:readInt64(self.steamTrampBase + i) - cheat.process.modules.gameAssembly.base == cheat.offsets.debugging.debugcamera.offset then
                    return true;
                end
            end

            if cheat.process:readInt64(self.shellcodeContext + 0x8) - cheat.process.modules.gameAssembly.base == cheat.offsets.debugging.debugcamera.offset then
                return true;
            end]]

            for i = 0, self.totalPayloadSize - 1 do
                if cheat.process:readInt8(self.dispatchTableBase + i) ~= 0 then
                    notifications:add('err 2')
                    return false
                end
            end
        
            -- allocate enough memory to copy the apfnDispatch table into.
            local apfnDispatchCopy = m.alloc(self.apfnDispatchSize);
            if apfnDispatchCopy == nil then
                notifications:add('err 3')
                m.free(apfnDispatchCopy);
                return false;
            end

            if cheat.process:readInt64(cheat.process.modules.gameAssembly.base + cheat.offsets.localPlayer.getLocalPlayer.offset) == 0 then
                notifications:add('err 4')
                m.free(apfnDispatchCopy);
                return false;
            end

            if cheat.process:readInt64(cheat.process.modules.gameAssembly.base + cheat.offsets.debugging.debugcamera.offset) == 0 then
                notifications:add('err 5')
                m.free(apfnDispatchCopy);
                return false;
            end
        
            -- copy the original table from user32.dll to our buffer.j
            proc.read_to_memory_buffer(kernelCallbackTable, apfnDispatchCopy, self.apfnDispatchSize);
            -- modify the dispatch table so that the 3rd entry points to our shellcode ep.
            local fnDwordOriginal = m.read_int64(apfnDispatchCopy, 8 * 2);
            m.write_int64(apfnDispatchCopy, 8 * 2, self.shellcodeEP);
        
            -- map the dispatch table copy.
            proc.write_from_memory_buffer(self.dispatchTableBase, apfnDispatchCopy, self.apfnDispatchSize);
        
            -- map the shellcode context (8 byte aligned)
            -- 0x00 : Reset               // controls execution so that the routine can only be ran once without setting this variable back to non-zero.
            -- 0x08 : GetLocalPlayer      // function pointer for LocalPlayer.get_Entity
            -- 0x10 : DebugCamera         // function pointer for ConVar.Debugging.debugcamera
            -- 0x18 : PlayerFlagsOffset   // field offset for BasePlayer.playerFlags
            -- 0x20 : Original            // original function pointer for _fnDWORD
            cheat.process:writeInt64(self.shellcodeContext, 0); -- Reset
            cheat.process:writeInt64(self.shellcodeContext + 0x8, cheat.process.modules.gameAssembly.base + cheat.offsets.localPlayer.getLocalPlayer.offset); -- GetLocalPlayer
            cheat.process:writeInt64(self.shellcodeContext + 0x10, cheat.process.modules.gameAssembly.base + cheat.offsets.debugging.debugcamera.offset); -- DebugCamera
            cheat.process:writeInt64(self.shellcodeContext + 0x18, cheat.offsets.basePlayer.playerFlags.offset); -- PlayerFlagsOffset
            cheat.process:writeInt64(self.shellcodeContext + 0x20, fnDwordOriginal); -- Original fnDWORD pointer
        
            -- map the shellcode body.
            for i = 1, #cheat.debugcamera.debugCameraShellcode do
                local currentByte = cheat.debugcamera.debugCameraShellcode[i];
                cheat.process:writeInt8(self.shellcodeEP + (i - 1), currentByte);
            end

            m.free(apfnDispatchCopy);

            return true;
        end;

        invokeShellcode = function(self)
            if cheat.process:readInt64(self.shellcodeContext + 0x8) - cheat.process.modules.gameAssembly.base == cheat.offsets.debugging.debugcamera.offset then
                notifications:add('err 6')
                return false;
            end

            -- set the reset value to non-zero to allow the routine to execute once.
            cheat.process:writeInt64(self.shellcodeContext, 1);
        
            -- read the value of the KernelCallbackTable inside of the PEB.
            local pebKernelCallbackTable = cheat.process.peb + 0x58;
            local kernelCallbackTable = cheat.process:readInt64(pebKernelCallbackTable);
        
            -- apply the kernel callback table hook to execute our shellcode ep.
            cheat.process:writeInt64(pebKernelCallbackTable, self.dispatchTableBase);
        
            -- wait for the shellcode routine to finish executing
            local startTime = winapi.get_tickcount64();
            local resetValue = 1;
            while resetValue ~= 0 do
                if winapi.get_tickcount64() - startTime > 1000 then
                    log("invoke never responded");
                    break;
                end
                resetValue = cheat.process:readInt64(self.shellcodeContext);
            end
            
            -- routine executed; uninstall the hook.
            cheat.process:writeInt64(pebKernelCallbackTable, kernelCallbackTable);

            return true;
        end;
    };

    webRadar = {
        runTimer = timer.new();
        otherDataTimer = timer.new();
        teamOwnerTimer = timer.new();

        charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";

        numberToRandomString = function(self, num, length)
            local result = ""

            while num > 0 do
                local remainder = (num % #self.charset) + 1
                result = result .. string.sub(self.charset, remainder, remainder)
                num = math.floor(num / #self.charset)
            end

            -- Pad or trim to desired length
            if #result < length then
                result = result .. string.rep("A", length - #result)  -- pad with 'A'
            elseif #result > length then
                result = result:sub(1, length)
            end

            return result
        end;

        correctYawRadians = function(self, originalYaw)
            local correctedYaw = originalYaw + math.pi / 2
        
            --[[ 
            if correctedYaw >= 2 * math.pi then
                correctedYaw = correctedYaw - 2 * math.pi
            elseif correctedYaw < 0 then
                correctedYaw = correctedYaw + 2 * math.pi
            end
            ]]
        
            correctedYaw = 2 * math.pi - correctedYaw
        
            correctedYaw = correctedYaw + 90 -- Adding 90 degrees in radians
        
            return correctedYaw
        end;

        getPlayerEntry = function(self, player)
            if player.position and player.position:isValid() then
                if not player.isNpc and not player.isDead then
                    if not player.isSleeping then
                        local returnTable = {
                            name = player.name or "";
                            yaw = player.viewAngles and self:correctYawRadians(player.viewAngles.y) or 0;
                            x = player.position.x;
                            y = player.position.y;
                            z = player.position.z;
                            steamid = player.steam64 or "";
                            teamid = player.teamId or 0;
                            weapon = player.heldWeaponName or "";
                            id = player.networkableId or 0;
                        };

                        if player.isTeammate then
                            returnTable.teammate = true;
                        end

                        --[[if player.heldWeaponName and player.heldWeaponName ~= "" then
                            returnTable.weapon = player.heldWeaponName;
                        end]]

                        return returnTable;
                    end
                end
            end

            return nil;
        end;

        run = function(self)
            if not draw.cachedUiVars.misc.webRadar.value.state then
                return;
            end

            if self.runTimer.check(draw.cachedUiVars.misc.updateRate.value.state) then
                --log("name: ", cheat.client.localplayer.heldWeaponName);
                local startTime = winapi.get_tickcount64();

                local radarData = {
                    time = startTime;
                    code = storageSystem.radarId;
                    type = "data";
                    players = {};
                };

                if cheat.server.connectedAddress then
                    radarData.ip = cheat.server.connectedAddress;
                end

                if draw.cachedUiVars.misc.sharedRadar.value.state and cheat.client.localplayer.steam64 and string.len(cheat.client.localplayer.steam64) > 2 then
                    if self.teamOwnerTimer.check(1000) then
                        if cheat.client.localplayer.playerTeam then
                            local teamOwner = cheat.client.localplayer.playerTeam:getTeamLeader();
                            if teamOwner > 0 then
                                if not self.teamOwner or self.teamOwner ~= teamOwner then
                                    self.teamOwner = teamOwner;
                                    if cheat.server.connectedAddress and string.len(cheat.server.connectedAddress) > 2 then
                                        local numericStr = string.gsub(cheat.server.connectedAddress, "%D", "")

                                        self.teamCode = self:numberToRandomString(teamOwner + numericStr, 15);
                                    else
                                        self.teamCode = self:numberToRandomString(teamOwner, 15);
                                    end
                                end
                            end
                        end
                    end

                    if self.teamCode then
                        radarData.code = self.teamCode;
                        radarData.shared = true;
                        radarData.user = storageSystem.radarId;
                    end
                else
                    self.teamCode = nil;
                    self.teamOwner = nil;
                end

                local otherDataLoop = self.otherDataTimer.check(5000);

                for entity, player in pairs(cheat.entitylist.players) do
                    table.insert(radarData.players, self:getPlayerEntry(player))
                end

                local localPlayerEntry = self:getPlayerEntry(cheat.client.localplayer);

                if localPlayerEntry then
                    localPlayerEntry.isLocal = true;
                    localPlayerEntry.teammate = true;
                    table.insert(radarData.players, localPlayerEntry);
                end

                if otherDataLoop then
                    radarData.others = {};
                    for entity, other in pairs(cheat.entitylist.others) do
                        if other.prefabData.sendRadar and other.prefabData.sendRadar() then
                            if other.position and other.position:isValid() then
                                table.insert(radarData.others, {
                                    name = other.prefabData.name;
                                    x = other.position.x;
                                    z = other.position.z;
                                    id = other.networkableId or 0;
                                });
                            end
                        end
                    end
                end

                local jsonData = json:stringify(radarData);
                if jsonData then
                    local compressed = fs.compress(jsonData);
                    if compressed and string.len(compressed) > 2 then
                        local encoded = encrypt:base64Encode(compressed);
                        if encoded and string.len(encoded) > 2 then
                            local headers = "direct: " .. radarData.code;
                            net.send_request("http://192.3.180.138:1710/data", headers, encoded)
                            --log("took: ", winapi.get_tickcount64() - startTime);
                        end
                    end
                end
            end
        end;
    };

    visual = {
        bottomYOffset = 0;
        topYOffset = 0;
        activeTeams = {};
        teamColors = {};
        ignorePrefabList = {};

        drawFov = function(self)
            if draw.cachedUiVars.aimbot.drawFov.value.state then
                local radius = (math.tan((cheat.aimbot.fov * (math.pi / 180.0)) / 4.0) * draw.screenCenter.y) * 2.2
                local color = draw.cachedUiVars.aimbot.drawFov.value.colorpicker.value.color

                render.draw_circle(draw.screenCenter.x, draw.screenCenter.y, radius, color.r, color.g, color.b, color.a, 1, false)
            end
        end;

        prefabData = {
            ["metal-ore"] = {
                updateRate = -1;
                name = "METAL";
                getDistance = function() return draw.cachedUiVars.visuals.loot.oreDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.loot.metalOre.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.loot.metalOre.value.state; end;
                callback = function() return cheat.visual.misc.callbacks.ore; end;
                sendRadar = function() return draw.cachedUiVars.misc.webRadar.value.state and draw.cachedUiVars.misc.radarData.value.options[3].value end;
            };
            ["sulfur-ore"] = {
                updateRate = -1;
                name = "SULFUR";
                getDistance = function() return draw.cachedUiVars.visuals.loot.oreDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.loot.sulfurOre.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.loot.sulfurOre.value.state; end;
                callback = function() return cheat.visual.misc.callbacks.ore; end;
                sendRadar = function() return draw.cachedUiVars.misc.webRadar.value.state and draw.cachedUiVars.misc.radarData.value.options[3].value end;
            };
            ["stone-ore"] = {
                updateRate = -1;
                name = "STONE";
                getDistance = function() return draw.cachedUiVars.visuals.loot.oreDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.loot.stoneOre.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.loot.stoneOre.value.state; end;
                callback = function() return cheat.visual.misc.callbacks.ore; end;
                sendRadar = function() return draw.cachedUiVars.misc.webRadar.value.state and draw.cachedUiVars.misc.radarData.value.options[3].value end;
            };
            ["loot_barrel_1"] = {
                updateRate = -1;
                name = "BARREL";
                getDistance = function() return draw.cachedUiVars.visuals.loot.barrelDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.loot.barrels.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.loot.barrels.value.state; end;
            };
            ["loot_barrel_2"] = {
                updateRate = -1;
                name = "BARREL";
                getDistance = function() return draw.cachedUiVars.visuals.loot.barrelDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.loot.barrels.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.loot.barrels.value.state; end;
            };
            ["loot-barrel-1"] = {
                updateRate = -1;
                name = "BARREL";
                getDistance = function() return draw.cachedUiVars.visuals.loot.barrelDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.loot.barrels.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.loot.barrels.value.state; end;
            };
            ["loot-barrel-2"] = {
                updateRate = -1;
                name = "BARREL";
                getDistance = function() return draw.cachedUiVars.visuals.loot.barrelDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.loot.barrels.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.loot.barrels.value.state; end;
            };
            ["crate_elite"] = {
                updateRate = -1;
                name = "ELITE CRATE";
                getDistance = function() return draw.cachedUiVars.visuals.loot.crateDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.loot.eliteCrate.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.loot.eliteCrate.value.state; end;
            };
            ["crate_normal"] = {
                updateRate = -1;
                name = "MIL CRATE";
                getDistance = function() return draw.cachedUiVars.visuals.loot.crateDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.loot.militaryCrate.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.loot.militaryCrate.value.state; end;
            };
            ["crate"] = {
                updateRate = -1;
                name = "CRATE";
                getDistance = function() return draw.cachedUiVars.visuals.loot.crateDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.loot.normalCrate.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.loot.normalCrate.value.state; end;
            };
            ["crate_normal_2"] = {
                updateRate = -1;
                name = "CRATE";
                getDistance = function() return draw.cachedUiVars.visuals.loot.crateDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.loot.normalCrate.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.loot.normalCrate.value.state; end;
            };
            ["cctv.static"] = {
                updateRate = -1;
                name = "CCTV";
                getDistance = function() return 150; end;
                getColor = function() return draw.cachedUiVars.visuals.other.onlineCctvCameras.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.other.onlineCctvCameras.value.state; end;
                callback = function() return cheat.visual.misc.callbacks.cctv; end;
            };
            ["hiddenhackablecrate"] = {
                updateRate = 5000;
                name = "HACKABLE";
                getDistance = function() return draw.cachedUiVars.visuals.loot.hackableCrateDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.loot.hackableCrate.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.loot.hackableCrate.value.state; end;
                callback = function() return cheat.visual.misc.callbacks.hackableCrate; end;
                class = function() return cheat.class.codeLockedHackableCrate; end;
            };
            ["codelockedhackablecrate"] = {
                updateRate = 5000;
                name = "HACKABLE";
                getDistance = function() return draw.cachedUiVars.visuals.loot.hackableCrateDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.loot.hackableCrate.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.loot.hackableCrate.value.state; end;
                callback = function() return cheat.visual.misc.callbacks.hackableCrate; end;
                class = function() return cheat.class.codeLockedHackableCrate; end;
            };
            ["codelockedhackablecrate_oilrig"] = {
                updateRate = 5000;
                name = "HACKABLE";
                getDistance = function() return draw.cachedUiVars.visuals.loot.hackableCrateDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.loot.hackableCrate.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.loot.hackableCrate.value.state; end;
                callback = function() return cheat.visual.misc.callbacks.hackableCrate; end;
                class = function() return cheat.class.codeLockedHackableCrate; end;
            };
            ["item_drop_backpack"] = {
                updateRate = 2000;
                name = "CORPSE";
                getDistance = function() return draw.cachedUiVars.visuals.other.corpseDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.other.corpse.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.other.corpse.value.state; end;

            };
            ["player_corpse_new"] = {
                updateRate = 5000;
                name = "CORPSE";
                getDistance = function() return draw.cachedUiVars.visuals.other.corpseDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.other.corpse.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.other.corpse.value.state; end;
                callback = function() return cheat.visual.misc.callbacks.corpse; end;
            };
            ["player_corpse"] = {
                updateRate = 5000;
                name = "CORPSE";
                getDistance = function() return draw.cachedUiVars.visuals.other.corpseDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.other.corpse.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.other.corpse.value.state; end;
                callback = function() return cheat.visual.misc.callbacks.corpse; end;
            };
            ["mushroom-cluster-6"] = {
                updateRate = -1;
                name = "MUSHROOM";
                getDistance = function() return draw.cachedUiVars.visuals.plants.foodDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.plants.mushroom.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.plants.mushroom.value.state; end;
            };
            ["mushroom-cluster-5"] = {
                updateRate = -1;
                name = "MUSHROOM";
                getDistance = function() return draw.cachedUiVars.visuals.plants.foodDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.plants.mushroom.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.plants.mushroom.value.state; end;
            };
            ["mushroom-cluster-4"] = {
                updateRate = -1;
                name = "MUSHROOM";
                getDistance = function() return draw.cachedUiVars.visuals.plants.foodDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.plants.mushroom.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.plants.mushroom.value.state; end;
            };
            ["mushroom-cluster-3"] = {
                updateRate = -1;
                name = "MUSHROOM";
                getDistance = function() return draw.cachedUiVars.visuals.plants.foodDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.plants.mushroom.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.plants.mushroom.value.state; end;
            };
            ["mushroom-cluster-2"] = {
                updateRate = -1;
                name = "MUSHROOM";
                getDistance = function() return draw.cachedUiVars.visuals.plants.foodDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.plants.mushroom.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.plants.mushroom.value.state; end;
            };
            ["mushroom-cluster-1"] = {
                updateRate = -1;
                name = "MUSHROOM";
                getDistance = function() return draw.cachedUiVars.visuals.plants.foodDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.plants.mushroom.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.plants.mushroom.value.state; end;
            };
            ["polar"] = {
                updateRate = 0;
                name = "BEAR";
                getDistance = function() return draw.cachedUiVars.visuals.animal.animalDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.animal.bear.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.animal.bear.value.state; end;
            };
            ["bear"] = {
                updateRate = 0;
                name = "BEAR";
                getDistance = function() return draw.cachedUiVars.visuals.animal.animalDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.animal.bear.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.animal.bear.value.state; end;
            };
            ["bear_tutorial"] = {
                updateRate = 0;
                name = "BEAR";
                getDistance = function() return draw.cachedUiVars.visuals.animal.animalDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.animal.bear.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.animal.bear.value.state; end;
            };
            ["40mm_grenade_smoke"] = {
                updateRate = 50;
                name = "SMOKE GRENADE";
                getDistance = function() return 100; end;
                getColor = function() return draw.cachedUiVars.visuals.other.grenades.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.other.grenades.value.state; end;
            };
            ["grenade.smoke.deployed"] = {
                updateRate = 0;
                name = "SMOKE GRENADE";
                getDistance = function() return 100; end;
                getColor = function() return draw.cachedUiVars.visuals.other.grenades.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.other.grenades.value.state; end;
            };
            ["grenade.f1.deployed"] = {
                updateRate = 0;
                name = "GRENADE";
                getDistance = function() return 100; end;
                getColor = function() return draw.cachedUiVars.visuals.other.grenades.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.other.grenades.value.state; end;
            };
            ["hemp-collectable"] = {
                updateRate = -1;
                name = "HEMP";
                getDistance = function() return draw.cachedUiVars.visuals.plants.hempDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.plants.hemp.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.plants.hemp.value.state; end;
            };
            ["recycler_static"] = {
                updateRate = -1;
                name = "RECYCLER";
                getDistance = function() return 100; end;
                getColor = function() return draw.cachedUiVars.visuals.other.recycler.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.other.recycler.value.state; end;
            };
            ["minicopter.entity"] = {
                updateRate = 0;
                name = "MINI";
                getDistance = function() return draw.cachedUiVars.visuals.vehicle.heliDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.vehicle.minicopter.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.vehicle.minicopter.value.state; end;
                callback = function() return cheat.visual.misc.callbacks.helicopters; end;
                class = function() return cheat.class.playerHelicopter; end;
                lingerTime = function() return draw.cachedUiVars.visuals.vehicle.heliLingerTime.value.state*1000; end;
                sendRadar = function() return draw.cachedUiVars.misc.webRadar.value.state and draw.cachedUiVars.misc.radarData.value.options[1].value end;
            };
            ["scraptransporthelicopter"] = {
                updateRate = 0;
                name = "SCRAP HELI";
                getDistance = function() return draw.cachedUiVars.visuals.vehicle.heliDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.vehicle.scrapHeli.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.vehicle.scrapHeli.value.state; end;
                callback = function() return cheat.visual.misc.callbacks.helicopters; end;
                class = function() return cheat.class.playerHelicopter; end;
                lingerTime = function() return draw.cachedUiVars.visuals.vehicle.heliLingerTime.value.state*1000; end;
                sendRadar = function() return draw.cachedUiVars.misc.webRadar.value.state and draw.cachedUiVars.misc.radarData.value.options[2].value end;
            };
            ["combatheli"] = {
                updateRate = 0;
                name = "COMBAT HELI";
                getDistance = function() return draw.cachedUiVars.visuals.vehicle.heliDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.vehicle.combatHeli.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.vehicle.combatHeli.value.state; end;
                callback = function() return cheat.visual.misc.callbacks.helicopters; end;
                class = function() return cheat.class.playerHelicopter; end;
                lingerTime = function() return draw.cachedUiVars.visuals.vehicle.heliLingerTime.value.state*1000; end;
            };
            ["rhib"] = {
                updateRate = 0;
                name = "RHIB";
                getDistance = function() return draw.cachedUiVars.visuals.vehicle.boatDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.vehicle.rHIB.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.vehicle.rHIB.value.state; end;
            };
            ["rowboat"] = {
                updateRate = 0;
                name = "ROWBOAT";
                getDistance = function() return draw.cachedUiVars.visuals.vehicle.boatDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.vehicle.rowboat.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.vehicle.rowboat.value.state; end;
            };
            ["supply_drop"] = {
                updateRate = 1000;
                name = "SUPPLY DROP";
                getDistance = function() return draw.cachedUiVars.visuals.loot.supplyDropDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.loot.supplyDrop.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.loot.supplyDrop.value.state; end;
            };
            ["landmine"] = {
                updateRate = -1;
                name = "LAND MINE";
                getDistance = function() return draw.cachedUiVars.visuals.traps.trapDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.traps.landmine.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.traps.landmine.value.state; end;
            };
            ["beartrap"] = {
                updateRate = -1;
                name = "BEAR TRAP";
                getDistance = function() return draw.cachedUiVars.visuals.traps.trapDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.traps.bearTrap.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.traps.bearTrap.value.state; end;
            };
            ["bradleyapc"] = {
                updateRate = 30;
                name = "BRADLEY";
                getDistance = function() return draw.cachedUiVars.visuals.other.aPCDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.other.bradley.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.other.bradley.value.state; end;
                callback = function() return cheat.visual.misc.callbacks.bradley; end;
                class = function() return cheat.class.baseCombatEntity; end;
            };
            ["patrolhelicopter"] = {
                updateRate = 0;
                name = "ATTACK HELI";
                getDistance = function() return draw.cachedUiVars.visuals.other.aPCDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.other.attackHeli.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.other.attackHeli.value.state; end;
                callback = function() return cheat.visual.misc.callbacks.attackHeli; end;
                class = function() return cheat.class.patrolHelicopter; end;
            };
            ["diesel_barrel_world"] = {
                updateRate = -1;
                name = "DIESEL";
                getDistance = function() return 300; end;
                getColor = function() return draw.cachedUiVars.visuals.loot.dieselFuel.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.loot.dieselFuel.value.state; end;
            };
            ["oil_barrel"] = {
                updateRate = -1;
                name = "OIL BARREL";
                getDistance = function() return draw.cachedUiVars.visuals.loot.barrelDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.loot.oilBarrel.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.loot.oilBarrel.value.state; end;
            };
            ["workbench3.static"] = {
                updateRate = -1;
                name = "TIER 3";
                getDistance = function() return 400; end;
                getColor = function() return draw.cachedUiVars.visuals.loot.workbenchTier3.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.loot.workbenchTier3.value.state; end;
            };
            ["crate_tools"] = {
                updateRate = -1;
                name = "TOOLBOX";
                getDistance = function() return 400; end;
                getColor = function() return draw.cachedUiVars.visuals.loot.toolbox.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.loot.toolbox.value.state; end;
            };
            ["box.wooden.large"] = {
                updateRate = -1;
                name = "LARGE BOX";
                getDistance = function() return 400; end;
                getColor = function() return draw.cachedUiVars.visuals.loot.largeStorageBox.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.loot.largeStorageBox.value.state; end;
            };
            ["yellow_berry.entity"] = {
                updateRate = -1;
                name = "YELLOW Berry";
                getDistance = function() return draw.cachedUiVars.visuals.plants.berryDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.plants.yellowBerry.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.plants.yellowBerry.value.state; end;
            };
            ["white_berry.entity"] = {
                updateRate = -1;
                name = "WHITE Berry";
                getDistance = function() return draw.cachedUiVars.visuals.plants.berryDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.plants.whiteBerry.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.plants.whiteBerry.value.state; end;
            };
            ["red_berry.entity"] = {
                updateRate = -1;
                name = "RED Berry";
                getDistance = function() return draw.cachedUiVars.visuals.plants.berryDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.plants.redBerry.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.plants.redBerry.value.state; end;
            };
            ["green_berry.entity"] = {
                updateRate = -1;
                name = "GREEN Berry";
                getDistance = function() return draw.cachedUiVars.visuals.plants.berryDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.plants.greenBerry.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.plants.greenBerry.value.state; end;
            };
            ["blue_berry.entity"] = {
                updateRate = -1;
                name = "BLUE Berry";
                getDistance = function() return draw.cachedUiVars.visuals.plants.berryDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.plants.blueBerry.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.plants.blueBerry.value.state; end;
            };
            ["black_berry.entity"] = {
                updateRate = -1;
                name = "BLACK Berry";
                getDistance = function() return draw.cachedUiVars.visuals.plants.berryDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.plants.blackBerry.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.plants.blackBerry.value.state; end;
            };
            ["pumpkin.entity"] = {
                updateRate = -1;
                name = "PUMPKIN";
                getDistance = function() return draw.cachedUiVars.visuals.plants.foodDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.plants.pumpkin.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.plants.pumpkin.value.state; end;
            };
            ["pumpkin-collectable"] = {
                updateRate = -1;
                name = "PUMPKIN";
                getDistance = function() return draw.cachedUiVars.visuals.plants.foodDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.plants.pumpkin.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.plants.pumpkin.value.state; end;
            };
            ["potato.entity"] = {
                updateRate = -1;
                name = "POTATO";
                getDistance = function() return draw.cachedUiVars.visuals.plants.foodDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.plants.potato.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.plants.potato.value.state; end;
            };
            ["potato.collectable"] = {
                updateRate = -1;
                name = "POTATO";
                getDistance = function() return draw.cachedUiVars.visuals.plants.foodDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.plants.potato.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.plants.potato.value.state; end;
            };
            ["corn.collectable"] = {
                updateRate = -1;
                name = "CORN";
                getDistance = function() return draw.cachedUiVars.visuals.plants.foodDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.plants.corn.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.plants.corn.value.state; end;
            };
            ["corn.entity"] = {
                updateRate = -1;
                name = "CORN";
                getDistance = function() return draw.cachedUiVars.visuals.plants.foodDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.plants.corn.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.plants.corn.value.state; end;
            };
            ["cupboard.tool.retro.deployed"] = {
                updateRate = -1;
                name = "TC";
                getDistance = function() return draw.cachedUiVars.visuals.other.tCDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.other.toolCupboard.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.other.toolCupboard.value.state; end;
            };
            ["cupboard.tool.deployed"] = {
                updateRate = -1;
                name = "TC";
                getDistance = function() return draw.cachedUiVars.visuals.other.tCDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.other.toolCupboard.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.other.toolCupboard.value.state; end;
            };
            ["boar"] = {
                updateRate = 30;
                name = "BOAR";
                getDistance = function() return draw.cachedUiVars.visuals.animal.animalDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.animal.boar.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.animal.boar.value.state; end;
            };
            ["wolf"] = {
                updateRate = 30;
                name = "WOLF";
                getDistance = function() return draw.cachedUiVars.visuals.animal.animalDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.animal.wolf.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.animal.wolf.value.state; end;
            };
            ["wolf2"] = {
                updateRate = 30;
                name = "WOLF";
                getDistance = function() return draw.cachedUiVars.visuals.animal.animalDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.animal.wolf.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.animal.wolf.value.state; end;
            };
            ["stag"] = {
                updateRate = 30;
                name = "DEER";
                getDistance = function() return draw.cachedUiVars.visuals.animal.animalDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.animal.deer.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.animal.deer.value.state; end;
            };
            ["testridablehorse"] = {
                updateRate = 0;
                name = "HORSE";
                getDistance = function() return draw.cachedUiVars.visuals.animal.horseDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.animal.horse.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.animal.horse.value.state; end;
            };
            ["ridablehorse2"] = {
                updateRate = 0;
                name = "HORSE";
                getDistance = function() return draw.cachedUiVars.visuals.animal.horseDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.animal.horse.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.animal.horse.value.state; end;
            };
            ["flameturret.deployed"] = {
                updateRate = -1;
                name = "FLAME TURRET";
                getDistance = function() return draw.cachedUiVars.visuals.traps.trapDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.traps.flameTurret.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.traps.flameTurret.value.state; end;
            };
            ["guntrap.deployed"] = {
                updateRate = -1;
                name = "SHOTGUN TRAP";
                getDistance = function() return draw.cachedUiVars.visuals.traps.trapDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.traps.shotgunTrap.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.traps.shotgunTrap.value.state; end;
            };
            ["sam_site_turret_deployed"] = {
                updateRate = -1;
                name = "SAMSITE";
                getDistance = function() return draw.cachedUiVars.visuals.traps.samsiteDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.traps.samsite.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.traps.samsite.value.state; end;
            };
            ["sam_static"] = {
                updateRate = -1;
                name = "SAMSITE";
                getDistance = function() return draw.cachedUiVars.visuals.traps.samsiteDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.traps.samsite.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.traps.samsite.value.state; end;
                callback = function() return cheat.visual.misc.callbacks.samsite end;
            };
            ["autoturret_deployed"] = {
                updateRate = -1;
                name = "TURRET";
                getDistance = function() return draw.cachedUiVars.visuals.traps.turretDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.traps.turret.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.traps.turret.value.state; end;
                callback = function() return cheat.visual.misc.callbacks.turret end;
            };
            ["foodbox"] = {
                updateRate = -1;
                name = "FOOD CRATE";
                getDistance = function() return draw.cachedUiVars.visuals.loot.crateDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.loot.foodCrate.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.loot.foodCrate.value.state; end;
            };
            ["bradley_crate"] = {
                updateRate = -1;
                name = "BRAD CRATE";
                getDistance = function() return draw.cachedUiVars.visuals.loot.aPCCrateDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.loot.aPCCrate.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.loot.aPCCrate.value.state; end;
                callback = function() return cheat.visual.misc.callbacks.apcCrate; end;
            };
            ["heli_crate"] = {
                updateRate = -1;
                name = "HELI CRATE";
                getDistance = function() return draw.cachedUiVars.visuals.loot.aPCCrateDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.loot.aPCCrate.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.loot.aPCCrate.value.state; end;
                callback = function() return cheat.visual.misc.callbacks.apcCrate; end;
            };
            ["pedalbike"] = {
                updateRate = 10;
                name = "BIKE";
                getDistance = function() return draw.cachedUiVars.visuals.vehicle.bikeDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.vehicle.pedalBike.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.vehicle.pedalBike.value.state; end;
            };
            ["motorbike"] = {
                updateRate = 10;
                name = "MOTOR BIKE";
                getDistance = function() return draw.cachedUiVars.visuals.vehicle.bikeDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.vehicle.motorBike.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.vehicle.motorBike.value.state; end;
            };
            ["rifle.ak (world)"] = {
                updateRate = 350;
                name = "AK47";
                getDistance = function() return draw.cachedUiVars.visuals.other.droppedWeaponDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.state and draw.cachedUiVars.visuals.other.droppedWeaponsTypes.value.options[3].value; end;
            };
            
            ["lmg.m249 (world)"] = {
                updateRate = 350;
                name = "M249";
                getDistance = function() return draw.cachedUiVars.visuals.other.droppedWeaponDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.state and draw.cachedUiVars.visuals.other.droppedWeaponsTypes.value.options[3].value; end;
            };
            
            ["rifle.ak.diver (world)"] = {
                updateRate = 350;
                name = "AK47";
                getDistance = function() return draw.cachedUiVars.visuals.other.droppedWeaponDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.state and draw.cachedUiVars.visuals.other.droppedWeaponsTypes.value.options[3].value; end;
            };
            
            ["multiplegrenadelauncher (world)"] = {
                updateRate = 350;
                name = "MGL";
                getDistance = function() return draw.cachedUiVars.visuals.other.droppedWeaponDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.state and draw.cachedUiVars.visuals.other.droppedWeaponsTypes.value.options[3].value; end;
            };
            
            ["minigun (world)"] = {
                updateRate = 350;
                name = "MINIGUN";
                getDistance = function() return draw.cachedUiVars.visuals.other.droppedWeaponDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.state and draw.cachedUiVars.visuals.other.droppedWeaponsTypes.value.options[3].value; end;
            };
            
            ["military flamethrower (world)"] = {
                updateRate = 350;
                name = "FLAMETHROWER";
                getDistance = function() return draw.cachedUiVars.visuals.other.droppedWeaponDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.state and draw.cachedUiVars.visuals.other.droppedWeaponsTypes.value.options[3].value; end;
            };
            
            ["hmlmg (world)"] = {
                updateRate = 350;
                name = "HMLMG";
                getDistance = function() return draw.cachedUiVars.visuals.other.droppedWeaponDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.state and draw.cachedUiVars.visuals.other.droppedWeaponsTypes.value.options[3].value; end;
            };
            
            ["homingmissile.launcher (world)"] = {
                updateRate = 350;
                name = "LAUNCHER";
                getDistance = function() return draw.cachedUiVars.visuals.other.droppedWeaponDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.state and draw.cachedUiVars.visuals.other.droppedWeaponsTypes.value.options[3].value; end;
            };
            
            ["rifle.l96 (world)"] = {
                updateRate = 350;
                name = "L96";
                getDistance = function() return draw.cachedUiVars.visuals.other.droppedWeaponDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.state and draw.cachedUiVars.visuals.other.droppedWeaponsTypes.value.options[3].value; end;
            };
            
            ["rifle.lr300 (world)"] = {
                updateRate = 350;
                name = "LR300";
                getDistance = function() return draw.cachedUiVars.visuals.other.droppedWeaponDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.state and draw.cachedUiVars.visuals.other.droppedWeaponsTypes.value.options[3].value; end;
            };
            
            ["shotgun.m4 (world)"] = {
                updateRate = 350;
                name = "M4 SHOTGUN";
                getDistance = function() return draw.cachedUiVars.visuals.other.droppedWeaponDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.state and draw.cachedUiVars.visuals.other.droppedWeaponsTypes.value.options[3].value; end;
            };
            
            ["rocket.launcher.dragon (world)"] = {
                updateRate = 350;
                name = "LAUNCHER";
                getDistance = function() return draw.cachedUiVars.visuals.other.droppedWeaponDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.state and draw.cachedUiVars.visuals.other.droppedWeaponsTypes.value.options[3].value; end;
            };
            
            ["rifle.bolt (world)"] = {
                updateRate = 350;
                name = "BOLT";
                getDistance = function() return draw.cachedUiVars.visuals.other.droppedWeaponDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.state and draw.cachedUiVars.visuals.other.droppedWeaponsTypes.value.options[3].value; end;
            };
            
            ["rifle.ak.ice (world)"] = {
                updateRate = 350;
                name = "AK47";
                getDistance = function() return draw.cachedUiVars.visuals.other.droppedWeaponDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.state and draw.cachedUiVars.visuals.other.droppedWeaponsTypes.value.options[3].value; end;
            };
            
            ["rocket.launcher (world)"] = {
                updateRate = 350;
                name = "LAUNCHER";
                getDistance = function() return draw.cachedUiVars.visuals.other.droppedWeaponDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.state and draw.cachedUiVars.visuals.other.droppedWeaponsTypes.value.options[3].value; end;
            };
            
            ["smg.2 (world)"] = {
                updateRate = 350;
                name = "CUSTOM SMG";
                getDistance = function() return draw.cachedUiVars.visuals.other.droppedWeaponDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.state and draw.cachedUiVars.visuals.other.droppedWeaponsTypes.value.options[3].value; end;
            };
            
            ["pistol.python (world)"] = {
                updateRate = 350;
                name = "PYTHON";
                getDistance = function() return draw.cachedUiVars.visuals.other.droppedWeaponDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.state and draw.cachedUiVars.visuals.other.droppedWeaponsTypes.value.options[2].value; end;
            };
            
            ["smg.mp5 (world)"] = {
                updateRate = 350;
                name = "MP5";
                getDistance = function() return draw.cachedUiVars.visuals.other.droppedWeaponDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.state and draw.cachedUiVars.visuals.other.droppedWeaponsTypes.value.options[2].value; end;
            };
            
            ["shotgun.pump (world)"] = {
                updateRate = 350;
                name = "PUMP SHOTGUN";
                getDistance = function() return draw.cachedUiVars.visuals.other.droppedWeaponDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.state and draw.cachedUiVars.visuals.other.droppedWeaponsTypes.value.options[2].value; end;
            };
            
            ["revolver.hc (world)"] = {
                updateRate = 350;
                name = "REVOLVER";
                getDistance = function() return draw.cachedUiVars.visuals.other.droppedWeaponDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.state and draw.cachedUiVars.visuals.other.droppedWeaponsTypes.value.options[2].value; end;
            };
            
            ["pistol.prototype17 (world)"] = {
                updateRate = 350;
                name = "PROTO P17";
                getDistance = function() return draw.cachedUiVars.visuals.other.droppedWeaponDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.state and draw.cachedUiVars.visuals.other.droppedWeaponsTypes.value.options[2].value; end;
            };
            
            ["rifle.sks (world)"] = {
                updateRate = 350;
                name = "SKS";
                getDistance = function() return draw.cachedUiVars.visuals.other.droppedWeaponDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.state and draw.cachedUiVars.visuals.other.droppedWeaponsTypes.value.options[2].value; end;
            };
            
            ["smg.thompson (world)"] = {
                updateRate = 350;
                name = "THOMPSON";
                getDistance = function() return draw.cachedUiVars.visuals.other.droppedWeaponDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.state and draw.cachedUiVars.visuals.other.droppedWeaponsTypes.value.options[2].value; end;
            };
            
            ["rifle.semiauto (world)"] = {
                updateRate = 350;
                name = "SAR";
                getDistance = function() return draw.cachedUiVars.visuals.other.droppedWeaponDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.state and draw.cachedUiVars.visuals.other.droppedWeaponsTypes.value.options[2].value; end;
            };
            
            ["rifle.m39 (world)"] = {
                updateRate = 350;
                name = "M39";
                getDistance = function() return draw.cachedUiVars.visuals.other.droppedWeaponDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.state and draw.cachedUiVars.visuals.other.droppedWeaponsTypes.value.options[2].value; end;
            };
            
            ["pistol.m92 (world)"] = {
                updateRate = 350;
                name = "M92";
                getDistance = function() return draw.cachedUiVars.visuals.other.droppedWeaponDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.state and draw.cachedUiVars.visuals.other.droppedWeaponsTypes.value.options[2].value; end;
            };
            
            ["pistol.nailgun (world)"] = {
                updateRate = 350;
                name = "NAILGUN";
                getDistance = function() return draw.cachedUiVars.visuals.other.droppedWeaponDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.state and draw.cachedUiVars.visuals.other.droppedWeaponsTypes.value.options[4].value; end;
            };
            
            ["bow.hunting (world)"] = {
                updateRate = 350;
                name = "BOW";
                getDistance = function() return draw.cachedUiVars.visuals.other.droppedWeaponDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.state and draw.cachedUiVars.visuals.other.droppedWeaponsTypes.value.options[4].value; end;
            };
            
            ["legacy bow (world)"] = {
                updateRate = 350;
                name = "BOW";
                getDistance = function() return draw.cachedUiVars.visuals.other.droppedWeaponDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.state and draw.cachedUiVars.visuals.other.droppedWeaponsTypes.value.options[4].value; end;
            };
            
            ["crossbow (world)"] = {
                updateRate = 350;
                name = "CROSSBOW";
                getDistance = function() return draw.cachedUiVars.visuals.other.droppedWeaponDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.state and draw.cachedUiVars.visuals.other.droppedWeaponsTypes.value.options[4].value; end;
            };
            
            ["bow.compound (world)"] = {
                updateRate = 350;
                name = "COMPOUND BOW";
                getDistance = function() return draw.cachedUiVars.visuals.other.droppedWeaponDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.state and draw.cachedUiVars.visuals.other.droppedWeaponsTypes.value.options[4].value; end;
            };
            
            ["shotgun.double (world)"] = {
                updateRate = 350;
                name = "DOUBLE BARREL";
                getDistance = function() return draw.cachedUiVars.visuals.other.droppedWeaponDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.state and draw.cachedUiVars.visuals.other.droppedWeaponsTypes.value.options[1].value; end;
            };
            
            ["pistol.revolver (world)"] = {
                updateRate = 350;
                name = "REVOLVER";
                getDistance = function() return draw.cachedUiVars.visuals.other.droppedWeaponDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.state and draw.cachedUiVars.visuals.other.droppedWeaponsTypes.value.options[1].value; end;
            };
            
            ["pistol.semiauto (world)"] = {
                updateRate = 350;
                name = "SEMI PISTOL";
                getDistance = function() return draw.cachedUiVars.visuals.other.droppedWeaponDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.state and draw.cachedUiVars.visuals.other.droppedWeaponsTypes.value.options[1].value; end;
            };
            
            ["shotgun.waterpipe (world)"] = {
                updateRate = 350;
                name = "WATERPIPE";
                getDistance = function() return draw.cachedUiVars.visuals.other.droppedWeaponDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.state and draw.cachedUiVars.visuals.other.droppedWeaponsTypes.value.options[1].value; end;
            };
            
            ["workbench3 (world)"] = {
                updateRate = 350;
                name = "TIER 3";
                getDistance = function() return draw.cachedUiVars.visuals.other.droppedWeaponDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.state and draw.cachedUiVars.visuals.other.droppedWeaponsTypes.value.options[6].value; end;
            };
            
            ["workbench2 (world)"] = {
                updateRate = 350;
                name = "TIER 2";
                getDistance = function() return draw.cachedUiVars.visuals.other.droppedWeaponDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.state and draw.cachedUiVars.visuals.other.droppedWeaponsTypes.value.options[6].value; end;
            };
            
            ["jackhammer (world)"] = {
                updateRate = 350;
                name = "JACKHAMMER";
                getDistance = function() return draw.cachedUiVars.visuals.other.droppedWeaponDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.state and draw.cachedUiVars.visuals.other.droppedWeaponsTypes.value.options[6].value; end;
            };
            
            ["explosive.satchel (world)"] = {
                updateRate = 350;
                name = "SATCHEL";
                getDistance = function() return draw.cachedUiVars.visuals.other.droppedWeaponDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.state and draw.cachedUiVars.visuals.other.droppedWeaponsTypes.value.options[5].value; end;
            };
            
            ["explosive.timed (world)"] = {
                updateRate = 350;
                name = "C4";
                getDistance = function() return draw.cachedUiVars.visuals.other.droppedWeaponDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.state and draw.cachedUiVars.visuals.other.droppedWeaponsTypes.value.options[5].value; end;
            };
            ["ammo.rocket.basic (world)"] = {
                updateRate = 350;
                name = "ROCKET";
                getDistance = function() return draw.cachedUiVars.visuals.other.droppedWeaponDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.state and draw.cachedUiVars.visuals.other.droppedWeaponsTypes.value.options[5].value; end;
            };
            ["jackhammer (world)"] = {
                updateRate = 350;
                name = "JACKHAMMER";
                getDistance = function() return draw.cachedUiVars.visuals.other.droppedWeaponDistance.value.state; end;
                getColor = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.colorpicker.value.color; end;
                getShouldDraw = function() return draw.cachedUiVars.visuals.other.droppedWeapons.value.state and draw.cachedUiVars.visuals.other.droppedWeaponsTypes.value.options[6].value; end;
            };
        };

        ColorConvertHSVtoRGB = function(self, h, s, v)
            local out_r, out_g, out_b = 1.0, 1.0, 1.0
        
            if s == 0.0 then
                -- Gray
                out_r = v
                out_g = v
                out_b = v
            else
                h = (h % 1.0) * 6.0
                local i = math.floor(h)
                local f = h - i
                local p = v * (1.0 - s)
                local q = v * (1.0 - s * f)
                local t = v * (1.0 - s * (1.0 - f))
        
                if i == 0 then
                    out_r, out_g, out_b = v, t, p
                elseif i == 1 then
                    out_r, out_g, out_b = q, v, p
                elseif i == 2 then
                    out_r, out_g, out_b = p, v, t
                elseif i == 3 then
                    out_r, out_g, out_b = p, q, v
                elseif i == 4 then
                    out_r, out_g, out_b = t, p, v
                else
                    out_r, out_g, out_b = v, p, q
                end
            end
        
            return {
                r = math.floor(out_r * 255.0),
                g = math.floor(out_g * 255.0),
                b = math.floor(out_b * 255.0),
                a = 255
            }
        end;
        
        calculateHealthColor = function(self, health, maxHealth)
            local h = (health * (120.0 / 360.0)) / (maxHealth or 100)
            local s = 1.0
            local v = 0.68
            return self:ColorConvertHSVtoRGB(h, s, v)
        end;

        drawTriangle = function(self, point1, point2, point3, color, thickness)
            render.draw_line(point1.x, point1.y, point2.x, point2.y, color.r, color.g, color.b, color.a or 255, thickness or 1)
            render.draw_line(point2.x, point2.y, point3.x, point3.y, color.r, color.g, color.b, color.a or 255, thickness or 1)
            render.draw_line(point3.x, point3.y, point1.x, point1.y, color.r, color.g, color.b, color.a or 255, thickness or 1)
        end;

        getTeamColor = function(self, teamid)
            if self.teamColors[teamid] then
                return self.teamColors[teamid] -- Return cached color if already generated
            end

            local r = (teamid * 2654435761) % 256
            local g = (teamid * 1597334677) % 256
            local b = (teamid * 11400714819323198485) % 256
        
            -- Function to calculate the luminance of the color
            local function calculateLuminance(r, g, b)
                return 0.299 * r + 0.587 * g + 0.114 * b
            end
        
            -- Ensure the color isn't too dark
            local minLuminance = 100  -- Adjust this threshold based on your needs (0 is black, 255 is white)
            local luminance = calculateLuminance(r, g, b)
        
            if luminance < minLuminance then
                local adjustmentFactor = minLuminance / luminance
                r = math.min(255, r * adjustmentFactor)
                g = math.min(255, g * adjustmentFactor)
                b = math.min(255, b * adjustmentFactor)
            end
        
            self.teamColors[teamid] = {r = r, g = g, b = b, a = 255}
            return self.teamColors[teamid]
        end;

        drawBox = function(self, player, r, g, b, a)
            local boxWidth = player.bounds.right - player.bounds.left;
            local boxHeight = player.bounds.bottom - player.bounds.top;

            if draw.cachedUiVars.visuals.other.boxOutlines.value.state then
                drawRectangle(player.bounds.left + 1, player.bounds.top + 1, boxWidth - 2, boxHeight - 2, 0, 0, 0, a, false, 1);
                drawRectangle(player.bounds.left - 1, player.bounds.top - 1, boxWidth + 2, boxHeight + 2, 0, 0, 0, a, false, 1);
            end

            drawRectangle(player.bounds.left, player.bounds.top, boxWidth, boxHeight, r, g, b, a, false, 1);
        end;

        drawWeapon = function(self, player, r, g, b, a)
            local boxWidth = player.bounds.right - player.bounds.left;

            if player.heldEntity then
                if player.heldWeaponName and string.len(player.heldWeaponName) > 1 and player.heldWeaponName ~= "?" then
                    drawText(draw.fonts.entityText, player.heldWeaponName, player.bounds.left + (boxWidth/2), (player.bounds.bottom) + 1 + self.bottomYOffset, r,g,b,a, draw.cachedUiVars.visuals.other.outlines.value.state, true, false, a);
                    self.bottomYOffset = self.bottomYOffset + draw.fonts.entityText.height;
                end
            end
        end;

        drawName = function(self, player, r, g, b, a)
            local boxWidth = player.bounds.right - player.bounds.left;

            if not player.name or string.len(player.name) == 0 then
                return;
            end

            --local distanceText = tostring(math.floor(player.position.x)) .. " - " .. tostring(math.floor(player.position.y)) .. " - " .. tostring(math.floor(player.position.z)) .. " - "
            drawText(draw.fonts.entityText, player.name, player.bounds.left + (boxWidth/2), (player.bounds.top) - draw.fonts.entityText.height - self.topYOffset - 2, r,g,b,a, draw.cachedUiVars.visuals.other.outlines.value.state, true, false, a);

        end;

        drawDistance = function(self, player, r, g, b, a)
            if player.distance then
                local boxWidth = player.bounds.right - player.bounds.left;
                local distanceText = tostring(math.floor(player.distance)) .. "m"
                drawText(draw.fonts.entityText, distanceText, player.bounds.left + (boxWidth/2), (player.bounds.bottom) + 1 + self.bottomYOffset, r,g,b,a, draw.cachedUiVars.visuals.other.outlines.value.state, true, false, a);

                self.bottomYOffset = self.bottomYOffset + draw.fonts.entityText.height;
                --self.bottomYOffset = self.bottomYOffset + draw.fonts.entityText.height;
            end
        end;

        oofArrows = {
            scaleDistanceToRange = function(self, distance, minDistance, maxDistance, newMin, newMax)
                -- Ensure the distance is within the range
                if distance < minDistance then
                    distance = minDistance
                elseif distance > maxDistance then
                    distance = maxDistance
                end
                
                -- Apply the linear interpolation formula
                local scaled_value = (distance - minDistance) * (newMax - newMin) / (maxDistance - minDistance) + newMin
                return scaled_value
            end;

            drawPlayer = function(self, player)
                if draw.cachedUiVars.visuals.enemy.oOFArrows.value.state then
                    if not player.isSleeping and not player.isKnocked and not player.isTeammate and not player.onScreen and not player.isNpc and player.distance < 600 then
                        local screenCenterX = draw.screenSize.x / 2
                        local screenCenterY = draw.screenSize.y / 2
            
                        -- Calculate the relative position of the player
                        local position = vector3:create(cheat.client.cameraPosition.x - player.position.x, cheat.client.cameraPosition.z - player.position.z):unitVector()
            
                        -- Use cameraYaw instead of bodyAngles for calculating angle to player
                        local angle = number:atan2(position.x, position.y) * 57.29578 - 180 - cheat.client.yaw
            
                        -- Calculate triangle points for arrow drawing using the adjusted angle
                        local pos_0 = number:cosTanHorizontal(angle, 10, screenCenterX, screenCenterY, 140)
                        local pos_1 = number:cosTanHorizontal(angle + 2, 10, screenCenterX, screenCenterY, 130)
                        local pos_2 = number:cosTanHorizontal(angle - 2, 10, screenCenterX, screenCenterY, 130)
            
                        -- Get the player's color and opacity based on distance
                        local playerColor = draw.cachedUiVars.visuals.enemy.oOFArrows.value.colorpicker.value.color
                        local opacity = self:scaleDistanceToRange(player.distance, 0, 275, 255, 50)
            
                        -- Draw the triangle as the OOF arrow with calculated positions
                        cheat.visual:drawTriangle(pos_0, pos_1, pos_2, {r = playerColor.r, g = playerColor.g, b = playerColor.b, a = opacity}, 2)
                    end
                end
            end;
        };

        hotbar = {
            referenceWidth = 1920;
            referenceHeight = 1080;
            
            originalRectWidth = 90;
            originalRectHeight = 90;
            originalGap = 6;
            
            originalStartX = 660;
            originalStartY = 850;

            playerHotbarReferences = {};

            drawHotbars = function(self)
                local scaleX = draw.screenSize.x / self.referenceWidth
                local scaleY = draw.screenSize.y / self.referenceHeight
        
                local rectWidth = math.floor(self.originalRectWidth * scaleX)
                local rectHeight = math.floor(self.originalRectHeight * scaleY)
                local gap = math.floor(self.originalGap * scaleX)
        
                local hotbarsToDraw = {}
        
                -- Prepare valid hotbar data
                for _, player in ipairs(self.playerHotbarReferences) do
                    if player.playerInventory then
                        local belt = player.playerInventory:getBelt()
                        if belt then
                            local itemList = belt:getItemList()
                            if itemList and itemList ~= 0 then
                                local items = cheat.class.itemList:getItemList(itemList)
                                local listSize = cheat.class.itemList:getSize(itemList)
        
                                if listSize > 0 and listSize <= 6 then
                                    local strings = {}
                                    local largestX, totalY = 0, 0
        
                                    for i = 0, (listSize - 1) do
                                        local item = cheat.class.item:create(cheat.process:readInt64(items + 0x20 + (i * 0x8)))
                                        if item then
                                            local itemDefinition = item:getItemDefinition()
                                            if itemDefinition then
                                                local displayName = itemDefinition:getDisplayName()
                                                if displayName and #displayName > 0 then
                                                    table.insert(strings, displayName)
                                                    local textMX, textMY = render.measure_text(draw.fonts.hotbarText.font, displayName)
                                                    largestX = math.max(largestX, textMX)
                                                    totalY = totalY + textMY + 1
                                                end
                                            end
                                        end
                                    end
        
                                    if #strings > 0 then
                                        local hotbarText = player.name and (#player.name > 0 and (player.name .. " HOTBAR") or "HOTBAR") or "HOTBAR"
                                        local titleMX, titleMY = render.measure_text(draw.fonts.hotbarText.font, hotbarText)
                                        largestX = math.max(largestX, titleMX)
                                        totalY = totalY + draw.fonts.hotbarText.height + 4
        
                                        table.insert(hotbarsToDraw, {
                                            name = hotbarText,
                                            strings = strings,
                                            width = largestX,
                                            height = totalY
                                        })
                                    end
                                end
                            end
                        end
                    end
                end

        
                -- Positioning and drawing
                local totalHeight = 0
                for _, data in ipairs(hotbarsToDraw) do
                    totalHeight = totalHeight + data.height + 16 -- 16px vertical gap
                end
                totalHeight = totalHeight - 16 -- Remove gap after last item
        
                local startY = draw.screenCenter.y - (totalHeight / 2)
        
                for _, data in ipairs(hotbarsToDraw) do
                    local x = draw.screenSize.x - data.width - 12
                    local y = startY
        
                    drawRectangle(x, y, data.width + 4, data.height + 2, 70, 70, 70, 255, false, 2)
                    drawRectangle(x, y, data.width + 4, data.height + 2, 22, 22, 22, 220, true, 1)
                    drawRectangle(x, y, data.width + 4, draw.fonts.hotbarText.height + 4, 45, 45, 45, 220, true, 1)
                    drawText(draw.fonts.hotbarText, data.name, x + ((data.width + 2) / 2), y + 2, 255, 255, 255, 255, true, true)
        
                    local yOffset = draw.fonts.hotbarText.height + 5
                    for _, itemName in ipairs(data.strings) do
                        drawText(draw.fonts.hotbarText, itemName, x + 2, y + yOffset, 255, 255, 255, 255, false, false)
                        yOffset = yOffset + draw.fonts.hotbarText.height + 1
                    end
        
                    startY = startY + data.height + 16
                end
            end
        };

        drawPlayerFlags = function(self, player)
            if not player.isTeammate and not player.isNpc then
                if player.distance then
                    if player.distance < 400 then
                        local fontSize = number:roundToDecimals(number:scaleValue(25, 206, player.distance, 8, 5, false), 0)
                        --local outlineWidth = number:scaleValue(25, 206, player.distance, 4.3, 2.1, false)
                        local flagFont = draw:createFont("consola.ttf", math.floor(fontSize), 150, {
                            thickness = 1.4;
                        });
                        
                        if flagFont then
                            if flagFont.font then
                                local scaleFactor = player.distance / 160;
                                local adjustedTop = player.bounds.top - scaleFactor;

                                if player.teamId and player.teamId ~= 0 and draw.cachedUiVars.visuals.enemy.teamidFlag.value.state and cheat.visual.activeTeams[player.teamId] > 1 then
                                    if draw.cachedUiVars.visuals.enemy.teamidDrawType.value.state == 1 then -- colored box
                                        local flagColor = self:getTeamColor(player.teamId)
                                        drawRectangle(player.bounds.right + 2, adjustedTop, 3, 2, flagColor.r, flagColor.g, flagColor.b, player.opacity and player.opacity or flagColor.a, true, 1)
                                    elseif draw.cachedUiVars.visuals.enemy.teamidDrawType.value.state == 2 then 
                                        local flagColor = self:getTeamColor(player.teamId)
                                        drawText(flagFont, tostring(player.teamId), player.bounds.right + 3, adjustedTop, flagColor.r,flagColor.g,flagColor.b,player.opacity and player.opacity or flagColor.a, true, false, false, player.opacity);
                                    else
                                        local flagColor = draw.cachedUiVars.visuals.enemy.teamidFlag.value.colorpicker.value.color;
                                        drawText(flagFont, tostring(player.teamId), player.bounds.right + 3, adjustedTop, flagColor.r,flagColor.g,flagColor.b,player.opacity and player.opacity or flagColor.a, true, false, false, player.opacity);
                                    end
                                end

                                local startY = 0;
                                if player.isBot and draw.cachedUiVars.visuals.enemy.botFlag.value.state then
                                    local flagColor = draw.cachedUiVars.visuals.enemy.botFlag.value.colorpicker.value.color;
                                    drawRectangle(player.bounds.left - 2 - 4, adjustedTop + startY, 3, 2, flagColor.r, flagColor.g, flagColor.b, player.opacity and player.opacity or flagColor.a, true, 1)
                                    startY = startY + 4;
                                end
                
                                if not player.isBot then
                                    if player.isServerAdmin then
                                        local flagColor = {r = 138, g = 43, b = 226, a = 255};
                                        drawRectangle(player.bounds.left - 2 - 4, adjustedTop + startY, 3, 2, flagColor.r, flagColor.g, flagColor.b, player.opacity and player.opacity or flagColor.a, true, 1)
                                        startY = startY + 4;
                                    end
                                    if player.isAdminFlag then
                                        local flagColor = {r = 0, g = 255, b = 255, a = 255};
                                        drawRectangle(player.bounds.left - 2 - 4, adjustedTop + startY, 3, 2, flagColor.r, flagColor.g, flagColor.b, player.opacity and player.opacity or flagColor.a, true, 1)
                                        startY = startY + 4;
                                    end
                                    if draw.cachedUiVars.visuals.enemy.altLookingFlag.value.state then
                                        if cheat.class:hasFlag(player.modelStateFlags, cheat.structs.modelStateFlags.headLook) then
                                            local flagColor = draw.cachedUiVars.visuals.enemy.altLookingFlag.value.colorpicker.value.color;
                                            drawRectangle(player.bounds.left - 2 - 4, adjustedTop + startY, 3, 2, flagColor.r, flagColor.g, flagColor.b, player.opacity and player.opacity or flagColor.a, true, 1)
                                            startY = startY + 4;
                                        end
                                    end
                                    if draw.cachedUiVars.visuals.enemy.boomFlag.value.state then
                                        if player.hasBoom then
                                            local flagColor = draw.cachedUiVars.visuals.enemy.boomFlag.value.colorpicker.value.color;
                                            drawRectangle(player.bounds.left - 2 - 4, adjustedTop + startY, 3, 2, flagColor.r, flagColor.g, flagColor.b, player.opacity and player.opacity or flagColor.a, true, 1)
                                            startY = startY + 4;
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end;

        drawSkeletonConnection = function(self, player, from, to, r, g, b, a, skeletonBounds, thickness, drawSkeletonLines)
            local fromBone = player:getBonePosition(from);
            local toBone = player:getBonePosition(to);
            if fromBone and toBone and fromBone:isValid() and toBone:isValid() then
                if fromBone:unityDistance(toBone) > 1.3 then
                    return;
                end

                local fromOnScreen = cheat:worldToScreen(fromBone);
                if fromOnScreen then
                    local toOnScreen = cheat:worldToScreen(toBone);
                    if toOnScreen then
                        if drawSkeletonLines then
                            render.draw_line(fromOnScreen.x, fromOnScreen.y, toOnScreen.x, toOnScreen.y, r, g, b, a, thickness)
                        end

                        if to == cheat.structs.bones.lowerNeck then
                            toBone = toBone:add(vector3:create(0,0.18,0));
                        end
        
                        if from == cheat.structs.bones.lowerNeck then
                            fromBone = fromBone:add(vector3:create(0,0.18,0));
                        end

                        fromOnScreen = cheat:worldToScreen(fromBone);
                        if fromOnScreen then
                            toOnScreen = cheat:worldToScreen(toBone);
                            if toOnScreen then
                                local padding = number:scaleValue(10, 150, player.distance, 0.7, 7, true)
                                skeletonBounds.left = math.min(skeletonBounds.left, math.min(fromOnScreen.x, toOnScreen.x) - padding)
                                skeletonBounds.right = math.max(skeletonBounds.right, math.max(fromOnScreen.x, toOnScreen.x) + padding)
                                skeletonBounds.top = math.min(skeletonBounds.top, math.min(fromOnScreen.y, toOnScreen.y) - padding)
                                skeletonBounds.bottom = math.max(skeletonBounds.bottom, math.max(fromOnScreen.y, toOnScreen.y) + padding)
                            end
                        end
                    end
                end
            end


        end;

        drawSkeleton = function(self, player, r, g, b, a, thickness, drawSkeletonLines)
            local skeletonBounds = {
                left = math.huge,   -- Equivalent to FLT_MAX
                top = math.huge,    -- Equivalent to FLT_MAX
                right = -math.huge, -- Equivalent to -FLT_MAX
                bottom = -math.huge -- Equivalent to -FLT_MAX
            }


            if drawSkeletonLines or (draw.cachedUiVars.visuals.other.dynamicBoxes.value.state and not player.isNpc) then
                self:drawSkeletonConnection(player, cheat.structs.bones.lowerNeck, cheat.structs.bones.pelvis, r, g, b, a, skeletonBounds, thickness, drawSkeletonLines);
                self:drawSkeletonConnection(player, cheat.structs.bones.pelvis, cheat.structs.bones.leftHip, r, g, b, a, skeletonBounds, thickness, drawSkeletonLines);
                self:drawSkeletonConnection(player, cheat.structs.bones.pelvis, cheat.structs.bones.rightHip, r, g, b, a, skeletonBounds, thickness, drawSkeletonLines);
                self:drawSkeletonConnection(player, cheat.structs.bones.rightHip, cheat.structs.bones.rightKnee, r, g, b, a, skeletonBounds, thickness, drawSkeletonLines);
                self:drawSkeletonConnection(player, cheat.structs.bones.leftHip, cheat.structs.bones.leftKnee, r, g, b, a, skeletonBounds, thickness, drawSkeletonLines);
                self:drawSkeletonConnection(player, cheat.structs.bones.leftKnee, cheat.structs.bones.leftAnkle, r, g, b, a, skeletonBounds, thickness, drawSkeletonLines);
                self:drawSkeletonConnection(player, cheat.structs.bones.rightKnee, cheat.structs.bones.rightAnkle, r, g, b, a, skeletonBounds, thickness, drawSkeletonLines);
                self:drawSkeletonConnection(player, cheat.structs.bones.lowerNeck, cheat.structs.bones.leftShoulder, r, g, b, a, skeletonBounds, thickness, drawSkeletonLines);
                self:drawSkeletonConnection(player, cheat.structs.bones.lowerNeck, cheat.structs.bones.rightShoulder, r, g, b, a, skeletonBounds, thickness, drawSkeletonLines);
                self:drawSkeletonConnection(player, cheat.structs.bones.leftShoulder, cheat.structs.bones.leftElbow, r, g, b, a, skeletonBounds, thickness, drawSkeletonLines);
                self:drawSkeletonConnection(player, cheat.structs.bones.rightShoulder, cheat.structs.bones.rightElbow, r, g, b, a, skeletonBounds, thickness, drawSkeletonLines);
                self:drawSkeletonConnection(player, cheat.structs.bones.lowerNeck, cheat.structs.bones.pelvis, r, g, b, a, skeletonBounds, thickness, drawSkeletonLines);
            end

            local assignedBounds = false;

            if skeletonBounds and not cheat.entitylist.cr3Fail and (drawSkeletonLines or draw.cachedUiVars.visuals.other.dynamicBoxes.value.state) and not player.lastDrawFail then
                local boxWidth = player.bounds.right - player.bounds.left;
                local boxHeight = player.bounds.bottom - player.bounds.top;

                if boxHeight > 2 and boxWidth > 2 and draw.screenSize.x > boxWidth and draw.screenSize.y > boxHeight then
                    if skeletonBounds.left ~= math.huge and skeletonBounds.left ~= -math.huge and
                        skeletonBounds.top ~= math.huge and skeletonBounds.top ~= -math.huge and
                        skeletonBounds.right ~= math.huge and skeletonBounds.right ~= -math.huge and
                        skeletonBounds.bottom ~= math.huge and skeletonBounds.bottom ~= -math.huge then
                        player.bounds = skeletonBounds
                        player.lastDynamicBoxFail = nil;
                        assignedBounds = true;
                    end
                end
            end

            if not assignedBounds and not cheat.entitylist.cr3Fail and not player.lastDrawFail then
                if not player.lastDynamicBoxFail then
                    player.lastDynamicBoxFail = winapi.get_tickcount64();
                end
                if winapi.get_tickcount64() - player.lastDynamicBoxFail > 60 then
                    player.bounds = player:getBoxBounds();
                end
            end
        end;

        drawLookDirection = function(self, player, r, g, b, a, lineDistance)
            if player.viewAngles then
                if player.isNpc or player.isTeammate or player.isDead or player.distance > 140 then
                    return;
                end

                local headPos = player:getBonePosition(cheat.structs.bones.eyeTransform)
                if headPos and headPos:isValid() then
                    local forwardVector = cheat:angleToVector(player.viewAngles);

                    forwardVector.x = forwardVector.x * lineDistance;
                    forwardVector.y = forwardVector.y * lineDistance;
                    forwardVector.z = forwardVector.z * lineDistance;
                    
                    local forward = headPos:add(forwardVector);
                    local endPoint = cheat:worldToScreen(forward);
                    if endPoint then
                        local startPoint = cheat:worldToScreen(headPos);
                        if startPoint then
                            render.draw_line(startPoint.x, startPoint.y, endPoint.x, endPoint.y, r, g, b, a, 1)
                        end
                    end
                end
            end
        end;

        getPlayerColor = function(self, player)
            if player.isNpc then
                return draw.cachedUiVars.visuals.enemy.nPCBox.value.colorpicker.value.color;
            else
                if player.isTeammate then
                    if player.isKnocked then
                        return draw.cachedUiVars.visuals.team.teammateKnocked.value.colorpicker.value.color;
                    else
                        if player.isSleeping then
                            return draw.cachedUiVars.visuals.team.teammateAsleep.value.colorpicker.value.color;
                        else
                            return draw.cachedUiVars.visuals.team.teammateBox.value.colorpicker.value.color;
                        end
                    end
                else
                    if player.isKnocked then
                        return draw.cachedUiVars.visuals.enemy.playerKnocked.value.colorpicker.value.color;
                    else
                        if player.isSleeping then
                            return draw.cachedUiVars.visuals.enemy.playerAsleep.value.colorpicker.value.color;
                        else
                            if player.isVisible and draw.cachedUiVars.visuals.enemy.playerVisibleCheck.value.state then
                                return draw.cachedUiVars.visuals.enemy.playerVisibleCheck.value.colorpicker.value.color;
                            else
                                return draw.cachedUiVars.visuals.enemy.invisibleColor.value.color;
                            end
                            --return draw.cachedUiVars.visuals.enemy.teammateBox.value.colorpicker.value.color;
                        end
                    end
                end
            end
        end;

        getShouldDrawData = function(self, player)
            local returnData = {};

            if player.isTeammate then
                returnData.shouldBox = draw.cachedUiVars.visuals.team.teammateBox.value.state;
                returnData.shouldName = draw.cachedUiVars.visuals.team.teammateName.value;
                returnData.shouldDistance = draw.cachedUiVars.visuals.team.teammateDistance.value;
                returnData.shouldWeapon = draw.cachedUiVars.visuals.team.teammateWeapon.value;
                returnData.shouldSkeleton = draw.cachedUiVars.visuals.team.teammateSkeleton.value;
                returnData.skeletonDistance = draw.cachedUiVars.visuals.team.maxSkeletonDistance.value
                returnData.maxDistance = draw.cachedUiVars.visuals.team.maxTeammateDistance.value;
            elseif player.isNpc then
                returnData.shouldBox = draw.cachedUiVars.visuals.enemy.nPCBox.value.state;
                returnData.shouldName = draw.cachedUiVars.visuals.enemy.nPCName.value;
                returnData.shouldDistance = draw.cachedUiVars.visuals.enemy.nPCDistance.value;
                returnData.shouldWeapon = draw.cachedUiVars.visuals.enemy.nPCWeapon.value;
                returnData.shouldSkeleton = draw.cachedUiVars.visuals.enemy.nPCSkeleton.value;
                returnData.skeletonDistance = draw.cachedUiVars.visuals.enemy.maxSkeletonDistance.value
                returnData.maxDistance = draw.cachedUiVars.visuals.enemy.maxNPCDistance.value;
            else
                returnData.shouldBox = player.isKnocked and draw.cachedUiVars.visuals.enemy.playerKnockedBox.value.state or not draw.cachedUiVars.visuals.enemy.playerVisibleCheck.value.state and (draw.cachedUiVars.visuals.enemy.playerInvisibleBox.value.state or draw.cachedUiVars.visuals.enemy.playerVisibleBox.value.state) or (draw.cachedUiVars.visuals.enemy.playerVisibleCheck.value.state and (player.isVisible and draw.cachedUiVars.visuals.enemy.playerVisibleBox.value.state or not player.isVisible and draw.cachedUiVars.visuals.enemy.playerInvisibleBox.value.state));
                if player.isSleeping then
                    returnData.shouldBox = true;
                end
                returnData.shouldName = draw.cachedUiVars.visuals.enemy.playerName.value;
                returnData.shouldDistance = draw.cachedUiVars.visuals.enemy.playerDistance.value;
                returnData.shouldWeapon = draw.cachedUiVars.visuals.enemy.playerWeapon.value;
                returnData.shouldSkeleton = draw.cachedUiVars.visuals.enemy.playerSkeleton.value;
                returnData.skeletonDistance = draw.cachedUiVars.visuals.enemy.maxSkeletonDistance.value;
                returnData.maxDistance = draw.cachedUiVars.visuals.enemy.maxPlayerDistance.value;
            end

            return returnData;
        end;

        handlePlayerDraw = function(self)
            self.activeTeams = {};

            for entity, player in pairs(cheat.entitylist.players) do
                if player.teamId then
                    if self.activeTeams[player.teamId] then
                        self.activeTeams[player.teamId] = self.activeTeams[player.teamId] + 1;
                    else
                        self.activeTeams[player.teamId] = 1
                    end
                end
            end

            cheat.radar:drawOverlay();
            cheat.visual.hotbar.playerHotbarReferences = {};
            
            for entity, player in pairs(cheat.entitylist.players) do
                self.bottomYOffset = 0;
                self.topYOffset = 0;

                cheat.radar:addPlayer(player);

                if not player.onScreen then
                    if player.model then
                        cheat.visual.oofArrows:drawPlayer(player);
                    end
                end

                cheat.entitylist:updateCr3Fail();
                if draw.cachedUiVars.visuals.enemy.playerDead.value.state or not player.isDead then
                    if player.position and player.position:isValid() then
                        local shouldDraw = self:getShouldDrawData(player);
                        if player.distance < shouldDraw.maxDistance.state then
                            if player.isKnocked and not player.isNpc then
                                if player.isTeammate then
                                    if not draw.cachedUiVars.visuals.team.teammateKnocked.value.state then
                                        goto endLoop;
                                    end
                                else
                                    if not draw.cachedUiVars.visuals.enemy.playerKnocked.value.state then
                                        goto endLoop;
                                    end
                                end
                            end
                    
                            if player.isSleeping and not player.isNpc then
                                if player.isTeammate then
                                    if not draw.cachedUiVars.visuals.team.teammateAsleep.value.state then
                                        goto endLoop;
                                    end
                                else
                                    if not draw.cachedUiVars.visuals.enemy.playerAsleep.value.state then
                                        goto endLoop;
                                    end
                                end
                            end
                            
                            if player.isDead and not player.isNpc then
                                if player.isTeammate then
                                    if not draw.cachedUiVars.visuals.team.teammateDead.value.state then
                                        goto endLoop;
                                    end
                                else
                                    if not draw.cachedUiVars.visuals.enemy.playerDead.value.state then
                                        goto endLoop;
                                    end
                                end
                            end

                            local bounds = player:getBoxBounds();
                            if bounds then
                                player.lastDrawFail = nil;
                                
                                if draw.cachedUiVars.visuals.other.dynamicBoxes.value.state and not player.isNpc then
                                    if not player.bounds then
                                        player.bounds = bounds;
                                    end
                                else
                                    player.bounds = bounds;
                                end
                            else
                                if not player.lastDrawFail then
                                    player.lastDrawFail = winapi.get_tickcount64();
                                end
                            end

                            if player.bounds and (not player.lastDrawFail or winapi.get_tickcount64() - player.lastDrawFail < 80) then
                                local mainColor = self:getPlayerColor(player);

                                local hadBounds = player.bounds ~= nil;

                                self:drawSkeleton(player, mainColor.r, mainColor.g, mainColor.b, player.opacity and player.opacity or mainColor.a, 1, shouldDraw.shouldSkeleton.state and player.distance and shouldDraw.skeletonDistance.state > player.distance)

                                if shouldDraw.shouldBox then
                                    self:drawBox(player, mainColor.r, mainColor.g, mainColor.b, player.opacity and player.opacity or mainColor.a)
                                end
                                if shouldDraw.shouldName.state then
                                    self:drawName(player, shouldDraw.shouldName.colorpicker.value.color.r, shouldDraw.shouldName.colorpicker.value.color.g, shouldDraw.shouldName.colorpicker.value.color.b, player.opacity and player.opacity or shouldDraw.shouldName.colorpicker.value.color.a)
                                end
                                if shouldDraw.shouldWeapon.state then
                                    self:drawWeapon(player, shouldDraw.shouldWeapon.colorpicker.value.color.r, shouldDraw.shouldWeapon.colorpicker.value.color.g, shouldDraw.shouldWeapon.colorpicker.value.color.b, player.opacity and player.opacity or shouldDraw.shouldWeapon.colorpicker.value.color.a)
                                end
                                if shouldDraw.shouldDistance.state then
                                    self:drawDistance(player, shouldDraw.shouldDistance.colorpicker.value.color.r, shouldDraw.shouldDistance.colorpicker.value.color.g, shouldDraw.shouldDistance.colorpicker.value.color.b, player.opacity and player.opacity or shouldDraw.shouldDistance.colorpicker.value.color.a)
                                end

                                self:drawPlayerFlags(player);
                                
                                if draw.cachedUiVars.visuals.enemy.playerViewangle.value.state then
                                    self:drawLookDirection(player ,draw.cachedUiVars.visuals.enemy.playerViewangle.value.colorpicker.value.color.r, draw.cachedUiVars.visuals.enemy.playerViewangle.value.colorpicker.value.color.g, draw.cachedUiVars.visuals.enemy.playerViewangle.value.colorpicker.value.color.b, player.opacity and player.opacity or draw.cachedUiVars.visuals.enemy.playerViewangle.value.colorpicker.value.color.a, draw.cachedUiVars.visuals.enemy.viewangleLineDistance.value.state);
                                end

                                if not player.isDead and not player.isNpc and not player.isDormant and not player.isTeammate then
                                    if draw.cachedUiVars.visuals.enemy.playerHotbar.value.state then
                                        if #cheat.visual.hotbar.playerHotbarReferences < draw.cachedUiVars.visuals.enemy.maxPlayers.value.state then
                                            local fov = cheat.aimbot:calculateFov(player.midPosition);
                                            if fov < draw.cachedUiVars.visuals.enemy.hotbarFov.value.state then
                                                table.insert(cheat.visual.hotbar.playerHotbarReferences, player);
                                            end

                                        end
                                    end
                                end
                                
                                if player.isNpc then
                                    --self.hotbar:drawHotbar(player);
                                end
                            end
                        end   
                    end
                end

                --[[if player.distance < draw.cachedUiVars.visuals.maxPlayerDistance.value.state then
                    if not player.bounds or player.rootPosition or not draw.cachedUiVars.visuals.dynamicBoxes.value.state then
                        player.bounds = player:getBoxBounds();
                    end

                    if player.bounds then
                        if player.position then
                            if player.position:isValid() then
                                if not player.isTeammate then
                                    if not player.isDying then
                                        local drawSkeletonLines = false;
                                        local skeletonColor = draw.cachedUiVars.visuals.invisiblePlayerSkeleton.value.colorpicker.value.color;

                                        if player.distance < draw.cachedUiVars.visuals.maxSkeletonDistance.value.state then
                                            if draw.cachedUiVars.visuals.visiblePlayerSkeleton.value.state and player.isVisible then
                                                skeletonColor = draw.cachedUiVars.visuals.visiblePlayerSkeleton.value.colorpicker.value.color;
                                                drawSkeletonLines = true;
                                            elseif draw.cachedUiVars.visuals.invisiblePlayerSkeleton.value.state and not player.isVisible then
                                                drawSkeletonLines = true;
                                            end
                                            if player.isKnocked then
                                                skeletonColor = draw.cachedUiVars.visuals.playerKnocked.value.color;
                                            end
                                        end

                                        self:drawSkeleton(player, skeletonColor.r, skeletonColor.g, skeletonColor.b, skeletonColor.a, 1, drawSkeletonLines);
                                        
                                        if player.bounds then
                                            if draw.cachedUiVars.visuals.playerInvisibleBox.value.state and not player.isVisible or draw.cachedUiVars.visuals.playerVisibleBox.value.state and player.isVisible then
                                                local boxColor = draw.cachedUiVars.visuals.playerInvisibleBox.value.colorpicker.value.color;
                                                
                                                if player.isKnocked then
                                                    boxColor = draw.cachedUiVars.visuals.playerKnocked.value.color;
                                                elseif player.isVisible then
                                                    boxColor = draw.cachedUiVars.visuals.playerVisibleBox.value.colorpicker.value.color;
                                                end

                                                self:drawBox(player, boxColor.r,boxColor.g,boxColor.b,boxColor.a);
                                            end

                                            if draw.cachedUiVars.visuals.playerWeapon.value.state then
                                                local weaponColor = draw.cachedUiVars.visuals.playerWeapon.value.colorpicker.value.color;

                                                if draw.cachedUiVars.visuals.weaponRarityColor.value.state and player.heldWeapon and player.heldWeapon.rarity then
                                                    local rarityIndex = cheat.structs.weaponRarities[player.heldWeapon.rarity];
                                                    if rarityIndex then
                                                        weaponColor = rarityIndex.color;
                                                        weaponColor.a = draw.cachedUiVars.visuals.playerWeapon.value.colorpicker.value.color.a;
                                                    end
                                                end

                                                self:drawWeapon(player, weaponColor.r,weaponColor.g,weaponColor.b,weaponColor.a);
                                            end

                                            if draw.cachedUiVars.visuals.playerDistance.value.state then
                                                local distanceColor = draw.cachedUiVars.visuals.playerDistance.value.colorpicker.value.color;
                                                self:drawDistance(player, distanceColor.r,distanceColor.g,distanceColor.b,distanceColor.a);
                                            end

                                            if draw.cachedUiVars.visuals.playerName.value.state then
                                                local nameColor = draw.cachedUiVars.visuals.playerName.value.colorpicker.value.color;
                                                self:drawName(player, nameColor.r,nameColor.g,nameColor.b,nameColor.a);
                                            end
                                            
                                            self:drawPlayerFlags(player);
                                        end
                                    end
                                end
                            end
                        end
                    end
                end]]

                    ::endLoop::
            end

            cheat.radar:addPlayer(cheat.client.localplayer, true);
            self.hotbar:drawHotbars();
        end;

        misc = {
            drawOther = function(self, screenPosition, text, entity)
                local color = entity.prefabData.getColor();
                local entityColor = {r = color.r, g = color.g, b = color.b, a = color.a};

                if draw.cachedUiVars.visuals.other.fadeOutEsp.value.state then
                    entityColor.a = number:scaleValue(entity.prefabData.getDistance()*0.22, entity.prefabData.getDistance()*0.7, entity.distance, 255, 85, false);
                end

                if draw.cachedUiVars.visuals.other.worldEspDistance.value.state == 1 then
                    drawText(draw.fonts.entityText, text .. " [" .. math.floor(entity.distance) .. "M]", screenPosition.x,screenPosition.y, entityColor.r,entityColor.g,entityColor.b,entityColor.a, draw.cachedUiVars.visuals.other.outlines.value.state, true, false, entityColor.a)
                elseif draw.cachedUiVars.visuals.other.worldEspDistance.value.state == 2 then
                    drawText(draw.fonts.entityText, text, screenPosition.x,screenPosition.y - ((draw.fonts.entityText.height or 0)/2), entityColor.r,entityColor.g,entityColor.b,entityColor.a, draw.cachedUiVars.visuals.other.outlines.value.state, true, false, entityColor.a)
                    drawText(draw.fonts.entityText, "[" .. math.floor(entity.distance) .. "M]", screenPosition.x,screenPosition.y + ((draw.fonts.entityText.height or 0)/2), entityColor.r,entityColor.g,entityColor.b,entityColor.a, draw.cachedUiVars.visuals.other.outlines.value.state, true, false, entityColor.a)
                else
                    drawText(draw.fonts.entityText, text, screenPosition.x,screenPosition.y, entityColor.r,entityColor.g,entityColor.b,entityColor.a, draw.cachedUiVars.visuals.other.outlines.value.state, true, false, entityColor.a)
                end
            end;

            fuelMonitor = {
                currentFuel = 0;
    
                monitor = function(self)
                    if draw.cachedUiVars.misc.lowFuelWarning.value.state and not cheat.client.localplayer.isDead then
                        if cheat.client.localplayer.mounted and cheat.client.localplayer.mounted.entity ~= 0 then
                            local currentTime = winapi.get_tickcount64();
                            if currentTime > (self.lastMonitorCheck or 0) + 3000 then
                                for key, value in pairs(cheat.entitylist.others) do
                                    if (value.prefabData.name == "MINI" or value.prefabData.name == "SCRAP HELI" or value.prefabData.name == "COMBAT HELI") and 2.4 > value.distance and not value:getIsDestroyed() then
                                        self.currentFuel = value:getFuelGauge()*100;
                                        break;
                                    end
                                end;
    
                                self.lastMonitorCheck = currentTime;
                            end
    
                            local color = draw.cachedUiVars.misc.lowFuelWarning.value.colorpicker.value.color;
    
                            if self.currentFuel > 0 and 60 > self.currentFuel then
                                drawText(draw.fonts.fuelText.font, "LOW FUEL: " .. math.floor(self.currentFuel), draw.screenSize.x / 2, (draw.screenSize.y * (140 / 1080)), color.r, color.g, color.b, color.a, true, true)
                            end
                        end
                    end
                end;
            };

            callbacks = {
                ore = function(entity, screenPosition)
                    if draw.cachedUiVars.visuals.loot.meleeEquippedOnly.value.state then
                        if cheat.client.localplayer.isMelee then
                            return true;
                        else
                            return false;
                        end
                    end
    
                    return true;
                end;
    
                cctv = function(entity, screenPosition)
                    if not entity.flagTimer then
                        entity.flagTimer = timer.new();
                    end

                    if entity.flagTimer.check(10000) then
                        entity.flags = entity:getFlags()
                    end
                    
                    if entity.flags then
                        if cheat.class:hasFlag(entity.flags, 2048) then
                            return true;
                        end    
                    end
                    
                    return false;
                end;
    
                corpse = function(entity, screenPosition)
                    if not entity.ownerName then
                        if entity.prefabName == "item_drop_backpack" then
                            entity.ownerName = cheat.class.droppedItemContainer:create(entity.entity):getClassName();
                        elseif entity.prefabName == "player_corpse" or entity.prefabName == "player_corpse_new" then
                            entity.ownerName = string.upper(std:cleanseName(cheat.class.lootableCorpse:create(entity.entity):getPlayerName()));
                        end
                    end
    
                    if entity.ownerName then
                        cheat.visual.misc:drawOther(screenPosition, (entity.ownerName or "?") .. " "   .. entity.prefabData.name, entity);
                        return false;
                    end
    
                    return true;
                end;
    
                bradley = function(entity, screenPosition)
                    if not entity.timer then
                        entity.timer = timer.new();
                    end

                    if entity.timer.check(1500) then
                        entity.health = entity:getHealth()
                    end
    
                    if entity.health and entity.health > 0.01 then
                        local startPos = draw.fonts.entityText.height + 3;
    
                        if draw.cachedUiVars.visuals.other.worldEspDistance.value.state == 2 then
                            startPos = startPos + (draw.fonts.entityText.height/2)
                        end
    
                        local mainHealthWidth = 46.0 * (entity.health / 1000);
                        local healthColor = cheat.visual:calculateHealthColor(entity.health, 1000);
    
                        drawRectangle(screenPosition.x - 23 - 1, screenPosition.y + startPos - 1, 46 + 2, 2 + 2, 0, 0, 0, 255, true, 1)
                        drawRectangle(screenPosition.x - 23, screenPosition.y + startPos, mainHealthWidth, 2, healthColor.r, healthColor.g, healthColor.b, 255, true, 1)
                    end
    
                    return true;
                end;
    
                plants = function(entity, screenPosition)
                    --[[if currentTime > (entity.lastCallbackUpdate or 0) + 1000000 then
                        entity.growState = entity:getGrowState()
                        entity.lastCallbackUpdate = currentTime;
                    end
    
                    if entity.growState then
                        Input.SetClipboard(entity.entity)
                        log(entity.growState, ' - ', cheat.process:readFloat(entity.entity + 0x60C))
                    end]]
    
                    return true;
                end;
    
                attackHeli = function(entity, screenPosition)
                    if not entity.timer then
                        entity.timer = timer.new();
                    end
                    
                    if entity.timer.check(1500) then
                        entity.weakSpots = entity:getWeakSpots()
                        --entity.weakSpots.mainHealth = entity.weakSpots.mainHealth * 1.5;
                        --entity.weakSpots.tailHealth = entity.weakSpots.tailHealth * 1.5;
                    end
    
                    --[[local heliAi = cheat.process:readInt64(entity.entity + 0x370); --private PatrolHelicopterAI %ff589f59297288043e309dafba3b22f2046fd81d; // 0x370
    
                    if heliAi ~= 0 then
                        local targetVector = cheat.process:readVector3(heliAi + 0x20);
                        log(targetVector.x, " - ", targetVector.y, " - ", targetVector.z)
                    else
                        log('fuckfuckfuck')
                    end
    
                    Input.SetClipboard(entity.entity + 0x370)]]
                    
                    if entity.weakSpots then
                        local didMain = false;
    
                        local startPos = draw.fonts.entityText.height + 3;
    
                        if draw.cachedUiVars.visuals.other.worldEspDistance.value.state == 2 then
                            startPos = startPos + (draw.fonts.entityText.height/2)
                        end

                        local barWidth = 70;
    
                        if entity.weakSpots.mainHealth and entity.weakSpots.mainMaxHealth and entity.weakSpots.mainHealth > 0.01 then
                            didMain = true
                            -- Clamp the mainHealthWidth to avoid going out of bounds
                            --local mainHealthWidth = math.min(80.0 * ((entity.weakSpots.mainHealth * 1.52) / entity.weakSpots.mainMaxHealth), 80)
                            local mainHealthWidth = math.min(barWidth * ((entity.weakSpots.mainHealth * 1.52) / entity.weakSpots.mainMaxHealth), barWidth)
                            local healthColor = cheat.visual:calculateHealthColor(entity.weakSpots.mainHealth, entity.weakSpots.mainMaxHealth)
                        
                            drawRectangle(screenPosition.x - 35 - 1, screenPosition.y + startPos - 1, barWidth + 2, 2 + 2, 0, 0, 0, 255, true, 1)
                            drawRectangle(screenPosition.x - 35, screenPosition.y + startPos, mainHealthWidth, 2, healthColor.r, healthColor.g, healthColor.b, 255, true, 1)
                        end
                        
                        if entity.weakSpots.tailHealth and entity.weakSpots.tailMaxHealth and entity.weakSpots.tailHealth > 0.01 then
                            -- Clamp the tailHealthWidth to avoid going out of bounds
                            local tailHealthWidth = math.min(barWidth * ((entity.weakSpots.tailHealth * 1.52) / entity.weakSpots.tailMaxHealth), barWidth)
                            local healthColor = cheat.visual:calculateHealthColor(entity.weakSpots.tailHealth, entity.weakSpots.tailMaxHealth)
                        
                            drawRectangle(screenPosition.x - 35 - 1, screenPosition.y + (didMain and (startPos + 6) or startPos) - 1, barWidth + 2, 2 + 2, 0, 0, 0, 255, true, 1)
                            drawRectangle(screenPosition.x - 35, screenPosition.y + (didMain and (startPos + 6) or startPos), tailHealthWidth, 2, healthColor.r, healthColor.g, healthColor.b, 255, true, 1)
                        end
                    end
    
                    return true;
                end;
    
                helicopters = function(entity, screenPosition)
                    --log('diff: ', (currentTime - entity.lastFound))
                    --if currentTime > entity.lastFound then
                    
                    if entity.isDestroyed then
                        if entity.distance > 150 then
                            entity.grid = entity.grid or cheat.class.world:getGrid(entity.position);
                            cheat.visual.misc:drawOther(screenPosition, entity.prefabData.name .. " [" .. entity.grid .. "]", entity);
                        end
                        return false;
                    end
                    
                    return true;
                end;
    
                samsite = function(entity, screenPosition)
                    local onlineOnly = draw.cachedUiVars.visuals.traps.samsiteOptions.value.options[1].value;
                    local drawState = draw.cachedUiVars.visuals.traps.samsiteOptions.value.options[2].value;
    
                    --[[if cheat.misc.powerSources.highlightedTraps[entity.entity] then
                        
                    elseif (cheat.misc.powerSources.pressedTime or 0) + cheat.misc.powerSources.informationTime > currentTime then
                        return false;
                    end]]
    
                    if onlineOnly or drawState then
                        if not entity.timer then
                            entity.timer = timer.new();
                        end
                        
                        if entity.timer.check(4000) then
                            entity.flags = entity:getFlags()
                            entity.isOnline = cheat.class:hasFlag(entity.flags, 65536);
                        end
    
                        if not entity.isOnline --[[and not cheat.misc.powerSources.highlightedTraps[entity.entity]] then
                            return false;
                        end
    
                        if drawState then
                            cheat.visual.misc:drawOther(screenPosition, entity.prefabData.name .. " [" .. (entity.isOnline and "ON" or "OFF") .. "]", entity);
                            return false;
                        end
                    end
    
                    return true;
                end;
    
                turret = function(entity, screenPosition)
                    local onlineOnly = draw.cachedUiVars.visuals.traps.turretOptions.value.options[1].value;
                    local drawState = draw.cachedUiVars.visuals.traps.turretOptions.value.options[2].value;
                    
                    --[[if cheat.misc.powerSources.highlightedTraps[entity.entity] then
                        
                    elseif (cheat.misc.powerSources.pressedTime or 0) + 10000 > currentTime then
                        return false;
                    end]]
    
                    if onlineOnly or drawState then
                        if not entity.timer then
                            entity.timer = timer.new();
                        end
                        
                        if entity.timer.check(2000) then
                            entity.flags = entity:getFlags()
                            entity.isOnline = cheat.class:hasFlag(entity.flags, cheat.structs.entityFlags.on);
                        end
    
                        if onlineOnly then
                            if not entity.isOnline --[[and not cheat.misc.powerSources.highlightedTraps[entity.entity]] then
                                return false;
                            end
                        end
                        
                        if drawState then
                            cheat.visual.misc:drawOther(screenPosition, entity.prefabData.name .. " [" .. (entity.isOnline and "ON" or "OFF") .. "]", entity);
                            return false;
                        end
                    end
                    
                    return true;
                end;
    
                apcCrate = function(entity, screenPosition)
                    if not entity.timer then
                        entity.timer = timer.new();
                    end
                    
                    if entity.timer.check(2000) then
                        entity.flags = entity:getFlags()
                        entity.isOnFire = cheat.class:hasFlag(entity.flags, cheat.structs.entityFlags.onFire);
                    end
    
                    if entity.isOnFire then
                        cheat.visual.misc:drawOther(screenPosition, entity.prefabData.name .. (entity.isOnFire and " [FIRE]" or ""), entity);
                        return false;
                    end;
    
                    return true;
                end;
    
                hackableCrate = function(entity, screenPosition)
                    if not entity.timer then
                        entity.timer = timer.new();
                    end
                    
                    if entity.timer.check(1000) then
                        if not entity.isFullyHacked then
                            if entity.isBeingHacked then
                                local screenText = entity:getText();
                                if screenText and screenText ~= 0 then
                                    entity.time = (string.upper(screenText:getString())) or "?";
                                end
                            end
                            entity.flags = entity:getFlags()
                            entity.isBeingHacked = cheat.class:hasFlag(entity.flags, 128);
                            entity.isFullyHacked = cheat.class:hasFlag(entity.flags, 256);
                        end
                    end
    
                    if entity.isFullyHacked or entity.isBeingHacked then
                        cheat.visual.misc:drawOther(screenPosition, entity.prefabData.name .. (entity.isFullyHacked and " [HACKED]" or (" [" .. (entity.time or "HACKING") .. "]")), entity);
                        return false;
                    end
    
                    return true;
                end;
            };

            handleOtherDraw = function(self)
                for entity, other in pairs(cheat.entitylist.others) do
                    if other.prefabData.getShouldDraw() then
                        if other.distance and other.distance < other.prefabData.getDistance() then
                            if other.position and other.position:isValid() then

                                local onScreen = cheat:worldToScreen(other.position);
                                if onScreen then
                                    other.lastDrawFail = nil;
                                    other.screenPosition = onScreen;
                                else
                                    if not other.lastDrawFail then
                                        other.lastDrawFail = winapi.get_tickcount64();
                                    end
                                end

                                if other.screenPosition and (not other.lastDrawFail or winapi.get_tickcount64() - other.lastDrawFail < 80) then
                                    
                                    if not other.prefabData.callback or other.prefabData.callback()(other, other.screenPosition) then
                                        self:drawOther(other.screenPosition, other.prefabData.name, other);
                                    end
                                end
                            end
                        end
                    end
                end
            end;
        };
    };

    server = {
        mapSize = 0;

        updateServer = function(self)

            
            if not cheat.offsets.world.staticClass then
                cheat.offsets.world.class = cheat.process:readInt64(cheat.process.modules.gameAssembly.base + cheat.offsets.world.offset);
                if cheat.offsets.world.class ~= 0 then
                    cheat.offsets.world.staticClass = cheat.process:readInt64(cheat.offsets.world.class + 0xb8);
                end
            end
    
            if cheat.offsets.world.staticClass and cheat.offsets.world.staticClass ~= 0 then
                --0x340
                --for i = 0, 0x360 do
                    
                --end
                local world = cheat.class.world:create(cheat.offsets.world.staticClass);

                self.mapSize = world:getMapSize();
                --self.mapSeed = world:getMapSeed();
                --self.mapUrl = world:getMapUrl();
            else
                return self:resetServerData();
            end;    

            self.connectedAddress = nil;
            local network = cheat.class.net:getStaticInstance();
            if network then
                self.connectedAddress = network:getConnectedIp();
                    --[[self.connectedAddress = self.client:getConnectedAddress();
                    self.connectedPort = self.client:getConnectedPort();
                    self.serverName = self.client:getServerName();]]
                
                --[[if self.mapUrl and string.len(self.mapUrl) > 2 then
                    self.isCustom = true;
                    self.customUrl = self:getRustmapsId(self.mapUrl or "?");
                else
                    self.isCustom = false;
                end]]
            end
        end;

        resetServerData = function(self)
            self.mapSize = 0;
            self.mapSeed = 0;
            self.mapUrl = nil;
            self.mapSeed = 0;
            self.mapSize = 0;
            self.connectedAddress = nil;
            self.connectedPort = 0;
            self.isCustom = false;
            self.customUrl = nil;
            self.serverName = nil;
        end;
    };

    entitylist = {
        --engineDataTimer = timer.new();
        loopEntitiesTimer = timer.new();
        decryptionPointerTimer = timer.new();
        players = {};
        others = {};
        ignoredPointers = {};
        cr3Fail = false;

        handlePlayerAlert = function(self, player)
            if 2000 > (winapi.get_tickcount64() - loadTime) then
                --notifications:add("called", 5000)
                return;
            end

            local shouldBot = draw.cachedUiVars.misc.alerts.value.options[3].value;
            local shouldm2minigun = draw.cachedUiVars.misc.alerts.value.options[1].value;
            local shouldBoom = draw.cachedUiVars.misc.alerts.value.options[2].value;

            if player.isSleeping or player.isTeammate then
                return;
            end;

          
            if player.isBot and shouldBot then
                notifications:add("Bot named " .. (player.name or "?") .. " has spawned " .. cheat:getCompassDirection(cheat.client.cameraPosition, player.position), 5000);
            end

            if not player.isBot and not player.isNpc and (shouldm2minigun or shouldBoom) then
                local children = player:getChildren();
                if children and children ~= 0 then
                    local listSize = cheat.class.itemList:getSize(children);
                    if listSize ~= 0 and 1000 > listSize then
                        local itemL = cheat.class.itemList:getItemList(children);
                        if itemL ~= 0 then
                            local alertString = "";
                            for i = 0, (listSize - 1) do
                                local child = cheat.class.baseEntity:create(cheat.process:readInt64(itemL + 0x20 + (i * 0x8)));
                                if child ~= 0 and not child:getIsDestroyed() then
                                    local prefabUid = child:getPrefabUid();
                                    if prefabUid == 601440135 and shouldBoom then
                                        alertString = alertString .. " Launcher"
                                    end
                                    if prefabUid == 1915331115 and shouldBoom then
                                        alertString = alertString .. " C4"
                                    end
                                    if prefabUid == 3046924118 and shouldBoom then
                                        alertString = alertString .. " Rocket"
                                    end
                                    if prefabUid == 1440914039 and shouldm2minigun then
                                        alertString = alertString .. " M249"
                                    end
                                end

                            end
                            if alertString ~= "" then
                                notifications:add((player.name or "?") .. " Spawned " .. cheat:getCompassDirection(cheat.client.cameraPosition, player.position) .. " with" .. alertString, 5000);
                            end
                        end
                    end
                end
            end
        end;

        updateCr3Fail = function(self)
            local readValue = cheat.process:readInt64(cheat.process.modules.gameAssembly.base + cheat.offsets.todSky.offset)

            if not self.originalTodSky and readValue ~= 0 then
                self.originalTodSky = readValue;
            end

            local originalDigits = tostring(self.originalTodSky):len()
            local currentDigits = tostring(readValue):len()

            if currentDigits < originalDigits then
                self.cr3Fail = true
            else
                self.cr3Fail = false
            end

            return self.cr3Fail;
        end;

        scientistClassnames = {
            ["scientistnpc_arena"] = {},
            ["scientistnpc_bradley"] = {},
            ["scientistnpc_cargo"] = {},
            ["scientistnpc_cargo_turret_any"] = {},
            ["scientistnpc_cargo_turret_lr300"] = {},
            ["scientistnpc_excavator"] = {},
            ["scientistnpc_full_any"] = {},
            ["scientistnpc_full_lr300"] = {},
            ["scientistnpc_full_mp5"] = {},
            ["scientistnpc_full_pistol"] = {},
            ["scientistnpc_full_shotgun"] = {},
            ["scientistnpc_junkpile_pistol"] = {},
            ["scientistnpc_oilrig"] = {},
            ["scientistnpc_patrol"] = {},
            ["scientistnpc_roam"] = {},
            ["scientistnpc_roamtethered"] = {},
            ["npc_tunneldweller"] = {},
            ["npc_tunneldwellerspawned"] = {},
            ["npc_underwaterdweller"] = {},
            ["scientistnpc_bradley_heavy"] = { name = "HEAVY NPC" },
            ["scientistnpc_heavy"] = { name = "HEAVY NPC" },
            ["scientistnpc_roam_nvg_variant"] = { name = "NVG NPC" },
        };

        updateEngineData = function(self)
            
        end;

        updateData = function(self)        
            if self:updateCr3Fail() then
                return
            end
        
            for entity, player in pairs(self.players) do
                local isDestroyed = player:getIsDestroyed();
                if isDestroyed then
                    player.isDestroyed = true;
                end

                if not player.isDestroyed then
                    player.bonePositions = {};
                    player.lingerFailTime = nil;
                    player.opacity = nil;
                    player.isDormant = false;
                    player.isDead = player:getIsDead();

                    if player.model then
                        local position = player.model:getPosition();
                        if position and position:isValid() then
                            player.viewAngles = player.model:getLookAngles();
                            if player.viewAngles and player.viewAngles:isValid() then
                                player.viewAngles = player.viewAngles:calculateEulerAngle();
                            end
                            player.position = position;
                            player.midPosition = player.position:add(vector3:create(0,0.7,0));
                            player.isTeammate = player.teamId ~= 0 and player.teamId == cheat.client.localplayer.teamId; 
                            player.onScreen = cheat:worldToScreen(player.position:add(vector3:create(0,1.1,0)));
                            player.playerFlags = player:getPlayerFlags();
                            if player.modelState then
                                player.modelStateFlags = player.modelstate:getFlags();
                            else
                                player.modelStateFlags = 0;
                            end

                            player.isVisible = player.model:getIsVisible();

                            if cheat.class:hasFlag(player.playerFlags, 4) or cheat.class:hasFlag(player.playerFlags, 32) or cheat.class:hasFlag(player.playerFlags, 128) then
                                player.hasAdminFlag = true;
                            end

                            player.isKnocked = cheat.class:hasFlag(player.playerFlags, cheat.structs.playerFlags.wounded);
                            player.isSleeping = cheat.class:hasFlag(player.playerFlags, cheat.structs.playerFlags.sleeping);

                            if not player.isDead then
                                if not player.weaponTimer then
                                    player.weaponTimer = timer:new();
                                end

                                if player.weaponTimer.check(250) then
                                    local updatedWeapon = false;

                                    local item = player:getHeldItem();
                                    if item then
                                        if not player.heldEntity or item.entity ~= player.heldEntity.heldEntity.entity then
                                            local itemDef = item.item:getItemDefinition();
                                            if itemDef then
                                                local displayName = itemDef:getDisplayName();
                                                if displayName and string.len(displayName) > 0 then
                                                    player.heldEntity = item;
                                                    player.heldWeaponName = displayName;
                                                    updatedWeapon = true;
                                                end
                                            end
                                        end
                                    end

                                    if not updatedWeapon then
                                        player.heldEntity = nil;
                                        player.heldWeaponName = "";
                                    end
                                end

                                if not cheat.class:hasFlag(player.playerFlags, 16) then

                                end
                            end

                            if not player.notified then
                                player.notified = true;
                                cheat.entitylist:handlePlayerAlert(player);
                            end
                        end
                    end
                else
                    self:removePlayer(entity);
                end

                if player.position then
                    player.distance = cheat.client.cameraPosition:unityDistance(player.position);
                end
            end

            if self:updateCr3Fail() then
                return
            end

            for entity, other in pairs(self.others) do
                if not other.transform then
                    other.transform = other:getGameObjectTransform()
                end

                local isDestroyed = other:getIsDestroyed();
                if isDestroyed then
                    other.isDestroyed = true;
                end

                if not other.isDestroyed then
                    if other.transform ~= 0 then
                        if other.prefabData.getShouldDraw() or other.prefabData.sendRadar and other.prefabData.sendRadar() then
                            local didRestart = false;
                            ::restartPosition::
                            if not other.updateRateTimer then
                                other.updateRateTimer = timer.new();
                            end

                            if not other.position or other.prefabData.updateRate == -1 or other.prefabData.updateRate < 16 or other.updateRateTimer.check(other.prefabData.updateRate or 30) or other.parentEntity then
                                if other.prefabData.updateRate ~= -1 or not other.position or other.parentEntity then
                                    local position = cheat.process:readTransformPosition(other.transform)
                                    if position and position:isValid() then
                                        other.position = position;
                                        other.distance = cheat.client.cameraPosition:unityDistance(other.position)
                                        other.lastPositionFail = nil;
                                    else
                                        if not other.lastPositionFail then
                                            other.lastPositionFail = winapi.get_tickcount64();
                                        end

                                        if winapi.get_tickcount64() - other.lastPositionFail > 100 then
                                            local transform = other:getGameObjectTransform();
                                            if transform ~= 0 then
                                                local trasnformPosition = cheat.process:readTransformPosition(transform)
                                                if trasnformPosition and trasnformPosition:isValid() and not didRestart then
                                                    other.transform = transform;
                                                    didRestart = true
                                                    goto restartPosition;
                                                end
                                            end
                                        end
                                    end
                                end
                            end

                            if other.position then
                                other.distance = cheat.client.cameraPosition:unityDistance(other.position);
                            end
                        end 
                    end
                else
                    if other.position then
                        other.distance = cheat.client.cameraPosition:unityDistance(other.position)
                    end

                    self:removeOther(entity);
                end
            end
        end;

        removePlayer = function(self, player, ignoreCheck)
            local index = self.players[player];

            if not index then return end;

            if not index.lingerFailTime then
                index.lingerFailTime = winapi.get_tickcount64();
            end

            local timeDiff = winapi.get_tickcount64() - index.lingerFailTime;

            if timeDiff < 8000 and not ignoreCheck and not cheat.client.localplayer.isDead then
                index.opacity = number:scaleValue(0, 8000, timeDiff, 150, 0, false);
                index.isDormant = true;
                return;
            end

            self.players[player] = nil;
        end;

        removeOther = function(self, other)
            local index = self.others[other];

            if not index then return end;

            if index.prefabData.lingerTime then
                if not index.lingerFailTime then
                    index.lingerFailTime = winapi.get_tickcount64();
                end

                local timeDiff = winapi.get_tickcount64() - index.lingerFailTime;

                if timeDiff > index.prefabData.lingerTime() then
                    if timeDiff - index.prefabData.lingerTime() > 3000 then
                        index.lingerFailTime = winapi.get_tickcount64();
                        return;
                    else

                    end
                else
                    return;
                end
            end

            self.others[other] = nil;
        end;

        setupDecryptionPointers = function(self)
            if self.entityListPointer then
                return true;
            end

            if self.decryptionPointerTimer.check(2000) then
                local findPlayerList = false;

                ::repeatDecryption::

                for i=0, 10000 do
                    local handle = cheat.decryption:il2cppGetHandle(i);

                    if handle and handle ~= 0 then
                        local handleEntity = cheat.class.baseEntity:create(handle);
                        local handleClassname = handleEntity:getClassName();
                        local prefix = "%"
                        if handleClassname and string.len(handleClassname) > 5 and string.sub(handleClassname, 1, #prefix) == prefix then
                            for j = 0, 32, 4 do
                                local randomRead = cheat.process:readInt64(handle + j);
                                if randomRead and randomRead ~= 0 then

                                    if not self.listPtrOffset then
                                        self.listPtrOffset = 0x10;
                                        self.listSizeOffset = 0x18;
                                    end
                                    
                                    local entitySize = cheat.process:readInt64(randomRead + self.listSizeOffset); --changes sometimes?
                                    local enityArrayPtr = cheat.process:readInt64(randomRead + self.listPtrOffset);

                                    if enityArrayPtr ~= 0 and entitySize > 0 and 99999 > entitySize then

                                    else
                                        entitySize = cheat.process:readInt64(randomRead + self.listPtrOffset); --changes sometimes?
                                        enityArrayPtr = cheat.process:readInt64(randomRead + self.listSizeOffset);
                                        if enityArrayPtr ~= 0 and entitySize > 0 and 99999 > entitySize then
                                            local listSizeOffset = self.listSizeOffset;
                                            local listPtrOffset = self.listPtrOffset;
                                            self.listPtrOffset = listSizeOffset;
                                            self.listSizeOffset = listPtrOffset;
                                        end
                                    end

                                    if enityArrayPtr ~= 0 and entitySize > 0 and 99999 > entitySize then
                                        for randomEntity=0, entitySize do
                                            local foundEntity = cheat.class.baseEntity:create(cheat.process:readInt64(enityArrayPtr + 0x20 + (randomEntity * 8)));
                                            if foundEntity then
                                                if findPlayerList then
                                                    if handle ~= self.entityListPointer then
                                                        local entityClassname = foundEntity:getClassName();
                                                        if randomEntity == 0 then
                                                            if entityClassname == "BasePlayer" or entityClassname == "Localplayer" or entityClassname == "LocalPlayer" then
                                                                self.playerListPointer = handle;
                                                                self.playerListOffset = j;

                                                                return true;
                                                            end
                                                        end
                                                    end
                                                else
                                                    local entityClassname = foundEntity:getClassName();

                                                    if randomEntity == 0 then
                                                        if entityClassname ~= "BasePlayer" and entityClassname ~= "Localplayer" and entityClassname ~= "LocalPlayer" then
                                                            break;
                                                        end
                                                    end

                                                    if entityClassname == "CollectibleEntity" or entityClassname == "BaseProjectile" or entityClassname == "BoxStorage" or entityClassname == "InstrumentTool" or entityClassname == "ElectricGenerator" or entityClassname == "BuildingBlock" or entityClassname == "TreeEntity" or entityClassname == "BushEntity" or entityClassname == "JunkPile" then
                                                        self.entityListPointer = handle;
                                                        self.entityListOffset = j;
                                                        --log("found entitylist ", i, " - ", j);

                                                        --return true;
                                                        findPlayerList = true;
                                                        goto repeatDecryption;
                                                    end
                                                end
                                            else
                                                if randomEntity == 0 then
                                                    break;
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end

                self.entityListPointer = nil;
                self.entityListOffset = nil;

                self.decryptionPointerTimer.update();
            end
        end;

        idToPrefabName = {};
        idIgnoreList = {};

        getCachedPrefabName = function(self, entity, networkId)
            if self.idToPrefabName[networkId] and networkId ~= -1039821371 then
                return self.idToPrefabName[networkId]
            end
        
            local prefabName = entity:getPrefabName()
            if prefabName and prefabName ~= "" then
                local prefabRemoved = prefabName:sub(-7) == ".prefab"
                    and prefabName:sub(1, #prefabName - 7)
                    or prefabName
        
                local lastSlash = prefabRemoved:match("^.*()/")
                local prefabShortened = lastSlash and prefabRemoved:sub(lastSlash + 1) or prefabRemoved
        
                self.idToPrefabName[networkId] = {short = prefabShortened, original = prefabName};
                return self.idToPrefabName[networkId];
            else
                self.idIgnoreList[networkId] = true -- //////////////// could cause problems?
            end
        
            return nil
        end;

        populatePlayerComponents = function(self, player)
            if player.object and player.object ~= 0 then
                cheat:getComponent(player, true, function(object, name)
                    if name == "PlayerEyes" then
                        player.playerEyes = cheat.class.playerEyes:create(object)
                    end
                    if name == "PlayerInventory" then
                        player.playerInventory = cheat.class.playerInventory:create(object)
                    end
                end)
            end

            return player;
        end;

        loopEntities = function(self)
            if cheat.entitylist:updateCr3Fail() then
                self.loopEntitiesTimer.update();
                return;
            end

            if not cheat.entitylist.entityListPointer or cheat.entitylist.entityListPointer == 0 then
                return;
            end

            local playerDictionaryPointer = cheat.process:readInt64(self.playerListPointer + self.playerListOffset);
            local entityDictionaryPointer = cheat.process:readInt64(self.entityListPointer + self.entityListOffset);
            if entityDictionaryPointer ~= 0 then
                local entitySize = cheat.process:readInt64(entityDictionaryPointer + self.listSizeOffset);
                local entityArrayPtr = cheat.process:readInt64(entityDictionaryPointer + self.listPtrOffset);
                local playerSize = cheat.process:readInt64(playerDictionaryPointer + self.listSizeOffset);
                local playerArrayPtr = cheat.process:readInt64(playerDictionaryPointer + self.listPtrOffset);

                local playerCountChanged = false;

                if playerSize > 0 and 10000 > playerSize then
                    if self.lastPlayerSize and self.lastPlayerSize ~= playerSize then
                        playerCountChanged = true;
                        entitySize = playerSize;
                        entityArrayPtr = playerArrayPtr;
                    end

                    self.lastPlayerSize = playerSize
                end

                if not self.loopEntitiesTimer.check(2500) and not playerCountChanged then
                    return false;
                end

                if entityArrayPtr ~= 0 and entitySize > 0 and 99999 > entitySize then
                    for key, value in pairs(self.players) do
                        value.found = false;
                    end

                    for key, value in pairs(self.others) do
                        value.found = false;
                    end

                    for key, value in pairs(self.ignoredPointers) do
                        value.found = false;
                    end

                    proc.read_to_memory_buffer(entityArrayPtr, self.entityBuffer, 0x20 + (entitySize * 8));

                    for randomEntity=0, entitySize do
                        local entityPtr = cheat.class.baseEntity:create(m.read_int64(self.entityBuffer, 0x20 + (randomEntity * 8)))

                        if entityPtr then
                            if randomEntity == 0 then 
                                if not cheat.client.localplayer or cheat.client.localplayer.entity ~= entityPtr.entity then
                                    cheat.client.localplayer = cheat.class.basePlayer:create(entityPtr.entity)
                                end

                                if not cheat.client.localplayer.name then
                                    cheat.client.localplayer.name = "?";
                                    cheat.client.localplayer.name = std:cleanseName(string.upper(cheat.client.localplayer:getName() or "?"));
                                end

                                cheat.client.localplayer.networkableId = cheat.client.localplayer:getNetworkableId();
                                cheat.client.localplayer.teamId = cheat.client.localplayer:getTeamId();

                                if not cheat.client.localplayer.steam64 then
                                    cheat.client.localplayer.steam64 = (cheat.client.localplayer:getUserIdString());
                                    if cheat.client.localplayer.steam64 and string.len(cheat.client.localplayer.steam64) > 2 then
                                        cheat.client.localplayer.steam64Number = tonumber(cheat.client.localplayer.steam64);
                                    end
                                end

                                if cheat.client.localplayer.steam64 then
                                    sendAccountMessage(cheat.client.localplayer.steam64);
                                end

                                cheat.client.localplayer.mounted = cheat.client.localplayer:getMounted();
                                cheat.client.localplayer.model = cheat.client.localplayer:getPlayerModel();
                                cheat.client.localplayer.modelstate = cheat.client.localplayer:getModelState();
                                cheat.client.localplayer.parentEntity = cheat.client.localplayer:getParentEntity();
                                cheat.client.localplayer.playerTeam = cheat.client.localplayer:getPlayerTeam();
                                

                                cheat.client.localplayer.gameObject = cheat.process:readInt64(cheat.client.localplayer.entity + 0x10)
                                if cheat.client.localplayer.gameObject ~= 0 then
                                    cheat.client.localplayer.object = cheat.process:readInt64(cheat.client.localplayer.gameObject + 0x30)
                                end
                                self:populatePlayerComponents(cheat.client.localplayer);
                            else
                                if self.ignoredPointers[entityPtr.entity] == nil then
                                    local networkId = entityPtr:getPrefabUid();

                                    local playerIndex = self.players[entityPtr.entity];
                                    local otherIndex = self.others[entityPtr.entity];

                                    if playerIndex then
                                        if playerIndex.networkId ~= networkId then
                                            self:removePlayer(playerIndex.key);
                                        end
                                    elseif otherIndex then
                                        if otherIndex.networkId ~= networkId then
                                            self:removeOther(otherIndex.key);
                                        end
                                    end

                                    playerIndex = self.players[entityPtr.entity];
                                    otherIndex = self.others[entityPtr.entity];

                                    if not playerIndex and not otherIndex then
                                        local basePlayer =  cheat.class.basePlayer:create(entityPtr.entity);
                                        local prefabName = self:getCachedPrefabName(basePlayer, networkId);
                                        if prefabName then
                                            local isScientist = self.scientistClassnames[prefabName.short];
                                            if prefabName.short == "player" or isScientist then
                                                basePlayer.isNpc = isScientist ~= nil;
                                                if isScientist then
                                                    if isScientist.name then
                                                        basePlayer.name = isScientist.name;
                                                    else
                                                        basePlayer.name = "NPC";
                                                    end
                                                end

                                                local networkableId = basePlayer:getNetworkableId();

                                                for key, value in pairs(self.players) do
                                                    if value.networkableId == networkableId then
                                                        self:removePlayer(key, true);
                                                    end
                                                end;

                                                self.players[basePlayer.entity] = basePlayer;
                                                self.players[basePlayer.entity].networkId = networkId;
                                                self.players[basePlayer.entity].networkableId = networkableId
                                            else
                                                local prefabData = cheat.visual.prefabData[prefabName.short];
                                                if not prefabData then
                                                    prefabData = cheat.visual.prefabData[prefabName.original];
                                                end

                                                if prefabData or draw.cachedUiVars.visuals.other.debugMode.value.state then
                                                    if not draw.cachedUiVars.visuals.other.debugMode.value.state and prefabData.class then
                                                        entityPtr = prefabData.class():create(entityPtr.entity);
                                                    end

                                                    local networkableId = entityPtr:getNetworkableId();

                                                    for key, value in pairs(self.others) do
                                                        if value.networkableId == networkableId then
                                                            self:removeOther(key, true);
                                                        end
                                                    end;

                                                    self.others[entityPtr.entity] = entityPtr;
                                                    self.others[entityPtr.entity].prefabName = prefabName.short;
                                                    
                                                    if draw.cachedUiVars.visuals.other.debugMode.value.state then
                                                        self.others[entityPtr.entity].prefabData = {
                                                            updateRate = 1000;
                                                            name = prefabName.short;
                                                            getDistance = function() return 100; end;
                                                            getColor = function() return draw.cachedUiVars.visuals.other.debugMode.value.colorpicker.value.color; end;
                                                            getShouldDraw = function() return true; end;
                                                        };
                                                    else
                                                        self.others[entityPtr.entity].prefabData = prefabData;
                                                    end
                                                    self.others[entityPtr.entity].networkId = networkId;
                                                    self.others[entityPtr.entity].networkableId = networkableId;
                                                else
                                                    --self.ignoredPointers[entityPtr.entity] = {found = true};
                                                end
                                            end
                                        end
                                    end

                                    playerIndex = self.players[entityPtr.entity];
                                    if playerIndex then
                                        playerIndex.found = true;
                                        playerIndex.model = playerIndex:getPlayerModel();
                                        playerIndex.modelstate = playerIndex:getModelState();

                                        if not playerIndex.name then
                                            playerIndex.name = "?";
                                            playerIndex.name = std:cleanseName(string.upper(playerIndex:getName() or "?"));
                                        end

                                        --[[if playerIndex.model then
                                            if draw.cachedUiVars.visuals.other.skeletonFlickFix.value.state then
                                                local gestureConfig = playerIndex.model:getCurrentGesture();
                                                if gestureConfig then
                                                    playerIndex.model:setIsInGesture(1);
                                                    gestureConfig:setPlayerModelLayer(0);
                                                end
                                            end
                                        end]]


                                        if not playerIndex.isNpc then
                                            playerIndex.teamId = playerIndex:getTeamId()
                                        end

                                        if not playerIndex.steam64 then
                                            playerIndex.steam64 = (playerIndex:getUserIdString());

                                            if playerIndex.steam64 and string.len(playerIndex.steam64) > 2 then
                                                playerIndex.steam64Number = tonumber(playerIndex.steam64);
                                                if not playerIndex.isNpc then
                                                    if playerIndex.steam64Number < 0x989680 then
                                                        playerIndex.isBot = true;
                                                    end
                                                end
                                            end
                                        end

                                        playerIndex.playerTeam = playerIndex:getPlayerTeam();
                                        playerIndex.gameObject = cheat.process:readInt64(playerIndex.entity + 0x10)
                                        if playerIndex.gameObject ~= 0 then
                                            playerIndex.object = cheat.process:readInt64(playerIndex.gameObject + 0x30)
                                        end
                                        
                                        playerIndex.hasBoom = false;
                                        local children = playerIndex:getChildren();
                                        if children and children ~= 0 then
                                            local listSize = cheat.class.itemList:getSize(children);
                                            if listSize ~= 0 and 1000 > listSize then
                                                local itemL = cheat.class.itemList:getItemList(children);
                                                if itemL ~= 0 then
                                                    local alertString = "";
                                                    for i = 0, (listSize - 1) do
                                                        local child = cheat.class.baseEntity:create(cheat.process:readInt64(itemL + 0x20 + (i * 0x8)));
                                                        if child and not child:getIsDestroyed() then
                                                            local prefabUid = child:getPrefabUid();
                                                            if prefabUid == 601440135 and prefabUid == 1915331115 and prefabUid == 3046924118 then
                                                                playerIndex.hasBoom = true;
                                                                break;
                                                            end
                                                        end
                                                    end
                                                end
                                            end
                                        end

                                        self:populatePlayerComponents(playerIndex);
                                    else
                                        otherIndex = self.others[entityPtr.entity]
                                        if otherIndex then
                                            otherIndex.found = true;
                                            otherIndex.parentEntity = otherIndex:getParentEntity();
                                        end
                                    end
                                else
                                    --self.ignoredPointers[entityPtr.entity].found = true;
                                end

                                
                            end
                        end
                    end

                    for key, value in pairs(self.players) do
                        if not value.found then
                            self:removePlayer(key);
                        end
                    end

                    local otherCount = 0;

                    if not playerCountChanged then
                        for key, value in pairs(self.others) do
                            if not value.found then
                                self:removeOther(key);
                                --self.players[key] = nil;
                            end
                        end
                    end

                    for key, value in pairs(self.ignoredPointers) do
                        if not value.found then
                            self.ignoredPointers[key] = nil;
                        end
                    end
                end
            end
        end;

        updateLocalPlayer = function(self)
            if cheat.client.localplayer then
                if cheat.client.localplayer.model then
                    cheat.client.localplayer.isDead = cheat.client.localplayer:getIsDead();
                    local position = cheat.client.localplayer.model:getPosition();
                    if position and position:isValid() then
                        cheat.client.localplayer.bonePositions = {};
                        cheat.client.localplayer.position = position;

                        cheat.client.localplayer.viewAngles = cheat.client.localplayer.model:getLookAngles();
                        if cheat.client.localplayer.viewAngles and cheat.client.localplayer.viewAngles:isValid() then
                            cheat.client.localplayer.viewAngles = cheat.client.localplayer.viewAngles:calculateEulerAngle();
                        end

                        cheat.client.localplayer.isDestroyed = cheat.client.localplayer:getIsDestroyed();
                        if not cheat.client.localplayer.isDestroyed then
                            cheat.client.localplayer.playerFlags = cheat.client.localplayer:getPlayerFlags();
                            cheat.client.localplayer.input = cheat.client.localplayer:getPlayerInput();
                            cheat.client.localplayer.isKnocked = cheat.class:hasFlag(cheat.client.localplayer.playerFlags, cheat.structs.playerFlags.wounded);

                            if not cheat.client.localplayer.weaponTimer then
                                cheat.client.localplayer.weaponTimer = timer:new();
                            end

                            if not cheat.client.localplayer.isDead then
                                local updatedWeapon = false;

                                local item = cheat.client.localplayer:getHeldItem();
                                if item then
                                    
                                    if not cheat.client.localplayer.heldEntity or item.entity ~= cheat.client.localplayer.heldEntity.heldEntity.entity then
                                        if not cheat.client.localplayer.lastWeaponFind then
                                            cheat.client.localplayer.lastWeaponFind = winapi.get_tickcount64();
                                        end
    
                                        if winapi.get_tickcount64() - cheat.client.localplayer.lastWeaponFind > 80 then
                                            local itemDef = item.item:getItemDefinition();
                                            if itemDef then
                                                local displayName = itemDef:getDisplayName();
                                                if displayName and string.len(displayName) > 0 then
                                                    cheat.client.localplayer.heldEntity = item;
                                                    cheat.client.localplayer.heldWeaponName = displayName;
                                                    cheat.recoil:weaponChange();
                                                    cheat.client.localplayer.lastWeaponFind = nil;
                                                    cheat.client.localplayer.itemId = itemDef:getItemId();

                                                    local itemClassname = cheat.client.localplayer.heldEntity.heldEntity:getClassName();
                               
                                                    if itemClassname == "Jackhammer" or itemClassname == "BaseMelee" then
                                                        cheat.client.localplayer.isMelee = true;
                                                    else
                                                        cheat.client.localplayer.isMelee = false;
                                                    end
                                                end
                                            end
                                        end
                                    else
                                        cheat.client.localplayer.lastWeaponFind = nil;
                                    end

                                    cheat.client.localplayer.lastWeaponFail = nil;
                                    updatedWeapon = true;
                                end
                                
                                if not updatedWeapon then
                                    if not cheat.client.localplayer.lastWeaponFail then
                                        cheat.client.localplayer.lastWeaponFail = winapi.get_tickcount64()
                                    else
                                        if winapi.get_tickcount64() - cheat.client.localplayer.lastWeaponFail > 170 then
                                            cheat.client.localplayer.heldEntity = nil;
                                            cheat.client.localplayer.heldWeaponName = "";
                                            cheat.client.localplayer.isMelee = false;
                                        end
                                    end
                                end
                            end
                        else
                            
                        end
                    end
                end
            end

            return false;
        end;

        --[[local tbl = {
            ["mediumBattery"] = {
                updateRate = 10000000;
                name = "MBATTERY";
                getState = function()
                    return draw.cachedUiVars.visuals.other.powerSources.value.state;
                end;
                getColor = function()
                    return draw.cachedUiVars.visuals.other.powerSources.value.colorpicker.value.color;
                end;
                getDistance = function()
                    return 80; -- or whatever variable
                end;
            }
        }]]
    };

    ensureOffset = function(self, offsets)
        for name, offset in pairs(offsets) do
            if type(offset) == "table" then
                if offset.bufferSize and not offset.buffer then
                    --offset.buffer = Memory.Allocate(offset.bufferSize)
                end
    
                if name ~= "pattern" then
                    self:ensureOffset(offset)
                end

                if offset.offset and offset.search then
                    local foundReplacement = false;
                    local replacedSearch = string.gsub(offset.search, "%.", ":");

                    for hardName, hardOffset in pairs(cheat.hardcodedOffsets) do
                        local replacedName = string.gsub(hardName, "%.", ":");
                        if string.lower(replacedName) == string.lower(replacedSearch) then
                            foundReplacement = true
                            offset.offset = hardOffset;
                            break;
                        end
                    end

                    if not foundReplacement then
                        --log("didnt find: ", offset.search);
                    end
                end
            end
        end
    end;

    ensureOffsets = function(self)
        cheat.process = processSetup:createProcess("RustClient.exe", {
            "gameAssembly.dll";
            "user32.dll";
            "unityPlayer.dll"
        }, {
            cr3 = true;

        });
        
        if cheat.process then
            --[[if cheat.waitPattern and not _debug then
                local menuPattern = cheat.process:findPattern(cheat.process.modules.main, cheat.waitPattern.pattern,cheat.waitPattern.mask)
                if menuPattern == 0 then
                    --cheat.waitPattern.failCount = cheat.waitPattern.failCount + 1;
                    watermark.gameStatus = "Waiting For Pattern";
                    cheat.process = nil;
                    return;
                end
            end]]

            watermark.gameStatus = "Waiting";
            cheat.canDoMemory = true;

            if not self.ensured then
                self.ensured = true;
                self:ensureOffset(cheat.offsets);
            end
        end
    end;

    getComponent = function(self, gameObject, findName, callback, ignoreObjectRead)
        local base = 0;
        
        if not gameObject then
            return 0;
        end
        
        if type(gameObject) == "table" then
            if gameObject.object then
                base = gameObject.object;
            else
                local go = cheat.process:readInt64(gameObject.entity + 0x10)
                if go ~= 0 then
                    base = cheat.process:readInt64(go + 0x30)
                end
            end
        else
            if ignoreObjectRead then
                base = gameObject
            else
                local go = cheat.process:readInt64(gameObject + 0x10)
                if go ~= 0 then
                    base = cheat.process:readInt64(go + 0x30)
                end
            end
        end
        
        if base ~= 0 then
            local componentList = cheat.process:readInt64(base + 0x30)

            for i = 0, 35 do
                local currentEntry = cheat.process:readInt64(componentList + (0x10 * i + 0x8))
                if currentEntry ~= 0 then
                    local object = cheat.process:readInt64(currentEntry + 0x28)
                    if object ~= 0 then
                        local namePointer = cheat.process:readInt64(object + 0x0)
                        if namePointer ~= 0 then
                            namePointer = cheat.process:readInt64(namePointer + 0x10)
                            if namePointer ~= 0 then
                                local name = cheat.process:readString(namePointer);
                                if findName == true then
                                    local stop = callback(object, name);
                                    if stop == true then
                                        return;
                                    end
                                else
                                    if name == findName then
                                        return object;
                                    end
                                end
                            end
                        end
                    end
                else
                    break;
                end
            end
        end
    
        return 0;
    end;

    getCompassDirection = function(self, localPlayerPosition, targetPosition)
        local x = ""
        local y = ""
    
        local deltaX = targetPosition.x - localPlayerPosition.x
        local deltaZ = targetPosition.z - localPlayerPosition.z
    
        if math.abs(deltaX) > math.abs(deltaZ) then
            if deltaX > 0 then
                x = "E"
            elseif deltaX < 0 then
                x = "W"
            end
        else
            if deltaZ > 0 then
                y = "N"
            elseif deltaZ < 0 then
                y = "S"
            end
        end
    
        return y .. x;
    end;

    worldToScreen = function(self, EntityPos, ignoreCheck)
        if not cheat.client.viewMatrix then return false end;
        local TransVec = vector3:create(cheat.client.viewMatrix[1][4], cheat.client.viewMatrix[2][4], cheat.client.viewMatrix[3][4])
        local RightVec = vector3:create(cheat.client.viewMatrix[1][1], cheat.client.viewMatrix[2][1], cheat.client.viewMatrix[3][1])
        local UpVec = vector3:create(cheat.client.viewMatrix[1][2], cheat.client.viewMatrix[2][2], cheat.client.viewMatrix[3][2])
        local w = TransVec:dot(EntityPos) + cheat.client.viewMatrix[4][4]
        local overLimit = w < 0.098

        if overLimit then
            return false
        end
        local y = UpVec:dot(EntityPos) + cheat.client.viewMatrix[4][2]
        local x = RightVec:dot(EntityPos) + cheat.client.viewMatrix[4][1]
        local ScreenPos = { x = (draw.screenSize.x / 2) * (1 + x / w), y = (draw.screenSize.y / 2) * (1 - y / w) }
        local inScreen = ScreenPos.x > (0 - 130) and (draw.screenSize.x + 130) > ScreenPos.x and ScreenPos.y > (0 - 130) and (draw.screenSize.y + 130) > ScreenPos.y
        if inScreen or ignoreCheck then
            return ScreenPos
        else
            return false
        end
    end;

    updateCamera = function(self)
        if not cheat.offsets.mainCamera.staticClass then
            cheat.offsets.mainCamera.class = cheat.process:readInt64(cheat.process.modules.gameAssembly.base + cheat.offsets.mainCamera.offset);
            if cheat.offsets.mainCamera.class ~= 0 then
                cheat.offsets.mainCamera.staticClass = cheat.process:readInt64(cheat.offsets.mainCamera.class + 0xb8);
            end
        end

        if cheat.offsets.mainCamera.staticClass and cheat.offsets.mainCamera.staticClass ~= 0 then
            if not self.mainCameraOffset then
                for i=0, 500 do
                    local mainCam = cheat.class.baseEntity:create(cheat.process:readInt64(cheat.offsets.mainCamera.staticClass + i));
                    if mainCam then
                        if mainCam:getClassName() == "Camera" then
                            self.mainCameraOffset = i;
                            break;
                        end
                    end
                end
            end

            if self.mainCameraOffset then
                local mainCam = cheat.process:readInt64(cheat.offsets.mainCamera.staticClass + self.mainCameraOffset);
                if mainCam ~= 0 then
                    local object = cheat.process:readInt64(mainCam + 0x10);
                    if object ~= 0 then
                        local cameraPosition = cheat.process:readVector3(object + cheat.offsets.camera.cameraPosition.offset);
                        if cameraPosition:isValid() then
                            local viewMatrix = cheat.process:readMatrix(object + cheat.offsets.camera.viewMatrix.offset);
                            if viewMatrix:isValid() then

                                if not cheat.entitylist:updateCr3Fail() then
                                    self.lastUpdatedCamera = nil;
                                    self.updatedCamera = true;
                                    cheat.client.cameraPosition = cameraPosition;
                                    cheat.client.viewMatrix = viewMatrix;
                                    cheat.client.pitch = math.asin(-viewMatrix[2][3]) * (180 / math.pi)
                                    cheat.client.yaw = number:atan2(cheat.client.viewMatrix[1][3], cheat.client.viewMatrix[3][3]) * (180 / math.pi);
                                    return;
                                end
                            end
                        end
                    end
                end
            end
        end

        if not self.lastUpdatedCamera then
            self.lastUpdatedCamera = winapi.get_tickcount64();
        end

        if winapi.get_tickcount64() - self.lastUpdatedCamera > 700 then
            self.updatedCamera = false;
        end
    end;

    allocateMemory = function(self)
        vector4.buffer = m.alloc(0x8 * 4);
        vector3.buffer = m.alloc(0x8*3);
        vector2.buffer = m.alloc(0x8*2);
        matrix4x4.buffer = m.alloc(16 * 4);
        cheat.entitylist.entityBuffer = m.alloc(196608);
    end;

    deAllocateMemory = function(self)
        m.free(vector4.buffer);
        m.free(vector3.buffer);
        m.free(vector2.buffer);
        m.free(matrix4x4.buffer);
        m.free(cheat.entitylist.entityBuffer);
    end;

    resetData = function(self)
        cheat.client.viewMatrix = nil;
        cheat.client.localplayer = nil;
        cheat.entitylist.players = {};
        cheat.entitylist.others = {};
        cheat.entitylist.ignoredPointers = {};
        cheat.entitylist.teams = {};
        cheat.server:resetServerData();
        cheat.wasActive = false;
    end;
}

local processCheckTimer = timer.new();

local function onTick()
    if (draw.cachedUiVars == nil or draw.cachedUiVars.visuals == nil) then
        draw:drawStart();
    end
    keyHandler:handle();

    if not cheat.process then
        if processCheckTimer.check(4000) then
            cheat:ensureOffsets();
        end

    end;

    if cheat.process then
        if proc.did_exit() == true then
            --Process.Release(cheat.process.process);
            watermark.gameStatus = "Waiting For Game";
            cheat.process = nil;
            cheat.canDoMemory = false;
            cheat:resetData();
        else
            if not cheat.setupClasses then
                cheat.class:setupClasses();
                cheat.setupClasses = true;
            end
            if cheat.canDoMemory then
                --[[local bit = bitmap:getBitmap("https://cheati.ng/radar/cs/guns/1.png"); --https://files.facepunch.com/rust/item/syringe.medical_512.png
                if bit then
                    log("did find");
                end]]

                --[[if not cheat.dd then
                    cheat.dd = true;
                end

                ]]

                --[[if cheat.debugcamera:setupAddresses() then
                    if not cheat.debug then
                        cheat.debug = true;
                        cheat.d = cheat.debugcamera:injectShellcode();
                        cheat.t = winapi.get_tickcount64();
                    end
                end

                if cheat.d and not cheat.f then
                    if winapi.get_tickcount64() - cheat.t > 750 then
                        cheat.f = true;
                        log("calling shellcode");
                        cheat.debugcamera:invokeShellcode();
                        log("called shellcode");
                    end
                end]]
                

                --[[if not cheat.d then
                    local netRead = cheat.process:readInt64(cheat.process.modules.gameAssembly.base + 197896904);
                    if netRead ~= 0 then
                        local staticClass = cheat.process:readInt64(netRead + 0xB8);
                        if staticClass ~= 0 then
                            cheat.d = true;
                            for i = 0, 150 do
                                local randomRead = cheat.class.baseEntity:create(cheat.process:readInt64(staticClass + i));
                                if randomRead then
                                    local className = randomRead:getClassName();
                                    if className and string.len(className) > 5 and className:sub(1, 1) == "%" then
                                        for i = 0, 0x100 do
                                            local randomStringRead = cheat.process:readIl2cppString(randomRead.entity + i);
                                            if randomStringRead and string.len(randomStringRead) > 2 then
                                                log("str: ", randomStringRead);
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end]]

                if cheat.entitylist:setupDecryptionPointers() then
                    if not cheat.wasActive then
                        cheat.server:updateServer();
                        cheat.wasActive = true;
                    end

                    if not cheat.entitylist:updateCr3Fail() then
                        cheat:updateCamera();
                    end
                    
                    cheat.entitylist:loopEntities();

                    if cheat.updatedCamera then
                        if not cheat.entitylist:updateCr3Fail() then
                            cheat.entitylist:updateLocalPlayer();
                        end

                        if cheat.client.localplayer then
                            cheat.entitylist:updateData();
                            cheat.visual.misc:handleOtherDraw();
                            cheat.visual:handlePlayerDraw();
                            cheat.crosshair:drawCrosshair();
                            cheat.visual.misc.fuelMonitor:monitor();
                            cheat.fullbright:run();

                            if not cheat.client.localplayer.isDead then
                                cheat.recoil:run();
                                cheat.aimbot:run();
                                cheat.visual:drawFov();
                                cheat.adminFlags:run();
                                --cheat.nospread:run();
                            end

                            cheat.webRadar:run();
                        end
                    end
                end

                watermark.doWatermark = false;
                draw:drawStart();
            end
        end
    end

    watermark:drawWatermark();
    notifications:drawNotifications();
end

local function onUnload()
    cheat.fullbright:resetValues();
    cheat.recoil:restoreModifiedWeapons();
    cheat.deAllocateMemory();
    sendUnloadedMessage()
end

local function onLoad()
    sendLoadedMessage();
    cheat.allocateMemory();
end;

onLoad();

draw.menuVars.currentVerticalTab = 4;



local function onNetworkRecieved(var1, var2)
    bitmap:networkRequestCreate(var1, var2);
end

engine.register_on_network_callback(onNetworkRecieved)
engine.register_on_engine_tick(onTick)
engine.register_onunload(onUnload)