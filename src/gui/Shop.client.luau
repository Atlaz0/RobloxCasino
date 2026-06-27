local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

ReplicatedStorage:WaitForChild("Remotes", 15)

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MachineData  = require(Shared.constants.MachineData)
local FormatNumber = require(Shared.utils.FormatNumber)
local UIStyle      = require(Shared.utils.UIStyle)

local Client = Players.LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("Client")
local PlacementController = require(Client.controllers.PlacementController)

local BG_DARK    = Color3.fromRGB(12, 8, 20)
local BG_PANEL   = Color3.fromRGB(20, 13, 35)
local GOLD       = Color3.fromRGB(255, 200, 55)
local GOLD_LIGHT = Color3.fromRGB(255, 235, 130)
local ACCENT     = Color3.fromRGB(160, 90, 255)
local NEON_GREEN = Color3.fromRGB(80, 255, 140)
local PHASE_COLORS = {
	Color3.fromRGB(255, 190, 30),
	Color3.fromRGB(160, 90, 255),
	Color3.fromRGB(0, 220, 220),
}

local PANEL_CLOSED = UDim2.new(1, 20, 1, -646)
local PANEL_OPEN   = UDim2.new(1, -376, 1, -646)

local function corner(parent: Instance, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

local function stroke(parent: Instance, color: Color3, thickness: number): UIStroke
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness
	s.Parent = parent
	return s
end

local function gradient(parent: Instance, c1: Color3, c2: Color3, rotation: number): UIGradient
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, c1),
		ColorSequenceKeypoint.new(1, c2),
	})
	g.Rotation = rotation
	g.Parent = parent
	return g
end

-- Sort machines by phase then cost.
local sortedMachines = {}
for _, def in pairs(MachineData) do
	table.insert(sortedMachines, def)
end
table.sort(sortedMachines, function(a, b)
	if a.phase ~= b.phase then return a.phase < b.phase end
	return a.cost < b.cost
end)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "Shop"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

-- Toggle button (bottom-right)
local toggleBtn = UIStyle.toggleButton({
	name = "ShopToggle",
	text = "Shop",
	accent = UIStyle.GOLD,
	position = UDim2.new(1, -170, 1, -72),
})
toggleBtn.Parent = screenGui

-- Panel
local panel = Instance.new("Frame")
panel.Name = "ShopPanel"
panel.Size = UDim2.new(0, 360, 0, 520)
panel.Position = PANEL_CLOSED
panel.BackgroundColor3 = UIStyle.PANEL_TOP
panel.BackgroundTransparency = 0.15
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = screenGui
corner(panel, 18)
stroke(panel, ACCENT, 1.5)
gradient(panel, UIStyle.PANEL_TOP, UIStyle.PANEL_BOTTOM, 180)

-- Panel header
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 52)
header.Position = UDim2.new(0, 0, 0, 0)
header.BackgroundColor3 = Color3.fromRGB(255, 190, 30)
header.BorderSizePixel = 0
header.Parent = panel
corner(header, 18)
gradient(header, Color3.fromRGB(255, 190, 30), Color3.fromRGB(160, 90, 255), 0)

-- Clip the bottom corners of the header so it blends with panel body
local headerBottomClip = Instance.new("Frame")
headerBottomClip.Size = UDim2.new(1, 0, 0, 18)
headerBottomClip.Position = UDim2.new(0, 0, 1, -18)
headerBottomClip.BackgroundColor3 = UIStyle.PANEL_TOP
headerBottomClip.BorderSizePixel = 0
headerBottomClip.ZIndex = 2
headerBottomClip.Parent = header

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -60, 1, 0)
titleLabel.Position = UDim2.new(0, 14, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "CASINO SHOP"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex = 3
titleLabel.Parent = header
UIStyle.maxText(titleLabel, 24)

local closeBtn = UIStyle.closeButton(28)
closeBtn.Position = UDim2.new(1, -38, 0.5, -14)
closeBtn.ZIndex = 4
closeBtn.Parent = header

-- Hint bar below header
local hint = Instance.new("TextLabel")
hint.Size = UDim2.new(1, -24, 0, 18)
hint.Position = UDim2.new(0, 12, 0, 58)
hint.BackgroundTransparency = 1
hint.Text = "Buy a machine, then click your plot to place it."
hint.TextColor3 = Color3.fromRGB(190, 170, 220)
hint.TextScaled = true
hint.Font = Enum.Font.Gotham
hint.TextXAlignment = Enum.TextXAlignment.Left
hint.Parent = panel
UIStyle.maxText(hint, 13)

-- Scroll area
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -16, 1, -84)
scroll.Position = UDim2.new(0, 8, 0, 80)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 5
scroll.ScrollBarImageColor3 = ACCENT
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = panel

local layout = Instance.new("UIListLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 6)
layout.Parent = scroll

local scrollPadding = Instance.new("UIPadding")
scrollPadding.PaddingTop = UDim.new(0, 8)
scrollPadding.PaddingLeft = UDim.new(0, 8)
scrollPadding.PaddingRight = UDim.new(0, 8)
scrollPadding.Parent = scroll

local function phaseLabel(phase: number): Frame
	local phaseColor = PHASE_COLORS[phase] or ACCENT
	local names = { "Phase 1 — The Floor", "Phase 2 — The Resort", "Phase 3 — The Strip" }

	local lf = Instance.new("Frame")
	lf.Size = UDim2.new(1, 0, 0, 28)
	lf.BackgroundColor3 = UIStyle.PANEL_BOTTOM
	lf.BorderSizePixel = 0
	lf.LayoutOrder = phase * 1000 - 1
	corner(lf, 6)
	stroke(lf, phaseColor, 1)

	local accentBar = Instance.new("Frame")
	accentBar.Size = UDim2.new(0, 6, 1, 0)
	accentBar.Position = UDim2.new(0, 0, 0, 0)
	accentBar.BackgroundColor3 = phaseColor
	accentBar.BorderSizePixel = 0
	accentBar.Parent = lf
	corner(accentBar, 4)

	local lt = Instance.new("TextLabel")
	lt.Size = UDim2.new(1, -18, 1, 0)
	lt.Position = UDim2.new(0, 14, 0, 0)
	lt.BackgroundTransparency = 1
	lt.Text = names[phase] or ("Phase " .. phase)
	lt.TextColor3 = phaseColor
	lt.Font = Enum.Font.GothamBold
	lt.TextScaled = true
	lt.TextXAlignment = Enum.TextXAlignment.Left
	lt.Parent = lf
	UIStyle.maxText(lt, 15)

	return lf
end

local currentPhase = 0
for i, def in ipairs(sortedMachines) do
	if def.phase ~= currentPhase then
		currentPhase = def.phase
		phaseLabel(def.phase).Parent = scroll
	end

	local phaseColor = PHASE_COLORS[def.phase] or ACCENT

	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, 0, 0, 88)
	card.BackgroundColor3 = UIStyle.CARD_BG
	card.BorderSizePixel = 0
	card.LayoutOrder = def.phase * 1000 + i
	card.Parent = scroll
	corner(card, 12)
	gradient(card, UIStyle.CARD_BG, Color3.fromRGB(42, 34, 62), 135)

	local cardAccentBar = Instance.new("Frame")
	cardAccentBar.Size = UDim2.new(0, 5, 1, 0)
	cardAccentBar.Position = UDim2.new(0, 0, 0, 0)
	cardAccentBar.BackgroundColor3 = phaseColor
	cardAccentBar.BorderSizePixel = 0
	cardAccentBar.Parent = card
	corner(cardAccentBar, 4)

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -126, 0, 32)
	nameLabel.Position = UDim2.new(0, 18, 0, 12)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = def.displayName
	nameLabel.TextColor3 = Color3.fromRGB(255, 245, 215)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextScaled = true
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = card
	UIStyle.maxText(nameLabel, 18)

	local incomeLabel = Instance.new("TextLabel")
	incomeLabel.Size = UDim2.new(1, -126, 0, 22)
	incomeLabel.Position = UDim2.new(0, 18, 0, 48)
	incomeLabel.BackgroundTransparency = 1
	incomeLabel.Text = "+" .. FormatNumber.format(def.incomePerSecond) .. "/s"
	incomeLabel.TextColor3 = NEON_GREEN
	incomeLabel.Font = Enum.Font.Gotham
	incomeLabel.TextScaled = true
	incomeLabel.TextXAlignment = Enum.TextXAlignment.Left
	incomeLabel.Parent = card
	UIStyle.maxText(incomeLabel, 14)

	local buyBtn = Instance.new("TextButton")
	buyBtn.Size = UDim2.new(0, 104, 0, 44)
	buyBtn.Position = UDim2.new(1, -114, 0.5, -22)
	buyBtn.BackgroundColor3 = Color3.fromRGB(220, 160, 0)
	buyBtn.BorderSizePixel = 0
	buyBtn.Text = ""
	buyBtn.AutoButtonColor = false
	buyBtn.Parent = card
	corner(buyBtn, 10)
	gradient(buyBtn, Color3.fromRGB(220, 160, 0), Color3.fromRGB(255, 200, 30), 90)

	-- Chip on the left, price filling the rest — laid out so they never overlap.
	local chip = UIStyle.chipIcon(20)
	chip.AnchorPoint = Vector2.new(0, 0.5)
	chip.Position = UDim2.new(0, 9, 0.5, 0)
	chip.ZIndex = 3
	chip.Parent = buyBtn

	local priceLabel = Instance.new("TextLabel")
	priceLabel.Size = UDim2.new(1, -38, 1, -14)
	priceLabel.Position = UDim2.new(0, 33, 0.5, 0)
	priceLabel.AnchorPoint = Vector2.new(0, 0.5)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Text = FormatNumber.format(def.cost)
	priceLabel.TextColor3 = Color3.fromRGB(20, 10, 0)
	priceLabel.Font = Enum.Font.GothamBlack
	priceLabel.TextScaled = true
	priceLabel.TextXAlignment = Enum.TextXAlignment.Center
	priceLabel.ZIndex = 3
	priceLabel.Parent = buyBtn
	UIStyle.maxText(priceLabel, 18)

	buyBtn.MouseEnter:Connect(function()
		TweenService:Create(buyBtn, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = Color3.fromRGB(255, 215, 60),
		}):Play()
	end)
	buyBtn.MouseLeave:Connect(function()
		TweenService:Create(buyBtn, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = Color3.fromRGB(220, 160, 0),
		}):Play()
	end)

	local machineId = def.id
	buyBtn.MouseButton1Click:Connect(function()
		panel.Visible = false
		PlacementController.beginPlacement(machineId)
	end)
end

-- Open / close animations
local open = false
local activeTween: Tween? = nil

local function openPanel()
	panel.Visible = true
	if activeTween then activeTween:Cancel() end
	local tween = TweenService:Create(panel, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = PANEL_OPEN,
		BackgroundTransparency = 0,
	})
	activeTween = tween
	tween:Play()
end

local function closePanel()
	if activeTween then activeTween:Cancel() end
	local tween = TweenService:Create(panel, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = PANEL_CLOSED,
		BackgroundTransparency = 0.3,
	})
	activeTween = tween
	tween:Play()
	tween.Completed:Connect(function()
		if not open then
			panel.Visible = false
		end
	end)
end

toggleBtn.MouseButton1Click:Connect(function()
	open = not open
	if open then
		openPanel()
	else
		closePanel()
	end
end)

closeBtn.MouseButton1Click:Connect(function()
	open = false
	closePanel()
end)
