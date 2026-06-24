-- Wait for remotes folder before starting controllers
local ReplicatedStorage = game:GetService("ReplicatedStorage")
ReplicatedStorage:WaitForChild("Remotes", 15)

local PlacementController = require(script.Parent.controllers.PlacementController)

PlacementController.init()
