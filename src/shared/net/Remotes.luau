-- Single source of truth for all RemoteEvents and RemoteFunctions.
-- Server creates them; client requires this module to get references.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local IS_SERVER = game:GetService("RunService"):IsServer()

local function getOrCreate(parent: Instance, className: string, name: string): Instance
	local existing = parent:FindFirstChild(name)
	if existing then return existing end
	assert(IS_SERVER, "Remote '" .. name .. "' must be created by the server first")
	local inst = Instance.new(className)
	inst.Name = name
	inst.Parent = parent
	return inst
end

local folder = IS_SERVER
	and (ReplicatedStorage:FindFirstChild("Remotes") or (function()
		local f = Instance.new("Folder")
		f.Name = "Remotes"
		f.Parent = ReplicatedStorage
		return f
	end)())
	or ReplicatedStorage:WaitForChild("Remotes", 10)

local function Event(name: string): RemoteEvent
	return getOrCreate(folder, "RemoteEvent", name) :: RemoteEvent
end

local function Func(name: string): RemoteFunction
	return getOrCreate(folder, "RemoteFunction", name) :: RemoteFunction
end

return {
	-- Economy
	ChipsUpdated       = Event("ChipsUpdated"),       -- server → client: (newTotal: number)
	IncomeRateUpdated  = Event("IncomeRateUpdated"),  -- server → client: (perSecond: number)

	-- Placement
	RequestPlace       = Event("RequestPlace"),       -- client → server: (machineId: string, cf: CFrame)
	PlacementResult    = Event("PlacementResult"),    -- server → client: (success: bool, reason: string?)

	-- Plots
	PlotAssigned       = Event("PlotAssigned"),       -- server → client: ({ claimed, center?, halfSize?, topY? })

	-- Upgrades
	RequestUpgrade     = Event("RequestUpgrade"),     -- client → server: (upgradeId: string)
	UpgradeResult      = Event("UpgradeResult"),      -- server → client: (success: bool, reason: string?)

	-- Prestige
	RequestPrestige    = Event("RequestPrestige"),    -- client → server
	PrestigeResult     = Event("PrestigeResult"),     -- server → client: (success: bool)

	-- Leaderboard
	LeaderboardUpdated = Event("LeaderboardUpdated"), -- server → all clients: (data: {})

	-- Daily reward
	RequestDailyReward = Func("RequestDailyReward"),  -- client → server: () → { success, reward?, reason?, status }
	RequestDailyStatus = Func("RequestDailyStatus"),  -- client → server: () → status (pull current status on load)
	DailyRewardStatus  = Event("DailyRewardStatus"),  -- server → client: (status: { canClaim, secondsRemaining, streak, nextReward })

	-- Monetization
	RequestLootCase    = Func("RequestLootCase"),     -- client → server: (caseId) → result
}
