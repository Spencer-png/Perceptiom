-- @SCREEN

local screenWidth, screenHeight = render.get_viewport_size();

local screenCenter = vec2(screenWidth / 2, screenHeight / 2);

-- @FONTS

local defaultFont = render.create_font("Palatino.ttf", 10);

local bigFont = render.create_font("Palatino.ttf", 14);

-- @ATTACH

local attach = proc.attach_by_name("DayZ_x64.exe");

if (proc.is_attached()) then
    gameBaseAddress = proc.base_address();

    if (not gameBaseAddress or gameBaseAddress == 0) then
        engine.log("Failed to find base address", 255, 75, 75, 255);

        return;
    end;
else
    engine.log("Failed to find DayZ", 255, 75, 75, 255);

    return;
end;

-- @GAME

local gameOffsets = {
    world = 0x41CEB30,

    camera = 0x1B8,

    localPlayer = 0x2960,

    nearEntityList = 0xF48,

    farEntityList = 0x1090,

    itemList = 0x2060,

    networkId = 0x6EC,

    humanType = 0x180,

    categoryName = 0xA8,

    objectName = 0x70,

    cleanName = 0x4F0,

    visualState = 0x1D0,

    position = 0x2C,

    viewportMatrix = 0x58,

    invertedViewTranslation = 0x2C,

    invertedViewRight = 0x8,

    invertedViewUp = 0x14,

    invertedViewForward = 0x20,

    projectionD1 = 0xD0,

    projectionD2 = 0xDC
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

    menu.playersDistance = menu.playersPanel:add_checkbox("Distance");

    menu.playersMaximumDistance = menu.playersPanel:add_slider_int("Maximum Distance", 0, 1000, 1000);

    menu.zombiesPanel = menu.visualsTab:create_panel("Zombies", true);

    menu.zombiesEnabled = menu.zombiesPanel:add_checkbox("Enabled");

    menu.zombiesEnabledKeybind = menu.zombiesPanel:add_keybind("Enabled Keybind", 0, key_mode.always_on);

    menu.zombiesName = menu.zombiesPanel:add_checkbox("Name");

    menu.zombiesNameColor = menu.zombiesPanel:add_color_picker("Name Color", 175, 255, 75, 255);

    menu.zombiesDistance = menu.zombiesPanel:add_checkbox("Distance");

    menu.zombiesMaximumDistance = menu.zombiesPanel:add_slider_int("Maximum Distance", 0, 1000, 100);

    menu.animalsPanel = menu.visualsTab:create_panel("Animals", true);

    menu.animalsEnabled = menu.animalsPanel:add_checkbox("Enabled");

    menu.animalsEnabledKeybind = menu.animalsPanel:add_keybind("Enabled Keybind", 0, key_mode.always_on);

    menu.animalsName = menu.animalsPanel:add_checkbox("Name");

    menu.animalsNameColor = menu.animalsPanel:add_color_picker("Name Color", 255, 150, 0, 255);

    menu.animalsDistance = menu.animalsPanel:add_checkbox("Distance");

    menu.animalsMaximumDistance = menu.animalsPanel:add_slider_int("Maximum Distance", 0, 1000, 1000);

    menu.vehiclesPanel = menu.visualsTab:create_panel("Vehicles", true);

    menu.vehiclesEnabled = menu.vehiclesPanel:add_checkbox("Enabled");

    menu.vehiclesEnabledKeybind = menu.vehiclesPanel:add_keybind("Enabled Keybind", 0, key_mode.always_on);

    menu.vehiclesName = menu.vehiclesPanel:add_checkbox("Name");

    menu.vehiclesNameColor = menu.vehiclesPanel:add_color_picker("Name Color", 75, 175, 255, 255);

    menu.vehiclesDistance = menu.vehiclesPanel:add_checkbox("Distance");

    menu.vehiclesMaximumDistance = menu.vehiclesPanel:add_slider_int("Maximum Distance", 0, 1000, 1000);

    menu.itemsPanel = menu.visualsTab:create_panel("Items", true);

    menu.itemsEnabled = menu.itemsPanel:add_checkbox("Enabled");

    menu.itemsEnabledKeybind = menu.itemsPanel:add_keybind("Enabled Keybind", 0, key_mode.always_on);

    menu.itemsName = menu.itemsPanel:add_checkbox("Name");

    menu.itemsNameColor = menu.itemsPanel:add_color_picker("Name Color", 255, 200, 0, 255);

    menu.itemsDistance = menu.itemsPanel:add_checkbox("Distance");

    menu.itemsMaximumDistance = menu.itemsPanel:add_slider_int("Maximum Distance", 0, 1000, 200);

    menu.othersPanel = menu.visualsTab:create_panel("Others", true);

    menu.coordinatesEnabled = menu.othersPanel:add_checkbox("Self Coordinates");

    menu.coordinatesColor = menu.othersPanel:add_color_picker("Self Coordinates Color", 255, 255, 255, 255);
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

local worldToScreen = function(worldPosition, viewport, invertedViewTranslation, invertedViewRight, invertedViewUp, invertedViewForward, projectionD1, projectionD2)
    local transformedPosition = (worldPosition - invertedViewTranslation);

    local transformedX = transformedPosition:dot(invertedViewRight);

    local transformedY = transformedPosition:dot(invertedViewUp);

    local transformedZ = transformedPosition:dot(invertedViewForward);

    if (transformedZ > 0.1) then
        return vec2((viewport.x * (1 + (transformedX / projectionD1.x / transformedZ))), (viewport.y * (1 - (transformedY / projectionD2.y / transformedZ))));
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

local getCamera = function(worldAddress)
    return safeReadInt64(worldAddress + gameOffsets.camera);
end;

local getViewport = function(cameraAddress)
    return safeReadVector2(cameraAddress + gameOffsets.viewportMatrix);
end;

local getInvertedViewTranslation = function(cameraAddress)
    return safeReadVector3(cameraAddress + gameOffsets.invertedViewTranslation);
end;

local getInvertedViewRight = function(cameraAddress)
    return safeReadVector3(cameraAddress + gameOffsets.invertedViewRight);
end;

local getInvertedViewUp = function(cameraAddress)
    return safeReadVector3(cameraAddress + gameOffsets.invertedViewUp);
end;

local getInvertedViewForward = function(cameraAddress)
    return safeReadVector3(cameraAddress + gameOffsets.invertedViewForward);
end;

local getProjectionD1 = function(cameraAddress)
    return safeReadVector3(cameraAddress + gameOffsets.projectionD1);
end;

local getProjectionD2 = function(cameraAddress)
    return safeReadVector3(cameraAddress + gameOffsets.projectionD2);
end;

local getLocalPlayer = function(worldAddress)
    local localPlayerAddress = safeReadInt64(worldAddress + gameOffsets.localPlayer);

    if (localPlayerAddress ~= nil and localPlayerAddress ~= 0) then
        return (safeReadInt64(localPlayerAddress + 0x8) - 0xA8);
    end;

    return;
end;

local getNearEntityList = function(worldAddress)
    return safeReadInt64(worldAddress + gameOffsets.nearEntityList);
end;

local getFarEntityList = function(worldAddress)
    return safeReadInt64(worldAddress + gameOffsets.farEntityList);
end;

local getItemList = function(worldAddress)
    return safeReadInt64(worldAddress + gameOffsets.itemList);
end;

local getNetworkId = function(entityAddress)
    return safeReadInt64(entityAddress + gameOffsets.networkId);
end;

local getHumanType = function(entityAddress)
    return safeReadInt64(entityAddress + gameOffsets.humanType);
end;

local getCategoryName = function(humanTypeAddress)
    local categoryNameAddress = safeReadInt64(humanTypeAddress + gameOffsets.categoryName);

    if (categoryNameAddress ~= nil and categoryNameAddress ~= 0) then
        return safeReadString(categoryNameAddress + 0x10, 256);
    end;
    
    return;
end;

local getObjectName = function(humanTypeAddress)
    local objectNameAddress = safeReadInt64(humanTypeAddress + gameOffsets.objectName);

    if (objectNameAddress ~= nil and objectNameAddress ~= 0) then
        return safeReadString(objectNameAddress + 0x10, 256);
    end;
    
    return;
end;

local getCleanName = function(humanTypeAddress)
    local objectNameAddress = safeReadInt64(humanTypeAddress + gameOffsets.cleanName);

    if (objectNameAddress ~= nil and objectNameAddress ~= 0) then
        return safeReadString(objectNameAddress + 0x10, 256);
    end;
    
    return;
end;

local getVisualState = function(entityAddress)
    return safeReadInt64(entityAddress + gameOffsets.visualState);
end;

local getPosition = function(visualStateAddress)
    return safeReadVector3(visualStateAddress + gameOffsets.position);
end;

-- @UPDATE

local menuCache = { };

local updateMenuRelated = function()
    menuCache.playersEnabled = menu.playersEnabled:get();

    menuCache.playersEnabledKeybind = menu.playersEnabledKeybind:is_active();

    menuCache.playersName = menu.playersName:get();

    menuCache.playersNameColorR, menuCache.playersNameColorG, menuCache.playersNameColorB, menuCache.playersNameColorA = menu.playersNameColor:get();

    menuCache.playersDistance = menu.playersDistance:get();

    menuCache.playersMaximumDistance = menu.playersMaximumDistance:get();

    menuCache.zombiesEnabled = menu.zombiesEnabled:get();

    menuCache.zombiesEnabledKeybind = menu.zombiesEnabledKeybind:is_active();

    menuCache.zombiesName = menu.zombiesName:get();

    menuCache.zombiesNameColorR, menuCache.zombiesNameColorG, menuCache.zombiesNameColorB, menuCache.zombiesNameColorA = menu.zombiesNameColor:get();

    menuCache.zombiesDistance = menu.zombiesDistance:get();

    menuCache.zombiesMaximumDistance = menu.zombiesMaximumDistance:get();

    menuCache.animalsEnabled = menu.animalsEnabled:get();

    menuCache.animalsEnabledKeybind = menu.animalsEnabledKeybind:is_active();

    menuCache.animalsName = menu.animalsName:get();

    menuCache.animalsNameColorR, menuCache.animalsNameColorG, menuCache.animalsNameColorB, menuCache.animalsNameColorA = menu.animalsNameColor:get();

    menuCache.animalsDistance = menu.animalsDistance:get();

    menuCache.animalsMaximumDistance = menu.animalsMaximumDistance:get();

    menuCache.vehiclesEnabled = menu.vehiclesEnabled:get();

    menuCache.vehiclesEnabledKeybind = menu.vehiclesEnabledKeybind:is_active();

    menuCache.vehiclesName = menu.vehiclesName:get();

    menuCache.vehiclesNameColorR, menuCache.vehiclesNameColorG, menuCache.vehiclesNameColorB, menuCache.vehiclesNameColorA = menu.vehiclesNameColor:get();

    menuCache.vehiclesDistance = menu.vehiclesDistance:get();

    menuCache.vehiclesMaximumDistance = menu.vehiclesMaximumDistance:get();

    menuCache.coordinatesEnabled = menu.coordinatesEnabled:get();

    menuCache.coordinatesColorR, menuCache.coordinatesColorG, menuCache.coordinatesColorB, menuCache.coordinatesColorA = menu.coordinatesColor:get();

    menuCache.itemsEnabled = menu.itemsEnabled:get();

    menuCache.itemsEnabledKeybind = menu.itemsEnabledKeybind:is_active();

    menuCache.itemsName = menu.itemsName:get();

    menuCache.itemsNameColorR, menuCache.itemsNameColorG, menuCache.itemsNameColorB, menuCache.itemsNameColorA = menu.itemsNameColor:get();

    menuCache.itemsDistance = menu.itemsDistance:get();

    menuCache.itemsMaximumDistance = menu.itemsMaximumDistance:get();

    return;
end;

local gameCache = { };

local updateGameRelated = function()
    gameCache.world = getWorld();

    if (gameCache.world == nil or gameCache.world == 0) then
        gameCache.isValid = false;

        return;
    end;

    gameCache.camera = getCamera(gameCache.world);

    if (gameCache.camera == nil or gameCache.camera == 0) then
        gameCache.isValid = false;

        return;
    end;

    gameCache.viewport = getViewport(gameCache.camera);

    if (gameCache.viewport == nil or gameCache.viewport == 0) then
        gameCache.isValid = false;

        return;
    end;

    gameCache.invertedViewTranslation = getInvertedViewTranslation(gameCache.camera);

    if (gameCache.invertedViewTranslation == nil or gameCache.invertedViewTranslation == 0) then
        gameCache.isValid = false;

        return;
    end;

    gameCache.invertedViewRight = getInvertedViewRight(gameCache.camera);

    if (gameCache.invertedViewRight == nil or gameCache.invertedViewRight == 0) then
        gameCache.isValid = false;

        return;
    end;

    gameCache.invertedViewUp = getInvertedViewUp(gameCache.camera);

    if (gameCache.invertedViewUp == nil or gameCache.invertedViewUp == 0) then
        gameCache.isValid = false;

        return;
    end;

    gameCache.invertedViewForward = getInvertedViewForward(gameCache.camera);

    if (gameCache.invertedViewForward == nil or gameCache.invertedViewForward == 0) then
        gameCache.isValid = false;

        return;
    end;

    gameCache.projectionD1 = getProjectionD1(gameCache.camera);

    if (gameCache.projectionD1 == nil or gameCache.projectionD1 == 0) then
        gameCache.isValid = false;

        return;
    end;

    gameCache.projectionD2 = getProjectionD2(gameCache.camera);

    if (gameCache.projectionD2 == nil or gameCache.projectionD2 == 0) then
        gameCache.isValid = false;

        return;
    end;

    gameCache.localPlayer = getLocalPlayer(gameCache.world);

    if (gameCache.localPlayer == nil or gameCache.localPlayer == 0) then
        gameCache.isValid = false;

        return;
    end;

    gameCache.localPlayerVisualState = getVisualState(gameCache.localPlayer);

    if (gameCache.localPlayerVisualState == nil or gameCache.localPlayerVisualState == 0) then
        gameCache.isValid = false;

        return;
    end;

    gameCache.localPlayerPosition = getPosition(gameCache.localPlayerVisualState);

    if (gameCache.localPlayerPosition == nil or gameCache.localPlayerPosition == 0) then
        gameCache.isValid = false;

        return;
    end;

    gameCache.nearEntityList = getNearEntityList(gameCache.world);

    if (gameCache.nearEntityList == nil or gameCache.nearEntityList == 0) then
        gameCache.isValid = false;

        return;
    end;

    gameCache.farEntityList = getFarEntityList(gameCache.world);

    if (gameCache.farEntityList == nil or gameCache.farEntityList == 0) then
        gameCache.isValid = false;

        return;
    end;

    gameCache.itemList = getItemList(gameCache.world);

    if (gameCache.itemList == nil or gameCache.itemList == 0) then
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

    local fullEntityList = { };

    local nearEntityListSize = safeReadInt32(gameCache.world + gameOffsets.nearEntityList + 0x8);

    local nearEntityListNumeration = 0;

    while (nearEntityListNumeration < nearEntityListSize) do
        local entity = safeReadInt64(gameCache.nearEntityList + (nearEntityListNumeration * 0x8));

        if (entity ~= nil or entity ~= 0) then
            local entityId = getNetworkId(entity);

            if (entityId ~= nil) then
                table.insert(fullEntityList, entity);
            end;
        end;

        nearEntityListNumeration = (nearEntityListNumeration + 1);
    end;

    local farEntityListSize = safeReadInt32(gameCache.world + gameOffsets.farEntityList + 0x8);

    local farEntityListNumeration = 0;

    while (farEntityListNumeration < farEntityListSize) do
        local entity = safeReadInt64(gameCache.farEntityList + (farEntityListNumeration * 0x8));

        if (entity ~= nil or entity ~= 0) then
            local entityId = getNetworkId(entity);

            if (entityId ~= nil) then
                table.insert(fullEntityList, entity);
            end;
        end;

        farEntityListNumeration = (farEntityListNumeration + 1);
    end;

    for i, entity in pairs(fullEntityList) do
        if (entity == nil or entity == 0) then
            goto skipEntity;
        end;

        if (entity == gameCache.localPlayer) then
            goto skipEntity;
        end;

        local entityHumanType = getHumanType(entity);

        if (entityHumanType == nil or entityHumanType == 0) then
            goto skipEntity;
        end;

        local entityCategoryName = getCategoryName(entityHumanType);

        if (entityCategoryName == nil or entityCategoryName == 0) then
            goto skipEntity;
        end;

        local entityObjectName = getObjectName(entityHumanType);

        if (entityObjectName == nil or entityObjectName == 0) then
            goto skipEntity;
        end;

        local entityCleanName = getCleanName(entityHumanType);

        if (entityCleanName == nil or entityCleanName == 0) then
            goto skipEntity;
        end;

        local entityVisualState = getVisualState(entity);

        if (entityVisualState == nil or entityVisualState == 0) then
            goto skipEntity;
        end;

        local entityPosition = getPosition(entityVisualState);

        if (entityPosition == nil or entityPosition == 0) then
            goto skipEntity;
        end;

        local entityDistance = getDistance3D(gameCache.localPlayerPosition, entityPosition);

        if (entityDistance == nil) then
            goto skipEntity;
        end;

        local entityScreenPosition = worldToScreen(entityPosition, gameCache.viewport, gameCache.invertedViewTranslation, gameCache.invertedViewRight, gameCache.invertedViewUp, gameCache.invertedViewForward, gameCache.projectionD1, gameCache.projectionD2);

        if (entityScreenPosition == nil or entityScreenPosition == 0) then
            goto skipEntity;
        end;

        if (entityCategoryName == "dayzplayer") then
            if (not menuCache.playersEnabled or not menuCache.playersEnabledKeybind) then
                goto skipEntity;
            end;

            if (entityDistance > menuCache.playersMaximumDistance) then
                goto skipEntity;
            end;

            if (menuCache.playersName) then
                local text = tostring(entityCleanName);

                if (menuCache.playersDistance) then
                    text = (text .. " (" .. math.floor(entityDistance) .. "M)");
                end;

                local textWidth, textHeight = render.measure_text(defaultFont, text);

                local textX, textY = math.floor(entityScreenPosition.x - (textWidth / 2)), math.floor(entityScreenPosition.y);

                render.draw_text(defaultFont, text, textX + 1, textY + 1, 0, 0, 0, menuCache.playersNameColorA, 1, 0, 0, 0, 0);

                render.draw_text(defaultFont, text, textX, textY, menuCache.playersNameColorR, menuCache.playersNameColorG, menuCache.playersNameColorB, menuCache.playersNameColorA, 1, 0, 0, 0, 0);
            end;
        elseif (entityCategoryName == "dayzinfected") then
            if (not menuCache.zombiesEnabled or not menuCache.zombiesEnabledKeybind) then
                goto skipEntity;
            end;

            if (entityDistance > menuCache.zombiesMaximumDistance) then
                goto skipEntity;
            end;
            
            if (menuCache.zombiesName) then
                local text = tostring(entityCleanName);

                if (menuCache.zombiesDistance) then
                    text = (text .. " (" .. math.floor(entityDistance) .. "M)");
                end;

                local textWidth, textHeight = render.measure_text(defaultFont, text);

                local textX, textY = math.floor(entityScreenPosition.x - (textWidth / 2)), math.floor(entityScreenPosition.y);

                render.draw_text(defaultFont, text, textX + 1, textY + 1, 0, 0, 0, menuCache.zombiesNameColorA, 1, 0, 0, 0, 0);

                render.draw_text(defaultFont, text, textX, textY, menuCache.zombiesNameColorR, menuCache.zombiesNameColorG, menuCache.zombiesNameColorB, menuCache.zombiesNameColorA, 1, 0, 0, 0, 0);
            end;
        elseif (entityCategoryName == "dayzanimal") then
            if (not menuCache.animalsEnabled or not menuCache.animalsEnabledKeybind) then
                goto skipEntity;
            end;

            if (entityDistance > menuCache.animalsMaximumDistance) then
                goto skipEntity;
            end;

            if (menuCache.animalsName) then
                local text = tostring(entityCleanName);

                if (menuCache.animalsDistance) then
                    text = (text .. " (" .. math.floor(entityDistance) .. "M)");
                end;

                local textWidth, textHeight = render.measure_text(defaultFont, text);

                local textX, textY = math.floor(entityScreenPosition.x - (textWidth / 2)), math.floor(entityScreenPosition.y);

                render.draw_text(defaultFont, text, textX + 1, textY + 1, 0, 0, 0, menuCache.animalsNameColorA, 1, 0, 0, 0, 0);

                render.draw_text(defaultFont, text, textX, textY, menuCache.animalsNameColorR, menuCache.animalsNameColorG, menuCache.animalsNameColorB, menuCache.animalsNameColorA, 1, 0, 0, 0, 0);
            end;
        elseif (entityCategoryName == "car") then
            if (not menuCache.vehiclesEnabled or not menuCache.vehiclesEnabledKeybind) then
                goto skipEntity;
            end;

            if (entityDistance > menuCache.vehiclesMaximumDistance) then
                goto skipEntity;
            end;

            if (menuCache.vehiclesName) then
                local text = tostring(entityCleanName);

                if (menuCache.vehiclesDistance) then
                    text = (text .. " (" .. math.floor(entityDistance) .. "M)");
                end;

                local textWidth, textHeight = render.measure_text(defaultFont, text);

                local textX, textY = math.floor(entityScreenPosition.x - (textWidth / 2)), math.floor(entityScreenPosition.y);

                render.draw_text(defaultFont, text, textX + 1, textY + 1, 0, 0, 0, menuCache.vehiclesNameColorA, 1, 0, 0, 0, 0);

                render.draw_text(defaultFont, text, textX, textY, menuCache.vehiclesNameColorR, menuCache.vehiclesNameColorG, menuCache.vehiclesNameColorB, menuCache.vehiclesNameColorA, 1, 0, 0, 0, 0);
            end;
        end;

        ::skipEntity::
    end;

    return;
end;

local updateCheatRelated = function()
    if (not gameCache.isValid) then
        return;
    end;
    
    if (menuCache.coordinatesEnabled) then
        local text = ("X: " .. tostring(math.floor(gameCache.localPlayerPosition.x)) .. " Z: " .. tostring(math.floor(gameCache.localPlayerPosition.z)));

        local textWidth, textHeight = render.measure_text(bigFont, text);

        local textX, textY = math.floor((screenWidth / 2) - (textWidth / 2)), math.floor(20);

        render.draw_text(bigFont, text, textX + 1, textY + 1, 0, 0, 0, menuCache.coordinatesColorA, 1, 0, 0, 0, 0);

        render.draw_text(bigFont, text, textX, textY, menuCache.coordinatesColorR, menuCache.coordinatesColorG, menuCache.coordinatesColorB, menuCache.coordinatesColorA, 1, 0, 0, 0, 0);
    end;

    return;
end;

local updateItemRelated = function()
    if (not gameCache.isValid) then
        return;
    end;

    local fullItemList = { };

    local itemListSize = safeReadInt32(gameCache.world + gameOffsets.itemList + 0x8);

    local itemListNumeration = 0;

    while (itemListNumeration < itemListSize) do
        local item = safeReadInt64(gameCache.itemList + (itemListNumeration * 0x18) + 0x8);

        if (item ~= nil or item ~= 0) then
            local itemFlag = safeReadInt32(gameCache.itemList + (itemListNumeration * 0x18));

            if (itemFlag == 1) then
                table.insert(fullItemList, item);
            end;
        end;

        itemListNumeration = (itemListNumeration + 1);
    end;

    for i, item in pairs(fullItemList) do
        if (item == nil or item == 0) then
            goto skipItem;
        end;

        local itemHumanType = getHumanType(item);

        if (itemHumanType == nil or itemHumanType == 0) then
            goto skipItem;
        end;

        local itemCategoryName = getCategoryName(itemHumanType);

        if (itemCategoryName == nil or itemCategoryName == 0) then
            goto skipItem;
        end;

        local itemObjectName = getObjectName(itemHumanType);

        if (itemObjectName == nil or itemObjectName == 0) then
            goto skipItem;
        end;

        local itemCleanName = getCleanName(itemHumanType);

        if (itemCleanName == nil or itemCleanName == 0) then
            goto skipItem;
        end;

        local itemVisualState = getVisualState(item);

        if (itemVisualState == nil or itemVisualState == 0) then
            goto skipItem;
        end;

        local itemPosition = getPosition(itemVisualState);

        if (itemPosition == nil or itemPosition == 0) then
            goto skipItem;
        end;

        local itemDistance = getDistance3D(gameCache.localPlayerPosition, itemPosition);

        if (itemDistance == nil) then
            goto skipItem;
        end;

        local itemScreenPosition = worldToScreen(itemPosition, gameCache.viewport, gameCache.invertedViewTranslation, gameCache.invertedViewRight, gameCache.invertedViewUp, gameCache.invertedViewForward, gameCache.projectionD1, gameCache.projectionD2);

        if (itemScreenPosition == nil or itemScreenPosition == 0) then
            goto skipItem;
        end;

        if (not menuCache.itemsEnabled or not menuCache.itemsEnabledKeybind) then
            goto skipItem;
        end;

        if (itemDistance > menuCache.itemsMaximumDistance) then
            goto skipItem;
        end;

        if (menuCache.itemsName) then
            local text = tostring(itemCleanName);

            if (menuCache.itemsDistance) then
                text = (text .. " (" .. math.floor(itemDistance) .. "M)");
            end;

            local textWidth, textHeight = render.measure_text(defaultFont, text);

            local textX, textY = math.floor(itemScreenPosition.x - (textWidth / 2)), math.floor(itemScreenPosition.y);

            render.draw_text(defaultFont, text, textX + 1, textY + 1, 0, 0, 0, menuCache.itemsNameColorA, 1, 0, 0, 0, 0);

            render.draw_text(defaultFont, text, textX, textY, menuCache.itemsNameColorR, menuCache.itemsNameColorG, menuCache.itemsNameColorB, menuCache.itemsNameColorA, 1, 0, 0, 0, 0);
        end;

        ::skipItem::
    end;

    return;
end;

local updateAll = function()
    if (proc.is_attached()) then
        updateMenuRelated();
        
        updateGameRelated();

        updateEntityRelated();

        updateItemRelated();

        updateCheatRelated();
    end;

    return;
end;

-- @REGISTER

engine.register_on_engine_tick(updateAll);