local Players = game:GetService("Players")

local Shared       = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local DataManager  = require(script.Parent.Parent.data.DataManager)
local MachineData  = require(Shared.constants.MachineData)
local GameConfig   = require(Shared.constants.GameConfig)
local Remotes      = require(Shared.net.Remotes)
local PlotService  = require(script.Parent.Parent.systems.PlotService)

local function getActiveBoostMultiplier(profile): number
	local now = os.time()
	local best = 1
	for _, boost in profile.boosts do
		if boost.expiresAt > now and boost.multiplier > best then
			best = boost.multiplier
		end
	end
	return best
end

local function calcIncomePerSecond(profile): number
	local base = 0
	for _, machine in profile.machines do
		local def = MachineData[machine.id]
		if def then
			local levelBonus = 1 + (machine.level - 1) * def.incomeMultiplierPerLevel
			base += def.incomePerSecond * levelBonus
		end
	end

	local multiplier = profile.prestigeMultiplier
		* getActiveBoostMultiplier(profile)
		* (profile.hasVIPManager and 2 or 1)

	return base * multiplier
end

local function awardChips(player: Player, amount: number)
	local profile = DataManager.get(player)
	if not profile then return end

	profile.chips += amount
	profile.totalChipsEarned += math.max(amount, 0)
	DataManager.markDirty(player)

	Remotes.ChipsUpdated:FireClient(player, profile.chips)
end

local function spendChips(player: Player, amount: number): boolean
	local profile = DataManager.get(player)
	if not profile then return false end
	if profile.chips < amount then return false end

	profile.chips -= amount
	DataManager.markDirty(player)
	Remotes.ChipsUpdated:FireClient(player, profile.chips)
	return true
end

local function init()
	-- Passive income tick
	task.spawn(function()
		while true do
			task.wait(GameConfig.PASSIVE_INCOME_INTERVAL)
			for _, player in Players:GetPlayers() do
				local profile = DataManager.get(player)
				if profile then
					local hasClaimed = PlotService.getPlayerPlot(player) ~= nil
					local rate = hasClaimed and calcIncomePerSecond(profile) or 0
					if hasClaimed then
						awardChips(player, rate * GameConfig.PASSIVE_INCOME_INTERVAL)
					end
					Remotes.IncomeRateUpdated:FireClient(player, rate)
				end
			end
		end
	end)
end

return {
	init               = init,
	awardChips         = awardChips,
	spendChips         = spendChips,
	calcIncomePerSecond = calcIncomePerSecond,
}
