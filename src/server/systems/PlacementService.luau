local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local Shared       = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local DataManager    = require(script.Parent.Parent.data.DataManager)
local MachineData    = require(Shared.constants.MachineData)
local GameConfig     = require(Shared.constants.GameConfig)
local EconomyService = require(script.Parent.Parent.economy.EconomyService)
local Remotes        = require(Shared.net.Remotes)

local lotFolder: Folder

local function getLotFolder(): Folder
	if lotFolder then return lotFolder end
	lotFolder = workspace:FindFirstChild("Lots") or (function()
		local f = Instance.new("Folder")
		f.Name = "Lots"
		f.Parent = workspace
		return f
	end)()
	return lotFolder
end

local function getPlayerFolder(player: Player): Folder
	local lots = getLotFolder()
	local existing = lots:FindFirstChild(tostring(player.UserId))
	if existing then return existing :: Folder end
	local f = Instance.new("Folder")
	f.Name = tostring(player.UserId)
	f.Parent = lots
	return f
end

local function countMachines(profile): number
	return #profile.machines
end

local function placeMachine(player: Player, machineId: string, cf: CFrame): (boolean, string?)
	local profile = DataManager.get(player)
	if not profile then return false, "Profile not loaded" end

	local def = MachineData[machineId]
	if not def then return false, "Unknown machine" end

	if def.phase > profile.phase then
		return false, "Not unlocked yet"
	end

	local limit = GameConfig.MAX_LOT_MACHINES + (profile.hasExtraLot and 25 or 0)
	if countMachines(profile) >= limit then
		return false, "Lot is full"
	end

	if not EconomyService.spendChips(player, def.cost) then
		return false, "Not enough chips"
	end

	-- Spawn model in workspace
	local models = ServerStorage:FindFirstChild("Models")
	local template = models and models:FindFirstChild(def.modelName)
	if template then
		local clone = template:Clone()
		clone:SetPrimaryPartCFrame(cf)
		clone.Name = machineId .. "_" .. player.UserId
		clone.Parent = getPlayerFolder(player)
	end

	table.insert(profile.machines, {
		id = machineId,
		level = 1,
		cf = cf,
	})
	DataManager.markDirty(player)

	return true, nil
end

local function init()
	Remotes.RequestPlace.OnServerEvent:Connect(function(player, machineId, cf)
		-- basic type guards
		if type(machineId) ~= "string" then return end
		if typeof(cf) ~= "CFrame" then return end

		local ok, reason = placeMachine(player, machineId, cf)
		Remotes.PlacementResult:FireClient(player, ok, reason)
	end)
end

return {
	init         = init,
	placeMachine = placeMachine,
}
