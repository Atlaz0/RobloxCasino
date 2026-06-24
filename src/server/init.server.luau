-- Boot order matters: Data first, then Economy, then everything else.
local DataManager         = require(script.Parent.data.DataManager)
local EconomyService      = require(script.Parent.economy.EconomyService)
local PlacementService    = require(script.Parent.systems.PlacementService)
local UpgradeService      = require(script.Parent.systems.UpgradeService)
local PrestigeService     = require(script.Parent.systems.PrestigeService)
local MonetizationService = require(script.Parent.systems.MonetizationService)

-- Also touch Remotes here so the folder exists before any client requires it
require(game.ReplicatedStorage.Shared.net.Remotes)

DataManager.init()
EconomyService.init()
PlacementService.init()
UpgradeService.init()
PrestigeService.init()
MonetizationService.init()
