-- Clicking a placed machine opens this styled menu: pick it up into the inventory, or
-- sell it for chips. The ClickDetectors are tagged "MachineClick" by the server.

local Players           = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

ReplicatedStorage:WaitForChild("Remotes", 15)
local Shared       = ReplicatedStorage:WaitForChild("Shared")
local Remotes      = require(Shared.net.Remotes)
local MachineData  = require(Shared.constants.MachineData)
local GameConfig   = require(Shared.constants.GameConfig)
local FormatNumber = require(Shared.utils.FormatNumber)

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local PANEL_BG = Color3.fromRGB(18, 12, 28)
local ACCENT   = Color3.fromRGB(180, 130, 255)
local GOLD     = Color3.fromRGB(255, 230, 120)

local function corner(p, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r); c.Parent = p end
local function stroke(p, col, t) local s = Instance.new("UIStroke"); s.Color = col; s.Thickness = t; s.Parent = p end

local currentUid: string? = nil

-- UI ------------------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MachineMenu"
screenGui.ResetOnSpawn = false
screenGui.Enabled = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.new(0, 300, 0, 190)
panel.Position = UDim2.new(0.5, -150, 0.5, -95)
panel.BackgroundColor3 = PANEL_BG
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = screenGui
corner(panel, 16)
stroke(panel, ACCENT, 1.5)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -24, 0, 32)
title.Position = UDim2.new(0, 12, 0, 12)
title.BackgroundTransparency = 1
title.Text = "Machine"
title.TextColor3 = GOLD
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local info = Instance.new("TextLabel")
info.Size = UDim2.new(1, -24, 0, 24)
info.Position = UDim2.new(0, 12, 0, 46)
info.BackgroundTransparency = 1
info.Text = ""
info.TextColor3 = Color3.fromRGB(120, 255, 150)
info.TextScaled = true
info.Font = Enum.Font.Gotham
info.TextXAlignment = Enum.TextXAlignment.Left
info.Parent = panel

local function makeButton(text, color, posY)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, -24, 0, 38)
	b.Position = UDim2.new(0, 12, 0, posY)
	b.BackgroundColor3 = color
	b.BorderSizePixel = 0
	b.Text = text
	b.TextColor3 = Color3.fromRGB(255, 255, 255)
	b.Font = Enum.Font.GothamBold
	b.TextScaled = true
	b.Parent = panel
	corner(b, 10)
	local pad = Instance.new("UIPadding"); pad.PaddingTop = UDim.new(0, 8); pad.PaddingBottom = UDim.new(0, 8); pad.Parent = b
	return b
end

local pickupBtn = makeButton("📦 Pick Up", Color3.fromRGB(60, 120, 220), 80)
local sellBtn   = makeButton("💰 Sell", Color3.fromRGB(40, 150, 80), 124)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 26, 0, 26)
closeBtn.Position = UDim2.new(1, -34, 0, 10)
closeBtn.BackgroundColor3 = Color3.fromRGB(60, 40, 70)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = panel
corner(closeBtn, 8)

local function closeMenu()
	panel.Visible = false
	currentUid = nil
end

local function openMenu(model: Instance)
	local uid = model:GetAttribute("Uid")
	local machineId = model:GetAttribute("MachineId")
	local def = machineId and MachineData[machineId]
	if not uid or not def then return end

	currentUid = uid
	title.Text = def.displayName
	sellBtn.Text = "💰 Sell  (🪙 " .. FormatNumber.format(GameConfig.machineSellValue(def)) .. ")"
	info.Text = "+" .. FormatNumber.format(def.incomePerSecond) .. "/s"
	panel.Visible = true
end

-- Walks up from a clicked part to the machine model (the one carrying the Uid attribute).
local function machineFromDetector(cd: ClickDetector): Instance?
	local inst: Instance? = cd.Parent
	while inst and inst ~= workspace do
		if inst:GetAttribute("Uid") then return inst end
		inst = inst.Parent
	end
	return nil
end

closeBtn.MouseButton1Click:Connect(closeMenu)

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

-- Wire every machine ClickDetector (existing + future).
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
