local Players           = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")

ReplicatedStorage:WaitForChild("Remotes", 15)
local Shared       = ReplicatedStorage:WaitForChild("Shared")
local Remotes      = require(Shared.net.Remotes)
local MachineData  = require(Shared.constants.MachineData)
local GameConfig   = require(Shared.constants.GameConfig)
local FormatNumber = require(Shared.utils.FormatNumber)
local UIStyle      = require(Shared.utils.UIStyle)

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local BG_DARK    = UIStyle.PANEL_TOP
local BG_PANEL   = UIStyle.PANEL_BOTTOM
local GOLD       = UIStyle.GOLD
local GOLD_LIGHT = UIStyle.GOLD_LIGHT
local ACCENT     = UIStyle.ACCENT
local NEON_GREEN = UIStyle.NEON_GREEN
local CARD_BG    = UIStyle.CARD_BG

-- How far the player can walk from the machine before its menu auto-closes.
local AUTO_CLOSE_DISTANCE = 30

local function corner(p, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r); c.Parent = p end
local function stroke(p, col, t) local s = Instance.new("UIStroke"); s.Color = col; s.Thickness = t; s.Parent = p end

local currentUid: string? = nil
local currentModel: Instance? = nil

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MachineMenu"
screenGui.ResetOnSpawn = false
screenGui.Enabled = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.new(0, 320, 0, 220)
panel.Position = UDim2.new(0.5, -160, 0.5, -110)
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
	g.Rotation = 135
	g.Parent = panel
end

local panelScale = Instance.new("UIScale")
panelScale.Scale = 0.1
panelScale.Parent = panel

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

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -50, 1, 0)
title.Position = UDim2.new(0, 14, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Machine"
title.TextColor3 = UIStyle.TEXT
title.TextScaled = true
title.Font = Enum.Font.GothamBlack
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 3
title.Parent = header
UIStyle.maxText(title, 22)

-- Close button (drawn X)
local closeBtn = UIStyle.closeButton(30)
closeBtn.Position = UDim2.new(1, -40, 0, 9)
closeBtn.ZIndex = 5
closeBtn.Parent = panel

-- Income info line
local info = Instance.new("TextLabel")
info.Size = UDim2.new(1, -24, 0, 28)
info.Position = UDim2.new(0, 14, 0, 56)
info.BackgroundTransparency = 1
info.Text = ""
info.TextColor3 = NEON_GREEN
info.TextScaled = true
info.Font = Enum.Font.GothamBold
info.TextXAlignment = Enum.TextXAlignment.Left
info.Parent = panel
UIStyle.maxText(info, 15)

-- Pick Up button
local pickupBtn = Instance.new("TextButton")
pickupBtn.Name = "PickupButton"
pickupBtn.Size = UDim2.new(1, -24, 0, 46)
pickupBtn.Position = UDim2.new(0, 12, 0, 92)
pickupBtn.BackgroundColor3 = UIStyle.BTN_BLUE
pickupBtn.BorderSizePixel = 0
pickupBtn.Text = "Pick Up"
pickupBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
pickupBtn.Font = Enum.Font.GothamBold
pickupBtn.TextScaled = true
pickupBtn.AutoButtonColor = false
pickupBtn.Parent = panel
corner(pickupBtn, 12)
UIStyle.maxText(pickupBtn, 18)
do
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, UIStyle.BTN_BLUE),
		ColorSequenceKeypoint.new(1, UIStyle.BTN_BLUE_LT),
	})
	g.Rotation = 90
	g.Parent = pickupBtn
	local pad = Instance.new("UIPadding"); pad.PaddingTop = UDim.new(0, 10); pad.PaddingBottom = UDim.new(0, 10); pad.Parent = pickupBtn
end
pickupBtn.MouseEnter:Connect(function()
	TweenService:Create(pickupBtn, TweenInfo.new(0.12), {BackgroundColor3 = UIStyle.BTN_BLUE_LT}):Play()
end)
pickupBtn.MouseLeave:Connect(function()
	TweenService:Create(pickupBtn, TweenInfo.new(0.12), {BackgroundColor3 = UIStyle.BTN_BLUE}):Play()
end)

-- Sell button
local sellBtn = Instance.new("TextButton")
sellBtn.Name = "SellButton"
sellBtn.Size = UDim2.new(1, -24, 0, 46)
sellBtn.Position = UDim2.new(0, 12, 0, 146)
sellBtn.BackgroundColor3 = UIStyle.BTN_RED
sellBtn.BorderSizePixel = 0
sellBtn.Text = "Sell"
sellBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
sellBtn.Font = Enum.Font.GothamBold
sellBtn.TextScaled = true
sellBtn.AutoButtonColor = false
sellBtn.Parent = panel
corner(sellBtn, 12)
UIStyle.maxText(sellBtn, 18)
do
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, UIStyle.BTN_RED),
		ColorSequenceKeypoint.new(1, UIStyle.BTN_RED_LT),
	})
	g.Rotation = 90
	g.Parent = sellBtn
	local pad = Instance.new("UIPadding"); pad.PaddingTop = UDim.new(0, 10); pad.PaddingBottom = UDim.new(0, 10); pad.Parent = sellBtn
end

local sellChip = UIStyle.chipIcon(16)
sellChip.Name = "SellChip"
sellChip.AnchorPoint = Vector2.new(1, 0.5)
sellChip.Position = UDim2.new(1, -64, 0.5, 0)
sellChip.ZIndex = sellBtn.ZIndex + 1
sellChip.Parent = sellBtn
sellBtn.MouseEnter:Connect(function()
	TweenService:Create(sellBtn, TweenInfo.new(0.12), {BackgroundColor3 = UIStyle.BTN_RED_LT}):Play()
end)
sellBtn.MouseLeave:Connect(function()
	TweenService:Create(sellBtn, TweenInfo.new(0.12), {BackgroundColor3 = UIStyle.BTN_RED}):Play()
end)

local function closeMenu()
	if not panel.Visible then return end
	TweenService:Create(panelScale, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = 0.05}):Play()
	task.delay(0.15, function()
		panel.Visible = false
		panelScale.Scale = 0.1
	end)
	currentUid = nil
	currentModel = nil
end

local function openMenu(model: Instance)
	local uid = model:GetAttribute("Uid")
	local machineId = model:GetAttribute("MachineId")
	local def = machineId and MachineData[machineId]
	if not uid or not def then return end

	currentUid = uid
	currentModel = model
	title.Text = def.displayName
	sellBtn.Text = "Sell   " .. FormatNumber.format(GameConfig.machineSellValue(def))
	info.Text = "+" .. FormatNumber.format(def.incomePerSecond) .. " chips/sec"
	panelScale.Scale = 0.1
	panel.Visible = true
	TweenService:Create(panelScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
end

-- Auto-close the menu once the player walks away from the machine (or it's removed).
RunService.Heartbeat:Connect(function()
	if not panel.Visible or not currentModel then return end

	if not currentModel.Parent then
		closeMenu()
		return
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local pivotOk, pivot = pcall(function()
		return (currentModel :: any):GetPivot().Position
	end)
	if not pivotOk then return end

	if (root.Position - pivot).Magnitude > AUTO_CLOSE_DISTANCE then
		closeMenu()
	end
end)

local function machineFromDetector(cd: ClickDetector): Instance?
	local inst: Instance? = cd.Parent
	while inst and inst ~= workspace do
		if inst:GetAttribute("Uid") then return inst end
		inst = inst.Parent
	end
	return nil
end

closeBtn.MouseButton1Click:Connect(closeMenu)

UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == Enum.KeyCode.Escape and panel.Visible then
		closeMenu()
	end
end)

pickupBtn.MouseButton1Click:Connect(function()
	if not currentUid then return end
	local ok, result = pcall(function()
		return Remotes.RequestPickupMachine:InvokeServer(currentUid)
	end)
	closeMenu()
	if not (ok and result and result.success) then
		warn("Pickup failed:", ok and result and result.reason)
	end
end)

sellBtn.MouseButton1Click:Connect(function()
	if not currentUid then return end
	pcall(function()
		Remotes.RequestSellMachine:InvokeServer(currentUid)
	end)
	closeMenu()
end)

local function hookDetector(cd: Instance)
	if not cd:IsA("ClickDetector") then return end
	cd.MouseClick:Connect(function()
		local model = machineFromDetector(cd)
		if model then
			openMenu(model)
		end
	end)
end

for _, cd in CollectionService:GetTagged("MachineClick") do
	hookDetector(cd)
end
CollectionService:GetInstanceAddedSignal("MachineClick"):Connect(hookDetector)
