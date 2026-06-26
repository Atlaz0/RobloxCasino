local GameConfig = {}

-- World layout (shared so roads, plots, and placement all agree on geometry)
GameConfig.WORLD = {
	GROUND_TOP_Y  = 0,    -- world Y of the grass surface
	PLAZA_TOP_Y   = 1,    -- world Y of the raised stone plaza/road surface
	PLAZA_RADIUS  = 70,   -- central spawn plaza radius
	ROAD_WIDTH    = 44,   -- width of each of the 4 roads
	ROAD_LENGTH   = 280,  -- length of each road from plaza edge to its plot
	PLOT_SIZE     = 150,  -- side length of each square tycoon plot
	PLOT_COUNT    = 4,    -- one plot at the end of each road (+X, -X, +Z, -Z)
}

-- Center distance from world origin to each plot center.
function GameConfig.plotCenterDistance(): number
	local W = GameConfig.WORLD
	return W.PLAZA_RADIUS + W.ROAD_LENGTH + W.PLOT_SIZE / 2
end

-- Unit direction (Vector3 on the XZ plane) for plot index 1..4.
function GameConfig.plotDirection(index: number): Vector3
	local dirs = {
		Vector3.new(1, 0, 0),
		Vector3.new(-1, 0, 0),
		Vector3.new(0, 0, 1),
		Vector3.new(0, 0, -1),
	}
	return dirs[index] or dirs[1]
end

-- Economy
GameConfig.PASSIVE_INCOME_INTERVAL = 1        -- seconds between income ticks
GameConfig.STARTING_CHIPS           = 100
GameConfig.MAX_LOT_MACHINES         = 50

<<<<<<< HEAD
-- Manual starter slot machine (active income — press to earn)
GameConfig.MANUAL_SLOT_REWARD       = 2        -- chips per spin (guaranteed)
GameConfig.MANUAL_SLOT_JACKPOT      = 50       -- bonus chips when all 3 reels match
GameConfig.MANUAL_SLOT_COOLDOWN     = 0.25     -- seconds between presses per player
=======
-- Placement / machine management
GameConfig.MACHINE_MIN_SPACING   = 1   -- min gap (studs) between machine bounding boxes
GameConfig.SELL_REFUND_FRACTION  = 0.5 -- chips back when selling a machine, as a fraction of cost

-- Chips refunded for selling a machine of the given definition.
function GameConfig.machineSellValue(def): number
	return math.floor(def.cost * GameConfig.SELL_REFUND_FRACTION)
end
>>>>>>> 19b3fbb93fc4996a7899dc319aa85775a4c31a66

-- Prestige
GameConfig.PRESTIGE_COOLDOWN        = 300      -- seconds
GameConfig.PRESTIGE_MULTIPLIER_STEP = 0.10     -- +10% per prestige level

-- Leaderboard
GameConfig.LEADERBOARD_UPDATE_INTERVAL = 10   -- seconds
GameConfig.LEADERBOARD_SIZE            = 10

-- Rival challenge
GameConfig.RIVAL_DURATION = 600               -- 10 minutes in seconds

-- Daily reward (claimable once per 24h; streak grows on consecutive days)
GameConfig.DAILY_REWARD = {
	COOLDOWN            = 24 * 60 * 60, -- seconds before the reward can be claimed again
	STREAK_RESET_WINDOW = 48 * 60 * 60, -- claim within this window to keep the streak; else it resets
	BASE_CHIPS          = 1000,         -- day-1 reward
	STREAK_BONUS_CHIPS  = 750,          -- added per consecutive day
	MAX_STREAK          = 7,            -- streak (and bonus) caps here
}

-- Reward amount for a given streak day (day 1 = streak 1).
function GameConfig.dailyRewardForStreak(streak: number): number
	local capped = math.clamp(streak, 1, GameConfig.DAILY_REWARD.MAX_STREAK)
	return GameConfig.DAILY_REWARD.BASE_CHIPS + (capped - 1) * GameConfig.DAILY_REWARD.STREAK_BONUS_CHIPS
end

-- Daily bonus wheel
GameConfig.BONUS_WHEEL_BASE_REWARDS = {
	{ weight = 40, chips = 500 },
	{ weight = 30, chips = 1500 },
	{ weight = 15, chips = 5000 },
	{ weight = 10, chips = 15000 },
	{ weight = 4,  chips = 50000 },
	{ weight = 1,  chips = 250000 },
}

-- Loot case drop odds (shown to player before purchase — compliance requirement)
GameConfig.LOOT_CASES = {
	StandardCase = {
		cost = 80, -- Gold Chips
		outcomes = {
			{ id = "FloorSkin_MonteCarlo",  weight = 5,  displayOdds = "5%" },
			{ id = "Staff_LuckyLou",        weight = 10, displayOdds = "10%" },
			{ id = "Effect_Confetti",       weight = 25, displayOdds = "25%" },
			{ id = "Chips_5000",            weight = 60, displayOdds = "60%" },
		},
	},
}

-- Game passes (ProductId placeholders — replace with real IDs before publish)
GameConfig.GAMEPASSES = {
	VIPManager      = 0,
	AutoCollector   = 0,
	ExtraLot        = 0,
	HighRollerRoom  = 0,
	InfiniteRebirth = 0,
	NeonSkinPack    = 0,
}

-- Developer products (consumables)
GameConfig.PRODUCTS = {
	GoldChips_80   = 0,
	GoldChips_400  = 0,
	GoldChips_1200 = 0,
	GoldChips_2800 = 0,
	Boost_2x_15m   = 0,
	Boost_5x_30m   = 0,
	Boost_10x_60m  = 0,
}

return GameConfig
