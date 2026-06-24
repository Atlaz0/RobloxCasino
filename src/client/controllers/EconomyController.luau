local Remotes      = require(game.ReplicatedStorage.Shared.net.Remotes)
local FormatNumber = require(game.ReplicatedStorage.Shared.utils.FormatNumber)

local chipsLabel: TextLabel?
local incomeLabel: TextLabel?

local function bindLabels()
	local gui = game.Players.LocalPlayer.PlayerGui:WaitForChild("HUD", 10)
	if not gui then return end
	chipsLabel  = gui:FindFirstChild("ChipsLabel",  true) :: TextLabel
	incomeLabel = gui:FindFirstChild("IncomeLabel", true) :: TextLabel
end

local function init()
	bindLabels()

	Remotes.ChipsUpdated:Connect(function(total: number)
		if chipsLabel then
			chipsLabel.Text = FormatNumber.format(total) .. " chips"
		end
	end)

	Remotes.IncomeRateUpdated:Connect(function(perSecond: number)
		if incomeLabel then
			incomeLabel.Text = "+" .. FormatNumber.format(perSecond) .. "/s"
		end
	end)
end

return { init = init }
