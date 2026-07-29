-- ============================================================
-- 预下载脚本：一次性下载所有动画资源到本地缓存
-- 适用：PC端 和 手机端（需要执行器支持 writefile/readfile）
-- 使用方法：在游戏中执行此脚本，等待下载完成后即可使用主脚本
-- 注意：首次运行需要下载约270+152帧+BGM，耗时约2-5分钟
-- ============================================================

print("============================================")
print("   动画资源预下载脚本")
print("   适用平台：PC / 手机（需支持文件系统）")
print("============================================")

-- 检测文件系统支持
if not (isfile and readfile and writefile and getcustomasset) then
    warn("[错误] 当前执行器不支持文件系统！")
    warn("[错误] 请更换支持 writefile/readfile 的执行器（如 Delta、Arceus X 等）")
    return
end

-- ============================================================
-- 配置
-- ============================================================
local LOADING_BASE = "https://raw.githubusercontent.com/sssbbb3ryf/loading/main/"
local LOADING_CACHE = "loading_anim_cache"

local ANIM_BASE = "https://gitee.com/xsadad_0/roxy/raw/main/"
local ANIM_CACHE = "anim_bg_cache"

local NORMAL_URL = "https://raw.githubusercontent.com/sssbbb3ryf/h-h-h/main/bg.jpg"
local NORMAL_FILE = "normal_ui_bg_v2.jpg"

local BGM_FILE = "loading_bgm.mp3"

-- 创建缓存目录
if makefolder then
    makefolder(LOADING_CACHE)
    makefolder(ANIM_CACHE)
end

-- ============================================================
-- 带超时的 HttpGet
-- ============================================================
local function httpGetSafe(url, timeoutSec)
    timeoutSec = timeoutSec or 15
    local result = nil
    local done = false
    task.spawn(function()
        local ok, data = pcall(function()
            return game:HttpGet(url)
        end)
        if ok then result = data end
        done = true
    end)
    local start = tick()
    while not done do
        task.wait(0.1)
        if (tick() - start) > timeoutSec then
            done = true
            break
        end
    end
    return result
end

-- ============================================================
-- 自动检测加载动画帧数（GitHub 仓库）
-- ============================================================
local function detectLoadingFrames()
    print("[检测] 正在探测加载动画帧数...")
    -- 粗扫：每50帧跳着检测
    local lastFound = 0
    for i = 1, 1000, 50 do
        local fname = string.format("loading_%04d.jpg", i)
        local data = httpGetSafe(LOADING_BASE .. fname, 5)
        if data and #data > 500 then
            lastFound = i
        else
            break
        end
    end
    if lastFound == 0 then return 0 end
    -- 精扫
    for i = lastFound + 1, lastFound + 50 do
        local fname = string.format("loading_%04d.jpg", i)
        local data = httpGetSafe(LOADING_BASE .. fname, 5)
        if data and #data > 500 then
            lastFound = i
        else
            break
        end
    end
    return lastFound
end

-- ============================================================
-- 下载单个文件（带重试）
-- ============================================================
local function downloadFile(url, savePath, minSize)
    minSize = minSize or 1000
    for attempt = 1, 3 do
        local data = httpGetSafe(url, 15)
        if data and #data >= minSize then
            local ok, err = pcall(function() writefile(savePath, data) end)
            if ok then
                return true, #data
            else
                warn("[下载失败] 写入失败:", savePath, err)
            end
        end
        if attempt < 3 then
            task.wait(0.5)
        end
    end
    return false
end

-- ============================================================
-- UI 进度显示
-- ============================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PreloadProgress"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 99999
local ok, err = pcall(function()
    screenGui.Parent = game:GetService("CoreGui")
end)
if not ok then
    screenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
end

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 400, 0, 250)
mainFrame.Position = UDim2.new(0.5, -200, 0.5, -125)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 40)
titleLabel.Position = UDim2.new(0, 0, 0, 15)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "动画资源预下载"
titleLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
titleLabel.TextSize = 22
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.Parent = mainFrame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -30, 0, 25)
statusLabel.Position = UDim2.new(0, 15, 0, 65)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "正在初始化..."
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.TextSize = 16
titleLabel.Font = Enum.Font.SourceSans
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = mainFrame

local detailLabel = Instance.new("TextLabel")
detailLabel.Size = UDim2.new(1, -30, 0, 20)
detailLabel.Position = UDim2.new(0, 15, 0, 95)
detailLabel.BackgroundTransparency = 1
detailLabel.Text = ""
detailLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
detailLabel.TextSize = 13
detailLabel.Font = Enum.Font.SourceSans
detailLabel.TextXAlignment = Enum.TextXAlignment.Left
detailLabel.Parent = mainFrame

-- 进度条背景
local barBg = Instance.new("Frame")
barBg.Size = UDim2.new(1, -30, 0, 20)
barBg.Position = UDim2.new(0, 15, 0, 130)
barBg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
barBg.BorderSizePixel = 0
barBg.Parent = mainFrame
local barBgCorner = Instance.new("UICorner")
barBgCorner.CornerRadius = UDim.new(0, 6)
barBgCorner.Parent = barBg

-- 进度条前景
local barFill = Instance.new("Frame")
barFill.Size = UDim2.new(0, 0, 1, 0)
barFill.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
barFill.BorderSizePixel = 0
barFill.Parent = barBg
local barFillCorner = Instance.new("UICorner")
barFillCorner.CornerRadius = UDim.new(0, 6)
barFillCorner.Parent = barFill

local percentLabel = Instance.new("TextLabel")
percentLabel.Size = UDim2.new(1, 0, 0, 25)
percentLabel.Position = UDim2.new(0, 0, 0, 160)
percentLabel.BackgroundTransparency = 1
percentLabel.Text = "0%"
percentLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
percentLabel.TextSize = 18
percentLabel.Font = Enum.Font.SourceSansBold
percentLabel.Parent = mainFrame

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(1, -30, 0, 20)
speedLabel.Position = UDim2.new(0, 15, 0, 195)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = ""
speedLabel.TextColor3 = Color3.fromRGB(130, 130, 130)
speedLabel.TextSize = 12
speedLabel.Font = Enum.Font.SourceSans
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = mainFrame

local tipLabel = Instance.new("TextLabel")
tipLabel.Size = UDim2.new(1, -30, 0, 20)
tipLabel.Position = UDim2.new(0, 15, 0, 220)
tipLabel.BackgroundTransparency = 1
tipLabel.Text = "下载完成后即可使用主脚本"
tipLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
tipLabel.TextSize = 12
tipLabel.Font = Enum.Font.SourceSansItalic
tipLabel.TextXAlignment = Enum.TextXAlignment.Left
tipLabel.Parent = mainFrame

local function updateProgress(current, total, label, detail)
    local pct = math.floor((current / total) * 100)
    barFill.Size = UDim2.new(pct / 100, 0, 1, 0)
    percentLabel.Text = pct .. "%"
    statusLabel.Text = label
    detailLabel.Text = detail or ""
end

-- ============================================================
-- 主下载流程
-- ============================================================
task.spawn(function()
    local totalSteps = 0
    local completedSteps = 0

    -- 1. 检测加载动画帧数
    updateProgress(0, 1, "正在检测加载动画帧数...", "连接 GitHub 仓库中")
    local loadingTotal = detectLoadingFrames()
    print("[检测] 加载动画: " .. loadingTotal .. " 帧")

    -- 2. UI背景动画固定152帧
    local animTotal = 152
    print("[检测] UI背景动画: " .. animTotal .. " 帧")

    -- 计算总任务数
    local loadingToDl = 0
    local animToDl = 0
    local needBGM = true
    local needNormalBg = true

    -- 检查加载动画缓存
    for i = 1, loadingTotal do
        local fname = string.format("loading_%04d.jpg", i)
        local fpath = LOADING_CACHE .. "/" .. fname
        if not isfile(fpath) then
            loadingToDl = loadingToDl + 1
        end
    end

    -- 检查UI背景动画缓存
    for i = 1, animTotal do
        local fname = string.format("frame_%04d.jpg", i)
        local fpath = ANIM_CACHE .. "/" .. fname
        if not isfile(fpath) then
            animToDl = animToDl + 1
        end
    end

    -- 检查BGM
    if isfile(BGM_FILE) then
        local ok, data = pcall(function() return readfile(BGM_FILE) end)
        if ok and data and #data > 10000 then
            needBGM = false
        else
            pcall(function() if delfile then delfile(BGM_FILE) end end)
        end
    end

    -- 检查正常UI背景
    if isfile(NORMAL_FILE) then
        local ok, data = pcall(function() return readfile(NORMAL_FILE) end)
        if ok and data and #data > 1000 then
            needNormalBg = false
        else
            pcall(function() if delfile then delfile(NORMAL_FILE) end end)
        end
    end

    totalSteps = loadingToDl + animToDl + (needBGM and 1 or 0) + (needNormalBg and 1 or 0)
    completedSteps = 0

    print("[统计] 需要下载: 加载动画" .. loadingToDl .. "帧 + UI背景" .. animToDl .. "帧 + BGM(" .. tostring(needBGM) .. ") + 正常背景(" .. tostring(needNormalBg) .. ")")
    print("[统计] 总计: " .. totalSteps .. " 个文件")

    if totalSteps == 0 then
        updateProgress(1, 1, "全部资源已缓存，无需下载", "可以直接使用主脚本了！")
        tipLabel.Text = "所有资源已就绪，关闭此窗口即可"
        tipLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        return
    end

    -- ============================================================
    -- 下载加载动画帧（batch=3 并发）
    -- ============================================================
    print("[下载] 开始下载加载动画 " .. loadingToDl .. " 帧...")
    local downloaded = 0
    local dlFailed = 0
    local failedFrames = {}
    local BATCH_SIZE = 3
    local BATCH_DELAY = 0.3
    local dlStartTime = tick()

    -- 收集需要下载的帧号
    local toDownload = {}
    for i = 1, loadingTotal do
        local fname = string.format("loading_%04d.jpg", i)
        local fpath = LOADING_CACHE .. "/" .. fname
        if not isfile(fpath) then
            toDownload[#toDownload + 1] = i
        end
    end

    for batchStart = 1, #toDownload, BATCH_SIZE do
        local batchDone = 0
        local batchTotal = math.min(BATCH_SIZE, #toDownload - batchStart + 1)
        for b = 0, batchTotal - 1 do
            local idx = batchStart + b
            local frameNum = toDownload[idx]
            task.spawn(function()
                local fname = string.format("loading_%04d.jpg", frameNum)
                local fpath = LOADING_CACHE .. "/" .. fname
                local ok, size = downloadFile(LOADING_BASE .. fname, fpath, 5000)
                if ok then
                    downloaded = downloaded + 1
                    completedSteps = completedSteps + 1
                else
                    dlFailed = dlFailed + 1
                    failedFrames[#failedFrames + 1] = frameNum
                    completedSteps = completedSteps + 1
                end
                batchDone = batchDone + 1
            end)
        end
        -- 等待本批完成
        local waitStart = tick()
        while batchDone < batchTotal do
            task.wait(0.1)
            if (tick() - waitStart) > 30 then break end
        end
        -- 更新进度
        local elapsed = tick() - dlStartTime
        local speed = completedSteps / math.max(elapsed, 0.1)
        local remain = (totalSteps - completedSteps) / math.max(speed, 0.01)
        updateProgress(
            completedSteps, totalSteps,
            "下载加载动画帧 (" .. downloaded .. "/" .. loadingToDl .. ")",
            "失败: " .. dlFailed .. " | 已用时: " .. string.format("%.0f", elapsed) .. "s | 剩余约: " .. string.format("%.0f", remain) .. "s"
        )
        speedLabel.Text = string.format("速度: %.1f 文件/秒", speed)
        if batchStart + BATCH_SIZE <= #toDownload then
            task.wait(BATCH_DELAY)
        end
    end

    -- 重试失败的帧
    if dlFailed > 0 then
        print("[重试] 加载动画 " .. #failedFrames .. " 帧失败，开始重试...")
        local retryOk = 0
        local retryFail = 0
        for j = 1, #failedFrames do
            local frameNum = failedFrames[j]
            local fname = string.format("loading_%04d.jpg", frameNum)
            local fpath = LOADING_CACHE .. "/" .. fname
            local ok, size = downloadFile(LOADING_BASE .. fname, fpath, 5000)
            if ok then
                retryOk = retryOk + 1
            else
                retryFail = retryFail + 1
            end
            updateProgress(
                completedSteps, totalSteps,
                "重试加载动画帧 (" .. retryOk .. "/" .. #failedFrames .. ")",
                "仍失败: " .. retryFail
            )
            task.wait(0.3)
        end
        print("[重试] 完成 成功:" .. retryOk .. " 失败:" .. retryFail)
    end

    -- ============================================================
    -- 下载UI背景动画帧（batch=3 并发）
    -- ============================================================
    print("[下载] 开始下载UI背景动画 " .. animToDl .. " 帧...")
    local animDlOk = 0
    local animDlFail = 0
    local animFailedFrames = {}

    local animToDownload = {}
    for i = 1, animTotal do
        local fname = string.format("frame_%04d.jpg", i)
        local fpath = ANIM_CACHE .. "/" .. fname
        if not isfile(fpath) then
            animToDownload[#animToDownload + 1] = i
        end
    end

    for batchStart = 1, #animToDownload, BATCH_SIZE do
        local batchDone = 0
        local batchTotal = math.min(BATCH_SIZE, #animToDownload - batchStart + 1)
        for b = 0, batchTotal - 1 do
            local idx = batchStart + b
            local frameNum = animToDownload[idx]
            task.spawn(function()
                local fname = string.format("frame_%04d.jpg", frameNum)
                local fpath = ANIM_CACHE .. "/" .. fname
                local ok, size = downloadFile(ANIM_BASE .. fname, fpath, 1000)
                if ok then
                    animDlOk = animDlOk + 1
                    completedSteps = completedSteps + 1
                else
                    animDlFail = animDlFail + 1
                    animFailedFrames[#animFailedFrames + 1] = frameNum
                    completedSteps = completedSteps + 1
                end
                batchDone = batchDone + 1
            end)
        end
        local waitStart = tick()
        while batchDone < batchTotal do
            task.wait(0.1)
            if (tick() - waitStart) > 30 then break end
        end
        local elapsed = tick() - dlStartTime
        local speed = completedSteps / math.max(elapsed, 0.1)
        local remain = (totalSteps - completedSteps) / math.max(speed, 0.01)
        updateProgress(
            completedSteps, totalSteps,
            "下载UI背景动画帧 (" .. animDlOk .. "/" .. animToDl .. ")",
            "失败: " .. animDlFail .. " | 已用时: " .. string.format("%.0f", elapsed) .. "s | 剩余约: " .. string.format("%.0f", remain) .. "s"
        )
        speedLabel.Text = string.format("速度: %.1f 文件/秒", speed)
        if batchStart + BATCH_SIZE <= #animToDownload then
            task.wait(BATCH_DELAY)
        end
    end

    -- 重试UI背景失败帧
    if animDlFail > 0 then
        print("[重试] UI背景动画 " .. #animFailedFrames .. " 帧失败，开始重试...")
        local retryOk = 0
        local retryFail = 0
        for j = 1, #animFailedFrames do
            local frameNum = animFailedFrames[j]
            local fname = string.format("frame_%04d.jpg", frameNum)
            local fpath = ANIM_CACHE .. "/" .. fname
            local ok, size = downloadFile(ANIM_BASE .. fname, fpath, 1000)
            if ok then
                retryOk = retryOk + 1
            else
                retryFail = retryFail + 1
            end
            task.wait(0.3)
        end
        print("[重试] UI背景完成 成功:" .. retryOk .. " 失败:" .. retryFail)
    end

    -- ============================================================
    -- 下载BGM
    -- ============================================================
    if needBGM then
        print("[下载] 正在下载BGM...")
        updateProgress(completedSteps, totalSteps, "正在下载BGM...", "loading_bgm.mp3")
        local ok, size = downloadFile(LOADING_BASE .. "loading_bgm.mp3", BGM_FILE, 10000)
        if ok then
            completedSteps = completedSteps + 1
            print("[下载] BGM下载成功 (" .. size .. " 字节)")
        else
            print("[下载] BGM下载失败")
            completedSteps = completedSteps + 1
        end
    end

    -- ============================================================
    -- 下载正常UI背景图
    -- ============================================================
    if needNormalBg then
        print("[下载] 正在下载正常UI背景...")
        updateProgress(completedSteps, totalSteps, "正在下载正常UI背景...", "bg.jpg")
        local ok, size = downloadFile(NORMAL_URL, NORMAL_FILE, 1000)
        if ok then
            completedSteps = completedSteps + 1
            print("[下载] 正常UI背景下载成功 (" .. size .. " 字节)")
        else
            print("[下载] 正常UI背景下载失败")
            completedSteps = completedSteps + 1
        end
    end

    -- ============================================================
    -- 完成
    -- ============================================================
    local totalTime = tick() - dlStartTime
    updateProgress(totalSteps, totalSteps, "下载完成！", string.format("总用时: %.0f 秒", totalTime))
    speedLabel.Text = "所有资源已缓存到本地"
    tipLabel.Text = "现在可以关闭此窗口并使用主脚本了！"
    tipLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    percentLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    barFill.BackgroundColor3 = Color3.fromRGB(100, 255, 100)

    -- 最终统计
    local finalLoading = 0
    for i = 1, loadingTotal do
        if isfile(LOADING_CACHE .. "/" .. string.format("loading_%04d.jpg", i)) then
            finalLoading = finalLoading + 1
        end
    end
    local finalAnim = 0
    for i = 1, animTotal do
        if isfile(ANIM_CACHE .. "/" .. string.format("frame_%04d.jpg", i)) then
            finalAnim = finalAnim + 1
        end
    end

    print("============================================")
    print("   下载完成！")
    print("   加载动画帧: " .. finalLoading .. "/" .. loadingTotal)
    print("   UI背景动画帧: " .. finalAnim .. "/" .. animTotal)
    print("   BGM: " .. tostring(isfile(BGM_FILE)))
    print("   正常UI背景: " .. tostring(isfile(NORMAL_FILE)))
    print("   总用时: " .. string.format("%.1f", totalTime) .. " 秒")
    print("============================================")
    print("现在可以使用主脚本了！")

    -- 10秒后自动关闭UI
    task.delay(10, function()
        if screenGui and screenGui.Parent then
            screenGui:Destroy()
        end
    end)
end)
