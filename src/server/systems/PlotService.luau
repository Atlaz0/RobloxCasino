local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local Shared       = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig   = require(Shared.constants.GameConfig)
local MachineData  = require(Shared.constants.MachineData)
local Remotes      = require(Shared.net.Remotes)

local DataManager  = require(script.Parent.Parent.data.DataManager)
local MachineModel = require(script.Parent.MachineModel)

local W = GameConfig.WORLD
local PLOT_HALF = W.PLOT_SIZE / 2
local PLACE_MARGIN = 8 -- keep machines this far from the plot edge

local STONE_SURFACE = Color3.fromRGB(170, 175, 185)
local STONE_BORDER = Color3.fromRGB(90, 95, 105)

-- plots[index] = { center, plotCF, machinesFolder, sign, ownerUserId }
local plots = {}
local playerPlot = {} -- [userId] = index

local PlotService = {}

-- The CFrame that machine positions are stored relative to (plot surface, base height).
local function plotBaseCF(center: Vector3): CFrame
	return CFrame.new(center.X, W.PLAZA_TOP_Y + 0.5, center.Z)
end

local function makePart(name: string, size: Vector3, cf: CFrame, color: Color3, parent: Instance, neon: boolean?): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Material = neon and Enum.Material.Neon or Enum.Material.SmoothPlastic
	part.Color = color
	part.Size = size
	part.CFrame = cf
	part.Parent = parent
	return part
end

local function updateSign(index: number)
	local plot = plots[index]
	if not plot or not plot.sign then return end
	local label = plot.sign:FindFirstChild("Label")
	if not label then return end

	if plot.ownerUserId then
		local owner = Players:GetPlayerByUserId(plot.ownerUserId)
		label.Text = (owner and owner.DisplayName or "Player") .. "'s Casino"
		label.TextColor3 = Color3.fromRGB(255, 220, 120)
	else
		label.Text = "Plot " .. index .. "\nWalk through to claim"
		label.TextColor3 = Color3.fromRGB(200, 255, 200)
	end
end

-- A wooden door frame at the road-facing edge of the plot. Players claim the plot by
-- walking through the doorway (an invisible trigger fills the opening). The path guides
-- them to this doorway (exposed as the plot's ClaimPoint attribute).
local DOOR_WIDTH = 20
local POST_THICK = 2.5
local POST_HEIGHT = 18
local LINTEL_HEIGHT = 3
local WOOD = Color3.fromRGB(116, 78, 48)
local WOOD_TOP = Color3.fromRGB(150, 104, 62)

local function buildDoorway(index: number, plotModel: Model, center: Vector3)
	local dir = GameConfig.plotDirection(index)
	local alongX = math.abs(dir.X) > 0.5
	local doorCenter = center - dir * (PLOT_HALF - 1) -- front edge, facing the road

	-- Perpendicular offset for the two posts.
	local halfSpan = DOOR_WIDTH / 2 + POST_THICK / 2
	local function sideOffset(side: number): Vector3
		return alongX and Vector3.new(0, 0, side * halfSpan) or Vector3.new(side * halfSpan, 0, 0)
	end

	for _, side in { 1, -1 } do
		local p = doorCenter + sideOffset(side)
		makePart("DoorPost", Vector3.new(POST_THICK, POST_HEIGHT, POST_THICK),
			CFrame.new(p.X, W.PLAZA_TOP_Y + POST_HEIGHT / 2, p.Z), WOOD, plotModel)
	end

	-- Top beam.
	local lintelLen = DOOR_WIDTH + 2 * POST_THICK
	local lintelSize = alongX and Vector3.new(POST_THICK, LINTEL_HEIGHT, lintelLen)
		or Vector3.new(lintelLen, LINTEL_HEIGHT, POST_THICK)
	local lintel = makePart("DoorLintel", lintelSize,
		CFrame.new(doorCenter.X, W.PLAZA_TOP_Y + POST_HEIGHT + LINTEL_HEIGHT / 2, doorCenter.Z), WOOD_TOP, plotModel)

	-- Invisible claim trigger filling the opening.
	local triggerSize = alongX and Vector3.new(5, POST_HEIGHT, DOOR_WIDTH)
		or Vector3.new(DOOR_WIDTH, POST_HEIGHT, 5)
	local trigger = makePart("ClaimTrigger", triggerSize,
		CFrame.new(doorCenter.X, W.PLAZA_TOP_Y + POST_HEIGHT / 2, doorCenter.Z),
		Color3.fromRGB(80, 200, 120), plotModel)
	trigger.Transparency = 1
	trigger.CanCollide = false

	-- Sign on the lintel.
	local sign = Instance.new("BillboardGui")
	sign.Name = "Sign"
	sign.Size = UDim2.new(0, 240, 0, 80)
	sign.StudsOffset = Vector3.new(0, 4, 0)
	sign.AlwaysOnTop = true
	sign.MaxDistance = 500
	sign.Adornee = lintel
	sign.Parent = lintel

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Text = ""
	label.Parent = sign

	plots[index].sign = sign

	-- The path points clients at this doorway.
	plotModel:SetAttribute("ClaimPoint", doorCenter)

	trigger.Touched:Connect(function(hit)
		local character = hit and hit.Parent
		local player = character and Players:GetPlayerFromCharacter(character)
		if not player then return end
		PlotService.tryClaim(player, index)
	end)
end

local function buildPlot(index: number)
	local dir = GameConfig.plotDirection(index)
	local dist = GameConfig.plotCenterDistance()
	local center = Vector3.new(dir.X * dist, 0, dir.Z * dist)

	local model = Instance.new("Model")
	model.Name = "Plot" .. index
	model.Parent = workspace:FindFirstChild("Plots")

	makePart("Border", Vector3.new(W.PLOT_SIZE + 10, 2, W.PLOT_SIZE + 10),
		CFrame.new(center.X, W.PLAZA_TOP_Y - 1.4, center.Z), STONE_BORDER, model)
	local surface = makePart("Surface", Vector3.new(W.PLOT_SIZE, 2, W.PLOT_SIZE),
		CFrame.new(center.X, W.PLAZA_TOP_Y - 1, center.Z), STONE_SURFACE, model)
	model.PrimaryPart = surface

	-- Occupancy is exposed as an attribute so the client path guide can find free plots
	-- (and the ClaimPoint attribute, set in buildDoorway) without coupling to internals.
	model:SetAttribute("Occupied", false)
	CollectionService:AddTag(model, "Plot")

	local machinesFolder = Instance.new("Folder")
	machinesFolder.Name = "Machines"
	machinesFolder.Parent = model

	plots[index] = {
		model = model,
		center = center,
		plotCF = plotBaseCF(center),
		machinesFolder = machinesFolder,
		ownerUserId = nil,
	}

	buildDoorway(index, model, center)
	updateSign(index)
end

local function notifyPlot(player: Player)
	local index = playerPlot[player.UserId]
	if index then
		local plot = plots[index]
		Remotes.PlotAssigned:FireClient(player, {
			claimed = true,
			center = plot.center,
			halfSize = PLOT_HALF - PLACE_MARGIN,
			topY = W.PLAZA_TOP_Y,
		})
	else
		Remotes.PlotAssigned:FireClient(player, { claimed = false })
	end
end

-- Rebuilds a returning player's machines (stored plot-relative) onto their plot.
local function rebuildMachines(player: Player, index: number)
	local profile = DataManager.get(player)
	if not profile then return end
	local plot = plots[index]
	plot.machinesFolder:ClearAllChildren()

	for _, m in profile.machines do
		local def = MachineData[m.id]
		if def and m.x and m.z then
			local worldCF = plot.plotCF * CFrame.new(m.x, 0, m.z)
			local model = MachineModel.build(def, worldCF)
			model.Parent = plot.machinesFolder
		end
	end
end

function PlotService.tryClaim(player: Player, index: number): boolean
	if playerPlot[player.UserId] then return false end -- already has a plot
	local plot = plots[index]
	if not plot or plot.ownerUserId then return false end -- taken

	plot.ownerUserId = player.UserId
	playerPlot[player.UserId] = index
	if plot.model then plot.model:SetAttribute("Occupied", true) end
	updateSign(index)
	rebuildMachines(player, index)
	notifyPlot(player)
	return true
end

local function releasePlot(userId: number)
	local index = playerPlot[userId]
	if not index then return end
	playerPlot[userId] = nil
	local plot = plots[index]
	if plot then
		plot.ownerUserId = nil
		if plot.model then plot.model:SetAttribute("Occupied", false) end
		plot.machinesFolder:ClearAllChildren()
		updateSign(index)
	end
end

-- Bounds + frame used by PlacementService to validate and store placements.
function PlotService.getPlayerPlot(player: Player)
	local index = playerPlot[player.UserId]
	if not index then return nil end
	local plot = plots[index]
	return {
		index = index,
		center = plot.center,
		halfSize = PLOT_HALF - PLACE_MARGIN,
		topY = W.PLAZA_TOP_Y,
		plotCF = plot.plotCF,
		machinesFolder = plot.machinesFolder,
	}
end

function PlotService.init()
	local folder = workspace:FindFirstChild("Plots")
	if folder then folder:Destroy() end
	folder = Instance.new("Folder")
	folder.Name = "Plots"
	folder.Parent = workspace

	for index = 1, W.PLOT_COUNT do
		buildPlot(index)
	end

	Players.PlayerRemoving:Connect(function(player)
		releasePlot(player.UserId)
	end)

	-- Tell joining players they have no plot yet (after their profile has had a moment to load).
	Players.PlayerAdded:Connect(function(player)
		task.defer(notifyPlot, player)
	end)
	for _, player in Players:GetPlayers() do
		task.defer(notifyPlot, player)
	end
end

return PlotService
