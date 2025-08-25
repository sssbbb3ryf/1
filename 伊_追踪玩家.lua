local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PlayerTrackerUI"
ScreenGui.Parent = PlayerGui
ScreenGui.ResetOnSpawn = false

local MinimizedContainer = Instance.new("Frame")
MinimizedContainer.Name = "MinimizedContainer"
MinimizedContainer.Size = UDim2.new(0, 35, 0, 35)
MinimizedContainer.Position = UDim2.new(1, -45, 0, 20)
MinimizedContainer.AnchorPoint = Vector2.new(1, 0)
MinimizedContainer.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
MinimizedContainer.BorderSizePixel = 0
MinimizedContainer.Parent = ScreenGui

local MiniCorner = Instance.new("UICorner")
MiniCorner.CornerRadius = UDim.new(0, 8)
MiniCorner.Parent = MinimizedContainer

local MiniStroke = Instance.new("UIStroke")
MiniStroke.Color = Color3.fromRGB(200, 200, 200)
MiniStroke.Thickness = 1
MiniStroke.Parent = MinimizedContainer

local MiniButton = Instance.new("TextButton")
MiniButton.Name = "MiniButton"
MiniButton.Text = "H"
MiniButton.Size = UDim2.new(1, 0, 1, 0)
MiniButton.BackgroundTransparency = 1
MiniButton.TextColor3 = Color3.fromRGB(50, 50, 50)
MiniButton.Font = Enum.Font.SourceSansBold
MiniButton.TextSize = 20
MiniButton.Parent = MinimizedContainer

local MainContainer = Instance.new("Frame")
MainContainer.Name = "MainContainer"
MainContainer.Size = UDim2.new(0, 220, 0, 170)
MainContainer.Position = MinimizedContainer.Position - UDim2.new(0, 0, 0, -10)
MainContainer.AnchorPoint = Vector2.new(1, 0)
MainContainer.BackgroundColor3 = Color3.fromRGB(250, 250, 250)
MainContainer.BorderSizePixel = 0
MainContainer.Visible = false
MainContainer.Parent = ScreenGui

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(200, 200, 200)
MainStroke.Thickness = 1
MainStroke.Parent = MainContainer

local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 28)
TitleBar.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainContainer

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Text = "HUAの追踪"
Title.Size = UDim2.new(0.7, 0, 1, 0)
Title.Position = UDim2.new(0.15, 0, 0, 0)
Title.BackgroundTransparency = 1
Title.TextColor3 = Color3.fromRGB(50, 50, 50)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 16
Title.Parent = TitleBar

local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Text = "×"
CloseButton.Size = UDim2.new(0, 28, 0, 28)
CloseButton.Position = UDim2.new(1, -28, 0, 0)
CloseButton.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
CloseButton.TextColor3 = Color3.fromRGB(50, 50, 50)
CloseButton.Font = Enum.Font.SourceSansBold
CloseButton.TextSize = 20
CloseButton.Parent = TitleBar

local ContentFrame = Instance.new("Frame")
ContentFrame.Name = "Content"
ContentFrame.Size = UDim2.new(1, -10, 1, -40)
ContentFrame.Position = UDim2.new(0, 5, 0, 35)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainContainer

local SearchBox = Instance.new("TextBox")
SearchBox.Name = "SearchBox"
SearchBox.PlaceholderText = "搜索玩家..."
SearchBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
SearchBox.Size = UDim2.new(1, 0, 0, 30)
SearchBox.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
SearchBox.TextColor3 = Color3.fromRGB(50, 50, 50)
SearchBox.Font = Enum.Font.SourceSans
SearchBox.TextSize = 14
SearchBox.Parent = ContentFrame

local SearchStroke = Instance.new("UIStroke")
SearchStroke.Color = Color3.fromRGB(200, 200, 200)
SearchStroke.Thickness = 1
SearchStroke.Parent = SearchBox

local PlayerList = Instance.new("ScrollingFrame")
PlayerList.Name = "PlayerList"
PlayerList.Size = UDim2.new(1, 0, 1, -65)
PlayerList.Position = UDim2.new(0, 0, 0, 35)
PlayerList.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
PlayerList.BorderSizePixel = 0
PlayerList.CanvasSize = UDim2.new(0, 0, 0, 0)
PlayerList.AutomaticCanvasSize = Enum.AutomaticSize.Y
PlayerList.ScrollBarThickness = 4
PlayerList.Parent = ContentFrame

local ListStroke = Instance.new("UIStroke")
ListStroke.Color = Color3.fromRGB(200, 200, 200)
ListStroke.Thickness = 1
ListStroke.Parent = PlayerList

local ListLayout = Instance.new("UIListLayout")
ListLayout.Padding = UDim.new(0, 4)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Parent = PlayerList

local TrackButton = Instance.new("TextButton")
TrackButton.Name = "TrackButton"
TrackButton.Text = "开始追踪"
TrackButton.Size = UDim2.new(1, 0, 0, 30)
TrackButton.Position = UDim2.new(0, 0, 1, -30)
TrackButton.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
TrackButton.TextColor3 = Color3.fromRGB(50, 50, 50)
TrackButton.Font = Enum.Font.SourceSansBold
TrackButton.TextSize = 16
TrackButton.Parent = ContentFrame

local TrackStroke = Instance.new("UIStroke")
TrackStroke.Color = Color3.fromRGB(200, 200, 200)
TrackStroke.Thickness = 1
TrackStroke.Parent = TrackButton

local isTracking = false
local isExpanded = false
local targetPlayer = nil
local isDragging = false
local dragStartPosition = nil
local dragStartOffset = nil

local function UpdatePlayerList(searchTerm)
    for _, child in ipairs(PlayerList:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    local players = Players:GetPlayers()
    local filteredPlayers = {}
    
    if searchTerm and searchTerm ~= "" then
        local lowerTerm = string.lower(searchTerm)
        for _, player in ipairs(players) do
            if player ~= LocalPlayer then
                local name = string.lower(player.Name)
                if string.find(name, lowerTerm, 1, true) then
                    table.insert(filteredPlayers, player)
                end
            end
        end
    else
        for _, player in ipairs(players) do
            if player ~= LocalPlayer then
                table.insert(filteredPlayers, player)
            end
        end
    end
    
    for _, player in ipairs(filteredPlayers) do
        local playerButton = Instance.new("TextButton")
        playerButton.Name = player.Name
        playerButton.Text = player.Name
        playerButton.Size = UDim2.new(1, -5, 0, 28)
        playerButton.BackgroundColor3 = Color3.fromRGB(250, 250, 250)
        playerButton.TextColor3 = Color3.fromRGB(50, 50, 50)
        playerButton.Font = Enum.Font.SourceSans
        playerButton.TextSize = 14
        playerButton.LayoutOrder = #PlayerList:GetChildren()
        playerButton.Parent = PlayerList
        
        local ButtonStroke = Instance.new("UIStroke")
        ButtonStroke.Color = Color3.fromRGB(200, 200, 200)
        ButtonStroke.Thickness = 1
        ButtonStroke.Parent = playerButton
        
        playerButton.MouseButton1Click:Connect(function()
            SearchBox.Text = player.Name
            targetPlayer = player
        end)
    end
end

local function ToggleTracking()
    if not targetPlayer then
        return
    end
    
    isTracking = not isTracking
    
    if isTracking then
        TrackButton.Text = "停止追踪"
        TrackButton.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
    else
        TrackButton.Text = "开始追踪"
        TrackButton.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
    end
end

local function TrackPlayer()
    if not isTracking or not targetPlayer then return end
    
    local targetChar = targetPlayer.Character
    local localChar = LocalPlayer.Character
    
    if targetChar and targetChar:FindFirstChild("HumanoidRootPart") and 
       localChar and localChar:FindFirstChild("HumanoidRootPart") then
        
        local targetHRP = targetChar.HumanoidRootPart
        local localHRP = localChar.HumanoidRootPart
        
        local behindOffset = targetHRP.CFrame.LookVector * -3
        local teleportPosition = targetHRP.Position + behindOffset
        
        local teleportCFrame = CFrame.new(teleportPosition, targetHRP.Position)
        localHRP.CFrame = teleportCFrame
    end
end

local function HandleDragStart(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or 
       input.UserInputType == Enum.UserInputType.Touch then
        
        isDragging = true
        dragStartPosition = input.Position
        
        if isExpanded then
            dragStartOffset = MainContainer.Position
        else
            dragStartOffset = MinimizedContainer.Position
        end
    end
end

local function HandleDrag(input)
    if not isDragging then return end
    
    local currentPos = input.Position
    local delta = currentPos - dragStartPosition
    
    if isExpanded then
        MainContainer.Position = UDim2.new(
            dragStartOffset.X.Scale, 
            dragStartOffset.X.Offset + delta.X,
            dragStartOffset.Y.Scale,
            dragStartOffset.Y.Offset + delta.Y
        )
    else
        MinimizedContainer.Position = UDim2.new(
            dragStartOffset.X.Scale, 
            dragStartOffset.X.Offset + delta.X,
            dragStartOffset.Y.Scale,
            dragStartOffset.Y.Offset + delta.Y
        )
    end
end

local function HandleDragEnd()
    isDragging = false
end

local function ToggleUI()
    isExpanded = not isExpanded
    
    if isExpanded then
        MinimizedContainer.Visible = false
        MainContainer.Visible = true
        UpdatePlayerList("")
    else
        MainContainer.Visible = false
        MinimizedContainer.Visible = true
    end
end

SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    UpdatePlayerList(SearchBox.Text)
end)

TrackButton.MouseButton1Click:Connect(ToggleTracking)
MiniButton.MouseButton1Click:Connect(ToggleUI)
CloseButton.MouseButton1Click:Connect(ToggleUI)

TitleBar.InputBegan:Connect(HandleDragStart)
MinimizedContainer.InputBegan:Connect(HandleDragStart)

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or 
       input.UserInputType == Enum.UserInputType.Touch then
        HandleDrag(input)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or 
       input.UserInputType == Enum.UserInputType.Touch then
        HandleDragEnd()
    end
end)

UpdatePlayerList("")

RunService.Heartbeat:Connect(TrackPlayer)

Players.PlayerAdded:Connect(function()
    UpdatePlayerList(SearchBox.Text)
end)

Players.PlayerRemoving:Connect(function(player)
    if player == targetPlayer then
        isTracking = false
        targetPlayer = nil
        TrackButton.Text = "开始追踪"
        TrackButton.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
    end
    UpdatePlayerList(SearchBox.Text)
end)

if UserInputService.TouchEnabled then
    MinimizedContainer.Size = UDim2.new(0, 40, 0, 40)
    MainContainer.Size = UDim2.new(0, 240, 0, 190)
    
    MiniButton.TextSize = 24
    SearchBox.TextSize = 16
    TrackButton.TextSize = 16
    
    PlayerList:GetChildren():ForEach(function(child)
        if child:IsA("TextButton") then
            child.Size = UDim2.new(1, -5, 0, 32)
            child.TextSize = 14
        end
    end)
end

local function UpdateSafeZone()
    local safeZone = game:GetService("GuiService"):GetSafeZone()
    local screenSize = workspace.CurrentCamera.ViewportSize
    
    if isExpanded then
        local currentPosition = MainContainer.Position
        local newX = math.clamp(currentPosition.X.Offset, safeZone.X, screenSize.X - safeZone.X - MainContainer.AbsoluteSize.X)
        local newY = math.clamp(currentPosition.Y.Offset, safeZone.Y, screenSize.Y - safeZone.Y - MainContainer.AbsoluteSize.Y)
        
        MainContainer.Position = UDim2.new(currentPosition.X.Scale, newX, currentPosition.Y.Scale, newY)
    else
        local currentPosition = MinimizedContainer.Position
        local newX = math.clamp(currentPosition.X.Offset, safeZone.X, screenSize.X - safeZone.X - MinimizedContainer.AbsoluteSize.X)
        local newY = math.clamp(currentPosition.Y.Offset, safeZone.Y, screenSize.Y - safeZone.Y - MinimizedContainer.AbsoluteSize.Y)
        
        MinimizedContainer.Position = UDim2.new(currentPosition.X.Scale, newX, currentPosition.Y.Scale, newY)
    end
end
