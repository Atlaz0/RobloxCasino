-- Defines every placeable machine/building.
-- incomePerSecond is the BASE rate before upgrades/multipliers.

export type MachineDefinition = {
	id: string,
	displayName: string,
	description: string,
	cost: number,          -- chips to place
	incomePerSecond: number,
	modelName: string,     -- ServerStorage model name
	phase: number,         -- 1/2/3 — which progression phase unlocks it
	maxLevel: number,
	upgradeCostMultiplier: number,  -- each level costs cost * multiplier^level
	incomeMultiplierPerLevel: number,
}

local machines: { [string]: MachineDefinition } = {

	-- Phase 1 — The Floor
	SlotMachine = {
		id = "SlotMachine",
		displayName = "Slot Machine",
		description = "The bread and butter. Flashy lights, steady income.",
		cost = 100,
		incomePerSecond = 2,
		modelName = "Model_SlotMachine",
		phase = 1,
		maxLevel = 10,
		upgradeCostMultiplier = 1.8,
		incomeMultiplierPerLevel = 0.25,
	},

	RouletteTable = {
		id = "RouletteTable",
		displayName = "Roulette Table",
		description = "Spin the wheel. More income, more floor space.",
		cost = 500,
		incomePerSecond = 8,
		modelName = "Model_RouletteTable",
		phase = 1,
		maxLevel = 10,
		upgradeCostMultiplier = 1.9,
		incomeMultiplierPerLevel = 0.28,
	},

	CardTable = {
		id = "CardTable",
		displayName = "Card Table",
		description = "Blackjack, poker — the classics.",
		cost = 1200,
		incomePerSecond = 18,
		modelName = "Model_CardTable",
		phase = 1,
		maxLevel = 10,
		upgradeCostMultiplier = 2.0,
		incomeMultiplierPerLevel = 0.30,
	},

	-- Phase 2 — The Resort
	HotelWing = {
		id = "HotelWing",
		displayName = "Hotel Wing",
		description = "Guests stay longer. Big income multiplier for the whole floor.",
		cost = 25000,
		incomePerSecond = 80,
		modelName = "Model_HotelWing",
		phase = 2,
		maxLevel = 5,
		upgradeCostMultiplier = 2.5,
		incomeMultiplierPerLevel = 0.40,
	},

	Restaurant = {
		id = "Restaurant",
		displayName = "Restaurant",
		description = "Keep the high-rollers fed.",
		cost = 15000,
		incomePerSecond = 45,
		modelName = "Model_Restaurant",
		phase = 2,
		maxLevel = 5,
		upgradeCostMultiplier = 2.2,
		incomeMultiplierPerLevel = 0.35,
	},

	VIPLounge = {
		id = "VIPLounge",
		displayName = "VIP Lounge",
		description = "Exclusive access. Attracts high-roller visitors.",
		cost = 50000,
		incomePerSecond = 150,
		modelName = "Model_VIPLounge",
		phase = 2,
		maxLevel = 5,
		upgradeCostMultiplier = 2.8,
		incomeMultiplierPerLevel = 0.50,
	},

	ParkingGarage = {
		id = "ParkingGarage",
		displayName = "Parking Garage",
		description = "More visitors = more income.",
		cost = 8000,
		incomePerSecond = 25,
		modelName = "Model_ParkingGarage",
		phase = 2,
		maxLevel = 5,
		upgradeCostMultiplier = 2.0,
		incomeMultiplierPerLevel = 0.20,
	},

	-- Phase 3 — The Strip (prestige-locked)
	HighRollerRoom = {
		id = "HighRollerRoom",
		displayName = "High Roller Room",
		description = "For the elite. Massive income, prestige-only unlock.",
		cost = 500000,
		incomePerSecond = 1000,
		modelName = "Model_HighRollerRoom",
		phase = 3,
		maxLevel = 3,
		upgradeCostMultiplier = 3.0,
		incomeMultiplierPerLevel = 0.60,
	},
}

return machines
