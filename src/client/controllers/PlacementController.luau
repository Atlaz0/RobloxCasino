local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")

local Shared        = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes       = require(Shared.net.Remotes)
local MachineData   = require(Shared.constants.MachineData)
local MachineAssets = require(Shared.MachineAssets)

local player = Players.LocalPlayer
local mouse  = player:GetMouse()

local GRID_SIZE = 4
local GHOST_GREEN = Color3.fromRGB(80, 255, 140)
local GHOST_RED   = Color3.fromRGB(255, 90, 90)

local activeMachineId: string? = nil
local ghostModel: Model? = nil
local plotInfo = { claimed = false } -- updated by PlotAssigned

-- Simple screen toast for feedback (placement errors, hints).
local toastLabel: TextLabel
local function ensureToast()
	if toastLabel then return end
	local gui = Instance.new("ScreenGui")
	gui.Name = "PlacementToast"
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")

	toastLabel = Instance.new("TextLabel")
	toastLabel.Size = UDim2.new(0, 360, 0, 44)
	toastLabel.Position = UDim2.new(0.5, -180, 0, 80)
	toastLabel.BackgroundColor3 = Color3.fromRGB(18, 12, 28)
	toastLabel.TextColor3 = Color3.fromRGB(255, 230, 120)
	toastLabel.Font = Enum.Font.GothamBold
	toastLabel.TextScaled = true
	toastLabel.Text = ""
	toastLabel.Visible = false
	toastLabel.Parent = gui
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 12); c.Parent = toastLabel
	local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(180, 130, 255); s.Thickness = 1.5; s.Parent = toastLabel
	local p = Instance.new("UIPadding"); p.PaddingLeft = UDim.new(0, 12); p.PaddingRight = UDim.new(0, 12); p.Parent = toastLabel
end

local toastToken = 0
local function toast(text: string)
	ensureToast()
	toastLabel.Text = text
	toastLabel.Visible = true
	toastToken += 1
	local myToken = toastToken
	task.delay(2.5, function()
		if toastToken == myToken then
			toastLabel.Visible = false
		end
	end)
end

local function clearGhost()
	if ghostModel then
		ghostModel:Destroy()
		ghostModel = nil
	end
end

-- Makes a cloned model into a ghost: translucent, non-colliding, and transparent to the
-- mouse ray (CanQuery = false), with a green/red validity Highlight.
local function styleGhost(model: Model)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanTouch = false
			d.CanQuery = false -- so mouse.Hit lands on the plot, not the ghost
			d.Transparency = math.clamp(d.Transparency + 0.45, 0.4, 0.85)
		elseif d:IsA("Decal") or d:IsA("Texture") then
			d.Transparency = math.clamp(d.Transparency + 0.45, 0.4, 1)
		end
	end

	local hl = Instance.new("Highlight")
	hl.Name = "GhostHighlight"
	hl.FillColor = GHOST_GREEN
	hl.OutlineColor = GHOST_GREEN
	hl.FillTransparency = 0.55
	hl.DepthMode = Enum.HighlightDepthMode.Occluded
	hl.Parent = model
end

local function beginPlacement(machineId: string)
	clearGhost()
	local def = MachineData[machineId]
	if not def then return end

	if not plotInfo.claimed then
		toast("Claim a plot first — walk onto a plot pad!")
		return
	end

	activeMachineId = machineId

	-- Ghost = a translucent clone of the real model so it matches the placed shape.
	local template = MachineAssets.find(def.modelName)
	if template then
		ghostModel = template:Clone()
		MachineAssets.stripScripts(ghostModel) -- never run embedded model scripts (even client-side)
	else
		-- Fallback if the model is missing: a simple box.
		ghostModel = Instance.new("Model")
		local box = Instance.new("Part")
		box.Size = Vector3.new(6, 10, 6)
		box.Material = Enum.Material.Neon
		box.Parent = ghostModel
		ghostModel.PrimaryPart = box
	end

	styleGhost(ghostModel)
	ghostModel.Parent = workspace
end

local function cancelPlacement()
	clearGhost()
	activeMachineId = nil
end

-- Snap to grid and clamp inside the plot square. Returns the placement point + whether
-- it is inside the plot.
local function resolvePoint(worldPos: Vector3): (Vector3, boolean)
	local cx, cz = plotInfo.center.X, plotInfo.center.Z
	local half = plotInfo.halfSize

	local x = math.round(worldPos.X / GRID_SIZE) * GRID_SIZE
	local z = math.round(worldPos.Z / GRID_SIZE) * GRID_SIZE

	local inside = math.abs(worldPos.X - cx) <= half and math.abs(worldPos.Z - cz) <= half
	x = math.clamp(x, cx - half, cx + half)
	z = math.clamp(z, cz - half, cz + half)

	return Vector3.new(x, plotInfo.topY, z), inside
end

local function init()
	RunService.RenderStepped:Connect(function()
		if not activeMachineId or not ghostModel or not plotInfo.claimed then return end
		local hit = mouse.Hit
		if not hit then return end
		local point, inside = resolvePoint(hit.Position)
		-- Ground the ghost on the plot surface at the snapped point.
		MachineAssets.ground(ghostModel, point.X, point.Z, plotInfo.topY)
		local hl = ghostModel:FindFirstChild("GhostHighlight")
		if hl then
			hl.FillColor = inside and GHOST_GREEN or GHOST_RED
			hl.OutlineColor = inside and GHOST_GREEN or GHOST_RED
		end
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if not activeMachineId then return end

		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			local hit = mouse.Hit
			if not hit then return end
			local point, inside = resolvePoint(hit.Position)
			if not inside then
				toast("Place it on your plot")
				return
			end
			Remotes.RequestPlace:FireServer(activeMachineId, CFrame.new(point.X, plotInfo.topY, point.Z))
			cancelPlacement()
		elseif input.KeyCode == Enum.KeyCode.Escape then
			cancelPlacement()
		end
	end)

	Remotes.PlacementResult.OnClientEvent:Connect(function(success: boolean, reason: string?)
		if not success then
			toast(reason or "Placement failed")
		end
	end)

	Remotes.PlotAssigned.OnClientEvent:Connect(function(info)
		plotInfo = info or { claimed = false }
		if plotInfo.claimed then
			toast("Plot claimed! Open the Shop to build your casino.")
		end
	end)
end

return {
	init            = init,
	beginPlacement  = beginPlacement,
	cancelPlacement = cancelPlacement,
	isPlotClaimed   = function() return plotInfo.claimed end,
}
