local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local VFXController = {}
VFXController.__index = VFXController

function VFXController.new(plotController)
	local self = setmetatable({}, VFXController)
	self.Plot = plotController

	self.Folder = Instance.new("Folder")
	self.Folder.Name = "Effects"
	self.Folder.Parent = plotController.Model

	return self
end

function VFXController:MakeBall(name, position, color, size)
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(size, size, size)
	part.Anchored = true
	part.CanCollide = false
	part.Material = Enum.Material.Neon
	part.Color = color
	part.CFrame = CFrame.new(position)
	part.Parent = self.Folder
	return part
end

function VFXController:PlayMuzzleFlash(muzzle)
	local flash = self:MakeBall("MuzzleFlash", muzzle.Position, Color3.fromRGB(255, 230, 80), 0.8)

	local tween = TweenService:Create(
		flash,
		TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Size = Vector3.new(2.4, 2.4, 2.4),
			Transparency = 1,
		}
	)

	tween:Play()
	Debris:AddItem(flash, 0.12)
end

function VFXController:PlayTracer(startPosition, endPosition)
	local direction = endPosition - startPosition
	local distance = direction.Magnitude

	if distance <= 0 then
		return
	end

	local tracer = Instance.new("Part")
	tracer.Name = "ShotTracer"
	tracer.Anchored = true
	tracer.CanCollide = false
	tracer.Material = Enum.Material.Neon
	tracer.Color = Color3.fromRGB(255, 235, 80)
	tracer.Size = Vector3.new(0.18, 0.18, distance)
	tracer.CFrame = CFrame.lookAt(startPosition + direction / 2, endPosition)
	tracer.Parent = self.Folder

	Debris:AddItem(tracer, 0.08)
end

function VFXController:PlayHitFlash(position)
	local hit = self:MakeBall("HitFlash", position, Color3.fromRGB(255, 150, 55), 1.0)

	local tween = TweenService:Create(
		hit,
		TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Size = Vector3.new(3.0, 3.0, 3.0),
			Transparency = 1,
		}
	)

	tween:Play()
	Debris:AddItem(hit, 0.16)
end

function VFXController:PlayBreakBurst(position)
	local shock = self:MakeBall("CaseBreakBurst", position, Color3.fromRGB(255, 135, 45), 2.0)

	local tween = TweenService:Create(
		shock,
		TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Size = Vector3.new(8, 8, 8),
			Transparency = 1,
		}
	)

	tween:Play()
	Debris:AddItem(shock, 0.3)

	for i = 1, 14 do
		local shard = Instance.new("Part")
		shard.Name = "CaseShard"
		shard.Size = Vector3.new(
			math.random(4, 9) / 10,
			math.random(4, 9) / 10,
			math.random(4, 9) / 10
		)
		shard.Anchored = false
		shard.CanCollide = false
		shard.Material = Enum.Material.Wood
		shard.Color = Color3.fromRGB(140, 86, 42)
		shard.CFrame = CFrame.new(position)
		shard.Parent = self.Folder
		shard.AssemblyLinearVelocity = Vector3.new(
			math.random(-20, 20),
			math.random(12, 26),
			math.random(-20, 20)
		)
		Debris:AddItem(shard, 1.1)
	end
end

function VFXController:PlayCashBurst(position, amount)
	for i = 1, 10 do
		local bill = Instance.new("Part")
		bill.Name = "CashBill"
		bill.Size = Vector3.new(0.9, 0.08, 0.5)
		bill.Anchored = false
		bill.CanCollide = false
		bill.Material = Enum.Material.Neon
		bill.Color = Color3.fromRGB(70, 255, 110)
		bill.CFrame = CFrame.new(position + Vector3.new(0, 1, 0))
		bill.Parent = self.Folder
		bill.AssemblyLinearVelocity = Vector3.new(
			math.random(-14, 14),
			math.random(12, 24),
			math.random(-14, 14)
		)
		Debris:AddItem(bill, 1.0)
	end

	self:FloatingText("+$" .. tostring(amount), position + Vector3.new(0, 3, 0), Color3.fromRGB(80, 255, 110))
end

function VFXController:PlayEscape(position)
	local puff = self:MakeBall("EscapePuff", position, Color3.fromRGB(255, 70, 60), 1.6)

	local tween = TweenService:Create(
		puff,
		TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Size = Vector3.new(5, 5, 5),
			Transparency = 1,
		}
	)

	tween:Play()
	Debris:AddItem(puff, 0.25)

	self:FloatingText("ESCAPED", position + Vector3.new(0, 3, 0), Color3.fromRGB(255, 70, 60))
end

function VFXController:FloatingText(text, position, color)
	local holder = Instance.new("Part")
	holder.Name = "FloatingTextHolder"
	holder.Anchored = true
	holder.CanCollide = false
	holder.Transparency = 1
	holder.Size = Vector3.new(0.1, 0.1, 0.1)
	holder.CFrame = CFrame.new(position)
	holder.Parent = self.Folder

	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(180, 55)
	gui.AlwaysOnTop = true
	gui.Parent = holder

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.TextColor3 = color
	label.TextStrokeTransparency = 0
	label.Parent = gui

	local move = TweenService:Create(
		holder,
		TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			CFrame = holder.CFrame + Vector3.new(0, 2.5, 0),
		}
	)

	local fade = TweenService:Create(
		label,
		TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			TextTransparency = 1,
			TextStrokeTransparency = 1,
		}
	)

	move:Play()
	fade:Play()
	Debris:AddItem(holder, 0.9)
end

return VFXController
