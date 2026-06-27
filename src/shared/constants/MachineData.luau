-- Defines every placeable casino game/machine.
-- incomePerSecond is the BASE rate before upgrades/multipliers.
-- `modelName` is matched (case/space-insensitive) against a model in ReplicatedStorage.Machines
-- (synced from assets/machines/*.rbxm) — the filename IS the modelName. See MachineModel.luau.
-- NOTE: world decoration models live separately in ServerStorage.Assets (assets/models/).

export type MachineDefinition = {
	id: string,
	displayName: string,
	description: string,
	cost: number,          -- chips to place
	incomePerSecond: number,
	modelName: string,     -- ReplicatedStorage.Machines model (= assets/machines/<name>.rbxm)
	phase: number,         -- 1/2/3 — which progression phase unlocks it
	maxLevel: number,
	upgradeCostMultiplier: number,  -- each level costs cost * multiplier^level
	incomeMultiplierPerLevel: number,
}

local machines: { [string]: MachineDefinition } = {

	SlotMachine = {
		id = "SlotMachine",
		displayName = "Slot Machine",
		description = "The bread and butter. Flashy lights, steady income.",
		cost = 100,
		incomePerSecond = 2,
		modelName = "SlotMachine",
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
		modelName = "RouletteTable",
		phase = 1,
		maxLevel = 10,
		upgradeCostMultiplier = 1.9,
		incomeMultiplierPerLevel = 0.28,
	},

	PokerTable = {
		id = "PokerTable",
		displayName = "Poker Table",
		description = "Texas hold'em with the high-rollers.",
		cost = 1500,
		incomePerSecond = 18,
		modelName = "PokerTable",
		phase = 1,
		maxLevel = 10,
		upgradeCostMultiplier = 2.0,
		incomeMultiplierPerLevel = 0.30,
	},

	BlackjackTable = {
		id = "BlackjackTable",
		displayName = "Blackjack Table",
		description = "Hit or stand — the dealer's busiest table.",
		cost = 4000,
		incomePerSecond = 40,
		modelName = "BlackjackTable",
		phase = 1,
		maxLevel = 10,
		upgradeCostMultiplier = 2.1,
		incomeMultiplierPerLevel = 0.32,
	},
}

return machines
