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
	accent = UIStyle.GOLD,
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
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, BG_DARK),
		ColorSequenceKeypoint.new(1, BG_PANEL),
	})
	g.Rotation = 180
	g.Parent = panel
	local s = Instance.new("UIStroke"); s.Color = GOLD; s.Thickness = 1.5; s.Parent = panel
end

-- Header bar
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 50)
header.Position = UDim2.new(0, 0, 0, 0)
header.BackgroundColor3 = Color3.fromRGB(200, 120, 15)
header.BorderSizePixel = 0
header.ZIndex = 2
header.Parent = panel
do
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 18); c.Parent = header
	local cover = Instance.new("Frame")
	cover.Size = UDim2.new(1, 0, 0, 18)
	cover.Position = UDim2.new(0, 0, 1, -18)
	cover.BackgroundColor3 = Color3.fromRGB(200, 120, 15)
	cover.BorderSizePixel = 0
	cover.ZIndex = 2
	cover.Parent = header
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 150, 20)),
		ColorSequenceKeypoint.new(1, GOLD),
	})
	g.Rotation = 0
	g.Parent = header
end
local headerTitle = Instance.new("TextLabel")
headerTitle.Size = UDim2.new(1, -52, 1, 0)
headerTitle.Position = UDim2.new(0, 26, 0, 0)
headerTitle.BackgroundTransparency = 1
headerTitle.Text = "DAILY REWARD"
headerTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
headerTitle.TextScaled = true
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
	dot.BackgroundColor3 = Color3.fromRGB(50, 40, 60)
	dot.BorderSizePixel = 0
	dot.Parent = dotsRow
	local dc = Instance.new("UICorner"); dc.CornerRadius = UDim.new(1, 0); dc.Parent = dot
	local ds = Instance.new("UIStroke"); ds.Color = Color3.fromRGB(80, 70, 90); ds.Thickness = 1.5; ds.Parent = dot
	local dl = Instance.new("TextLabel")
	dl.Size = UDim2.new(1, 0, 1, 0)
	dl.BackgroundTransparency = 1
	dl.Text = tostring(i)
	dl.TextColor3 = Color3.fromRGB(120, 110, 130)
	dl.TextScaled = true
	dl.Font = Enum.Font.GothamBold
	dl.Parent = dot
	table.insert(streakDots, {frame = dot, stroke = ds, label = dl})
end

-- Reward row (drawn chip icon + text, no emoji)
local rewardHolder = Instance.new("Frame")
rewardHolder.Name = "RewardHolder"
rewardHolder.Size = UDim2.new(1, -24, 0, 60)
rewardHolder.Position = UDim2.new(0, 12, 0, 110)
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

local rewardChip = UIStyle.chipIcon(30)
rewardChip.LayoutOrder = 1
rewardChip.Parent = rewardHolder

local rewardLabel = Instance.new("TextLabel")
rewardLabel.Size = UDim2.new(0, 240, 1, 0)
rewardLabel.AutomaticSize = Enum.AutomaticSize.X
rewardLabel.LayoutOrder = 2
rewardLabel.BackgroundTransparency = 1
rewardLabel.Text = "0 chips"
rewardLabel.TextColor3 = GOLD
rewardLabel.TextSize = 34
rewardLabel.Font = Enum.Font.GothamBlack
rewardLabel.TextXAlignment = Enum.TextXAlignment.Left
rewardLabel.Parent = rewardHolder

-- Claim button
local claimBtn = Instance.new("TextButton")
claimBtn.Name = "ClaimButton"
claimBtn.Size = UDim2.new(1, -24, 0, 56)
claimBtn.Position = UDim2.new(0, 12, 1, -68)
claimBtn.BackgroundColor3 = Color3.fromRGB(0, 160, 60)
claimBtn.Text = "✦  Claim Reward  ✦"
claimBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
claimBtn.TextScaled = true
claimBtn.Font = Enum.Font.GothamBold
claimBtn.BorderSizePixel = 0
claimBtn.AutoButtonColor = false
claimBtn.Parent = panel
local claimGradient = Instance.new("UIGradient")
claimGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 160, 60)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 220, 100)),
})
claimGradient.Rotation = 90
claimGradient.Parent = claimBtn
do
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 12); c.Parent = claimBtn
	local pad = Instance.new("UIPadding"); pad.PaddingTop = UDim.new(0, 10); pad.PaddingBottom = UDim.new(0, 10); pad.Parent = claimBtn
end

local claimStroke = Instance.new("UIStroke")
claimStroke.Color = NEON_GREEN
claimStroke.Thickness = 0
claimStroke.Parent = claimBtn

local pulseConn
local function startClaimPulse()
	if pulseConn then return end
	claimStroke.Thickness = 2
	pulseConn = task.spawn(function()
		while true do
			TweenService:Create(claimStroke, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Thickness = 3}):Play()
			task.wait(0.7)
			TweenService:Create(claimStroke, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Thickness = 1.5}):Play()
			task.wait(0.7)
		end
	end)
end
local function stopClaimPulse()
	if pulseConn then task.cancel(pulseConn); pulseConn = nil end
	claimStroke.Thickness = 0
end

local function updateStreakDots()
	for i, d in streakDots do
		if i < status.streak then
			d.frame.BackgroundColor3 = GOLD
			d.stroke.Color = GOLD_LIGHT
			d.stroke.Thickness = 2
			d.label.TextColor3 = Color3.fromRGB(20, 10, 0)
		elseif i == status.streak and not status.canClaim then
			d.frame.BackgroundColor3 = GOLD
			d.stroke.Color = GOLD_LIGHT
			d.stroke.Thickness = 2
			d.label.TextColor3 = Color3.fromRGB(20, 10, 0)
		elseif i == (status.streak + 1) or (status.canClaim and i == status.streak + 1) then
			d.frame.BackgroundColor3 = Color3.fromRGB(30, 20, 50)
			d.stroke.Color = NEON_GREEN
			d.stroke.Thickness = 2.5
			d.label.TextColor3 = NEON_GREEN
		else
			d.frame.BackgroundColor3 = Color3.fromRGB(50, 40, 60)
			d.stroke.Color = Color3.fromRGB(80, 70, 90)
			d.stroke.Thickness = 1.5
			d.label.TextColor3 = Color3.fromRGB(120, 110, 130)
		end
	end
end

local function refreshUI()
	rewardLabel.Text = FormatNumber.format(status.nextReward) .. " chips"
	readyBadge.Visible = status.canClaim
	updateStreakDots()

	if status.canClaim then
		claimBtn.Text = "✦  Claim Reward  ✦"
		claimGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 160, 60)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 220, 100)),
		})
		claimBtn.Active = true
		claimBtn.AutoButtonColor = false
		startClaimPulse()
	else
		stopClaimPulse()
		claimBtn.Text = "Next: " .. formatCountdown(status.secondsRemaining)
		claimGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(55, 50, 65)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(55, 50, 65)),
		})
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
	stopClaimPulse()
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
