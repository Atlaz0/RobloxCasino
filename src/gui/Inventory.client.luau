local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

ReplicatedStorage:WaitForChild("Remotes", 15)
local Shared       = ReplicatedStorage:WaitForChild("Shared")
local Remotes      = require(Shared.net.Remotes)
local MachineData  = require(Shared.constants.MachineData)
local GameConfig   = require(Shared.constants.GameConfig)
local FormatNumber = require(Shared.utils.FormatNumber)
local UIStyle      = require(Shared.utils.UIStyle)

local Client = Players.LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("Client")
local PlacementController = require(Client.controllers.PlacementController)

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local BG_DARK    = UIStyle.PANEL_TOP
local BG_PANEL   = UIStyle.PANEL_BOTTOM
local GOLD       = UIStyle.GOLD
local GOLD_LIGHT = UIStyle.GOLD_LIGHT
local ACCENT     = UIStyle.ACCENT
local CARD_BG    = UIStyle.CARD_BG

local function corner(p, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r); c.Parent = p end
local function stroke(p, col, t) local s = Instance.new("UIStroke"); s.Color = col; s.Thickness = t; s.Parent = p end

local items = {}

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "Inventory"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Toggle button
local toggleBtn = UIStyle.toggleButton({
	name = "InventoryToggle",
	text = "Stash",
	accent = UIStyle.ACCENT,
	position = UDim2.new(0, 16, 1, -130),
})
toggleBtn.Parent = screenGui

-- Panel
local PANEL_CLOSED_POS = UDim2.new(0, -340, 1, -606)
local PANEL_OPEN_POS   = UDim2.new(0, 16, 1, -606)

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.new(0, 320, 0, 420)
panel.Position = PANEL_CLOSED_POS
panel.BackgroundColor3 = BG_DARK
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = screenGui
do
	corner(panel, 18)
	stroke(panel, ACCENT, 1.5)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, BG_DARK),
		ColorSequenceKeypoint.new(1, BG_PANEL),
	})
	g.Rotation = 160
	g.Parent = panel
end

-- Header bar
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 48)
header.Position = UDim2.new(0, 0, 0, 0)
header.BackgroundColor3 = UIStyle.HEADER
header.BorderSizePixel = 0
header.ZIndex = 2
header.Parent = panel
do
	corner(header, 18)
	local cover = Instance.new("Frame")
	cover.Size = UDim2.new(1, 0, 0, 18)
	cover.Position = UDim2.new(0, 0, 1, -18)
	cover.BackgroundColor3 = UIStyle.HEADER
	cover.BorderSizePixel = 0
	cover.ZIndex = 2
	cover.Parent = header
end

local headerTitle = Instance.new("TextLabel")
headerTitle.Size = UDim2.new(0.6, 0, 1, 0)
headerTitle.Position = UDim2.new(0, 14, 0, 0)
headerTitle.BackgroundTransparency = 1
headerTitle.Text = "STASH"
headerTitle.TextColor3 = UIStyle.TEXT
headerTitle.TextScaled = true
UIStyle.maxText(headerTitle, 24)
headerTitle.Font = Enum.Font.GothamBlack
headerTitle.TextXAlignment = Enum.TextXAlignment.Left
headerTitle.ZIndex = 3
headerTitle.Parent = header

local itemCountBadge = Instance.new("TextLabel")
itemCountBadge.Name = "ItemCount"
itemCountBadge.Size = UDim2.new(0, 38, 0, 24)
itemCountBadge.Position = UDim2.new(1, -90, 0.5, -12)
itemCountBadge.BackgroundColor3 = UIStyle.PANEL_BOTTOM
itemCountBadge.Text = "0"
itemCountBadge.TextColor3 = GOLD
itemCountBadge.TextScaled = true
UIStyle.maxText(itemCountBadge, 15)
itemCountBadge.Font = Enum.Font.GothamBold
itemCountBadge.ZIndex = 4
itemCountBadge.Parent = header
corner(itemCountBadge, 12)
stroke(itemCountBadge, GOLD, 1)

-- Close button (drawn X)
local closeBtn = UIStyle.closeButton(28)
closeBtn.Position = UDim2.new(1, -38, 0.5, -14)
closeBtn.ZIndex = 5
closeBtn.Parent = header

-- Empty state
local emptyHolder = Instance.new("Frame")
emptyHolder.Size = UDim2.new(1, 0, 1, -56)
emptyHolder.Position = UDim2.new(0, 0, 0, 56)
emptyHolder.BackgroundTransparency = 1
emptyHolder.Visible = false
emptyHolder.Parent = panel

local emptyIcon = Instance.new("TextLabel")
emptyIcon.Size = UDim2.new(1, 0, 0, 60)
emptyIcon.Position = UDim2.new(0, 0, 0.35, -30)
emptyIcon.BackgroundTransparency = 1
emptyIcon.Text = "📦"
emptyIcon.TextScaled = true
emptyIcon.Font = Enum.Font.GothamBold
emptyIcon.Parent = emptyHolder

local emptyLabel = Instance.new("TextLabel")
emptyLabel.Size = UDim2.new(1, -40, 0, 30)
emptyLabel.Position = UDim2.new(0, 20, 0.35, 38)
emptyLabel.BackgroundTransparency = 1
emptyLabel.Text = "Nothing in your stash yet."
emptyLabel.TextColor3 = UIStyle.TEXT_DIM
emptyLabel.TextScaled = true
UIStyle.maxText(emptyLabel, 16)
emptyLabel.Font = Enum.Font.Gotham
emptyLabel.Parent = emptyHolder

-- Scroll area
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -16, 1, -60)
scroll.Position = UDim2.new(0, 8, 0, 54)
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
do
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 4)
	pad.PaddingLeft = UDim.new(0, 4)
	pad.PaddingRight = UDim.new(0, 4)
	pad.PaddingBottom = UDim.new(0, 4)
	pad.Parent = scroll
end

local function rebuild()
	for _, child in scroll:GetChildren() do
		if child:IsA("Frame") then child:Destroy() end
	end

	local count = #items
	itemCountBadge.Text = tostring(count)
	emptyHolder.Visible = (count == 0)
	scroll.Visible = (count > 0)

	for index, item in items do
		local def = MachineData[item.id]
		if def then
			local card = Instance.new("Frame")
			card.Size = UDim2.new(1, 0, 0, 64)
			card.BackgroundColor3 = CARD_BG
			card.BorderSizePixel = 0
			card.LayoutOrder = index
			card.Parent = scroll
			do
				corner(card, 12)
				stroke(card, Color3.fromRGB(74, 86, 82), 1)
				local g = Instance.new("UIGradient")
				g.Color = ColorSequence.new(UIStyle.PANEL_BOTTOM, CARD_BG)
				g.Rotation = 0
				g.Parent = card
			end

			-- Left accent bar
			local accentBar = Instance.new("Frame")
			accentBar.Size = UDim2.new(0, 5, 1, -16)
			accentBar.Position = UDim2.new(0, 0, 0, 8)
			accentBar.BackgroundColor3 = ACCENT
			accentBar.BorderSizePixel = 0
			accentBar.Parent = card
			corner(accentBar, 3)

			-- Machine name
			local nameLabel = Instance.new("TextLabel")
			nameLabel.Size = UDim2.new(1, -170, 1, 0)
			nameLabel.Position = UDim2.new(0, 14, 0, 0)
			nameLabel.BackgroundTransparency = 1
			nameLabel.Text = def.displayName
			nameLabel.TextColor3 = UIStyle.TEXT
			nameLabel.Font = Enum.Font.GothamBold
			nameLabel.TextScaled = true
			UIStyle.maxText(nameLabel, 18)
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.Parent = card
			do
				local np = Instance.new("UIPadding")
				np.PaddingTop = UDim.new(0, 12)
				np.PaddingBottom = UDim.new(0, 12)
				np.Parent = nameLabel
			end

			-- Place button
			local placeBtn = Instance.new("TextButton")
			placeBtn.Size = UDim2.new(0, 72, 0, 36)
			placeBtn.Position = UDim2.new(1, -158, 0.5, -18)
			placeBtn.BackgroundColor3 = UIStyle.NEON_BLUE
			placeBtn.BorderSizePixel = 0
			placeBtn.Text = "Place"
			placeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			placeBtn.Font = Enum.Font.GothamBold
			placeBtn.TextScaled = true
			UIStyle.maxText(placeBtn, 16)
			placeBtn.AutoButtonColor = false
			placeBtn.Parent = card
			do
				corner(placeBtn, 9)
				local g = Instance.new("UIGradient")
				g.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, UIStyle.NEON_BLUE),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(132, 154, 162)),
				})
				g.Rotation = 90
				g.Parent = placeBtn
			end
			placeBtn.MouseEnter:Connect(function()
				TweenService:Create(placeBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(140, 162, 170)}):Play()
			end)
			placeBtn.MouseLeave:Connect(function()
				TweenService:Create(placeBtn, TweenInfo.new(0.1), {BackgroundColor3 = UIStyle.NEON_BLUE}):Play()
			end)

			-- Sell button
			local sellBtn = Instance.new("TextButton")
			sellBtn.Size = UDim2.new(0, 80, 0, 36)
			sellBtn.Position = UDim2.new(1, -80, 0.5, -18)
			sellBtn.BackgroundColor3 = UIStyle.GOLD_DEEP
			sellBtn.BorderSizePixel = 0
			sellBtn.Text = ""
			sellBtn.AutoButtonColor = false
			sellBtn.Parent = card
			do
				corner(sellBtn, 9)
				local g = Instance.new("UIGradient")
				g.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, UIStyle.GOLD_DEEP),
					ColorSequenceKeypoint.new(1, UIStyle.GOLD),
				})
				g.Rotation = 90
				g.Parent = sellBtn
			end
			local sellChip = UIStyle.chipIcon(16)
			sellChip.AnchorPoint = Vector2.new(0, 0.5)
			sellChip.Position = UDim2.new(0, 7, 0.5, 0)
			sellChip.ZIndex = 3
			sellChip.Parent = sellBtn

			local sellPrice = Instance.new("TextLabel")
			sellPrice.Size = UDim2.new(1, -30, 1, -10)
			sellPrice.Position = UDim2.new(0, 27, 0.5, 0)
			sellPrice.AnchorPoint = Vector2.new(0, 0.5)
			sellPrice.BackgroundTransparency = 1
			sellPrice.Text = FormatNumber.format(GameConfig.machineSellValue(def))
			sellPrice.TextColor3 = UIStyle.BG_DARK
			sellPrice.Font = Enum.Font.GothamBold
			sellPrice.TextScaled = true
			UIStyle.maxText(sellPrice, 16)
			sellPrice.TextXAlignment = Enum.TextXAlignment.Center
			sellPrice.ZIndex = 3
			sellPrice.Parent = sellBtn
			sellBtn.MouseEnter:Connect(function()
				TweenService:Create(sellBtn, TweenInfo.new(0.1), {BackgroundColor3 = UIStyle.GOLD}):Play()
			end)
			sellBtn.MouseLeave:Connect(function()
				TweenService:Create(sellBtn, TweenInfo.new(0.1), {BackgroundColor3 = UIStyle.GOLD_DEEP}):Play()
			end)

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
local function openPanel()
	panel.Position = PANEL_CLOSED_POS
	panel.Visible = true
	TweenService:Create(panel, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = PANEL_OPEN_POS}):Play()
end
local function closePanel()
	TweenService:Create(panel, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = PANEL_CLOSED_POS}):Play()
	task.delay(0.2, function() panel.Visible = false end)
end

toggleBtn.MouseButton1Click:Connect(function()
	open = not open
	if open then openPanel() else closePanel() end
end)

closeBtn.MouseButton1Click:Connect(function()
	open = false
	closePanel()
end)

rebuild()
