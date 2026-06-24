local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for server to create Remotes before requiring anything
ReplicatedStorage:WaitForChild("Remotes", 15)

local Remotes      = require(ReplicatedStorage:WaitForChild("Shared").net.Remotes)
local FormatNumber = require(ReplicatedStorage:WaitForChild("Shared").utils.FormatNumber)

-- Build ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HUD"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

-- Top bar background
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(0, 340, 0, 64)
topBar.Position = UDim2.new(0.5, -170, 0, 12)
topBar.BackgroundColor3 = Color3.fromRGB(10, 8, 18)
topBar.BorderSizePixel = 0
topBar.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 14)
corner.Parent = topBar

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(180, 130, 255)
stroke.Thickness = 1.5
stroke.Parent = topBar

-- Chip icon label
local chipIcon = Instance.new("TextLabel")
chipIcon.Size = UDim2.new(0, 36, 1, 0)
chipIcon.Position = UDim2.new(0, 10, 0, 0)
chipIcon.BackgroundTransparency = 1
chipIcon.Text = "🪙"
chipIcon.TextScaled = true
chipIcon.Font = Enum.Font.GothamBold
chipIcon.Parent = topBar

-- Chip count
local chipsLabel = Instance.new("TextLabel")
chipsLabel.Name = "ChipsLabel"
chipsLabel.Size = UDim2.new(0, 160, 1, 0)
chipsLabel.Position = UDim2.new(0, 50, 0, 0)
chipsLabel.BackgroundTransparency = 1
chipsLabel.Text = "0 chips"
chipsLabel.TextColor3 = Color3.fromRGB(255, 220, 80)
chipsLabel.TextScaled = true
chipsLabel.Font = Enum.Font.GothamBold
chipsLabel.TextXAlignment = Enum.TextXAlignment.Left
chipsLabel.Parent = topBar

-- Income rate
local incomeLabel = Instance.new("TextLabel")
incomeLabel.Name = "IncomeLabel"
incomeLabel.Size = UDim2.new(0, 120, 0, 22)
incomeLabel.Position = UDim2.new(0, 50, 1, -26)
incomeLabel.BackgroundTransparency = 1
incomeLabel.Text = "+0/s"
incomeLabel.TextColor3 = Color3.fromRGB(120, 255, 150)
incomeLabel.TextScaled = true
incomeLabel.Font = Enum.Font.Gotham
incomeLabel.TextXAlignment = Enum.TextXAlignment.Left
incomeLabel.Parent = topBar

-- Animate chip label on update (quick scale pulse)
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
	incomeLabel.Text = "+" .. FormatNumber.format(perSecond) .. "/s"
end)
