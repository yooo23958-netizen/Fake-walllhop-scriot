-- =============================================
-- WALLHOP V4.0 - UI OVERHAUL
-- Original: Nova  |  UI Rewrite: Enhanced
-- =============================================
-- Controls:
-- (-) Minus = ON/OFF
-- LCtrl    = Infinite Jump Mode
-- RAlt     = Cam Flick Mode
-- Drag header = Move GUI
-- =============================================

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local Workspace        = game:GetService("Workspace")

local player      = Players.LocalPlayer
local enabled     = false
local currentMode = 1  -- 1 = Inf Jump  |  2 = Cam Flick

-- =============================================
-- SETTINGS
-- =============================================
local Settings = {
    Mode1_Cooldown = 0.12,
    Mode2_Cooldown = 0.3,
    FlickAngle     = 45,
    MaxChain       = 5,
    SnapDuration   = 0.04,
    JumpPower      = 61,
    WallDistance   = 4.2,
    SoundFeedback  = true,
    VisualFeedback = true,
}

local function loadSettings()
    local ok, data = pcall(function() return getgenv().WallhopSettings end)
    if ok and data then
        for k, v in pairs(data) do
            if Settings[k] ~= nil then Settings[k] = v end
        end
    end
end

local function saveSettings()
    getgenv().WallhopSettings = Settings
end
loadSettings()

-- =============================================
-- PALETTE
-- =============================================
local C = {
    BG         = Color3.fromRGB(9,  9,  14),
    Panel      = Color3.fromRGB(15, 15, 22),
    Surface    = Color3.fromRGB(22, 22, 32),
    Surface2   = Color3.fromRGB(30, 30, 44),
    Border     = Color3.fromRGB(45, 45, 68),
    Accent     = Color3.fromRGB(99, 175, 255),
    AccentDim  = Color3.fromRGB(45, 80,  160),
    Green      = Color3.fromRGB(68, 240, 138),
    GreenDim   = Color3.fromRGB(30, 110,  65),
    Red        = Color3.fromRGB(245, 72,  72),
    RedDim     = Color3.fromRGB(110, 30,  30),
    Yellow     = Color3.fromRGB(255, 210, 55),
    TextMain   = Color3.fromRGB(228, 228, 242),
    TextSub    = Color3.fromRGB(130, 130, 158),
    TextDim    = Color3.fromRGB(58,  58,  85),
    Mode1      = Color3.fromRGB(68,  240, 138),
    Mode1Dim   = Color3.fromRGB(30,  110,  65),
    Mode2      = Color3.fromRGB(155, 112, 255),
    Mode2Dim   = Color3.fromRGB(75,  45,  150),
}

-- =============================================
-- HELPERS
-- =============================================
local function tw(obj, props, t, style, dir)
    TweenService:Create(obj,
        TweenInfo.new(t or 0.2,
            style or Enum.EasingStyle.Quad,
            dir   or Enum.EasingDirection.Out),
        props):Play()
end

local function corner(parent, r)
    local c = Instance.new("UICorner", parent)
    c.CornerRadius = UDim.new(0, r or 8)
    return c
end

local function stroke(parent, col, thick)
    local s = Instance.new("UIStroke", parent)
    s.Color              = col   or C.Border
    s.Thickness          = thick or 1.2
    s.ApplyStrokeMode    = Enum.ApplyStrokeMode.Border
    return s
end

-- =============================================
-- CLEANUP OLD GUI
-- =============================================
for _, host in ipairs({player.PlayerGui, game:GetService("CoreGui")}) do
    local old = host:FindFirstChild("WallhopGUI")
    if old then old:Destroy() end
end

-- =============================================
-- SCREEN GUI
-- =============================================
local sg = Instance.new("ScreenGui")
sg.Name           = "WallhopGUI"
sg.ResetOnSpawn   = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.DisplayOrder   = 100
pcall(function() sg.Parent = game:GetService("CoreGui") end)
if not sg.Parent then sg.Parent = player:WaitForChild("PlayerGui") end

-- =============================================
-- MAIN FRAME
-- =============================================
local MAIN_W, MAIN_H = 214, 92

local frame = Instance.new("Frame")
frame.Name                  = "Main"
frame.Size                  = UDim2.fromOffset(MAIN_W, MAIN_H)
frame.Position              = UDim2.new(0.5, -MAIN_W/2, 0, 18)
frame.BackgroundColor3      = C.BG
frame.BackgroundTransparency = 0.04
frame.BorderSizePixel       = 0
frame.ClipsDescendants      = true
frame.Parent                = sg
corner(frame, 14)
local mainStroke = stroke(frame, C.Border, 1.3)

-- Subtle diagonal BG gradient
local bgGrad = Instance.new("UIGradient", frame)
bgGrad.Color    = ColorSequence.new(Color3.fromRGB(13,13,20), Color3.fromRGB(8,8,12))
bgGrad.Rotation = 135

-- Shimmer top line (reactive to mode/enabled)
local shimmer = Instance.new("Frame", frame)
shimmer.Size              = UDim2.new(0.65, 0, 0, 2)
shimmer.Position          = UDim2.new(0.175, 0, 0, 0)
shimmer.BackgroundColor3  = C.Accent
shimmer.BorderSizePixel   = 0
shimmer.ZIndex            = 5
corner(shimmer, 2)
local shimGrad = Instance.new("UIGradient", shimmer)
shimGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.new(0,0,0)),
    ColorSequenceKeypoint.new(0.5, C.Accent),
    ColorSequenceKeypoint.new(1,   Color3.new(0,0,0)),
})
shimGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0,   1),
    NumberSequenceKeypoint.new(0.25, 0),
    NumberSequenceKeypoint.new(0.75, 0),
    NumberSequenceKeypoint.new(1,   1),
})

-- =============================================
-- HEADER
-- =============================================
local header = Instance.new("Frame", frame)
header.Size                  = UDim2.new(1, 0, 0, 36)
header.BackgroundTransparency = 1

-- ⚙ Gear (Settings)
local gearBtn = Instance.new("TextButton", header)
gearBtn.Size                  = UDim2.fromOffset(30, 30)
gearBtn.Position              = UDim2.new(0, 5, 0.5, -15)
gearBtn.BackgroundColor3      = C.Surface
gearBtn.BackgroundTransparency = 0.35
gearBtn.Text                  = "⚙"
gearBtn.TextColor3            = C.TextSub
gearBtn.TextSize              = 15
gearBtn.Font                  = Enum.Font.GothamBold
gearBtn.AutoButtonColor       = false
gearBtn.ZIndex                = 2
corner(gearBtn, 8)

-- Title
local titleLbl = Instance.new("TextLabel", header)
titleLbl.Size                  = UDim2.new(0, 80, 1, 0)
titleLbl.Position              = UDim2.new(0, 42, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text                  = "WALLHOP"
titleLbl.TextColor3            = C.TextMain
titleLbl.TextSize              = 13
titleLbl.Font                  = Enum.Font.GothamBold
titleLbl.TextXAlignment        = Enum.TextXAlignment.Left
titleLbl.ZIndex                = 2

-- Version badge
local verFrame = Instance.new("Frame", header)
verFrame.Size             = UDim2.fromOffset(34, 16)
verFrame.Position         = UDim2.new(0, 122, 0.5, -8)
verFrame.BackgroundColor3 = C.AccentDim
verFrame.BackgroundTransparency = 0.25
verFrame.ZIndex           = 2
corner(verFrame, 4)
local verLbl = Instance.new("TextLabel", verFrame)
verLbl.Size               = UDim2.fromScale(1,1)
verLbl.BackgroundTransparency = 1
verLbl.Text               = "v4.0"
verLbl.TextColor3         = C.Accent
verLbl.TextSize           = 9
verLbl.Font               = Enum.Font.GothamBold
verLbl.ZIndex             = 3

-- "by Nova" sub-label
local byLbl = Instance.new("TextLabel", header)
byLbl.Size               = UDim2.fromOffset(55, 16)
byLbl.Position           = UDim2.new(1, -60, 0.5, -8)
byLbl.BackgroundTransparency = 1
byLbl.Text               = "by Nova"
byLbl.TextColor3         = C.TextDim
byLbl.TextSize           = 9
byLbl.Font               = Enum.Font.Gotham
byLbl.TextXAlignment     = Enum.TextXAlignment.Right
byLbl.ZIndex             = 2

-- ─── TOGGLE SWITCH (pill with sliding knob) ───
local pillW, pillH = 60, 26
local toggleOuter = Instance.new("Frame", header)
toggleOuter.Size             = UDim2.fromOffset(pillW, pillH)
toggleOuter.Position         = UDim2.new(1, -(pillW + 6), 0.5, -pillH/2)
toggleOuter.BackgroundColor3 = C.Surface
toggleOuter.BorderSizePixel  = 0
toggleOuter.ZIndex           = 3
corner(toggleOuter, 13)
stroke(toggleOuter, C.Border, 1)

local knob = Instance.new("Frame", toggleOuter)
knob.Size            = UDim2.fromOffset(20, 20)
knob.Position        = UDim2.new(0, 3, 0.5, -10)
knob.BackgroundColor3 = C.Red
knob.BorderSizePixel = 0
knob.ZIndex          = 4
corner(knob, 10)

local pillLbl = Instance.new("TextLabel", toggleOuter)
pillLbl.Size               = UDim2.new(1, -26, 1, 0)
pillLbl.Position           = UDim2.new(0, 26, 0, 0)
pillLbl.BackgroundTransparency = 1
pillLbl.Text               = "OFF"
pillLbl.TextColor3         = C.Red
pillLbl.TextSize           = 10
pillLbl.Font               = Enum.Font.GothamBold
pillLbl.ZIndex             = 4

local toggleBtn = Instance.new("TextButton", toggleOuter)
toggleBtn.Size               = UDim2.fromScale(1,1)
toggleBtn.BackgroundTransparency = 1
toggleBtn.Text               = ""
toggleBtn.ZIndex             = 5

-- =============================================
-- MODE TABS
-- =============================================
local tabBar = Instance.new("Frame", frame)
tabBar.Size             = UDim2.new(1, -14, 0, 28)
tabBar.Position         = UDim2.new(0, 7, 0, 39)
tabBar.BackgroundColor3 = C.Surface
tabBar.BorderSizePixel  = 0
tabBar.ZIndex           = 2
corner(tabBar, 8)

local tabSlider = Instance.new("Frame", tabBar)
tabSlider.Size             = UDim2.new(0.5, -3, 1, -4)
tabSlider.Position         = UDim2.new(0, 2, 0, 2)
tabSlider.BackgroundColor3 = C.Mode1
tabSlider.BackgroundTransparency = 0.65
tabSlider.ZIndex           = 2
corner(tabSlider, 6)

local tab1 = Instance.new("TextButton", tabBar)
tab1.Size               = UDim2.new(0.5, -3, 1, -4)
tab1.Position           = UDim2.new(0, 2, 0, 2)
tab1.BackgroundTransparency = 1
tab1.Text               = "⬆  Inf Jump"
tab1.TextColor3         = C.Mode1
tab1.TextSize           = 11
tab1.Font               = Enum.Font.GothamBold
tab1.ZIndex             = 3

local tab2 = Instance.new("TextButton", tabBar)
tab2.Size               = UDim2.new(0.5, -3, 1, -4)
tab2.Position           = UDim2.new(0.5, 1, 0, 2)
tab2.BackgroundTransparency = 1
tab2.Text               = "↪  Cam Flick"
tab2.TextColor3         = C.TextDim
tab2.TextSize           = 11
tab2.Font               = Enum.Font.GothamBold
tab2.ZIndex             = 3

-- =============================================
-- BOTTOM ROW (hint + chain counter)
-- =============================================
local bottomRow = Instance.new("Frame", frame)
bottomRow.Size               = UDim2.new(1, -14, 0, 18)
bottomRow.Position           = UDim2.new(0, 7, 0, 72)
bottomRow.BackgroundTransparency = 1
bottomRow.ZIndex             = 2

local hintLbl = Instance.new("TextLabel", bottomRow)
hintLbl.Size               = UDim2.new(0.7, 0, 1, 0)
hintLbl.BackgroundTransparency = 1
hintLbl.Text               = "(-) toggle  •  Ctrl / Alt = mode"
hintLbl.TextColor3         = C.TextDim
hintLbl.TextSize           = 8.5
hintLbl.Font               = Enum.Font.Gotham
hintLbl.TextXAlignment     = Enum.TextXAlignment.Left
hintLbl.ZIndex             = 2

local chainLbl = Instance.new("TextLabel", bottomRow)
chainLbl.Size               = UDim2.new(0.3, 0, 1, 0)
chainLbl.Position           = UDim2.new(0.7, 0, 0, 0)
chainLbl.BackgroundTransparency = 1
chainLbl.Text               = ""
chainLbl.TextColor3         = C.Yellow
chainLbl.TextSize           = 10
chainLbl.Font               = Enum.Font.GothamBold
chainLbl.TextXAlignment     = Enum.TextXAlignment.Right
chainLbl.ZIndex             = 2

-- =============================================
-- SETTINGS PANEL
-- =============================================
local SET_W = 232

local settingsFrame = Instance.new("Frame", sg)
settingsFrame.Name             = "SettingsPanel"
settingsFrame.Size             = UDim2.fromOffset(SET_W, 10)
settingsFrame.Position         = UDim2.new(0.5, -(SET_W/2), 0.5, -130)
settingsFrame.BackgroundColor3 = C.BG
settingsFrame.BorderSizePixel  = 0
settingsFrame.Visible          = false
settingsFrame.ZIndex           = 20
corner(settingsFrame, 12)
stroke(settingsFrame, C.Border, 1.4)

-- Panel BG gradient
local panelGrad = Instance.new("UIGradient", settingsFrame)
panelGrad.Color    = ColorSequence.new(Color3.fromRGB(13,13,20), Color3.fromRGB(9,9,14))
panelGrad.Rotation = 135

-- Panel header band
local panelHeader = Instance.new("Frame", settingsFrame)
panelHeader.Size             = UDim2.new(1, 0, 0, 38)
panelHeader.BackgroundColor3 = C.Surface
panelHeader.BorderSizePixel  = 0
panelHeader.ZIndex           = 21
corner(panelHeader, 12)
local headerFlat = Instance.new("Frame", panelHeader)
headerFlat.Size              = UDim2.new(1, 0, 0.5, 0)
headerFlat.Position          = UDim2.new(0, 0, 0.5, 0)
headerFlat.BackgroundColor3  = C.Surface
headerFlat.BorderSizePixel   = 0
headerFlat.ZIndex            = 21

local panelTitleLbl = Instance.new("TextLabel", panelHeader)
panelTitleLbl.Size               = UDim2.new(1, -60, 1, 0)
panelTitleLbl.Position           = UDim2.new(0, 14, 0, 0)
panelTitleLbl.BackgroundTransparency = 1
panelTitleLbl.Text               = "⚙  Settings"
panelTitleLbl.TextColor3         = C.TextMain
panelTitleLbl.TextSize           = 13
panelTitleLbl.Font               = Enum.Font.GothamBold
panelTitleLbl.TextXAlignment     = Enum.TextXAlignment.Left
panelTitleLbl.ZIndex             = 22

local closeBtn = Instance.new("TextButton", panelHeader)
closeBtn.Size                  = UDim2.fromOffset(28, 28)
closeBtn.Position              = UDim2.new(1, -34, 0.5, -14)
closeBtn.BackgroundColor3      = C.RedDim
closeBtn.BackgroundTransparency = 0.4
closeBtn.Text                  = "✕"
closeBtn.TextColor3            = C.Red
closeBtn.TextSize              = 12
closeBtn.Font                  = Enum.Font.GothamBold
closeBtn.AutoButtonColor       = false
closeBtn.ZIndex                = 22
corner(closeBtn, 6)

-- ── Slider row builder ──────────────────────
local rowY = 44

local function makeSliderRow(label, key, minV, maxV, step)
    step = step or 1
    local H = 40

    local row = Instance.new("Frame", settingsFrame)
    row.Size             = UDim2.new(1, -16, 0, H)
    row.Position         = UDim2.new(0, 8, 0, rowY)
    row.BackgroundColor3 = C.Surface
    row.BackgroundTransparency = 0.45
    row.BorderSizePixel  = 0
    row.ZIndex           = 21
    corner(row, 7)

    local lbl = Instance.new("TextLabel", row)
    lbl.Size               = UDim2.new(0.6, 0, 0, 16)
    lbl.Position           = UDim2.new(0, 9, 0, 5)
    lbl.BackgroundTransparency = 1
    lbl.Text               = label
    lbl.TextColor3         = C.TextSub
    lbl.TextSize           = 10
    lbl.Font               = Enum.Font.Gotham
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.ZIndex             = 22

    local valLbl = Instance.new("TextLabel", row)
    valLbl.Size               = UDim2.new(0.35, 0, 0, 16)
    valLbl.Position           = UDim2.new(0.65, -6, 0, 5)
    valLbl.BackgroundTransparency = 1
    valLbl.Text               = tostring(Settings[key])
    valLbl.TextColor3         = C.Accent
    valLbl.TextSize           = 10
    valLbl.Font               = Enum.Font.GothamBold
    valLbl.TextXAlignment     = Enum.TextXAlignment.Right
    valLbl.ZIndex             = 22

    -- Track
    local track = Instance.new("Frame", row)
    track.Size             = UDim2.new(1, -18, 0, 5)
    track.Position         = UDim2.new(0, 9, 0, 28)
    track.BackgroundColor3 = C.Surface2
    track.BorderSizePixel  = 0
    track.ZIndex           = 22
    corner(track, 3)

    local ratio0 = (Settings[key] - minV) / (maxV - minV)
    local fill = Instance.new("Frame", track)
    fill.Size             = UDim2.new(math.clamp(ratio0, 0, 1), 0, 1, 0)
    fill.BackgroundColor3 = C.Accent
    fill.BorderSizePixel  = 0
    fill.ZIndex           = 23
    corner(fill, 3)

    -- Invisible drag button over track
    local trackBtn = Instance.new("TextButton", track)
    trackBtn.Size               = UDim2.fromScale(1, 1)
    trackBtn.BackgroundTransparency = 1
    trackBtn.Text               = ""
    trackBtn.ZIndex             = 25

    local dragging = false
    trackBtn.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or
           inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or
           inp.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if not dragging then return end
        if inp.UserInputType ~= Enum.UserInputType.MouseMovement and
           inp.UserInputType ~= Enum.UserInputType.Touch then return end
        local abs   = track.AbsolutePosition
        local sz    = track.AbsoluteSize
        local rel   = math.clamp((inp.Position.X - abs.X) / sz.X, 0, 1)
        local raw   = minV + rel * (maxV - minV)
        local snapped = math.floor(raw / step + 0.5) * step
        snapped = math.clamp(math.floor(snapped * 1000) / 1000, minV, maxV)
        Settings[key] = snapped
        local r = (snapped - minV) / (maxV - minV)
        fill.Size = UDim2.new(math.clamp(r, 0, 1), 0, 1, 0)
        valLbl.Text = tostring(snapped)
        saveSettings()
    end)

    rowY = rowY + H + 5
    return row
end

makeSliderRow("Inf Jump Cooldown",   "Mode1_Cooldown", 0.05, 0.5,  0.01)
makeSliderRow("Cam Flick Cooldown",  "Mode2_Cooldown", 0.1,  1.0,  0.05)
makeSliderRow("Flick Angle",         "FlickAngle",     15,   90,   5)
makeSliderRow("Max Chain",           "MaxChain",       1,    10,   1)
makeSliderRow("Jump Power",          "JumpPower",      45,   85,   1)

-- ── Toggle buttons (Sound / Visual) ─────────
local function makeToggleRow(label, key, xOff)
    local btn = Instance.new("TextButton", settingsFrame)
    btn.Size               = UDim2.new(0, 98, 0, 26)
    btn.Position           = UDim2.new(0, xOff, 0, rowY + 2)
    btn.BackgroundColor3   = Settings[key] and C.GreenDim or C.RedDim
    btn.BackgroundTransparency = 0.15
    btn.Text               = (Settings[key] and "✓ " or "✕ ") .. label
    btn.TextColor3         = Settings[key] and C.Green or C.Red
    btn.TextSize           = 10
    btn.Font               = Enum.Font.GothamBold
    btn.AutoButtonColor    = false
    btn.ZIndex             = 21
    corner(btn, 6)
    btn.MouseButton1Click:Connect(function()
        Settings[key]     = not Settings[key]
        btn.BackgroundColor3 = Settings[key] and C.GreenDim or C.RedDim
        btn.Text          = (Settings[key] and "✓ " or "✕ ") .. label
        btn.TextColor3    = Settings[key] and C.Green or C.Red
        saveSettings()
    end)
    btn.MouseEnter:Connect(function() tw(btn, {BackgroundTransparency = 0}, 0.1) end)
    btn.MouseLeave:Connect(function() tw(btn, {BackgroundTransparency = 0.15}, 0.15) end)
    return btn
end

makeToggleRow("Sound",  "SoundFeedback",  8)
makeToggleRow("Visual", "VisualFeedback", 116)

-- Reset
local resetBtn = Instance.new("TextButton", settingsFrame)
resetBtn.Size               = UDim2.new(1, -16, 0, 26)
resetBtn.Position           = UDim2.new(0, 8, 0, rowY + 36)
resetBtn.BackgroundColor3   = C.Surface
resetBtn.BackgroundTransparency = 0.2
resetBtn.Text               = "↺   Reset to Defaults"
resetBtn.TextColor3         = C.Yellow
resetBtn.TextSize           = 11
resetBtn.Font               = Enum.Font.GothamBold
resetBtn.AutoButtonColor    = false
resetBtn.ZIndex             = 21
corner(resetBtn, 6)

resetBtn.MouseEnter:Connect(function() tw(resetBtn, {BackgroundTransparency = 0}, 0.1) end)
resetBtn.MouseLeave:Connect(function() tw(resetBtn, {BackgroundTransparency = 0.2}, 0.15) end)

resetBtn.MouseButton1Click:Connect(function()
    local def = {
        Mode1_Cooldown = 0.12, Mode2_Cooldown = 0.3,
        FlickAngle = 45, MaxChain = 5, SnapDu
