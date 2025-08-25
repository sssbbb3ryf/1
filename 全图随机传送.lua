game:GetService("StarterGui"):SetCore("SendNotification",{
    Title = "灰",
    Text = "作者灰",
    Icon = "rbxassetid://80818864421975",
    Duration = 50,
    Callback = bindable,
})
local PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
local UserInputService = game:GetService("UserInputService")

-- 创建UI界面
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoTPGui"
screenGui.Parent = PlayerGui
screenGui.ResetOnSpawn = false

-- 创建主容器
local container = Instance.new("Frame")
container.Name = "ControlContainer"
container.Size = UDim2.new(0, 70, 0, 70)  -- 容器尺寸略大于按钮
container.Position = UDim2.new(1, -80, 0, 20)  -- 右上角位置
container.AnchorPoint = Vector2.new(1, 0)  -- 右上锚点
container.BackgroundTransparency = 1  -- 完全透明
container.Active = true  -- 允许接收输入
container.Selectable = true
container.Parent = screenGui

-- 创建控制按钮
local button = Instance.new("TextButton")
button.Name = "AutoTPToggle"
button.Size = UDim2.new(0, 60, 0, 60)  -- 60x60像素
button.Position = UDim2.new(0.5, 0, 0.5, 0)  -- 容器中心
button.AnchorPoint = Vector2.new(0.5, 0.5)  -- 中心锚点
button.BackgroundColor3 = Color3.fromRGB(220, 20, 60)  -- 关闭状态颜色（红色）
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.Text = "OFF"
button.Font = Enum.Font.SourceSansBold
button.TextSize = 18
button.Parent = container

-- 添加圆角效果
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)  -- 完全圆形
corner.Parent = button

-- 添加阴影效果
local shadow = Instance.new("UIStroke")
shadow.Color = Color3.fromRGB(60, 60, 60)
shadow.Thickness = 3
shadow.Parent = button

-- 控制变量
local br = false
local loopActive = false
local currentPlayerIndex = 1  -- 当前传送的玩家索引
local loopThread = nil  -- 用于存储循环线程
local dragging = false
local dragStartPosition = nil
local dragStartOffset = nil

-- 可拖动功能实现
container.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStartPosition = Vector2.new(input.Position.X, input.Position.Y)
        dragStartOffset = container.Position
    end
end)

container.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = Vector2.new(input.Position.X, input.Position.Y) - dragStartPosition
        container.Position = UDim2.new(
            dragStartOffset.X.Scale, 
            dragStartOffset.X.Offset + delta.X,
            dragStartOffset.Y.Scale,
            dragStartOffset.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
        dragStartPosition = nil
        dragStartOffset = nil
    end
end)

-- 修复循环中断的核心函数
local function teleportLoop()
    while br and loopActive do
        -- 使用pcall捕获错误防止中断
        local success, err = pcall(function()
            -- 获取所有玩家（排除自己）
            local players = {}
            for _, player in ipairs(game.Players:GetPlayers()) do
                if player ~= game.Players.LocalPlayer then
                    table.insert(players, player)
                end
            end
            
            if #players == 0 then
                currentPlayerIndex = 1
                return
            end
            
            -- 确保索引有效
            if currentPlayerIndex > #players then
                currentPlayerIndex = 1
            end
            
            local targetPlayer = players[currentPlayerIndex]
            
            -- 确保目标玩家有效
            if not targetPlayer or not targetPlayer:IsDescendantOf(game) then
                currentPlayerIndex = (currentPlayerIndex % #players) + 1
                return
            end
            
            -- 确保目标玩家角色存在
            if targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local targetHRP = targetPlayer.Character.HumanoidRootPart
                
                -- 确保部件有效
                if targetHRP:IsDescendantOf(workspace) then
                    -- 计算身后位置（紧贴着目标）
                    local behindOffset = targetHRP.CFrame.LookVector * -3  -- 3个单位的距离
                    local teleportPosition = targetHRP.Position + behindOffset
                    
                    -- 确保本地玩家角色存在
                    local localChar = game.Players.LocalPlayer.Character
                    if localChar and localChar:FindFirstChild("HumanoidRootPart") then
                        local localHRP = localChar.HumanoidRootPart
                        
                        -- 确保本地部件有效
                        if localHRP:IsDescendantOf(workspace) then
                            -- 创建面向目标玩家的CFrame
                            local teleportCFrame = CFrame.new(teleportPosition, targetHRP.Position)
                            localHRP.CFrame = teleportCFrame
                        end
                    end
                end
            end
            
            -- 移动到下一个玩家
            currentPlayerIndex = (currentPlayerIndex % #players) + 1
        end)
        
        if not success then
            warn("传送循环出错: " .. tostring(err))
            -- 出错时重置索引
            currentPlayerIndex = 1
        end
        
        -- 使用task.wait代替wait更可靠
        task.wait(0.1)
    end
    loopActive = false
end

-- 切换传送功能
local function toggleTeleport()
    if br and not loopActive then
        loopActive = true
        
        -- 终止之前的线程（如果存在）
        if loopThread then
            coroutine.close(loopThread)
        end
        
        -- 创建新线程
        loopThread = coroutine.create(teleportLoop)
        coroutine.resume(loopThread)
    elseif not br and loopActive then
        loopActive = false
    end
end

-- 按钮点击事件
button.MouseButton1Click:Connect(function()
    br = not br
    button.Text = br and "开" or "关"
    button.BackgroundColor3 = br and Color3.fromRGB(50, 205, 50) or Color3.fromRGB(220, 20, 60)
    
    toggleTeleport()
end)

-- 玩家离开时重置状态
game.Players.PlayerRemoving:Connect(function(player)
    if player == game.Players.LocalPlayer then
        br = false
        loopActive = false
        button.Text = "关"
        button.BackgroundColor3 = Color3.fromRGB(220, 20, 60)
    else
        -- 如果离开的是当前目标玩家，重置索引
        currentPlayerIndex = 1
    end
end)

-- 角色变化时重置状态
game.Players.LocalPlayer.CharacterAdded:Connect(function()
    if br then
        br = false
        button.Text = "关"
        button.BackgroundColor3 = Color3.fromRGB(220, 20, 60)
        loopActive = false
    end
end)

-- 游戏重置时清理
game.Players.LocalPlayer.CharacterRemoving:Connect(function()
    if br then
        br = false
        loopActive = false
    end
end)

-- 处理窗口大小变化
game:GetService("GuiService"):GetSafeZoneChangedSignal():Connect(function()
    local safeZone = game:GetService("GuiService"):GetSafeZone()
    local screenSize = workspace.CurrentCamera.ViewportSize
    
    -- 确保UI保持在安全区域内
    local currentPosition = container.Position
    local newX = math.clamp(currentPosition.X.Offset, safeZone.X, screenSize.X - safeZone.X - container.AbsoluteSize.X)
    local newY = math.clamp(currentPosition.Y.Offset, safeZone.Y, screenSize.Y - safeZone.Y - container.AbsoluteSize.Y)
    
    container.Position = UDim2.new(currentPosition.X.Scale, newX, currentPosition.Y.Scale, newY)
end)