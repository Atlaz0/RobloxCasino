local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")

local Shared      = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes     = require(Shared.net.Remotes)
local MachineData = require(Shared.constants.MachineData)

local player = Players.LocalPlayer
local mouse  = player:GetMouse()

local PHASE_COLORS = {
	[1] = Color3.fromRGB(255, 200, 40),
	[2] = Color3.fromRGB(170, 90, 230),
	[3] = Color3.fromRGB(60, 220, 220),
}

local GRID_SIZE = 4

local activeMachineId: string? = nil
local ghost: Part? = nil
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
	if ghost then
		ghost:Destroy()
		ghost = nil
	end
	mouse.TargetFilter = nil
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

	ghost = Instance.new("Part")
	ghost.Name = "PlacementGhost"
	ghost.Anchored = true
	ghost.CanCollide = false
	ghost.Transparency = 0.45
	ghost.Material = Enum.Material.Neon
	ghost.Color = PHASE_COLORS[def.phase] or PHASE_COLORS[1]
	ghost.Size = Vector3.new(6, 10, 6)
	ghost.Parent = workspace

	-- Critical: make the mouse ray ignore the ghost, otherwise mouse.Hit lands on the
	-- ghost itself and the placement position feeds back on itself.
	mouse.TargetFilter = ghost
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

	return Vector3.new(x, plotInfo.topY + 5, z), inside
end

local function init()
	RunService.RenderStepped:Connect(function()
		if not activeMachineId or not ghost or not plotInfo.claimed then return end
		local hit = mouse.Hit
		if not hit then return end
		local point, inside = resolvePoint(hit.Position)
		ghost.Position = point
		ghost.Color = inside and Color3.fromRGB(120, 255, 150) or Color3.fromRGB(255, 90, 90)
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
