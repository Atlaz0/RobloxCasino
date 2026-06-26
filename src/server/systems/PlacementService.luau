local Players     = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local Shared       = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local DataManager    = require(script.Parent.Parent.data.DataManager)
local MachineData    = require(Shared.constants.MachineData)
local GameConfig     = require(Shared.constants.GameConfig)
local EconomyService = require(script.Parent.Parent.economy.EconomyService)
local Remotes        = require(Shared.net.Remotes)

local MachineAssets  = require(Shared.MachineAssets)
local PlotService    = require(script.Parent.PlotService)
local MachineModel   = require(script.Parent.MachineModel)

local PlacementService = {}

-- ---------- inventory replication ----------

local function sendInventory(player: Player)
	local profile = DataManager.get(player)
	if not profile then return end
	local items = {}
	for _, it in profile.inventory do
		table.insert(items, { id = it.id, level = it.level })
	end
	Remotes.InventoryUpdated:FireClient(player, items)
end

-- ---------- placement helpers ----------

local function machineLookup(profile, uid: string)
	for i, m in profile.machines do
		if m.uid == uid then
			return m, i
		end
	end
	return nil
end

local function placedModel(plot, uid: string): Model?
	for _, m in plot.machinesFolder:GetChildren() do
		if m:IsA("Model") and m:GetAttribute("Uid") == uid then
			return m
		end
	end
	return nil
end

-- True if `model` would overlap (within MACHINE_MIN_SPACING) any other machine on the plot.
local function overlapsExisting(model: Model, folder: Folder): boolean
	local minX, maxX, minZ, maxZ = MachineAssets.worldAABB(model)
	local gap = GameConfig.MACHINE_MIN_SPACING
	for _, other in folder:GetChildren() do
		if other:IsA("Model") and other ~= model then
			local oMinX, oMaxX, oMinZ, oMaxZ = MachineAssets.worldAABB(other)
			if MachineAssets.footprintsOverlap(minX, maxX, minZ, maxZ, oMinX, oMaxX, oMinZ, oMaxZ, gap) then
				return true
			end
		end
	end
	return false
end

-- Shared validation for any placement (cost is checked separately by the buy path).
local function validate(player: Player, def, worldCF: CFrame): (boolean, string?)
	local profile = DataManager.get(player)
	if not profile then return false, "Profile not loaded" end
	if not def then return false, "Unknown machine" end
	if def.phase > profile.phase then return false, "Not unlocked yet" end

	local plot = PlotService.getPlayerPlot(player)
	if not plot then return false, "Claim a plot first" end

	local pos = worldCF.Position
	if math.abs(pos.X - plot.center.X) > plot.halfSize or math.abs(pos.Z - plot.center.Z) > plot.halfSize then
		return false, "Place it on your plot"
	end

	local limit = GameConfig.MAX_LOT_MACHINES + (profile.hasExtraLot and 25 or 0)
	if #profile.machines >= limit then return false, "Lot is full" end

	return true
end

-- Builds the machine, runs the collision check, and records it in the profile. Does NOT
-- handle cost. Returns ok, reason.
local function buildAndRecord(player: Player, def, worldCF: CFrame, level: number): (boolean, string?)
	local profile = DataManager.get(player)
	local plot = PlotService.getPlayerPlot(player)
	if not profile or not plot then return false, "Not ready" end

	local pos = worldCF.Position
	local baseCF = CFrame.new(pos.X, plot.topY + 0.5, pos.Z)
	local uid = HttpService:GenerateGUID(false)

	local model = MachineModel.build(def, baseCF)
	MachineModel.finalize(model, uid, def.id)
	model.Parent = plot.machinesFolder

	if overlapsExisting(model, plot.machinesFolder) then
		model:Destroy()
		return false, "Too close to another machine"
	end

	local rel = plot.plotCF:ToObjectSpace(baseCF).Position
	table.insert(profile.machines, { uid = uid, id = def.id, level = level, x = rel.X, z = rel.Z })
	DataManager.markDirty(player)
	return true
end

-- ---------- public placement entry points ----------

-- Buy + place a brand-new machine.
local function placeMachine(player: Player, machineId: string, worldCF: CFrame): (boolean, string?)
	local def = MachineData[machineId]
	local ok, reason = validate(player, def, worldCF)
	if not ok then return false, reason end

	local profile = DataManager.get(player)
	if profile.chips < def.cost then return false, "Not enough chips" end

	local placed, preason = buildAndRecord(player, def, worldCF, 1)
	if not placed then return false, preason end

	EconomyService.spendChips(player, def.cost) -- affordability already checked above
	return true
end

-- Place a machine that was previously picked up into the inventory (no cost).
local function placeFromInventory(player: Player, invIndex: number, machineId: string, worldCF: CFrame): (boolean, string?)
	local profile = DataManager.get(player)
	if not profile then return false, "Profile not loaded" end

	local item = profile.inventory[invIndex]
	if not item or item.id ~= machineId then return false, "Item not in inventory" end

	local def = MachineData[machineId]
	local ok, reason = validate(player, def, worldCF)
	if not ok then return false, reason end

	local placed, preason = buildAndRecord(player, def, worldCF, item.level)
	if not placed then return false, preason end

	table.remove(profile.inventory, invIndex)
	DataManager.markDirty(player)
	sendInventory(player)
	return true
end

-- ---------- pickup / sell ----------

local function pickupMachine(player: Player, uid: string)
	local profile = DataManager.get(player)
	if not profile then return { success = false, reason = "No profile" } end
	local plot = PlotService.getPlayerPlot(player)
	if not plot then return { success = false, reason = "No plot" } end

	local entry, idx = machineLookup(profile, uid)
	if not entry then return { success = false, reason = "Machine not found" } end

	local model = placedModel(plot, uid)
	if model then model:Destroy() end

	table.remove(profile.machines, idx)
	table.insert(profile.inventory, { id = entry.id, level = entry.level })
	DataManager.markDirty(player)
	sendInventory(player)
	return { success = true }
end

local function sellMachine(player: Player, uid: string)
	local profile = DataManager.get(player)
	if not profile then return { success = false, reason = "No profile" } end

	local entry, idx = machineLookup(profile, uid)
	if not entry then return { success = false, reason = "Machine not found" } end

	local def = MachineData[entry.id]
	local refund = def and GameConfig.machineSellValue(def) or 0

	local plot = PlotService.getPlayerPlot(player)
	if plot then
		local model = placedModel(plot, uid)
		if model then model:Destroy() end
	end

	table.remove(profile.machines, idx)
	EconomyService.awardChips(player, refund)
	DataManager.markDirty(player)
	return { success = true, refund = refund }
end

local function sellInventory(player: Player, invIndex: number)
	local profile = DataManager.get(player)
	if not profile then return { success = false, reason = "No profile" } end

	local item = profile.inventory[invIndex]
	if not item then return { success = false, reason = "Item not found" } end

	local def = MachineData[item.id]
	local refund = def and GameConfig.machineSellValue(def) or 0

	table.remove(profile.inventory, invIndex)
	EconomyService.awardChips(player, refund)
	DataManager.markDirty(player)
	sendInventory(player)
	return { success = true, refund = refund }
end

-- ---------- wiring ----------

local function init()
	Remotes.RequestPlace.OnServerEvent:Connect(function(player, machineId, cf)
		if type(machineId) ~= "string" or typeof(cf) ~= "CFrame" then return end
		local ok, reason = placeMachine(player, machineId, cf)
		Remotes.PlacementResult:FireClient(player, ok, reason)
	end)

	Remotes.RequestPlaceFromInventory.OnServerEvent:Connect(function(player, invIndex, machineId, cf)
		if type(invIndex) ~= "number" or type(machineId) ~= "string" or typeof(cf) ~= "CFrame" then return end
		local ok, reason = placeFromInventory(player, invIndex, machineId, cf)
		Remotes.PlacementResult:FireClient(player, ok, reason)
	end)

	Remotes.RequestPickupMachine.OnServerInvoke = function(player, uid)
		if type(uid) ~= "string" then return { success = false, reason = "Bad request" } end
		return pickupMachine(player, uid)
	end
	Remotes.RequestSellMachine.OnServerInvoke = function(player, uid)
		if type(uid) ~= "string" then return { success = false, reason = "Bad request" } end
		return sellMachine(player, uid)
	end
	Remotes.RequestSellInventory.OnServerInvoke = function(player, invIndex)
		if type(invIndex) ~= "number" then return { success = false, reason = "Bad request" } end
		return sellInventory(player, invIndex)
	end

	-- Push inventory once each player's profile has loaded.
	Players.PlayerAdded:Connect(function(player)
		task.defer(function()
			for _ = 1, 30 do
				if DataManager.get(player) then break end
				task.wait(0.5)
			end
			sendInventory(player)
		end)
	end)
	for _, player in Players:GetPlayers() do
		task.defer(sendInventory, player)
	end
end

PlacementService.init = init
PlacementService.placeMachine = placeMachine
PlacementService.sendInventory = sendInventory

return PlacementService
