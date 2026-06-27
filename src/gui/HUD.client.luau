local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

ReplicatedStorage:WaitForChild("Remotes", 15)

local Shared       = ReplicatedStorage:WaitForChild("Shared")
local Remotes      = require(Shared.net.Remotes)
local FormatNumber = require(Shared.utils.FormatNumber)
local UIStyle      = require(Shared.utils.UIStyle)

local BG_DARK     = UIStyle.BG_DARK
local GOLD        = UIStyle.GOLD
local GOLD_LIGHT  = UIStyle.GOLD_LIGHT
local NEON_GREEN  = UIStyle.NEON_GREEN
local DIVIDER_COL = Color3.fromRGB(120, 132, 122)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HUD"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(0, 460, 0, 72)
topBar.Position = UDim2.new(0.5, -230, 0, 14)
topBar.BackgroundColor3 = BG_DARK
topBar.BorderSizePixel = 0
topBar.Parent = screenGui
UIStyle.corner(topBar, 18)
UIStyle.gradient(topBar, BG_DARK, Color3.fromRGB(72, 86, 80), 135)

local barStroke = UIStyle.stroke(topBar, GOLD, 2)

local chipIcon = UIStyle.chipIcon(28)
chipIcon.AnchorPoint = Vector2.new(0, 0.5)
chipIcon.Position = UDim2.new(0, 14, 0.5, 0)
chipIcon.ZIndex = 3
chipIcon.Parent = topBar

local chipsLabel = Instance.new("TextLabel")
chipsLabel.Name = "ChipsLabel"
chipsLabel.Size = UDim2.new(0, 220, 1, 0)
chipsLabel.Position = UDim2.new(0, 52, 0, 0)
chipsLabel.BackgroundTransparency = 1
chipsLabel.Text = "0"
chipsLabel.TextColor3 = GOLD
chipsLabel.TextSize = 26
chipsLabel.Font = Enum.Font.GothamBlack
chipsLabel.TextXAlignment = Enum.TextXAlignment.Left
chipsLabel.TextYAlignment = Enum.TextYAlignment.Center
chipsLabel.ZIndex = 3
chipsLabel.Parent = topBar

local divider = Instance.new("Frame")
divider.Name = "Divider"
divider.Size = UDim2.new(0, 1, 0, 36)
divider.Position = UDim2.new(0, 296, 0.5, -18)
divider.BackgroundColor3 = DIVIDER_COL
divider.BorderSizePixel = 0
divider.ZIndex = 3
divider.Parent = topBar

local incomeLabel = Instance.new("TextLabel")
incomeLabel.Name = "IncomeLabel"
incomeLabel.Size = UDim2.new(0, 148, 1, 0)
incomeLabel.Position = UDim2.new(0, 306, 0, 0)
incomeLabel.BackgroundTransparency = 1
incomeLabel.Text = "+0/s"
incomeLabel.TextColor3 = NEON_GREEN
incomeLabel.TextSize = 20
incomeLabel.Font = Enum.Font.GothamBold
incomeLabel.TextXAlignment = Enum.TextXAlignment.Left
incomeLabel.TextYAlignment = Enum.TextYAlignment.Center
incomeLabel.ZIndex = 3
incomeLabel.Parent = topBar

-- Subtle hover glow on the bar (hover only — not a constant pulse).
topBar.MouseEnter:Connect(function()
	TweenService:Create(barStroke,
		TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Thickness = 3, Color = GOLD_LIGHT }
	):Play()
end)
topBar.MouseLeave:Connect(function()
	TweenService:Create(barStroke,
		TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Thickness = 2, Color = GOLD }
	):Play()
end)

Remotes.ChipsUpdated.OnClientEvent:Connect(function(total: number)
	chipsLabel.Text = FormatNumber.format(total)
end)

Remotes.IncomeRateUpdated.OnClientEvent:Connect(function(perSecond: number)
	incomeLabel.Text = "+" .. FormatNumber.format(perSecond) .. "/s"
end)
