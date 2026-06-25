local Players = game:GetService("Players")

local Shared          = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig      = require(Shared.constants.GameConfig)
local Remotes         = require(Shared.net.Remotes)

local DataManager     = require(script.Parent.Parent.data.DataManager)
local EconomyService  = require(script.Parent.Parent.economy.EconomyService)

local CFG = GameConfig.DAILY_REWARD

-- Returns a status table the client can use to render the daily-reward UI.
-- `streak` is the player's CURRENT streak; `nextReward` is what they'd get if they claim now.
local function getStatus(player: Player)
	local profile = DataManager.get(player)
	if not profile then
		return { canClaim = false, secondsRemaining = CFG.COOLDOWN, streak = 0, nextReward = GameConfig.dailyRewardForStreak(1) }
	end

	local now = os.time()
	local elapsed = now - (profile.lastDailyBonusTime or 0)
	local canClaim = elapsed >= CFG.COOLDOWN
	local secondsRemaining = canClaim and 0 or (CFG.COOLDOWN - elapsed)

	-- The streak the player would be ON if they claimed right now: continues if still
	-- inside the reset window, otherwise restarts at 1.
	local nextStreak
	if profile.lastDailyBonusTime == 0 then
		nextStreak = 1
	elseif elapsed <= CFG.STREAK_RESET_WINDOW then
		nextStreak = math.min(profile.dailyBonusStreak + 1, CFG.MAX_STREAK)
	else
		nextStreak = 1
	end

	return {
		canClaim = canClaim,
		secondsRemaining = secondsRemaining,
		streak = profile.dailyBonusStreak or 0,
		nextReward = GameConfig.dailyRewardForStreak(nextStreak),
	}
end

local function pushStatus(player: Player)
	Remotes.DailyRewardStatus:FireClient(player, getStatus(player))
end

-- Server-authoritative claim. Validates the cooldown, awards chips, advances/resets the
-- streak, and returns a result table to the invoking client.
local function claim(player: Player)
	local profile = DataManager.get(player)
	if not profile then
		return { success = false, reason = "No profile loaded.", status = getStatus(player) }
	end

	local now = os.time()
	local elapsed = now - (profile.lastDailyBonusTime or 0)
	if profile.lastDailyBonusTime ~= 0 and elapsed < CFG.COOLDOWN then
		return { success = false, reason = "Already claimed today.", status = getStatus(player) }
	end

	-- Advance or reset the streak.
	if profile.lastDailyBonusTime ~= 0 and elapsed <= CFG.STREAK_RESET_WINDOW then
		profile.dailyBonusStreak = math.min(profile.dailyBonusStreak + 1, CFG.MAX_STREAK)
	else
		profile.dailyBonusStreak = 1
	end

	local reward = GameConfig.dailyRewardForStreak(profile.dailyBonusStreak)
	profile.lastDailyBonusTime = now
	DataManager.markDirty(player)

	EconomyService.awardChips(player, reward)

	local status = getStatus(player)
	pushStatus(player)
	return { success = true, reward = reward, streak = profile.dailyBonusStreak, status = status }
end

local function init()
	Remotes.RequestDailyReward.OnServerInvoke = function(player: Player)
		return claim(player)
	end

	-- Lets the client pull current status on load, avoiding a race where the join-time
	-- push fires before the client's status handler is connected.
	Remotes.RequestDailyStatus.OnServerInvoke = function(player: Player)
		return getStatus(player)
	end

	Players.PlayerAdded:Connect(function(player)
		-- Profile loads asynchronously; wait briefly for it before pushing status.
		task.defer(function()
			for _ = 1, 30 do
				if DataManager.get(player) then
					break
				end
				task.wait(0.5)
			end
			pushStatus(player)
		end)
	end)

	-- Players already present (Studio test / hot reload).
	for _, player in Players:GetPlayers() do
		task.defer(pushStatus, player)
	end
end

return {
	init = init,
	getStatus = getStatus,
	claim = claim,
}
