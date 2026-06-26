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

<<<<<<< HEAD
local gui = Instance.new("ScreenGui")
gui.Name = "HUD"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

-- ── Chip counter (top center) ──────────────────────────────────────────────

local pill = Instance.new("Frame")
pill.Name = "ChipPill"
pill.AnchorPoint = Vector2.new(0.5, 0)
pill.Position = UDim2.new(0.5, 0, 0, 14)
pill.Size = UDim2.new(0, 220, 0, 56)
pill.BackgroundColor3 = Color3.fromRGB(12, 9, 22)
pill.BorderSizePixel = 0
pill.Parent = gui

local pillCorner = Instance.new("UICorner")
pillCorner.CornerRadius = UDim.new(1, 0)
pillCorner.Parent = pill

local pillStroke = Instance.new("UIStroke")
pillStroke.Color = Color3.fromRGB(200, 160, 60)
pillStroke.Thickness = 1.5
pillStroke.Transparency = 0.3
pillStroke.Parent = pill

-- Gold chip dot
local dot = Instance.new("Frame")
dot.Size = UDim2.new(0, 28, 0, 28)
dot.Position = UDim2.new(0, 14, 0.5, -14)
dot.BackgroundColor3 = Color3.fromRGB(255, 195, 40)
dot.BorderSizePixel = 0
dot.Parent = pill
local dotCorner = Instance.new("UICorner")
dotCorner.CornerRadius = UDim.new(1, 0)
dotCorner.Parent = dot

-- Inner ring on dot
local dotInner = Instance.new("Frame")
dotInner.Size = UDim2.new(0, 16, 0, 16)
dotInner.Position = UDim2.new(0.5, -8, 0.5, -8)
dotInner.BackgroundColor3 = Color3.fromRGB(220, 155, 20)
dotInner.BorderSizePixel = 0
dotInner.Parent = dot
local diCorner = Instance.new("UICorner")
diCorner.CornerRadius = UDim.new(1, 0)
diCorner.Parent = dotInner

-- Chip amount
local chipsLabel = Instance.new("TextLabel")
chipsLabel.Name = "ChipsLabel"
chipsLabel.Size = UDim2.new(1, -60, 0, 30)
chipsLabel.Position = UDim2.new(0, 52, 0, 6)
chipsLabel.BackgroundTransparency = 1
chipsLabel.Text = "100"
chipsLabel.TextColor3 = Color3.fromRGB(255, 235, 130)
=======
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
>>>>>>> 19b3fbb93fc4996a7899dc319aa85775a4c31a66
chipsLabel.Font = Enum.Font.GothamBold
chipsLabel.TextSize = 22
chipsLabel.TextXAlignment = Enum.TextXAlignment.Left
<<<<<<< HEAD
chipsLabel.Parent = pill
=======
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
>>>>>>> 19b3fbb93fc4996a7899dc319aa85775a4c31a66

local incomeLabel = Instance.new("TextLabel")
incomeLabel.Name = "IncomeLabel"
<<<<<<< HEAD
incomeLabel.Size = UDim2.new(1, -60, 0, 18)
incomeLabel.Position = UDim2.new(0, 52, 0, 34)
incomeLabel.BackgroundTransparency = 1
incomeLabel.Text = "+0 / sec"
incomeLabel.TextColor3 = Color3.fromRGB(100, 220, 120)
incomeLabel.Font = Enum.Font.Gotham
incomeLabel.TextSize = 13
incomeLabel.TextXAlignment = Enum.TextXAlignment.Left
incomeLabel.Parent = pill

-- ── Pulse animation on chip update ────────────────────────────────────────
=======
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
>>>>>>> 19b3fbb93fc4996a7899dc319aa85775a4c31a66

local function pulseChips()
	TweenService:Create(dot,
		TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Size = UDim2.new(0, 34, 0, 34), Position = UDim2.new(0, 11, 0.5, -17) }
	):Play()
	task.delay(0.12, function()
		TweenService:Create(dot,
			TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = UDim2.new(0, 28, 0, 28), Position = UDim2.new(0, 14, 0.5, -14) }
		):Play()
	end)
end

Remotes.ChipsUpdated.OnClientEvent:Connect(function(total: number)
	chipsLabel.Text = FormatNumber.format(total)
	pulseChips()
end)

Remotes.IncomeRateUpdated.OnClientEvent:Connect(function(perSecond: number)
<<<<<<< HEAD
	if perSecond > 0 then
		incomeLabel.Text = "+" .. FormatNumber.format(perSecond) .. " / sec"
	else
		incomeLabel.Text = "no income yet"
		incomeLabel.TextColor3 = Color3.fromRGB(140, 140, 140)
	end
=======
	incomeLabel.Text = "+" .. FormatNumber.format(perSecond) .. " / sec"
>>>>>>> 19b3fbb93fc4996a7899dc319aa85775a4c31a66
end)
