local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ControllersFolder = script.Parent

local IntakeConveyorController = require(ControllersFolder:WaitForChild("IntakeConveyorController"))
local SlotController = require(ControllersFolder:WaitForChild("SlotController"))
local TargetingController = require(ControllersFolder:WaitForChild("TargetingController"))
local AimController = require(ControllersFolder:WaitForChild("AimController"))
local VFXController = require(ControllersFolder:WaitForChild("VFXController"))

local ProgressionConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ProgressionConfig"))

local PlotController = {}
PlotController.__index = PlotController

function PlotController.new(owner, plotModel, services)
	local self = setmetatable({}, PlotController)

	self.Owner = owner
	self.Model = plotModel
	self.Services = services
	self.Origin = Vector3.new(0, 0, 0)

	self.RootFolder = Instance.new("Folder")
	self.RootFolder.Name = "Runtime"
	self.RootFolder.Parent = plotModel

	self:BuildBase()

	self.VFX = VFXController.new(self)
	self.Aim = AimController.new(self)
	self.Conveyor = IntakeConveyorController.new(self)
	self.Targeting = TargetingController.new(self)

	self.Slots = {
		[1] = SlotController.new(self, 1, CFrame.new(-10, 0.6, -8), true),
		[2] = SlotController.new(self, 2, CFrame.new(-2, 0.6, -8), false),
	}

	self:BuildCrateButton()
	self:Refresh()

	return self
end

function PlotController:BuildBase()
	local base = Instance.new("Part")
	base.Name = "PlotBase"
	base.Size = Vector3.new(62, 0.4, 32)
	base.Anchored = true
	base.CanCollide = true
	base.Material = Enum.Material.SmoothPlastic
	base.Color = Color3.fromRGB(42, 45, 52)
	base.CFrame = CFrame.new(0, -0.2, 0)
	base.Parent = self.Model

	local border = Instance.new("Part")
	border.Name = "BackBorder"
	border.Size = Vector3.new(62, 2, 0.5)
	border.Anchored = true
	border.CanCollide = true
	border.Material = Enum.Material.Metal
	border.Color = Color3.fromRGB(28, 30, 36)
	border.CFrame = CFrame.new(0, 1, 16)
	border.Parent = self.Model
end

function PlotController:BuildCrateButton()
	local button = Instance.new("Part")
	button.Name = "FreeGunCrateButton"
	button.Size = Vector3.new(6, 1.2, 6)
	button.Anchored = true
	button.CanCollide = true
	button.Material = Enum.Material.Neon
	button.Color = Color3.fromRGB(40, 190, 80)
	button.CFrame = CFrame.new(-22, 0.6, -8)
	button.Parent = self.Model

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ClaimFreeGunCratePrompt"
	prompt.ActionText = "Claim FREE GUN CRATE"
	prompt.ObjectText = "Starter Pistol"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = button

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Label"
	billboard.Size = UDim2.fromOffset(260, 80)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = button

	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Text = "FREE\nGUN CRATE"
	text.TextScaled = true
	text.Font = Enum.Font.GothamBlack
	text.TextColor3 = Color3.fromRGB(255, 255, 255)
	text.TextStrokeTransparency = 0
	text.Parent = billboard

	prompt.Triggered:Connect(function(player)
		if player ~= self.Owner then
			return
		end

		self.Services.CrateService:ClaimFreeCrate(player)
	end)

	self.CrateButton = button
	self.CratePrompt = prompt
end

function PlotController:Refresh()
	for _, slot in pairs(self.Slots) do
		slot:UpdateVisual()
	end

	self.Services.RewardService:PushUpdate(self.Owner)
end

function PlotController:OnGunPlaced(slotController, gunId)
	print(string.format("[PlotController] %s placed in Slot %d", gunId, slotController.SlotId))

	self.Conveyor:Start()
	self.Services.RewardService:PushUpdate(self.Owner)
	self:Refresh()
end

function PlotController:OnCaseBroken(player, caseData)
	local broken = self.Services.RewardService:AwardCaseBreak(player, caseData.Reward)

	if broken >= ProgressionConfig.Slot2BreakRequirement then
		local playerData = self.Services.PlayerDataService
		if not playerData:HasUnlockedSlot(player, 2) then
			playerData:UnlockSlot(player, 2)
			self.Slots[2]:Unlock()
			self.Services.RewardService:PushUpdate(player, "Slot 2 Unlocked")
			return
		end
	end

	self.Services.RewardService:PushUpdate(player)
end

function PlotController:OnCaseEscaped(player, caseData)
	self.Services.RewardService:AwardEscape(player)
	self.Services.RewardService:PushUpdate(player)
end

function PlotController:Update(dt)
	self.Conveyor:Update(dt)

	for _, slot in pairs(self.Slots) do
		slot:Update(dt)
	end
end

function PlotController:Destroy()
	if self.Model then
		self.Model:Destroy()
	end
end

return PlotController
