-- PathGuideController — renders a SMOOTH green guiding path (client-side, per-frame) from
-- the player to the nearest unclaimed plot's doorway. Runs entirely on the client so the
-- chevrons flow fluidly with no replication choppiness. A fixed pool of chevron parts is
-- repositioned each frame and "flows" toward the door; it stops once the player claims.

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

ReplicatedStorage:WaitForChild("Remotes", 15)
local Shared     = ReplicatedStorage:WaitForChild("Shared")
local Remotes    = require(Shared.net.Remotes)
local GameConfig = require(Shared.constants.GameConfig)

local player = Players.LocalPlayer
local W = GameConfig.WORLD

local PATH_Y     = W.PLAZA_TOP_Y + 0.3
local UNIT_COUNT = 18    -- chevrons in the pool
local SPACING    = 8     -- studs between chevrons
local FLOW_SPEED = 16    -- studs/sec the chevrons march toward the door
local ARM_LEN    = 6     -- length of each chevron arm
local STOP_SHORT = 6     -- stop the trail this far before the doorway
local FADE       = 14    -- fade-in/out distance at each end of the trail

local claimed = false
local folder: Folder
local units = {} -- units[i] = { Part, Part }

local function ensureParts()
	if folder then return end
	folder = Instance.new("Folder")
	folder.Name = "GuidePath_Local"
	folder.Parent = workspace

	for i = 1, UNIT_COUNT do
		local bars = {}
		for b = 1, 2 do
			local bar = Instance.new("Part")
			bar.Anchored = true
			bar.CanCollide = false
			bar.CanQuery = false
			bar.CanTouch = false
			bar.CastShadow = false
			bar.Material = Enum.Material.Neon
			bar.BrickColor = BrickColor.new("Lime green")
			bar.Size = Vector3.new(1.4, 0.2, ARM_LEN)
			bar.Transparency = 1
			bar.Parent = folder
			bars[b] = bar
		end
		units[i] = bars
	end
end

local function hideAll()
	for _, bars in units do
		bars[1].Transparency = 1
		bars[2].Transparency = 1
	end
end

local function flatXZ(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

local function getFreePlots(): { Model }
	local free = {}
	local plotsFolder = workspace:FindFirstChild("Plots")
	if not plotsFolder then return free end
	for _, plot in plotsFolder:GetChildren() do
		if plot:IsA("Model") and plot:GetAttribute("Occupied") == false then
			table.insert(free, plot)
		end
	end
	return free
end

local function claimPoint(plot: Model): Vector3
	local cp = plot:GetAttribute("ClaimPoint")
	if typeof(cp) == "Vector3" then
		return cp
	end
	return plot:GetPivot().Position
end

local function nearestFreePlot(fromPos: Vector3): Model?
	local best, bestDist
	for _, plot in getFreePlots() do
		local d = (flatXZ(claimPoint(plot)) - flatXZ(fromPos)).Magnitude
		if not bestDist or d < bestDist then
			best, bestDist = plot, d
		end
	end
	return best
end

-- Positions a 2-bar ">" chevron at `pos` pointing along `dir`, at the given transparency.
local function placeChevron(bars, pos: Vector3, dir: Vector3, transparency: number)
	local base = CFrame.lookAt(pos, pos + dir)
	local right = base.RightVector
	local back = -dir
	for b, sign in { 1, -1 } do
		local armDir = (back + right * sign).Unit
		local center = pos + armDir * (ARM_LEN / 2)
		bars[b].CFrame = CFrame.lookAt(center, center + armDir)
		bars[b].Transparency = transparency
	end
end

local function update()
	if claimed then
		hideAll()
		return
	end

	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		hideAll()
		return
	end

	local plot = nearestFreePlot(hrp.Position)
	if not plot then
		hideAll()
		return
	end

	local start = flatXZ(hrp.Position)
	local target = flatXZ(claimPoint(plot))
	local toTarget = target - start
	local dist = toTarget.Magnitude
	if dist < 2 then
		hideAll()
		return
	end
	local dir = toTarget.Unit

	-- A periodic flow offset (period = SPACING) makes the whole chevron pattern scroll
	-- toward the door seamlessly.
	local flow = (os.clock() * FLOW_SPEED) % SPACING
	local maxD = dist - STOP_SHORT

	for i, bars in units do
		local d = (i - 1) * SPACING + flow
		if d >= 2 and d <= maxD then
			-- Fade in near the player, fade out near the door.
			local alpha = 1
			if d < FADE then
				alpha = d / FADE
			end
			if maxD - d < FADE then
				alpha = math.min(alpha, (maxD - d) / FADE)
			end
			local transparency = 1 - math.clamp(alpha, 0, 1) * 0.85
			local pos = start + dir * d
			placeChevron(bars, Vector3.new(pos.X, PATH_Y, pos.Z), dir, transparency)
		else
			bars[1].Transparency = 1
			bars[2].Transparency = 1
		end
	end
end

local function init()
	ensureParts()

	-- The server tells us when we own a plot; stop guiding then.
	Remotes.PlotAssigned.OnClientEvent:Connect(function(info)
		claimed = info ~= nil and info.claimed == true
		if claimed then
			hideAll()
		end
	end)

	RunService.RenderStepped:Connect(update)
end

return {
	init = init,
}
