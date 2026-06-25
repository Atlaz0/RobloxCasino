local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

ReplicatedStorage:WaitForChild("Remotes", 15)

local Remotes      = require(ReplicatedStorage:WaitForChild("Shared").net.Remotes)
local FormatNumber = require(ReplicatedStorage:WaitForChild("Shared").utils.FormatNumber)

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
chipsLabel.Font = Enum.Font.GothamBold
chipsLabel.TextSize = 22
chipsLabel.TextXAlignment = Enum.TextXAlignment.Left
chipsLabel.Parent = pill

-- Income rate
local incomeLabel = Instance.new("TextLabel")
incomeLabel.Name = "IncomeLabel"
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
	if perSecond > 0 then
		incomeLabel.Text = "+" .. FormatNumber.format(perSecond) .. " / sec"
	else
		incomeLabel.Text = "no income yet"
		incomeLabel.TextColor3 = Color3.fromRGB(140, 140, 140)
	end
end)
