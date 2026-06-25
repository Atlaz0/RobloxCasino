local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

ReplicatedStorage:WaitForChild("Remotes", 15)

local Shared      = ReplicatedStorage:WaitForChild("Shared")
local MachineData  = require(Shared.constants.MachineData)
local FormatNumber = require(Shared.utils.FormatNumber)

local Client = Players.LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("Client")
local PlacementController = require(Client.controllers.PlacementController)

-- ── Helpers ────────────────────────────────────────────────────────────────

local function applyCorner(parent: Instance, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

local function applyStroke(parent: Instance, color: Color3, thickness: number, transparency: number?)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness
	s.Transparency = transparency or 0
	s.Parent = parent
end

local PURPLE     = Color3.fromRGB(130, 70, 230)
local PURPLE_DIM = Color3.fromRGB(80, 40, 150)
local GOLD       = Color3.fromRGB(255, 195, 40)
local GOLD_DIM   = Color3.fromRGB(180, 130, 20)
local BG_DARK    = Color3.fromRGB(10, 7, 20)
local BG_CARD    = Color3.fromRGB(20, 14, 36)
local BG_CARD_HO = Color3.fromRGB(30, 20, 52)
local TEXT_WHITE = Color3.fromRGB(240, 235, 255)
local TEXT_DIM   = Color3.fromRGB(160, 150, 190)
local TEXT_GREEN = Color3.fromRGB(100, 220, 120)

local PHASE_COLORS = {
	[1] = Color3.fromRGB(255, 195, 40),
	[2] = Color3.fromRGB(130, 200, 255),
	[3] = Color3.fromRGB(255, 100, 180),
}

-- ── Root ScreenGui ─────────────────────────────────────────────────────────

local gui = Instance.new("ScreenGui")
gui.Name = "Shop"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

-- ── Toggle button ──────────────────────────────────────────────────────────

local toggleBtn = Instance.new("TextButton")
toggleBtn.AnchorPoint = Vector2.new(1, 1)
toggleBtn.Position = UDim2.new(1, -16, 1, -16)
toggleBtn.Size = UDim2.new(0, 100, 0, 40)
toggleBtn.BackgroundColor3 = PURPLE
toggleBtn.BorderSizePixel = 0
toggleBtn.Text = "SHOP"
toggleBtn.TextColor3 = TEXT_WHITE
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 15
toggleBtn.Parent = gui
applyCorner(toggleBtn, 20)

-- ── Panel ──────────────────────────────────────────────────────────────────

local PANEL_W, PANEL_H = 300, 500

local panel = Instance.new("Frame")
panel.Name = "ShopPanel"
panel.AnchorPoint = Vector2.new(1, 1)
panel.Position = UDim2.new(1, -16, 1, -68)
panel.Size = UDim2.new(0, PANEL_W, 0, PANEL_H)
panel.BackgroundColor3 = BG_DARK
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = gui
applyCorner(panel, 16)
applyStroke(panel, PURPLE, 1.5, 0.2)

-- Panel header bar
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 52)
header.BackgroundColor3 = Color3.fromRGB(20, 12, 40)
header.BorderSizePixel = 0
header.Parent = panel
applyCorner(header, 16)

-- Mask bottom corners of header
local headerMask = Instance.new("Frame")
headerMask.Size = UDim2.new(1, 0, 0, 16)
headerMask.Position = UDim2.new(0, 0, 1, -16)
headerMask.BackgroundColor3 = Color3.fromRGB(20, 12, 40)
headerMask.BorderSizePixel = 0
headerMask.ZIndex = 0
headerMask.Parent = header

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -52, 1, 0)
titleLabel.Position = UDim2.new(0, 16, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "CASINO SHOP"
titleLabel.TextColor3 = TEXT_WHITE
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 18
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = header

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 32, 0, 32)
closeBtn.Position = UDim2.new(1, -44, 0.5, -16)
closeBtn.BackgroundColor3 = Color3.fromRGB(50, 30, 80)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "✕"
closeBtn.TextColor3 = TEXT_DIM
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.Parent = header
applyCorner(closeBtn, 8)

-- Scroll area
local scroll = Instance.new("ScrollingFrame")
scroll.Position = UDim2.new(0, 0, 0, 52)
scroll.Size = UDim2.new(1, 0, 1, -52)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 3
scroll.ScrollBarImageColor3 = PURPLE
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = panel

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 6)
listLayout.Parent = scroll

local listPad = Instance.new("UIPadding")
listPad.PaddingTop = UDim.new(0, 10)
listPad.PaddingBottom = UDim.new(0, 10)
listPad.PaddingLeft = UDim.new(0, 10)
listPad.PaddingRight = UDim.new(0, 10)
listPad.Parent = scroll

-- ── Build machine cards ────────────────────────────────────────────────────

local sortedMachines = {}
for _, def in pairs(MachineData) do
	table.insert(sortedMachines, def)
end
table.sort(sortedMachines, function(a, b)
	return a.phase ~= b.phase and a.phase < b.phase or a.cost < b.cost
end)

local currentPhase = 0

for i, def in ipairs(sortedMachines) do
	-- Phase divider
	if def.phase ~= currentPhase then
		currentPhase = def.phase
		local divider = Instance.new("Frame")
		divider.Size = UDim2.new(1, 0, 0, 28)
		divider.BackgroundTransparency = 1
		divider.LayoutOrder = def.phase * 1000 - 1
		divider.Parent = scroll

		local phaseText = Instance.new("TextLabel")
		phaseText.Size = UDim2.new(1, 0, 1, 0)
		phaseText.BackgroundTransparency = 1
		phaseText.Text = ({ "Phase 1 — The Floor", "Phase 2 — The Resort", "Phase 3 — The Strip" })[def.phase] or ""
		phaseText.TextColor3 = PHASE_COLORS[def.phase] or TEXT_DIM
		phaseText.Font = Enum.Font.GothamBold
		phaseText.TextSize = 12
		phaseText.TextXAlignment = Enum.TextXAlignment.Left
		phaseText.Parent = divider

		-- Divider line
		local line = Instance.new("Frame")
		line.Size = UDim2.new(1, 0, 0, 1)
		line.Position = UDim2.new(0, 0, 1, -1)
		line.BackgroundColor3 = PHASE_COLORS[def.phase] or TEXT_DIM
		line.BackgroundTransparency = 0.7
		line.BorderSizePixel = 0
		line.Parent = divider
	end

	-- Card
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, 0, 0, 72)
	card.BackgroundColor3 = BG_CARD
	card.BorderSizePixel = 0
	card.LayoutOrder = def.phase * 1000 + i
	card.Parent = scroll
	applyCorner(card, 10)

	-- Left accent bar (phase colour)
	local accent = Instance.new("Frame")
	accent.Size = UDim2.new(0, 3, 0.7, 0)
	accent.Position = UDim2.new(0, 0, 0.15, 0)
	accent.BackgroundColor3 = PHASE_COLORS[def.phase] or PURPLE
	accent.BorderSizePixel = 0
	accent.Parent = card
	applyCorner(accent, 2)

	-- Machine name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -110, 0, 26)
	nameLabel.Position = UDim2.new(0, 14, 0, 10)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = def.displayName
	nameLabel.TextColor3 = TEXT_WHITE
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 14
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = card

	-- Income rate
	local incLabel = Instance.new("TextLabel")
	incLabel.Size = UDim2.new(1, -110, 0, 18)
	incLabel.Position = UDim2.new(0, 14, 0, 38)
	incLabel.BackgroundTransparency = 1
	incLabel.Text = "+" .. FormatNumber.format(def.incomePerSecond) .. " chips/s"
	incLabel.TextColor3 = TEXT_GREEN
	incLabel.Font = Enum.Font.Gotham
	incLabel.TextSize = 12
	incLabel.TextXAlignment = Enum.TextXAlignment.Left
	incLabel.Parent = card

	-- Buy button
	local buyBtn = Instance.new("TextButton")
	buyBtn.AnchorPoint = Vector2.new(1, 0.5)
	buyBtn.Position = UDim2.new(1, -10, 0.5, 0)
	buyBtn.Size = UDim2.new(0, 86, 0, 36)
	buyBtn.BackgroundColor3 = GOLD
	buyBtn.BorderSizePixel = 0
	buyBtn.Text = FormatNumber.format(def.cost)
	buyBtn.TextColor3 = Color3.fromRGB(30, 15, 0)
	buyBtn.Font = Enum.Font.GothamBold
	buyBtn.TextSize = 13
	buyBtn.Parent = card
	applyCorner(buyBtn, 8)

	-- Coin dot on button
	local coinDot = Instance.new("Frame")
	coinDot.Size = UDim2.new(0, 10, 0, 10)
	coinDot.Position = UDim2.new(0, 8, 0.5, -5)
	coinDot.BackgroundColor3 = Color3.fromRGB(200, 140, 10)
	coinDot.BorderSizePixel = 0
	coinDot.Parent = buyBtn
	applyCorner(coinDot, 5)

	-- Hover tween on card
	local cardBtn = Instance.new("TextButton")
	cardBtn.Size = UDim2.new(1, 0, 1, 0)
	cardBtn.BackgroundTransparency = 1
	cardBtn.Text = ""
	cardBtn.ZIndex = 2
	cardBtn.Parent = card

	cardBtn.MouseEnter:Connect(function()
		TweenService:Create(card, TweenInfo.new(0.15), { BackgroundColor3 = BG_CARD_HO }):Play()
	end)
	cardBtn.MouseLeave:Connect(function()
		TweenService:Create(card, TweenInfo.new(0.15), { BackgroundColor3 = BG_CARD }):Play()
	end)

	-- Buy button hover
	buyBtn.MouseEnter:Connect(function()
		TweenService:Create(buyBtn, TweenInfo.new(0.1), { BackgroundColor3 = Color3.fromRGB(255, 215, 80) }):Play()
	end)
	buyBtn.MouseLeave:Connect(function()
		TweenService:Create(buyBtn, TweenInfo.new(0.1), { BackgroundColor3 = GOLD }):Play()
	end)

	local machineId = def.id
	buyBtn.MouseButton1Click:Connect(function()
		closePanel()
		PlacementController.beginPlacement(machineId)
	end)
end

-- ── Panel open / close ─────────────────────────────────────────────────────

local isOpen = false

function closePanel()
	isOpen = false
	TweenService:Create(panel,
		TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position = UDim2.new(1, -16, 1, -60), Size = UDim2.new(0, PANEL_W, 0, 0) }
	):Play()
	task.delay(0.2, function() panel.Visible = false end)
	TweenService:Create(toggleBtn, TweenInfo.new(0.1), { BackgroundColor3 = PURPLE }):Play()
end

local function openPanel()
	isOpen = true
	panel.Size = UDim2.new(0, PANEL_W, 0, 0)
	panel.Visible = true
	TweenService:Create(panel,
		TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = UDim2.new(1, -16, 1, -68), Size = UDim2.new(0, PANEL_W, 0, PANEL_H) }
	):Play()
	TweenService:Create(toggleBtn, TweenInfo.new(0.1), { BackgroundColor3 = PURPLE_DIM }):Play()
end

toggleBtn.MouseButton1Click:Connect(function()
	if isOpen then closePanel() else openPanel() end
end)

closeBtn.MouseButton1Click:Connect(function()
	closePanel()
end)
