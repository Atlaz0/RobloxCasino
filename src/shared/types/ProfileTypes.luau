-- Player data schema. Keep this in sync with DataManager defaults.

export type MachineInstance = {
	uid: string,      -- unique id, used to identify a placed machine for pickup/sell
	id: string,       -- MachineData key e.g. "SlotMachine"
	level: number,
	x: number,        -- plot-relative offset (DataStore-serializable; no CFrame)
	z: number,
}

export type InventoryItem = {
	id: string,       -- MachineData key
	level: number,
}

export type StaffSlot = {
	staffId: string,
	level: number,
}

export type BoostEntry = {
	multiplier: number,
	expiresAt: number,  -- os.time()
}

export type PlayerProfile = {
	-- Currency
	chips: number,
	goldChips: number,
	totalChipsEarned: number,   -- lifetime, for leaderboard

	-- Progression
	prestigeLevel: number,
	prestigeMultiplier: number,
	lastPrestigeTime: number,   -- os.time()
	phase: number,              -- 1/2/3

	-- Casino floor
	machines: { MachineInstance },
	inventory: { InventoryItem }, -- machines picked up off the floor, ready to re-place/sell
	casinoRating: number,       -- 1–5

	-- Staff
	staff: { StaffSlot },

	-- Gamepasses (cached server-side)
	hasVIPManager: boolean,
	hasAutoCollector: boolean,
	hasExtraLot: boolean,
	hasHighRollerRoom: boolean,
	hasInfiniteRebirth: boolean,
	hasNeonSkinPack: boolean,

	-- Active boosts
	boosts: { BoostEntry },

	-- Engagement
	lastDailyBonusTime: number,  -- os.time()
	dailyBonusStreak: number,

	-- Meta
	version: number,
}

-- Default values for a new player
local function newProfile(): PlayerProfile
	return {
		chips = 100,
		goldChips = 0,
		totalChipsEarned = 0,

		prestigeLevel = 0,
		prestigeMultiplier = 1.0,
		lastPrestigeTime = 0,
		phase = 1,

		machines = {},
		inventory = {},
		casinoRating = 1,

		staff = {},

		hasVIPManager = false,
		hasAutoCollector = false,
		hasExtraLot = false,
		hasHighRollerRoom = false,
		hasInfiniteRebirth = false,
		hasNeonSkinPack = false,

		boosts = {},

		lastDailyBonusTime = 0,
		dailyBonusStreak = 0,

		version = 1,
	}
end

return {
	newProfile = newProfile,
}
