local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for server to create Remotes before requiring anything
ReplicatedStorage:WaitForChild("Remotes", 15)

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MachineData  = require(Shared.constants.MachineData)
local FormatNumber = require(Shared.utils.FormatNumber)

local Client = Players.LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("Client")
local PlacementController = require(Client.controllers.PlacementController)

-- Sort machines by phase then cost
local sortedMachines = {}
for _, def in pairs(MachineData) do
	table.insert(sortedMachines, def)
end
table.sort(sortedMachines, function(a, b)
	if a.phase ~= b.phase then return a.phase < b.phase end
	return a.cost < b.cost
end)

-- Build ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "Shop"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

-- Toggle button (bottom-right)
local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "ShopToggle"
toggleBtn.Size = UDim2.new(0, 110, 0, 44)
toggleBtn.Position = UDim2.new(1, -122, 1, -58)
toggleBtn.BackgroundColor3 = Color3.fromRGB(120, 60, 220)
toggleBtn.BorderSizePixel = 0
toggleBtn.Text = "🏪  Shop"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.TextScaled = true
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.Parent = screenGui
local tc = Instance.new("UICorner"); tc.CornerRadius = UDim.new(0, 10); tc.Parent = toggleBtn

-- Panel
local panel = Instance.new("Frame")
panel.Name = "ShopPanel"
panel.Size = UDim2.new(0, 320, 0, 480)
panel.Position = UDim2.new(1, -332, 1, -550)
panel.BackgroundColor3 = Color3.fromRGB(10, 8, 18)
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = screenGui
local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(0, 14); pc.Parent = panel
local ps = Instance.new("UIStroke"); ps.Color = Color3.fromRGB(120, 60, 220); ps.Thickness = 1.5; ps.Parent = panel

-- Panel title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 40)
title.Position = UDim2.new(0, 10, 0, 8)
title.BackgroundTransparency = 1
title.Text = "CASINO SHOP"
title.TextColor3 = Color3.fromRGB(200, 150, 255)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.Parent = panel

-- Scrolling list
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -16, 1, -60)
scroll.Position = UDim2.new(0, 8, 0, 54)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 4
scroll.ScrollBarImageColor3 = Color3.fromRGB(120, 60, 220)
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = panel

local layout = Instance.new("UIListLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 6)
layout.Parent = scroll

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 4)
padding.Parent = scroll

-- Phase label helper
local currentPhase = 0
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
	lt.TextColor3 = Color3.fromRGB(160, 110, 255)
	lt.Font = Enum.Font.GothamBold
	lt.TextScaled = true
	lt.TextXAlignment = Enum.TextXAlignment.Left
	lt.Parent = lf
	return lf
end

-- Card for each machine
for i, def in ipairs(sortedMachines) do
	if def.phase ~= currentPhase then
		currentPhase = def.phase
		phaseLabel(def.phase).Parent = scroll
	end

	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, 0, 0, 68)
	card.BackgroundColor3 = Color3.fromRGB(22, 16, 38)
	card.BorderSizePixel = 0
	card.LayoutOrder = def.phase * 1000 + i
	card.Parent = scroll
	local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0, 10); cc.Parent = card

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -110, 0, 26)
	nameLabel.Position = UDim2.new(0, 10, 0, 8)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = def.displayName
	nameLabel.TextColor3 = Color3.fromRGB(255, 240, 200)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextScaled = true
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = card

	local incomeLabel = Instance.new("TextLabel")
	incomeLabel.Size = UDim2.new(1, -110, 0, 20)
	incomeLabel.Position = UDim2.new(0, 10, 0, 36)
	incomeLabel.BackgroundTransparency = 1
	incomeLabel.Text = "+" .. FormatNumber.format(def.incomePerSecond) .. "/s"
	incomeLabel.TextColor3 = Color3.fromRGB(120, 255, 150)
	incomeLabel.Font = Enum.Font.Gotham
	incomeLabel.TextScaled = true
	incomeLabel.TextXAlignment = Enum.TextXAlignment.Left
	incomeLabel.Parent = card

	local buyBtn = Instance.new("TextButton")
	buyBtn.Size = UDim2.new(0, 90, 0, 38)
	buyBtn.Position = UDim2.new(1, -100, 0.5, -19)
	buyBtn.BackgroundColor3 = Color3.fromRGB(255, 190, 30)
	buyBtn.BorderSizePixel = 0
	buyBtn.Text = "🪙 " .. FormatNumber.format(def.cost)
	buyBtn.TextColor3 = Color3.fromRGB(20, 10, 0)
	buyBtn.Font = Enum.Font.GothamBold
	buyBtn.TextScaled = true
	buyBtn.Parent = card
	local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 8); bc.Parent = buyBtn

	local machineId = def.id
	buyBtn.MouseButton1Click:Connect(function()
		panel.Visible = false
		PlacementController.beginPlacement(machineId)
	end)
end

-- Toggle panel open/close
local open = false
toggleBtn.MouseButton1Click:Connect(function()
	open = not open
	panel.Visible = open
end)
