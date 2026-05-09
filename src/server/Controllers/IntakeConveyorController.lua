local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CaseConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("CaseConfig"))

local IntakeConveyorController = {}
IntakeConveyorController.__index = IntakeConveyorController

function IntakeConveyorController.new(plotController)
	local self = setmetatable({}, IntakeConveyorController)

	self.Plot = plotController
	self.Model = Instance.new("Folder")
	self.Model.Name = "IntakeConveyor"
	self.Model.Parent = plotController.Model

	self.CasesFolder = Instance.new("Folder")
	self.CasesFolder.Name = "Cases"
	self.CasesFolder.Parent = self.Model

	self.ActiveCases = {}
	self.NextCaseId = 0
	self.SpawnTimer = 999
	self.IsStarted = false

	self.SpawnPosition = Vector3.new(-18, 2.2, 3)
	self.ExitPosition = Vector3.new(24, 2.2, 3)

	self:BuildConveyor()

	return self
end

function IntakeConveyorController:BuildConveyor()
	local belt = Instance.new("Part")
	belt.Name = "Belt"
	belt.Size = Vector3.new(46, 0.45, 5.5)
	belt.Anchored = true
	belt.CanCollide = true
	belt.Material = Enum.Material.Metal
	belt.Color = Color3.fromRGB(28, 29, 32)
	belt.CFrame = CFrame.new(3, 0.35, 3)
	belt.Parent = self.Model

	for i = 1, 8 do
		local stripe = Instance.new("Part")
		stripe.Name = "DirectionStripe_" .. i
		stripe.Size = Vector3.new(2.0, 0.08, 2.8)
		stripe.Anchored = true
		stripe.CanCollide = false
		stripe.Material = Enum.Material.Neon
		stripe.Color = Color3.fromRGB(255, 230, 40)
		stripe.CFrame = CFrame.new(-15 + i * 5, 0.65, 3) * CFrame.Angles(0, 0, math.rad(45))
		stripe.Parent = self.Model
	end

	local intake = Instance.new("Part")
	intake.Name = "INTAKE"
	intake.Size = Vector3.new(1, 5, 7)
	intake.Anchored = true
	intake.CanCollide = true
	intake.Material = Enum.Material.Neon
	intake.Color = Color3.fromRGB(60, 255, 100)
	intake.CFrame = CFrame.new(self.SpawnPosition.X - 2, 2.5, self.SpawnPosition.Z)
	intake.Parent = self.Model
	self:MakeBillboard(intake, "▶ INTAKE", Color3.fromRGB(60, 255, 100), Vector3.new(0, 3.2, 0))

	local exit = Instance.new("Part")
	exit.Name = "EXIT"
	exit.Size = Vector3.new(1, 5, 7)
	exit.Anchored = true
	exit.CanCollide = true
	exit.Material = Enum.Material.Neon
	exit.Color = Color3.fromRGB(255, 65, 55)
	exit.CFrame = CFrame.new(self.ExitPosition.X + 2, 2.5, self.ExitPosition.Z)
	exit.Parent = self.Model
	self:MakeBillboard(exit, "EXIT ▶", Color3.fromRGB(255, 65, 55), Vector3.new(0, 3.2, 0))
end

function IntakeConveyorController:MakeBillboard(part, text, color, offset)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Billboard"
	gui.Size = UDim2.fromOffset(220, 60)
	gui.StudsOffset = offset
	gui.AlwaysOnTop = true
	gui.Parent = part

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.TextColor3 = color
	label.TextStrokeTransparency = 0
	label.Parent = gui

	return gui
end

function IntakeConveyorController:Start()
	if self.IsStarted then
		return
	end

	self.IsStarted = true
	self.SpawnTimer = 999
	print("[Conveyor] Started")
end

function IntakeConveyorController:GetPositionAtProgress(progress)
	return self.SpawnPosition:Lerp(self.ExitPosition, math.clamp(progress, 0, 1))
end

function IntakeConveyorController:SpawnCase()
	self.NextCaseId += 1

	local config = CaseConfig.CardboardCase
	local caseId = "Case_" .. self.NextCaseId

	local model = Instance.new("Model")
	model.Name = caseId
	model.Parent = self.CasesFolder

	local core = Instance.new("Part")
	core.Name = "Core"
	core.Size = config.Size
	core.Anchored = true
	core.CanCollide = true
	core.Material = Enum.Material.Wood
	core.Color = Color3.fromRGB(155, 95, 42)
	core.CFrame = CFrame.new(self.SpawnPosition)
	core.Parent = model
	model.PrimaryPart = core

	local band = Instance.new("Part")
	band.Name = "MetalBand"
	band.Size = Vector3.new(config.Size.X + 0.12, 0.35, config.Size.Z + 0.12)
	band.Anchored = true
	band.CanCollide = false
	band.Material = Enum.Material.Metal
	band.Color = Color3.fromRGB(75, 75, 82)
	band.CFrame = core.CFrame
	band.Parent = model

	local hpGui = Instance.new("BillboardGui")
	hpGui.Name = "HPGui"
	hpGui.Size = UDim2.fromOffset(180, 55)
	hpGui.StudsOffset = Vector3.new(0, 3.0, 0)
	hpGui.AlwaysOnTop = true
	hpGui.Parent = core

	local hpText = Instance.new("TextLabel")
	hpText.Name = "HPText"
	hpText.Size = UDim2.fromScale(1, 1)
	hpText.BackgroundTransparency = 1
	hpText.Text = "HP: " .. config.HP .. " / " .. config.HP
	hpText.TextScaled = true
	hpText.Font = Enum.Font.GothamBlack
	hpText.TextColor3 = Color3.fromRGB(255, 255, 255)
	hpText.TextStrokeTransparency = 0
	hpText.Parent = hpGui

	model:SetAttribute("CaseId", caseId)
	model:SetAttribute("HP", config.HP)
	model:SetAttribute("MaxHP", config.HP)
	model:SetAttribute("Alive", true)
	model:SetAttribute("Progress", 0)

	local caseData = {
		Id = caseId,
		Model = model,
		Core = core,
		HPText = hpText,
		HP = config.HP,
		MaxHP = config.HP,
		Progress = 0,
		Reward = config.Reward,
		Alive = true,
	}

	table.insert(self.ActiveCases, caseData)

	print("[Conveyor] Spawned", caseId)
end

function IntakeConveyorController:GetAliveCases()
	local alive = {}

	for _, caseData in ipairs(self.ActiveCases) do
		if caseData.Alive and caseData.Model and caseData.Model.Parent then
			table.insert(alive, caseData)
		end
	end

	return alive
end

function IntakeConveyorController:UpdateCaseDisplay(caseData)
	if not caseData.HPText then
		return
	end

	local hp = math.max(0, math.floor(caseData.HP))
	caseData.HPText.Text = string.format("HP: %d / %d", hp, caseData.MaxHP)
	caseData.Model:SetAttribute("HP", hp)
end

function IntakeConveyorController:ShakeCase(caseData)
	if not caseData.Model or not caseData.Model.Parent then
		return
	end

	local original = caseData.Model:GetPivot()
	local offset = Vector3.new(
		math.random(-8, 8) / 80,
		math.random(0, 8) / 80,
		math.random(-8, 8) / 80
	)

	caseData.Model:PivotTo(original + offset)

	task.delay(0.05, function()
		if caseData.Model and caseData.Model.Parent and caseData.Alive then
			caseData.Model:PivotTo(original)
		end
	end)
end

function IntakeConveyorController:DamageCase(caseData, damage, sourcePlayer)
	if not caseData or not caseData.Alive then
		return false
	end

	caseData.HP -= damage
	caseData.Model:SetAttribute("HP", caseData.HP)

	self:ShakeCase(caseData)
	self:UpdateCaseDisplay(caseData)

	print(string.format("[Conveyor] Damage %s hp=%d", caseData.Id, math.max(0, caseData.HP)))

	if caseData.HP <= 0 then
		self:BreakCase(caseData, sourcePlayer)
		return true
	end

	return false
end

function IntakeConveyorController:BreakCase(caseData, sourcePlayer)
	if not caseData or not caseData.Alive then
		return
	end

	caseData.Alive = false
	caseData.Model:SetAttribute("Alive", false)

	local position = caseData.Core.Position
	self.Plot.VFX:PlayBreakBurst(position)
	self.Plot.VFX:PlayCashBurst(position, caseData.Reward)

	if caseData.Model then
		caseData.Model:Destroy()
	end

	self.Plot:OnCaseBroken(sourcePlayer or self.Plot.Owner, caseData)
end

function IntakeConveyorController:EscapeCase(caseData)
	if not caseData or not caseData.Alive then
		return
	end

	caseData.Alive = false
	caseData.Model:SetAttribute("Alive", false)

	local position = caseData.Core.Position
	self.Plot.VFX:PlayEscape(position)

	if caseData.Model then
		caseData.Model:Destroy()
	end

	self.Plot:OnCaseEscaped(self.Plot.Owner, caseData)
end

function IntakeConveyorController:Update(dt)
	if not self.IsStarted then
		return
	end

	self.SpawnTimer += dt

	if self.SpawnTimer >= CaseConfig.SpawnInterval and #self:GetAliveCases() < CaseConfig.MaxActiveCases then
		self.SpawnTimer = 0
		self:SpawnCase()
	end

	for _, caseData in ipairs(self.ActiveCases) do
		if caseData.Alive and caseData.Model and caseData.Model.Parent then
			caseData.Progress += dt / CaseConfig.TravelTime
			caseData.Model:SetAttribute("Progress", caseData.Progress)

			if caseData.Progress >= 1 then
				self:EscapeCase(caseData)
			else
				local position = self:GetPositionAtProgress(caseData.Progress)
				caseData.Model:PivotTo(CFrame.new(position))
			end
		end
	end

	for index = #self.ActiveCases, 1, -1 do
		local caseData = self.ActiveCases[index]
		if not caseData.Alive or not caseData.Model or not caseData.Model.Parent then
			table.remove(self.ActiveCases, index)
		end
	end
end

return IntakeConveyorController
