local Players        = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService     = game:GetService("RunService")

local Shared      = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes     = require(Shared.net.Remotes)
local MachineData = require(Shared.constants.MachineData)

local camera = workspace.CurrentCamera
local mouse  = Players.LocalPlayer:GetMouse()

local activeMachineId: string? = nil
local ghostModel: Model? = nil
local GRID_SIZE = 4

local function snapToGrid(v: Vector3): Vector3
	return Vector3.new(
		math.round(v.X / GRID_SIZE) * GRID_SIZE,
		v.Y,
		math.round(v.Z / GRID_SIZE) * GRID_SIZE
	)
end

local function clearGhost()
	if ghostModel then
		ghostModel:Destroy()
		ghostModel = nil
	end
end

local function beginPlacement(machineId: string)
	clearGhost()
	activeMachineId = machineId

	-- Build a transparent ghost from the machine's model (client-side preview)
	local def = MachineData[machineId]
	if not def then return end

	local template = game.ReplicatedStorage:FindFirstChild("GhostModels")
		and game.ReplicatedStorage.GhostModels:FindFirstChild(def.modelName)
	if template then
		ghostModel = template:Clone()
		for _, part in ghostModel:GetDescendants() do
			if part:IsA("BasePart") then
				part.Transparency = 0.5
				part.CanCollide = false
				part.Anchored = true
			end
		end
		ghostModel.Parent = workspace
	end
end

local function cancelPlacement()
	clearGhost()
	activeMachineId = nil
end

local function init()
	-- Update ghost position every frame
	RunService.RenderStepped:Connect(function()
		if not activeMachineId or not ghostModel then return end
		local hit = mouse.Hit
		if hit then
			local snapped = snapToGrid(hit.Position)
			ghostModel:SetPrimaryPartCFrame(CFrame.new(snapped))
		end
	end)

	-- Click to place
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if not activeMachineId then return end

		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			local hit = mouse.Hit
			if hit then
				local snapped = snapToGrid(hit.Position)
				local cf = CFrame.new(snapped)
				Remotes.RequestPlace:FireServer(activeMachineId, cf)
				cancelPlacement()
			end
		elseif input.KeyCode == Enum.KeyCode.Escape then
			cancelPlacement()
		end
	end)

	Remotes.PlacementResult.OnClientEvent:Connect(function(success: boolean, reason: string?)
		if not success then
			warn("Placement failed:", reason)
			-- TODO: show UI toast
		end
	end)
end

return {
	init             = init,
	beginPlacement   = beginPlacement,
	cancelPlacement  = cancelPlacement,
}
