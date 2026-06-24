local Players = game:GetService("Players")

local DataManager    = require(script.Parent.Parent.data.DataManager)
local GameConfig     = require(game.ReplicatedStorage.Shared.constants.GameConfig)
local ProfileTypes   = require(game.ReplicatedStorage.Shared.types.ProfileTypes)
local Remotes        = require(game.ReplicatedStorage.Shared.net.Remotes)

local MIN_PHASE_FOR_PRESTIGE = 3

local function canPrestige(profile: ProfileTypes.PlayerProfile): (boolean, string?)
	if profile.phase < MIN_PHASE_FOR_PRESTIGE then
		return false, "Reach Phase 3 first"
	end

	local cooldown = GameConfig.PRESTIGE_COOLDOWN
	if not profile.hasInfiniteRebirth then
		local elapsed = os.time() - profile.lastPrestigeTime
		if elapsed < cooldown then
			return false, string.format("Cooldown: %ds remaining", cooldown - elapsed)
		end
	end

	return true, nil
end

local function prestige(player: Player): (boolean, string?)
	local profile = DataManager.get(player)
	if not profile then return false, "Profile not loaded" end

	local ok, reason = canPrestige(profile)
	if not ok then return false, reason end

	-- Reset floor but keep prestige perks
	profile.machines = {}
	profile.chips = GameConfig.STARTING_CHIPS
	profile.phase = 1
	profile.casinoRating = 1
	profile.staff = {}
	profile.boosts = {}

	-- Increment prestige
	profile.prestigeLevel += 1
	profile.prestigeMultiplier = 1 + profile.prestigeLevel * GameConfig.PRESTIGE_MULTIPLIER_STEP
	profile.lastPrestigeTime = os.time()

	DataManager.markDirty(player)
	return true, nil
end

local function init()
	Remotes.RequestPrestige:Connect(function(player)
		local ok, reason = prestige(player)
		Remotes.PrestigeResult:FireClient(player, ok, reason)
	end)
end

return {
	init     = init,
	prestige = prestige,
	canPrestige = canPrestige,
}
