local Shared       = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local DataManager    = require(script.Parent.Parent.data.DataManager)
local MachineData    = require(Shared.constants.MachineData)
local GameConfig     = require(Shared.constants.GameConfig)
local EconomyService = require(script.Parent.Parent.economy.EconomyService)
local Remotes        = require(Shared.net.Remotes)

local PlotService    = require(script.Parent.PlotService)
local MachineModel   = require(script.Parent.MachineModel)

local function countMachines(profile): number
	return #profile.machines
end

-- worldCF is where the player clicked on their plot (from the client ghost).
local function placeMachine(player: Player, machineId: string, worldCF: CFrame): (boolean, string?)
	local profile = DataManager.get(player)
	if not profile then return false, "Profile not loaded" end

	local def = MachineData[machineId]
	if not def then return false, "Unknown machine" end

	if def.phase > profile.phase then
		return false, "Not unlocked yet"
	end

	local plot = PlotService.getPlayerPlot(player)
	if not plot then
		return false, "Claim a plot first"
	end

	-- Must be placed within the player's plot square.
	local pos = worldCF.Position
	if math.abs(pos.X - plot.center.X) > plot.halfSize or math.abs(pos.Z - plot.center.Z) > plot.halfSize then
		return false, "Place it on your plot"
	end

	local limit = GameConfig.MAX_LOT_MACHINES + (profile.hasExtraLot and 25 or 0)
	if countMachines(profile) >= limit then
		return false, "Lot is full"
	end

	if not EconomyService.spendChips(player, def.cost) then
		return false, "Not enough chips"
	end

	-- Snap the machine to the plot surface and build a visible model.
	local baseCF = CFrame.new(pos.X, plot.topY + 0.5, pos.Z)
	local model = MachineModel.build(def, baseCF)
	model.Parent = plot.machinesFolder

	-- Store the position RELATIVE to the plot so it can be rebuilt on whatever plot the
	-- player claims next session.
	local relativeCF = plot.plotCF:ToObjectSpace(baseCF)
	table.insert(profile.machines, {
		id = machineId,
		level = 1,
		cf = relativeCF,
	})
	DataManager.markDirty(player)

	return true, nil
end

local function init()
	Remotes.RequestPlace.OnServerEvent:Connect(function(player, machineId, cf)
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
