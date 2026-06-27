local Lighting = game:GetService("Lighting")
local StarterPlayer = game:GetService("StarterPlayer")
local ServerStorage = game:GetService("ServerStorage")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared.constants.GameConfig)

local W = GameConfig.WORLD
local GROUND_TOP_Y = W.GROUND_TOP_Y
local PLAZA_TOP_Y = W.PLAZA_TOP_Y
local SPAWN_PLAZA_RADIUS = W.PLAZA_RADIUS

local PLAYER_WALK_SPEED = 28 -- Roblox default is 16

local PLANE_RADIUS = 1500 -- enlarged so the roads + plots fit comfortably on the grass
local PLANE_HEIGHT = 40
local BUFFER = 350
local MOUNTAIN_RING_INNER = PLANE_RADIUS + BUFFER
local MOUNTAIN_RING_OUTER = MOUNTAIN_RING_INNER + 550
local MOUNTAIN_COUNT = 34

-- Decoration is placed on a jittered grid (one candidate per cell) rather than fully
-- random scatter, so trees/rocks/pebbles are spaced evenly instead of clumping.
local DECOR_GRID_SPACING = 75 -- studs between decoration cells
local DECOR_JITTER_FRAC = 0.35 -- max offset from cell center, as a fraction of spacing
local DECOR_TREE_CHANCE = 0.45 -- per filled cell
local DECOR_ROCK_CHANCE = 0.15
local DECOR_PEBBLE_CHANCE = 0.30
-- (remaining ~10% of cells are left empty for breathing room)

-- How far decoration must stay clear of the road center lines / plot squares.
local ROAD_CLEARANCE = W.ROAD_WIDTH / 2 + 14
local PLOT_REACH = GameConfig.plotCenterDistance() + W.PLOT_SIZE / 2 + 20

local WorldService = {}

-- VillageAssetPack is synced via Rojo into ServerStorage.Assets (see default.project.json,
-- which maps ServerStorage.Assets to assets/models on disk). ServerStorage keeps the source
-- templates out of the live Workspace — only the clones placed below should be visible.
local function getAssetPack(): Instance?
	local assets = ServerStorage:FindFirstChild("Assets")
	if not assets then
		warn("WorldService: ServerStorage.Assets not found (Rojo not synced yet?), skipping asset-based world decoration")
		return nil
	end
	local pack = assets:FindFirstChild("VillageAssetPack")
	if not pack then
		warn("WorldService: VillageAssetPack not found under Workspace.Assets")
		return nil
	end
	return pack
end

-- Clones `prefab`, drops it so the bottom of its bounding box sits on GROUND_TOP_Y at
-- (x, z), and applies a random Y-axis rotation for natural variety.
local function stripScripts(inst: Instance)
	for _, d in inst:GetDescendants() do
		if d:IsA("LuaSourceContainer") then d:Destroy() end
	end
end

local function placeOnGround(prefab: Instance, x: number, z: number, parent: Instance): Instance
	local clone = prefab:Clone()
	stripScripts(clone) -- VillageAssetPack models ship with embedded "Structure" scripts

	if clone:IsA("Model") then
		local boundsCFrame, boundsSize = clone:GetBoundingBox()
		local bottomY = boundsCFrame.Position.Y - boundsSize.Y / 2
		local pivot = clone:GetPivot()
		local offsetFromBottom = pivot.Position.Y - bottomY
		local targetY = GROUND_TOP_Y + offsetFromBottom
		clone:PivotTo(CFrame.new(x, targetY, z) * CFrame.Angles(0, math.random() * math.pi * 2, 0))
	elseif clone:IsA("BasePart") then
		local targetY = GROUND_TOP_Y + clone.Size.Y / 2
		clone.CFrame = CFrame.new(x, targetY, z) * CFrame.Angles(0, math.random() * math.pi * 2, 0)
	end

	clone.Parent = parent
	return clone
end

local function buildMountainRing(pack: Instance, parent: Instance)
	local mountainPrefab = pack:FindFirstChild("Mountains")
	if not mountainPrefab then
		return
	end

	local mountains = Instance.new("Folder")
	mountains.Name = "Mountains"
	mountains.Parent = parent

	for i = 1, MOUNTAIN_COUNT do
		local angle = (i / MOUNTAIN_COUNT) * math.pi * 2 + math.random() * 0.15
		local distance = MOUNTAIN_RING_INNER + math.random() * (MOUNTAIN_RING_OUTER - MOUNTAIN_RING_INNER)
		local x = math.cos(angle) * distance
		local z = math.sin(angle) * distance
		placeOnGround(mountainPrefab, x, z, mountains)
	end
end

-- Evenly distributes trees, rocks, and pebbles across the grass using a jittered grid:
-- one candidate per grid cell, nudged randomly within the cell and assigned a type by
-- weighted roll. This guarantees consistent spacing (no clumps, no bald patches) while
-- still looking organic. Cells inside the spawn plaza or off the plane are skipped.
local function scatterDecorations(pack: Instance, parent: Instance)
	local trees = {}
	for _, name in { "Tree1", "Tree2", "Tree3" } do
		local prefab = pack:FindFirstChild(name)
		if prefab then
			table.insert(trees, prefab)
		end
	end
	local rock = pack:FindFirstChild("Rocks")
	local pebble = pack:FindFirstChild("Pebbles")

	local folder = Instance.new("Folder")
	folder.Name = "Decorations"
	folder.Parent = parent

	local jitter = DECOR_GRID_SPACING * DECOR_JITTER_FRAC
	local plazaClearance = SPAWN_PLAZA_RADIUS + 15
	local edgeClearance = PLANE_RADIUS - 25
	local plotHalf = W.PLOT_SIZE / 2 + 12
	local plotDist = GameConfig.plotCenterDistance()

	-- Keep decoration off the roads (plus-shaped corridor) and off the plot squares.
	local function isReserved(x: number, z: number): boolean
		if (math.abs(x) < ROAD_CLEARANCE and math.abs(z) < plotDist)
			or (math.abs(z) < ROAD_CLEARANCE and math.abs(x) < plotDist) then
			return true
		end
		for index = 1, 4 do
			local dir = GameConfig.plotDirection(index)
			if math.abs(x - dir.X * plotDist) < plotHalf and math.abs(z - dir.Z * plotDist) < plotHalf then
				return true
			end
		end
		return false
	end

	for gx = -PLANE_RADIUS, PLANE_RADIUS, DECOR_GRID_SPACING do
		for gz = -PLANE_RADIUS, PLANE_RADIUS, DECOR_GRID_SPACING do
			local x = gx + (math.random() * 2 - 1) * jitter
			local z = gz + (math.random() * 2 - 1) * jitter
			local dist = math.sqrt(x * x + z * z)

			if dist > plazaClearance and dist < edgeClearance and not isReserved(x, z) then
				local roll = math.random()
				local prefab
				if roll < DECOR_TREE_CHANCE and #trees > 0 then
					prefab = trees[math.random(1, #trees)]
				elseif roll < DECOR_TREE_CHANCE + DECOR_ROCK_CHANCE and rock then
					prefab = rock
				elseif roll < DECOR_TREE_CHANCE + DECOR_ROCK_CHANCE + DECOR_PEBBLE_CHANCE and pebble then
					prefab = pebble
				end
				if prefab then
					placeOnGround(prefab, x, z, folder)
				end
			end
		end
	end
end

local function buildGround(parent: Instance)
	local ground = Instance.new("Part")
	ground.Name = "Ground"
	ground.Shape = Enum.PartType.Block
	ground.Anchored = true
	ground.CanCollide = true
	ground.Size = Vector3.new(PLANE_RADIUS * 2, PLANE_HEIGHT, PLANE_RADIUS * 2)
	ground.CFrame = CFrame.new(0, GROUND_TOP_Y - PLANE_HEIGHT / 2, 0)
	ground.Material = Enum.Material.SmoothPlastic
	ground.Color = Color3.fromRGB(120, 200, 110)
	ground.Parent = parent
end

-- Shared stone palette so the plaza, roads, and plots all read as one style.
local STONE_SURFACE = Color3.fromRGB(170, 175, 185)
local STONE_BORDER = Color3.fromRGB(90, 95, 105)
local LAMP_POST_COLOR = Color3.fromRGB(60, 55, 70)
local LAMP_BULB_COLOR = Color3.fromRGB(255, 230, 160)

-- A single lamp post (post + neon bulb + light) used by the plaza, roads, and plots.
local function buildLampPost(x: number, z: number, parent: Instance)
	local post = Instance.new("Part")
	post.Name = "LampPost"
	post.Anchored = true
	post.CanCollide = false
	post.Material = Enum.Material.SmoothPlastic
	post.Color = LAMP_POST_COLOR
	post.Size = Vector3.new(1.5, 14, 1.5)
	post.CFrame = CFrame.new(x, PLAZA_TOP_Y + 7, z)
	post.Parent = parent

	local bulb = Instance.new("Part")
	bulb.Name = "Bulb"
	bulb.Shape = Enum.PartType.Ball
	bulb.Anchored = true
	bulb.CanCollide = false
	bulb.Material = Enum.Material.Neon
	bulb.Color = LAMP_BULB_COLOR
	bulb.Size = Vector3.new(2.5, 2.5, 2.5)
	bulb.CFrame = CFrame.new(x, PLAZA_TOP_Y + 14.5, z)
	bulb.Parent = parent

	local light = Instance.new("PointLight")
	light.Color = LAMP_BULB_COLOR
	light.Range = 20
	light.Brightness = 1.2
	light.Parent = bulb
end

-- A circular stone plaza at the world center: a raised disc, a darker border ring
-- beneath it, and four corner lamp posts framing the spawn point.
local function buildSpawnPlaza(parent: Instance)
	local plaza = Instance.new("Model")
	plaza.Name = "SpawnPlaza"
	plaza.Parent = parent

	local function disc(name: string, radius: number, thickness: number, topY: number, color: Color3)
		local part = Instance.new("Part")
		part.Name = name
		part.Shape = Enum.PartType.Cylinder
		part.Anchored = true
		part.CanCollide = true
		part.Material = Enum.Material.SmoothPlastic
		part.Color = color
		part.Size = Vector3.new(thickness, radius * 2, radius * 2)
		-- Cylinder axis is local X by default; rotate so it points up (world Y).
		part.CFrame = CFrame.new(0, topY - thickness / 2, 0) * CFrame.Angles(0, 0, math.rad(90))
		part.Parent = plaza
		return part
	end

	disc("Border", SPAWN_PLAZA_RADIUS + 6, 2, PLAZA_TOP_Y - 0.4, STONE_BORDER)
	disc("Surface", SPAWN_PLAZA_RADIUS, 2, PLAZA_TOP_Y, STONE_SURFACE)

	local lampOffset = SPAWN_PLAZA_RADIUS - 12
	for _, corner in { Vector2.new(1, 1), Vector2.new(1, -1), Vector2.new(-1, 1), Vector2.new(-1, -1) } do
		buildLampPost(corner.X * lampOffset, corner.Y * lampOffset, plaza)
	end
end

-- Four stone roads radiating from the plaza in +X, -X, +Z, -Z, each lined with lamp
-- posts. Same raised-surface + darker-border style as the plaza. Built in the plaza's
-- local frame then oriented per direction.
local function buildRoads(parent: Instance)
	local roads = Instance.new("Model")
	roads.Name = "Roads"
	roads.Parent = parent

	local startDist = SPAWN_PLAZA_RADIUS - 4 -- overlap the plaza slightly for a seamless join
	local roadLength = W.ROAD_LENGTH + 8
	local centerDist = startDist + roadLength / 2

	-- Lamp posts spaced along both sides of the road.
	local lampSpacing = 60
	local lampSide = W.ROAD_WIDTH / 2 + 4

	for index = 1, 4 do
		local dir = GameConfig.plotDirection(index)
		local alongX = math.abs(dir.X) > 0.5
		local center = dir * centerDist

		local function slab(name: string, width: number, length: number, topY: number, color: Color3)
			local part = Instance.new("Part")
			part.Name = name
			part.Anchored = true
			part.CanCollide = true
			part.Material = Enum.Material.SmoothPlastic
			part.Color = color
			-- Road runs along the direction axis; width is perpendicular.
			local sizeX = alongX and length or width
			local sizeZ = alongX and width or length
			part.Size = Vector3.new(sizeX, 2, sizeZ)
			part.CFrame = CFrame.new(center.X, topY - 1, center.Z)
			part.Parent = roads
			return part
		end

		slab("RoadBorder" .. index, W.ROAD_WIDTH + 10, roadLength, PLAZA_TOP_Y - 0.4, STONE_BORDER)
		slab("Road" .. index, W.ROAD_WIDTH, roadLength, PLAZA_TOP_Y, STONE_SURFACE)

		-- Lamps along both edges.
		local count = math.floor(roadLength / lampSpacing)
		for i = 1, count do
			local along = startDist + (i - 0.5) * (roadLength / count)
			for _, side in { -1, 1 } do
				local x, z
				if alongX then
					x = dir.X * along
					z = side * lampSide
				else
					x = side * lampSide
					z = dir.Z * along
				end
				buildLampPost(x, z, roads)
			end
		end
	end
end

local function ensureSpawnLocation(parent: Instance)
	local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
	if not spawn then
		spawn = Instance.new("SpawnLocation")
		spawn.Name = "Spawn"
		spawn.Size = Vector3.new(10, 1, 10)
		spawn.Parent = parent
	end
	-- Make the spawn pad itself invisible (and strip the default sunburst decal) so only
	-- the grey plaza surface shows; the plaza beneath it is what the player stands on.
	spawn.Anchored = true
	spawn.CanCollide = false
	spawn.Transparency = 1
	for _, child in spawn:GetChildren() do
		if child:IsA("Decal") or child:IsA("Texture") then
			child:Destroy()
		end
	end
	-- Sit the spawn pad on top of the plaza surface so players land on the plaza.
	spawn.Position = Vector3.new(0, PLAZA_TOP_Y + spawn.Size.Y / 2, 0)
end

-- Removes the legacy Studio-template baseplate so it can't sit underneath/above our world.
local function removeLegacyBaseplate()
	local legacy = workspace:FindFirstChild("Baseplate")
	if legacy and legacy:IsA("BasePart") then
		legacy:Destroy()
	end
end

-- Punchy, saturated, high-contrast look instead of a realistic muted render.
local function applyCartoonLook()
	Lighting.Brightness = 3
	Lighting.Ambient = Color3.fromRGB(120, 120, 140)
	Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 165)
	Lighting.ColorShift_Top = Color3.fromRGB(180, 220, 255)
	Lighting.EnvironmentSpecularScale = 0.5
	Lighting.EnvironmentDiffuseScale = 0.5

	-- Push the fog cutoff far out so the much bigger world renders at full distance.
	-- (StreamingEnabled is disabled via default.project.json — it can't be written at runtime.)
	Lighting.FogStart = 0
	Lighting.FogEnd = 100000

	local colorCorrection = Lighting:FindFirstChild("WorldColorCorrection")
	if not colorCorrection then
		colorCorrection = Instance.new("ColorCorrectionEffect")
		colorCorrection.Name = "WorldColorCorrection"
		colorCorrection.Parent = Lighting
	end
	colorCorrection.Saturation = 0.45
	colorCorrection.Contrast = 0.2
	colorCorrection.Brightness = 0.02

	if not Lighting:FindFirstChildOfClass("Sky") then
		Instance.new("Sky").Parent = Lighting
	end
end

local function applyPlayerMovement()
	StarterPlayer.CharacterWalkSpeed = PLAYER_WALK_SPEED
end

function WorldService.generate()
	removeLegacyBaseplate()
	workspace.Terrain:Clear()

	local existing = workspace:FindFirstChild("World")
	if existing then
		existing:Destroy()
	end

	local world = Instance.new("Model")
	world.Name = "World"
	world.Parent = workspace

	buildGround(world)
	buildSpawnPlaza(world)
	buildRoads(world)

	local pack = getAssetPack()
	if pack then
		buildMountainRing(pack, world)
		scatterDecorations(pack, world)
	end

	ensureSpawnLocation(world)
	applyCartoonLook()
	applyPlayerMovement()
end

function WorldService.init()
	removeLegacyBaseplate() -- always strip the Studio-template baseplate, even if the world already exists
	applyPlayerMovement() -- cheap, always reapply regardless of whether the world regenerates
	if workspace:GetAttribute("WorldGenerated") then
		return
	end
	WorldService.generate()
	workspace:SetAttribute("WorldGenerated", true)
end

return WorldService
