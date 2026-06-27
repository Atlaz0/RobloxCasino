-- Wait for remotes folder before starting controllers
local ReplicatedStorage = game:GetService("ReplicatedStorage")
ReplicatedStorage:WaitForChild("Remotes", 15)

local PlacementController = require(script.controllers.PlacementController)
local PathGuideController = require(script.controllers.PathGuideController)

PlacementController.init()
PathGuideController.init()
