local Players = game:GetService("Players")

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
		label.Text = "Plot " .. index .. "\nWalk here to claim"
		label.TextColor3 = Color3.fromRGB(200, 255, 200)
	end
end

local function buildClaimPad(index: number, plotModel: Model, center: Vector3)
	-- Sits at the road-facing edge of the plot.
	local dir = GameConfig.plotDirection(index)
	local padPos = center - dir * (PLOT_HALF - 6)

	local pad = makePart(
		"ClaimPad",
		Vector3.new(14, 0.6, 14),
		CFrame.new(padPos.X, W.PLAZA_TOP_Y + 0.6, padPos.Z),
		Color3.fromRGB(80, 200, 120),
		plotModel,
		true
	)
	pad.CanCollide = false

	local sign = Instance.new("BillboardGui")
	sign.Name = "Sign"
	sign.Size = UDim2.new(0, 220, 0, 90)
	sign.StudsOffset = Vector3.new(0, 9, 0)
	sign.AlwaysOnTop = true
	sign.MaxDistance = 400
	sign.Adornee = pad
	sign.Parent = pad

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Text = ""
	label.Parent = sign

	plots[index].sign = sign

	pad.Touched:Connect(function(hit)
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
	makePart("Surface", Vector3.new(W.PLOT_SIZE, 2, W.PLOT_SIZE),
		CFrame.new(center.X, W.PLAZA_TOP_Y - 1, center.Z), STONE_SURFACE, model)

	local machinesFolder = Instance.new("Folder")
	machinesFolder.Name = "Machines"
	machinesFolder.Parent = model

	plots[index] = {
		center = center,
		plotCF = plotBaseCF(center),
		machinesFolder = machinesFolder,
		ownerUserId = nil,
	}

	buildClaimPad(index, model, center)
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
		if def and typeof(m.cf) == "CFrame" then
			local worldCF = plot.plotCF * m.cf
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
