-- Shared helpers for the real machine art models, synced via Rojo into
-- ReplicatedStorage.Machines (assets/machines/*.rbxm). Used by the server to place
-- bought machines and by the client to build a placement ghost that matches the model.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MachineAssets = {}

-- Strip spaces/punctuation + lowercase, so "SlotMachine" matches a model named "slot machine".
local function normalize(s: string): string
	return (string.gsub(string.lower(s), "%W", ""))
end

-- Finds the art template for a machine def's `modelName` (case/space-insensitive).
function MachineAssets.find(modelName: string?): Model?
	if not modelName then return nil end
	local folder = ReplicatedStorage:FindFirstChild("Machines")
	if not folder then return nil end

	local exact = folder:FindFirstChild(modelName)
	if exact and exact:IsA("Model") then return exact end

	local want = normalize(modelName)
	for _, child in folder:GetChildren() do
		if child:IsA("Model") and normalize(child.Name) == want then
			return child
		end
	end
	return nil
end

-- Removes any embedded scripts from a cloned model. Free Toolbox models routinely ship
-- with junk or backdoor scripts; we never want those running in the game. Strips Scripts,
-- LocalScripts, and ModuleScripts (all LuaSourceContainers).
function MachineAssets.stripScripts(model: Instance): number
	local removed = 0
	for _, d in model:GetDescendants() do
		if d:IsA("LuaSourceContainer") then
			d:Destroy()
			removed += 1
		end
	end
	return removed
end

-- Lowest world-space Y across every part corner — orientation-proof (works even if the
-- model's PrimaryPart is rotated, which fooled the simple bounding-box approach).
function MachineAssets.worldBottom(model: Model): number
	local minY = math.huge
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			local cf, sz = p.CFrame, p.Size
			for _, sx in { -1, 1 } do
				for _, sy in { -1, 1 } do
					for _, sz2 in { -1, 1 } do
						local corner = cf * Vector3.new(sx * sz.X / 2, sy * sz.Y / 2, sz2 * sz.Z / 2)
						if corner.Y < minY then
							minY = corner.Y
						end
					end
				end
			end
		end
	end
	return minY == math.huge and 0 or minY
end

-- World-axis-aligned XZ footprint (minX, maxX, minZ, maxZ) across every part corner.
-- Orientation-proof, unlike Model:GetBoundingBox() which aligns to the model's pivot.
function MachineAssets.worldAABB(model: Model): (number, number, number, number)
	local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			local cf, sz = p.CFrame, p.Size
			for _, sx in { -1, 1 } do
				for _, sy in { -1, 1 } do
					for _, sz2 in { -1, 1 } do
						local c = cf * Vector3.new(sx * sz.X / 2, sy * sz.Y / 2, sz2 * sz.Z / 2)
						if c.X < minX then minX = c.X end
						if c.X > maxX then maxX = c.X end
						if c.Z < minZ then minZ = c.Z end
						if c.Z > maxZ then maxZ = c.Z end
					end
				end
			end
		end
	end
	if minX == math.huge then
		return 0, 0, 0, 0
	end
	return minX, maxX, minZ, maxZ
end

-- True if two XZ footprints overlap once each is expanded by `gap` on every side.
function MachineAssets.footprintsOverlap(aMinX, aMaxX, aMinZ, aMaxZ, bMinX, bMaxX, bMinZ, bMaxZ, gap: number): boolean
	return (aMinX - gap) < bMaxX and (aMaxX + gap) > bMinX
		and (aMinZ - gap) < bMaxZ and (aMaxZ + gap) > bMinZ
end

-- Uniformly scales `model` in-place by `factor` around its bounding-box centre.
-- Safer than Model:ScaleTo() which breaks models whose pivot is not centred.
function MachineAssets.scale(model: Model, factor: number)
	local center = model:GetBoundingBox().Position
	for _, desc in model:GetDescendants() do
		if desc:IsA("BasePart") then
			local cf = desc.CFrame
			local newPos = center + (cf.Position - center) * factor
			local _, _, _, r00, r01, r02, r10, r11, r12, r20, r21, r22 = cf:GetComponents()
			desc.CFrame = CFrame.new(newPos.X, newPos.Y, newPos.Z, r00, r01, r02, r10, r11, r12, r20, r21, r22)
			desc.Size = desc.Size * factor
		end
	end
end

-- Positions `model` so its bottom rests on `surfaceY` at (x, z).
-- Normalises the model to Y-up first so .rbxm files exported with a tilted pivot
-- are corrected automatically (PivotTo with identity rotation untilts all descendants).
function MachineAssets.ground(model: Model, x: number, z: number, surfaceY: number)
	-- Step 1: strip any X/Z tilt by pivoting to the same position with identity rotation.
	local pivotPos = model:GetPivot().Position
	model:PivotTo(CFrame.new(pivotPos))

	-- Step 2: now the model is Y-up; compute the correct grounding offset.
	local center = model:GetBoundingBox().Position
	local bottom = MachineAssets.worldBottom(model)
	local shift = Vector3.new(x - center.X, surfaceY - bottom, z - center.Z)
	model:PivotTo(CFrame.new(shift) * model:GetPivot())
end

return MachineAssets
