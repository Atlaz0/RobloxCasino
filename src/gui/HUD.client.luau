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
local DIVIDER_COL = Color3.fromRGB(60, 40, 90)

local prevChips: number = 0

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
topBar.ClipsDescendants = true
topBar.Parent = screenGui
UIStyle.corner(topBar, 18)

UIStyle.gradient(topBar, BG_DARK, Color3.fromRGB(28, 16, 48), 135)

local barStroke = UIStyle.stroke(topBar, GOLD, 2)

local shimmer = Instance.new("Frame")
shimmer.Name = "Shimmer"
shimmer.Size = UDim2.new(0, 80, 1, 0)
shimmer.Position = UDim2.new(-0.2, 0, 0, 0)
shimmer.BackgroundColor3 = Color3.fromRGB(255, 235, 130)
shimmer.BackgroundTransparency = 0.88
shimmer.BorderSizePixel = 0
shimmer.ZIndex = 2
shimmer.Parent = topBar

local shimmerGrad = Instance.new("UIGradient")
shimmerGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 235, 130)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 235, 130)),
})
shimmerGrad.Rotation = 15
shimmerGrad.Parent = shimmer

local function loopShimmer()
	while shimmer and shimmer.Parent do
		shimmer.Position = UDim2.new(-0.2, 0, 0, 0)
		TweenService:Create(shimmer,
			TweenInfo.new(2.4, Enum.EasingStyle.Linear, Enum.EasingDirection.In),
			{ Position = UDim2.new(1.1, 0, 0, 0) }
		):Play()
		task.wait(5.2)
	end
end
task.spawn(loopShimmer)

local chipIcon = UIStyle.chipIcon(28)
chipIcon.AnchorPoint = Vector2.new(0, 0.5)
chipIcon.Position = UDim2.new(0, 14, 0.5, 0)
chipIcon.ZIndex = 3
chipIcon.Parent = topBar

local chipsLabelContainer = Instance.new("Frame")
chipsLabelContainer.Name = "ChipsContainer"
chipsLabelContainer.Size = UDim2.new(0, 220, 1, 0)
chipsLabelContainer.Position = UDim2.new(0, 52, 0, 0)
chipsLabelContainer.BackgroundTransparency = 1
chipsLabelContainer.ZIndex = 3
chipsLabelContainer.Parent = topBar

local chipsScale = Instance.new("UIScale")
chipsScale.Scale = 1
chipsScale.Parent = chipsLabelContainer

local chipsLabel = Instance.new("TextLabel")
chipsLabel.Name = "ChipsLabel"
chipsLabel.Size = UDim2.new(1, 0, 1, 0)
chipsLabel.Position = UDim2.new(0, 0, 0, 0)
chipsLabel.BackgroundTransparency = 1
chipsLabel.Text = "0"
chipsLabel.TextColor3 = GOLD
chipsLabel.TextSize = 26
chipsLabel.Font = Enum.Font.GothamBlack
chipsLabel.TextXAlignment = Enum.TextXAlignment.Left
chipsLabel.TextYAlignment = Enum.TextYAlignment.Center
chipsLabel.ZIndex = 3
chipsLabel.Parent = chipsLabelContainer

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

local incomeShadow = Instance.new("TextLabel")
incomeShadow.Name = "IncomeShadow"
incomeShadow.Size = UDim2.new(0, 148, 1, 0)
incomeShadow.Position = UDim2.new(0, 307, 0, 1)
incomeShadow.BackgroundTransparency = 1
incomeShadow.Text = "+0/s"
incomeShadow.TextColor3 = Color3.fromRGB(20, 80, 40)
incomeShadow.TextTransparency = 0.4
incomeShadow.TextSize = 20
incomeShadow.Font = Enum.Font.GothamBold
incomeShadow.TextXAlignment = Enum.TextXAlignment.Left
incomeShadow.TextYAlignment = Enum.TextYAlignment.Center
incomeShadow.ZIndex = 2
incomeShadow.Parent = topBar

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

local activePopup: TextLabel? = nil

local function showPopup(amount: number)
	if activePopup then
		activePopup:Destroy()
		activePopup = nil
	end

	local popup = Instance.new("TextLabel")
	popup.Name = "ChipPopup"
	popup.Size = UDim2.new(0, 160, 0, 32)
	popup.AnchorPoint = Vector2.new(0.5, 1)
	popup.Position = UDim2.new(0.5, 0, 0, 14)
	popup.BackgroundTransparency = 1
	popup.Text = "+" .. FormatNumber.format(amount)
	popup.TextColor3 = NEON_GREEN
	popup.TextSize = 22
	popup.Font = Enum.Font.GothamBold
	popup.TextTransparency = 0
	popup.ZIndex = 10
	popup.Parent = screenGui

	activePopup = popup

	local tweenUp = TweenService:Create(popup,
		TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Position = UDim2.new(0.5, 0, 0, -22),
			TextTransparency = 1,
		}
	)
	tweenUp:Play()
	tweenUp.Completed:Connect(function()
		if activePopup == popup then
			activePopup = nil
		end
		popup:Destroy()
	end)
end

local function bounceChips()
	TweenService:Create(chipsScale,
		TweenInfo.new(0.08, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Scale = 1.18 }
	):Play()
	TweenService:Create(chipsLabel,
		TweenInfo.new(0.08, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ TextColor3 = GOLD_LIGHT }
	):Play()

	task.delay(0.08, function()
		TweenService:Create(chipsScale,
			TweenInfo.new(0.09, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Scale = 1 }
		):Play()
		TweenService:Create(chipsLabel,
			TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ TextColor3 = GOLD }
		):Play()
	end)
end

Remotes.ChipsUpdated.OnClientEvent:Connect(function(total: number)
	local gained = total - prevChips
	chipsLabel.Text = FormatNumber.format(total)
	bounceChips()
	if gained > 0 then
		showPopup(gained)
	end
	prevChips = total
end)

Remotes.IncomeRateUpdated.OnClientEvent:Connect(function(perSecond: number)
	local txt = "+" .. FormatNumber.format(perSecond) .. "/s"
	incomeLabel.Text = txt
	incomeShadow.Text = txt
end)
