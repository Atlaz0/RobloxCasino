-- The manual starter slot machine.
-- Dome-top shape inspired by classic "Lucky" toy slot aesthetic.
-- Press the ProximityPrompt → lever pulls → reels roll with tick sounds → earn chips.

local Workspace    = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local Shared         = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig     = require(Shared.constants.GameConfig)
local EconomyService = require(script.Parent.Parent.economy.EconomyService)

local REWARD         = GameConfig.MANUAL_SLOT_REWARD
local JACKPOT        = GameConfig.MANUAL_SLOT_JACKPOT
local MACHINE_CFRAME = CFrame.new(0, 2.6, -10)
local ALL_SYMBOLS    = { "7", "A", "$", "K", "Q", "J" }
local TEXT_COLORS    = {
	["7"] = Color3.fromRGB(200, 30, 45),
	["A"] = Color3.fromRGB(40, 90, 200),
	["$"] = Color3.fromRGB(40, 160, 70),
}

-- Reel rolling geometry (in SurfaceGui pixels)
local CELL_H       = 120
local CELL_W       = 76
local NUM_CELLS    = 15
local TARGET_INDEX = 1
local ROLL_CELLS   = 12
local END_Y        = -TARGET_INDEX * CELL_H
local START_Y      = END_Y - ROLL_CELLS * CELL_H

local GOLD   = Color3.fromRGB(214, 175, 60)
local MAROON = Color3.fromRGB(110, 18, 28)
local SILVER = Color3.fromRGB(165, 165, 170)

local debounce: { [Player]: boolean } = {}

local cabinet: Part
local marqueeLight: Part
local knob: Part
local leverArm: Part
local jackpotLight: PointLight
local sparkles: ParticleEmitter
local spinSound: Sound
local winSound: Sound
local tickSound: Sound
local reelWindows: { Frame } = {}

local leverRestCF: CFrame
local leverPulledCF: CFrame

local onSpin: (player: Player) -> ()

-- ── Part helpers ──────────────────────────────────────────────────────────────

local function part(model: Model, name: string, size: Vector3, pos: Vector3, color: Color3, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Position = pos
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.Parent = model
	return p
end

-- For parts that need a rotation (angled screen, dome cylinder)
local function partCF(model: Model, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.Parent = model
	return p
end

-- ── Crown icon drawing (K / Q / J reel symbols) ──────────────────────────────

local function diamond(parent: Instance, size: number, posX: number, posYc: number, color: Color3, z: number)
	local d = Instance.new("Frame")
	d.AnchorPoint = Vector2.new(0.5, 0.5)
	d.Position = UDim2.new(0.5, posX, 0, posYc)
	d.Size = UDim2.fromOffset(size, size)
	d.Rotation = 45
	d.BackgroundColor3 = color
	d.BorderSizePixel = 0
	d.ZIndex = z
	d.Parent = parent
end

local function band(parent: Instance, w: number, h: number, posYc: number, color: Color3, z: number)
	local b = Instance.new("Frame")
	b.AnchorPoint = Vector2.new(0.5, 0.5)
	b.Position = UDim2.new(0.5, 0, 0, posYc)
	b.Size = UDim2.fromOffset(w, h)
	b.BackgroundColor3 = color
	b.BorderSizePixel = 0
	b.ZIndex = z
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 3); c.Parent = b
	b.Parent = parent
end

local function jewel(parent: Instance, size: number, posYc: number, color: Color3, z: number)
	local j = Instance.new("Frame")
	j.AnchorPoint = Vector2.new(0.5, 0.5)
	j.Position = UDim2.new(0.5, 0, 0, posYc)
	j.Size = UDim2.fromOffset(size, size)
	j.BackgroundColor3 = color
	j.BorderSizePixel = 0
	j.ZIndex = z
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = j
	j.Parent = parent
end

local function buildKing(c: Frame)
	local gold = Color3.fromRGB(255, 205, 60)
	diamond(c, 30, 0, 42, gold, 2)
	diamond(c, 24, -22, 50, gold, 2)
	diamond(c, 24, 22, 50, gold, 2)
	band(c, 60, 20, 64, Color3.fromRGB(190, 30, 40), 3)
	jewel(c, 12, 64, gold, 4)
end

local function buildQueen(c: Frame)
	local rose = Color3.fromRGB(255, 120, 180)
	diamond(c, 22, -20, 46, rose, 2)
	diamond(c, 22, 0, 46, rose, 2)
	diamond(c, 22, 20, 46, rose, 2)
	band(c, 58, 18, 64, Color3.fromRGB(200, 200, 210), 3)
	jewel(c, 12, 64, rose, 4)
end

local function buildJack(c: Frame)
	local teal = Color3.fromRGB(40, 190, 180)
	diamond(c, 28, 0, 42, teal, 2)
	diamond(c, 16, -20, 52, teal, 2)
	diamond(c, 16, 20, 52, teal, 2)
	band(c, 56, 18, 64, Color3.fromRGB(40, 60, 70), 3)
	jewel(c, 10, 64, teal, 4)
end

local CROWN_BUILDERS = { K = buildKing, Q = buildQueen, J = buildJack }

local function drawSymbol(cell: Frame, id: string)
	local builder = CROWN_BUILDERS[id]
	if builder then
		builder(cell)
		return
	end
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 1
	lbl.Text = id
	lbl.TextColor3 = TEXT_COLORS[id] or Color3.fromRGB(40, 40, 40)
	lbl.Font = Enum.Font.GothamBlack
	lbl.TextScaled = true
	lbl.Parent = cell
end

-- ── Reel strips (rolling) ────────────────────────────────────────────────────

local function makeCell(strip: Frame, idx: number, sym: string)
	local cell = Instance.new("Frame")
	cell.Size = UDim2.fromOffset(CELL_W, CELL_H)
	cell.Position = UDim2.fromOffset(0, idx * CELL_H)
	cell.BackgroundTransparency = 1
	cell.ClipsDescendants = true   -- prevents symbol art overflowing into neighbouring cells
	cell.Parent = strip
	drawSymbol(cell, sym)
end

local function setReelStatic(reelIndex: number, sym: string)
	local window = reelWindows[reelIndex]
	local old = window:FindFirstChild("Strip")
	if old then old:Destroy() end

	local strip = Instance.new("Frame")
	strip.Name = "Strip"
	strip.Size = UDim2.fromOffset(CELL_W, CELL_H)
	strip.Position = UDim2.fromOffset(0, 0)
	strip.BackgroundTransparency = 1
	strip.Parent = window
	makeCell(strip, 0, sym)
end

local function rollReel(reelIndex: number, target: string, duration: number): Tween
	local window = reelWindows[reelIndex]
	local old = window:FindFirstChild("Strip")
	if old then old:Destroy() end

	local strip = Instance.new("Frame")
	strip.Name = "Strip"
	strip.Size = UDim2.fromOffset(CELL_W, NUM_CELLS * CELL_H)
	strip.BackgroundTransparency = 1
	strip.Position = UDim2.fromOffset(0, START_Y)
	strip.Parent = window

	for idx = 0, NUM_CELLS - 1 do
		local sym = (idx == TARGET_INDEX) and target or ALL_SYMBOLS[math.random(#ALL_SYMBOLS)]
		makeCell(strip, idx, sym)
	end

	local tween = TweenService:Create(strip,
		TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
		{ Position = UDim2.fromOffset(0, END_Y) })
	tween:Play()
	return tween
end

-- Plays tick sounds that mimic a decelerating reel
local function tickReels(totalDuration: number)
	task.spawn(function()
		local elapsed = 0
		local interval = 0.07
		while elapsed < totalDuration - 0.25 do
			tickSound:Play()
			task.wait(interval)
			elapsed += interval
			interval = math.min(interval * 1.14, 0.5)
		end
	end)
end

local function spinReels(final: { string }, onComplete: () -> ())
	rollReel(1, final[1], 1.1)
	rollReel(2, final[2], 1.45)
	local last = rollReel(3, final[3], 1.8)
	tickReels(1.8)
	last.Completed:Connect(function()
		onComplete()
	end)
end

-- ── Jackpot odds panel ────────────────────────────────────────────────────────

local function buildJackpotPanel(face: Frame)
	local oddsText = string.format("%.1f%%", 100 / ((#ALL_SYMBOLS) ^ 2))

	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Vertical
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.Padding = UDim.new(0, 2)
	list.Parent = face

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 28)
	title.BackgroundTransparency = 1
	title.Text = "JACKPOT CHANCE"
	title.TextColor3 = Color3.fromRGB(255, 215, 90)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 22
	title.LayoutOrder = 1
	title.Parent = face

	local pct = Instance.new("TextLabel")
	pct.Size = UDim2.new(1, 0, 0, 60)
	pct.BackgroundTransparency = 1
	pct.Text = oddsText .. "!"
	pct.TextColor3 = Color3.fromRGB(255, 255, 255)
	pct.TextStrokeTransparency = 0.2
	pct.TextStrokeColor3 = Color3.fromRGB(120, 20, 0)
	pct.Font = Enum.Font.GothamBlack
	pct.TextSize = 56
	pct.LayoutOrder = 2
	pct.Parent = face

	local sub = Instance.new("TextLabel")
	sub.Size = UDim2.new(1, 0, 0, 44)
	sub.BackgroundTransparency = 1
	sub.Text = "match 3  •  +" .. JACKPOT .. " chips"
	sub.TextColor3 = Color3.fromRGB(255, 200, 160)
	sub.Font = Enum.Font.GothamBold
	sub.TextSize = 30
	sub.LayoutOrder = 3
	sub.Parent = face
end

-- ── Build the machine ─────────────────────────────────────────────────────────
--
-- Shape overview (local space, cabinet PrimaryPart centered at y=0):
--
--   DomeCap   y≈5.2   ← horizontal cylinder = rounded top (dome)
--   Marquee   y≈3.0   ← tall maroon top, wider + stepped back 0.7 from cabinet
--   ──── Brow ledge (gold) bridging the step ────
--   Cabinet   y= 0    ← silver body (PrimaryPart), front face at z=+1.4
--   Base      y≈-2.2  ← dark plinth

local function build(): Model
	local model = Instance.new("Model")
	model.Name = "ManualSlotMachine"

	-- Dark plinth
	part(model, "Base", Vector3.new(5, 0.4, 4.2), Vector3.new(0, -2.2, 0), Color3.fromRGB(28, 24, 30))

	-- Silver lower body (contains screen + panel)
	cabinet = part(model, "Cabinet", Vector3.new(3.4, 4.0, 2.8), Vector3.new(0, 0, 0), SILVER, Enum.Material.Metal)
	model.PrimaryPart = cabinet

	-- Tall maroon marquee — wider and pushed back relative to cabinet
	-- Cabinet front face: z = +1.4 | Marquee front face: z = -0.5+1.2 = +0.7 (0.7 step)
	local marquee = part(model, "Marquee", Vector3.new(4.3, 2.8, 2.4), Vector3.new(0, 2.9, -0.5), MAROON)

	-- Dome cap: horizontal cylinder on top of marquee creates the rounded top silhouette.
	-- Default Roblox cylinder runs along Y; rotating 90° around Z makes it run along X.
	-- After rotation: Size.Y maps to world-X (width=4.3), Size.X/Z map to world-Y/Z (diam=1.8).
	local domeCap = partCF(model, "DomeCap",
		Vector3.new(1.8, 4.3, 1.8),
		CFrame.new(0, 5.2, -0.5) * CFrame.Angles(0, 0, math.rad(90)),
		MAROON)
	domeCap.Shape = Enum.PartType.Cylinder

	-- Gold brow: thin ledge that bridges the step between marquee front and cabinet front
	part(model, "Brow", Vector3.new(4.4, 0.2, 0.85), Vector3.new(0, 1.92, 1.025), GOLD, Enum.Material.Metal)

	-- Neon accent strip at the bottom-front of the marquee
	marqueeLight = part(model, "MarqueeLight", Vector3.new(3.2, 0.18, 0.28),
		Vector3.new(0, 1.56, 0.82), Color3.fromRGB(255, 220, 80), Enum.Material.Neon)

	-- "LUCKY SLOT" title + sub-text on the marquee face
	local mg = Instance.new("SurfaceGui")
	mg.Face = Enum.NormalId.Back
	mg.CanvasSize = Vector2.new(300, 130)
	mg.LightInfluence = 0
	mg.Parent = marquee

	local mTitle = Instance.new("TextLabel")
	mTitle.Size = UDim2.new(1, 0, 0, 78)
	mTitle.Position = UDim2.new(0, 0, 0, 8)
	mTitle.BackgroundTransparency = 1
	mTitle.Text = "LUCKY SLOT"
	mTitle.TextColor3 = Color3.fromRGB(255, 220, 90)
	mTitle.TextStrokeTransparency = 0.2
	mTitle.TextStrokeColor3 = Color3.fromRGB(80, 10, 0)
	mTitle.Font = Enum.Font.GothamBlack
	mTitle.TextScaled = true
	mTitle.Parent = mg

	local mSub = Instance.new("TextLabel")
	mSub.Size = UDim2.new(1, 0, 0, 32)
	mSub.Position = UDim2.new(0, 0, 0, 90)
	mSub.BackgroundTransparency = 1
	mSub.Text = "Hit The Jackpot!"
	mSub.TextColor3 = Color3.fromRGB(255, 160, 170)
	mSub.Font = Enum.Font.GothamBold
	mSub.TextScaled = true
	mSub.Parent = mg

	-- Screen: pushed back from cabinet face and angled 12° toward the player (ergonomic tilt).
	-- CFrame.Angles(+rx, 0, 0): positive rx tilts top of part in +Z direction (toward player).
	local screenAngle = math.rad(12)
	local sfCF = CFrame.new(0, 0.25, 0.95) * CFrame.Angles(screenAngle, 0, 0)
	local ssCF = CFrame.new(0, 0.25, 1.06) * CFrame.Angles(screenAngle, 0, 0)
	partCF(model, "ScreenFrame", Vector3.new(3.0, 2.4, 0.26), sfCF, Color3.fromRGB(235, 195, 70), Enum.Material.Metal)
	local screen = partCF(model, "Screen", Vector3.new(2.56, 1.9, 0.2), ssCF, Color3.fromRGB(15, 12, 10))

	-- Jackpot odds panel (lower cabinet, flat against front face)
	local panel = part(model, "Panel", Vector3.new(3.0, 1.5, 0.25), Vector3.new(0, -1.55, 1.4), MAROON)
	local pg = Instance.new("SurfaceGui")
	pg.Face = Enum.NormalId.Back
	pg.CanvasSize = Vector2.new(300, 170)
	pg.LightInfluence = 0
	pg.Parent = panel
	local pFace = Instance.new("Frame")
	pFace.Size = UDim2.fromScale(1, 1)
	pFace.BackgroundTransparency = 1
	pFace.Parent = pg
	buildJackpotPanel(pFace)

	-- Lever: black arm on the right side, red ball knob welded to follow it
	leverArm = part(model, "LeverArm", Vector3.new(0.4, 2.6, 0.4), Vector3.new(2.15, 0.6, 0), Color3.fromRGB(20, 20, 22), Enum.Material.Metal)
	leverArm.CanCollide = false
	knob = part(model, "LeverKnob", Vector3.new(1.1, 1.1, 1.1), Vector3.new(2.15, 2.15, 0), Color3.fromRGB(210, 35, 40), Enum.Material.SmoothPlastic)
	knob.Shape = Enum.PartType.Ball
	knob.CanCollide = false
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = leverArm
	weld.Part1 = knob
	weld.Parent = leverArm
	knob.Anchored = false

	-- Jackpot effects: point light + sparkle emitter parented to the neon strip
	jackpotLight = Instance.new("PointLight")
	jackpotLight.Range = 22
	jackpotLight.Brightness = 0
	jackpotLight.Color = Color3.fromRGB(255, 255, 255)
	jackpotLight.Parent = marqueeLight

	sparkles = Instance.new("ParticleEmitter")
	sparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparkles.Enabled = false
	sparkles.Lifetime = NumberRange.new(0.6, 1.1)
	sparkles.Speed = NumberRange.new(9, 18)
	sparkles.SpreadAngle = Vector2.new(180, 180)
	sparkles.Rotation = NumberRange.new(0, 360)
	sparkles.RotSpeed = NumberRange.new(-200, 200)
	sparkles.Size = NumberSequence.new(0.7)
	sparkles.LightEmission = 1
	sparkles.Acceleration = Vector3.new(0, -12, 0)
	sparkles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 230, 120)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 100, 180)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 200, 255)),
	})
	sparkles.Parent = marqueeLight

	-- Lever pull click
	spinSound = Instance.new("Sound")
	spinSound.SoundId = "rbxasset://sounds/switch.wav"
	spinSound.Volume = 0.6
	spinSound.Parent = cabinet

	-- Jackpot sting
	winSound = Instance.new("Sound")
	winSound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
	winSound.Volume = 0.9
	winSound.Parent = cabinet

	-- Reel tick (plays repeatedly while reels spin, with increasing intervals)
	tickSound = Instance.new("Sound")
	tickSound.SoundId = "rbxasset://sounds/button.wav"
	tickSound.Volume = 0.35
	tickSound.PlaybackSpeed = 1.6
	tickSound.Parent = cabinet

	-- Reel display (SurfaceGui on the angled screen part)
	local sg = Instance.new("SurfaceGui")
	sg.Name = "ReelDisplay"
	sg.Face = Enum.NormalId.Back
	sg.CanvasSize = Vector2.new(300, 200)
	sg.LightInfluence = 0
	sg.Parent = screen

	local container = Instance.new("Frame")
	container.Size = UDim2.fromScale(1, 1)
	container.BackgroundTransparency = 1
	container.Parent = sg

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 10)
	layout.Parent = container

	for i = 1, 3 do
		local window = Instance.new("Frame")
		window.Size = UDim2.fromOffset(CELL_W, CELL_H)
		window.BackgroundColor3 = Color3.fromRGB(248, 248, 250)
		window.BorderSizePixel = 0
		window.ClipsDescendants = true
		window.Parent = container
		local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = window
		reelWindows[i] = window
		setReelStatic(i, "7")
	end

	-- Interaction prompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "SpinPrompt"
	prompt.ActionText = "Spin  (+" .. REWARD .. " chips)"
	prompt.ObjectText = "Lucky Slot"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = cabinet
	prompt.Triggered:Connect(function(player)
		onSpin(player)
	end)

	return model
end

-- ── Visual / audio feedback ───────────────────────────────────────────────────

local function pullLever()
	TweenService:Create(leverArm, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ CFrame = leverPulledCF }):Play()
	task.delay(0.18, function()
		TweenService:Create(leverArm, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ CFrame = leverRestCF }):Play()
	end)
end

local function jackpotEffects()
	sparkles:Emit(80)
	task.spawn(function()
		for i = 1, 18 do
			local c = Color3.fromHSV((i / 18) % 1, 1, 1)
			marqueeLight.Color = c
			knob.Color = c
			jackpotLight.Color = c
			jackpotLight.Brightness = 5
			task.wait(0.07)
		end
		marqueeLight.Color = Color3.fromRGB(255, 220, 80)
		knob.Color = Color3.fromRGB(210, 35, 40)
		jackpotLight.Brightness = 0
	end)
end

local function popup(amount: number, isJackpot: boolean)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(isJackpot and 220 or 120, isJackpot and 60 or 44)
	bb.AlwaysOnTop = true
	bb.StudsOffset = Vector3.new(math.random(-8, 8) / 10, 5, 0)
	bb.Adornee = cabinet
	bb.Parent = cabinet

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 1
	lbl.Text = isJackpot and ("JACKPOT  +" .. amount) or ("+" .. amount)
	lbl.TextColor3 = isJackpot and Color3.fromRGB(255, 80, 200) or Color3.fromRGB(255, 225, 90)
	lbl.TextStrokeTransparency = 0.3
	lbl.Font = Enum.Font.GothamBlack
	lbl.TextScaled = true
	lbl.Parent = bb

	local rise = isJackpot and 5 or 3
	TweenService:Create(bb, TweenInfo.new(isJackpot and 1.2 or 0.8),
		{ StudsOffset = bb.StudsOffset + Vector3.new(0, rise, 0) }):Play()
	TweenService:Create(lbl, TweenInfo.new(isJackpot and 1.2 or 0.8),
		{ TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	task.delay(isJackpot and 1.25 or 0.85, function() bb:Destroy() end)
end

-- ── Spin handler ──────────────────────────────────────────────────────────────

function onSpin(player: Player)
	if debounce[player] then return end
	debounce[player] = true

	spinSound:Play()
	pullLever()

	EconomyService.awardChips(player, REWARD)
	popup(REWARD, false)

	local final = {
		ALL_SYMBOLS[math.random(#ALL_SYMBOLS)],
		ALL_SYMBOLS[math.random(#ALL_SYMBOLS)],
		ALL_SYMBOLS[math.random(#ALL_SYMBOLS)],
	}
	local isJackpot = final[1] == final[2] and final[2] == final[3]

	spinReels(final, function()
		if isJackpot then
			EconomyService.awardChips(player, JACKPOT)
			winSound:Play()
			jackpotEffects()
			popup(JACKPOT, true)
		end
		debounce[player] = nil
	end)
end

-- ── Init ──────────────────────────────────────────────────────────────────────

local function init()
	local model = build()
	model:PivotTo(MACHINE_CFRAME)
	model.Parent = Workspace

	leverRestCF = leverArm.CFrame
	local hingeCF = leverRestCF * CFrame.new(0, -1.3, 0)
	leverPulledCF = hingeCF * CFrame.Angles(math.rad(55), 0, 0) * CFrame.new(0, 1.3, 0)
end

return { init = init }
