local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GunConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("GunConfig"))

local SlotController = {}
SlotController.__index = SlotController

function SlotController.new(plotController, slotId, cframe, unlocked)
	local self = setmetatable({}, SlotController)

	self.Plot = plotController
	self.Owner = plotController.Owner
	self.SlotId = slotId
	self.CFrame = cframe
	self.Unlocked = unlocked == true
	self.Occupied = false
	self.GunId = nil
	self.GunModel = nil
	self.Muzzle = nil
	self.FireTimer = 0
	self.FireInterval = 1
	self.Damage = 0
	self.Range = 80

	self.Model = Instance.new("Model")
	self.Model.Name = "Slot" .. slotId
	self.Model.Parent = plotController.Model

	self:BuildStand()
	self:UpdateVisual()

	return self
end

function SlotController:BuildStand()
	local base = Instance.new("Part")
	base.Name = "Base"
	base.Size = Vector3.new(5, 0.5, 5)
	base.Anchored = true
	base.CanCollide = true
	base.Material = Enum.Material.SmoothPlastic
	base.CFrame = self.CFrame
	base.Parent = self.Model
	self.Base = base

	local labelGui = Instance.new("BillboardGui")
	labelGui.Name = "Label"
	labelGui.Size = UDim2.fromOffset(150, 80)
	labelGui.StudsOffset = Vector3.new(0, 3.0, 0)
	labelGui.AlwaysOnTop = true
	labelGui.Parent = base

	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0
	label.Text = "SLOT " .. self.SlotId
	label.Parent = labelGui
	self.Label = label

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "SlotPrompt"
	prompt.ActionText = "Place Starter Pistol"
	prompt.ObjectText = "Slot " .. self.SlotId
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = base
	self.Prompt = prompt

	prompt.Triggered:Connect(function(player)
		if player ~= self.Owner then
			return
		end

		self:TryPlaceGun(player, "StarterPistol")
	end)
end

function SlotController:UpdateVisual()
	local dataService = self.Plot.Services.PlayerDataService
	local ownsStarter = dataService:OwnsGun(self.Owner, "StarterPistol")
	local starterPlaced = dataService:IsGunPlaced(self.Owner, "StarterPistol")

	if not self.Unlocked then
		self.Base.Color = Color3.fromRGB(145, 35, 35)
		self.Label.Text = "🔒 SLOT\n" .. self.SlotId
		self.Prompt.Enabled = false
		return
	end

	if self.Occupied then
		self.Base.Color = Color3.fromRGB(35, 130, 45)
		self.Label.Text = "SLOT " .. self.SlotId .. "\n✅"
		self.Prompt.Enabled = false
		return
	end

	self.Base.Color = Color3.fromRGB(45, 145, 55)

	if not ownsStarter then
		self.Label.Text = "SLOT " .. self.SlotId .. "\nClaim crate"
		self.Prompt.ActionText = "Claim crate first"
		self.Prompt.Enabled = true
		return
	end

	if starterPlaced then
		self.Label.Text = "SLOT " .. self.SlotId .. "\nNeed gun"
		self.Prompt.ActionText = "Need another gun"
		self.Prompt.Enabled = true
		return
	end

	self.Label.Text = "SLOT " .. self.SlotId .. "\nPlace"
	self.Prompt.ActionText = "Place Starter Pistol"
	self.Prompt.Enabled = true
end

function SlotController:Unlock()
	self.Unlocked = true
	self:UpdateVisual()
	print("[SlotController] Slot", self.SlotId, "unlocked")
end

function SlotController:TryPlaceGun(player, gunId)
	if not self.Unlocked then
		return false
	end

	if self.Occupied then
		return false
	end

	local dataService = self.Plot.Services.PlayerDataService

	if not dataService:OwnsGun(player, gunId) then
		self.Plot.VFX:FloatingText("Claim crate first", self.Base.Position + Vector3.new(0, 2.5, 0), Color3.fromRGB(255, 230, 80))
		return false
	end

	if dataService:IsGunPlaced(player, gunId) then
		self.Plot.VFX:FloatingText("Need another gun", self.Base.Position + Vector3.new(0, 2.5, 0), Color3.fromRGB(255, 230, 80))
		return false
	end

	self.Occupied = true
	self.GunId = gunId

	local config = GunConfig[gunId]
	self.FireInterval = config.FireInterval
	self.Damage = config.Damage
	self.Range = config.Range

	dataService:MarkGunPlaced(player, gunId, self.SlotId)

	self:SpawnGunModel(gunId)

	print(string.format("[SlotController] Placed %s in Slot %d", gunId, self.SlotId))

	self.Plot:OnGunPlaced(self, gunId)
	self:UpdateVisual()

	return true
end

function SlotController:SpawnGunModel(gunId)
	if self.GunModel then
		self.GunModel:Destroy()
	end

	local config = GunConfig[gunId]

	local gun = Instance.new("Model")
	gun.Name = gunId .. "_Turret"
	gun.Parent = self.Model

	local pivotPosition = self.Base.Position + Vector3.new(0, 1.0, 0)
	gun:SetAttribute("PivotPosition", pivotPosition)

	local stand = Instance.new("Part")
	stand.Name = "Stand"
	stand.Size = Vector3.new(1.4, 1.2, 1.4)
	stand.Anchored = true
	stand.CanCollide = false
	stand.Material = Enum.Material.Metal
	stand.Color = Color3.fromRGB(35, 38, 45)
	stand.CFrame = CFrame.new(pivotPosition + Vector3.new(0, -0.3, 0))
	stand.Parent = gun

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(2.4, 1.4, 1.8)
	body.Anchored = true
	body.CanCollide = false
	body.Material = Enum.Material.Metal
	body.Color = config.Color
	body.CFrame = CFrame.new(pivotPosition + Vector3.new(0, 0.8, 0))
	body.Parent = gun
	gun.PrimaryPart = body

	local barrel = Instance.new("Part")
	barrel.Name = "Barrel"
	barrel.Size = Vector3.new(0.65, 0.65, 3.0)
	barrel.Anchored = true
	barrel.CanCollide = false
	barrel.Material = Enum.Material.Metal
	barrel.Color = Color3.fromRGB(20, 23, 30)
	barrel.CFrame = CFrame.new(pivotPosition + Vector3.new(0, 0.8, -2.0))
	barrel.Parent = gun

	local muzzle = Instance.new("Part")
	muzzle.Name = "Muzzle"
	muzzle.Shape = Enum.PartType.Ball
	muzzle.Size = Vector3.new(0.75, 0.75, 0.75)
	muzzle.Anchored = true
	muzzle.CanCollide = false
	muzzle.Material = Enum.Material.Neon
	muzzle.Color = Color3.fromRGB(255, 220, 60)
	muzzle.CFrame = CFrame.new(pivotPosition + Vector3.new(0, 0.8, -3.65))
	muzzle.Parent = gun

	self.GunModel = gun
	self.Muzzle = muzzle

	self:FaceConveyor()
end

function SlotController:FaceConveyor()
	if not self.GunModel then
		return
	end

	local pivot = self.GunModel:GetAttribute("PivotPosition")
	local target = Vector3.new(3, pivot.Y, 3)
	self.GunModel:PivotTo(CFrame.lookAt(pivot, target))
end

function SlotController:GetMuzzlePosition()
	if self.Muzzle and self.Muzzle.Parent then
		return self.Muzzle.Position
	end

	return nil
end

function SlotController:Update(dt)
	if not self.Occupied or not self.GunModel or not self.Muzzle then
		return
	end

	self.FireTimer += dt

	local target = self.Plot.Targeting:GetTargetForSlot(self)

	if target and target.Core then
		self.Plot.Aim:AimAt(self.GunModel, target.Core.Position)
	end

	if target and self.FireTimer >= self.FireInterval then
		self.FireTimer = 0
		self:Fire(target)
	end
end

function SlotController:Fire(caseData)
	if not caseData or not caseData.Alive or not caseData.Core then
		return
	end

	local startPosition = self.Muzzle.Position
	local endPosition = caseData.Core.Position + Vector3.new(0, 0.3, 0)

	print("[SlotController] FireAt", caseData.Id)

	self.Plot.VFX:PlayMuzzleFlash(self.Muzzle)
	self.Plot.VFX:PlayTracer(startPosition, endPosition)
	self.Plot.VFX:PlayHitFlash(endPosition)

	self.Plot.Conveyor:DamageCase(caseData, self.Damage, self.Owner)
end

return SlotController
