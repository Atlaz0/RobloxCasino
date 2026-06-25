local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

ReplicatedStorage:WaitForChild("Remotes", 15)

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes      = require(Shared.net.Remotes)
local FormatNumber = require(Shared.utils.FormatNumber)

local PANEL_BG = Color3.fromRGB(18, 12, 28)
local ACCENT   = Color3.fromRGB(180, 130, 255)
local GOLD     = Color3.fromRGB(255, 220, 80)
local GREEN    = Color3.fromRGB(120, 255, 150)

local function corner(parent: Instance, radius: number)
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, radius); c.Parent = parent
end
local function stroke(parent: Instance, color: Color3, thickness: number)
	local s = Instance.new("UIStroke"); s.Color = color; s.Thickness = thickness; s.Parent = parent
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HUD"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

-- Chips bar (top center)
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(0, 320, 0, 56)
topBar.Position = UDim2.new(0.5, -160, 0, 12)
topBar.BackgroundColor3 = PANEL_BG
topBar.BorderSizePixel = 0
topBar.Parent = screenGui
corner(topBar, 14)
stroke(topBar, ACCENT, 1.5)

local chipIcon = Instance.new("TextLabel")
chipIcon.Size = UDim2.new(0, 34, 1, 0)
chipIcon.Position = UDim2.new(0, 12, 0, 0)
chipIcon.BackgroundTransparency = 1
chipIcon.Text = "🪙"
chipIcon.TextScaled = true
chipIcon.Font = Enum.Font.GothamBold
chipIcon.Parent = topBar

local chipsLabel = Instance.new("TextLabel")
chipsLabel.Name = "ChipsLabel"
chipsLabel.Size = UDim2.new(1, -60, 1, 0)
chipsLabel.Position = UDim2.new(0, 52, 0, 0)
chipsLabel.BackgroundTransparency = 1
chipsLabel.Text = "0 chips"
chipsLabel.TextColor3 = GOLD
chipsLabel.TextScaled = true
chipsLabel.Font = Enum.Font.GothamBold
chipsLabel.TextXAlignment = Enum.TextXAlignment.Left
chipsLabel.Parent = topBar
do
	local pad = Instance.new("UIPadding"); pad.PaddingTop = UDim.new(0, 12); pad.PaddingBottom = UDim.new(0, 12); pad.Parent = chipsLabel
end

-- Income pill (below the chips bar) — the overhauled "+/s" indicator.
local incomePill = Instance.new("Frame")
incomePill.Name = "IncomePill"
incomePill.Size = UDim2.new(0, 200, 0, 34)
incomePill.Position = UDim2.new(0.5, -100, 0, 74)
incomePill.BackgroundColor3 = PANEL_BG
incomePill.BorderSizePixel = 0
incomePill.Parent = screenGui
corner(incomePill, 12)
stroke(incomePill, GREEN, 1.5)

local incomeIcon = Instance.new("TextLabel")
incomeIcon.Size = UDim2.new(0, 26, 1, 0)
incomeIcon.Position = UDim2.new(0, 10, 0, 0)
incomeIcon.BackgroundTransparency = 1
incomeIcon.Text = "📈"
incomeIcon.TextScaled = true
incomeIcon.Font = Enum.Font.GothamBold
incomeIcon.Parent = incomePill
do
	local pad = Instance.new("UIPadding"); pad.PaddingTop = UDim.new(0, 7); pad.PaddingBottom = UDim.new(0, 7); pad.Parent = incomeIcon
end

local incomeLabel = Instance.new("TextLabel")
incomeLabel.Name = "IncomeLabel"
incomeLabel.Size = UDim2.new(1, -44, 1, 0)
incomeLabel.Position = UDim2.new(0, 40, 0, 0)
incomeLabel.BackgroundTransparency = 1
incomeLabel.Text = "+0 / sec"
incomeLabel.TextColor3 = GREEN
incomeLabel.TextScaled = true
incomeLabel.Font = Enum.Font.GothamBold
incomeLabel.TextXAlignment = Enum.TextXAlignment.Left
incomeLabel.Parent = incomePill
do
	local pad = Instance.new("UIPadding"); pad.PaddingTop = UDim.new(0, 7); pad.PaddingBottom = UDim.new(0, 7); pad.Parent = incomeLabel
end

local function pulseChips()
	local tween = TweenService:Create(chipsLabel,
		TweenInfo.new(0.08, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ TextTransparency = 0 })
	chipsLabel.TextTransparency = 0.4
	tween:Play()
end

Remotes.ChipsUpdated.OnClientEvent:Connect(function(total: number)
	chipsLabel.Text = FormatNumber.format(total) .. " chips"
	pulseChips()
end)

Remotes.IncomeRateUpdated.OnClientEvent:Connect(function(perSecond: number)
	incomeLabel.Text = "+" .. FormatNumber.format(perSecond) .. " / sec"
end)
