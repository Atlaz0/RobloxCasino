-- FountainService — builds a cartoony multi-tier water fountain as the spawn-area
-- centerpiece. Pure Roblox parts (no external assets). Runs once on server start.

local Shared     = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared.constants.GameConfig)

local W = GameConfig.WORLD

-- Cartoony pastel palette.
local STONE       = Color3.fromRGB(216, 208, 228) -- pastel stone
local STONE_DARK  = Color3.fromRGB(176, 166, 194)
local WATER       = Color3.fromRGB(120, 200, 255) -- sky blue water

local FountainService = {}

-- Helper: a vertical cylinder (disc/pillar). Cylinder parts point along local X by
-- default, so we rotate 90° about Z to stand them upright. `height` is the Y extent.
local function disc(name, radius, height, topY, color, material, canCollide, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = Enum.PartType.Cylinder
	part.Anchored = true
	part.CanCollide = canCollide
	part.Material = material
	part.Color = color
	part.Size = Vector3.new(height, radius * 2, radius * 2)
	part.CFrame = CFrame.new(0, topY - height / 2, 0) * CFrame.Angles(0, 0, math.rad(90))
	part.Parent = parent
	return part
end

function FountainService.build(centerX: number, centerZ: number, baseY: number): Model
	local model = Instance.new("Model")
	model.Name = "WaterFountain"

	-- We build at the origin then move the whole model to (centerX, _, centerZ) at the end,
	-- so the disc() helper's centered math stays simple.
	-- ---- Lower tier (big bubbly basin) ----
	local lowerBasin = disc("LowerBasin", 16, 4, 4, STONE, Enum.Material.SmoothPlastic, true, model)
	disc("LowerRim", 17, 1.6, 4.4, STONE_DARK, Enum.Material.SmoothPlastic, true, model) -- chunky rim
	local lowerWater = disc("LowerWater", 14.5, 0.6, 4.2, WATER, Enum.Material.Neon, false, model)
	lowerWater.Transparency = 0.25

	-- ---- Central pedestal connecting the tiers ----
	disc("Pedestal", 4, 8, 12, STONE, Enum.Material.SmoothPlastic, true, model)

	-- ---- Upper tier (smaller basin) ----
	disc("UpperBasin", 8, 2.5, 14, STONE, Enum.Material.SmoothPlastic, false, model)
	disc("UpperRim", 8.6, 1, 14.3, STONE_DARK, Enum.Material.SmoothPlastic, false, model)
	local upperWater = disc("UpperWater", 6.8, 0.5, 14.2, WATER, Enum.Material.Neon, false, model)
	upperWater.Transparency = 0.25

	-- ---- Center spout ----
	local spout = disc("Spout", 1.4, 6, 20, STONE_DARK, Enum.Material.SmoothPlastic, false, model)

	-- Upward water spray from the spout.
	local spray = Instance.new("ParticleEmitter")
	spray.Name = "WaterSpray"
	spray.Color = ColorSequence.new(WATER)
	spray.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	spray.Lifetime = NumberRange.new(0.8, 1.4)
	spray.Rate = 60
	spray.Speed = NumberRange.new(14, 20)
	spray.SpreadAngle = Vector2.new(18, 18)
	spray.Acceleration = Vector3.new(0, -40, 0) -- gravity pulls the spray back down
	spray.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.6),
		NumberSequenceKeypoint.new(1, 0.2),
	})
	spray.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	spray.EmissionDirection = Enum.NormalId.Right -- spout's local +X points up after rotation
	spray.Parent = spout

	-- Gentle sparkle on the lower water surface for charm.
	local sparkle = Instance.new("ParticleEmitter")
	sparkle.Name = "Sparkle"
	sparkle.Color = ColorSequence.new(Color3.fromRGB(220, 245, 255))
	sparkle.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparkle.Lifetime = NumberRange.new(0.6, 1.2)
	sparkle.Rate = 14
	sparkle.Speed = NumberRange.new(0.5, 1.5)
	sparkle.SpreadAngle = Vector2.new(180, 180)
	sparkle.Size = NumberSequence.new(0.6)
	sparkle.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	sparkle.Parent = lowerWater

	-- Light-blue glow from inside the basin.
	local light = Instance.new("PointLight")
	light.Name = "WaterGlow"
	light.Color = WATER
	light.Brightness = 2.5
	light.Range = 30
	light.Parent = lowerWater

	model.PrimaryPart = lowerBasin

	-- Translate the whole fountain (built at origin with its base bottom at y=0) to
	-- (centerX, centerZ) and up onto the plaza surface. Pre-multiplying by the current
	-- pivot keeps each part's orientation (the basins are rotated cylinders).
	model:PivotTo(CFrame.new(centerX, baseY, centerZ) * model:GetPivot())
	return model
end

-- Nudges the SpawnLocation off the exact center so players don't spawn inside the fountain.
local function offsetSpawnAroundFountain()
	local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
	if not spawn then return end
	-- Sit the spawn pad just outside the lower-basin footprint, still on the plaza.
	spawn.Position = Vector3.new(24, W.PLAZA_TOP_Y + spawn.Size.Y / 2, 0)
end

function FountainService.init()
	local existing = workspace:FindFirstChild("WaterFountain")
	if existing then existing:Destroy() end

	-- Plaza is centered on the world origin; base sits on the plaza surface.
	local model = FountainService.build(0, 0, W.PLAZA_TOP_Y)
	model.Parent = workspace

	offsetSpawnAroundFountain()
end

return FountainService
