local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

ReplicatedStorage:WaitForChild("Remotes", 15)

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MachineData  = require(Shared.constants.MachineData)
local FormatNumber = require(Shared.utils.FormatNumber)

local Client = Players.LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("Client")
local PlacementController = require(Client.controllers.PlacementController)

-- Shared style tokens (match HUD / DailyReward).
local PANEL_BG = Color3.fromRGB(18, 12, 28)
local CARD_BG  = Color3.fromRGB(28, 20, 44)
local ACCENT   = Color3.fromRGB(180, 130, 255)
local GOLD     = Color3.fromRGB(255, 230, 120)
local GREEN    = Color3.fromRGB(120, 255, 150)

local function corner(parent: Instance, radius: number)
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, radius); c.Parent = parent
end
local function stroke(parent: Instance, color: Color3, thickness: number)
	local s = Instance.new("UIStroke"); s.Color = color; s.Thickness = thickness; s.Parent = parent
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

-- Toggle button (bottom-right), styled like the Daily button.
local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "ShopToggle"
toggleBtn.Size = UDim2.new(0, 130, 0, 48)
toggleBtn.Position = UDim2.new(1, -146, 1, -120)
toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 24, 60)
toggleBtn.Text = "🏪 Shop"
toggleBtn.TextColor3 = GOLD
toggleBtn.TextScaled = true
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.BorderSizePixel = 0
toggleBtn.Parent = screenGui
corner(toggleBtn, 12)
stroke(toggleBtn, ACCENT, 2)
do
	local pad = Instance.new("UIPadding"); pad.PaddingTop = UDim.new(0, 8); pad.PaddingBottom = UDim.new(0, 8); pad.Parent = toggleBtn
end

-- Panel
local panel = Instance.new("Frame")
panel.Name = "ShopPanel"
panel.Size = UDim2.new(0, 330, 0, 500)
panel.Position = UDim2.new(1, -346, 1, -636)
panel.BackgroundColor3 = PANEL_BG
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = screenGui
corner(panel, 16)
stroke(panel, ACCENT, 1.5)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -24, 0, 34)
title.Position = UDim2.new(0, 12, 0, 10)
title.BackgroundTransparency = 1
title.Text = "Casino Shop"
title.TextColor3 = GOLD
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local hint = Instance.new("TextLabel")
hint.Size = UDim2.new(1, -24, 0, 20)
hint.Position = UDim2.new(0, 12, 0, 44)
hint.BackgroundTransparency = 1
hint.Text = "Buy a machine, then click your plot to place it."
hint.TextColor3 = Color3.fromRGB(190, 180, 210)
hint.TextScaled = true
hint.Font = Enum.Font.Gotham
hint.TextXAlignment = Enum.TextXAlignment.Left
hint.Parent = panel

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -16, 1, -76)
scroll.Position = UDim2.new(0, 8, 0, 70)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 4
scroll.ScrollBarImageColor3 = ACCENT
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = panel

local layout = Instance.new("UIListLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 6)
layout.Parent = scroll

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 4)
padding.PaddingLeft = UDim.new(0, 4)
padding.PaddingRight = UDim.new(0, 4)
padding.Parent = scroll

local function phaseLabel(phase: number): Frame
	local lf = Instance.new("Frame")
	lf.Size = UDim2.new(1, 0, 0, 24)
	lf.BackgroundTransparency = 1
	lf.LayoutOrder = phase * 1000 - 1

	local lt = Instance.new("TextLabel")
	lt.Size = UDim2.new(1, -8, 1, 0)
	lt.Position = UDim2.new(0, 8, 0, 0)
	lt.BackgroundTransparency = 1
	local names = { "Phase 1 — The Floor", "Phase 2 — The Resort", "Phase 3 — The Strip" }
	lt.Text = names[phase] or ("Phase " .. phase)
	lt.TextColor3 = ACCENT
	lt.Font = Enum.Font.GothamBold
	lt.TextScaled = true
	lt.TextXAlignment = Enum.TextXAlignment.Left
	lt.Parent = lf
	return lf
end

local currentPhase = 0
for i, def in ipairs(sortedMachines) do
	if def.phase ~= currentPhase then
		currentPhase = def.phase
		phaseLabel(def.phase).Parent = scroll
	end

	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, 0, 0, 68)
	card.BackgroundColor3 = CARD_BG
	card.BorderSizePixel = 0
	card.LayoutOrder = def.phase * 1000 + i
	card.Parent = scroll
	corner(card, 10)

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -120, 0, 26)
	nameLabel.Position = UDim2.new(0, 12, 0, 8)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = def.displayName
	nameLabel.TextColor3 = Color3.fromRGB(255, 240, 200)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextScaled = true
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = card

	local incomeLabel = Instance.new("TextLabel")
	incomeLabel.Size = UDim2.new(1, -120, 0, 20)
	incomeLabel.Position = UDim2.new(0, 12, 0, 38)
	incomeLabel.BackgroundTransparency = 1
	incomeLabel.Text = "+" .. FormatNumber.format(def.incomePerSecond) .. "/s"
	incomeLabel.TextColor3 = GREEN
	incomeLabel.Font = Enum.Font.Gotham
	incomeLabel.TextScaled = true
	incomeLabel.TextXAlignment = Enum.TextXAlignment.Left
	incomeLabel.Parent = card

	local buyBtn = Instance.new("TextButton")
	buyBtn.Size = UDim2.new(0, 96, 0, 40)
	buyBtn.Position = UDim2.new(1, -106, 0.5, -20)
	buyBtn.BackgroundColor3 = Color3.fromRGB(255, 190, 30)
	buyBtn.BorderSizePixel = 0
	buyBtn.Text = "🪙 " .. FormatNumber.format(def.cost)
	buyBtn.TextColor3 = Color3.fromRGB(20, 10, 0)
	buyBtn.Font = Enum.Font.GothamBold
	buyBtn.TextScaled = true
	buyBtn.Parent = card
	corner(buyBtn, 8)
	do
		local pad = Instance.new("UIPadding"); pad.PaddingTop = UDim.new(0, 8); pad.PaddingBottom = UDim.new(0, 8); pad.Parent = buyBtn
	end

	local machineId = def.id
	buyBtn.MouseButton1Click:Connect(function()
		panel.Visible = false
		PlacementController.beginPlacement(machineId)
	end)
end

local open = false
toggleBtn.MouseButton1Click:Connect(function()
	open = not open
	panel.Visible = open
end)
