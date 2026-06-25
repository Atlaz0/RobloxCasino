-- PathGuideService — lays a glowing green chevron path that FOLLOWS the player from
-- their current position to the nearest unclaimed plot, continuously, until they claim
-- a plot (or no free plots remain). Reads occupancy from the `Occupied` attribute that
-- PlotService sets on each plot model; detects "claimed" via PlotService.getPlayerPlot.

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Shared     = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared.constants.GameConfig)

local PlotService = require(script.Parent.PlotService)

local W = GameConfig.WORLD

local ARROW_Y          = W.PLAZA_TOP_Y + 0.3 -- sit just above the road/plot surface
local CHEVRON_SPACING  = 7                   -- studs between chevrons
local CHEVRON_ARM_LEN  = 6
local STOP_SHORT        = 10                 -- stop drawing this far from the plot center
local REBUILD_MOVE_DIST = 6                  -- rebuild once the player moves this far
local UPDATE_INTERVAL   = 0.35

local PathGuideService = {}

-- activePaths[userId] = { folder, token, lastBuildPos, targetPlot, warned }
local activePaths = {}

-- Returns models under workspace.Plots with `Occupied == false`. Safe if missing/empty.
local function getFreePlots(): { Model }
	local free = {}
	local plotsFolder = workspace:FindFirstChild("Plots")
	if not plotsFolder then return free end
	for _, plot in plotsFolder:GetChildren() do
		if plot:IsA("Model") and plot:GetAttribute("Occupied") == false then
			table.insert(free, plot)
		end
	end
	return free
end

local function flatXZ(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

local function plotCenter(plot: Model): Vector3
	if plot.PrimaryPart then
		return plot.PrimaryPart.Position
	end
	return plot:GetBoundingBox().Position
end

local function findNearestFreePlot(fromPos: Vector3): Model?
	local best, bestDist
	for _, plot in getFreePlots() do
		local d = (flatXZ(plotCenter(plot)) - flatXZ(fromPos)).Magnitude
		if not bestDist or d < bestDist then
			best, bestDist = plot, d
		end
	end
	return best
end

-- One ">" chevron at `position` pointing along `dir`: two flat neon-green bars splayed
-- back from a forward apex, each with a looping transparency pulse.
local function buildChevron(position: Vector3, dir: Vector3, parent: Instance)
	local base = CFrame.lookAt(position, position + dir)
	local right = base.RightVector
	local back = -dir

	for _, sign in { 1, -1 } do
		local armDir = (back + right * sign).Unit
		local center = position + armDir * (CHEVRON_ARM_LEN / 2)

		local bar = Instance.new("Part")
		bar.Name = "Chevron"
		bar.Anchored = true
		bar.CanCollide = false
		bar.CanTouch = false
		bar.CanQuery = false
		bar.Material = Enum.Material.Neon
		bar.BrickColor = BrickColor.new("Lime green")
		bar.Size = Vector3.new(1.4, 0.2, CHEVRON_ARM_LEN)
		bar.CFrame = CFrame.lookAt(center, center + armDir)
		bar.Parent = parent

		TweenService:Create(
			bar,
			TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{ Transparency = 0.5 }
		):Play()
	end
end

local function clearPath(userId: number)
	local entry = activePaths[userId]
	if not entry then return end
	activePaths[userId] = nil
	entry.token = -1
	if entry.folder then
		entry.folder:Destroy()
	end
end

-- Rebuilds the chevron trail from `startPos` to `targetPlot`, reusing the player's path
-- folder (replacing its contents).
local function drawPath(userId: number, startPos: Vector3, targetPlot: Model)
	local entry = activePaths[userId]
	if not entry then return end

	if entry.folder then
		entry.folder:ClearAllChildren()
	else
		local folder = Instance.new("Folder")
		folder.Name = "PlayerPath_" .. userId
		folder.Parent = workspace
		entry.folder = folder
	end

	local target = flatXZ(plotCenter(targetPlot))
	local start = flatXZ(startPos)
	local toTarget = target - start
	local distance = toTarget.Magnitude
	if distance <= STOP_SHORT then return end
	local dir = toTarget.Unit

	local steps = math.max(1, math.floor((distance - STOP_SHORT) / CHEVRON_SPACING))
	for i = 1, steps do
		local pos = start + dir * (i * CHEVRON_SPACING)
		buildChevron(Vector3.new(pos.X, ARROW_Y, pos.Z), dir, entry.folder)
	end

	entry.lastBuildPos = flatXZ(startPos)
	entry.targetPlot = targetPlot
end

-- Persistent follow loop: keeps the path pointing from the player's CURRENT position to
-- the nearest free plot, rebuilding as they move, until they claim a plot.
local function followLoop(player: Player)
	local userId = player.UserId
	clearPath(userId)

	local token = os.clock()
	activePaths[userId] = { token = token, warned = false }

	task.spawn(function()
		while activePaths[userId] and activePaths[userId].token == token do
			local entry = activePaths[userId]

			-- Stop the moment they own a plot.
			if PlotService.getPlayerPlot(player) then
				clearPath(userId)
				return
			end

			local character = player.Character
			local hrp = character and character:FindFirstChild("HumanoidRootPart")
			if not character or not character.Parent or not hrp then
				task.wait(UPDATE_INTERVAL)
				continue
			end

			local target = findNearestFreePlot(hrp.Position)
			if not target then
				if not entry.warned then
					warn("PathGuideService: no free plots available for " .. player.Name)
					entry.warned = true
				end
				if entry.folder then entry.folder:ClearAllChildren() end
			else
				entry.warned = false
				local moved = not entry.lastBuildPos
					or (flatXZ(hrp.Position) - entry.lastBuildPos).Magnitude >= REBUILD_MOVE_DIST
				if moved or entry.targetPlot ~= target then
					drawPath(userId, hrp.Position, target)
				end
			end

			task.wait(UPDATE_INTERVAL)
		end
	end)
end

function PathGuideService.routeFor(player: Player)
	followLoop(player)
end

function PathGuideService.init()
	local function onCharacter(player: Player)
		task.wait(0.3) -- let the character/HRP settle
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			followLoop(player)
		end
	end

	local function hookPlayer(player: Player)
		if player.Character then
			task.spawn(onCharacter, player)
		end
		player.CharacterAdded:Connect(function()
			onCharacter(player)
		end)
	end

	Players.PlayerAdded:Connect(hookPlayer)
	for _, player in Players:GetPlayers() do
		hookPlayer(player)
	end

	Players.PlayerRemoving:Connect(function(player)
		clearPath(player.UserId)
	end)
end

return PathGuideService
