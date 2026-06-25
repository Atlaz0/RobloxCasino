local GameConfig = {}

-- Economy
GameConfig.PASSIVE_INCOME_INTERVAL = 1        -- seconds between income ticks
GameConfig.STARTING_CHIPS           = 100
GameConfig.MAX_LOT_MACHINES         = 50

-- Manual starter slot machine (active income — press to earn)
GameConfig.MANUAL_SLOT_REWARD       = 2        -- chips per spin (guaranteed)
GameConfig.MANUAL_SLOT_JACKPOT      = 50       -- bonus chips when all 3 reels match
GameConfig.MANUAL_SLOT_COOLDOWN     = 0.25     -- seconds between presses per player

-- Prestige
GameConfig.PRESTIGE_COOLDOWN        = 300      -- seconds
GameConfig.PRESTIGE_MULTIPLIER_STEP = 0.10     -- +10% per prestige level

-- Leaderboard
GameConfig.LEADERBOARD_UPDATE_INTERVAL = 10   -- seconds
GameConfig.LEADERBOARD_SIZE            = 10

-- Rival challenge
GameConfig.RIVAL_DURATION = 600               -- 10 minutes in seconds

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
