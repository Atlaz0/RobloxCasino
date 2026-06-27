-- Shared UI style helpers so every ScreenGui reads as one premium casino theme.
-- The currency icon is DRAWN (a gold casino chip made of Frames), never an emoji —
-- the 🪙 glyph renders as a tofu box (□) in the Gotham fonts, so we avoid it entirely.

local TweenService = game:GetService("TweenService")

local UIStyle = {}

-- Palette ------------------------------------------------------------------
UIStyle.BG_DARK    = Color3.fromRGB(12, 8, 20)
UIStyle.BG_PANEL   = Color3.fromRGB(20, 13, 35)
UIStyle.CARD_BG    = Color3.fromRGB(26, 16, 42)
UIStyle.GOLD       = Color3.fromRGB(255, 200, 55)
UIStyle.GOLD_LIGHT = Color3.fromRGB(255, 235, 130)
UIStyle.GOLD_DEEP  = Color3.fromRGB(226, 168, 30)
UIStyle.ACCENT     = Color3.fromRGB(160, 90, 255)
UIStyle.ACCENT_LT  = Color3.fromRGB(200, 150, 255)
UIStyle.NEON_GREEN = Color3.fromRGB(80, 255, 140)
UIStyle.NEON_RED   = Color3.fromRGB(255, 60, 80)
UIStyle.NEON_BLUE  = Color3.fromRGB(80, 150, 255)
UIStyle.TEXT       = Color3.fromRGB(245, 240, 255)
UIStyle.TEXT_DIM   = Color3.fromRGB(170, 160, 195)

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
	UIStyle.gradient(chip, Color3.fromRGB(255, 224, 120), UIStyle.GOLD_DEEP, 90)
	UIStyle.stroke(chip, Color3.fromRGB(150, 100, 10), math.max(1, size * 0.09))

	-- Inner ring gives it the poker-chip read.
	local inner = Instance.new("Frame")
	inner.Name = "Inner"
	inner.Size = UDim2.fromScale(0.5, 0.5)
	inner.Position = UDim2.fromScale(0.25, 0.25)
	inner.BackgroundColor3 = Color3.fromRGB(255, 238, 175)
	inner.BorderSizePixel = 0
	inner.Parent = chip
	UIStyle.round(inner)
	UIStyle.stroke(inner, Color3.fromRGB(195, 145, 30), math.max(1, size * 0.05))
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
	btn.BackgroundColor3 = Color3.fromRGB(40, 26, 60)
	btn.AutoButtonColor = false
	btn.Text = ""
	btn.BorderSizePixel = 0
	UIStyle.corner(btn, 14)
	UIStyle.gradient(btn, Color3.fromRGB(52, 33, 78), Color3.fromRGB(28, 17, 44), 90)
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
		TweenService:Create(s, TweenInfo.new(0.15), { Thickness = 3, Color = UIStyle.GOLD_LIGHT }):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(s, TweenInfo.new(0.15), { Thickness = 2, Color = props.accent }):Play()
	end)
	return btn
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
