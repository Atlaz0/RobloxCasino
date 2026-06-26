<<<<<<< HEAD
-- Boot order matters: Data first, then Economy, then everything else.
local DataManager         = require(script.data.DataManager)
local EconomyService      = require(script.economy.EconomyService)
local PlacementService    = require(script.systems.PlacementService)
local UpgradeService      = require(script.systems.UpgradeService)
local PrestigeService     = require(script.systems.PrestigeService)
local MonetizationService = require(script.systems.MonetizationService)
local SlotMachineService  = require(script.systems.SlotMachineService)
=======
-- Boot order matters: World first, then Data, then Economy, then everything else.
local WorldService          = require(script.systems.WorldService)
local PlotService           = require(script.systems.PlotService)
local FountainService       = require(script.systems.FountainService)
local DataManager           = require(script.data.DataManager)
local EconomyService        = require(script.economy.EconomyService)
local PlacementService      = require(script.systems.PlacementService)
local UpgradeService        = require(script.systems.UpgradeService)
local PrestigeService       = require(script.systems.PrestigeService)
local MonetizationService   = require(script.systems.MonetizationService)
local DailyRewardService    = require(script.systems.DailyRewardService)
>>>>>>> 19b3fbb93fc4996a7899dc319aa85775a4c31a66

-- Also touch Remotes here so the folder exists before any client requires it
require(game.ReplicatedStorage.Shared.net.Remotes)

-- World + spawn area first (Fountain needs the spawn & plaza to exist).
WorldService.init()
PlotService.init()
FountainService.init()

DataManager.init()
EconomyService.init()
PlacementService.init()
UpgradeService.init()
PrestigeService.init()
MonetizationService.init()
<<<<<<< HEAD
SlotMachineService.init()
=======
DailyRewardService.init()
>>>>>>> 19b3fbb93fc4996a7899dc319aa85775a4c31a66
