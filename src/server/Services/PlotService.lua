local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local ControllersFolder = script.Parent.Parent:WaitForChild("Controllers")
local PlotController = require(ControllersFolder:WaitForChild("PlotController"))

local PlotService = {}

function PlotService:Init(services)
	self.Services = services
	self.PlotByPlayer = {}
	self.ActivePlots = {}

	self:BuildPlotsFolder()

	RunService.Heartbeat:Connect(function(dt)
		for _, plotController in pairs(self.ActivePlots) do
			plotController:Update(dt)
		end
	end)
end

function PlotService:BuildPlotsFolder()
	local existing = Workspace:FindFirstChild("Plots")
	if existing then
		existing:Destroy()
	end

	local plots = Instance.new("Folder")
	plots.Name = "Plots"
	plots.Parent = Workspace
	self.PlotsFolder = plots
end

function PlotService:PlayerAdded(player)
	if self.PlotByPlayer[player] then
		return
	end

	local plotModel = Instance.new("Model")
	plotModel.Name = "Plot_" .. player.UserId
	plotModel.Parent = self.PlotsFolder

	local plotController = PlotController.new(player, plotModel, self.Services)
	self.PlotByPlayer[player] = plotController
	self.ActivePlots[player] = plotController

	print("[PlotService] Assigned prototype plot to", player.Name)
end

function PlotService:PlayerRemoving(player)
	local plotController = self.PlotByPlayer[player]
	if plotController then
		plotController:Destroy()
	end

	self.PlotByPlayer[player] = nil
	self.ActivePlots[player] = nil
end

function PlotService:GetPlotController(player)
	return self.PlotByPlayer[player]
end

function PlotService:RefreshPlayerPlot(player)
	local plotController = self:GetPlotController(player)
	if plotController then
		plotController:Refresh()
	end
end

return PlotService
