-- Boot order matters: Data first, then Economy, then everything else.
local DataManager         = require(script.data.DataManager)
local EconomyService      = require(script.economy.EconomyService)
local PlacementService    = require(script.systems.PlacementService)
local UpgradeService      = require(script.systems.UpgradeService)
local PrestigeService     = require(script.systems.PrestigeService)
local MonetizationService = require(script.systems.MonetizationService)
local SlotMachineService  = require(script.systems.SlotMachineService)

-- Also touch Remotes here so the folder exists before any client requires it
require(game.ReplicatedStorage.Shared.net.Remotes)

DataManager.init()
EconomyService.init()
PlacementService.init()
UpgradeService.init()
PrestigeService.init()
MonetizationService.init()
SlotMachineService.init()
