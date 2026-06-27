local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

ReplicatedStorage:WaitForChild("Remotes", 15)

local Shared       = ReplicatedStorage:WaitForChild("Shared")
local Remotes      = require(Shared.net.Remotes)
local FormatNumber = require(Shared.utils.FormatNumber)
local UIStyle      = require(Shared.utils.UIStyle)

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local BG_DARK    = UIStyle.PANEL_TOP
local BG_PANEL   = UIStyle.PANEL_BOTTOM
local GOLD       = UIStyle.GOLD
local GOLD_LIGHT = UIStyle.GOLD_LIGHT
local NEON_GREEN = UIStyle.NEON_GREEN

local status = { canClaim = false, secondsRemaining = 0, streak = 0, nextReward = 0 }

local function formatCountdown(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	local h = math.floor(seconds / 3600)
	local m = math.floor((seconds % 3600) / 60)
	local s = seconds % 60
	return string.format("%02d:%02d:%02d", h, m, s)
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DailyReward"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Toggle button
local toggleBtn = UIStyle.toggleButton({
	name = "DailyToggle",
	text = "Daily",
	accent = UIStyle.BTN_GREEN,
	position = UDim2.new(0, 16, 1, -72),
})
toggleBtn.Parent = screenGui

-- Ready badge
local readyBadge = Instance.new("TextLabel")
readyBadge.Name = "ReadyBadge"
readyBadge.Size = UDim2.new(0, 20, 0, 20)
readyBadge.Position = UDim2.new(1, -6, 0, -6)
readyBadge.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
readyBadge.Text = "!"
readyBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
readyBadge.TextScaled = true
readyBadge.Font = Enum.Font.GothamBold
readyBadge.Visible = false
readyBadge.Parent = toggleBtn
do
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = readyBadge
end

-- Panel
local PANEL_CLOSED_POS = UDim2.new(0, 16, 1, 20)
local PANEL_OPEN_POS   = UDim2.new(0, 16, 1, -370)

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.new(0, 320, 0, 340)
panel.Position = PANEL_CLOSED_POS
panel.BackgroundColor3 = BG_DARK
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = screenGui
do
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 18); c.Parent = panel
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(UIStyle.PANEL_TOP, UIStyle.PANEL_BOTTOM)
	g.Rotation = 180
	g.Parent = panel
	local s = Instance.new("UIStroke"); s.Color = UIStyle.ACCENT; s.Thickness = 1.5; s.Parent = panel
end

-- Header bar (solid)
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 50)
header.Position = UDim2.new(0, 0, 0, 0)
header.BackgroundColor3 = UIStyle.HEADER
header.BorderSizePixel = 0
header.ZIndex = 2
header.Parent = panel
do
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 18); c.Parent = header
	local cover = Instance.new("Frame")
	cover.Size = UDim2.new(1, 0, 0, 18)
	cover.Position = UDim2.new(0, 0, 1, -18)
	cover.BackgroundColor3 = UIStyle.HEADER
	cover.BorderSizePixel = 0
	cover.ZIndex = 2
	cover.Parent = header
end
local headerTitle = Instance.new("TextLabel")
headerTitle.Size = UDim2.new(1, -52, 1, 0)
headerTitle.Position = UDim2.new(0, 26, 0, 0)
headerTitle.BackgroundTransparency = 1
headerTitle.Text = "DAILY REWARD"
headerTitle.TextColor3 = UIStyle.TEXT
headerTitle.TextScaled = true
UIStyle.maxText(headerTitle, 24)
headerTitle.Font = Enum.Font.GothamBlack
headerTitle.ZIndex = 3
headerTitle.Parent = header

-- Close button (drawn X)
local closeBtn = UIStyle.closeButton(28)
closeBtn.Position = UDim2.new(1, -38, 0.5, -14)
closeBtn.ZIndex = 5
closeBtn.Parent = header

-- Streak dots row
local dotsRow = Instance.new("Frame")
dotsRow.Name = "StreakDots"
dotsRow.Size = UDim2.new(1, -24, 0, 36)
dotsRow.Position = UDim2.new(0, 12, 0, 60)
dotsRow.BackgroundTransparency = 1
dotsRow.Parent = panel
local dotsLayout = Instance.new("UIListLayout")
dotsLayout.FillDirection = Enum.FillDirection.Horizontal
dotsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
dotsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
dotsLayout.Padding = UDim.new(0, 8)
dotsLayout.Parent = dotsRow

local streakDots = {}
for i = 1, 7 do
	local dot = Instance.new("Frame")
	dot.Size = UDim2.new(0, 24, 0, 24)
	dot.BackgroundColor3 = Color3.fromRGB(70, 82, 78)
	dot.BorderSizePixel = 0
	dot.Parent = dotsRow
	local dc = Instance.new("UICorner"); dc.CornerRadius = UDim.new(1, 0); dc.Parent = dot
	local ds = Instance.new("UIStroke"); ds.Color = Color3.fromRGB(110, 122, 116); ds.Thickness = 1.5; ds.Parent = dot
	local dl = Instance.new("TextLabel")
	dl.Size = UDim2.new(1, 0, 1, 0)
	dl.BackgroundTransparency = 1
	dl.Text = tostring(i)
	dl.TextColor3 = UIStyle.TEXT_DIM
	dl.TextScaled = true
	dl.Font = Enum.Font.GothamBold
	dl.Parent = dot
	UIStyle.maxText(dl, 13)
	table.insert(streakDots, {frame = dot, stroke = ds, label = dl})
end

-- Caption above the reward amount
local rewardCaption = Instance.new("TextLabel")
rewardCaption.Size = UDim2.new(1, -24, 0, 16)
rewardCaption.Position = UDim2.new(0, 12, 0, 104)
rewardCaption.BackgroundTransparency = 1
rewardCaption.Text = "TODAY'S REWARD"
rewardCaption.TextColor3 = UIStyle.TEXT_DIM
rewardCaption.Font = Enum.Font.GothamBold
rewardCaption.TextSize = 13
rewardCaption.Parent = panel

-- Reward row (drawn chip icon + text, no emoji)
local rewardHolder = Instance.new("Frame")
rewardHolder.Name = "RewardHolder"
rewardHolder.Size = UDim2.new(1, -24, 0, 60)
rewardHolder.Position = UDim2.new(0, 12, 0, 126)
rewardHolder.BackgroundTransparency = 1
rewardHolder.Parent = panel
do
	local rh = Instance.new("UIListLayout")
	rh.FillDirection = Enum.FillDirection.Horizontal
	rh.HorizontalAlignment = Enum.HorizontalAlignment.Center
	rh.VerticalAlignment = Enum.VerticalAlignment.Center
	rh.Padding = UDim.new(0, 8)
	rh.Parent = rewardHolder
end

local rewardChip = UIStyle.chipIcon(24)
rewardChip.LayoutOrder = 1
rewardChip.Parent = rewardHolder

local rewardLabel = Instance.new("TextLabel")
rewardLabel.Size = UDim2.new(0, 240, 1, 0)
rewardLabel.AutomaticSize = Enum.AutomaticSize.X
rewardLabel.LayoutOrder = 2
rewardLabel.BackgroundTransparency = 1
rewardLabel.Text = "0 chips"
rewardLabel.TextColor3 = GOLD
rewardLabel.TextSize = 26
rewardLabel.Font = Enum.Font.GothamBlack
rewardLabel.TextXAlignment = Enum.TextXAlignment.Left
rewardLabel.Parent = rewardHolder

-- "Day X of 7" progress line, fills the space between the reward and the button.
local dayLabel = Instance.new("TextLabel")
dayLabel.Name = "DayLabel"
dayLabel.Size = UDim2.new(1, -24, 0, 22)
dayLabel.Position = UDim2.new(0, 12, 0, 200)
dayLabel.BackgroundTransparency = 1
dayLabel.Text = "Day 1 of 7"
dayLabel.TextColor3 = UIStyle.ACCENT_LT
dayLabel.Font = Enum.Font.GothamMedium
dayLabel.TextSize = 16
dayLabel.Parent = panel

-- Claim button
local claimBtn = Instance.new("TextButton")
claimBtn.Name = "ClaimButton"
claimBtn.Size = UDim2.new(1, -24, 0, 56)
claimBtn.Position = UDim2.new(0, 12, 1, -68)
local CLAIM_READY    = UIStyle.BTN_GREEN_DK
local CLAIM_READY_LT = UIStyle.BTN_GREEN_LT
local CLAIM_WAIT     = Color3.fromRGB(70, 82, 78)

claimBtn.BackgroundColor3 = CLAIM_READY
claimBtn.Text = "Claim Reward"
claimBtn.TextColor3 = UIStyle.TEXT
claimBtn.TextScaled = true
claimBtn.Font = Enum.Font.GothamBold
claimBtn.BorderSizePixel = 0
claimBtn.AutoButtonColor = false
claimBtn.Parent = panel
UIStyle.maxText(claimBtn, 20)
local claimGradient = Instance.new("UIGradient")
claimGradient.Color = ColorSequence.new(CLAIM_READY, CLAIM_READY_LT)
claimGradient.Rotation = 90
claimGradient.Parent = claimBtn
do
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 12); c.Parent = claimBtn
	local pad = Instance.new("UIPadding"); pad.PaddingTop = UDim.new(0, 10); pad.PaddingBottom = UDim.new(0, 10); pad.Parent = claimBtn
end

-- Static stroke when claimable (no pulsing).
local claimStroke = Instance.new("UIStroke")
claimStroke.Color = UIStyle.BTN_GREEN_LT
claimStroke.Thickness = 0
claimStroke.Parent = claimBtn

local function updateStreakDots()
	for i, d in streakDots do
		if i < status.streak then
			d.frame.BackgroundColor3 = GOLD
			d.stroke.Color = GOLD_LIGHT
			d.stroke.Thickness = 2
			d.label.TextColor3 = UIStyle.BG_DARK
		elseif i == status.streak and not status.canClaim then
			d.frame.BackgroundColor3 = GOLD
			d.stroke.Color = GOLD_LIGHT
			d.stroke.Thickness = 2
			d.label.TextColor3 = UIStyle.BG_DARK
		elseif i == (status.streak + 1) or (status.canClaim and i == status.streak + 1) then
			d.frame.BackgroundColor3 = UIStyle.BG_DARK
			d.stroke.Color = NEON_GREEN
			d.stroke.Thickness = 2.5
			d.label.TextColor3 = NEON_GREEN
		else
			d.frame.BackgroundColor3 = Color3.fromRGB(70, 82, 78)
			d.stroke.Color = Color3.fromRGB(110, 122, 116)
			d.stroke.Thickness = 1.5
			d.label.TextColor3 = UIStyle.TEXT_DIM
		end
	end
end

local function refreshUI()
	rewardLabel.Text = FormatNumber.format(status.nextReward) .. " chips"
	readyBadge.Visible = status.canClaim
	updateStreakDots()

	local day = status.canClaim and math.min(status.streak + 1, 7) or math.max(status.streak, 1)
	dayLabel.Text = "Day " .. day .. " of 7"

	if status.canClaim then
		claimBtn.Text = "Claim Reward"
		claimGradient.Color = ColorSequence.new(CLAIM_READY, CLAIM_READY_LT)
		claimStroke.Thickness = 2
		claimBtn.Active = true
		claimBtn.AutoButtonColor = false
	else
		claimBtn.Text = "Next: " .. formatCountdown(status.secondsRemaining)
		claimGradient.Color = ColorSequence.new(CLAIM_WAIT, CLAIM_WAIT)
		claimStroke.Thickness = 0
		claimBtn.Active = false
		claimBtn.AutoButtonColor = false
	end
end

local panelOpen = false

local function openPanel()
	panel.Position = PANEL_CLOSED_POS
	panel.Visible = true
	TweenService:Create(panel, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = PANEL_OPEN_POS}):Play()
end
local function closePanel()
	TweenService:Create(panel, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = PANEL_CLOSED_POS}):Play()
	task.delay(0.2, function() panel.Visible = false end)
end

toggleBtn.MouseButton1Click:Connect(function()
	panelOpen = not panelOpen
	if panelOpen then openPanel() else closePanel() end
end)

closeBtn.MouseButton1Click:Connect(function()
	panelOpen = false
	closePanel()
end)

claimBtn.MouseButton1Click:Connect(function()
	if not status.canClaim then return end
	claimBtn.Active = false
	claimBtn.AutoButtonColor = false
	claimBtn.Text = "Claiming..."
	claimStroke.Thickness = 0
	local ok, result = pcall(function()
		return Remotes.RequestDailyReward:InvokeServer()
	end)
	if ok and result and result.status then
		status = result.status
		if result.success then
			rewardLabel.Text = "Claimed! " .. FormatNumber.format(result.reward)
		end
	end
	refreshUI()
end)

Remotes.DailyRewardStatus.OnClientEvent:Connect(function(newStatus)
	status = newStatus
	refreshUI()
end)

task.spawn(function()
	while true do
		task.wait(1)
		if not status.canClaim and status.secondsRemaining > 0 then
			status.secondsRemaining -= 1
			if status.secondsRemaining <= 0 then
				status.canClaim = true
			end
			refreshUI()
		end
	end
end)

task.spawn(function()
	local ok, pulled = pcall(function()
		return Remotes.RequestDailyStatus:InvokeServer()
	end)
	if ok and pulled then
		status = pulled
		refreshUI()
	end
end)

refreshUI()
