local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

ReplicatedStorage:WaitForChild("Remotes", 15)

local Shared       = ReplicatedStorage:WaitForChild("Shared")
local Remotes      = require(Shared.net.Remotes)
local FormatNumber = require(Shared.utils.FormatNumber)

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Local copy of the latest server status; the countdown ticks down off this each second.
local status = { canClaim = false, secondsRemaining = 0, streak = 0, nextReward = 0 }

local function formatCountdown(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	local h = math.floor(seconds / 3600)
	local m = math.floor((seconds % 3600) / 60)
	local s = seconds % 60
	return string.format("%02d:%02d:%02d", h, m, s)
end

-- ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DailyReward"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Floating toggle button (bottom-left)
local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "ToggleButton"
toggleBtn.Size = UDim2.new(0, 130, 0, 48)
toggleBtn.Position = UDim2.new(0, 16, 1, -120)
toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 24, 60)
toggleBtn.Text = "🎁 Daily"
toggleBtn.TextColor3 = Color3.fromRGB(255, 230, 120)
toggleBtn.TextScaled = true
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.BorderSizePixel = 0
toggleBtn.Parent = screenGui
do
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 12); c.Parent = toggleBtn
	local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(255, 200, 90); s.Thickness = 2; s.Parent = toggleBtn
	local pad = Instance.new("UIPadding"); pad.PaddingTop = UDim.new(0, 8); pad.PaddingBottom = UDim.new(0, 8); pad.Parent = toggleBtn
end

-- A small badge on the toggle button when a reward is ready.
local readyBadge = Instance.new("TextLabel")
readyBadge.Name = "ReadyBadge"
readyBadge.Size = UDim2.new(0, 20, 0, 20)
readyBadge.Position = UDim2.new(1, -8, 0, -8)
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
local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.new(0, 300, 0, 220)
panel.Position = UDim2.new(0, 16, 1, -350)
panel.BackgroundColor3 = Color3.fromRGB(18, 12, 28)
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = screenGui
do
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 16); c.Parent = panel
	local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(180, 130, 255); s.Thickness = 1.5; s.Parent = panel
end

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -24, 0, 36)
title.Position = UDim2.new(0, 12, 0, 10)
title.BackgroundTransparency = 1
title.Text = "Daily Reward"
title.TextColor3 = Color3.fromRGB(255, 230, 120)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local streakLabel = Instance.new("TextLabel")
streakLabel.Size = UDim2.new(1, -24, 0, 26)
streakLabel.Position = UDim2.new(0, 12, 0, 52)
streakLabel.BackgroundTransparency = 1
streakLabel.Text = "Streak: 0 days"
streakLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
streakLabel.TextScaled = true
streakLabel.Font = Enum.Font.Gotham
streakLabel.TextXAlignment = Enum.TextXAlignment.Left
streakLabel.Parent = panel

local rewardLabel = Instance.new("TextLabel")
rewardLabel.Size = UDim2.new(1, -24, 0, 30)
rewardLabel.Position = UDim2.new(0, 12, 0, 82)
rewardLabel.BackgroundTransparency = 1
rewardLabel.Text = "Reward: 🪙 0"
rewardLabel.TextColor3 = Color3.fromRGB(120, 255, 150)
rewardLabel.TextScaled = true
rewardLabel.Font = Enum.Font.GothamBold
rewardLabel.TextXAlignment = Enum.TextXAlignment.Left
rewardLabel.Parent = panel

local claimBtn = Instance.new("TextButton")
claimBtn.Name = "ClaimButton"
claimBtn.Size = UDim2.new(1, -24, 0, 56)
claimBtn.Position = UDim2.new(0, 12, 1, -68)
claimBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 70)
claimBtn.Text = "Claim"
claimBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
claimBtn.TextScaled = true
claimBtn.Font = Enum.Font.GothamBold
claimBtn.BorderSizePixel = 0
claimBtn.Parent = panel
do
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 12); c.Parent = claimBtn
	local pad = Instance.new("UIPadding"); pad.PaddingTop = UDim.new(0, 10); pad.PaddingBottom = UDim.new(0, 10); pad.Parent = claimBtn
end

local function refreshUI()
	streakLabel.Text = "Streak: " .. status.streak .. " day" .. (status.streak == 1 and "" or "s")
	rewardLabel.Text = "Reward: 🪙 " .. FormatNumber.format(status.nextReward)
	readyBadge.Visible = status.canClaim

	if status.canClaim then
		claimBtn.Text = "Claim"
		claimBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 70)
		claimBtn.Active = true
		claimBtn.AutoButtonColor = true
	else
		claimBtn.Text = "Next: " .. formatCountdown(status.secondsRemaining)
		claimBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
		claimBtn.Active = false
		claimBtn.AutoButtonColor = false
	end
end

toggleBtn.MouseButton1Click:Connect(function()
	panel.Visible = not panel.Visible
end)

claimBtn.MouseButton1Click:Connect(function()
	if not status.canClaim then
		return
	end
	claimBtn.Active = false
	claimBtn.AutoButtonColor = false
	claimBtn.Text = "Claiming..."

	local ok, result = pcall(function()
		return Remotes.RequestDailyReward:InvokeServer()
	end)

	if ok and result and result.status then
		status = result.status
		if result.success then
			rewardLabel.Text = "Claimed! 🪙 " .. FormatNumber.format(result.reward)
		end
	end
	refreshUI()
end)

Remotes.DailyRewardStatus.OnClientEvent:Connect(function(newStatus)
	status = newStatus
	refreshUI()
end)

-- Local countdown tick so the timer feels live between server pushes.
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

-- Pull current status on load (the server's join-time push may have fired before this
-- script connected its handler above).
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
