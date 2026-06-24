-- The manual starter slot machine.
-- A fixed world object near spawn: press the prompt → pull the lever → reels roll → earn chips.
-- Always pays the base reward; matching all 3 reels triggers a jackpot with effects.
-- This is the FIRST income source, before any placeable passive machines.
-- Visual style: classic gold "Lucky Slot" arcade toy.

local Workspace    = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local Shared         = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig     = require(Shared.constants.GameConfig)
local EconomyService = require(script.Parent.Parent.economy.EconomyService)

local REWARD         = GameConfig.MANUAL_SLOT_REWARD
local JACKPOT        = GameConfig.MANUAL_SLOT_JACKPOT
local MACHINE_CFRAME = CFrame.new(0, 3.5, -10)
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
local TARGET_INDEX = 1             -- target rests near the top; reel scrolls downward onto it
local ROLL_CELLS   = 12            -- how many cells of travel
local END_Y        = -TARGET_INDEX * CELL_H
local START_Y      = END_Y - ROLL_CELLS * CELL_H

local GOLD = Color3.fromRGB(214, 175, 60)

local debounce: { [Player]: boolean } = {}

-- references filled in build()
local cabinet: Part
local marqueeLight: Part
local knob: Part
local leverArm: Part
local jackpotLight: PointLight
local sparkles: ParticleEmitter
local spinSound: Sound
local winSound: Sound
local reelWindows: { Frame } = {}

-- computed in init() after the machine is pivoted into place
local leverRestCF: CFrame
local leverPulledCF: CFrame

-- forward declaration (defined below build)
local onSpin: (player: Player) -> ()

-- ── Part helper ──────────────────────────────────────────────────────────────

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

-- Draw one symbol (visible) filling the given cell frame
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

local function spinReels(final: { string }, onComplete: () -> ())
	rollReel(1, final[1], 1.1)
	rollReel(2, final[2], 1.45)
	local last = rollReel(3, final[3], 1.8)
	last.Completed:Connect(function()
		onComplete()
	end)
end

-- ── Jackpot odds panel (lower front display) ─────────────────────────────────

local function buildJackpotPanel(face: Frame)
	-- chance that all three reels match = 1 / (symbols ^ 2)
	local oddsText = string.format("%.1f%%", 100 / ((#ALL_SYMBOLS) ^ 2))

	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Vertical
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.Padding = UDim.new(0, 2)
	list.Parent = face

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 30)
	title.BackgroundTransparency = 1
	title.Text = "JACKPOT CHANCE"
	title.TextColor3 = Color3.fromRGB(255, 215, 90)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 24
	title.LayoutOrder = 1
	title.Parent = face

	local pct = Instance.new("TextLabel")
	pct.Size = UDim2.new(1, 0, 0, 64)
	pct.BackgroundTransparency = 1
	pct.Text = oddsText .. "!"
	pct.TextColor3 = Color3.fromRGB(255, 255, 255)
	pct.TextStrokeTransparency = 0.2
	pct.TextStrokeColor3 = Color3.fromRGB(120, 20, 0)
	pct.Font = Enum.Font.GothamBlack
	pct.TextSize = 60
	pct.LayoutOrder = 2
	pct.Parent = face

	local sub = Instance.new("TextLabel")
	sub.Size = UDim2.new(1, 0, 0, 24)
	sub.BackgroundTransparency = 1
	sub.Text = "match 3  •  +" .. JACKPOT .. " chips"
	sub.TextColor3 = Color3.fromRGB(255, 200, 160)
	sub.Font = Enum.Font.Gotham
	sub.TextSize = 18
	sub.LayoutOrder = 3
	sub.Parent = face
end

-- ── Build the machine ────────────────────────────────────────────────────────

local function build(): Model
	local model = Instance.new("Model")
	model.Name = "ManualSlotMachine"

	-- Dark base
	part(model, "Base", Vector3.new(5, 0.6, 4), Vector3.new(0, -3.2, 0), Color3.fromRGB(28, 24, 30))

	-- Gold cabinet body (primary part)
	cabinet = part(model, "Cabinet", Vector3.new(4, 6, 3), Vector3.new(0, 0, 0), GOLD, Enum.Material.Metal)
	model.PrimaryPart = cabinet

	-- Maroon marquee on top — pushed back so the silhouette is stepped, not a flat rectangle.
	-- Cabinet front face (player-facing) is at local z = +1.5.
	-- Marquee front face sits at z = +0.5, giving a 1-stud step-back.
	local marquee = part(model, "Marquee", Vector3.new(4.2, 1.4, 2.0), Vector3.new(0, 3.6, -0.5), Color3.fromRGB(120, 20, 32))
	-- Neon light strip sits flush with the marquee's front face.
	marqueeLight = part(model, "MarqueeLight", Vector3.new(3.2, 0.22, 0.3), Vector3.new(0, 2.9, 0.55), Color3.fromRGB(255, 220, 80), Enum.Material.Neon)
	-- Brow: thin gold ledge that bridges the step between marquee and cabinet front.
	part(model, "Brow", Vector3.new(4.3, 0.22, 1.2), Vector3.new(0, 2.9, 1.0), GOLD, Enum.Material.Metal)

	-- Marquee title "LUCKY SLOT"
	local mg = Instance.new("SurfaceGui")
	mg.Face = Enum.NormalId.Back
	mg.CanvasSize = Vector2.new(300, 100)
	mg.LightInfluence = 0
	mg.Parent = marquee
	local mTitle = Instance.new("TextLabel")
	mTitle.Size = UDim2.fromScale(1, 1)
	mTitle.BackgroundTransparency = 1
	mTitle.Text = "LUCKY SLOT"
	mTitle.TextColor3 = Color3.fromRGB(255, 220, 90)
	mTitle.TextStrokeTransparency = 0.2
	mTitle.TextStrokeColor3 = Color3.fromRGB(120, 20, 0)
	mTitle.Font = Enum.Font.GothamBlack
	mTitle.TextScaled = true
	mTitle.Parent = mg

	-- Gold trim + dark reel window backing
	part(model, "ScreenFrame", Vector3.new(3.5, 2.7, 0.25), Vector3.new(0, 1.1, 1.5), Color3.fromRGB(235, 195, 70), Enum.Material.Metal)
	local screen = part(model, "Screen", Vector3.new(3.1, 2.1, 0.2), Vector3.new(0, 1.1, 1.62), Color3.fromRGB(15, 12, 10))

	-- Jackpot odds panel (lower front)
	local panel = part(model, "Panel", Vector3.new(3.5, 1.6, 0.25), Vector3.new(0, -1.6, 1.5), Color3.fromRGB(120, 20, 32))
	local pg = Instance.new("SurfaceGui")
	pg.Face = Enum.NormalId.Back
	pg.CanvasSize = Vector2.new(300, 140)
	pg.LightInfluence = 0
	pg.Parent = panel
	local pFace = Instance.new("Frame")
	pFace.Size = UDim2.fromScale(1, 1)
	pFace.BackgroundTransparency = 1
	pFace.Parent = pg
	buildJackpotPanel(pFace)

	-- Lever: black arm (anchored) + big red ball knob (welded so it follows)
	leverArm = part(model, "LeverArm", Vector3.new(0.4, 2.6, 0.4), Vector3.new(2.45, 1.6, 0), Color3.fromRGB(20, 20, 22), Enum.Material.Metal)
	leverArm.CanCollide = false
	knob = part(model, "LeverKnob", Vector3.new(1.1, 1.1, 1.1), Vector3.new(2.45, 3.1, 0), Color3.fromRGB(210, 35, 40), Enum.Material.SmoothPlastic)
	knob.Shape = Enum.PartType.Ball
	knob.CanCollide = false
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = leverArm
	weld.Part1 = knob
	weld.Parent = leverArm
	knob.Anchored = false

	-- Jackpot light + sparkle emitter on the marquee light
	jackpotLight = Instance.new("PointLight")
	jackpotLight.Range = 20
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

	-- Sounds (built-in engine assets, always load)
	spinSound = Instance.new("Sound")
	spinSound.SoundId = "rbxasset://sounds/switch.wav"
	spinSound.Volume = 0.5
	spinSound.Parent = cabinet

	winSound = Instance.new("Sound")
	winSound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
	winSound.Volume = 0.9
	winSound.Parent = cabinet

	-- Reels on the screen (SurfaceGui faces +Z / Back, toward the player)
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

-- ── Visual / audio feedback ──────────────────────────────────────────────────

local function pullLever()
	TweenService:Create(leverArm, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ CFrame = leverPulledCF }):Play()
	task.delay(0.18, function()
		TweenService:Create(leverArm, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ CFrame = leverRestCF }):Play()
	end)
end

local function jackpotEffects()
	sparkles:Emit(70)
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

-- ── Spin handler ─────────────────────────────────────────────────────────────

function onSpin(player: Player)
	if debounce[player] then return end
	debounce[player] = true

	spinSound:Play()
	pullLever()

	-- guaranteed base reward, paid up front for snappy feedback
	EconomyService.awardChips(player, REWARD)
	popup(REWARD, false)

	-- roll the reels; matching all three is a jackpot
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

-- ── Init ─────────────────────────────────────────────────────────────────────

local function init()
	local model = build()
	model:PivotTo(MACHINE_CFRAME)
	model.Parent = Workspace

	-- compute lever rest/pulled CFrames now that the machine is in place
	leverRestCF = leverArm.CFrame
	local hingeCF = leverRestCF * CFrame.new(0, -1.3, 0)          -- bottom of the arm
	leverPulledCF = hingeCF * CFrame.Angles(math.rad(55), 0, 0) * CFrame.new(0, 1.3, 0)
end

return { init = init }
