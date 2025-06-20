Screen = { };

Screen.Width, Screen.Height = render.get_viewport_size();

-- @FONTS

Fonts = { };

Fonts.ESP = render.create_font("Smallest Pixel.ttf", 10, 400);

-- @GAME

Game = { };

Game.Objects = { };

Game.Aimbot = { };

Game.Cache = { };

Game.Offsets = {
    VisualEngineToDatamodel = 0x720,

    FakeDatamodelToDatamodel = 0x1B8,

    VisualEngine = 0x6535DD8,

    LocalPlayer = 0x128,

    Viewmatrix = 0x4D0,

    Workspace = 0x180,

    GameId = 0x198,

    WalkSpeedCheck = 0x3B0,

    WalkSpeed = 0x1D8,

    JumpPower = 0x1B8,

    ModelInstance = 0x330,

    StringLength = 0x10,

    ClassName = 0x18,

    Children = 0x80,

    Primitive = 0x178,

    Position = 0x140,

    Rotation = 0x124,

    Velocity = 0x14C,

    MaxHealth = 0x1BC,

    Health = 0x19C,

    RigType = 0x1D0,

    MoveDirection = 0x160,

    Size = 0x10,

    Name = 0x78,

    Team = 0x258
};

-- @STRUCTURE

Structure = { };

Structure.R6 = {
    "Head",

    "Torso",

    "Left Arm",

    "Right Arm",

    "Left Leg",

    "Right Leg"
};

Structure.R15 = {
    "Head",

    "UpperTorso",

    "LowerTorso",

    "LeftUpperArm",

    "LeftLowerArm",

    "LeftHand",

    "RightUpperArm",

    "RightLowerArm",

    "RightHand",

    "LeftUpperLeg",

    "LeftLowerLeg",

    "LeftFoot",

    "RightUpperLeg",

    "RightLowerLeg",

    "RightFoot"
};

-- @ATTACH

Attach = { };

Attach.Run = function()
    proc.attach_by_name("RobloxPlayerBeta.exe");

    if (proc.is_attached()) then
        Game.BaseAddress = proc.base_address();

        if (Game.BaseAddress ~= nil and Game.BaseAddress ~= 0) then
            return true;
        end;
    end;

    return false;
end;

if (not Attach.Run()) then
    engine.log("Failed attaching to Roblox!", 255, 75, 75, 255);
    
    return nil;
end;

-- @MENU

do
    Menu = { };

    Menu.Elements = { };

    Menu.Colors = { };

    Menu.Keybinds = { };

    Menu.Cache = { };

    Menu.VisualsTab = gui.get_tab("visuals");

    Menu.PlayersPanel = Menu.VisualsTab:create_panel("Players", false);

    Menu.Elements.PlayersEnabled = Menu.PlayersPanel:add_checkbox("Enabled");

    Menu.Keybinds.PlayersEnabledKeybind = Menu.PlayersPanel:add_keybind("Enabled Keybind", 0, key_mode.always_on);

    Menu.Elements.PlayersName = Menu.PlayersPanel:add_checkbox("Name");

    Menu.Colors.PlayersNameColor = Menu.PlayersPanel:add_color_picker("Name Color", 255, 255, 255, 255);

    Menu.Elements.PlayersTool = Menu.PlayersPanel:add_checkbox("Tool");

    Menu.Colors.PlayersToolColor = Menu.PlayersPanel:add_color_picker("Tool Color", 255, 255, 255, 255);

    Menu.Elements.PlayersBox = Menu.PlayersPanel:add_checkbox("Box");

    Menu.Colors.PlayersBoxColor = Menu.PlayersPanel:add_color_picker("Box Color", 255, 255, 255, 255);

    Menu.Elements.PlayersBoxFill = Menu.PlayersPanel:add_checkbox("Box Fill");

    Menu.Colors.PlayersBoxFillColor = Menu.PlayersPanel:add_color_picker("Box Fill Color", 0, 0, 0, 70);

    Menu.Elements.PlayersHealth = Menu.PlayersPanel:add_checkbox("Health");

    Menu.Colors.PlayersHealthColor = Menu.PlayersPanel:add_color_picker("Health Color", 255, 125, 125, 255);

    Menu.Elements.PlayersHealthText = Menu.PlayersPanel:add_checkbox("Health Text");

    Menu.Colors.PlayersHealthTextColor = Menu.PlayersPanel:add_color_picker("Health Text Color", 255, 255, 255, 255);

    Menu.Elements.PlayersDistance = Menu.PlayersPanel:add_checkbox("Distance");

    Menu.Elements.PlayersMaximumDistance = Menu.PlayersPanel:add_slider_int("Maximum Distance", 0, 10000, 10000);

    Menu.TeammatesPanel = Menu.VisualsTab:create_panel("Teammates", false);

    Menu.Elements.TeammatesEnabled = Menu.TeammatesPanel:add_checkbox("Enabled");

    Menu.Keybinds.TeammatesEnabledKeybind = Menu.TeammatesPanel:add_keybind("Enabled Keybind", 0, key_mode.always_on);

    Menu.Elements.TeammatesName = Menu.TeammatesPanel:add_checkbox("Name");

    Menu.Colors.TeammatesNameColor = Menu.TeammatesPanel:add_color_picker("Name Color", 75, 255, 75, 255);

    Menu.Elements.TeammatesTool = Menu.TeammatesPanel:add_checkbox("Tool");

    Menu.Colors.TeammatesToolColor = Menu.TeammatesPanel:add_color_picker("Tool Color", 75, 255, 75, 255);

    Menu.Elements.TeammatesBox = Menu.TeammatesPanel:add_checkbox("Box");

    Menu.Colors.TeammatesBoxColor = Menu.TeammatesPanel:add_color_picker("Box Color", 75, 255, 75, 255);

    Menu.Elements.TeammatesBoxFill = Menu.TeammatesPanel:add_checkbox("Box Back");

    Menu.Colors.TeammatesBoxFillColor = Menu.TeammatesPanel:add_color_picker("Box Back Color", 0, 0, 0, 70);

    Menu.Elements.TeammatesHealth = Menu.TeammatesPanel:add_checkbox("Health");

    Menu.Colors.TeammatesHealthColor = Menu.TeammatesPanel:add_color_picker("Health Color", 75, 255, 75, 255);

    Menu.Elements.TeammatesHealthText = Menu.TeammatesPanel:add_checkbox("Health Text");

    Menu.Colors.TeammatesHealthTextColor = Menu.TeammatesPanel:add_color_picker("Health Text Color", 75, 255, 75, 255);

    Menu.Elements.TeammatesDistance = Menu.TeammatesPanel:add_checkbox("Distance");

    Menu.Elements.TeammatesMaximumDistance = Menu.TeammatesPanel:add_slider_int("Maximum Distance", 0, 10000, 10000);

    Menu.AimbotTab = gui.get_tab("aimbot");

    Menu.AimbotPanel = Menu.AimbotTab:create_panel("Aimbot", false);

    Menu.Elements.AimbotEnabled = Menu.AimbotPanel:add_checkbox("Enabled");

    Menu.Keybinds.AimbotEnabledKeybind = Menu.AimbotPanel:add_keybind("Enabled Keybind", 6, key_mode.onhotkey);

    Menu.Elements.AimbotDrawFOV = Menu.AimbotPanel:add_checkbox("Draw FOV");

    Menu.Colors.AimbotDrawFOVColor = Menu.AimbotPanel:add_color_picker("Draw FOV Color", 255, 255, 255, 255);

    Menu.Elements.AimbotIgnoreTeam = Menu.AimbotPanel:add_checkbox("Ignore Team");

    Menu.Elements.AimbotHitbox = Menu.AimbotPanel:add_single_select("Hitbox", {"Head", "Body"}, 0);

    Menu.Elements.AimbotTarget = Menu.AimbotPanel:add_single_select("Target", {"Mouse", "Distance"}, 0);

    Menu.Elements.AimbotFOV = Menu.AimbotPanel:add_slider_int("FOV", 1, 90, 15);

    Menu.Elements.AimbotSmoothing = Menu.AimbotPanel:add_slider_int("Smoothing", 0, 100, 50);

    Menu.SettingsTab = gui.get_tab("settings");

    Menu.CharacterPanel = Menu.SettingsTab:create_panel("Character", false);

    Menu.Elements.WalkSpeedEnabled = Menu.CharacterPanel:add_checkbox("Walk Speed");

    Menu.Keybinds.WalkSpeedEnabledKeybind = Menu.CharacterPanel:add_keybind("Enabled Keybind", 0, key_mode.always_on);

    Menu.Elements.WalkSpeedMode = Menu.CharacterPanel:add_single_select("Mode", {"Spoof", "Velocity"}, 0);

    Menu.Elements.WalkSpeedValue = Menu.CharacterPanel:add_slider_int("Speed", 1, 500, 100);

    Menu.Elements.JumpPowerEnabled = Menu.CharacterPanel:add_checkbox("Jump Power");

    Menu.Keybinds.JumpPowerEnabledKeybind = Menu.CharacterPanel:add_keybind("Enabled Keybind", 0, key_mode.always_on);

    Menu.Elements.JumpPowerMode = Menu.CharacterPanel:add_single_select("Mode", {"Spoof", "Velocity"}, 0);

    Menu.Elements.JumpPowerValue = Menu.CharacterPanel:add_slider_int("Height", 1, 500, 100);
end;

-- @MEMORY

Memory = { };

Memory.ReadInt64 = function(Address)
    local ReadValue;
    
    if (proc.is_attached() and Address ~= nil and Address ~= 0) then
        pcall(function()
            ReadValue = proc.read_int64(Address);
        end);
    end;

    return ReadValue;
end;

Memory.WriteInt64 = function(Address, Value)
    if (proc.is_attached() and Address ~= nil and Address ~= 0 and Value ~= nil) then
        proc.write_int64(Address, Value);

        return true;
    end;

    return false;
end;

Memory.ReadInt32 = function(Address)
    local ReadValue;
    
    if (proc.is_attached() and Address ~= nil and Address ~= 0) then
        pcall(function()
            ReadValue = proc.read_int32(Address);
        end);
    end;

    return ReadValue;
end;

Memory.WriteInt32 = function(Address, Value)
    if (proc.is_attached() and Address ~= nil and Address ~= 0 and Value ~= nil) then
        proc.write_int32(Address, Value);

        return true;
    end;

    return false;
end;

Memory.ReadInt16 = function(Address)
    local ReadValue;
    
    if (proc.is_attached() and Address ~= nil and Address ~= 0) then
        pcall(function()
            ReadValue = proc.read_int16(Address);
        end);
    end;

    return ReadValue;
end;

Memory.WriteInt16 = function(Address, Value)
    if (proc.is_attached() and Address ~= nil and Address ~= 0 and Value ~= nil) then
        proc.write_int16(Address, Value);

        return true;
    end;

    return false;
end;

Memory.ReadInt8 = function(Address)
    local ReadValue;
    
    if (proc.is_attached() and Address ~= nil and Address ~= 0) then
        pcall(function()
            ReadValue = proc.read_int8(Address);
        end);
    end;

    return ReadValue;
end;

Memory.WriteInt8 = function(Address, Value)
    if (proc.is_attached() and Address ~= nil and Address ~= 0 and Value ~= nil) then
        proc.write_int8(Address, Value);

        return true;
    end;

    return false;
end;

Memory.ReadFloat = function(Address)
    local ReadValue;
    
    if (proc.is_attached() and Address ~= nil and Address ~= 0) then
        pcall(function()
            ReadValue = proc.read_float(Address);
        end);
    end;

    return ReadValue;
end;

Memory.WriteFloat = function(Address, Value)
    if (proc.is_attached() and Address ~= nil and Address ~= 0 and Value ~= nil) then
        proc.write_float(Address, Value);

        return true;
    end;

    return false;
end;

Memory.ReadString = function(Address, Size)
    local ReadValue;
    
    if (proc.is_attached() and Address ~= nil and Address ~= 0 and Size ~= nil and Size ~= 0) then
        pcall(function()
            ReadValue = proc.read_string(Address, Size);
        end);
    end;

    return ReadValue;
end;

Memory.WriteString = function(Address, Value)
    if (proc.is_attached() and Address ~= nil and Address ~= 0 and Value ~= nil) then
        proc.write_string(Address, Value);

        return true;
    end;

    return false;
end;

Memory.ReadVector2 = function(Address)
    local ReadValue;
    
    if (proc.is_attached() and Address ~= nil and Address ~= 0) then
        pcall(function()
            ReadValue = vec2.read_float(Address);
        end);
    end;

    return ReadValue;
end;

Memory.WriteVector2 = function(Address, Value)
    if (proc.is_attached() and Address ~= nil and Address ~= 0 and Value ~= nil) then
        vec2.write_float(Address, Value);

        return true;
    end;

    return false;
end;

Memory.ReadVector3 = function(Address)
    local ReadValue;
    
    if (proc.is_attached() and Address ~= nil and Address ~= 0) then
        pcall(function()
            ReadValue = vec3.read_float(Address);
        end);
    end;

    return ReadValue;
end;

Memory.WriteVector3 = function(Address, Value)
    if (proc.is_attached() and Address ~= nil and Address ~= 0 and Value ~= nil) then
        vec3.write_float(Address, Value);

        return true;
    end;

    return false;
end;

Memory.ReadMatrix = function(Address)
    local ReadValue;

    if (proc.is_attached() and Address ~= nil and Address ~= 0) then
        pcall(function()
            ReadValue = mat4.read(Address);
        end);
    end;

    return ReadValue;
end;

-- @SDK

SDK = { };

SDK.GetScreenPosition = function(WorldPosition, Viewmatrix)
    if (WorldPosition ~= nil and WorldPosition ~= 0 and Viewmatrix ~= nil and Viewmatrix ~= 0) then
        local Vector4 = vec4(
            ((WorldPosition.x * Viewmatrix:get(1, 1)) + (WorldPosition.y * Viewmatrix:get(1, 2)) + (WorldPosition.z * Viewmatrix:get(1, 3)) + Viewmatrix:get(1, 4)),

            ((WorldPosition.x * Viewmatrix:get(2, 1)) + (WorldPosition.y * Viewmatrix:get(2, 2)) + (WorldPosition.z * Viewmatrix:get(2, 3)) + Viewmatrix:get(2, 4)),

            ((WorldPosition.x * Viewmatrix:get(3, 1)) + (WorldPosition.y * Viewmatrix:get(3, 2)) + (WorldPosition.z * Viewmatrix:get(3, 3)) + Viewmatrix:get(3, 4)),

            ((WorldPosition.x * Viewmatrix:get(4, 1)) + (WorldPosition.y * Viewmatrix:get(4, 2)) + (WorldPosition.z * Viewmatrix:get(4, 3)) + Viewmatrix:get(4, 4))
        );
        
        if (Vector4.w > 0.1) then
            local Vector3 = vec3(
                (Vector4.x * (1 / Vector4.w)),
                
                (Vector4.y * (1 / Vector4.w)),
            
                (Vector4.z * (1 / Vector4.w))
            );

            local Vector2 = vec2(
                ((Screen.Width / 2 * Vector3.x) + (Vector3.x + Screen.Width / 2)),
                
                (-(Screen.Height / 2 * Vector3.y) + (Vector3.y + Screen.Height / 2))
            );

            return Vector2;
        end;
    end;

    return nil;
end;

SDK.GetScreenDistance = function(FirstVector, SecondVector)
    local Distance2D = vec2(
        (FirstVector.x - SecondVector.x),

        (FirstVector.y - SecondVector.y)
    );

    local CalculatedDistance = math.sqrt(Distance2D.x * Distance2D.x + Distance2D.y * Distance2D.y);

    return CalculatedDistance;
end;

SDK.GetName = function(ObjectAddress, FromClass)
    if (ObjectAddress ~= nil and ObjectAddress ~= 0) then
        local NameAddress = Memory.ReadInt64(ObjectAddress + (FromClass and Game.Offsets.ClassName or Game.Offsets.Name));

        if (NameAddress ~= nil and NameAddress ~= 0) then
            local NameLength = Memory.ReadInt64(NameAddress + Game.Offsets.StringLength);

            if (NameLength ~= nil and NameLength ~= 0 and NameLength >= 16) then
                local NameSubAddress = Memory.ReadInt64(NameAddress + (FromClass and 0x8 or 0x0));

                if (NameSubAddress ~= nil and NameSubAddress ~= 0) then
                    local NameString = Memory.ReadString(NameSubAddress, 256);

                    return NameString;
                end;
            elseif (NameLength < 16) then
                local NameString = Memory.ReadString(NameAddress, 256);

                return NameString;
            end;
        end;
    end;

    return nil;
end;

SDK.GetChildren = function(ObjectAddress)
    if (ObjectAddress ~= nil and ObjectAddress ~= 0) then
        local ChildrenList = { };

        local ChildrenStart = Memory.ReadInt64(ObjectAddress + Game.Offsets.Children);

        if (ChildrenStart ~= nil and ChildrenStart ~= 0) then
            local ChildrenEnd = Memory.ReadInt64(ChildrenStart + Game.Offsets.Size);

            if (ChildrenEnd ~= nil and ChildrenEnd ~= 0) then
                local Child = Memory.ReadInt64(ChildrenStart);

                if (Child ~= nil and Child ~= 0) then
                    while (Child < ChildrenEnd) do
                        local ChildAddress = Memory.ReadInt64(Child);
                        
                        if (ChildAddress ~= nil and ChildAddress ~= 0 and SDK.GetName(ChildAddress, false) ~= nil and SDK.GetName(ChildAddress, true) ~= nil) then
                            table.insert(ChildrenList, ChildAddress);
                        end;

                        Child = (Child + 0x10);
                    end;

                    return ChildrenList;
                end;
            end;
        end;
    end;

    return nil;
end;

SDK.FindFirstChild = function(ObjectAddress, FromClass, Name)
    if (ObjectAddress ~= nil or ObjectAddress ~= 0) then
        local ChildrenList = SDK.GetChildren(ObjectAddress);

        if (ChildrenList ~= nil and ChildrenList ~= 0) then
            for Numeration, Object in pairs(ChildrenList) do
                if (Object ~= nil and Object ~= 0) then
                    if (Name == nil or Name == 0) then
                        return Object;
                    end;
                    
                    local ObjectName = SDK.GetName(Object, FromClass);
                    
                    if (ObjectName ~= nil and ObjectName == Name) then
                        return Object;
                    end;
                end;
            end;
        end;
    end;

    return nil;
end;

SDK.GetVisualEngine = function(BaseAddress)
    local VisualEngineAddress = Memory.ReadInt64(BaseAddress + Game.Offsets.VisualEngine);
    
    return VisualEngineAddress;
end;

SDK.GetViewmatrix = function(VisualEngineAddress)
    local ViewmatrixAddress = Memory.ReadMatrix(VisualEngineAddress + Game.Offsets.Viewmatrix);
    
    return ViewmatrixAddress;
end;

SDK.GetDatamodel = function(VisualEngineAddress)
    local FakeDatamodelAddress = Memory.ReadInt64(VisualEngineAddress + Game.Offsets.VisualEngineToDatamodel);

    if (FakeDatamodelAddress ~= nil and FakeDatamodelAddress ~= 0) then
        local DatamodelAddress = Memory.ReadInt64(FakeDatamodelAddress + Game.Offsets.FakeDatamodelToDatamodel);
    
        return DatamodelAddress;
    end;

    return nil;
end;

SDK.GetWorkspace = function(DatamodelAddress)
    local WorkspaceAddress = Memory.ReadInt64(DatamodelAddress + Game.Offsets.Workspace);
    
    return WorkspaceAddress;
end;

SDK.GetGameId = function(DatamodelAddress)
    local GameIdAddress = Memory.ReadInt64(DatamodelAddress + Game.Offsets.GameId);
    
    return GameIdAddress;
end;

SDK.GetLocalPlayer = function(PlayerServiceAddress)
    local LocalPlayerAddress = Memory.ReadInt64(PlayerServiceAddress + Game.Offsets.LocalPlayer);
    
    return LocalPlayerAddress;
end;

SDK.GetModelInstance = function(ObjectAddress)
    local ModelInstanceAddress = Memory.ReadInt64(ObjectAddress + Game.Offsets.ModelInstance);
    
    return ModelInstanceAddress;
end;

SDK.GetWorldPosition = function(ObjectAddress)
    if (ObjectAddress ~= nil and ObjectAddress ~= 0) then
        local PrimitiveAddress = Memory.ReadInt64(ObjectAddress + Game.Offsets.Primitive);

        if (PrimitiveAddress ~= nil and PrimitiveAddress ~= 0) then
            local PositionAddress = Memory.ReadVector3(PrimitiveAddress + Game.Offsets.Position);
        
            return PositionAddress;
        end;
    end;
    
    return nil;
end;

SDK.SetWorldPosition = function(ObjectAddress, Value)
    if (ObjectAddress ~= nil and ObjectAddress ~= 0 and Value ~= nil and Value ~= 0) then
        local PrimitiveAddress = Memory.ReadInt64(ObjectAddress + Game.Offsets.Primitive);

        if (PrimitiveAddress ~= nil and PrimitiveAddress ~= 0) then
            Memory.WriteVector3(PrimitiveAddress + Game.Offsets.Position, Value);
        
            return true;
        end;
    end;
    
    return false;
end;

SDK.GetWorldDistance = function(FirstVector, SecondVector)
    local Distance3D = vec3(
        (FirstVector.x - SecondVector.x),

        (FirstVector.y - SecondVector.y),

        (FirstVector.z - SecondVector.z)
    );

    local CalculatedDistance = math.sqrt(Distance3D.x * Distance3D.x + Distance3D.y * Distance3D.y + Distance3D.z * Distance3D.z);

    return CalculatedDistance;
end;

SDK.GetWorldVelocity = function(ObjectAddress)
    if (ObjectAddress ~= nil and ObjectAddress ~= 0) then
        local PrimitiveAddress = Memory.ReadInt64(ObjectAddress + Game.Offsets.Primitive);

        if (PrimitiveAddress ~= nil and PrimitiveAddress ~= 0) then
            local VelocityAddress = Memory.ReadVector3(PrimitiveAddress + Game.Offsets.Velocity);

            return VelocityAddress;
        end;
    end;
    
    return nil;
end;

SDK.SetWorldVelocity = function(ObjectAddress, Value)
    if (ObjectAddress ~= nil and ObjectAddress ~= 0 and Value ~= nil and Value ~= 0) then
        local PrimitiveAddress = Memory.ReadInt64(ObjectAddress + Game.Offsets.Primitive);

        if (PrimitiveAddress ~= nil and PrimitiveAddress ~= 0) then
            Memory.WriteVector3(PrimitiveAddress + Game.Offsets.Velocity, Value);

            return true;
        end;
    end;
    
    return false;
end;

SDK.GetWorldRotation = function(ObjectAddress)
    if (ObjectAddress ~= nil and ObjectAddress ~= 0) then
        local PrimitiveAddress = Memory.ReadInt64(ObjectAddress + Game.Offsets.Primitive);

        if (PrimitiveAddress ~= nil and PrimitiveAddress ~= 0) then
            local RotationAddress = Memory.ReadFloat(PrimitiveAddress + Game.Offsets.Rotation);

            return RotationAddress;
        end;
    end;
    
    return nil;
end;

SDK.SetWorldRotation = function(ObjectAddress, Value)
    if (ObjectAddress ~= nil and ObjectAddress ~= 0 and Value ~= nil and Value ~= 0) then
        local PrimitiveAddress = Memory.ReadInt64(ObjectAddress + Game.Offsets.Primitive);

        if (PrimitiveAddress ~= nil and PrimitiveAddress ~= 0) then
            Memory.WriteFloat(PrimitiveAddress + Game.Offsets.Rotation, Value);

            return true;
        end;
    end;
    
    return false;
end;

SDK.GetHealth = function(HumanoidAddress, IsMaximum)
    local HealthAddress = Memory.ReadFloat(HumanoidAddress + (IsMaximum and Game.Offsets.MaxHealth or Game.Offsets.Health));
    
    return HealthAddress;
end;

SDK.GetRigType = function(HumanoidAddress)
    local RigTypeAddress = Memory.ReadInt64(HumanoidAddress + Game.Offsets.RigType);
    
    return RigTypeAddress;
end;

SDK.GetMoveDirection = function(HumanoidAddress)
    local MoveDirectionAddress = Memory.ReadVector3(HumanoidAddress + Game.Offsets.MoveDirection);
    
    return MoveDirectionAddress;
end;

SDK.GetTeam = function(PlayerAddress)
    local TeamAddress = Memory.ReadInt64(PlayerAddress + Game.Offsets.Team);
    
    return TeamAddress;
end;

SDK.SetWalkSpeed = function(HumanoidAddress, Value)
    if (HumanoidAddress ~= nil and HumanoidAddress ~= 0) then
        Memory.WriteFloat(HumanoidAddress + Game.Offsets.WalkSpeedCheck, Value);

        Memory.WriteFloat(HumanoidAddress + Game.Offsets.WalkSpeed, Value);

        return true;
    end;

    return false;
end;

SDK.SetJumpPower = function(HumanoidAddress, Value)
    if (HumanoidAddress ~= nil and HumanoidAddress ~= 0) then
        Memory.WriteFloat(HumanoidAddress + Game.Offsets.JumpPower, Value);

        return true;
    end;

    return false;
end;

-- @FUNCTIONS

Functions = { };

Functions.UpdateStaticCache = function()
    if (Game.Cache.StaticValid) then
        local Datamodel = SDK.GetDatamodel(Game.Cache.VisualEngine);
        
        if (Game.Cache.Datamodel ~= Datamodel) then
            Game.Cache.StaticValid = false;
        end;
        
        return true;
    end;
    
    Game.Cache.VisualEngine = SDK.GetVisualEngine(Game.BaseAddress);
    
    if (Game.Cache.VisualEngine == nil or Game.Cache.VisualEngine == 0) then
        Game.Cache.StaticValid = false;

        return false;
    end;

    Game.Cache.Datamodel = SDK.GetDatamodel(Game.Cache.VisualEngine);

    if (Game.Cache.Datamodel == nil or Game.Cache.Datamodel == 0) then
        Game.Cache.StaticValid = false;

        return false;
    end;

    Game.Cache.GameId = SDK.GetGameId(Game.Cache.Datamodel);

    if (Game.Cache.GameId == nil or Game.Cache.GameId == 0) then
        Game.Cache.StaticValid = false;

        return false;
    end;

    Game.Cache.PlayerService = SDK.FindFirstChild(Game.Cache.Datamodel, true, "Players");

    if (Game.Cache.PlayerService == nil or Game.Cache.PlayerService == 0) then
        Game.Cache.StaticValid = false;

        return false;
    end;

    Game.Cache.LocalPlayer = SDK.GetLocalPlayer(Game.Cache.PlayerService);

    if (Game.Cache.LocalPlayer == nil or Game.Cache.LocalPlayer == 0) then
        Game.Cache.StaticValid = false;

        return false;
    end;
    
    Game.Cache.StaticValid = true;

    return true;
end;

Functions.UpdateDynamicCache = function()
    if (not Game.Cache.StaticValid) then
        Game.Cache.DynamicValid = false;

        return false;
    end;

    Game.Cache.Workspace = SDK.GetWorkspace(Game.Cache.Datamodel);

    if (Game.Cache.Workspace == nil or Game.Cache.Workspace == 0) then
        Game.Cache.StaticValid = false;

        return false;
    end;

    Game.Cache.Viewmatrix = SDK.GetViewmatrix(Game.Cache.VisualEngine);

    if (Game.Cache.Viewmatrix == nil or Game.Cache.Viewmatrix == 0) then
        Game.Cache.DynamicValid = false;
        
        return false;
    end;

    Game.Cache.LocalTeam = SDK.GetTeam(Game.Cache.LocalPlayer);

    if (Game.Cache.LocalTeam == nil) then
        Game.Cache.DynamicValid = false;
        
        return false;
    end;

    Game.Cache.LocalCharacter = SDK.GetModelInstance(Game.Cache.LocalPlayer);

    if (Game.Cache.LocalCharacter == nil or Game.Cache.LocalCharacter == 0) then
        Game.Cache.DynamicValid = false;
        
        return false;
    end;

    Game.Cache.LocalHumanoid = SDK.FindFirstChild(Game.Cache.LocalCharacter, false, "Humanoid");

    if (Game.Cache.LocalHumanoid == nil or Game.Cache.LocalHumanoid == 0) then
        Game.Cache.DynamicValid = false;
        
        return false;
    end;

    Game.Cache.LocalRigType = SDK.GetRigType(Game.Cache.LocalHumanoid);

    if (Game.Cache.LocalRigType == nil or (Game.Cache.LocalRigType ~= 0 and Game.Cache.LocalRigType ~= 1)) then
        Game.Cache.DynamicValid = false;
        
        return false;
    end;

    Game.Cache.LocalRootPart = SDK.FindFirstChild(Game.Cache.LocalCharacter, false, "HumanoidRootPart");

    if (Game.Cache.LocalRootPart == nil or Game.Cache.LocalRootPart == 0) then
        Game.Cache.DynamicValid = false;
        
        return false;
    end;

    Game.Cache.LocalPosition = SDK.GetWorldPosition(Game.Cache.LocalRootPart);

    if (Game.Cache.LocalPosition == nil or Game.Cache.LocalPosition == 0) then
        Game.Cache.DynamicValid = false;
        
        return false;
    end;

    Game.Cache.DynamicValid = true;
    
    return true;
end;

Functions.UpdateMenuCache = function()
    if (not Game.Cache.StaticValid or not Game.Cache.DynamicValid) then
        Menu.Cache = { };
        
        return false;
    end;
    
    for Numeration, Object in pairs(Menu.Elements) do
        Menu.Cache[Numeration] = Object:get();
    end;

    for Numeration, Object in pairs(Menu.Colors) do
        Menu.Cache[Numeration .. "R"], Menu.Cache[Numeration .. "G"], Menu.Cache[Numeration .. "B"], Menu.Cache[Numeration .. "A"] = Object:get();
    end;

    for Numeration, Object in pairs(Menu.Keybinds) do
        Menu.Cache[Numeration] = Object:is_active();
    end;

    return true;
end;

Functions.UpdateObjects = function()
    if (not Game.Cache.StaticValid or not Game.Cache.DynamicValid) then
        Game.Objects = { };
        
        return false;
    end;

    if (Game.Objects.Players == nil) then
        Game.Objects.Players = { };
    end;

    local ClosestWorldDistance = 1000000;

    local ClosestScreenDistance = 1000000;

    local MousePositionX, MousePositionY = input.get_mouse_position();

    local PlayerServiceChildren = SDK.GetChildren(Game.Cache.PlayerService);

    if (PlayerServiceChildren == nil or PlayerServiceChildren == 0) then
        goto SkipPlayers;
    end;

    for Numeration, Player in pairs(PlayerServiceChildren) do
        if (Player == nil or Player == 0) then
            goto SkipPlayer;
        end;

        if (Player == Game.Cache.LocalPlayer) then
            goto SkipPlayer;
        end;

        if (Game.Objects.Players[Player] ~= nil) then
            goto SkipPlayer;
        end;

        Game.Objects.Players[Player] = { };

        ::SkipPlayer::
    end;

    for Player, Data in pairs(Game.Objects.Players) do
        local TemporaryData = { };

        TemporaryData.Character = SDK.GetModelInstance(Player);

        if (TemporaryData.Character == nil or TemporaryData.Character == 0) then
            TemporaryData.Valid = false;
            
            goto SkipPlayerData;
        end;

        if (Data.Character ~= TemporaryData.Character or ((Data.Valid == nil or Data.Valid == 0 or Data.Valid == false) and (Data.Dead == nil or Data.Dead == 0 or Data.Dead == false))) then
            Game.Objects.Players[Player] = { };
            
            TemporaryData.Name = SDK.GetName(Player, false);

            if (TemporaryData.Name == nil or TemporaryData.Name == 0) then
                TemporaryData.Valid = false;
                
                goto SkipPlayerData;
            end;

            TemporaryData.Humanoid = SDK.FindFirstChild(TemporaryData.Character, false, "Humanoid");

            if (TemporaryData.Humanoid == nil or TemporaryData.Humanoid == 0) then
                TemporaryData.Valid = false;
                
                goto SkipPlayerData;
            end;

            TemporaryData.RootPart = SDK.FindFirstChild(TemporaryData.Character, false, "HumanoidRootPart");

            if (TemporaryData.RootPart == nil or TemporaryData.RootPart == 0) then
                TemporaryData.Valid = false;
                
                goto SkipPlayerData;
            end;

            TemporaryData.RigType = SDK.GetRigType(TemporaryData.Humanoid);

            if (TemporaryData.RigType == nil or (TemporaryData.RigType ~= 0 and TemporaryData.RigType ~= 1)) then
                TemporaryData.Valid = false;
                
                goto SkipPlayerData;
            end;

            TemporaryData.Structure = (TemporaryData.RigType == 0 and Structure.R6 or Structure.R15);

            TemporaryData.BodyParts = { };

            for Numeration, Object in pairs(TemporaryData.Structure) do
                local Part = SDK.FindFirstChild(TemporaryData.Character, false, Object);

                if (Part == nil or Part == 0) then
                    TemporaryData.Valid = false;
                    
                    goto SkipPlayerData;
                end;

                local Name = string.gsub(Object, "%s+", "");

                TemporaryData.BodyParts[Name] = Part;
            end;
        else
            TemporaryData.Name = Data.Name;

            TemporaryData.Humanoid = Data.Humanoid;

            TemporaryData.RootPart = Data.RootPart;

            TemporaryData.RigType = Data.RigType;

            TemporaryData.Structure = Data.Structure;

            TemporaryData.BodyParts = Data.BodyParts;
        end;

        TemporaryData.Team = SDK.GetTeam(Player);

        if (TemporaryData.Team == nil) then
            TemporaryData.Valid = false;
            
            goto SkipPlayerData;
        end;

        if (TemporaryData.Team == 0) then
            TemporaryData.Team = 9977886699;
        end;

        TemporaryData.Position = SDK.GetWorldPosition(TemporaryData.RootPart);

        if (TemporaryData.Position == nil or TemporaryData.Position == 0) then
            TemporaryData.Valid = false;
            
            goto SkipPlayerData;
        end;

        TemporaryData.Distance = SDK.GetWorldDistance(TemporaryData.Position, Game.Cache.LocalPosition);

        if (TemporaryData.Distance == nil or TemporaryData.Distance < 0) then
            TemporaryData.Valid = false;
            
            goto SkipPlayerData;
        end;

        if ((not Menu.Cache.AimbotIgnoreTeam or (Menu.Cache.AimbotIgnoreTeam and TemporaryData.Team ~= Game.Cache.LocalTeam)) and TemporaryData.Distance < ClosestWorldDistance) then
            Game.Objects.ClosestWorldPlayer = Player;

            ClosestWorldDistance = TemporaryData.Distance;
        end;

        TemporaryData.ScreenPosition = SDK.GetScreenPosition(TemporaryData.Position, Game.Cache.Viewmatrix);

        if (TemporaryData.ScreenPosition ~= nil and TemporaryData.ScreenPosition ~= 0) then
            TemporaryData.ScreenDistance = SDK.GetScreenDistance(TemporaryData.ScreenPosition, vec2(MousePositionX, MousePositionY));

            if ((not Menu.Cache.AimbotIgnoreTeam or (Menu.Cache.AimbotIgnoreTeam and TemporaryData.Team ~= Game.Cache.LocalTeam)) and TemporaryData.ScreenDistance ~= nil and TemporaryData.ScreenDistance < ClosestScreenDistance) then
                Game.Objects.ClosestScreenPlayer = Player;

                ClosestScreenDistance = TemporaryData.ScreenDistance;
            end;
        end;

        TemporaryData.Health = SDK.GetHealth(TemporaryData.Humanoid, false);

        if (TemporaryData.Health == nil or TemporaryData.Health <= 0) then
            TemporaryData.Valid = false;

            TemporaryData.Dead = true;
            
            goto SkipPlayerData;
        else
            TemporaryData.Dead = false;
        end;

        TemporaryData.MaxHealth = SDK.GetHealth(TemporaryData.Humanoid, true);

        if (TemporaryData.MaxHealth == nil or TemporaryData.MaxHealth <= 0) then
            TemporaryData.Valid = false;

            TemporaryData.Dead = true;
            
            goto SkipPlayerData;
        else
            TemporaryData.Dead = false;
        end;

        TemporaryData.Tool = SDK.FindFirstChild(TemporaryData.Character, true, "Tool");

        if (TemporaryData.Tool ~= nil and TemporaryData.Tool ~= 0) then
            TemporaryData.ToolName = SDK.GetName(TemporaryData.Tool, false);
        end;

        TemporaryData.Valid = true;

        ::SkipPlayerData::

        Game.Objects.Players[Player] = TemporaryData;
    end;

    ::SkipPlayers::

    return true;
end;

Functions.UpdateRender = function()
    if (not Game.Cache.StaticValid or not Game.Cache.DynamicValid) then
        return false;
    end;

    if (Game.Objects.Players == nil) then
        goto SkipPlayers;
    end;

    for Player, Data in pairs(Game.Objects.Players) do
        if (Data.Valid == nil or Data.Valid == 0 or Data.Valid == false) then
            goto SkipPlayer;
        end;

        local IsTeammate = (Data.Team == Game.Cache.LocalTeam);
        
        if ((IsTeammate and (not Menu.Cache.TeammatesEnabled or not Menu.Cache.TeammatesEnabledKeybind)) or (not IsTeammate and (not Menu.Cache.PlayersEnabled or not Menu.Cache.PlayersEnabledKeybind))) then
            goto SkipPlayer;
        end;
        
        if ((IsTeammate and Data.Distance > Menu.Cache.TeammatesMaximumDistance) or (not IsTeammate and Data.Distance > Menu.Cache.PlayersMaximumDistance)) then
            goto SkipPlayer;
        end;

        local HeadPosition = SDK.GetWorldPosition(Data.BodyParts.Head);

        if (HeadPosition == nil or HeadPosition == 0) then
            goto SkipPlayer;
        end;
        
        local FootPosition = SDK.GetWorldPosition((Data.RigType == 0 and Data.BodyParts.LeftLeg or Data.BodyParts.LeftFoot));

        if (FootPosition == nil or FootPosition == 0) then
            goto SkipPlayer;
        end;
        
        local TopScreenPosition = SDK.GetScreenPosition(HeadPosition + vec3(0, 1, 0), Game.Cache.Viewmatrix);

        if (TopScreenPosition == nil or TopScreenPosition == 0) then
            goto SkipPlayer;
        end;

        local BottomScreenPosition = SDK.GetScreenPosition((Data.RigType == 0 and (FootPosition - vec3(0, 1.5, 0)) or (FootPosition - vec3(0, 1, 0))), Game.Cache.Viewmatrix);

        if (BottomScreenPosition == nil or BottomScreenPosition == 0) then
            goto SkipPlayer;
        end;

        local BoxHeight = math.floor(math.max((BottomScreenPosition.y - TopScreenPosition.y), 8));

        local BoxWidth = math.floor(BoxHeight / 1.6);

        if ((IsTeammate and Menu.Cache.TeammatesName) or (not IsTeammate and Menu.Cache.PlayersName)) then
            local Text = tostring(Data.Name);

            if ((IsTeammate and Menu.Cache.TeammatesDistance) or (not IsTeammate and Menu.Cache.PlayersDistance)) then
                Text = (Text .. " [" .. tostring(math.floor(Data.Distance)) .. "M]");
            end;

            local TextWidth, TextHeight = render.measure_text(Fonts.ESP, Text);

            local TextX, TextY = math.floor(TopScreenPosition.x - (TextWidth / 2)), math.floor(TopScreenPosition.y - TextHeight + 1);
            
            render.draw_text(Fonts.ESP, Text, TextX, TextY, (IsTeammate and Menu.Cache.TeammatesNameColorR or Menu.Cache.PlayersNameColorR), (IsTeammate and Menu.Cache.TeammatesNameColorG or Menu.Cache.PlayersNameColorG), (IsTeammate and Menu.Cache.TeammatesNameColorB or Menu.Cache.PlayersNameColorB), (IsTeammate and Menu.Cache.TeammatesNameColorA or Menu.Cache.PlayersNameColorA), 1, 0, 0, 0, 75);
        end;

        if ((IsTeammate and Menu.Cache.TeammatesTool) or (not IsTeammate and Menu.Cache.PlayersTool)) then
            local Text = ((Data.Tool ~= nil and Data.Tool ~= 0) and tostring(Data.ToolName) or "Unarmed");

            local CleanedText = string.gsub(Text, "[^%w%s]", "");

            if (CleanedText ~= nil and CleanedText ~= "") then
                local TextWidth, TextHeight = render.measure_text(Fonts.ESP, CleanedText);

                local TextX, TextY = math.floor(TopScreenPosition.x - (TextWidth / 2)), math.floor(TopScreenPosition.y + BoxHeight);
                
                render.draw_text(Fonts.ESP, CleanedText, TextX, TextY, (IsTeammate and Menu.Cache.TeammatesToolColorR or Menu.Cache.PlayersToolColorR), (IsTeammate and Menu.Cache.TeammatesToolColorG or Menu.Cache.PlayersToolColorG), (IsTeammate and Menu.Cache.TeammatesToolColorB or Menu.Cache.PlayersToolColorB), (IsTeammate and Menu.Cache.TeammatesToolColorA or Menu.Cache.PlayersToolColorA), 1, 0, 0, 0, 75);
            end;
        end;

        if (((IsTeammate and Menu.Cache.TeammatesBox) or (not IsTeammate and Menu.Cache.PlayersBox)) or ((IsTeammate and Menu.Cache.TeammatesHealth) or (not IsTeammate and Menu.Cache.PlayersHealth))) then
            local BoxX, BoxY = math.floor(TopScreenPosition.x - (BoxWidth / 2)), math.floor(TopScreenPosition.y);

            if ((IsTeammate and Menu.Cache.TeammatesBox) or (not IsTeammate and Menu.Cache.PlayersBox)) then
                render.draw_rectangle(BoxX, BoxY, BoxWidth, BoxHeight, 0, 0, 0, 100, 3, false);

                if ((IsTeammate and Menu.Cache.TeammatesBoxFill) or (not IsTeammate and Menu.Cache.PlayersBoxFill)) then
                    render.draw_rectangle(BoxX, BoxY, BoxWidth, BoxHeight, (IsTeammate and Menu.Cache.TeammatesBoxFillColorR or Menu.Cache.PlayersBoxFillColorR), (IsTeammate and Menu.Cache.TeammatesBoxFillColorG or Menu.Cache.PlayersBoxFillColorG), (IsTeammate and Menu.Cache.TeammatesBoxFillColorB or Menu.Cache.PlayersBoxFillColorB), (IsTeammate and Menu.Cache.TeammatesBoxFillColorA or Menu.Cache.PlayersBoxFillColorA), 1, true);
                end;
                                                                    
                render.draw_rectangle(BoxX, BoxY, BoxWidth, BoxHeight, (IsTeammate and Menu.Cache.TeammatesBoxColorR or Menu.Cache.PlayersBoxColorR), (IsTeammate and Menu.Cache.TeammatesBoxColorG or Menu.Cache.PlayersBoxColorG), (IsTeammate and Menu.Cache.TeammatesBoxColorB or Menu.Cache.PlayersBoxColorB), (IsTeammate and Menu.Cache.TeammatesBoxColorA or Menu.Cache.PlayersBoxColorA), 1, false);
            end;

            if ((IsTeammate and Menu.Cache.TeammatesHealth) or (not IsTeammate and Menu.Cache.PlayersHealth)) then
                local HealthBarX, HealthBarY = math.floor(BoxX - 5), math.floor(BoxY - 1);

                local HealthBarWidth, HealthBarHeight = math.floor(3), math.floor(BoxHeight + 2);

                local HealthBarFillHeight = math.floor(math.max((Data.Health / Data.MaxHealth) * (HealthBarHeight - 2), 0));

                render.draw_rectangle(HealthBarX, HealthBarY, HealthBarWidth, HealthBarHeight, 0, 0, 0, 125, 0, true);

                render.draw_rectangle(HealthBarX + 1, HealthBarY + (HealthBarHeight - HealthBarFillHeight) - 1, HealthBarWidth - 2, HealthBarFillHeight, (IsTeammate and Menu.Cache.TeammatesHealthColorR or Menu.Cache.PlayersHealthColorR), (IsTeammate and Menu.Cache.TeammatesHealthColorG or Menu.Cache.PlayersHealthColorG), (IsTeammate and Menu.Cache.TeammatesHealthColorB or Menu.Cache.PlayersHealthColorB), (IsTeammate and Menu.Cache.TeammatesHealthColorA or Menu.Cache.PlayersHealthColorA), 0, true);
            
                if (((IsTeammate and Menu.Cache.TeammatesHealthText) or (not IsTeammate and Menu.Cache.PlayersHealthText)) and Data.Health ~= Data.MaxHealth) then
                    local Text = tostring(math.floor(Data.Health));

                    local TextWidth, TextHeight = render.measure_text(Fonts.ESP, Text);

                    local TextX, TextY = math.floor(HealthBarX - (TextWidth / 2) + 1), math.floor(HealthBarY + (HealthBarHeight - HealthBarFillHeight) - (TextHeight / 2) - 2);
                    
                    render.draw_text(Fonts.ESP, Text, TextX, TextY, (IsTeammate and Menu.Cache.TeammatesHealthTextColorR or Menu.Cache.PlayersHealthTextColorR), (IsTeammate and Menu.Cache.TeammatesHealthTextColorG or Menu.Cache.PlayersHealthTextColorG), (IsTeammate and Menu.Cache.TeammatesHealthTextColorB or Menu.Cache.PlayersHealthTextColorB), (IsTeammate and Menu.Cache.TeammatesHealthTextColorA or Menu.Cache.PlayersHealthTextColorA), 1, 0, 0, 0, 75);
                end;
            end;
        end;

        ::SkipPlayer::
    end;

    ::SkipPlayers::

    return true;
end;

Functions.UpdateCheat = function()
    if (not Game.Cache.StaticValid or not Game.Cache.DynamicValid) then
        Game.Aimbot = { };
        
        return false;
    end;

    if (Game.Aimbot.LastUpdate == nil) then
        Game.Aimbot.LastUpdate = winapi.get_tickcount64();
    elseif (Game.Aimbot.LastUpdate ~= nil) then
        if (Menu.Cache.AimbotEnabled) then
            local MousePositionX, MousePositionY = input.get_mouse_position();

            if (Menu.Cache.AimbotDrawFOV) then
                render.draw_circle(MousePositionX, MousePositionY, (Menu.Cache.AimbotFOV * 5) - 1, Menu.Cache.AimbotDrawFOVColorR, Menu.Cache.AimbotDrawFOVColorG, Menu.Cache.AimbotDrawFOVColorB, Menu.Cache.AimbotDrawFOVColorA, 1, false);
            end;

            if (winapi.get_tickcount64() - Game.Aimbot.LastUpdate > ((1 / 60) / 1000)) then
                local BaseSmoothing = (Menu.Cache.AimbotSmoothing / 100);

                local BaseFOV = (Menu.Cache.AimbotFOV * 5);

                if (not Menu.Cache.AimbotEnabledKeybind or Game.Aimbot.Target == 0) then
                    if (Menu.Cache.AimbotTarget == 0) then
                        Game.Aimbot.Target = Game.Objects.ClosestScreenPlayer;
                    else
                        Game.Aimbot.Target = Game.Objects.ClosestWorldPlayer;
                    end;
                end;

                if (Game.Aimbot.Target == nil or Game.Aimbot.Target == 0) then
                    goto SkipAimbot;
                end;

                local PlayerData = Game.Objects.Players[Game.Aimbot.Target];

                if (PlayerData == nil or PlayerData == 0) then
                    Game.Aimbot.Target = 0;
                    
                    goto SkipAimbot;
                end;

                if (PlayerData.Valid == nil or PlayerData.Valid == 0 or PlayerData.Valid == false) then
                    Game.Aimbot.Target = 0;
                    
                    goto SkipAimbot;
                end;

                if (Menu.Cache.AimbotEnabledKeybind) then
                    local Hitbox = (Menu.Cache.AimbotHitbox == 0 and PlayerData.BodyParts.Head or PlayerData.RootPart);

                    if (Hitbox == nil or Hitbox == 0) then
                        Game.Aimbot.Target = 0;
                        
                        goto SkipAimbot;
                    end;

                    local Position = SDK.GetWorldPosition(Hitbox);

                    if (Position == nil or Position == 0) then
                        Game.Aimbot.Target = 0;
                        
                        goto SkipAimbot;
                    end;

                    local ScreenPosition = SDK.GetScreenPosition(Position, Game.Cache.Viewmatrix);

                    if (ScreenPosition == nil or ScreenPosition == 0) then
                        Game.Aimbot.Target = 0;
                        
                        goto SkipAimbot;
                    end;

                    local ScreenDistance = SDK.GetScreenDistance(ScreenPosition, vec2(MousePositionX, MousePositionY));

                    if (ScreenDistance == nil or ScreenDistance >= BaseFOV) then
                        Game.Aimbot.Target = 0;
                        
                        goto SkipAimbot;
                    end;

                    local DeltaX, DeltaY = (ScreenPosition.x - MousePositionX), (ScreenPosition.y - MousePositionY);

                    if (math.abs(DeltaX) < 1 and math.abs(DeltaY) < 1) then
                        goto SkipAimbot;
                    end;

                    local LerpDistance = math.clamp(ScreenDistance / 500, 0.2, 1);

                    local LerpCurve = (LerpDistance ^ 0.6);

                    local LerpFactor = math.clamp((1 - BaseSmoothing) * LerpCurve, 0.06, 1);

                    local MoveX, MoveY = math.lerp(0, DeltaX, LerpFactor), math.lerp(0, DeltaY, LerpFactor);

                    Game.Aimbot.ResidualX = ((Game.Aimbot.ResidualX or 0) + MoveX);

                    Game.Aimbot.ResidualY = ((Game.Aimbot.ResidualY or 0) + MoveY);

                    local SendX, SendY = math.floor(Game.Aimbot.ResidualX), math.floor(Game.Aimbot.ResidualY);

                    Game.Aimbot.ResidualX = ((Game.Aimbot.ResidualX - SendX) * 0.9);

                    Game.Aimbot.ResidualY = ((Game.Aimbot.ResidualY - SendY) * 0.9);

                    input.simulate_mouse(SendX, SendY, 1);
                end;

                Game.Aimbot.LastUpdate = winapi.get_tickcount64();
            end;
        end;
    end;

    ::SkipAimbot::

    if (Menu.Cache.WalkSpeedEnabled or Menu.Cache.JumpPowerEnabled) then
        local MoveDirection = SDK.GetMoveDirection(Game.Cache.LocalHumanoid);

        local Velocity = SDK.GetWorldVelocity(Game.Cache.LocalRootPart);

        local Position = SDK.GetWorldPosition(Game.Cache.LocalRootPart);

        local Rotation = SDK.GetWorldRotation(Game.Cache.LocalRootPart);

        if (MoveDirection == nil or MoveDirection == 0 or Velocity == nil or Velocity == 0 or Position == nil or Position == 0 or Rotation == nil) then
            goto SkipModifiers;
        end;

        if ((Menu.Cache.WalkSpeedEnabled and Menu.Cache.WalkSpeedEnabledKeybind) or (Menu.Cache.JumpPowerEnabled and Menu.Cache.JumpPowerEnabledKeybind)) then
            if (Menu.Cache.WalkSpeedEnabled and Menu.Cache.WalkSpeedEnabledKeybind and Menu.Cache.WalkSpeedMode == 0) then
                SDK.SetWalkSpeed(Game.Cache.LocalHumanoid, Menu.Cache.WalkSpeedValue);

                goto SkipModifiers;
            end;

            if (Menu.Cache.JumpPowerEnabled and Menu.Cache.JumpPowerEnabledKeybind and Menu.Cache.JumpPowerMode == 0) then
                SDK.SetJumpPower(Game.Cache.LocalHumanoid, Menu.Cache.JumpPowerValue);

                goto SkipModifiers;
            end;
            
            if (Menu.Cache.JumpPowerMode == 1 or Menu.Cache.WalkSpeedMode == 1) then
                local AdjustedVelocity = vec3(
                    ((Menu.Cache.WalkSpeedMode == 1 and Menu.Cache.WalkSpeedEnabled and Menu.Cache.WalkSpeedEnabledKeybind) and (MoveDirection.x * Menu.Cache.WalkSpeedValue) or Velocity.x),

                    ((Menu.Cache.JumpPowerMode == 1 and Menu.Cache.JumpPowerEnabled and Menu.Cache.JumpPowerEnabledKeybind and input.is_key_down(32)) and Menu.Cache.JumpPowerValue or Velocity.y),

                    ((Menu.Cache.WalkSpeedMode == 1 and Menu.Cache.WalkSpeedEnabled and Menu.Cache.WalkSpeedEnabledKeybind) and (MoveDirection.z * Menu.Cache.WalkSpeedValue) or Velocity.z)
                );

                SDK.SetWorldRotation(Game.Cache.LocalRootPart, Rotation + 0.001);

                SDK.SetWorldVelocity(Game.Cache.LocalRootPart, vec3(AdjustedVelocity.x, AdjustedVelocity.y, AdjustedVelocity.z));

                goto SkipModifiers;
            end;
        end;
    end;

    ::SkipModifiers::

    return true;
end;

Functions.Update = function()
    Functions.UpdateStaticCache();

    Functions.UpdateDynamicCache();

    Functions.UpdateMenuCache();

    Functions.UpdateObjects();
    
    Functions.UpdateRender();

    Functions.UpdateCheat();

    return true;
end;

-- @REGISTER

engine.register_on_engine_tick(Functions.Update);