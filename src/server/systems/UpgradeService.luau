local Players = game:GetService("Players")

local DataManager    = require(script.Parent.Parent.data.DataManager)
local MachineData    = require(game.ReplicatedStorage.Shared.constants.MachineData)
local EconomyService = require(script.Parent.Parent.economy.EconomyService)
local Remotes        = require(game.ReplicatedStorage.Shared.net.Remotes)

-- upgradeId format: "SlotMachine:0"  (machineId + colon + index in machines array)
local function upgradeMachine(player: Player, upgradeId: string): (boolean, string?)
	local profile = DataManager.get(player)
	if not profile then return false, "Profile not loaded" end

	local machineId, indexStr = upgradeId:match("^(.+):(%d+)$")
	if not machineId or not indexStr then return false, "Bad upgradeId" end

	local index = tonumber(indexStr)
	local machine = profile.machines[index]
	if not machine or machine.id ~= machineId then return false, "Machine not found" end

	local def = MachineData[machineId]
	if not def then return false, "Unknown machine" end

	if machine.level >= def.maxLevel then return false, "Already max level" end

	local cost = math.floor(def.cost * def.upgradeCostMultiplier ^ machine.level)
	if not EconomyService.spendChips(player, cost) then
		return false, "Not enough chips"
	end

	machine.level += 1
	DataManager.markDirty(player)
	return true, nil
end

local function getUpgradeCost(machineId: string, currentLevel: number): number
	local def = MachineData[machineId]
	if not def then return 0 end
	return math.floor(def.cost * def.upgradeCostMultiplier ^ currentLevel)
end

local function init()
	Remotes.RequestUpgrade:Connect(function(player, upgradeId)
		if type(upgradeId) ~= "string" then return end
		local ok, reason = upgradeMachine(player, upgradeId)
		Remotes.UpgradeResult:FireClient(player, ok, reason)
	end)
end

return {
	init           = init,
	upgradeMachine = upgradeMachine,
	getUpgradeCost = getUpgradeCost,
}
