-- Shared UI style helpers so every ScreenGui reads as one premium casino theme.
-- The currency icon is DRAWN (a gold casino chip made of Frames), never an emoji —
-- the 🪙 glyph renders as a tofu box (□) in the Gotham fonts, so we avoid it entirely.

local TweenService = game:GetService("TweenService")

local UIStyle = {}

-- Palette ------------------------------------------------------------------
-- Muted natural theme: dark slate grey, dim grey, ebony, ivory, dry sage.
UIStyle.BG_DARK      = Color3.fromRGB(54, 69, 59)    -- Dark Slate Grey
UIStyle.BG_PANEL     = Color3.fromRGB(89, 104, 105)  -- Dim Grey
UIStyle.CARD_BG      = Color3.fromRGB(101, 116, 113) -- a touch lighter than the panel
UIStyle.PANEL_TOP    = Color3.fromRGB(96, 111, 110)  -- subtle same-family panel gradient
UIStyle.PANEL_BOTTOM = Color3.fromRGB(82, 95, 92)
UIStyle.HEADER       = Color3.fromRGB(54, 69, 59)    -- solid header (Dark Slate Grey)
-- Currency coin stays gold so money reads clearly, just muted to fit the theme.
UIStyle.GOLD       = Color3.fromRGB(214, 196, 120)
UIStyle.GOLD_LIGHT = Color3.fromRGB(235, 224, 170)
UIStyle.GOLD_DEEP  = Color3.fromRGB(176, 156, 86)
UIStyle.ACCENT     = Color3.fromRGB(194, 193, 165)   -- Dry Sage
UIStyle.ACCENT_LT  = Color3.fromRGB(222, 221, 198)
UIStyle.NEON_GREEN = Color3.fromRGB(150, 190, 140)   -- muted sage-green (income/positive)
UIStyle.NEON_RED   = Color3.fromRGB(184, 98, 86)     -- muted terracotta (sell/close)
UIStyle.NEON_BLUE  = Color3.fromRGB(108, 130, 138)   -- muted slate-blue (place/pickup)
UIStyle.TEXT       = Color3.fromRGB(245, 249, 233)   -- Ivory
UIStyle.TEXT_DIM   = Color3.fromRGB(205, 209, 188)

-- Primitives ---------------------------------------------------------------
function UIStyle.corner(parent: Instance, radius: number): UICorner
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
	return c
end

function UIStyle.round(parent: Instance): UICorner
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(1, 0)
	c.Parent = parent
	return c
end

function UIStyle.stroke(parent: Instance, color: Color3, thickness: number): UIStroke
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness
	s.Parent = parent
	return s
end

function UIStyle.gradient(parent: Instance, c1: Color3, c2: Color3, rotation: number?): UIGradient
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(c1, c2)
	g.Rotation = rotation or 0
	g.Parent = parent
	return g
end

function UIStyle.pad(parent: Instance, px: number): UIPadding
	local p = Instance.new("UIPadding")
	p.PaddingTop = UDim.new(0, px)
	p.PaddingBottom = UDim.new(0, px)
	p.PaddingLeft = UDim.new(0, px)
	p.PaddingRight = UDim.new(0, px)
	p.Parent = parent
	return p
end

-- A gold casino chip currency icon (no emoji). `size` is the square pixel size.
function UIStyle.chipIcon(size: number): Frame
	local chip = Instance.new("Frame")
	chip.Name = "ChipIcon"
	chip.Size = UDim2.fromOffset(size, size)
	chip.BackgroundColor3 = UIStyle.GOLD
	chip.BorderSizePixel = 0
	UIStyle.round(chip)
	UIStyle.gradient(chip, Color3.fromRGB(228, 212, 142), UIStyle.GOLD_DEEP, 90)
	UIStyle.stroke(chip, Color3.fromRGB(140, 120, 64), math.max(1, size * 0.09))

	-- Inner ring gives it the poker-chip read.
	local inner = Instance.new("Frame")
	inner.Name = "Inner"
	inner.Size = UDim2.fromScale(0.5, 0.5)
	inner.Position = UDim2.fromScale(0.25, 0.25)
	inner.BackgroundColor3 = Color3.fromRGB(236, 226, 168)
	inner.BorderSizePixel = 0
	inner.Parent = chip
	UIStyle.round(inner)
	UIStyle.stroke(inner, Color3.fromRGB(160, 140, 82), math.max(1, size * 0.05))
	return chip
end

-- A standardized floating toggle button. Returns the TextButton; its readable
-- text lives on a child TextLabel named "Label" (button.Text is empty so the
-- gradient + icon never fight the text). Hover brightens the stroke.
-- props = { name, text, accent: Color3, position: UDim2, size: UDim2? }
function UIStyle.toggleButton(props): TextButton
	local btn = Instance.new("TextButton")
	btn.Name = props.name
	btn.Size = props.size or UDim2.fromOffset(154, 50)
	btn.Position = props.position
	btn.BackgroundColor3 = Color3.fromRGB(82, 95, 92)
	btn.AutoButtonColor = false
	btn.Text = ""
	btn.BorderSizePixel = 0
	UIStyle.corner(btn, 14)
	UIStyle.gradient(btn, Color3.fromRGB(96, 111, 110), Color3.fromRGB(70, 82, 80), 90)
	local s = UIStyle.stroke(btn, props.accent, 2)

	-- A colored rounded icon-chip on the left in place of an emoji.
	local dot = Instance.new("Frame")
	dot.Name = "Icon"
	dot.Size = UDim2.fromOffset(22, 22)
	dot.Position = UDim2.new(0, 14, 0.5, -11)
	dot.BackgroundColor3 = props.accent
	dot.BorderSizePixel = 0
	dot.Parent = btn
	UIStyle.corner(dot, 7)
	UIStyle.gradient(dot, props.accent, Color3.fromRGB(
		math.floor(props.accent.R * 255 * 0.65),
		math.floor(props.accent.G * 255 * 0.65),
		math.floor(props.accent.B * 255 * 0.65)
	), 90)

	local lbl = Instance.new("TextLabel")
	lbl.Name = "Label"
	lbl.Size = UDim2.new(1, -52, 1, 0)
	lbl.Position = UDim2.new(0, 46, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = props.text
	lbl.TextColor3 = UIStyle.TEXT
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 18
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = btn

	btn.MouseEnter:Connect(function()
		TweenService:Create(s, TweenInfo.new(0.15), { Thickness = 3, Color = UIStyle.ACCENT_LT }):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(s, TweenInfo.new(0.15), { Thickness = 2, Color = props.accent }):Play()
	end)
	return btn
end

-- A close (✕) button drawn from two rotated bars — the "✕" glyph renders as a
-- tofu box in the Gotham fonts, so we draw the X instead. Connect MouseButton1Click
-- on the returned button. Pass it a parent and it sits top-right by default.
function UIStyle.closeButton(size: number): TextButton
	local btn = Instance.new("TextButton")
	btn.Name = "CloseButton"
	btn.Size = UDim2.fromOffset(size, size)
	btn.Text = ""
	btn.AutoButtonColor = false
	btn.BackgroundColor3 = UIStyle.BG_DARK
	btn.BorderSizePixel = 0
	btn.ZIndex = 6
	UIStyle.corner(btn, math.floor(size / 3))
	UIStyle.stroke(btn, UIStyle.ACCENT, 1.5)

	for _, rot in { 45, -45 } do
		local bar = Instance.new("Frame")
		bar.AnchorPoint = Vector2.new(0.5, 0.5)
		bar.Position = UDim2.fromScale(0.5, 0.5)
		bar.Size = UDim2.new(0, math.floor(size * 0.5), 0, math.max(2, math.floor(size * 0.14)))
		bar.BackgroundColor3 = UIStyle.TEXT
		bar.BorderSizePixel = 0
		bar.Rotation = rot
		bar.ZIndex = 7
		bar.Parent = btn
		UIStyle.corner(bar, 2)
	end

	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = UIStyle.NEON_RED }):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = UIStyle.BG_DARK }):Play()
	end)
	return btn
end

-- Caps how large a TextScaled label may grow. TextScaled fills the whole box, so big
-- boxes produce oversized text that overlaps neighbours — this keeps it readable but tidy.
function UIStyle.maxText(obj: Instance, maxSize: number): UITextSizeConstraint
	local c = Instance.new("UITextSizeConstraint")
	c.MaxTextSize = maxSize
	c.Parent = obj
	return c
end

-- Standard hover brighten/restore for an action button's BackgroundColor3.
function UIStyle.hoverColor(btn: GuiButton, base: Color3, hover: Color3)
	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = hover }):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = base }):Play()
	end)
end

return UIStyle
