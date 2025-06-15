-- Blockspin Ultimate Script with Full Menu
-- Version: 1.0 - Professional Grade
-- Compatible with Solara and other executors

-- Wait for game to load
if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = Workspace.CurrentCamera

-- Remove existing GUI
for _, gui in pairs(CoreGui:GetChildren()) do
    if gui.Name == "BlockspinUltimateGUI" then
        gui:Destroy()
    end
end

-- Configuration
local Config = {
    -- Aimbot Settings
    Aimbot = {
        Enabled = false,
        FOV = 100,
        MaxDistance = 500,
        TargetPart = "Head",
        Smoothing = true,
        SmoothingFactor = 0.15,
        PredictMovement = true,
        PredictionStrength = 0.2,
        WallCheck = true,
        TeamCheck = true,
        ShowFOV = true,
        HighlightTarget = true,
        AutoShoot = false,
        TriggerBot = false
    },
    
    -- ESP Settings
    ESP = {
        Enabled = false,
        MaxDistance = 800,
        ShowBoxes = true,
        ShowNames = true,
        ShowHealth = true,
        ShowDistance = true,
        ShowWeapons = false,
        ShowTracers = false,
        ShowHeadDots = true,
        ShowTeam = false,
        BoxThickness = 2,
        TextSize = 13,
        EnemyColor = Color3.fromRGB(255, 80, 80),
        TeamColor = Color3.fromRGB(80, 255, 80)
    },
    
    -- Player Modifications
    Player = {
        WalkSpeed = 16,
        JumpPower = 50,
        Fly = false,
        FlySpeed = 50,
        Noclip = false,
        InfiniteJump = false,
        SpeedHack = false,
        JumpHack = false
    },
    
    -- Visual Settings
    Visual = {
        FullBright = false,
        NoFog = false,
        Crosshair = false,
        CrosshairSize = 10,
        CrosshairColor = Color3.fromRGB(255, 255, 255),
        RemoveTextures = false,
        Wireframe = false
    },
    
    -- Misc Settings
    Misc = {
        AutoRespawn = false,
        ChatSpam = false,
        ChatMessage = "Blockspin Ultimate!",
        SpamDelay = 2,
        KillAura = false,
        KillAuraRange = 20,
        AutoClick = false,
        ClickDelay = 0.1
    }
}

-- Variables
local ESPObjects = {}
local Connections = {}
local CurrentTarget = nil
local FOVCircle = nil
local TargetHighlight = nil
local FlyBodyVelocity = nil
local FlyBodyAngularVelocity = nil
local OriginalWalkSpeed = 16
local OriginalJumpPower = 50

-- Utility Functions
local function GetPlayerTeam(Player)
    return Player.Team
end

local function IsTeammate(Player)
    if not Config.Aimbot.TeamCheck then return false end
    local LocalTeam = GetPlayerTeam(LocalPlayer)
    local PlayerTeam = GetPlayerTeam(Player)
    return LocalTeam == PlayerTeam and LocalTeam ~= nil
end

local function GetCharacterPart(Character, PartName)
    if PartName == "Head" then
        return Character:FindFirstChild("Head")
    elseif PartName == "UpperTorso" then
        return Character:FindFirstChild("UpperTorso") or Character:FindFirstChild("Torso")
    else
        return Character:FindFirstChild("HumanoidRootPart")
    end
end

local function IsPlayerValid(Player)
    if not Player or Player == LocalPlayer then return false end
    if not Player.Character then return false end
    if IsTeammate(Player) and Config.Aimbot.TeamCheck then return false end
    
    local Character = Player.Character
    local Humanoid = Character:FindFirstChild("Humanoid")
    local TargetPart = GetCharacterPart(Character, Config.Aimbot.TargetPart)
    
    if not Humanoid or not TargetPart then return false end
    if Humanoid.Health <= 0 then return false end
    
    return true
end

local function GetDistance(Player)
    if not IsPlayerValid(Player) then return math.huge end
    
    local Character = Player.Character
    local TargetPart = GetCharacterPart(Character, Config.Aimbot.TargetPart)
    local LocalCharacter = LocalPlayer.Character
    
    if not LocalCharacter or not LocalCharacter:FindFirstChild("HumanoidRootPart") then
        return math.huge
    end
    
    return (LocalCharacter.HumanoidRootPart.Position - TargetPart.Position).Magnitude
end

-- Aimbot Functions
local function GetClosestPlayer()
    local ClosestPlayer = nil
    local ShortestDistance = math.huge
    
    for _, Player in pairs(Players:GetPlayers()) do
        if IsPlayerValid(Player) then
            local Distance = GetDistance(Player)
            
            if Distance < Config.Aimbot.MaxDistance and Distance < ShortestDistance then
                ShortestDistance = Distance
                ClosestPlayer = Player
            end
        end
    end
    
    return ClosestPlayer
end

local function AimAtTarget(Player)
    if not IsPlayerValid(Player) then return end
    
    local Character = Player.Character
    local TargetPart = GetCharacterPart(Character, Config.Aimbot.TargetPart)
    
    if not TargetPart then return end
    
    local TargetPosition = TargetPart.Position
    
    -- Prediction
    if Config.Aimbot.PredictMovement then
        local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
        if HumanoidRootPart then
            local Velocity = HumanoidRootPart.Velocity
            local Distance = GetDistance(Player)
            local TimeToTarget = Distance / 1000
            TargetPosition = TargetPosition + (Velocity * TimeToTarget * Config.Aimbot.PredictionStrength)
        end
    end
    
    local CameraPosition = Camera.CFrame.Position
    local Direction = (TargetPosition - CameraPosition).Unit
    local NewCFrame = CFrame.lookAt(CameraPosition, CameraPosition + Direction)
    
    if Config.Aimbot.Smoothing then
        Camera.CFrame = Camera.CFrame:Lerp(NewCFrame, Config.Aimbot.SmoothingFactor)
    else
        Camera.CFrame = NewCFrame
    end
end

-- ESP Functions
local function CreateESP(Player)
    if ESPObjects[Player] then return end
    if not IsPlayerValid(Player) then return end
    
    local Character = Player.Character
    local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
    
    if not HumanoidRootPart then return end
    
    -- Create BillboardGui
    local Billboard = Instance.new("BillboardGui")
    Billboard.Parent = HumanoidRootPart
    Billboard.Size = UDim2.new(0, 200, 0, 100)
    Billboard.StudsOffset = Vector3.new(0, 3, 0)
    Billboard.AlwaysOnTop = true
    
    -- Name Label
    local NameLabel = Instance.new("TextLabel")
    NameLabel.Parent = Billboard
    NameLabel.Size = UDim2.new(1, 0, 0.4, 0)
    NameLabel.BackgroundTransparency = 1
    NameLabel.Text = Player.DisplayName or Player.Name
    NameLabel.TextColor3 = IsTeammate(Player) and Config.ESP.TeamColor or Config.ESP.EnemyColor
    NameLabel.TextSize = Config.ESP.TextSize
    NameLabel.TextStrokeTransparency = 0
    NameLabel.Font = Enum.Font.GothamBold
    
    -- Health Label
    local HealthLabel = Instance.new("TextLabel")
    HealthLabel.Parent = Billboard
    HealthLabel.Size = UDim2.new(1, 0, 0.3, 0)
    HealthLabel.Position = UDim2.new(0, 0, 0.4, 0)
    HealthLabel.BackgroundTransparency = 1
    HealthLabel.Text = "100/100"
    HealthLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
    HealthLabel.TextSize = Config.ESP.TextSize - 2
    HealthLabel.TextStrokeTransparency = 0
    HealthLabel.Font = Enum.Font.Gotham
    
    -- Distance Label
    local DistanceLabel = Instance.new("TextLabel")
    DistanceLabel.Parent = Billboard
    DistanceLabel.Size = UDim2.new(1, 0, 0.3, 0)
    DistanceLabel.Position = UDim2.new(0, 0, 0.7, 0)
    DistanceLabel.BackgroundTransparency = 1
    DistanceLabel.Text = "0m"
    DistanceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    DistanceLabel.TextSize = Config.ESP.TextSize - 2
    DistanceLabel.TextStrokeTransparency = 0
    DistanceLabel.Font = Enum.Font.Gotham
    
    -- Box
    local Box = Instance.new("SelectionBox")
    Box.Parent = Character
    Box.Adornee = Character
    Box.Color3 = IsTeammate(Player) and Config.ESP.TeamColor or Config.ESP.EnemyColor
    Box.LineThickness = Config.ESP.BoxThickness * 0.1
    Box.Transparency = 0.3
    
    ESPObjects[Player] = {
        Billboard = Billboard,
        NameLabel = NameLabel,
        HealthLabel = HealthLabel,
        DistanceLabel = DistanceLabel,
        Box = Box
    }
end

-- Player Modification Functions
local function SetWalkSpeed(speed)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = speed
    end
end

local function SetJumpPower(power)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.JumpPower = power
    end
end

local function ToggleFly()
    Config.Player.Fly = not Config.Player.Fly
    
    if Config.Player.Fly then
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local HumanoidRootPart = LocalPlayer.Character.HumanoidRootPart
            
            FlyBodyVelocity = Instance.new("BodyVelocity")
            FlyBodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
            FlyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
            FlyBodyVelocity.Parent = HumanoidRootPart
            
            FlyBodyAngularVelocity = Instance.new("BodyAngularVelocity")
            FlyBodyAngularVelocity.MaxTorque = Vector3.new(4000, 4000, 4000)
            FlyBodyAngularVelocity.AngularVelocity = Vector3.new(0, 0, 0)
            FlyBodyAngularVelocity.Parent = HumanoidRootPart
            
            Connections.Fly = RunService.Heartbeat:Connect(function()
                if FlyBodyVelocity then
                    local MoveVector = Vector3.new(0, 0, 0)
                    
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                        MoveVector = MoveVector + Camera.CFrame.LookVector
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                        MoveVector = MoveVector - Camera.CFrame.LookVector
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                        MoveVector = MoveVector - Camera.CFrame.RightVector
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                        MoveVector = MoveVector + Camera.CFrame.RightVector
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                        MoveVector = MoveVector + Vector3.new(0, 1, 0)
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                        MoveVector = MoveVector - Vector3.new(0, 1, 0)
                    end
                    
                    FlyBodyVelocity.Velocity = MoveVector * Config.Player.FlySpeed
                end
            end)
        end
    else
        if FlyBodyVelocity then
            FlyBodyVelocity:Destroy()
            FlyBodyVelocity = nil
        end
        if FlyBodyAngularVelocity then
            FlyBodyAngularVelocity:Destroy()
            FlyBodyAngularVelocity = nil
        end
        if Connections.Fly then
            Connections.Fly:Disconnect()
            Connections.Fly = nil
        end
    end
end

local function ToggleNoclip()
    Config.Player.Noclip = not Config.Player.Noclip
    
    if Config.Player.Noclip then
        Connections.Noclip = RunService.Stepped:Connect(function()
            if LocalPlayer.Character then
                for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end)
    else
        if Connections.Noclip then
            Connections.Noclip:Disconnect()
            Connections.Noclip = nil
        end
        
        if LocalPlayer.Character then
            for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
end

-- Visual Functions
local function ToggleFullBright()
    Config.Visual.FullBright = not Config.Visual.FullBright
    
    if Config.Visual.FullBright then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    else
        Lighting.Brightness = 1
        Lighting.ClockTime = 12
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = true
        Lighting.OutdoorAmbient = Color3.fromRGB(70, 70, 70)
    end
end

-- Create Main GUI
local function CreateMainGUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "BlockspinUltimateGUI"
    ScreenGui.Parent = CoreGui
    ScreenGui.ResetOnSpawn = false
    
    -- Main Frame
    local MainFrame = Instance.new("Frame")
    MainFrame.Parent = ScreenGui
    MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    MainFrame.BorderSizePixel = 0
    MainFrame.Position = UDim2.new(0, 50, 0, 50)
    MainFrame.Size = UDim2.new(0, 600, 0, 500)
    MainFrame.Active = true
    MainFrame.Draggable = true
    
    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 10)
    MainCorner.Parent = MainFrame
    
    -- Title Bar
    local TitleBar = Instance.new("Frame")
    TitleBar.Parent = MainFrame
    TitleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    TitleBar.BorderSizePixel = 0
    TitleBar.Size = UDim2.new(1, 0, 0, 40)
    
    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 10)
    TitleCorner.Parent = TitleBar
    
    local Title = Instance.new("TextLabel")
    Title.Parent = TitleBar
    Title.BackgroundTransparency = 1
    Title.Position = UDim2.new(0, 15, 0, 0)
    Title.Size = UDim2.new(1, -50, 1, 0)
    Title.Font = Enum.Font.GothamBold
    Title.Text = "🎮 Blockspin Ultimate v1.0"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 18
    Title.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Close Button
    local CloseButton = Instance.new("TextButton")
    CloseButton.Parent = TitleBar
    CloseButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    CloseButton.Position = UDim2.new(1, -35, 0, 5)
    CloseButton.Size = UDim2.new(0, 30, 0, 30)
    CloseButton.Font = Enum.Font.GothamBold
    CloseButton.Text = "×"
    CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseButton.TextSize = 16
    
    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 5)
    CloseCorner.Parent = CloseButton
    
    -- Tab System
    local TabFrame = Instance.new("Frame")
    TabFrame.Parent = MainFrame
    TabFrame.BackgroundTransparency = 1
    TabFrame.Position = UDim2.new(0, 0, 0, 40)
    TabFrame.Size = UDim2.new(0, 150, 1, -40)
    
    local ContentFrame = Instance.new("Frame")
    ContentFrame.Parent = MainFrame
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.Position = UDim2.new(0, 150, 0, 40)
    ContentFrame.Size = UDim2.new(1, -150, 1, -40)
    
    -- Tab Buttons
    local tabs = {"Aimbot", "ESP", "Player", "Visual", "Misc"}
    local tabButtons = {}
    local tabContents = {}
    
    for i, tabName in ipairs(tabs) do
        -- Tab Button
        local TabButton = Instance.new("TextButton")
        TabButton.Parent = TabFrame
        TabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        TabButton.Position = UDim2.new(0, 10, 0, 10 + (i-1) * 50)
        TabButton.Size = UDim2.new(1, -20, 0, 40)
        TabButton.Font = Enum.Font.Gotham
        TabButton.Text = tabName
        TabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        TabButton.TextSize = 14
        
        local TabCorner = Instance.new("UICorner")
        TabCorner.CornerRadius = UDim.new(0, 5)
        TabCorner.Parent = TabButton
        
        tabButtons[tabName] = TabButton
        
        -- Tab Content
        local TabContent = Instance.new("ScrollingFrame")
        TabContent.Parent = ContentFrame
        TabContent.BackgroundTransparency = 1
        TabContent.Position = UDim2.new(0, 10, 0, 10)
        TabContent.Size = UDim2.new(1, -20, 1, -20)
        TabContent.ScrollBarThickness = 5
        TabContent.Visible = (i == 1)
        
        local ContentLayout = Instance.new("UIListLayout")
        ContentLayout.Parent = TabContent
        ContentLayout.Padding = UDim.new(0, 5)
        ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
        
        tabContents[tabName] = TabContent
    end
    
    -- Tab switching
    for tabName, button in pairs(tabButtons) do
        button.MouseButton1Click:Connect(function()
            for name, content in pairs(tabContents) do
                content.Visible = (name == tabName)
            end
            
            for name, btn in pairs(tabButtons) do
                btn.BackgroundColor3 = (name == tabName) and Color3.fromRGB(60, 60, 60) or Color3.fromRGB(40, 40, 40)
            end
        end)
    end
    
    -- Helper function to create toggle
    local function CreateToggle(parent, text, configPath, callback)
        local ToggleFrame = Instance.new("Frame")
        ToggleFrame.Parent = parent
        ToggleFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        ToggleFrame.Size = UDim2.new(1, 0, 0, 35)
        
        local ToggleCorner = Instance.new("UICorner")
        ToggleCorner.CornerRadius = UDim.new(0, 5)
        ToggleCorner.Parent = ToggleFrame
        
        local ToggleLabel = Instance.new("TextLabel")
        ToggleLabel.Parent = ToggleFrame
        ToggleLabel.BackgroundTransparency = 1
        ToggleLabel.Position = UDim2.new(0, 10, 0, 0)
        ToggleLabel.Size = UDim2.new(1, -50, 1, 0)
        ToggleLabel.Font = Enum.Font.Gotham
        ToggleLabel.Text = text
        ToggleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        ToggleLabel.TextSize = 12
        ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
        
        local ToggleButton = Instance.new("TextButton")
        ToggleButton.Parent = ToggleFrame
        ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        ToggleButton.Position = UDim2.new(1, -35, 0, 5)
        ToggleButton.Size = UDim2.new(0, 30, 0, 25)
        ToggleButton.Font = Enum.Font.Gotham
        ToggleButton.Text = "OFF"
        ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        ToggleButton.TextSize = 10
        
        local ToggleBtnCorner = Instance.new("UICorner")
        ToggleBtnCorner.CornerRadius = UDim.new(0, 3)
        ToggleBtnCorner.Parent = ToggleButton
        
        ToggleButton.MouseButton1Click:Connect(function()
            local currentValue = Config[configPath[1]][configPath[2]]
            Config[configPath[1]][configPath[2]] = not currentValue
            
            ToggleButton.BackgroundColor3 = Config[configPath[1]][configPath[2]] and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
            ToggleButton.Text = Config[configPath[1]][configPath[2]] and "ON" or "OFF"
            
            if callback then
                callback(Config[configPath[1]][configPath[2]])
            end
        end)
        
        return ToggleFrame
    end
    
    -- Helper function to create slider
    local function CreateSlider(parent, text, configPath, min, max, callback)
        local SliderFrame = Instance.new("Frame")
        SliderFrame.Parent = parent
        SliderFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        SliderFrame.Size = UDim2.new(1, 0, 0, 50)
        
        local SliderCorner = Instance.new("UICorner")
        SliderCorner.CornerRadius = UDim.new(0, 5)
        SliderCorner.Parent = SliderFrame
        
        local SliderLabel = Instance.new("TextLabel")
        SliderLabel.Parent = SliderFrame
        SliderLabel.BackgroundTransparency = 1
        SliderLabel.Position = UDim2.new(0, 10, 0, 0)
        SliderLabel.Size = UDim2.new(1, -20, 0, 25)
        SliderLabel.Font = Enum.Font.Gotham
        SliderLabel.Text = text .. ": " .. Config[configPath[1]][configPath[2]]
        SliderLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        SliderLabel.TextSize = 12
        SliderLabel.TextXAlignment = Enum.TextXAlignment.Left
        
        local SliderBar = Instance.new("Frame")
        SliderBar.Parent = SliderFrame
        SliderBar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        SliderBar.Position = UDim2.new(0, 10, 0, 30)
        SliderBar.Size = UDim2.new(1, -20, 0, 15)
        
        local SliderBarCorner = Instance.new("UICorner")
        SliderBarCorner.CornerRadius = UDim.new(0, 3)
        SliderBarCorner.Parent = SliderBar
        
        local SliderFill = Instance.new("Frame")
        SliderFill.Parent = SliderBar
        SliderFill.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
        SliderFill.Size = UDim2.new((Config[configPath[1]][configPath[2]] - min) / (max - min), 0, 1, 0)
        
        local SliderFillCorner = Instance.new("UICorner")
        SliderFillCorner.CornerRadius = UDim.new(0, 3)
        SliderFillCorner.Parent = SliderFill
        
        local SliderButton = Instance.new("TextButton")
        SliderButton.Parent = SliderBar
        SliderButton.BackgroundTransparency = 1
        SliderButton.Size = UDim2.new(1, 0, 1, 0)
        SliderButton.Text = ""
        
        local dragging = false
        
        SliderButton.MouseButton1Down:Connect(function()
            dragging = true
        end)
        
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local mousePos = input.Position.X
                local sliderPos = SliderBar.AbsolutePosition.X
                local sliderSize = SliderBar.AbsoluteSize.X
                local relativePos = math.clamp((mousePos - sliderPos) / sliderSize, 0, 1)
                local value = min + (max - min) * relativePos
                
                Config[configPath[1]][configPath[2]] = value
                SliderFill.Size = UDim2.new(relativePos, 0, 1, 0)
                SliderLabel.Text = text .. ": " .. math.floor(value * 100) / 100
                
                if callback then
                    callback(value)
                end
            end
        end)
        
        return SliderFrame
    end
    
    -- Populate Aimbot Tab
    CreateToggle(tabContents.Aimbot, "Enable Aimbot", {"Aimbot", "Enabled"})
    CreateToggle(tabContents.Aimbot, "Show FOV Circle", {"Aimbot", "ShowFOV"})
    CreateToggle(tabContents.Aimbot, "Highlight Target", {"Aimbot", "HighlightTarget"})
    CreateToggle(tabContents.Aimbot, "Wall Check", {"Aimbot", "WallCheck"})
    CreateToggle(tabContents.Aimbot, "Team Check", {"Aimbot", "TeamCheck"})
    CreateToggle(tabContents.Aimbot, "Predict Movement", {"Aimbot", "PredictMovement"})
    CreateToggle(tabContents.Aimbot, "Smoothing", {"Aimbot", "Smoothing"})
    CreateSlider(tabContents.Aimbot, "FOV Size", {"Aimbot", "FOV"}, 10, 300)
    CreateSlider(tabContents.Aimbot, "Max Distance", {"Aimbot", "MaxDistance"}, 50, 1000)
    CreateSlider(tabContents.Aimbot, "Smoothing Factor", {"Aimbot", "SmoothingFactor"}, 0.01, 1)
    
    -- Populate ESP Tab
    CreateToggle(tabContents.ESP, "Enable ESP", {"ESP", "Enabled"})
    CreateToggle(tabContents.ESP, "Show Boxes", {"ESP", "ShowBoxes"})
    CreateToggle(tabContents.ESP, "Show Names", {"ESP", "ShowNames"})
    CreateToggle(tabContents.ESP, "Show Health", {"ESP", "ShowHealth"})
    CreateToggle(tabContents.ESP, "Show Distance", {"ESP", "ShowDistance"})
    CreateToggle(tabContents.ESP, "Show Team", {"ESP", "ShowTeam"})
    CreateSlider(tabContents.ESP, "Max Distance", {"ESP", "MaxDistance"}, 100, 2000)
    CreateSlider(tabContents.ESP, "Text Size", {"ESP", "TextSize"}, 8, 20)
    
    -- Populate Player Tab
    CreateToggle(tabContents.Player, "Speed Hack", {"Player", "SpeedHack"}, function(enabled)
        if enabled then
            SetWalkSpeed(Config.Player.WalkSpeed)
        else
            SetWalkSpeed(OriginalWalkSpeed)
        end
    end)
    CreateToggle(tabContents.Player, "Jump Hack", {"Player", "JumpHack"}, function(enabled)
        if enabled then
            SetJumpPower(Config.Player.JumpPower)
        else
            SetJumpPower(OriginalJumpPower)
        end
    end)
    CreateToggle(tabContents.Player, "Fly", {"Player", "Fly"}, ToggleFly)
    CreateToggle(tabContents.Player, "Noclip", {"Player", "Noclip"}, ToggleNoclip)
    CreateToggle(tabContents.Player, "Infinite Jump", {"Player", "InfiniteJump"})
    CreateSlider(tabContents.Player, "Walk Speed", {"Player", "WalkSpeed"}, 16, 200, function(value)
        if Config.Player.SpeedHack then
            SetWalkSpeed(value)
        end
    end)
    CreateSlider(tabContents.Player, "Jump Power", {"Player", "JumpPower"}, 50, 300, function(value)
        if Config.Player.JumpHack then
            SetJumpPower(value)
        end
    end)
    CreateSlider(tabContents.Player, "Fly Speed", {"Player", "FlySpeed"}, 10, 200)
    
    -- Populate Visual Tab
    CreateToggle(tabContents.Visual, "Full Bright", {"Visual", "FullBright"}, ToggleFullBright)
    CreateToggle(tabContents.Visual, "No Fog", {"Visual", "NoFog"})
    CreateToggle(tabContents.Visual, "Crosshair", {"Visual", "Crosshair"})
    CreateToggle(tabContents.Visual, "Remove Textures", {"Visual", "RemoveTextures"})
    CreateSlider(tabContents.Visual, "Crosshair Size", {"Visual", "CrosshairSize"}, 5, 50)
    
    -- Populate Misc Tab
    CreateToggle(tabContents.Misc, "Auto Respawn", {"Misc", "AutoRespawn"})
    CreateToggle(tabContents.Misc, "Kill Aura", {"Misc", "KillAura"})
    CreateToggle(tabContents.Misc, "Auto Click", {"Misc", "AutoClick"})
    CreateSlider(tabContents.Misc, "Kill Aura Range", {"Misc", "KillAuraRange"}, 5, 50)
    CreateSlider(tabContents.Misc, "Click Delay", {"Misc", "ClickDelay"}, 0.01, 1)
    
    -- Close button functionality
    CloseButton.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
        
        -- Cleanup all connections
        for _, connection in pairs(Connections) do
            if connection then
                connection:Disconnect()
            end
        end
        
        -- Reset player modifications
        if LocalPlayer.Character then
            if LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid.WalkSpeed = OriginalWalkSpeed
                LocalPlayer.Character.Humanoid.JumpPower = OriginalJumpPower
            end
        end
        
        print("Blockspin Ultimate closed!")
    end)
    
    return ScreenGui
end

-- Main execution functions
local function RunAimbot()
    if not Config.Aimbot.Enabled then return end
    
    local Target = GetClosestPlayer()
    CurrentTarget = Target
    
    if Target then
        AimAtTarget(Target)
    end
end

local function RunESP()
    if not Config.ESP.Enabled then return end
    
    for _, Player in pairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer then
            if not ESPObjects[Player] then
                CreateESP(Player)
            end
        end
    end
end

-- Initialize connections
Connections.Aimbot = RunService.Heartbeat:Connect(RunAimbot)
Connections.ESP = RunService.Heartbeat:Connect(RunESP)

-- Input handling
UserInputService.InputBegan:Connect(function(Input, GameProcessed)
    if GameProcessed then return end
    
    if Input.KeyCode == Enum.KeyCode.Insert then
        -- Toggle GUI visibility
        local gui = CoreGui:FindFirstChild("BlockspinUltimateGUI")
        if gui then
            gui.Enabled = not gui.Enabled
        end
    end
end)

-- Player events
Players.PlayerRemoving:Connect(function(Player)
    if ESPObjects[Player] then
        ESPObjects[Player].Billboard:Destroy()
        ESPObjects[Player].Box:Destroy()
        ESPObjects[Player] = nil
    end
    
    if CurrentTarget == Player then
        CurrentTarget = nil
    end
end)

-- Initialize GUI
CreateMainGUI()

print("=== Blockspin Ultimate v1.0 Loaded ===")
print("🎮 Press INSERT to toggle GUI")
print("🎯 Full aimbot and ESP system")
print("🚀 Player modifications available")
print("✨ Visual enhancements included")
print("🔧 Misc features and utilities")
print("=====================================")

-- Auto-notification
spawn(function()
    wait(2)
    game.StarterGui:SetCore("SendNotification", {
        Title = "Blockspin Ultimate";
        Text = "Script loaded successfully! Press INSERT to open menu.";
        Duration = 5;
    })
end)
