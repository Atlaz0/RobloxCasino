-- Background music: crossfade through sounds placed in SoundService > MusicPlaylist.
-- Add Sound objects to that folder in Studio and set their SoundId to your track asset IDs.

local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local FADE_TIME   = 3    -- seconds for each fade-in / fade-out
local TARGET_VOL  = 0.5

local playlistFolder = SoundService:WaitForChild("MusicPlaylist", 10)
if not playlistFolder then return end  -- folder not set up yet — fail silently

local sounds = {}
for _, s in ipairs(playlistFolder:GetChildren()) do
	if s:IsA("Sound") then
		table.insert(sounds, s)
	end
end
if #sounds == 0 then return end

local function playMusic()
	while true do
		for _, sound in ipairs(sounds) do
			-- Make sure TimeLength is known before we use it.
			if not sound.IsLoaded then
				sound.Loaded:Wait()
			end
			local duration = sound.TimeLength

			sound.Volume = 0
			sound:Play()

			TweenService:Create(sound, TweenInfo.new(FADE_TIME), { Volume = TARGET_VOL }):Play()

			local playTime = duration - FADE_TIME
			if playTime > 0 then
				task.wait(playTime)
			end

			TweenService:Create(sound, TweenInfo.new(FADE_TIME), { Volume = 0 }):Play()
			task.wait(FADE_TIME)
			sound:Stop()
		end
	end
end

task.spawn(playMusic)
