-- Wait for remotes folder before starting controllers
local ReplicatedStorage = game:GetService("ReplicatedStorage")
ReplicatedStorage:WaitForChild("Remotes", 15)

local EconomyController  = require(script.Parent.controllers.EconomyController)
local UIController       = require(script.Parent.controllers.UIController)
local PlacementController = require(script.Parent.controllers.PlacementController)

EconomyController.init()
UIController.init()
PlacementController.init()
