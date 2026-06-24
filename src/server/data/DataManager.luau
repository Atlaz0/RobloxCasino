local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ProfileTypes = require(game.ReplicatedStorage.Shared.types.ProfileTypes)
local GameConfig   = require(game.ReplicatedStorage.Shared.constants.GameConfig)

local DATASTORE_KEY_PREFIX = "Player_v1_"
local AUTO_SAVE_INTERVAL   = 60 -- seconds

local store = DataStoreService:GetDataStore("CasinoEmpire_v1")

local profiles: { [number]: ProfileTypes.PlayerProfile } = {}
local dirty: { [number]: boolean } = {}

local function load(player: Player): ProfileTypes.PlayerProfile
	local key = DATASTORE_KEY_PREFIX .. player.UserId
	local data

	local ok, err = pcall(function()
		data = store:GetAsync(key)
	end)

	if not ok then
		warn("DataManager: load failed for", player.Name, err)
	end

	local profile: ProfileTypes.PlayerProfile = data or ProfileTypes.newProfile()

	-- migrate old saves: add missing keys from newProfile default
	local defaults = ProfileTypes.newProfile()
	for k, v in pairs(defaults) do
		if profile[k] == nil then
			profile[k] = v
		end
	end

	profiles[player.UserId] = profile
	dirty[player.UserId] = false
	return profile
end

local function save(player: Player)
	local profile = profiles[player.UserId]
	if not profile then return end

	local key = DATASTORE_KEY_PREFIX .. player.UserId
	local ok, err = pcall(function()
		store:SetAsync(key, profile)
	end)

	if not ok then
		warn("DataManager: save failed for", player.Name, err)
	else
		dirty[player.UserId] = false
	end
end

local function get(player: Player): ProfileTypes.PlayerProfile?
	return profiles[player.UserId]
end

local function markDirty(player: Player)
	dirty[player.UserId] = true
end

local function init()
	Players.PlayerAdded:Connect(function(player)
		load(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		save(player)
		profiles[player.UserId] = nil
		dirty[player.UserId] = nil
	end)

	-- Load any players already in-game (Studio test mode)
	for _, player in Players:GetPlayers() do
		load(player)
	end

	-- Auto-save loop
	task.spawn(function()
		while true do
			task.wait(AUTO_SAVE_INTERVAL)
			for _, player in Players:GetPlayers() do
				if dirty[player.UserId] then
					save(player)
				end
			end
		end
	end)

	-- Save all on server close
	game:BindToClose(function()
		for _, player in Players:GetPlayers() do
			save(player)
		end
	end)
end

return {
	init      = init,
	get       = get,
	save      = save,
	markDirty = markDirty,
}
