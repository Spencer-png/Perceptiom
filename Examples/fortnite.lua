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

local function drawText(font, text, x, y, r, g, b, a, outline, centeredX, centeredY)
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
            render.draw_text(fontPointer, text, x, y, r, g, b, a, outline.thickness or 0, outline.r or 0, outline.g or 0, outline.b or 0, outline.a or 255);
            return;
        else
            if type(font) == "table" then
                if font.outline then
                    render.draw_text(fontPointer, text, x, y, r, g, b, a, font.outline.thickness or 0, font.outline.r or 0, font.outline.g or 0, font.outline.b or 0, font.outline.a or 255);
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

    isValid = function(self)
        for i = 1, 4 do
            for j = 1, 4 do
                if number:isBadFloat(self[i][j]) then
                    return false
                end
            end
        end
    
        return true
    end;

    functions = {
        multiplyPoint3x4 = function(self, point)
            return vector3:create(
                self.m[1][1] * point.x + self.m[1][2] * point.y + self.m[1][3] * point.z + self.m[1][4],
                self.m[2][1] * point.x + self.m[2][2] * point.y + self.m[2][3] * point.z + self.m[2][4],
                self.m[3][1] * point.x + self.m[3][2] * point.y + self.m[3][3] * point.z + self.m[3][4]
            )
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
        local pattern = "[^%w%s%p]"
        inputString = inputString:gsub(pattern, "")
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
            local eulerAngles = {}
        
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
                return nil;
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
            if base ~= 0 then
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
                local x,y,z = Intrin.UnityGetPositionFromTransform(address)
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

        local newFont = render.create_font(font.name, font.size);
        font.font = newFont;
        font.outline = outline;


        local textMX, textMY = render.measure_text(newFont, "HEIGHT TEXT")
        font.height = textMY;
        self.fonts[key] = font
        return self.fonts[key];
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

game = "FORTNITE";

cheat = {
    menuWidth = 732;
    menuHeight = 650;

    menuElements = {
        {
            bitmap = {
                url = "https://i.imgur.com/arJBBMW.png";
                width = 50;
                height = 50;
            };
            tabName = "Aimbot";
            currentSubtab = 1;
            menuSubtabs = {
                {
                    subtabName = "Global";
                    disableCheck = true;
                    leftPanes = {
                        {
                            paneName = "Main Aimbot";
                            --autoAdjustForElements = true;
                            elements = {
                                {
                                    key = "Use Global For Disabled";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = true;
                                        checkboxType = 1;
                                    }
                                };
                                {
                                    key = "Enabled";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
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
                                        state = 4;
                                        doOff = false;
                                        options = {
                                            "Head";
                                            "Neck";
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
                                    key = "Prediction";
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
                                        minValue = 12.0;
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
                                        checkboxType = 1;
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
                                        state = 4;
                                        doOff = false;
                                        options = {
                                            "Head";
                                            "Neck";
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
                                    key = "Alt Prediction";
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
                                        minValue = 12.0;
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
                                        state = 1;
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
                                --[[{
                                    key = "Movement Warning";
                                    value = {
                                        type = drawTypes.label;
                                        secondPane = false;
                                        message = "Mouse Movement Method Ban status is unknown";
                                    };
                                };]]
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
                            }
                        };
                        {
                            paneName = "Triggerbot";
                            autoAdjustForElements = true;
                            elements = {
                                {
                                    key = "Triggerbot";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 2;
                                        message = "Detection Status Unknown";
                                        --adaptive = true;
                                        hotkey = {
                                            key = "Triggerbot Hotkey";
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
                                    key = "Between Shot Delay";
                                    value = {
                                        
                                        type = drawTypes.slider;
                                        state = 250;
                                        maxValue = 1000;
                                        minValue = 10;
                                        doText = true;
                                        textSpecifier = "ms";
                                        adaptive = true;
                                    };
                                };
                                {
                                    key = "Shot Delay";
                                    value = {
                                        
                                        type = drawTypes.slider;
                                        state = 13;
                                        maxValue = 80;
                                        minValue = 0;
                                        doText = true;
                                        textSpecifier = "ms";
                                        adaptive = true;
                                    };
                                };
                                {
                                    key = "Shotgun Only";
                                    value = {
                                        type = drawTypes.checkbox;
                                        state = false;
                                        checkboxType = 1;
                                    };
                                };
                            };
                        };
                    };
                }
            },
                
        },
        {
            bitmap = {
                url = "https://i.imgur.com/Dr4AtGk.png";
                width = 50;
                height = 50;
            };
            tabName = "Visuals";
            rightPanes = {
                {
                    paneName = "Other";
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
                    };
                };
                {
                    paneName = "Settings";
                    elements = {
                        {
                            key = "Outlines";
                            value = {
                                type = drawTypes.checkbox;
                                state = true;
                                checkboxType = 1;
                            }
                        };
                        {
                            key = "Dynamic Boxes";
                            value = {
                                type = drawTypes.checkbox;
                                state = true;
                                checkboxType = 1;
                            };
                        };
                        {
                            key = "Box Outlines";
                            value = {
                                type = drawTypes.checkbox;
                                state = true;
                                checkboxType = 1;
                            };
                        };
                        {
                            key = "Max Player Distance";
                            value = {
                                
                                type = drawTypes.slider;
                                state = 400;
                                maxValue = 500;
                                minValue = 10;
                                doText = true;
                                textSpecifier = "m";
                            };
                        };
                        {
                            key = "Max Skeleton Distance";
                            value = {
                                
                                type = drawTypes.slider;
                                state = 60;
                                maxValue = 500;
                                minValue = 10;
                                doText = true;
                                textSpecifier = "m";
                            };
                        };
                    }
                };
            };
            leftPanes = {
                {
                    paneName = "Player";
                    elements = {
                        {
                            key = "Player Visible Box";
                            value = {
                                type = drawTypes.checkbox;
                                state = true;
                                checkboxType = 1;
                                colorpicker = {
                                    key = "Visible Box Color";
                                    value = {
                                        color = {r = 255, g = 0, b = 224, a = 255};
                                    }
                                };
                            };
                        };
                        {
                            key = "Player Invisible Box";
                            value = {
                                type = drawTypes.checkbox;
                                state = true;
                                checkboxType = 1;
                                colorpicker = {
                                    key = "Invisible Box Color";
                                    value = {
                                        color = {r = 0, g = 242, b = 137, a = 255};
                                    }
                                };
                            };
                        };
                        {
                            key = "Visible Player Skeleton";
                            value = {
                                type = drawTypes.checkbox;
                                state = false;
                                checkboxType = 1;
                                colorpicker = {
                                    key = "Visible Skeleton Color";
                                    value = {
                                        color = {r = 255, g = 0, b = 224, a = 255};
                                    }
                                };
                            };
                        };
                        {
                            key = "Invisible Player Skeleton";
                            value = {
                                type = drawTypes.checkbox;
                                state = false;
                                checkboxType = 1;
                                colorpicker = {
                                    key = "Invisible Skeleton Color";
                                    value = {
                                        color = {r = 0, g = 242, b = 137, a = 255};
                                    }
                                };
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
                            key = "Player Platform";
                            value = {
                                type = drawTypes.checkbox;
                                state = true;
                                checkboxType = 1;
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
                                children = {
                                    {
                                        key = "Weapon Rarity Color";
                                        value = {
                                            type = drawTypes.checkbox;
                                            state = false;
                                            checkboxType = 1;
                                        };
                                    };
                                }
                            };
                        };
                        {
                            key = "Player Knocked";
                            value = {
                                type = drawTypes.colorpicker;
                                color = {r = 178, g = 34, b = 34, a = 255};
                            };
                        };
                    };
                };
                {
                    autoAdjustForElements = true;
                    paneName = "Player Flags";
                    elements = {
                        {
                            key = "Building State";
                            value = {
                                type = drawTypes.checkbox;
                                state = true;
                                checkboxType = 1;
                                colorpicker = {
                                    key = "Building State Color";
                                    value = {
                                        color = {r = 54, g = 242, b = 137, a = 255};
                                    }
                                };
                            };
                        };
                        {
                            key = "Team";
                            value = {
                                type = drawTypes.checkbox;
                                state = true;
                                checkboxType = 1;
                                colorpicker = {
                                    key = "Building State Color";
                                    value = {
                                        color = {r = 54, g = 242, b = 137, a = 255};
                                    }
                                };
                                children = {
                                    {
                                        key = "Team Color Type";
                                        value = {
                                            type = drawTypes.combobox;
                                            state = 1;
                                            doOff = false;
                                            options = {
                                                "Selected Color";
                                                "Team Color";
                                            };
                                        };
                                    };
                                }
                            };
                        };
                    };
                };
            };
        },
        {
            bitmap = {
                url = "https://i.imgur.com/Hnk7JKD.png";
                width = 50;
                height = 50;
            };
            tabName = "Configs";
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
                    };
                };
                
            },
        },
    },

    offsets = {
        uWorld = {
            isStaticClass = true,
            seconds = { --camera rotation + 0x10
                offset = 0x190,
            },
            gameState = {
                search = "Engine_classes.h:UWorld:GameState",
                offset = 0x1D0,
            },
            levels = {
                search = "Engine_classes.h:UWorld:Levels",
                offset = 0x1b0,
            },
            search = "OFFSET_GWORLD*",
            offset = 0x18540340,
            persistentLevel = {
                search = "Engine_classes.h:UWorld:PersistentLevel",
                offset = 0x38,
            },
            gameInstance = {
                search = "Engine_classes.h:UWorld:OwningGameInstance",
                offset = 0x248,
            },
        },
        fortPawn = {
            isDying = {
                search = "FortniteGame_classes.h:AFortPawn:bIsDying",
                offset = 0x728,
            },
            isKnocked = {
                search = "FortniteGame_classes.h:AFortPawn:bIsDBNO",
                offset = 0x98a,
            },
            currentWeapon = {
                search = "FortniteGame_classes.h:AFortPawn:CurrentWeapon",
                offset = 0xaa8,
            },
            spotted = {
                search = "FortniteGame_classes.h:AFortPawn:bSpotted",
                offset = 0x6D2,
            },
        },
        gameState = {
            actorsArray = {
                search = "Engine_classes.h:AGameStateBase:PlayerArray",
                offset = 0x2C0,
                bufferSize = 327680,
            },
        },
        fortPlayerStateZone = {
        },
        itemDefinitionBase = {
            itemName = {
                offset = 0x40,
            },
        },
        fortPlayerPawnAthena = {
        },
        uObject = {
            objectId = {
                offset = 0x18,
            },
        },
        uLevel = {
            actorsArray = {
                search = "Engine_classes.h:ULevel:Actors",
                offset = 0x28,
                bufferSize = 327680,
            },
            owningWorld = {
                search = "Engine_classes.h:ULevel:OwningWorld",
                offset = 0xC0,
                bufferSize = 327680,
            },
        },
        playerCameraManager = {
            cameraCache = {
                search = "Engine_classes.h:APlayerCameraManager:CameraCachePrivate",
                offset = 0x13B0,
            },
        },
        playerController = {
            aPawn = {
                search = "Engine_classes.h:APlayerController:AcknowledgedPawn",
                offset = 0x350,
            },
            rotationInput = {
                offset = 0x520 + 0x8,
            },
            cameraManager = {
                search = "Engine_classes.h:APlayerController:PlayerCameraManager",
                offset = 0x348,
            },
        },
        aFortPlayerController = {
            targetedFortPawn = {
                search = "Engine_classes.h:AFortPlayerController:TargetedFortPawn",
                offset = 0x18C0, --0x18b0,
            },
        },
        fortWeaponItemDefinition = {
            rarity = {
                search = "FortniteGame_classes.h:UFortItemDefinition:Rarity",
                offset = 0xA2,
            },
        },
        buildingContainer = {
            spawnSourceOverride = {
                search = "FortniteGame_classes.h:ABuildingContainer:SpawnSourceOverride",
                offset = 0xC40,
            },
        },
        gameInstance = {
            localPlayers = {
                search = "Engine_classes.h:UGameInstance:LocalPlayers",
                offset = 0x38,
            },
        },
        player = {
            playerController = {
                search = "Engine_classes.h:UPlayer:PlayerController",
                offset = 0x30,
            },
        },
        aPawn = {
            playerController = {
                search = "Engine_classes.h:APawn:Controller",
                offset = 0x2C0,
            },
            playerState = {
                search = "Engine_classes.h:APawn:PlayerState",
                offset = 0x2b0,
            },
        },
        habanero = {
            rankedProgress = {
                search = "FortniteGame_classes.h:UFortPlayerStateComponent_Habanero:RankedProgress",
                offset = 0xB8,
            },
        },
        sceneComponent = {
            relativeLocation = {
                search = "Engine_classes.h:USceneComponent:RelativeLocation",
                offset = 0x138,
            },
            velocity = {
                search = "Engine_classes.h:USceneComponent:ComponentVelocity",
                offset = 0x180,
            },
        },
        fortPlayerState = {
            playerName = {
                offset = 0xb20,
            },
            habanero = {
                search = "FortniteGame_classes.h:AFortPlayerState:HabaneroComponent",
                offset = 0x9D8,
            },
            platformName = {
                search = "FortniteGame_classes.h:AFortPlayerState:Platform",
                offset = 0x430,
            },
        },
        fortPlayerStateAthena = {
            teamIndex = {
                search = "FortniteGame_classes.h:AFortPlayerStateAthena:TeamIndex",
                offset = 0x1271, --0x1251?
            },
        },
        actor = {
            aPawn = {
                search = "Engine_classes.h:AActor:Instigator",
                offset = 0x180,
            },
            rootComponent = {
                search = "Engine_classes.h:AActor:RootComponent",
                offset = 0x1B0,
            },
        },
        skinnedMeshComponent = {
            recentlyRendererd = {
                search = "Engine_classes.h:USkinnedMeshComponent:bRecentlyRendered",
                offset = 0x73F,
            },
        },
        skeletalMeshComponent = {
            boneArray = {
                search = "Engine_classes.h:USkinnedMeshComponent:boneArray",
                offset = 0x5E8, -- 0x5E8?
            },
            boneArrayCached = {
                search = "Engine_classes.h:USkinnedMeshComponent:boneArrayCached",
                offset = 0x5E8 + 0x10,
            },
            lastSubmitTime = {
                search = "Engine_classes.h:UPrimitiveComponent:lastSubmitTime",
                offset = 0x2E0,
            },
            lastRenderTime = {
                search = "Engine_classes.h:UPrimitiveComponent:lastRenderTime",
                offset = 0x32c, --0x32c, --0x32c -- 0x30C?
            },
            componentToWorld = {
                offset = 0x1E0,
            },
        },
        character = {
            skeletalMesh = {
                search = "Engine_classes.h:ACharacter:Mesh",
                offset = 0x328,
            },
        },
        fortPlayerPawn = {
            buildingState = {
                search = "FortniteGame_classes.h:AFortPlayerPawn:BuildingState",
                offset = 0x2028,
            },
            isScriptedBot = {
                search = "FortniteGame_classes.h:AFortPlayerPawn:bIsScriptedBot",
                offset = 0x1EAC,
            },
        },
        fortWeapon = {
            projectileSpeed = {
                offset = 0x1d50,--0x1D20,
            },
            projectileGravityScale = {
                offset = 0x2268,
            },
            weaponData = {
                search = "FortniteGame_classes.h:AFortWeapon:WeaponData",
                offset = 0x558, --0x570;--0x618,
            },
        },
        playerState = {
            aPawn = {
                search = "Engine_classes.h:APlayerState:PawnPrivate",
                offset = 0x320,
            },
            isABot = {
                search = "Engine_classes.h:APlayerState:bIsABot",
                offset = 0x29A,
            },
        },
    };

    client = {
        seconds = 0;
    };

    class = {
        fortPlayerPawnAthena = {
            inherit = {
                "fortPlayerPawn";
            };

            functions = {
             
            };
        };
        fortPlayerPawn = {
            inherit = {
                "fortPawn";
            };

            functions = {
                getBuildingState = function(self)
                    return cheat.process:readInt8(self.entity + cheat.offsets.fortPlayerPawn.buildingState.offset)
                end;
                getIsScriptedBot = function(self)
                    return cheat.process:readInt8(self.entity + cheat.offsets.fortPlayerPawn.isScriptedBot.offset) == 1;
                end;
            };
        };
        buildingContainer = {
            inherit = {
                "actor";
            };

            functions = {
                getType = function(self)
                    return cheat.process:readInt8(self.entity + cheat.offsets.buildingContainer.spawnSourceOverride.offset)
                end;
            };
        };
        skeletalMeshComponent = {
            inherit = {
                "skinnedMeshComponent";
            };

            functions = {
                getLastSubmitTime = function(self)
                    return cheat.process:readFloat(self.entity + cheat.offsets.skeletalMeshComponent.lastSubmitTime.offset)
                end;

                getLastRenderTime = function(self)
                    return cheat.process:readFloat(self.entity + cheat.offsets.skeletalMeshComponent.lastRenderTime.offset)
                end;

                getBoneArray = function(self)
                    local cached = cheat.process:readInt64(self.entity + cheat.offsets.skeletalMeshComponent.boneArray.offset);

                    if cached == 0 then
                        return cheat.process:readInt64(self.entity + cheat.offsets.skeletalMeshComponent.boneArrayCached.offset)
                    end

                    return cached;
                end;

                loadBoneArray = function(self, buffer)
                    local cached = cheat.process:readInt64(self.entity + cheat.offsets.skeletalMeshComponent.boneArray.offset);

                    if cached == 0 then
                        cached = cheat.process:readInt64(self.entity + cheat.offsets.skeletalMeshComponent.boneArrayCached.offset)
                    end

                    if cached ~= 0 then
                        proc.read_to_memory_buffer(cached, buffer, 115 * 0x60)
                        return true;
                    end

                    return false;
                end;
            };
        };
        skinnedMeshComponent = {
            functions = {
                getRecentlyRendered = function(self)
                    return cheat.process:readInt8(self.entity + cheat.offsets.skinnedMeshComponent.recentlyRendererd.offset)
                end;
            }
        };




        fortWeapon = {
            inherit = {
                "actor";
            };

            functions = {
                getWeaponData = function(self)
                    return cheat.class.fortWeaponItemDefinition:create(cheat.process:readInt64(self.entity + cheat.offsets.fortWeapon.weaponData.offset))
                end;

                getProjectileSpeed = function(self)
                    return cheat.process:readFloat(self.entity + cheat.offsets.fortWeapon.projectileSpeed.offset)
                end;

                getProjectileGravityScale = function(self)
                    return cheat.process:readFloat(self.entity + cheat.offsets.fortWeapon.projectileGravityScale.offset)
                end;
            };
        };

        fortWeaponItemDefinition = {
            inherit = {
                "itemDefinitionBase";
            };

            functions = {
                getRarity = function(self)
                    return cheat.process:readInt8(self.entity + cheat.offsets.fortWeaponItemDefinition.rarity.offset)
                end;
            };
        };

        itemDefinitionBase = {
            functions = {
                getName = function(self)
                    return cheat.process:readFText(self.entity + cheat.offsets.itemDefinitionBase.itemName.offset);
                end;
            };
        };

        fortPawn = {
            inherit = {
                "character";
            };

            functions = {
                getIsDying = function(self)
                    return ((cheat.process:readInt8(self.entity + cheat.offsets.fortPawn.isDying.offset) & 32) ~= 0)
                end;

                getIsSpotted = function(self)
                    return cheat.process:readInt8(self.entity + cheat.offsets.fortPawn.spotted.offset)
                end;

                getWeapon = function(self)
                      return cheat.class.fortWeapon:create(cheat.process:readInt64(self.entity + cheat.offsets.fortPawn.currentWeapon.offset))
                end;

                getIsKnocked = function(self)
                    return (((cheat.process:readInt8(self.entity + cheat.offsets.fortPawn.isKnocked.offset) >> 6) & 1) ~= 1) and true or false--cheat.process:readBool(self.entity + cheat.offsets.fortPawn.isKnocked.offset)--cheat.process:readBool(self.entity + cheat.offsets.fortPawn.isDying.offset)
                end;
            };
        };

        character = {
            inherit = {
                "aPawn";
            };

            functions = {
                getSkeletalMesh = function(self)
                    return cheat.class.skeletalMeshComponent:create(cheat.process:readInt64(self.entity + cheat.offsets.character.skeletalMesh.offset))
                end;
            };
        };

        aPawn = {
            inherit = {
                "actor";
            };

            functions = {
                getPlayerState = function(self)
                    return cheat.class.fortPlayerStateAthena:create(cheat.process:readInt64(self.entity + cheat.offsets.aPawn.playerState.offset))
                end;

                getPlayerController = function(self)
                    return cheat.class.aFortPlayerController:create(cheat.process:readInt64(self.entity + cheat.offsets.aPawn.playerController.offset))
                end;
            };
        };

        localPlayer = {
            inherit = {
                "player";
            };

            functions = {
     
            };
        };

        controller = {
            inherit = {
                "actor";
            };

            functions = {
                getPlayerState = function(self)
                    return cheat.class.fortPlayerStateAthena:create(cheat.process:readInt64(self.entity + cheat.offsets.aPawn.playerState.offset))
                end;
            };
        };

        fortPlayerStateAthena = {
            inherit = {
                "fortPlayerStateZone";
            };

            functions = {
                getBoxBounds = function(self)
                    local basePosition = self.position;
                    local headPosition = self.position:add(vector3:create(0, 0, 150));
        
                    local baseScreenPosition = cheat.unreal:worldToScreen(basePosition);
                    local headScreenPosition = cheat.unreal:worldToScreen(headPosition);
        
                    if baseScreenPosition and headScreenPosition then
                        local flBoxHeight = math.abs(headScreenPosition.y - baseScreenPosition.y);
                        local flBoxWidth = flBoxHeight * 0.70;
                        local vecMin = vector3:create(headScreenPosition.x - (flBoxWidth * 0.5), headScreenPosition.y - (flBoxHeight * 0.15))
                        local vecMax = vector3:create(vecMin.x + flBoxWidth, vecMin.y + flBoxHeight * 1.3);
                        local vecBoundingBoxSize = vecMax:subtract(vecMin);
        
                        local fraction = 1.0 * (flBoxHeight * 0.11);
            
                        local returnValue = {
                            left = vecMin.x;
                            right = vecMin.x + vecBoundingBoxSize.x;
                            top = vecMin.y;
                            bottom = vecMin.y + vecBoundingBoxSize.y;
                            fraction = fraction;
                        };
        
                        return returnValue;
                    end
        
                    return nil;
                end;

                getTeamIndex = function(self)
                    return cheat.process:readInt8(self.entity + cheat.offsets.fortPlayerStateAthena.teamIndex.offset);
                end;
            };
        };

        fortPlayerStateZone = {
            inherit = {
                "fortPlayerState";
            };

            functions = {
               
            };
        };

        habanero = {
            inherit = {
                
            };

            functions = {
                getRankId = function(self)
                    return cheat.process:readInt32(self.entity + cheat.offsets.habanero.rankedProgress.offset + 0x10)
                end;
            };
        };

        fortPlayerState = {
            inherit = {
                "playerState";
            };

            functions = {
                getPlayerName = function(self)
                    --local ptr = cheat.process:readInt64()
                    return fortnite.get_player_name(self.entity + cheat.offsets.fortPlayerState.playerName.offset)
                    --return "";
                end;

                getPlatform = function(self)
                    --local ptr = cheat.process:readInt64()get
                    return cheat.process:readFString(self.entity + cheat.offsets.fortPlayerState.platformName.offset)
                end;

                getHabanero = function(self)
                    --local ptr = cheat.process:readInt64()
                    return cheat.class.habanero:create(cheat.process:readInt64(self.entity + cheat.offsets.fortPlayerState.habanero.offset))
                end;
            };
        };

        playerState = {
            inherit = {
                "actor";
            };

            functions = {
                getStatePawn = function(self)
                    return cheat.class.fortPlayerPawnAthena:create(cheat.process:readInt64(self.entity + cheat.offsets.playerState.aPawn.offset))
                end;

                getIsPlayerBot = function(self)
                    --return cheat.process:readInt8(self.entity + cheat.offsets.playerState.isABot.offset) == 1 and true or false--cheat.process:readBool(self.entity + cheat.offsets.fortPawn.isDying.offset)
                    return cheat.process:readInt8(self.entity + 0x18ef) == 1 and true or false
                end;
            };
        };

        uObject = {
            functions = {
                getObjectId = function(self)
                    return cheat.process:readInt32(self.entity + cheat.offsets.uObject.objectId.offset)
                end;
            };
        };

        playerCameraManager = {
            inherit = {
                "actor";
            };

            functions = {

            };
        };

        aFortPlayerController = {
            inherit = {
                "playerController";
            },
            functions = {
                getTargetedFortPawn = function(self)
                    return cheat.class.fortPawn:create(cheat.process:readInt64(self.entity + cheat.offsets.aFortPlayerController.targetedFortPawn.offset))
                end;
            };
        },

        playerController = {
            inherit = {
                "controller";
            };

            functions = {
                getCameraManager = function(self)
                    return cheat.class.playerCameraManager:create(cheat.process:readInt64(self.entity + cheat.offsets.playerController.cameraManager.offset))
                end;

                getPawn = function(self)
                    return cheat.class.fortPlayerPawnAthena:create(cheat.process:readInt64(self.entity + cheat.offsets.playerController.aPawn.offset))
                end;

                handleRotation = function(self, value)
                    if value then
                        value.z = 0;
                        return cheat.process:writeFVector3(self.entity + cheat.offsets.playerController.rotationInput.offset, value);
                    else
                        return cheat.process:readFVector3(self.entity + cheat.offsets.playerController.rotationInput.offset);
                    end
                end;

                getCameraCache = function(self)
                    local locationPointer = cheat.process:readInt64(cheat.entitylist.world + 0x170)
                    local rotationPointer = cheat.process:readInt64(cheat.entitylist.world + 0x180)

                    local pitch = cheat.process:readDouble(rotationPointer); -- 3 * 8 bytes for FVector3 (location)
                    local yaw = cheat.process:readDouble(rotationPointer + 0x20);   -- 24 + 8
                    local roll = cheat.process:readDouble(rotationPointer + 0x1d0);  -- 32 + 8

                    local cam = {
                        pov = {
                            -- Read the location as a FVector3 (doubles)
                            location = cheat.process:readFVector3(locationPointer);
                        
                            rotation = {
                                pitch = math.asin(roll) * (180.0 / math.pi); -- 3 * 8 bytes for FVector3 (location)
                                yaw = ((number:atan2(pitch * -1, yaw) * (180.0 / math.pi)) * -1) * -1;  -- 32 + 8
                                roll = 0;
                            };
                        
                            fov = cheat.process:readFloat(self.entity + 0x3AC) * 90.0;       -- 40 + 8
                        };
                    }

                    

                    --if cam.pov.fov > 0 then
                    cam.worldMatrix = cheat.unreal:rotatorToMatrix( cam.pov.rotation)
                    cam.xAxis = vector3:create(cam.worldMatrix.x.x, cam.worldMatrix.x.y, cam.worldMatrix.x.z);
                    cam.yAxis = vector3:create(cam.worldMatrix.y.x, cam.worldMatrix.y.y, cam.worldMatrix.y.z);
                    cam.zAxis = vector3:create(cam.worldMatrix.z.x, cam.worldMatrix.z.y, cam.worldMatrix.z.z);

                    return cam;
                end;
            };
        };
        
        player = {
            functions = {
                getController = function(self)
                    return cheat.class.aFortPlayerController:create(cheat.process:readInt64(self.entity + cheat.offsets.player.playerController.offset))
                end;
            };
        };

        sceneComponent = { --class USceneComponent 
            functions = {
                getPosition = function(self)
                    return cheat.process:readFVector3(self.entity + cheat.offsets.sceneComponent.relativeLocation.offset);
                end;

                getVelocity = function(self)
                    return cheat.process:readFVector3(self.entity + cheat.offsets.sceneComponent.velocity.offset);
                end;
            };
        };

        actor = {
            inherit = {
                "uObject";
            };

            functions = {
                getRootComponent = function(self)
                    return cheat.class.sceneComponent:create(cheat.process:readInt64(self.entity + cheat.offsets.actor.rootComponent.offset))
                end;

                getBonePosition = function(self, boneIndex, passedBoneBuffer)
                    if self.bonePositions then
                        if self.bonePositions[boneIndex] then
                            return self.bonePositions[boneIndex];
                        end
                    else
                        self.bonePositions = {};
                    end

                    local boneBuff = passedBoneBuffer;
                    if boneBuff == nil or boneBuff == 0 then
                        boneBuff = self.boneBuffer;
                    end

                    if not boneBuff or not self.componentToWorld then return nil end
                
                    local offset = boneIndex * 0x60
                    local transform = {
                        rotation = vector4:create(
                            m.read_double(boneBuff, offset + 0x00),
                            m.read_double(boneBuff, offset + 0x08),
                            m.read_double(boneBuff, offset + 0x10),
                            m.read_double(boneBuff, offset + 0x18)
                        ),
                        translation = vector3:create(
                            m.read_double(boneBuff, offset + 0x20),
                            m.read_double(boneBuff, offset + 0x28),
                            m.read_double(boneBuff, offset + 0x30)
                        ),
                        scale = vector3:create(
                            m.read_double(boneBuff, offset + 0x38),
                            m.read_double(boneBuff, offset + 0x40),
                            m.read_double(boneBuff, offset + 0x48)
                        )
                    }

                    local localMatrix = cheat.unreal:toMatrixWithScale(transform)
                    local worldMatrix = cheat.unreal:matrixMultiplication(localMatrix, cheat.unreal:toMatrixWithScale(self.componentToWorld))

                    local vec = vector3:create(worldMatrix.w.x, worldMatrix.w.y, worldMatrix.w.z)

                    if not vec or not vec:isValid() then
                        return nil;
                    end

                    return vec
                end;

                --[[getBonePosition = function(self, boneIndex, boneArrayPtr, skeletalMeshPtr)
                    if self.bonePositions then
                        if self.bonePositions[boneIndex] then
                            return self.bonePositions[boneIndex];
                        end
                    else
                        self.bonePositions = {};
                    end

                    if self.rootPosition or not self.position then
                        return nil;
                    end
                    
                    if self.boneArray and self.boneArray ~= 0 and self.componentToWorld then
                        local boneTransform = cheat.process:readFTransform(boneArrayPtr or self.boneArray + (boneIndex * 0x60))
                        --log('bt: ', self.componentToWorld.translation.x, ' - ', self.componentToWorld.translation.z)
                        if boneTransform then
                            local matrix = cheat.unreal:matrixMultiplication(cheat.unreal:toMatrixWithScale(boneTransform), cheat.unreal:toMatrixWithScale(self.componentToWorld))
                            --log('yeye')
                            local vec = vector3:create(matrix.w.x, matrix.w.y, matrix.w.z);
                            if vec and vec.x == 0 and vec.y == 0 and vec.z == 0 or vec.x > 100000000 or vec.y > 100000000 or vec.z > 100000000 then

                            else
                                --probably a bad way to do this, but it works?
                                if vec and self.position and vec:unrealDistance(self.position) > 6 then
                                    --self.boneArray = nil;
                                    return nil;
                                end

                                self.bonePositions[boneIndex] = vec;
                                return vec
                            end
                        end
                    end

                    return nil;
                end;]]
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
        ranks = {
            "B1", -- Bronze 1
            "B2", -- Bronze 2
            "B3", -- Bronze 3
            "S1", -- Silver 1
            "S2", -- Silver 2
            "S3", -- Silver 3
            "G1", -- Gold 1
            "G2", -- Gold 2
            "G3", -- Gold 3
            "P1", -- Platinum 1
            "P2", -- Platinum 2
            "P3", -- Platinum 3
            "D1", -- Diamond 1
            "D2", -- Diamond 2
            "D3", -- Diamond 3
            "EL",  -- Elite
            "CH",  -- Champion
            "UR",  -- Unreal
        };
        
        weaponRarities = {
            [0] = {
                color = {
                    r = 189;
                    g = 195;
                    b = 199;
                };
            };
            [1] = {
                color = {
                    r = 0;
                    g = 150;
                    b = 0;
                };
            };
            [2] = {
                color = {
                    r = 3;
                    g = 138;
                    b = 255;
                };
            };
            [3] = {
                color = {
                    r = 165;
                    g = 55;
                    b = 253;
                };
            };
            [4] = {
                color = {
                    r = 249;
                    g = 180;
                    b = 45;
                };
            };
            [5] = {
                color = {
                    r = 255;
                    g = 215;
                    b = 0;
                };
            };
            [6] = {
                color = {
                    r = 196;
                    g = 77;
                    b = 86;
                };
            };
            [7] = {
                color = {
                    r = 217;
                    g = 30;
                    b = 24;
                };
            };
        };

        bones = {
            head = 110,
            neck = 67,
            chest = 66,
            pelvis = 2,
            lShoulder = 9,
            lElbow = 10,
            lHand = 11,
            rShoulder = 38,
            rElbow = 39,
            rHand = 40,
            lHip = 71,
            lKnee = 72,
            lFoot = 75,
            lToes = 76,
            rHip = 78,
            rKnee = 79,
            rFoot = 82,
            rToes = 83,
            root = 0,
        }
    };

    unreal = {
        toMatrixWithScale = function(self, fTransform)
            -- Initialize the matrix
            local m = {
                {0, 0, 0, 0},
                {0, 0, 0, 0},
                {0, 0, 0, 0},
                {0, 0, 0, 1}
            }
        
            -- Translation
            m[4][1] = fTransform.translation.x
            m[4][2] = fTransform.translation.y
            m[4][3] = fTransform.translation.z
        
            local x2 = fTransform.rotation.x + fTransform.rotation.x
            local y2 = fTransform.rotation.y + fTransform.rotation.y
            local z2 = fTransform.rotation.z + fTransform.rotation.z
        
            local xx2 = fTransform.rotation.x * x2
            local yy2 = fTransform.rotation.y * y2
            local zz2 = fTransform.rotation.z * z2
        
            m[1][1] = (1.0 - (yy2 + zz2)) * fTransform.scale.x
            m[2][2] = (1.0 - (xx2 + zz2)) * fTransform.scale.y
            m[3][3] = (1.0 - (xx2 + yy2)) * fTransform.scale.z
        
            local yz2 = fTransform.rotation.y * z2
            local wx2 = fTransform.rotation.w * x2
            m[3][2] = (yz2 - wx2) * fTransform.scale.z
            m[2][3] = (yz2 + wx2) * fTransform.scale.y
        
            local xy2 = fTransform.rotation.x * y2
            local wz2 = fTransform.rotation.w * z2
            m[2][1] = (xy2 - wz2) * fTransform.scale.y
            m[1][2] = (xy2 + wz2) * fTransform.scale.x
        
            local xz2 = fTransform.rotation.x * z2
            local wy2 = fTransform.rotation.w * y2
            m[3][1] = (xz2 + wy2) * fTransform.scale.z
            m[1][3] = (xz2 - wy2) * fTransform.scale.x
        
            -- Now return a structure similar to createFMatrix
            return {
                x = vector4:create(m[1][1], m[1][2], m[1][3], m[1][4]),
                y = vector4:create(m[2][1], m[2][2], m[2][3], m[2][4]),
                z = vector4:create(m[3][1], m[3][2], m[3][3], m[3][4]),
                w = vector4:create(m[4][1], m[4][2], m[4][3], m[4][4])
            }
        end;

        createFMatrix = function(self)
            return {
                x = vector4:create(0,0,0,0),
                y = vector4:create(0,0,0,0),
                z = vector4:create(0,0,0,0),
                w = vector4:create(0,0,0,0)
            };
        end;
    
        matrixMultiplication = function(self, A, B)
            local Copy = self:createFMatrix()
            Copy.w.x = A.w.x * B.x.x + A.w.y * B.y.x + A.w.z * B.z.x + A.w.w * B.w.x
            Copy.w.y = A.w.x * B.x.y + A.w.y * B.y.y + A.w.z * B.z.y + A.w.w * B.w.y
            Copy.w.z = A.w.x * B.x.z + A.w.y * B.y.z + A.w.z * B.z.z + A.w.w * B.w.z
            Copy.w.w = A.w.x * B.x.w + A.w.y * B.y.w + A.w.z * B.z.w + A.w.w * B.w.w
            return Copy
        end;
    
        fTransformToMatrix = function(self, transform)
    
            local returnValue = self:createFMatrix() 
        
            local x2 = transform.rotation.x * 2
            local y2 = transform.rotation.y * 2
            local z2 = transform.rotation.z * 2
        
            local xx2 = transform.rotation.x * x2
            local yy2 = transform.rotation.y * y2
            local zz2 = transform.rotation.z * z2
        
            local yz2 = transform.rotation.y * z2
            local wx2 = transform.rotation.w * x2
        
            local xy2 = transform.rotation.x * y2
            local wz2 = transform.rotation.w * z2
        
            local xz2 = transform.rotation.x * z2
            local wy2 = transform.rotation.w * y2
        
            returnValue.x.x = (1.0 - (yy2 + zz2)) * transform.scale.x
            returnValue.x.y = (xy2 + wz2) * transform.scale.x
            returnValue.x.z = (xz2 - wy2) * transform.scale.x
        
            returnValue.y.x = (xy2 - wz2) * transform.scale.y
            returnValue.y.y = (1.0 - (xx2 + zz2)) * transform.scale.y
            returnValue.y.z = (yz2 + wx2) * transform.scale.y
        
            returnValue.z.x = (xz2 + wy2) * transform.scale.z
            returnValue.z.y = (yz2 - wx2) * transform.scale.z
            returnValue.z.z = (1.0 - (xx2 + yy2)) * transform.scale.z
        
            returnValue.w.x = transform.translation.x
            returnValue.w.y = transform.translation.y
            returnValue.w.z = transform.translation.z
            returnValue.w.w = 1.0
        
            return returnValue
        end;
        
        rotatorToMatrix = function(self, Rotation)
    
            local returnValue = self:createFMatrix()
        
            local Pitch = Rotation.pitch * math.pi / 180.0
            local Yaw = Rotation.yaw * math.pi / 180.0
            local Roll = Rotation.roll * math.pi / 180.0
        
            local sp = math.sin(Pitch)
            local cp = math.cos(Pitch)
            local sy = math.sin(Yaw)
            local cy = math.cos(Yaw)
            local sr = math.sin(Roll)
            local cr = math.cos(Roll)
        
            returnValue.x.x = cp * cy
            returnValue.x.y = cp * sy
            returnValue.x.z = sp
        
            returnValue.y.x = sr * sp * cy - cr * sy
            returnValue.y.y = sr * sp * sy + cr * cy
            returnValue.y.z = -sr * cp
        
            returnValue.z.x = -(cr * sp * cy + sr * sy)
            returnValue.z.y = cy * sr - cr * sp * sy
            returnValue.z.z = cr * cp
        
            returnValue.w.w = 1
        
            return returnValue
        end;
        
        worldToScreen = function(self, worldLocation, ignore)
            if not cheat.client.camera or not cheat.client.camera.pov or not cheat.client.camera.pov.location or type(cheat.client.camera.pov.location) ~= "table" then
                return nil;
            end

            local vDelta = vector3:create(worldLocation.x - cheat.client.camera.pov.location.x ,worldLocation.y - cheat.client.camera.pov.location.y ,worldLocation.z - cheat.client.camera.pov.location.z);
            local Transform = vector3:create(vDelta:dot(cheat.client.camera.yAxis),vDelta:dot(cheat.client.camera.zAxis),vDelta:dot(cheat.client.camera.xAxis));
        
            if (Transform.z < 1.0)  then
                Transform.z = 1.0;
            end
        
            local vecWorld = {x = (( draw.screenSize.x / 2.00)) + Transform.x * (((( draw.screenSize.x / 2.00)) / math.tan(cheat.client.camera.pov.fov * math.pi / 360.0))) / Transform.z, y = (( draw.screenSize.y / 2.00)) - Transform.y * (((( draw.screenSize.x / 2.00)) / math.tan(cheat.client.camera.pov.fov* math.pi / 360.0))) / Transform.z } ;
         
            if vecWorld.x >= -20 and vecWorld.y>= -20 and vecWorld.x <= (draw.screenSize.x + 20) and vecWorld.y <= (draw.screenSize.y + 20) or ignore then
                return vecWorld;
            else
                  --return nil;
            end

            return nil;
        end;
    };

    triggerbot = {
        lastCompletedShot = 0;

        run = function(self)
            if self.setShotTime then
                if cheat.aimbot.shotDelay < 5 or winapi.get_tickcount64() - self.setShotTime > cheat.aimbot.shotDelay then
                    input.simulate_mouse(0, 0, 0x0002);
                    self.shotTime = winapi.get_tickcount64();
                    self.setShotTime = nil;
                else
                    return;
                end
            end

            if self.shotTime then
                if winapi.get_tickcount64() - self.shotTime > 12 then
                    input.simulate_mouse(0, 0, 0x0004);
                    self.lastCompletedShot = winapi.get_tickcount64();
                    self.shotTime = nil;
                else
                    return;
                end
            end

            if self.lastCompletedShot and winapi.get_tickcount64() - self.lastCompletedShot < cheat.aimbot.betweenShotDelay or not cheat.client.localplayer.controller then
                return;
            end

            if draw.cachedUiVars.aimbot.global.triggerbot.value.state then
                if draw.cachedUiVars.aimbot.global.triggerbot.value.hotkey.value.keyState then
                    if draw.cachedUiVars.aimbot.global.shotgunOnly.value.state then
                        if cheat.aimbot.rawCatagory ~= 3 then
                            return;
                        end
                    end
                    local targetedPawn = cheat.client.localplayer.controller:getTargetedFortPawn();
                    if targetedPawn then
                        if not targetedPawn:getIsDying() and not targetedPawn:getIsKnocked() then
                            local playerState = targetedPawn:getPlayerState();
                            if playerState then
                                if playerState:getTeamIndex() ~= cheat.client.localplayer.teamIndex then
                                    self.setShotTime = winapi.get_tickcount64();
                                end
                            end
                        end
                    end
                end
            end
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

        uiCreation = {
            handleAdaptiveElements = function(self, element, tabName, index, parentTable, elementIndex)
                if element.value.adaptive and not element.copy and not element.hasOriginated then
                    element.hasOriginated = true;
                    element.originalKey = element.key;
                    element.key = cheat.menuElements[1].menuSubtabs[1].subtabName .. " " .. element.key;
                    element.visibleRequirement = function()
                        if cheat.menuElements[1].currentSubtab == 1 then
                            return true;
                        end
                        return false;
                    end;
                    
                    element.indexes = {};

                    element.getCatagoryElement = function(catagory)
                        return parentTable[element.indexes[catagory]];
                    end;

                    table.insert(element.indexes, elementIndex);
                end

                if element.value and element.value.adaptive then

                    local newCopy = copyTable(element);
                    newCopy.copy = true;
                    newCopy.key = tabName .. " " .. element.originalKey;
                    newCopy.visibleRequirement = function()
                        if cheat.menuElements[1].currentSubtab == index then
                            return true;
                        end
                        return false;
                    end;

                    if newCopy.value.hotkey then
                        newCopy.value.hotkey = element.value.hotkey
                    end

                    table.insert(parentTable, newCopy);
                    table.insert(element.indexes, #parentTable);
                end
            end;

            createSubtab = function(self, name)
                local subtabCount = 0;
                for _, tab in ipairs(cheat.menuElements[1].menuSubtabs) do
                    subtabCount = subtabCount + 1;
                end

                cheat.menuElements[1].menuSubtabs[subtabCount + 1] = {
                    subtabName = name;
                    disableCheck = true;
                    copy = true;
                    leftPanes = {
                        {
                        }
                    };
                    rightPanes = {
                        {
                        }
                    }
                };

                for _, pane in ipairs(cheat.menuElements[1].menuSubtabs[1].leftPanes) do
                    local index = 1;
                    for _, element in ipairs(pane.elements) do
                        if not element.copy then
                            self:handleAdaptiveElements(element, name, subtabCount + 1, pane.elements, index);
                        end
                        index = index + 1;
                    end
                end
    
                for _, pane in ipairs(cheat.menuElements[1].menuSubtabs[1].rightPanes) do
                    local index = 1;
                    for _, element in ipairs(pane.elements) do
                        if not element.copy then
                            self:handleAdaptiveElements(element, name, subtabCount + 1, pane.elements, index);
                        end
                        index = index + 1;
                    end
                end
            end;
    
            setupUiElements = function(self)
                self:createSubtab("AR");
                self:createSubtab("Shotgun");
                self:createSubtab("SMG");
                self:createSubtab("Sniper");
            end;
        };

        ignoreWeaponNames = {
            ["pickaxe"] = true,
            ["juice"] = true,
            ["slurp"] = true,
            ["grenade"] = true,
            ["bomb"] = true,
            ["shield potion"] = true,
            ["shield mushroom"] = true,
            ["chug"] = true
        };

        getWeaponCategory = function(self, weaponName)
            if  std:includes(weaponName, "Assault Rifle") or
                std:includes(weaponName, "Legacy Ass") or
                std:includes(weaponName, "The Machinist's Combat A") or
                std:includes(weaponName, "Tactical Assault Rifle") or
                std:includes(weaponName, "Enforcer AR") or
                std:includes(weaponName, "Striker AR") or
                std:includes(weaponName, "Warforged Assault R") or
                std:includes(weaponName, "Nemesis AR") then
                return 2
            elseif  std:includes(weaponName, "Shotgun") or
                    std:includes(weaponName, "Pump") then
                return 3
            elseif  std:includes(weaponName, "Harbinger SMG") or
                    std:includes(weaponName, "Thunder Burst SMG") or
                    std:includes(weaponName, "Snoop Dog") or
                    std:includes(weaponName, "Submachine Gun") or
                    std:includes(weaponName, "SMG") then
                return 4
            elseif  std:includes(weaponName, "Sniper") or
                    std:includes(weaponName, "Huntress DMR") then
                return 5
            end
        
            return 1
        end;

        meetsRequirements = function(self, player)
            if not player.isKnocked and not player.isDying then
                if not player.isTeammate then
                    if player.rootComponent then
                        if player.isVisible or not self.visibleActive then
                            if not player.rootPosition then
                                return true;
                            end
                        end
                    end
                end
            end

            return false;
        end;

        isInFov = function(self, player)
            local bonePositions = {
                player:getBonePosition(cheat.structs.bones.head);
                player:getBonePosition(cheat.structs.bones.pelvis);
            }

            for _, bonePosition in ipairs(bonePositions) do
                if bonePosition and bonePosition:isValid() then
                    local screenPosition = cheat.unreal:worldToScreen(bonePosition)
                    if screenPosition then
                        local current_delta = {
                            x = screenPosition.x - draw.screenCenter.x,
                            y = screenPosition.y - draw.screenCenter.y
                        }
        
                        local screen_radius = math.min(draw.screenCenter.x, draw.screenCenter.y)

                        local normalized_delta_x = current_delta.x / screen_radius
                        local normalized_delta_y = current_delta.y / screen_radius

                        local fov = math.sqrt(normalized_delta_x^2 + normalized_delta_y^2) * 90.0
        
                        if (fov) < self.fov then
                            return true, fov;
                        end
                    end
                end
            end

            return false, 0;
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
                    --player = copyTable(foundIndex);

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
                            local screenPos = cheat.unreal:worldToScreen(pelvisPos)
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

        updateWeaponCatagory = function(self)
            local catagory = self:getWeaponCategory(cheat.client.localplayer.heldWeaponName);

            local returnCatagory = -1;
            
            if draw.cachedUiVars.aimbot.global.globalEnabled.getCatagoryElement(catagory).value.state then
                returnCatagory = catagory;
            elseif draw.cachedUiVars.aimbot.global.useGlobalForDisabled.value.state and draw.cachedUiVars.aimbot.global.globalEnabled.getCatagoryElement(1).value.state then
                returnCatagory = 1;
            end

            self.rawCatagory = catagory;
            self.weaponCatagory = returnCatagory;
            if self.weaponCatagory ~= -1 then
                self.active = false;
                self.altActive = false;

                if draw.cachedUiVars.aimbot.global.globalAltEnabled.getCatagoryElement(self.weaponCatagory).value.state and draw.cachedUiVars.aimbot.global.globalAltEnabled.getCatagoryElement(self.weaponCatagory).value.hotkey.value.keyState then
                    self.active = true;
                    self.altActive = true;
                elseif draw.cachedUiVars.aimbot.global.globalEnabled.getCatagoryElement(self.weaponCatagory).value.state and draw.cachedUiVars.aimbot.global.globalEnabled.getCatagoryElement(self.weaponCatagory).value.hotkey.value.keyState then
                    self.active = true;
                end

                if self.active then
                    if self.altActive then
                        self.fov = draw.cachedUiVars.aimbot.global.globalAltMinimumFov.getCatagoryElement(self.weaponCatagory).value.state;
                        self.consistentTargeting = draw.cachedUiVars.aimbot.global.globalAltConsistentTargeting.getCatagoryElement(self.weaponCatagory).value.state;
                        self.targetSwitchDelay = draw.cachedUiVars.aimbot.global.globalAltTargetSwitchDelay.getCatagoryElement(self.weaponCatagory).value.state
                        self.alwaysKeepTargetRegardlessOfFov = draw.cachedUiVars.aimbot.global.globalAltAlwaysKeepTarget.getCatagoryElement(self.weaponCatagory).value.state
                        self.visibleActive = draw.cachedUiVars.aimbot.global.globalAltVisibleCheck.getCatagoryElement(self.weaponCatagory).value.state
                        self.predictionActive = draw.cachedUiVars.aimbot.global.globalAltPrediction.getCatagoryElement(self.weaponCatagory).value.state
                        self.hitbox = draw.cachedUiVars.aimbot.global.globalAltHitboxes.getCatagoryElement(self.weaponCatagory).value.state
                        self.deadzone = draw.cachedUiVars.aimbot.global.globalAltDeadzone.getCatagoryElement(self.weaponCatagory).value.state
                        self.smoothing = draw.cachedUiVars.aimbot.global.globalAltSmoothing.getCatagoryElement(self.weaponCatagory).value.state
                    else
                        self.fov = draw.cachedUiVars.aimbot.global.globalMinimumFov.getCatagoryElement(self.weaponCatagory).value.state;
                        self.consistentTargeting = draw.cachedUiVars.aimbot.global.globalConsistentTargeting.getCatagoryElement(self.weaponCatagory).value.state
                        self.targetSwitchDelay = draw.cachedUiVars.aimbot.global.globalTargetSwitchDelay.getCatagoryElement(self.weaponCatagory).value.state
                        self.alwaysKeepTargetRegardlessOfFov = draw.cachedUiVars.aimbot.global.globalAlwaysKeepTarget.getCatagoryElement(self.weaponCatagory).value.state
                        self.visibleActive = draw.cachedUiVars.aimbot.global.globalVisibleCheck.getCatagoryElement(self.weaponCatagory).value.state
                        self.predictionActive = draw.cachedUiVars.aimbot.global.globalPrediction.getCatagoryElement(self.weaponCatagory).value.state
                        self.hitbox = draw.cachedUiVars.aimbot.global.globalHitboxes.getCatagoryElement(self.weaponCatagory).value.state
                        self.deadzone = draw.cachedUiVars.aimbot.global.globalDeadzone.getCatagoryElement(self.weaponCatagory).value.state
                        self.smoothing = draw.cachedUiVars.aimbot.global.globalSmoothing.getCatagoryElement(self.weaponCatagory).value.state
                    end
                end
            end

            self.shotDelay = draw.cachedUiVars.aimbot.global.globalShotDelay.getCatagoryElement(catagory).value.state
            self.betweenShotDelay = draw.cachedUiVars.aimbot.global.globalBetweenShotDelay.getCatagoryElement(catagory).value.state
        end;

        updatePredictionData = function(self)
            self.projectileGravity = 0;
            self.projectileSpeed = 0;
            self.targetVelocity = cheat.process:readFVector3(self.targetPlayerIndex.rootComponent.entity + cheat.offsets.sceneComponent.velocity.offset);--self.targetPlayer.rootComponent:getVelocity();

            if std:includes(string.lower(cheat.client.localplayer.heldWeaponName), "boom bolt") then
                self.projectileSpeed = 60000;
                self.projectileGravity = 2.4;
            end

            self.projectileGravity = cheat.client.localplayer.heldWeapon:getProjectileGravityScale();
            self.projectileSpeed = cheat.client.localplayer.heldWeapon:getProjectileSpeed();
        end;

        predictPosition = function(self, position)
            if self.prediction then
                if self.projectileSpeed > 0.0 then
                    local distance = math.sqrt(
                        (cheat.client.camera.pov.location.x - position.x)^2 +
                        (cheat.client.camera.pov.location.y - position.y)^2 +
                        (cheat.client.camera.pov.location.z - position.z)^2
                    )
    
                    local horizontalTime = distance / self.projectileSpeed
                    local verticalTime = distance / self.projectileSpeed
    
                    local output = {
                        x = position.x + self.targetVelocity.x * horizontalTime,
                        y = position.y + self.targetVelocity.y * horizontalTime,
                        z = position.z + self.targetVelocity.z * verticalTime + math.abs(-980.0 * self.projectileGravity) * 0.5 * (verticalTime * verticalTime)
                    }
    
                    return output
                end
            end

            return position;
        end;

        normalizeAngle = function(self, Angle)
            Angle = Angle % 360.0
        
            if Angle > 180.0 then
                Angle = Angle - 360.0
            elseif Angle < -180.0 then
                Angle = Angle + 360.0
            end
        
            return Angle
        end;

        normalizeVector = function(self, vec)
            return vector3:create(math.min(math.max(self:normalizeAngle(vec.x), -89.0), 89.0), math.min(math.max(self:normalizeAngle(vec.y), -180.0), 180.0))
        end;

        calculateAngle = function(self, localPosition, targetPosition)
            local pi = 3.141592653589793
            local pos = vector3:create(targetPosition.x - localPosition.x, targetPosition.y - localPosition.y, targetPosition.z - localPosition.z);
            return vector3:create(
                math.deg(math.atan(pos.z / math.sqrt(pos.x * pos.x + pos.y * pos.y))),
                math.deg(number:atan2(pos.y, pos.x))
            )
        end;

        getNearestHitbox = function(self, player, localAngles)
            local targetBones = {cheat.structs.bones.head,cheat.structs.bones.neck, cheat.structs.bones.chest, cheat.structs.bones.pelvis}
            local shouldModifyPitch = true
            local bestYawPitch = nil
            local lowestPitch = 10000;
            local highestPitch = -10000

        
            -- Iterate through all pairs of adjacent bones
            for i = 1, #targetBones - 1 do
                local startBone = self:predictPosition(player:getBonePosition(targetBones[i]))
                local endBone = self:predictPosition(player:getBonePosition(targetBones[i + 1]))
                if startBone and startBone:isValid() and endBone and endBone:isValid() then
                    local startAngle = self:normalizeVector(self:calculateAngle(cheat.client.camera.pov.location, startBone))
                    local endAngle = self:normalizeVector(self:calculateAngle(cheat.client.camera.pov.location, endBone))

                    
                    lowestPitch = math.min(lowestPitch, startAngle.x, endAngle.x)
                    highestPitch = math.max(highestPitch, startAngle.x, endAngle.x)


                    local directionStartToEnd = {x = endAngle.x - startAngle.x, y = endAngle.y - startAngle.y}
                    local directionStartToEye = {x = localAngles.x - startAngle.x, y = localAngles.y - startAngle.y}
            
                    -- Calculate the dot product
                    local dotProduct = directionStartToEnd.x * directionStartToEye.x + directionStartToEnd.y * directionStartToEye.y
            
                    -- Calculate the squared distance between startAngle and localAngles
                    local startToEyeDistSquared = (localAngles.x - startAngle.x)^2 + (localAngles.y - startAngle.y)^2
            
                    -- Calculate the squared distance between endAngle and localAngles
                    local endToEyeDistSquared = (localAngles.x - endAngle.x)^2 + (localAngles.y - endAngle.y)^2
            
                    -- Clamp the projection to the line segment
                    local nearestPoint
                    if dotProduct <= 0 then
                        nearestPoint = startAngle
                    elseif dotProduct >= (directionStartToEnd.x^2 + directionStartToEnd.y^2) then
                        nearestPoint = endAngle
                    else
                        -- Calculate the projection
                        local projection = {
                            x = startAngle.x + (directionStartToEnd.x * (dotProduct / (directionStartToEnd.x^2 + directionStartToEnd.y^2))),
                            y = startAngle.y + (directionStartToEnd.y * (dotProduct / (directionStartToEnd.x^2 + directionStartToEnd.y^2)))
                        }
            
                        -- Calculate the squared distance between projection and localAngles
                        local projectionToEyeDistSquared = (localAngles.x - projection.x)^2 + (localAngles.y - projection.y)^2
            
                        -- Check which point is nearest to localAngles
                        if projectionToEyeDistSquared <= startToEyeDistSquared then
                            nearestPoint = projection
                        else
                            nearestPoint = startAngle
                        end
                    end
            
                    -- Update the bestYawPitch
                    if bestYawPitch == nil or ((nearestPoint.x - localAngles.x)^2 + (nearestPoint.y - localAngles.y)^2) < ((bestYawPitch.x - localAngles.x)^2 + (bestYawPitch.y - localAngles.y)^2) then
                        self.predictionPosition = startBone
                        bestYawPitch = nearestPoint
                    end
                end
            end

            if localAngles.x >= lowestPitch and localAngles.x <= highestPitch then
                shouldModifyPitch = false;
            end
        
            return bestYawPitch, shouldModifyPitch
        end;

        convertViewAnglesToDirection = function(self, viewAngles)
            local pitch = viewAngles.x
            local yaw = viewAngles.y
        
            local radPitch = math.rad(pitch)  -- Convert degrees to radians
            local radYaw = math.rad(yaw)      -- Convert degrees to radians
        
            local direction = vector3:create(
                math.cos(radPitch) * math.cos(radYaw),
                math.cos(radPitch) * math.sin(radYaw),
                math.sin(radPitch)
        )
        
            return direction
        end;

        run = function(self)
            self:updateWeaponCatagory();

            if draw.menuOpen or draw.epaMenuOpen or not cheat.client.localplayer.heldWeapon or not cheat.client.localplayer.heldWeaponName or string.len(cheat.client.localplayer.heldWeaponName) == 0 or not cheat.client.localplayer.controller or cheat.client.localplayer.isDying or cheat.client.localplayer.isKnocked then
                return;
            end

            local lower = string.lower(cheat.client.localplayer.heldWeaponName)

            for word in pairs(self.ignoreWeaponNames) do
                if string.find(lower, word, 1, true) then  -- true = plain text match, not pattern
                    return;
                end
            end

            if cheat.entitylist:updateCr3Fail() then
                return;
            end;

            if self.weaponCatagory ~= -1 then
                cheat.triggerbot:run();

                if self.active then
                    if self.lastAimbot and winapi.get_tickcount64() - self.lastAimbot < 15 then
                        return;
                    end

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
                        if winapi.get_tickcount64() > (self.lastSwitchTime + self.targetSwitchDelay) then
                            self:updatePredictionData();
                            local rotation = vector3:create(cheat.client.camera.pov.rotation.pitch, cheat.client.camera.pov.rotation.yaw)

                            if self.rotationUpdateSent then
                                if ((rotation.x ~= self.lastSentRotationUpdate.x or rotation.y ~= self.lastSentRotationUpdate.y)) then
                                    self.rotationUpdateSent = false;
                                end
                            end

                            local aimAngles = nil;
                            local targetPosition = nil;
                            local isNearest = false;
                            local modifyPitch = true;

                            if self.hitbox == 1 then
                                targetPosition = self:predictPosition(self.targetPlayerIndex:getBonePosition(cheat.structs.bones.head));
                            elseif self.hitbox == 2 then
                                targetPosition = self:predictPosition(self.targetPlayerIndex:getBonePosition(cheat.structs.bones.neck));
                            elseif self.hitbox == 3 then
                                targetPosition = self:predictPosition(self.targetPlayerIndex:getBonePosition(cheat.structs.bones.pelvis));
                            elseif self.hitbox == 4 then
                                if self.targetPlayerIndex.distance > 130 then
                                    targetPosition = self:predictPosition(self.targetPlayerIndex:getBonePosition(cheat.structs.bones.neck));
                                else
                                    aimAngles, modifyPitch = self:getNearestHitbox(self.targetPlayerIndex, rotation);
                                    isNearest = true;
                                end
                            end

                            if not targetPosition and not isNearest then
                                --log("fail 3");
                                return;
                            end

                            
                           
                            if isNearest then
                                aimAngles = self:normalizeVector(aimAngles);
                            else
                                aimAngles = self:normalizeVector(self:calculateAngle(cheat.client.camera.pov.location, targetPosition));
                            end

                            if not modifyPitch then
                                aimAngles.x = rotation.x;
                            end
                            
                            if aimAngles:isValid() then
                                local deltaAngle = vector3:create(aimAngles.x - rotation.x, aimAngles.y - rotation.y, 0);
                                deltaAngle = self:normalizeVector(deltaAngle);

                                local fov = math.sqrt((deltaAngle.y ^ 2) + (deltaAngle.x ^ 2))
                                local scaledValue = number:scaleValue(10, 200, self.targetPlayerIndex.distance, 0.026, 0.2, true);
 
                                if fov >= ((self.deadzone / 10) * scaledValue) then
                                    self.lastDeadzoneFail = 0;
                                else
                                    if not self.lastDeadzoneFail or self.lastDeadzoneFail == 0 then
                                        self.lastDeadzoneFail = winapi.get_tickcount64();
                                    end
                                    if winapi.get_tickcount64() - self.lastDeadzoneFail > 100 then
                                        --log("deadzone ", winapi.get_tickcount64());
                                        return;
                                    end
                                end

                                --self.lastDeadzoneFail = 0;

                                if draw.cachedUiVars.aimbot.global.movementType.value.state == 2 then
                                    local norm = self:normalizeVector(aimAngles);
                                    local direction = self:convertViewAnglesToDirection(norm);
                                    direction = cheat.client.camera.pov.location:add(direction:multiplyBy(1000));
                                    local onScreen = cheat.unreal:worldToScreen(direction);
                                    if onScreen then
                                        local screenAngle = {
                                            x = (onScreen.x - draw.screenCenter.x),
                                            y = (onScreen.y - draw.screenCenter.y)
                                        }
                                
                                        local random_speed_factor = 0.35 + math.random() / (math.huge / (1.0 - 0.35))
                                        local aim_speed = ((100 - self.smoothing) / ((self.smoothing/10)) * random_speed_factor) / 100.0
                                
                                        screenAngle.x = screenAngle.x * aim_speed
                                        screenAngle.y = screenAngle.y * aim_speed
                                
                                        screenAngle.x = math.ceil(screenAngle.x)
                                        screenAngle.y = math.ceil(screenAngle.y)
                                
                                        if not modifyPitch then
                                            screenAngle.x = 0.0
                                        end

                                        if self.rotationUpdateSent == false then
                                            self.lastSentRotationUpdate.x = rotation.pitch;
                                            self.lastSentRotationUpdate.y = rotation.yaw;
                                            self.rotationUpdateSent = true;
                                            self.lastAimbot = winapi.get_tickcount64();
                                            input.simulate_mouse(math.floor(screenAngle.x), math.floor(screenAngle.y), 0x1);    
                                        end
                                    end
                                elseif draw.cachedUiVars.aimbot.global.movementType.value.state == 1 then
 

                                    local aimSmoothing = (100 - self.smoothing) / ((self.smoothing/10) * 100)
                                    local angle = vector3:new(
                                        deltaAngle.x * aimSmoothing,
                                        deltaAngle.y * aimSmoothing,
                                        0.0
                                    )

                                    angle = self:normalizeVector(angle);
                                    if self.rotationUpdateSent == false then
                                        if cheat.entitylist:updateCr3Fail() then
                                            return;
                                        end;

                                        self.lastSentRotationUpdate.x = rotation.pitch;
                                        self.lastSentRotationUpdate.y = rotation.yaw;
                                        self.rotationUpdateSent = true;
                                        if (angle.x ~= 89.0 and angle.x ~= -89.0 and angle.y ~= 180.0 and angle.y ~= -180.0) then
                                            angle.z = 0;
                                            
                                            cheat.client.localplayer.controller:handleRotation(angle);
                                        else
                                            --log("fail 3");
                                        end
                                        self.lastAimbot = winapi.get_tickcount64();
                                    end
                                    
                                end
                            else
                                --log("fail 1");
                            end
                        else
                            --log("switch time fail");
                        end
                    else
                        --log("target fail");
                    end
                else
                    self.targetPlayer = nil;
                    self.lastSwitchTime = 0;
                    self.lastTargetFail = 0;
                    self.lastUpdatedTargetFail = 0;
                    self.targetPlayerIndex = nil;
                    self.rotationUpdateSent = false;
                end
            else
                self.targetPlayer = nil;
                self.targetPlayerIndex = nil;
                self.lastSwitchTime = 0;
                self.lastTargetFail = 0;
                self.lastUpdatedTargetFail = 0;
                self.rotationUpdateSent = false;
            end
        end;
    };

    visual = {
        bottomYOffset = 0;
        topYOffset = 0;
        activeTeams = {};
        teamColors = {};

        drawTriangle = function(self, point1, point2, point3, color, thickness)
            render.draw_line(point1.x, point1.y, point2.x, point2.y, color.r, color.g, color.b, color.a or 255, thickness or 1)
            render.draw_line(point2.x, point2.y, point3.x, point3.y, color.r, color.g, color.b, color.a or 255, thickness or 1)
            render.draw_line(point3.x, point3.y, point1.x, point1.y, color.r, color.g, color.b, color.a or 255, thickness or 1)
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
                if draw.cachedUiVars.visuals.oOFArrows.value.state then
                    if not player.isKnocked and not player.isTeammate and not player.onScreen and player.distance < 600 and player.position then
                        local screenCenterX = draw.screenSize.x / 2
                        local screenCenterY = draw.screenSize.y / 2
            
                        local arrowScale = 1.7

                        local relative = vector3:create(
                            player.position.x - cheat.client.camera.pov.location.x,
                            player.position.y - cheat.client.camera.pov.location.y,
                            player.position.z - cheat.client.camera.pov.location.z
                        )
                        
                        local dir2D = vector2:create(relative.x, relative.y):unitVector()
                        
                        local camYawRad = math.rad(cheat.client.camera.pov.rotation.yaw)
                        local sinYaw = math.sin(-camYawRad)
                        local cosYaw = math.cos(-camYawRad)
                        
                        local rotatedX = dir2D.x * cosYaw - dir2D.y * sinYaw
                        local rotatedY = dir2D.x * sinYaw + dir2D.y * cosYaw
                        
                        local angle = number:atan2(rotatedY, rotatedX) * (180 / math.pi)
            
                        -- Apply scale to arrow offset
                        local pos_0 = number:cosTanHorizontal(angle, 10 * arrowScale, screenCenterX, screenCenterY, 110 * arrowScale)
                        local pos_1 = number:cosTanHorizontal(angle + 2, 10 * arrowScale, screenCenterX, screenCenterY, 100 * arrowScale)
                        local pos_2 = number:cosTanHorizontal(angle - 2, 10 * arrowScale, screenCenterX, screenCenterY, 100 * arrowScale)
            
                        -- Get the player's color and opacity based on distance
                        local playerColor = draw.cachedUiVars.visuals.oOFArrows.value.colorpicker.value.color
                        local opacity = self:scaleDistanceToRange(player.distance, 0, 275, 255, 50)
            
                        -- Draw the triangle as the OOF arrow with calculated positions
                        cheat.visual:drawTriangle(pos_0, pos_1, pos_2, {r = playerColor.r, g = playerColor.g, b = playerColor.b, a = opacity}, 2)
                    end
                end
            end;
        };

        drawFov = function(self)
            if draw.cachedUiVars.aimbot.global.drawFov.value.state then
                local radius = (math.tan((cheat.aimbot.fov * (math.pi / 180.0)) / 4.0) * draw.screenCenter.y) * 2.2
                local color = draw.cachedUiVars.aimbot.global.drawFov.value.colorpicker.value.color

                render.draw_circle(draw.screenCenter.x, draw.screenCenter.y, radius, color.r, color.g, color.b, color.a, 1, false)
            end
        end;

        getTeamColor = function(self, teamid)
            if self.teamColors[teamid] then
                return self.teamColors[teamid] -- Return cached color if already generated
            end

            -- Generate a hue based on the teamid (spread across 360 degrees)
            local hue = (teamid * 2654435761 % 360) -- Large prime number for better distribution
            
            -- Set high saturation and lightness for brightness
            local saturation = 0.9
            local lightness = 0.6

            -- Convert HSL to RGB
            local function hslToRgb(h, s, l)
                local function f(p, q, t)
                    if t < 0 then t = t + 1 end
                    if t > 1 then t = t - 1 end
                    if t < 1/6 then return p + (q - p) * 6 * t end
                    if t < 1/2 then return q end
                    if t < 2/3 then return p + (q - p) * (2/3 - t) * 6 end
                    return p
                end

                local q = l < 0.5 and l * (1 + s) or l + s - l * s
                local p = 2 * l - q

                local r = f(p, q, hue / 360 + 1/3)
                local g = f(p, q, hue / 360)
                local b = f(p, q, hue / 360 - 1/3)

                return {math.floor(r * 255), math.floor(g * 255), math.floor(b * 255)}
            end

            -- Generate RGB color
            local rgbColor = hslToRgb(hue, saturation, lightness)

            -- Store and return
            self.teamColors[teamid] = {r = rgbColor[1], g = rgbColor[2], b = rgbColor[3], a = 255};
            return self.teamColors[teamid]
        end;

        drawBox = function(self, player, r, g, b, a)
            local boxWidth = player.bounds.right - player.bounds.left;
            local boxHeight = player.bounds.bottom - player.bounds.top;

            if draw.cachedUiVars.visuals.boxOutlines.value.state then
                drawRectangle(player.bounds.left + 1, player.bounds.top + 1, boxWidth - 2, boxHeight - 2, 0, 0, 0, a, false, 1);
                drawRectangle(player.bounds.left - 1, player.bounds.top - 1, boxWidth + 2, boxHeight + 2, 0, 0, 0, a, false, 1);
            end

            drawRectangle(player.bounds.left, player.bounds.top, boxWidth, boxHeight, r, g, b, a, false, 1);
        end;

        drawWeapon = function(self, player, r, g, b, a)
            local boxWidth = player.bounds.right - player.bounds.left;

            if player.heldWeapon then
                if player.heldWeaponName and string.len(player.heldWeaponName) > 1 and player.heldWeaponName ~= "?" then
                    drawText(draw.fonts.entityText, player.heldWeaponName, player.bounds.left + (boxWidth/2), (player.bounds.bottom) + 1 + self.bottomYOffset, r,g,b,a, draw.cachedUiVars.visuals.outlines.value.state, true);
                    self.bottomYOffset = self.bottomYOffset + draw.fonts.entityText.height;
                end
            end
        end;

        drawName = function(self, player, r, g, b, a)
            local boxWidth = player.bounds.right - player.bounds.left;

            local baseString = "";
            if player.name and string.len(player.name) > 0 then
                baseString = player.name
                if draw.cachedUiVars.visuals.playerPlatform.value.state and string.len(player.platform) > 0 then
                    baseString = baseString  .. " [" .. player.platform .. "]";
                end
            else
                if player.platform and string.len(player.platform) > 0 and draw.cachedUiVars.visuals.playerPlatform.value.state then
                    baseString =player.platform;
                else
                    return;
                end
            end

            if string.len(baseString) == 0 then
                return;
            end

            --local distanceText = tostring(math.floor(player.position.x)) .. " - " .. tostring(math.floor(player.position.y)) .. " - " .. tostring(math.floor(player.position.z)) .. " - "
            drawText(draw.fonts.entityText, baseString, player.bounds.left + (boxWidth/2), (player.bounds.top) - draw.fonts.entityText.height - self.topYOffset - 2, r,g,b,a, draw.cachedUiVars.visuals.outlines.value.state, true);
        end;

        drawDistance = function(self, player, r, g, b, a)
            if player.distance then
                local boxWidth = player.bounds.right - player.bounds.left;
                local distanceText = tostring(math.floor(player.distance)) .. "m"
                drawText(draw.fonts.entityText, distanceText, player.bounds.left + (boxWidth/2), (player.bounds.bottom) + 1 + self.bottomYOffset, r,g,b,a, draw.cachedUiVars.visuals.outlines.value.state, true);

                self.bottomYOffset = self.bottomYOffset + draw.fonts.entityText.height;
                --self.bottomYOffset = self.bottomYOffset + draw.fonts.entityText.height;
            end
        end;

        drawPlayerFlags = function(self, player)
            if player.distance then
                if player.distance < 200 then
                    local fontSize = number:roundToDecimals(number:scaleValue(25, 206, player.distance, 9, 3, false), 0)
                    local flagFont = draw:createFont("SegoeUI.ttf", math.floor(fontSize));
                    if flagFont then
                        if flagFont.font then
                            local scaleFactor = player.distance / 40;
                            local adjustedTop = player.bounds.top - scaleFactor;

                            local leftOffset = 0;
                            local rightOffset = 0;

                            if draw.cachedUiVars.visuals.buildingState.value.state then
                                if player.buildingState == 0 then
                                    local color = draw.cachedUiVars.visuals.buildingState.value.colorpicker.value.color;
                                    drawText(flagFont, "P", player.bounds.right + 3, adjustedTop + rightOffset +1 , color.r,color.g,color.b,color.a)
                                    rightOffset = rightOffset + (flagFont.height) +1 ;
                                elseif player.buildingState == 1 then
                                    local color = draw.cachedUiVars.visuals.buildingState.value.colorpicker.value.color;
                                    drawText(flagFont, "E", player.bounds.right + 3, adjustedTop + rightOffset +1 , color.r,color.g,color.b,color.a)
                                    rightOffset = rightOffset + (flagFont.height) +1 ;
                                end
                            end

                            if draw.cachedUiVars.visuals.team.value.state then
                                if player.teamIndex then
                                    if self.activeTeams[player.teamIndex] and self.activeTeams[player.teamIndex] > 1 then
                                        local color = draw.cachedUiVars.visuals.team.value.colorpicker.value.color;

                                        if draw.cachedUiVars.visuals.teamColorType.value.state == 2 then
                                            color = self:getTeamColor(player.teamIndex)
                                        end

                                        drawText(flagFont, tostring(player.teamIndex), player.bounds.right + 3, adjustedTop + rightOffset +1 , color.r,color.g,color.b,color.a)
                                        rightOffset = rightOffset + (flagFont.height) +1 ;
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
                if fromBone:unrealDistance(toBone) > 1.3 then
                    return;
                end

                if to == cheat.structs.bones.head then
                    toBone = toBone:add(vector3:create(0,0,35));
                end

                if from == cheat.structs.bones.head then
                    fromBone = fromBone:add(vector3:create(0,0,35));
                end

                local fromOnScreen = cheat.unreal:worldToScreen(fromBone);
                if fromOnScreen then
                    local toOnScreen = cheat.unreal:worldToScreen(toBone);
                    if toOnScreen then
                        if drawSkeletonLines then
                            render.draw_line(fromOnScreen.x, fromOnScreen.y, toOnScreen.x, toOnScreen.y, r, g, b, a, thickness)
                        end
                        
                        local padding = number:scaleValue(10, 150, player.distance, 0.7, 7, true)
                        skeletonBounds.left = math.min(skeletonBounds.left, math.min(fromOnScreen.x, toOnScreen.x) - padding)
                        skeletonBounds.right = math.max(skeletonBounds.right, math.max(fromOnScreen.x, toOnScreen.x) + padding)
                        skeletonBounds.top = math.min(skeletonBounds.top, math.min(fromOnScreen.y, toOnScreen.y) - padding)
                        skeletonBounds.bottom = math.max(skeletonBounds.bottom, math.max(fromOnScreen.y, toOnScreen.y) + padding)
                    end
                end
            end


        end;

        drawSkeleton = function(self, player, r, g, b, a, thickness, drawSkeletonLines)
            if player.rootPosition then return end;

            local skeletonBounds = {
                left = math.huge,   -- Equivalent to FLT_MAX
                top = math.huge,    -- Equivalent to FLT_MAX
                right = -math.huge, -- Equivalent to -FLT_MAX
                bottom = -math.huge -- Equivalent to -FLT_MAX
            }

            if drawSkeletonLines or draw.cachedUiVars.visuals.dynamicBoxes.value.state then
                self:drawSkeletonConnection(player, cheat.structs.bones.neck, cheat.structs.bones.chest, r, g, b, a, skeletonBounds, thickness, drawSkeletonLines);
                self:drawSkeletonConnection(player, cheat.structs.bones.chest, cheat.structs.bones.pelvis, r, g, b, a, skeletonBounds, thickness, drawSkeletonLines);
                self:drawSkeletonConnection(player, cheat.structs.bones.pelvis, cheat.structs.bones.lHip, r, g, b, a, skeletonBounds, thickness, drawSkeletonLines);
                self:drawSkeletonConnection(player, cheat.structs.bones.pelvis, cheat.structs.bones.rHip, r, g, b, a, skeletonBounds, thickness, drawSkeletonLines);
                self:drawSkeletonConnection(player, cheat.structs.bones.lHip, cheat.structs.bones.lKnee, r, g, b, a, skeletonBounds, thickness, drawSkeletonLines);
                self:drawSkeletonConnection(player, cheat.structs.bones.rHip, cheat.structs.bones.rKnee, r, g, b, a, skeletonBounds, thickness, drawSkeletonLines);
                self:drawSkeletonConnection(player, cheat.structs.bones.lKnee, cheat.structs.bones.lFoot, r, g, b, a, skeletonBounds, thickness, drawSkeletonLines);
                self:drawSkeletonConnection(player, cheat.structs.bones.rKnee, cheat.structs.bones.rFoot, r, g, b, a, skeletonBounds, thickness, drawSkeletonLines);
                self:drawSkeletonConnection(player, cheat.structs.bones.neck, cheat.structs.bones.lShoulder, r, g, b, a, skeletonBounds, thickness, drawSkeletonLines);
                self:drawSkeletonConnection(player, cheat.structs.bones.neck, cheat.structs.bones.rShoulder, r, g, b, a, skeletonBounds, thickness, drawSkeletonLines);
                self:drawSkeletonConnection(player, cheat.structs.bones.lShoulder, cheat.structs.bones.lElbow, r, g, b, a, skeletonBounds, thickness, drawSkeletonLines);
                self:drawSkeletonConnection(player, cheat.structs.bones.rShoulder, cheat.structs.bones.rElbow, r, g, b, a, skeletonBounds, thickness, drawSkeletonLines);
                self:drawSkeletonConnection(player, cheat.structs.bones.lElbow, cheat.structs.bones.lHand, r, g, b, a, skeletonBounds, thickness, drawSkeletonLines);
                self:drawSkeletonConnection(player, cheat.structs.bones.rElbow, cheat.structs.bones.rHand, r, g, b, a, skeletonBounds, thickness, drawSkeletonLines);
            end

            local assignedBounds = false;

            if skeletonBounds and not cheat.entitylist.cr3Fail and (drawSkeletonLines or draw.cachedUiVars.visuals.dynamicBoxes.value.state) and not player.lastDrawFail then
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

        handlePlayerDraw = function(self)
            self.activeTeams = {};

            for entity, player in pairs(cheat.entitylist.players) do
                if self.activeTeams[player.teamIndex] then
                    self.activeTeams[player.teamIndex] = self.activeTeams[player.teamIndex] + 1;
                else
                    self.activeTeams[player.teamIndex] = 1
                end

            end

            local drawCount = 0;
            
            for entity, player in pairs(cheat.entitylist.players) do
                self.bottomYOffset = 0;
                self.topYOffset = 0;

                if not player.onScreen then
                    cheat.visual.oofArrows:drawPlayer(player);
                end

                if player.onScreen then
                    cheat.entitylist:updateCr3Fail();
                    if player.distance < draw.cachedUiVars.visuals.maxPlayerDistance.value.state then
                        local bounds = player:getBoxBounds();
                        if bounds then
                            player.lastDrawFail = nil;
                            
                            if (draw.cachedUiVars.visuals.dynamicBoxes.value.state or player.rootPosition and not cheat.entitylist.cr3Fail) then
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
                            if player.position then
                                if player.position:isValid() then
                                    if not player.isTeammate then
                                        drawCount = drawCount + 1;
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
                        --else
                            --log("fail 0: ", player.name);
                        end
                    end
                end
            end

            self.lastDrawCount = drawCount;
        end;
    };

    entitylist = {
        --engineDataTimer = timer.new();
        loopEntitiesTimer = timer.new();
        lastFoundWorld = 0;
        players = {};
        cr3Fail = false;

        updateCr3Fail = function(self)
            local readValue = cheat.process:readInt64(cheat.process.modules.main.base + cheat.offsets.uWorld.offset)

            if not self.orignalWorld and readValue ~= 0 then
                self.orignalWorld = readValue;
            end

            local originalDigits = tostring(self.orignalWorld):len()
            local currentDigits = tostring(readValue):len()

            if currentDigits < originalDigits then
                self.cr3Fail = true
            else
                self.cr3Fail = false
            end

            return self.cr3Fail
        end;

        updateEngineData = function(self)
            local world = cheat.process:readInt64(cheat.process.modules.main.base + cheat.offsets.uWorld.offset);
            if (world) then
                local persistentLevel = cheat.process:readInt64(world + cheat.offsets.uWorld.persistentLevel.offset);
                if persistentLevel then
                    local gameInstance = cheat.process:readInt64(world + cheat.offsets.uWorld.gameInstance.offset);
                    if gameInstance then
                        local gameState = cheat.process:readInt64(world + cheat.offsets.uWorld.gameState.offset);
                        if gameState then
                            self.lastFoundWorld = winapi.get_tickcount64();
                            self.world = world;
                            self.persistentLevel = persistentLevel;
                            self.gameInstance = gameInstance;
                            self.gameState = gameState;
                            self.updatedEngineData = true;
                            self.failedEngineData = false;
                            cheat.client.seconds = cheat.process:readDouble(self.world + cheat.offsets.uWorld.seconds.offset);
                            return true;
                        end
                    end
                end
            end

            if self.lastFoundWorld + 70 > winapi.get_tickcount64() then
                self.failedEngineData = true;
                return true;
            end

            self.failedEngineData = false;
            self.updatedEngineData = false;

            return false;
        end;

        updateData = function(self)
            local newPlayers = {}
            for entity, player in pairs(self.players) do
                newPlayers[entity] = (player);
            end
        
            if self:updateCr3Fail() then
                return;
            end
        
            for entity, player in pairs(newPlayers) do
                player.isDying = player.pawn:getIsDying();
                player.bonePositions = {};
                if not player.distance then
                    player.distance = 0;
                end
                if player.rootComponent then
                    player.isKnocked = player.pawn:getIsKnocked();
                    player.buildingState = player.pawn:getBuildingState();

                    local foundBones = false;
                    local skeletalMesh = player.pawn:getSkeletalMesh();
                    if skeletalMesh then
                        player.skeletalMesh = skeletalMesh;

                        if self:updateCr3Fail() then
                            return;
                        end
                        local componentToWorld = cheat.process:readFTransform(player.skeletalMesh.entity + cheat.offsets.skeletalMeshComponent.componentToWorld.offset)
                        if componentToWorld then
                            if componentToWorld.rotation and componentToWorld.rotation:isValid() then
                                player.componentToWorld = componentToWorld;
                            end
                        end

                        local boneArray = skeletalMesh:getBoneArray();
                        if boneArray > 0 then
                            player.boneArray = boneArray;
                            if player.boneBuffer and player.tempBoneBuffer then
                                if player.skeletalMesh:loadBoneArray(player.boneBuffer) then;
                                    local bonePosition = player:getBonePosition(0, player.boneBuffer);
                                    if bonePosition and bonePosition:isValid() then
                                        player.lastWorkingBoneArray = winapi.get_tickcount64();
                                        foundBones = true;
                                    end
                                end
                            end
                        end

                        local lastRenderTime = player.skeletalMesh:getLastRenderTime()

                        player.isVisible = ((cheat.client.seconds - lastRenderTime) <= 0.1)
                    end

                    if not player.lastWorkingBoneArray or winapi.get_tickcount64() - player.lastWorkingBoneArray > 75 then
                        player.rootPosition = true;
                        local position = player.rootComponent:getPosition();
                        if position and position:isValid() then
                            player.position = position;
                            player.midPosition = vector3:create(player.position.x, player.position.y, player.position.z);
                            player.position = position:subtract(vector3:create(0, 0, 90));
                        end
                    else
                        if foundBones then
                            player.rootPosition = false;
                            player.position = player:getBonePosition(0);
                            player.midPosition = player.position:add(vector3:create(0, 0, 90));
                        end
                    end

                    --[[local skeletalMesh = player.pawn:getSkeletalMesh();
                    if skeletalMesh then
                        player.skeletalMesh = skeletalMesh;

                        local boneArray = skeletalMesh:getBoneArray();
                        if boneArray > 0 then
                            if player.boneBuffer then
                                if player.skeletalMesh:loadBoneArray(player.boneBuffer) then;

                                end
                            end
                            player.lastBoneArrayFail = nil;
                            player.boneArray = boneArray;
                        else
                            player.lastBoneArrayFail = winapi.get_tickcount64();
                        end

                        player.componentToWorld = cheat.process:readFTransform(player.skeletalMesh.entity + cheat.offsets.skeletalMeshComponent.componentToWorld.offset)
                        local lastRenderTime = player.skeletalMesh:getLastRenderTime()

                        player.isVisible = ((cheat.client.seconds - lastRenderTime) <= 0.1)
                    else
                        player.lastBoneArrayFail = winapi.get_tickcount64();
                    end

                    local updatedBones = false;

                    if not player.lastBoneArrayFail or winapi.get_tickcount64() - player.lastBoneArrayFail < 60 then
                        if player.boneArray and player.boneArray ~= 0 then
                            player.rootPosition = false;
                            player.position = player:getBonePosition(0)
                            if not player.position or (not player.position:isValid()) then
                                player.boneArray = nil;
                            else
                                player.midPosition = player.position:add(vector3:create(0, 0, 75));
                                player.rootPosition = false;
                                updatedBones = true;
                            end
                        end
                    end

                    if updatedBones == false then
                        player.position = player.rootComponent:getPosition();
                        if player.position and player.position:isValid() then
                            player.midPosition = player.position;
                            player.position = player.position:subtract(vector3:create(0, 0, 75));
                        end

                        player.rootPosition = true;
                    end]]

                    if player.position and player.position:isValid() then
                        player.distance = player.position:unrealDistance(cheat.client.camera.pov.location);
                        player.onScreen = cheat.unreal:worldToScreen(player.midPosition)
                        if player.onScreen then
                            --player.bounds = player:getBoxBounds();
                        end
                    else
                        player.onScreen = nil;
                    end

                    if not player.weaponCheckTimer then
                        player.weaponCheckTimer = timer.new();
                    end

                    --cheat.client.seconds


                    if player.weaponCheckTimer.check(500) then
                        local heldWeapon = player.pawn:getWeapon();
    
                        if not heldWeapon then
                            player.heldWeapon = nil;
                            player.heldWeaponName = "";
                        else
                            player.heldWeapon = heldWeapon
                            local weaponData = player.heldWeapon:getWeaponData();
                            if (weaponData) then
                                local weaponName = weaponData:getName();
                                if weaponName and string.len(weaponName) > 1 then
                                    player.heldWeaponName = string.upper(weaponName);
                                    player.heldWeapon.rarity = weaponData:getRarity()
                                else
                                    player.heldWeapon = nil;
                                    player.heldWeaponName = "";
                                end
                            else
                                player.heldWeapon = nil;
                                player.heldWeaponName = "";
                            end
                        end
                    end
                end
            end

            if self:updateCr3Fail() then
                return
            end

            self.players = newPlayers;
        end;

        removePlayer = function(self, player)
            local index = self.players[player];

            if not index then return end;

            if index.boneBuffer then
                m.free(index.boneBuffer);
            end

            if index.tempBoneBuffer then
                m.free(index.tempBoneBuffer);
            end
            
            self.players[player] = nil;
        end;

        loopEntities = function(self)
            if cheat.entitylist.cr3Fail then
                self.loopEntitiesTimer.update()
            end

            if not self.loopEntitiesTimer.check(1500) then
                return false;
            end

            local actorArray = cheat.process:readInt64(cheat.entitylist.gameState + (cheat.offsets.gameState.actorsArray.offset))
            local actorArrayCount = cheat.process:readInt32(cheat.entitylist.gameState + (cheat.offsets.gameState.actorsArray.offset + 0x8))

            if actorArray ~= 0 and actorArrayCount > 0 and 5000 > actorArrayCount then
                proc.read_to_memory_buffer(actorArray, self.entityBuffer, actorArrayCount * 0x8);

                for key, value in pairs(self.players) do
                    value.found = false;
                end

                for i = 0, actorArrayCount do
                    local currentActor = m.read_int64(self.entityBuffer, i * 0x8);
                    if currentActor then
                        if not self.players[currentActor] then
                            local playerState = cheat.class.fortPlayerStateAthena:create(currentActor)
                            if playerState then
                                playerState.pawn = playerState:getStatePawn();

                                if playerState.pawn then
                                    if not cheat.client.localplayer or not cheat.client.localplayer.pawn or cheat.client.localplayer.pawn.entity ~= playerState.pawn.entity then
                                        if not cheat.client.localplayer or not cheat.client.localplayer.playerState or cheat.client.localplayer.playerState.entity ~= playerState.entity then
                                            self.players[currentActor] = playerState;
                                        end
                                    end
                                end
                            end
                        end

                        if self.players[currentActor] then
                            local index = self.players[currentActor];
                            local pawn = index:getStatePawn();

                            if pawn and index.pawn.entity == pawn.entity then
                                if not cheat.client.localplayer or not cheat.client.localplayer.pawn or cheat.client.localplayer.pawn.entity ~= index.pawn.entity then
                                    if not cheat.client.localplayer or not cheat.client.localplayer.playerState or cheat.client.localplayer.playerState.entity ~= index.entity then
                                        local rootComponent = index.pawn:getRootComponent();
                                        if rootComponent then
                                            local shouldContinue = true;

                                            if index.rootComponent then
                                                if index.rootComponent.entity ~= rootComponent.entity then
                                                    self:removePlayer(currentActor);
                                                    shouldContinue = false;
                                                end
                                            end

                                            if shouldContinue then
                                                index.rootComponent = rootComponent;
                                                if not index.name then
                                                    index.name = index:getPlayerName();
                                                    if not index.name or string.len(index.name) <= 0 then
                                                        index.name = "BOT";
                                                    else
                                                        index.name = string.upper(index.name)
                                                    end
                                                end

                                                if not index.boneBuffer then
                                                    index.boneBuffer = m.alloc(115 * 0x60);
                                                    index.tempBoneBuffer = m.alloc(115 * 0x60);
                                                end
            
                                                --[[playerState.habanero = playerState:getHabanero();
                                                if playerState.habanero then
                                                    playerState.rank = playerState.habanero:getRankId() + 1;
                                                    if playerState.rank > 0 and #cheat.structs.ranks >= playerState.rank then
                                                        playerState.rankName = cheat.structs.ranks[playerState.rank]
                                                    end
                                                end]]
            
                                                index.platform = string.upper(index:getPlatform());
                                                index.controller = index.pawn:getPlayerController();
                                                index.teamIndex = index:getTeamIndex();
                                                index.found = true;
                                                if cheat.client.localplayer and cheat.client.localplayer.teamIndex then
                                                    index.isTeammate = index.teamIndex == cheat.client.localplayer.teamIndex
                                                end
                                                --local didExist = self:updatePlayer(index);
                                            end
                                        else
                                            self:removePlayer(currentActor);
                                        end
                                    else
                                        self:removePlayer(currentActor);
                                    end
                                else
                                    self:removePlayer(currentActor);
                                end
                            else
                                self:removePlayer(currentActor);
                            end
                        end
                    end
                end

                for key, value in pairs(self.players) do
                    if not value.found then
                        self:removePlayer(key);
                        --self.players[key] = nil;
                    end
                end
            end
        end;

        updateLocalPlayer = function(self)
            local localPlayers = cheat.process:readInt64(cheat.entitylist.gameInstance + cheat.offsets.gameInstance.localPlayers.offset)
            --log('localplayers: ', localPlayers)
            if localPlayers ~= 0 then
                local localPlayer = cheat.process:readInt64(localPlayers);
                if localPlayer and localPlayer ~= 0 then
                    if not cheat.client.localplayer or cheat.client.localplayer.entity ~= localPlayer then
                        cheat.client.localplayer = cheat.class.localPlayer:create(localPlayer);
                    end

                    cheat.client.localplayer.controller = cheat.client.localplayer:getController()

                    if cheat.client.localplayer.controller then
                        cheat.client.localplayer.pawn = cheat.client.localplayer.controller:getPawn();
                        if cheat.client.localplayer.pawn then
                            cheat.client.localplayer.isKnocked = cheat.client.localplayer.pawn:getIsKnocked();
                            cheat.client.localplayer.isDying = cheat.client.localplayer.pawn:getIsDying();
                            cheat.client.localplayer.playerState = cheat.client.localplayer.controller:getPlayerState();
                            
                            cheat.client.localplayer.heldWeapon = cheat.client.localplayer.pawn:getWeapon();
                            if cheat.client.localplayer.heldWeapon then
                                local weaponData = cheat.client.localplayer.heldWeapon:getWeaponData();
                                if weaponData then
                                    local weaponName = weaponData:getName();
                                    cheat.client.localplayer.heldWeaponName = weaponName;
                                end

                                cheat.client.localplayer.heldWeapon.projectileSpeed = cheat.client.localplayer.heldWeapon:getProjectileSpeed();
                                cheat.client.localplayer.heldWeapon.projectileGravity = cheat.client.localplayer.heldWeapon:getProjectileGravityScale();
                            end
                            
                            if cheat.client.localplayer.playerState then
                                cheat.client.localplayer.teamIndex = cheat.client.localplayer.playerState:getTeamIndex();
                            end

                            local camera = cheat.client.localplayer.controller:getCameraCache();

                            if camera and camera.pov and camera.pov.location and camera.pov.location:isValid() then
                                cheat.client.camera = camera;
                                return true;
                            end
                        end
                    end
                end
            end

            return false;
        end;
    };

    ensureOffsets = function(self)
        cheat.process = processSetup:createProcess("FortniteClient-Win64-Shipping.exe", true, {
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
        end
    end;

    allocateMemory = function(self)
        vector4.buffer = m.alloc(0x8 * 4);
        vector3.buffer = m.alloc(0x8*3);
        vector2.buffer = m.alloc(0x8*2);
        matrix4x4.buffer = m.alloc(16 * 4);
        cheat.entitylist.entityBuffer = m.alloc(327680);
    end;

    deAllocateMemory = function(self)
        m.free(vector4.buffer);
        m.free(vector3.buffer);
        m.free(vector2.buffer);
        m.free(matrix4x4.buffer);
        m.free(cheat.entitylist.entityBuffer);

        for key, value in pairs(cheat.entitylist.players) do
            if value.boneBuffer then
                m.free(value.boneBuffer);
            end
            if value.tempBoneBuffer then
                m.free(value.tempBoneBuffer);
            end
        end
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
            watermark.doWatermark = true;
        else
            if not cheat.setupClasses then
                cheat.class:setupClasses();
                cheat.setupClasses = true;
            end
            if cheat.canDoMemory then
                cheat.entitylist:updateEngineData();

                if cheat.entitylist.updatedEngineData then
                    if not cheat.entitylist.failedEngineData then
                        cheat.entitylist:updateCr3Fail();
                        cheat.entitylist:updateLocalPlayer();
                        cheat.entitylist:loopEntities();

                        if cheat.client.camera then
                            cheat.entitylist:updateData();
                            cheat.aimbot:run();
                            cheat.triggerbot:run();
                        end
                    end
                end

                if cheat.client.camera then
                    cheat.visual:handlePlayerDraw();
                    cheat.visual:drawFov();
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
    cheat.deAllocateMemory();
    -- sendUnloadedMessage()
end

local function onLoad()
    -- sendLoadedMessage();
    cheat.allocateMemory();
end;

onLoad();

cheat.aimbot.uiCreation:setupUiElements();

engine.register_on_engine_tick(onTick)
engine.register_onunload(onUnload)