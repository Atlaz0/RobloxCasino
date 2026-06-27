-- Wait for remotes folder before starting controllers
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local RunService         = game:GetService("RunService")
local UserInputService   = game:GetService("UserInputService")
local Players            = game:GetService("Players")
ReplicatedStorage:WaitForChild("Remotes", 15)

local PlacementController = require(script.controllers.PlacementController)
local PathGuideController = require(script.controllers.PathGuideController)

PlacementController.init()
PathGuideController.init()

-- Hide the cursor in first person (camera within 1 stud of the head).
-- Restore it when zooming back out or when placement mode is active.
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
RunService.RenderStepped:Connect(function()
	local character = player.Character
	if not character then
		UserInputService.MouseIconEnabled = true
		return
	end
	local head = character:FindFirstChild("Head")
	if not head then
		UserInputService.MouseIconEnabled = true
		return
	end
	local isFirstPerson = (camera.CFrame.Position - head.Position).Magnitude < 1
	-- Keep cursor visible while actively placing a machine
	UserInputService.MouseIconEnabled = not isFirstPerson or PlacementController.isPlacing()
end)
