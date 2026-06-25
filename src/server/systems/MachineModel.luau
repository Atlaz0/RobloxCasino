-- Builds a simple, visible procedural model for a casino machine (we have no art
-- templates, so machines are constructed from parts). Used by PlacementService when a
-- machine is bought, and by PlotService when rebuilding a returning player's machines.

local Shared       = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local FormatNumber = require(Shared.utils.FormatNumber)

local PHASE_COLORS = {
	[1] = Color3.fromRGB(255, 200, 40),  -- gold
	[2] = Color3.fromRGB(170, 90, 230),  -- purple
	[3] = Color3.fromRGB(60, 220, 220),  -- cyan
}

local BASE_HEIGHT = 1
local BODY_HEIGHT = 7
local SCREEN_HEIGHT = 2

local MachineModel = {}

-- `baseCF` is the CFrame of the machine's base center (already on the plot surface).
function MachineModel.build(def, baseCF: CFrame): Model
	local color = PHASE_COLORS[def.phase] or PHASE_COLORS[1]

	local model = Instance.new("Model")
	model.Name = def.id

	local base = Instance.new("Part")
	base.Name = "Base"
	base.Anchored = true
	base.Material = Enum.Material.SmoothPlastic
	base.Color = Color3.fromRGB(40, 38, 50)
	base.Size = Vector3.new(6, BASE_HEIGHT, 6)
	base.CFrame = baseCF
	base.Parent = model

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Anchored = true
	body.Material = Enum.Material.SmoothPlastic
	body.Color = color
	body.Size = Vector3.new(4.5, BODY_HEIGHT, 3.5)
	body.CFrame = baseCF * CFrame.new(0, BASE_HEIGHT / 2 + BODY_HEIGHT / 2, 0)
	body.Parent = model

	local screen = Instance.new("Part")
	screen.Name = "Screen"
	screen.Anchored = true
	screen.Material = Enum.Material.Neon
	screen.Color = color
	screen.Size = Vector3.new(4.7, SCREEN_HEIGHT, 3.7)
	screen.CFrame = baseCF * CFrame.new(0, BASE_HEIGHT / 2 + BODY_HEIGHT + SCREEN_HEIGHT / 2, 0)
	screen.Parent = model

	model.PrimaryPart = base

	-- Floating info label so it's obvious the machine earns money.
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Info"
	billboard.Size = UDim2.new(0, 130, 0, 46)
	billboard.StudsOffset = Vector3.new(0, 7, 0)
	billboard.AlwaysOnTop = false
	billboard.MaxDistance = 250
	billboard.Adornee = screen
	billboard.Parent = screen

	local name = Instance.new("TextLabel")
	name.Size = UDim2.new(1, 0, 0.55, 0)
	name.BackgroundTransparency = 1
	name.Text = def.displayName
	name.TextColor3 = Color3.fromRGB(255, 240, 200)
	name.Font = Enum.Font.GothamBold
	name.TextScaled = true
	name.Parent = billboard

	local income = Instance.new("TextLabel")
	income.Size = UDim2.new(1, 0, 0.45, 0)
	income.Position = UDim2.new(0, 0, 0.55, 0)
	income.BackgroundTransparency = 1
	income.Text = "+" .. FormatNumber.format(def.incomePerSecond) .. "/s"
	income.TextColor3 = Color3.fromRGB(120, 255, 150)
	income.Font = Enum.Font.GothamBold
	income.TextScaled = true
	income.Parent = billboard

	return model
end

return MachineModel
