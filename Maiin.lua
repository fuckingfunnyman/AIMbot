--[[
    What the.. YOURE NOT WELCOME HERE SKID
]]

-- ============================================
-- SERVICES
-- ============================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ============================================
-- UTILITY FUNCTIONS (FIXED)
-- ============================================
local function clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

-- ============================================
-- LOAD RAYFIELD (FIXED LOADING)
-- ============================================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- ============================================
-- CONFIGURATION TABLES
-- ============================================
-- WALL CHECK TOGGLE - JUST THIS PART
local Aimbot = {
    Enabled = false,
    TeamCheck = true,
    WallCheck = true,  -- ← ADD THIS LINE
    AimPart = "Head",
    Smoothness = 0.1,
    FOV = 150,
    ShowFOV = true,
    FOVColor = Color3.fromRGB(255, 50, 50),
    FOVTransparency = 0.7,
    OnKey = Enum.UserInputType.MouseButton2,
    Holding = false,
    Target = nil,
    RainbowFOV = false
}

local ESP = {
    Enabled = false,
    TeamCheck = true,
    Boxes = true,
    HealthBars = true,
    ShowNames = true,
    ShowDistance = true,
    Tracers = false,
    TracerPosition = 1, -- 1 = Bottom, 2 = Center, 3 = Mouse
    MaxDistance = 1000,
    TextSize = 14,
    Font = Drawing.Fonts and Drawing.Fonts.UI or 0, -- FIXED: Safe access
    EnemyColor = Color3.fromRGB(255, 50, 50),
    TeammateColor = Color3.fromRGB(50, 255, 50),
    BoxColor = Color3.fromRGB(255, 255, 255),
    RainbowESP = false,
    RainbowSpeed = 1
}

-- ============================================
-- DRAWING OBJECTS
-- ============================================
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false
FOVCircle.Thickness = 2
FOVCircle.NumSides = 64
FOVCircle.Filled = false
FOVCircle.Transparency = Aimbot.FOVTransparency
FOVCircle.Color = Aimbot.FOVColor
FOVCircle.Radius = Aimbot.FOV
FOVCircle.Position = Camera.ViewportSize / 2

-- ESP object storage
local ESPObjects = {}

-- ============================================
-- FOV CIRCLE UPDATE
-- ============================================
RunService.RenderStepped:Connect(function()
    if Aimbot.Enabled and Aimbot.ShowFOV then
        local success, err = pcall(function()
            FOVCircle.Position = UserInputService:GetMouseLocation()
            FOVCircle.Radius = Aimbot.FOV
            if Aimbot.RainbowFOV then
                local Hue = (tick() % 1) / 1 -- FIXED: Simplified rainbow
                FOVCircle.Color = Color3.fromHSV(Hue, 1, 1)
            else
                FOVCircle.Color = Aimbot.FOVColor
            end
            FOVCircle.Visible = true
        end)
        if not success then
            FOVCircle.Visible = false
        end
    else
        FOVCircle.Visible = false
    end
end)

-- ============================================
-- WALL CHECK FUNCTION - STANDALONE VERSION
-- ============================================
--- WALL CHECK FUNCTION - ADD THIS ENTIRE BLOCK
local RaycastParams = RaycastParams.new()
RaycastParams.FilterType = Enum.RaycastFilterType.Blacklist
RaycastParams.IgnoreWater = true

local function IsTargetVisible(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return false end
    
    local localChar = LocalPlayer.Character
    if not localChar or not localChar:FindFirstChild("HumanoidRootPart") then return false end
    
    local targetChar = targetPlayer.Character
    if not targetChar or not targetChar:FindFirstChild("HumanoidRootPart") then return false end
    
    RaycastParams.FilterDescendantsInstances = {localChar, targetChar, Camera}
    
    local startPos = Camera.CFrame.Position
    local targetPos = targetChar.HumanoidRootPart.Position
    local direction = (targetPos - startPos)
    
    local rayResult = workspace:Raycast(startPos, direction, RaycastParams)
    return rayResult == nil
end

-- ============================================
-- AIMBOT FUNCTIONS
-- ============================================
-- MODIFY YOUR GetClosestPlayer FUNCTION - REPLACE WITH THIS
local function GetClosestPlayer()
    local ClosestDistance = math.huge
    local ClosestPlayer = nil
    local MousePosition = UserInputService:GetMouseLocation()
    
    for _, Player in pairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer then
            local Character = Player.Character
            if Character and Character:FindFirstChild("Humanoid") and Character.Humanoid.Health > 0 then
                
                if Aimbot.TeamCheck and Player.Team and LocalPlayer.Team and Player.Team == LocalPlayer.Team then
                    continue
                end
                
                -- ← ADD THIS WALL CHECK BLOCK
                if Aimbot.WallCheck and not IsTargetVisible(Player) then
                    continue
                end
                
                local AimPart = Character:FindFirstChild(Aimbot.AimPart)
                if AimPart then
                    local ScreenPosition, OnScreen = Camera:WorldToViewportPoint(AimPart.Position)
                    
                    if OnScreen then
                        local Distance = (Vector2.new(ScreenPosition.X, ScreenPosition.Y) - MousePosition).Magnitude
                        
                        if Distance < Aimbot.FOV and Distance < ClosestDistance then
                            ClosestDistance = Distance
                            ClosestPlayer = Player
                        end
                    end
                end
            end
        end
    end
    
    return ClosestPlayer
end
-- Input handling
UserInputService.InputBegan:Connect(function(Input, GameProcessed)
    if not GameProcessed and Aimbot.Enabled then
        if Input.UserInputType == Aimbot.OnKey or Input.KeyCode == Aimbot.OnKey then
            Aimbot.Holding = true
        end
    end
end)

UserInputService.InputEnded:Connect(function(Input, GameProcessed)
    if not GameProcessed and Aimbot.Enabled then
        if Input.UserInputType == Aimbot.OnKey or Input.KeyCode == Aimbot.OnKey then
            Aimbot.Holding = false
            Aimbot.Target = nil
        end
    end
end)

-- Main aimbot loop (FIXED: Added validation)
RunService.RenderStepped:Connect(function()
    if Aimbot.Enabled and Aimbot.Holding then
        local Target = GetClosestPlayer()
        if Target then
            Aimbot.Target = Target
            local Character = Target.Character
            if Character then
                local AimPart = Character:FindFirstChild(Aimbot.AimPart)
                if AimPart and Camera then
                    local success, err = pcall(function()
                        TweenService:Create(
                            Camera,
                            TweenInfo.new(Aimbot.Smoothness, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
                            {CFrame = CFrame.new(Camera.CFrame.Position, AimPart.Position)}
                        ):Play()
                    end)
                end
            end
        end
    end
end)

-- ============================================
-- ESP FUNCTIONS (FIXED)
-- ============================================
local function CleanupESP(Player)
    if ESPObjects[Player] then
        for _, Object in pairs(ESPObjects[Player]) do
            pcall(function()
                Object:Remove()
            end)
        end
        ESPObjects[Player] = nil
    end
end

local function CreateESP(Player)
    if Player == LocalPlayer then return end
    
    local Objects = {
        BoxOutline = Drawing.new("Square"),
        Box = Drawing.new("Square"),
        HealthBarOutline = Drawing.new("Square"),
        HealthBar = Drawing.new("Square"),
        NameLabel = Drawing.new("Text"),
        DistanceLabel = Drawing.new("Text"),
        Tracer = Drawing.new("Line")
    }
    
    ESPObjects[Player] = Objects
    
    -- Configure Boxes
    Objects.BoxOutline.Visible = false
    Objects.BoxOutline.Thickness = 3
    Objects.BoxOutline.Color = Color3.fromRGB(0, 0, 0)
    Objects.BoxOutline.Transparency = 1
    Objects.BoxOutline.Filled = false
    
    Objects.Box.Visible = false
    Objects.Box.Thickness = 1
    Objects.Box.Color = ESP.BoxColor
    Objects.Box.Transparency = 1
    Objects.Box.Filled = false
    
    -- Configure Health Bars
    Objects.HealthBarOutline.Visible = false
    Objects.HealthBarOutline.Thickness = 2
    Objects.HealthBarOutline.Color = Color3.fromRGB(0, 0, 0)
    Objects.HealthBarOutline.Filled = false
    
    Objects.HealthBar.Visible = false
    Objects.HealthBar.Thickness = 1
    Objects.HealthBar.Filled = true
    
    -- Configure Text
    Objects.NameLabel.Visible = false
    Objects.NameLabel.Font = ESP.Font
    Objects.NameLabel.Size = ESP.TextSize
    Objects.NameLabel.Outline = true
    Objects.NameLabel.OutlineColor = Color3.fromRGB(0, 0, 0)
    Objects.NameLabel.Center = true
    
    Objects.DistanceLabel.Visible = false
    Objects.DistanceLabel.Font = ESP.Font
    Objects.DistanceLabel.Size = ESP.TextSize - 2
    Objects.DistanceLabel.Outline = true
    Objects.DistanceLabel.OutlineColor = Color3.fromRGB(0, 0, 0)
    Objects.DistanceLabel.Center = true
    
    -- Configure Tracer
    Objects.Tracer.Visible = false
    Objects.Tracer.Thickness = 2
    Objects.Tracer.Color = ESP.BoxColor
    Objects.Tracer.Transparency = 1
end

-- ESP Update Function (FIXED: Removed math.clamp)
local function UpdateESP()
    if not ESP.Enabled then
        for Player, Objects in pairs(ESPObjects) do
            for _, Object in pairs(Objects) do
                pcall(function()
                    Object.Visible = false
                end)
            end
        end
        return
    end
    
    -- Rainbow ESP calculation
    local RainbowHue = (tick() % ESP.RainbowSpeed) / ESP.RainbowSpeed
    
    for _, Player in pairs(Players:GetPlayers()) do
        if Player == LocalPlayer then
            continue
        end
        
        if not ESPObjects[Player] then
            CreateESP(Player)
        end
        
        local Character = Player.Character
        local Objects = ESPObjects[Player]
        
        if not (Character and Character:FindFirstChild("HumanoidRootPart") and Character:FindFirstChild("Humanoid") and Character.Humanoid.Health > 0) then
            for _, Object in pairs(Objects) do
                pcall(function()
                    Object.Visible = false
                end)
            end
            continue
        end
        
        local Humanoid = Character.Humanoid
        local RootPart = Character.HumanoidRootPart
        local Head = Character:FindFirstChild("Head")
        
        -- Team color selection (FIXED: Added nil check for Team)
        local IsEnemy = true
        if ESP.TeamCheck and Player.Team and LocalPlayer.Team then
            IsEnemy = Player.Team ~= LocalPlayer.Team
        end
        local DisplayColor = IsEnemy and ESP.EnemyColor or ESP.TeammateColor
        
        if ESP.RainbowESP then
            DisplayColor = Color3.fromHSV(RainbowHue, 1, 1)
        end
        
        -- Get screen positions
        local ScreenPos, OnScreen = Camera:WorldToViewportPoint(RootPart.Position)
        local Distance = (Camera.CFrame.Position - RootPart.Position).Magnitude
        
        if OnScreen and Distance <= ESP.MaxDistance then
            local HeadPos = Head and Camera:WorldToViewportPoint(Head.Position) or Camera:WorldToViewportPoint(RootPart.Position + Vector3.new(0, 2.5, 0))
            local RootPos = Camera:WorldToViewportPoint(RootPart.Position - Vector3.new(0, 2.5, 0))
            
            local BoxHeight = math.abs(HeadPos.Y - RootPos.Y)
            local BoxWidth = BoxHeight * 0.6
            local BoxPos = Vector2.new(ScreenPos.X - BoxWidth/2, ScreenPos.Y - BoxHeight/2)
            
            -- Update Boxes
            if ESP.Boxes then
                Objects.BoxOutline.Visible = true
                Objects.BoxOutline.Position = BoxPos
                Objects.BoxOutline.Size = Vector2.new(BoxWidth, BoxHeight)
                
                Objects.Box.Visible = true
                Objects.Box.Position = BoxPos
                Objects.Box.Size = Vector2.new(BoxWidth, BoxHeight)
                Objects.Box.Color = DisplayColor
            else
                Objects.BoxOutline.Visible = false
                Objects.Box.Visible = false
            end
            
            -- Update Health Bars (FIXED: Replaced math.clamp)
            if ESP.HealthBars then
                local HealthPercent = Humanoid.Health / Humanoid.MaxHealth
                local BarHeight = BoxHeight * HealthPercent
                local BarY = BoxPos.Y + (BoxHeight - BarHeight)
                
                Objects.HealthBarOutline.Visible = true
                Objects.HealthBarOutline.Position = Vector2.new(BoxPos.X - 6, BoxPos.Y)
                Objects.HealthBarOutline.Size = Vector2.new(4, BoxHeight)
                
                Objects.HealthBar.Visible = true
                Objects.HealthBar.Position = Vector2.new(BoxPos.X - 5, BarY)
                Objects.HealthBar.Size = Vector2.new(2, BarHeight)
                Objects.HealthBar.Color = Color3.fromRGB(
                    clamp(255 - (255 * HealthPercent), 0, 255),
                    clamp(255 * HealthPercent, 0, 255),
                    0
                )
            else
                Objects.HealthBarOutline.Visible = false
                Objects.HealthBar.Visible = false
            end
            
            -- Update Name
            if ESP.ShowNames then
                Objects.NameLabel.Visible = true
                Objects.NameLabel.Position = Vector2.new(BoxPos.X + BoxWidth/2, BoxPos.Y - 18)
                Objects.NameLabel.Text = Player.Name
                Objects.NameLabel.Color = DisplayColor
                Objects.NameLabel.Size = ESP.TextSize -- FIXED: Update size
            else
                Objects.NameLabel.Visible = false
            end
            
            -- Update Distance
            if ESP.ShowDistance then
                Objects.DistanceLabel.Visible = true
                Objects.DistanceLabel.Position = Vector2.new(BoxPos.X + BoxWidth/2, BoxPos.Y + BoxHeight + 4)
                Objects.DistanceLabel.Text = string.format("%.0f studs", Distance)
                Objects.DistanceLabel.Color = DisplayColor
                Objects.DistanceLabel.Size = ESP.TextSize - 2 -- FIXED: Update size
            else
                Objects.DistanceLabel.Visible = false
            end
            
            -- Update Tracers
            if ESP.Tracers then
                Objects.Tracer.Visible = true
                local StartPos
                if ESP.TracerPosition == 1 then -- Bottom
                    StartPos = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                elseif ESP.TracerPosition == 2 then -- Center
                    StartPos = Camera.ViewportSize / 2
                else -- Mouse
                    StartPos = UserInputService:GetMouseLocation()
                end
                Objects.Tracer.From = StartPos
                Objects.Tracer.To = Vector2.new(ScreenPos.X, ScreenPos.Y)
                Objects.Tracer.Color = DisplayColor
            else
                Objects.Tracer.Visible = false
            end
        else
            -- Hide if off screen or out of range
            for _, Object in pairs(Objects) do
                pcall(function()
                    Object.Visible = false
                end)
            end
        end
    end
end

-- ESP Update Loop
RunService.RenderStepped:Connect(UpdateESP)

-- Cleanup on player leave
Players.PlayerRemoving:Connect(CleanupESP)

-- ============================================
-- CREATE INITIAL ESP
-- ============================================
for _, Player in pairs(Players:GetPlayers()) do
    if Player ~= LocalPlayer then
        CreateESP(Player)
    end
end

-- ============================================
-- RAYFIELD GUI CREATION (FIXED: Variable scope)
-- ============================================
local Window

-- Check if Rayfield loaded successfully
if Rayfield then
    Window = Rayfield:CreateWindow({
        Name = "ADVANCED AIMBOT + ESP v2.0",
        LoadingTitle = "Check Credits",
        LoadingSubtitle = "by DairyMan",
        ConfigurationSaving = {
            Enabled = true,
            FolderName = "SystemOverride",
            FileName = "AimbotESP"
        },
        Discord = {
            Enabled = false,
            Invite = "noinvite",
            RememberJoins = true
        },
        KeySystem = false,
        KeySettings = {
            Title = "System Override",
            Subtitle = "Key System",
            Note = "No key required - Educational Use Only",
            FileName = "SystemOverrideKey",
            SaveKey = true,
            GrabKeyFromSite = false,
            Key = {"systemoverride2024"}
        }
    })

    -- ============================================
    -- AIMBOT TAB
    -- ============================================
    local AimbotTab = Window:CreateTab("Aimbot", 4483362458)
    local AimbotSection = AimbotTab:CreateSection("Aimbot Controls")

    -- Main Toggle
    local AimbotToggle = AimbotTab:CreateToggle({
        Name = "Enable Aimbot",
        CurrentValue = false,
        Flag = "AimbotEnabled",
        Callback = function(Value)
            Aimbot.Enabled = Value
            Rayfield:Notify({
                Title = "Aimbot",
                Content = Value and "Aimbot Activated" or "Aimbot Deactivated",
                Duration = 2
            })
        end
    })

    -- Team Check
    AimbotTab:CreateToggle({
        Name = "Team Check",
        CurrentValue = true,
        Flag = "AimbotTeamCheck",
        Callback = function(Value)
            Aimbot.TeamCheck = Value
        end
    })

-- RAYFIELD TOGGLE - ADD THIS IN YOUR AIMBOT TAB SECTION
    AimbotTab:CreateToggle({
        Name = "Wall Check",
        CurrentValue = true,
        Flag = "AimbotWallCheck",
        Callback = function(Value)
            Aimbot.WallCheck = Value
        end
    })

    -- Smoothness Slider
    AimbotTab:CreateSlider({
        Name = "Smoothness",
        Range = {0.01, 0.5},
        Increment = 0.01,
        Suffix = "seconds",
        CurrentValue = 0.1,
        Flag = "Smoothness",
        Callback = function(Value)
            Aimbot.Smoothness = Value
        end
    })

    -- FOV Section
    local FOVSection = AimbotTab:CreateSection("Field of View")

    -- FOV Slider
    AimbotTab:CreateSlider({
        Name = "FOV Size",
        Range = {50, 500},
        Increment = 5,
        Suffix = "pixels",
        CurrentValue = 150,
        Flag = "FOVSize",
        Callback = function(Value)
            Aimbot.FOV = Value
        end
    })

    -- Show FOV Toggle
    AimbotTab:CreateToggle({
        Name = "Show FOV Circle",
        CurrentValue = true,
        Flag = "ShowFOV",
        Callback = function(Value)
            Aimbot.ShowFOV = Value
        end
    })

    -- FOV Color Picker
    AimbotTab:CreateColorPicker({
        Name = "FOV Color",
        Color = Color3.fromRGB(255, 50, 50),
        Flag = "FOVColor",
        Callback = function(Color)
            Aimbot.FOVColor = Color
        end
    })

    -- Rainbow FOV Toggle
    AimbotTab:CreateToggle({
        Name = "Rainbow FOV",
        CurrentValue = false,
        Flag = "RainbowFOV",
        Callback = function(Value)
            Aimbot.RainbowFOV = Value
        end
    })

    -- Keybind Section
    local KeybindSection = AimbotTab:CreateSection("Keybinds")

    -- Aim Key Dropdown
    AimbotTab:CreateDropdown({
        Name = "Aim Key (BROKEN)",
        Options = {"Mouse Button 2"},
        CurrentOption = "Mouse Button 2",
        Flag = "AimKey",
        Callback = function(Option)
            local keyMap = {
                ["Mouse Button 2"] = Enum.UserInputType.MouseButton2,
            }
            Aimbot.OnKey = keyMap[Option]
        end
    })

    -- ============================================
    -- ESP TAB
    -- ============================================
    local ESPTab = Window:CreateTab("ESP", 4483362458)
    local ESPMainSection = ESPTab:CreateSection("ESP Controls")

    -- ESP Toggle
    ESPTab:CreateToggle({
        Name = "Enable ESP",
        CurrentValue = false,
        Flag = "ESPEnabled",
        Callback = function(Value)
            ESP.Enabled = Value
            Rayfield:Notify({
                Title = "ESP",
                Content = Value and "ESP Activated" or "ESP Deactivated",
                Duration = 2
            })
        end
    })

    -- ESP Team Check
    ESPTab:CreateToggle({
        Name = "Team Check",
        CurrentValue = true,
        Flag = "ESPTeamCheck",
        Callback = function(Value)
            ESP.TeamCheck = Value
        end
    })

    -- ESP Features Section
    local ESPFeaturesSection = ESPTab:CreateSection("ESP Features")

    -- Boxes Toggle
    ESPTab:CreateToggle({
        Name = "Show Boxes",
        CurrentValue = true,
        Flag = "ESPBoxes",
        Callback = function(Value)
            ESP.Boxes = Value
        end
    })

    -- Health Bars Toggle
    ESPTab:CreateToggle({
        Name = "Health Bars",
        CurrentValue = true,
        Flag = "ESPHealthBars",
        Callback = function(Value)
            ESP.HealthBars = Value
        end
    })

    -- Names Toggle
    ESPTab:CreateToggle({
        Name = "Show Names",
        CurrentValue = true,
        Flag = "ESPNames",
        Callback = function(Value)
            ESP.ShowNames = Value
        end
    })

    -- Distance Toggle
    ESPTab:CreateToggle({
        Name = "Show Distance",
        CurrentValue = true,
        Flag = "ESPDistance",
        Callback = function(Value)
            ESP.ShowDistance = Value
        end
    })

    -- Tracers Toggle
    ESPTab:CreateToggle({
        Name = "Show Tracers",
        CurrentValue = false,
        Flag = "ESPTracers",
        Callback = function(Value)
            ESP.Tracers = Value
        end
    })

    -- Color Section
    local ESPColorSection = ESPTab:CreateSection("Colors")

    -- Enemy Color Picker
    ESPTab:CreateColorPicker({
        Name = "Enemy Color",
        Color = Color3.fromRGB(255, 50, 50),
        Flag = "EnemyColor",
        Callback = function(Color)
            ESP.EnemyColor = Color
        end
    })

    -- Teammate Color Picker
    ESPTab:CreateColorPicker({
        Name = "Teammate Color",
        Color = Color3.fromRGB(50, 255, 50),
        Flag = "TeammateColor",
        Callback = function(Color)
            ESP.TeammateColor = Color
        end
    })

    -- Rainbow ESP Toggle
    ESPTab:CreateToggle({
        Name = "Rainbow ESP",
        CurrentValue = false,
        Flag = "RainbowESP",
        Callback = function(Value)
            ESP.RainbowESP = Value
        end
    })

    -- Advanced Section
    local ESPAdvancedSection = ESPTab:CreateSection("Advanced")

    -- Tracer Position Dropdown
    ESPTab:CreateDropdown({
        Name = "Tracer Start (BROKEN)",
        Options = {"Bottom", "Center", "Mouse"},
        CurrentOption = "Bottom",
        Flag = "TracerPosition",
        Callback = function(Option)
            local positions = {Bottom = 1, Center = 2, Mouse = 3}
            ESP.TracerPosition = positions[Option]
        end
    })

    -- Max Distance Slider
    ESPTab:CreateSlider({
        Name = "Max Distance",
        Range = {100, 5000},
        Increment = 50,
        Suffix = "studs",
        CurrentValue = 1000,
        Flag = "MaxDistance",
        Callback = function(Value)
            ESP.MaxDistance = Value
        end
    })

    -- Text Size Slider
    ESPTab:CreateSlider({
        Name = "Text Size",
        Range = {8, 24},
        Increment = 1,
        Suffix = "px",
        CurrentValue = 14,
        Flag = "TextSize",
        Callback = function(Value)
            ESP.TextSize = Value
        end
    })

    -- ============================================
    -- SETTINGS TAB
    -- ============================================
    local SettingsTab = Window:CreateTab("Settings", 4483362458)
    local UISection = SettingsTab:CreateSection("UI Settings")

    -- Theme Dropdown
    SettingsTab:CreateDropdown({
        Name = "Theme",
        Options = {"Default", "Dark", "Light", "Blood", "Ocean"},
        CurrentOption = "Default",
        Flag = "Theme",
        Callback = function(Option)
            Rayfield:ChangeTheme(Option)
        end
    })

    -- Toggle GUI Keybind
    SettingsTab:CreateKeybind({
        Name = "Toggle GUI",
        CurrentKeybind = "RightShift",
        HoldToInteract = false,
        Flag = "ToggleGUI",
        Callback = function(Keybind)
            Window:Toggle()
        end
    })

    -- Destroy GUI Button (FIXED: Added proper cleanup)
    SettingsTab:CreateButton({
        Name = "Destroy GUI",
        Callback = function()
            -- Cleanup ESP objects
            for Player, Objects in pairs(ESPObjects) do
                for _, Object in pairs(Objects) do
                    pcall(function()
                        Object:Remove()
                    end)
                end
            end
            ESPObjects = {}
            
            -- Remove FOV circle
            pcall(function()
                FOVCircle:Remove()
            end)
            
            -- Destroy window
            Rayfield:Destroy()
        end
    })

    -- Utility Section
    local UtilitySection = SettingsTab:CreateSection("Utility")

    -- Clear Cache Button (FIXED: Added proper check)
    SettingsTab:CreateButton({
        Name = "Clear Drawing Cache",
        Callback = function()
            local success = pcall(function()
                if cleardrawcache then
                    cleardrawcache()
                end
            end)
            Rayfield:Notify({
                Title = "Cache",
                Content = success and "Drawing cache cleared" or "Cache clear failed",
                Duration = 2
            })
        end
    })

    -- Rejoin Game Button
    SettingsTab:CreateButton({
        Name = "Rejoin Game",
        Callback = function()
            local TeleportService = game:GetService("TeleportService")
            local PlaceId = game.PlaceId
            local JobId = game.JobId
            TeleportService:TeleportToPlaceInstance(PlaceId, JobId, LocalPlayer)
        end
    })

    -- ============================================
    -- Credits
    -- ============================================
    local CreditsTab = Window:CreateTab("Credits", 4483362458)
    local UISection = SettingsTab:CreateSection("Credits")
    
    CreditsTab:CreateButton({
        Name = "Discord",
        Callback = function()
        local url = "https://discord.gg/jbSqSMVW7R"
        setclipboard(url)
        Rayfield:Notify({
            Title = "URL Copied",
            Content = "The link has been copied to your clipboard.",
            Duration = 4
            })
        end,
    })
    -- ============================================
    -- INITIALIZATION
    -- ============================================
    Rayfield:Notify({
        Title = "System Override v2.0",
        Content = "Aimbot + ESP initialized! Press RightShift to toggle GUI.",
        Duration = 5
    })
else
    -- Fallback notification if Rayfield fails
    warn("Rayfield failed to load. Script will run without GUI.")
    print("Aimbot + ESP running in headless mode. Use console to toggle.")
    Aimbot.Enabled = true
    ESP.Enabled = true

end
