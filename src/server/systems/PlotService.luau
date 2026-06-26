local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")

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

-- A small gray door frame at the road-facing edge of the plot — it doubles as the
-- entrance to the glass building. Players claim by walking through the doorway (an
-- invisible trigger fills the opening). The path guides them here (ClaimPoint attribute).
local DOOR_WIDTH = 14
local POST_THICK = 1.5
local POST_HEIGHT = 12
local LINTEL_HEIGHT = 2
local DOOR_COLOR = Color3.fromRGB(125, 130, 140)     -- gray
local DOOR_TOP_COLOR = Color3.fromRGB(95, 100, 112)

-- Glass building constructed on the plot when it's claimed.
local WALL_HEIGHT = 26
local WALL_THICK = 1
local GLASS_COLOR = Color3.fromRGB(205, 235, 255)
local ROOF_COLOR = Color3.fromRGB(78, 82, 92)   -- solid roof
local BEAM_COLOR = Color3.fromRGB(88, 92, 104)   -- window frame beams
local BEAM_THICK = 2
local MULLION_PANES = 5                            -- vertical glass panes per wall

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
			CFrame.new(p.X, W.PLAZA_TOP_Y + POST_HEIGHT / 2, p.Z), DOOR_COLOR, plotModel)
	end

	-- Top beam.
	local lintelLen = DOOR_WIDTH + 2 * POST_THICK
	local lintelSize = alongX and Vector3.new(POST_THICK, LINTEL_HEIGHT, lintelLen)
		or Vector3.new(lintelLen, LINTEL_HEIGHT, POST_THICK)
	local lintel = makePart("DoorLintel", lintelSize,
		CFrame.new(doorCenter.X, W.PLAZA_TOP_Y + POST_HEIGHT + LINTEL_HEIGHT / 2, doorCenter.Z), DOOR_TOP_COLOR, plotModel)

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

-- Builds the glass-walled building on a claimed plot. The front (road-side) wall has a
-- gap aligned with the door frame — that doorway is the entrance. Walls are solid so you
-- enter through the door, but click-through (CanQuery=false) so machine placement rays
-- still reach the floor.
local function buildBuilding(index: number)
	local plot = plots[index]
	if not plot then return end
	if plot.building then plot.building:Destroy() end

	local center = plot.center
	local dir = GameConfig.plotDirection(index)
	local perp = Vector3.new(dir.Z, 0, -dir.X)
	local half = PLOT_HALF
	local floorY = W.PLAZA_TOP_Y

	local building = Instance.new("Folder")
	building.Name = "Building"
	building.Parent = plot.model

	local function glass(name: string, size: Vector3, pos: Vector3)
		local p = makePart(name, size, CFrame.new(pos.X, floorY + WALL_HEIGHT / 2, pos.Z), GLASS_COLOR, building)
		p.Material = Enum.Material.Glass
		p.Transparency = 0.5
		p.Reflectance = 0.08
		p.CanQuery = false
		return p
	end

	-- Opaque frame beam (post/rail). Click-through so placement isn't blocked.
	local function beam(name: string, size: Vector3, x: number, y: number, z: number)
		local p = makePart(name, size, CFrame.new(x, y, z), BEAM_COLOR, building)
		p.CanQuery = false
		return p
	end

	-- Length of a horizontal beam laid along `axis` (axis is ±X or ±Z unit).
	local function sizeAlong(axis: Vector3, length: number, height: number, thick: number): Vector3
		if math.abs(axis.X) > 0.5 then
			return Vector3.new(length, height, thick)
		end
		return Vector3.new(thick, height, length)
	end

	-- Vertical mullions evenly dividing a wall span into panes (skips a centred door gap).
	local function mullions(wallCenter: Vector3, spanAxis: Vector3, spanLength: number, panes: number, gapWidth: number?)
		for i = 1, panes - 1 do
			local t = -spanLength / 2 + i * (spanLength / panes)
			if not (gapWidth and math.abs(t) < gapWidth / 2) then
				local pos = wallCenter + spanAxis * t
				beam("Mullion", Vector3.new(BEAM_THICK, WALL_HEIGHT, BEAM_THICK), pos.X, floorY + WALL_HEIGHT / 2, pos.Z)
			end
		end
	end

	local fbSize = sizeAlong(perp, W.PLOT_SIZE, WALL_HEIGHT, WALL_THICK)
	local sideSize = sizeAlong(dir, W.PLOT_SIZE, WALL_HEIGHT, WALL_THICK)

	-- Glass walls.
	glass("WallBack", fbSize, center + dir * half)
	glass("WallSideA", sideSize, center + perp * half)
	glass("WallSideB", sideSize, center - perp * half)

	-- Front wall split into two glass segments around the door gap.
	local gap = DOOR_WIDTH + 3
	local segLen = (W.PLOT_SIZE - gap) / 2
	local segOffset = gap / 2 + segLen / 2
	local segSize = sizeAlong(perp, segLen, WALL_HEIGHT, WALL_THICK)
	local frontPos = center - dir * half
	for _, side in { 1, -1 } do
		glass("WallFront", segSize, frontPos + perp * (side * segOffset))
	end

	-- ---- frame beams (so the walls read as framed windows, not one big pane) ----

	-- Corner posts.
	for _, sx in { 1, -1 } do
		for _, sz in { 1, -1 } do
			beam("CornerPost", Vector3.new(BEAM_THICK, WALL_HEIGHT, BEAM_THICK),
				center.X + sx * half, floorY + WALL_HEIGHT / 2, center.Z + sz * half)
		end
	end

	-- Top rail and a mid rail (the mid rail sits above the door height so it clears it).
	for _, yLevel in { floorY + WALL_HEIGHT - BEAM_THICK / 2, floorY + WALL_HEIGHT / 2 } do
		local backC, frontC = center + dir * half, center - dir * half
		local sideAC, sideBC = center + perp * half, center - perp * half
		beam("Rail", sizeAlong(perp, W.PLOT_SIZE, BEAM_THICK, BEAM_THICK), backC.X, yLevel, backC.Z)
		beam("Rail", sizeAlong(perp, W.PLOT_SIZE, BEAM_THICK, BEAM_THICK), frontC.X, yLevel, frontC.Z)
		beam("Rail", sizeAlong(dir, W.PLOT_SIZE, BEAM_THICK, BEAM_THICK), sideAC.X, yLevel, sideAC.Z)
		beam("Rail", sizeAlong(dir, W.PLOT_SIZE, BEAM_THICK, BEAM_THICK), sideBC.X, yLevel, sideBC.Z)
	end

	-- Vertical mullions (front wall skips the door gap).
	mullions(center + dir * half, perp, W.PLOT_SIZE, MULLION_PANES)
	mullions(center + perp * half, dir, W.PLOT_SIZE, MULLION_PANES)
	mullions(center - perp * half, dir, W.PLOT_SIZE, MULLION_PANES)
	mullions(center - dir * half, perp, W.PLOT_SIZE, MULLION_PANES, gap)

	-- Solid roof.
	local roof = makePart("Roof", Vector3.new(W.PLOT_SIZE, WALL_THICK, W.PLOT_SIZE),
		CFrame.new(center.X, floorY + WALL_HEIGHT, center.Z), ROOF_COLOR, building)
	roof.CanQuery = false

	-- Ceiling lights (3x3 grid of glowing panels just under the roof).
	local lightY = floorY + WALL_HEIGHT - 1.5
	local spacing = W.PLOT_SIZE / 4
	for _, gx in { -1, 0, 1 } do
		for _, gz in { -1, 0, 1 } do
			local fixture = makePart("CeilingLight", Vector3.new(8, 0.6, 8),
				CFrame.new(center.X + gx * spacing, lightY, center.Z + gz * spacing),
				Color3.fromRGB(255, 250, 235), building)
			fixture.Material = Enum.Material.Neon
			fixture.CanQuery = false
			fixture.CanCollide = false
			local light = Instance.new("PointLight")
			light.Color = Color3.fromRGB(255, 244, 214)
			light.Brightness = 0.8
			light.Range = 26
			light.Parent = fixture
		end
	end

	plot.building = building
end

local function destroyBuilding(index: number)
	local plot = plots[index]
	if plot and plot.building then
		plot.building:Destroy()
		plot.building = nil
	end
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
			plotName = "Plot" .. index,
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
			if not m.uid then m.uid = HttpService:GenerateGUID(false) end
			local worldCF = plot.plotCF * CFrame.new(m.x, 0, m.z)
			local model = MachineModel.build(def, worldCF)
			MachineModel.finalize(model, m.uid, m.id)
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
	buildBuilding(index)
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
		destroyBuilding(index)
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
