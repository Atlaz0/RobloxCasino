-- Inventory panel: machines you've picked up off your plot. Re-place them (free) or sell
-- them for chips. Mirrors the server's profile.inventory via the InventoryUpdated event.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

ReplicatedStorage:WaitForChild("Remotes", 15)
local Shared       = ReplicatedStorage:WaitForChild("Shared")
local Remotes      = require(Shared.net.Remotes)
local MachineData  = require(Shared.constants.MachineData)
local GameConfig   = require(Shared.constants.GameConfig)
local FormatNumber = require(Shared.utils.FormatNumber)

local Client = Players.LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("Client")
local PlacementController = require(Client.controllers.PlacementController)

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local PANEL_BG = Color3.fromRGB(18, 12, 28)
local CARD_BG  = Color3.fromRGB(28, 20, 44)
local ACCENT   = Color3.fromRGB(180, 130, 255)
local GOLD     = Color3.fromRGB(255, 230, 120)

local function corner(p, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r); c.Parent = p end
local function stroke(p, col, t) local s = Instance.new("UIStroke"); s.Color = col; s.Thickness = t; s.Parent = p end

local items = {} -- mirror of server inventory: { { id, level } }

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "Inventory"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Toggle button (bottom-left, above the Daily button).
local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "InventoryToggle"
toggleBtn.Size = UDim2.new(0, 130, 0, 48)
toggleBtn.Position = UDim2.new(0, 16, 1, -176)
toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 24, 60)
toggleBtn.Text = "🎒 Inventory"
toggleBtn.TextColor3 = GOLD
toggleBtn.TextScaled = true
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.BorderSizePixel = 0
toggleBtn.Parent = screenGui
corner(toggleBtn, 12)
stroke(toggleBtn, ACCENT, 2)
do local pad = Instance.new("UIPadding"); pad.PaddingTop = UDim.new(0, 8); pad.PaddingBottom = UDim.new(0, 8); pad.Parent = toggleBtn end

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.new(0, 320, 0, 420)
panel.Position = UDim2.new(0, 16, 1, -606)
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
title.Text = "Inventory"
title.TextColor3 = GOLD
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local emptyLabel = Instance.new("TextLabel")
emptyLabel.Size = UDim2.new(1, -24, 0, 30)
emptyLabel.Position = UDim2.new(0, 12, 0, 54)
emptyLabel.BackgroundTransparency = 1
emptyLabel.Text = "Empty — pick up a machine to store it here."
emptyLabel.TextColor3 = Color3.fromRGB(190, 180, 210)
emptyLabel.TextScaled = true
emptyLabel.Font = Enum.Font.Gotham
emptyLabel.TextXAlignment = Enum.TextXAlignment.Left
emptyLabel.Visible = false
emptyLabel.Parent = panel

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -16, 1, -56)
scroll.Position = UDim2.new(0, 8, 0, 50)
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
do local pad = Instance.new("UIPadding"); pad.PaddingTop = UDim.new(0, 4); pad.PaddingLeft = UDim.new(0, 4); pad.PaddingRight = UDim.new(0, 4); pad.Parent = scroll end

local function makeRowButton(parent, text, color, posX, width)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0, width, 0, 34)
	b.Position = UDim2.new(1, posX, 0.5, -17)
	b.BackgroundColor3 = color
	b.BorderSizePixel = 0
	b.Text = text
	b.TextColor3 = Color3.fromRGB(255, 255, 255)
	b.Font = Enum.Font.GothamBold
	b.TextScaled = true
	b.Parent = parent
	corner(b, 8)
	local pad = Instance.new("UIPadding"); pad.PaddingTop = UDim.new(0, 7); pad.PaddingBottom = UDim.new(0, 7); pad.Parent = b
	return b
end

local function rebuild()
	for _, child in scroll:GetChildren() do
		if child:IsA("Frame") then child:Destroy() end
	end

	emptyLabel.Visible = (#items == 0)

	for index, item in items do
		local def = MachineData[item.id]
		if def then
			local card = Instance.new("Frame")
			card.Size = UDim2.new(1, 0, 0, 56)
			card.BackgroundColor3 = CARD_BG
			card.BorderSizePixel = 0
			card.LayoutOrder = index
			card.Parent = scroll
			corner(card, 10)

			local name = Instance.new("TextLabel")
			name.Size = UDim2.new(1, -150, 1, 0)
			name.Position = UDim2.new(0, 12, 0, 0)
			name.BackgroundTransparency = 1
			name.Text = def.displayName
			name.TextColor3 = Color3.fromRGB(255, 240, 200)
			name.Font = Enum.Font.GothamBold
			name.TextScaled = true
			name.TextXAlignment = Enum.TextXAlignment.Left
			name.Parent = card
			local np = Instance.new("UIPadding"); np.PaddingTop = UDim.new(0, 16); np.PaddingBottom = UDim.new(0, 16); np.Parent = name

			local placeBtn = makeRowButton(card, "Place", Color3.fromRGB(60, 120, 220), -138, 64)
			local sellBtn  = makeRowButton(card, "🪙 " .. FormatNumber.format(GameConfig.machineSellValue(def)),
				Color3.fromRGB(40, 150, 80), -70, 66)

			local capturedIndex = index
			local capturedId = item.id
			placeBtn.MouseButton1Click:Connect(function()
				panel.Visible = false
				PlacementController.beginInventoryPlacement(capturedIndex, capturedId)
			end)
			sellBtn.MouseButton1Click:Connect(function()
				pcall(function()
					Remotes.RequestSellInventory:InvokeServer(capturedIndex)
				end)
			end)
		end
	end
end

Remotes.InventoryUpdated.OnClientEvent:Connect(function(serverItems)
	items = serverItems or {}
	rebuild()
end)

local open = false
toggleBtn.MouseButton1Click:Connect(function()
	open = not open
	panel.Visible = open
end)

rebuild()
