-- =============================================
-- WALLHOP V4.0 - PREMIUM UI OVERHAUL
-- Optimized & Refactored by Gemini
-- =============================================
-- Controls:
-- (-) Minus = ON/OFF Toggle
-- LCtrl = Switch to Infinite Jump Mode
-- RAlt = Switch to Cam Flick Mode
-- =============================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local enabled = false
local currentMode = 1  -- 1 = Inf Jump, 2 = Cam Flick

-- Default Settings
local Settings = {
    Mode1_Cooldown = 0.12,
    Mode2_Cooldown = 0.3,
    FlickAngle = 45,
    MaxChain = 5,
    SnapDuration = 0.04,
    JumpPower = 61,
    WallDistance = 4.2,
    SoundFeedback = true,
    VisualFeedback = true,
}

-- Persistent settings (save between sessions)
local function loadSettings()
    local success, data = pcall(function() return getgenv().WallhopSettings end)
    if success and data then
        for k, v in pairs(data) do
            if Settings[k] ~= nil then Settings[k] = v end
        end
    end
end

local function saveSettings()
    getgenv().WallhopSettings = Settings
end
loadSettings()

-- Upgraded V4 UI Color Palette
local C = {
    BG = Color3.fromRGB(11, 11, 16),
    Panel = Color3.fromRGB(16, 16, 24),
    Surface = Color3.fromRGB(24, 24, 37),
    Border = Color3.fromRGB(36, 36, 54),
    Accent = Color3.fromRGB(0, 162, 255),
    Green = Color3.fromRGB(46, 213, 115),
    Red = Color3.fromRGB(255, 71, 87),
    Yellow = Color3.fromRGB(255, 165, 2),
    TextMain = Color3.fromRGB(241, 242, 246),
    TextSub = Color3.fromRGB(164, 176, 190),
    TextDim = Color3.fromRGB(87, 101, 116),
    Mode1 = Color3.fromRGB(46, 213, 115),
    Mode2 = Color3.fromRGB(112, 111, 211),
}

local mode2_jumpChain = 0

-- Cleanup old GUI elements safely
for _, gui in ipairs({player.PlayerGui, game:GetService("CoreGui")}) do
    local old = gui:FindFirstChild("WallhopGUI")
    if old then old:Destroy() end
end

-- Create ScreenGui
local sg = Instance.new("ScreenGui")
sg.Name = "WallhopGUI"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() sg.Parent = game:GetService("CoreGui") end)
if not sg.Parent then sg.Parent = player:WaitForChild("PlayerGui") end

-- Main Window Frame
local frame = Instance.new("Frame")
frame.Name = "Main"
frame.Size = UDim2.new(0, 240, 0, 115)
frame.Position = UDim2.new(0.5, -120, 0.15, 0)
frame.BackgroundColor3 = C.BG
frame.BackgroundTransparency = 0.05
frame.BorderSizePixel = 0
frame.ClipsDescendants = true
frame.Parent = sg
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

local outerStroke = Instance.new("UIStroke", frame)
outerStroke.Thickness = 1.5
outerStroke.Color = C.Border

-- REACTIVE SHIMMER LINE EFFECT (Changes color dynamically with mode)
local shimmerLine = Instance.new("Frame")
shimmerLine.Name = "ShimmerLine"
shimmerLine.Size = UDim2.new(1, 0, 0, 2)
shimmerLine.Position = UDim2.new(0, 0, 0, 0)
shimmerLine.BackgroundColor3 = C.Accent
shimmerLine.BorderSizePixel = 0
shimmerLine.ZIndex = 5
shimmerLine.Parent = frame

local function updateShimmer()
    local targetColor = enabled and (currentMode == 1 and C.Mode1 or C.Mode2) or C.Accent
    TweenService:Create(shimmerLine, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundColor3 = targetColor
    }):Play()
end

-- Header Panel
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 36)
header.BackgroundTransparency = 1
header.Parent = frame

local titleLbl = Instance.new("TextLabel")
titleLbl.Size = UDim2.new(0.5, 0, 1, 0)
titleLbl.Position = UDim2.new(0, 12, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "Wallhop V4.0"
titleLbl.TextColor3 = C.TextMain
titleLbl.TextSize = 14
titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.Parent = header

-- Settings Gear Icon
local gearBtn = Instance.new("TextButton")
gearBtn.Size = UDim2.new(0, 28, 0, 28)
gearBtn.Position = UDim2.new(1, -95, 0.5, -14)
gearBtn.BackgroundTransparency = 1
gearBtn.Text = "⚙"
gearBtn.TextColor3 = C.TextSub
gearBtn.TextSize = 16
gearBtn.Font = Enum.Font.GothamBold
gearBtn.Parent = header

-- REAL TOGGLE SWITCH WITH SLIDING KNOB ANIMATION
local switchBG = Instance.new("TextButton")
switchBG.Name = "ToggleSwitch"
switchBG.Size = UDim2.new(0, 44, 0, 22)
switchBG.Position = UDim2.new(1, -56, 0.5, -11)
switchBG.BackgroundColor3 = C.Surface
switchBG.Text = ""
switchBG.AutoButtonColor = false
switchBG.Parent = header
Instance.new("UICorner", switchBG).CornerRadius = UDim.new(1, 0)

local switchStroke = Instance.new("UIStroke", switchBG)
switchStroke.Thickness = 1
switchStroke.Color = C.Border

local switchKnob = Instance.new("Frame")
switchKnob.Size = UDim2.new(0, 16, 0, 16)
switchKnob.Position = UDim2.new(0, 3, 0.5, -8)
switchKnob.BackgroundColor3 = C.TextSub
switchKnob.BorderSizePixel = 0
switchKnob.Parent = switchBG
Instance.new("UICorner", switchKnob).CornerRadius = UDim.new(1, 0)

-- Mode Navigation Tabs
local tabRow = Instance.new("Frame")
tabRow.Size = UDim2.new(1, -24, 0, 30)
tabRow.Position = UDim2.new(0.5, 0, 0, 42)
tabRow.AnchorPoint = Vector2.new(0.5, 0)
tabRow.BackgroundColor3 = C.Surface
tabRow.BorderSizePixel = 0
tabRow.Parent = frame
Instance.new("UICorner", tabRow).CornerRadius = UDim.new(0, 8)

local tabSlider = Instance.new("Frame")
tabSlider.Size = UDim2.new(0.5, -4, 1, -4)
tabSlider.Position = UDim2.new(0, 2, 0, 2)
tabSlider.BackgroundColor3 = C.Mode1
tabSlider.BackgroundTransparency = 0.8
tabSlider.ZIndex = 1
tabSlider.Parent = tabRow
Instance.new("UICorner", tabSlider).CornerRadius = UDim.new(0, 6)

local tab1 = Instance.new("TextButton")
tab1.Size = UDim2.new(0.5, -4, 1, -4)
tab1.Position = UDim2.new(0, 2, 0, 2)
tab1.BackgroundTransparency = 1
tab1.Text = "Inf Jump"
tab1.TextColor3 = C.Mode1
tab1.TextSize = 11
tab1.Font = Enum.Font.GothamBold
tab1.ZIndex = 2
tab1.Parent = tabRow

local tab2 = Instance.new("TextButton")
tab2.Size = UDim2.new(0.5, -4, 1, -4)
tab2.Position = UDim2.new(0.5, 2, 0, 2)
tab2.BackgroundTransparency = 1
tab2.Text = "Cam Flick"
tab2.TextColor3 = C.TextDim
tab2.TextSize = 11
tab2.Font = Enum.Font.GothamBold
tab2.ZIndex = 2
tab2.Parent = tabRow

-- Bottom Bar Context (Chains Counter Integration & Shortcuts)
local bottomBar = Instance.new("Frame")
bottomBar.Size = UDim2.new(1, 0, 0, 22)
bottomBar.Position = UDim2.new(0, 0, 1, -22)
bottomBar.BackgroundColor3 = C.Panel
bottomBar.BorderSizePixel = 0
bottomBar.Parent = frame

local keyHint = Instance.new("TextLabel")
keyHint.Size = UDim2.new(1, -24, 1, 0)
keyHint.Position = UDim2.new(0, 12, 0, 0)
keyHint.BackgroundTransparency = 1
keyHint.Text = "[-] Toggle  •  LCtrl / RAlt = Modes"
keyHint.TextColor3 = C.TextDim
keyHint.TextSize = 9
keyHint.Font = Enum.Font.Gotham
keyHint.TextXAlignment = Enum.TextXAlignment.Left
keyHint.Parent = bottomBar

-- INTEGRATED CHAIN COUNTER DISPLAY
local chainCounterLbl = Instance.new("TextLabel")
chainCounterLbl.Size = UDim2.new(0, 80, 1, 0)
chainCounterLbl.Position = UDim2.new(1, -12, 0, 0)
chainCounterLbl.AnchorPoint = Vector2.new(1, 0)
chainCounterLbl.BackgroundTransparency = 1
chainCounterLbl.Text = "Chain: 0"
chainCounterLbl.TextColor3 = C.TextDim
chainCounterLbl.TextSize = 10
chainCounterLbl.Font = Enum.Font.GothamBold
chainCounterLbl.TextXAlignment = Enum.TextXAlignment.Right
chainCounterLbl.Parent = bottomBar

-- HOVER EFFECTS FUNCTIONALITY
local function applyHoverEffect(button, targetColor, originalColor)
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.15), {TextColor3 = targetColor}):Play()
    end)
    button.MouseLeave:Connect(function()
        if (button == tab1 and currentMode ~= 1) or (button == tab2 and currentMode ~= 2) or (button == gearBtn) then
            TweenService:Create(button, TweenInfo.new(0.15), {TextColor3 = originalColor}):Play()
        end
    end)
end
applyHoverEffect(gearBtn, C.TextMain, C.TextSub)
applyHoverEffect(tab1, C.Mode1, C.TextDim)
applyHoverEffect(tab2, C.Mode2, C.TextDim)

-- TOAST NOTIFICATION GENERATOR (Slides up smoothly from screen center bottom)
local function showToast(title, message, duration)
    local toast = Instance.new("Frame")
    toast.Name = "Toast"
    toast.Size = UDim2.new(0, 220, 0, 42)
    toast.Position = UDim2.new(0.5, -110, 1, 50) -- Offscreen starting point
    toast.BackgroundColor3 = C.Panel
    toast.BorderSizePixel = 0
    toast.ZIndex = 20
    toast.Parent = sg
    Instance.new("UICorner", toast).CornerRadius = UDim.new(0, 8)
    
    local toastStroke = Instance.new("UIStroke", toast)
    toastStroke.Color = C.Border
    toastStroke.Thickness = 1.2

    local tTitle = Instance.new("TextLabel")
    tTitle.Size = UDim2.new(1, -20, 0, 18)
    tTitle.Position = UDim2.new(0, 10, 0, 4)
    tTitle.BackgroundTransparency = 1
    tTitle.Text = title
    tTitle.TextColor3 = C.Accent
    tTitle.TextSize = 11
    tTitle.Font = Enum.Font.GothamBold
    tTitle.TextXAlignment = Enum.TextXAlignment.Left
    tTitle.Parent = toast

    local tMsg = Instance.new("TextLabel")
    tMsg.Size = UDim2.new(1, -20, 0, 16)
    tMsg.Position = UDim2.new(0, 10, 0, 20)
    tMsg.BackgroundTransparency = 1
    tMsg.Text = message
    tMsg.TextColor3 = C.TextSub
    tMsg.TextSize = 10
    tMsg.Font = Enum.Font.Gotham
    tMsg.TextXAlignment = Enum.TextXAlignment.Left
    tMsg.Parent = toast

    -- Animation Chain
    TweenService:Create(toast, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -110, 0.88, 0)
    }):Play()

    task.delay(duration or 2, function()
        local collapse = TweenService:Create(toast, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(0.5, -110, 1, 50)
        })
        collapse:Play()
        collapse.Completed:Connect(function() toast:Destroy() end)
    end)
end

-- =============================================
-- SETTINGS PANEL WITH DRAGGABLE SLIDERS
-- =============================================
local settingsFrame = Instance.new("Frame")
settingsFrame.Size = UDim2.new(0, 240, 0, 290)
settingsFrame.Position = UDim2.new(0.5, -120, 0.5, -145)
settingsFrame.BackgroundColor3 = C.BG
settingsFrame.BorderSizePixel = 0
settingsFrame.Visible = false
settingsFrame.ZIndex = 10
settingsFrame.Parent = sg
Instance.new("UICorner", settingsFrame).CornerRadius = UDim.new(0, 12)

local settingsStroke = Instance.new("UIStroke", settingsFrame)
settingsStroke.Color = C.Border
settingsStroke.Thickness = 1.5

local settingsTitle = Instance.new("TextLabel")
settingsTitle.Size = UDim2.new(1, 0, 0, 36)
settingsTitle.BackgroundTransparency = 1
settingsTitle.Text = "Configuration Panel"
settingsTitle.TextColor3 = C.TextMain
settingsTitle.TextSize = 13
settingsTitle.Font = Enum.Font.GothamBold
settingsTitle.Parent = settingsFrame

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -34, 0, 4)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "✕"
closeBtn.TextColor3 = C.TextSub
closeBtn.TextSize = 14
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = settingsFrame
applyHoverEffect(closeBtn, C.Red, C.TextSub)

-- CLEAN DRAGGABLE SLIDER CONSTRUCTOR
local function createSliderSetting(name, configKey, yPos, minVal, maxVal, isInt)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, 0, 0, 16)
    label.Position = UDim2.new(0, 16, 0, yPos)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = C.TextSub
    label.TextSize = 10
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = settingsFrame

    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.new(0.3, 0, 0, 16)
    valLbl.Position = UDim2.new(0.7, -16, 0, yPos)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = tostring(Settings[configKey])
    valLbl.TextColor3 = C.Accent
    valLbl.TextSize = 11
    valLbl.Font = Enum.Font.GothamBold
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.Parent = settingsFrame

    local sliderBG = Instance.new("TextButton")
    sliderBG.Size = UDim2.new(1, -32, 0, 6)
    sliderBG.Position = UDim2.new(0, 16, 0, yPos + 18)
    sliderBG.BackgroundColor3 = C.Surface
    sliderBG.Text = ""
    sliderBG.AutoButtonColor = false
    sliderBG.Parent = settingsFrame
    Instance.new("UICorner", sliderBG).CornerRadius = UDim.new(1, 0)

    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new((Settings[configKey] - minVal) / (maxVal - minVal), 0, 1, 0)
    sliderFill.BackgroundColor3 = C.Accent
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderBG
    Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(1, 0)

    local function updateSlider(input)
        local relativeX = math.clamp((input.Position.X - sliderBG.AbsolutePosition.X) / sliderBG.AbsoluteSize.X, 0, 1)
        local value = minVal + (relativeX * (maxVal - minVal))
        if isInt then value = math.round(value) else value = math.floor(value * 100) / 100 end
        
        Settings[configKey] = value
        valLbl.Text = tostring(value)
        sliderFill.Size = UDim2.new(relativeX, 0, 1, 0)
        saveSettings()
    end

    local holding = false
    sliderBG.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            holding = true
            updateSlider(input)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if holding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateSlider(input)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            holding = false
        end
    end)
end

createSliderSetting("Flick Angle Limit", "FlickAngle", 46, 15, 90, true)
createSliderSetting("Cam Flick Cooldown", "Mode2_Cooldown", 86, 0.1, 1.0, false)
createSliderSetting("Maximum Chain Cap", "MaxChain", 126, 1, 10, true)
createSliderSetting("Snap Window Interval", "SnapDuration", 166, 0.01, 0.15, false)
createSliderSetting("Inf Jump Velocity Speed", "JumpPower", 206, 45, 85, true)

-- Toggle Options for Sound/Visuals Layout
local function createToggleRow(name, configKey, xPos, yPos)
    local tBtn = Instance.new("TextButton")
    tBtn.Size = UDim2.new(0.42, 0, 0, 26)
    tBtn.Position = UDim2.new(xPos, 0, 0, yPos)
    tBtn.BackgroundColor3 = Settings[configKey] and C.Surface or C.Panel
    tBtn.Text = name .. ": " .. (Settings[configKey] and "ON" or "OFF")
    tBtn.TextColor3 = Settings[configKey] and C.TextMain or C.TextDim
    tBtn.TextSize = 10
    tBtn.Font = Enum.Font.GothamBold
    tBtn.Parent = settingsFrame
    Instance.new("UICorner", tBtn).CornerRadius = UDim.new(0, 6)
    
    local stroke = Instance.new("UIStroke", tBtn)
    stroke.Thickness = 1
    stroke.Color = Settings[configKey] and C.Accent or C.Border

    tBtn.MouseButton1Click:Connect(function()
        Settings[configKey] = not Settings[configKey]
        tBtn.BackgroundColor3 = Settings[configKey] and C.Surface or C.Panel
        tBtn.Text = name .. ": " .. (Settings[configKey] and "ON" or "OFF")
        tBtn.TextColor3 = Settings[configKey] and C.TextMain or C.TextDim
        stroke.Color = Settings[configKey] and C.Accent or C.Border
        saveSettings()
    end)
end

createToggleRow("Snd Feedback", "SoundFeedback", 0.06, 252)
createToggleRow("Vfx Display", "VisualFeedback", 0.52, 252)

-- =============================================
-- INTERACTION & WORKFLOW LOGIC
-- =============================================
local function updateTabs()
    local color = (currentMode == 1) and C.Mode1 or C.Mode2
    TweenService:Create(tabSlider, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(currentMode == 1 and 0 or 0.5, 2, 0, 2),
        BackgroundColor3 = color,
    }):Play()
    tab1.TextColor3 = (currentMode == 1) and C.Mode1 or C.TextDim
    tab2.TextColor3 = (currentMode == 2) and C.Mode2 or C.TextDim
    updateShimmer()
end

local function applyToggledState(targetState)
    enabled = targetState
    local targetColor = enabled and (currentMode == 1 and C.Mode1 or C.Mode2) or C.TextSub
    local targetPos = enabled and UDim2.new(1, -21, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    local bgTargetColor = enabled and (currentMode == 1 and C.Mode1 or C.Mode2) or C.Surface

    TweenService:Create(switchKnob, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Position = targetPos, BackgroundColor3 = enabled and C.BG or C.TextSub}):Play()
    TweenService:Create(switchBG, TweenInfo.new(0.2), {BackgroundColor3 = bgTargetColor}):Play()
    TweenService:Create(outerStroke, TweenInfo.new(0.25), {Color = enabled and (currentMode == 1 and C.Mode1 or C.Mode2) or C.Border}):Play()
    
    updateShimmer()

    if enabled then
        showToast("System Engaged", "Wallhop running on " .. (currentMode == 1 and "Inf Jump" or "Cam Flick"), 1.5)
    else
        showToast("System Stopped", "Hooks detached successfully.", 1.2)
        mode2_jumpChain = 0
        chainCounterLbl.Text = "Chain: 0"
        chainCounterLbl.TextColor3 = C.TextDim
    end
end

-- Input Registration
UserInputService.InputBegan:Connect(function(input, processed)
    if input.KeyCode == Enum.KeyCode.Minus then
        applyToggledState(not enabled)
        return
    end
    if processed then return end

    if input.KeyCode == Enum.KeyCode.LeftControl then
        currentMode = 1
        updateTabs()
        applyToggledState(enabled)
        return
    end
    if input.KeyCode == Enum.KeyCode.RightAlt then
        currentMode = 2
        updateTabs()
        applyToggledState(enabled)
        return
    end
end)

switchBG.MouseButton1Click:Connect(function() applyToggledState(not enabled) end)
gearBtn.MouseButton1Click:Connect(function() settingsFrame.Visible = not settingsFrame.Visible end)
closeBtn.MouseButton1Click:Connect(function() settingsFrame.Visible = false end)

tab1.MouseButton1Click:Connect(function() currentMode = 1; updateTabs(); applyToggledState(enabled) end)
tab2.MouseButton1Click:Connect(function() currentMode = 2; updateTabs(); applyToggledState(enabled) end)

-- =============================================
-- FIXED COMPLETE MULTI-SURFACE DRAG SYSTEM
-- =============================================
local function configureDragSystem(targetWindow, structuralSurfaces)
    local dragging = false
    local startInputPos = nil
    local initialWindowPos = nil

    for _, structure in ipairs(structuralSurfaces) do
        structure.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                startInputPos = input.Position
                initialWindowPos = targetWindow.Position
                
                local releasedConn
                releasedConn = input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                        releasedConn:Disconnect()
                    end
                end)
            end
        end)
    end

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local displacement = input.Position - startInputPos
    
