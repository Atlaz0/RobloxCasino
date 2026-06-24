local MarketplaceService = game:GetService("MarketplaceService")
local PolicyService      = game:GetService("PolicyService")
local Players            = game:GetService("Players")

local DataManager = require(script.Parent.Parent.data.DataManager)
local GameConfig  = require(game.ReplicatedStorage.Shared.constants.GameConfig)
local Remotes     = require(game.ReplicatedStorage.Shared.net.Remotes)

-- Gamepass ownership cache (avoid repeated API calls per session)
local passCache: { [number]: { [number]: boolean } } = {}

local function ownsPass(player: Player, passId: number): boolean
	passCache[player.UserId] = passCache[player.UserId] or {}
	if passCache[player.UserId][passId] ~= nil then
		return passCache[player.UserId][passId]
	end
	local ok, result = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, passId)
	local owns = ok and result or false
	passCache[player.UserId][passId] = owns
	return owns
end

local function syncPassesToProfile(player: Player)
	local profile = DataManager.get(player)
	if not profile then return end

	local gp = GameConfig.GAMEPASSES
	profile.hasVIPManager      = ownsPass(player, gp.VIPManager)
	profile.hasAutoCollector   = ownsPass(player, gp.AutoCollector)
	profile.hasExtraLot        = ownsPass(player, gp.ExtraLot)
	profile.hasHighRollerRoom  = ownsPass(player, gp.HighRollerRoom)
	profile.hasInfiniteRebirth = ownsPass(player, gp.InfiniteRebirth)
	profile.hasNeonSkinPack    = ownsPass(player, gp.NeonSkinPack)
	DataManager.markDirty(player)
end

-- Weighted random pick from an outcomes table
local function weightedPick(outcomes: { { weight: number, [string]: any } })
	local total = 0
	for _, o in outcomes do total += o.weight end
	local roll = math.random() * total
	local cumulative = 0
	for _, o in outcomes do
		cumulative += o.weight
		if roll <= cumulative then return o end
	end
	return outcomes[#outcomes]
end

-- Loot case handler (called via RemoteFunction from client)
local function handleLootCase(player: Player, caseId: string): { success: boolean, reward: string?, reason: string? }
	local caseDef = GameConfig.LOOT_CASES[caseId]
	if not caseDef then
		return { success = false, reason = "Unknown case" }
	end

	-- Compliance: check if player can use paid random items
	local ok, policy = pcall(function()
		return PolicyService:GetPolicyInfoForPlayerAsync(player)
	end)
	if not ok or policy.AreRandomItemsRestricted then
		return { success = false, reason = "Not available in your region" }
	end

	local profile = DataManager.get(player)
	if not profile then
		return { success = false, reason = "Profile not loaded" }
	end

	if profile.goldChips < caseDef.cost then
		return { success = false, reason = "Not enough Gold Chips" }
	end

	profile.goldChips -= caseDef.cost
	local outcome = weightedPick(caseDef.outcomes)

	-- Apply reward
	if outcome.id:find("^Chips_") then
		local amount = tonumber(outcome.id:match("Chips_(%d+)")) or 0
		profile.chips += amount
	end
	-- Other reward types (skins, staff) handled by their respective services

	DataManager.markDirty(player)
	return { success = true, reward = outcome.id }
end

-- Developer product (Gold Chips bundles, boosts)
local CHIP_AMOUNTS: { [number]: number } = {}

local function buildChipAmounts()
	local p = GameConfig.PRODUCTS
	CHIP_AMOUNTS[p.GoldChips_80]   = 80
	CHIP_AMOUNTS[p.GoldChips_400]  = 400
	CHIP_AMOUNTS[p.GoldChips_1200] = 1200
	CHIP_AMOUNTS[p.GoldChips_2800] = 2800
end

local BOOST_DATA: { [number]: { multiplier: number, duration: number } } = {}

local function buildBoostData()
	local p = GameConfig.PRODUCTS
	BOOST_DATA[p.Boost_2x_15m]  = { multiplier = 2,  duration = 15 * 60 }
	BOOST_DATA[p.Boost_5x_30m]  = { multiplier = 5,  duration = 30 * 60 }
	BOOST_DATA[p.Boost_10x_60m] = { multiplier = 10, duration = 60 * 60 }
end

local function init()
	buildChipAmounts()
	buildBoostData()

	-- Grant gamepasses when purchased mid-session
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, wasPurchased)
		if wasPurchased then
			passCache[player.UserId] = passCache[player.UserId] or {}
			passCache[player.UserId][passId] = true
			syncPassesToProfile(player)
		end
	end)

	-- Process developer products
	MarketplaceService.ProcessReceipt = function(info)
		local player = Players:GetPlayerByUserId(info.PlayerId)
		if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end

		local profile = DataManager.get(player)
		if not profile then return Enum.ProductPurchaseDecision.NotProcessedYet end

		local goldAmount = CHIP_AMOUNTS[info.ProductId]
		if goldAmount then
			profile.goldChips += goldAmount
			DataManager.markDirty(player)
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end

		local boostData = BOOST_DATA[info.ProductId]
		if boostData then
			table.insert(profile.boosts, {
				multiplier = boostData.multiplier,
				expiresAt  = os.time() + boostData.duration,
			})
			DataManager.markDirty(player)
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end

		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Load gamepasses for joining players
	Players.PlayerAdded:Connect(function(player)
		task.wait(1) -- let DataManager load profile first
		syncPassesToProfile(player)
	end)

	-- Loot case remote
	Remotes.RequestLootCase.OnServerInvoke = function(player, caseId)
		if type(caseId) ~= "string" then return { success = false, reason = "Invalid" } end
		return handleLootCase(player, caseId)
	end
end

return { init = init }
