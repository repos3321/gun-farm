-- CaseService.lua
-- Spawns cases on the conveyor, moves them each tick, resolves break/escape.
-- Calls RewardService.OnCaseBroken(player, caseData) and
--        RewardService.OnCaseEscaped(player, caseData).

local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ConveyorService   -- injected
local RewardService     -- injected

local CaseConfig       = require(ReplicatedStorage.Shared.Config.CaseConfig)
local ProgressionCfg   = require(ReplicatedStorage.Shared.Config.ProgressionConfig)

local CaseService = {}

-- Live cases: { [caseId] = CaseRecord }
-- CaseRecord: { Id, PlayerId, TypeId, HP, MaxHP, Distance, Speed, Part }
local _cases    = {}
local _nextId   = 0
local _spawnTimers = {}   -- { [userId] = timeUntilNextSpawn }

local function nextId()
	_nextId += 1
	return _nextId
end

local function countCasesForPlayer(userId)
	local n = 0
	for _, c in pairs(_cases) do
		if c.PlayerId == userId then n += 1 end
	end
	return n
end

-- Create a visible Part for the case in Workspace
local function makeCasePart(caseTypeCfg, startPos)
	local part = Instance.new("Part")
	part.Name       = "Case_" .. caseTypeCfg.Id
	part.Size       = caseTypeCfg.Size
	part.Color      = caseTypeCfg.Color
	part.Anchored   = true
	part.CanCollide = false
	part.Position   = startPos

	-- Simple HP label
	local billboard = Instance.new("BillboardGui")
	billboard.Size            = UDim2.new(0, 80, 0, 30)
	billboard.StudsOffset     = Vector3.new(0, 2, 0)
	billboard.AlwaysOnTop     = false
	billboard.Parent          = part

	local label = Instance.new("TextLabel")
	label.Size            = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.TextColor3      = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.Font            = Enum.Font.GothamBold
	label.TextScaled      = true
	label.Text            = "HP: " .. caseTypeCfg.MaxHP
	label.Name            = "HPLabel"
	label.Parent          = billboard

	part.Parent = workspace
	return part
end

function CaseService.Init(conveyorService, rewardService)
	ConveyorService = conveyorService
	RewardService   = rewardService

	-- Move cases every heartbeat
	RunService.Heartbeat:Connect(function(dt)
		CaseService._tick(dt)
	end)
end

function CaseService.StartSpawningForPlayer(player)
	_spawnTimers[player.UserId] = 0   -- spawn immediately on first tick
end

function CaseService.StopSpawningForPlayer(player)
	_spawnTimers[player.UserId] = nil
end

function CaseService.CleanupForPlayer(player)
	_spawnTimers[player.UserId] = nil
	for id, c in pairs(_cases) do
		if c.PlayerId == player.UserId then
			if c.Part and c.Part.Parent then c.Part:Destroy() end
			_cases[id] = nil
		end
	end
end

-- Returns the first live case within range of a world position (for GunService targeting)
function CaseService.GetNearestCaseInRange(userId, gunWorldPos, range)
	local best, bestDist = nil, math.huge
	for _, c in pairs(_cases) do
		if c.PlayerId == userId and c.HP > 0 then
			local d = (c.Part.Position - gunWorldPos).Magnitude
			if d <= range and d < bestDist then
				best     = c
				bestDist = d
			end
		end
	end
	return best
end

-- Apply damage from a gun shot; returns remaining HP
function CaseService.Damage(caseId, amount, player)
	local c = _cases[caseId]
	if not c or c.HP <= 0 then return 0 end

	c.HP = math.max(0, c.HP - amount)

	-- Update label
	if c.Part and c.Part:FindFirstChild("BillboardGui") then
		local lbl = c.Part.BillboardGui:FindFirstChild("HPLabel")
		if lbl then lbl.Text = "HP: " .. c.HP end
	end

	if c.HP <= 0 then
		CaseService._break(caseId, player)
	end

	return c.HP
end

function CaseService._break(caseId, player)
	local c = _cases[caseId]
	if not c then return end

	print(string.format("[CaseService] Case %d BROKEN for %s", caseId, player.Name))

	-- Visual: flash white then destroy
	if c.Part and c.Part.Parent then
		c.Part.Color = Color3.new(1, 1, 1)
		task.delay(0.15, function()
			if c.Part and c.Part.Parent then c.Part:Destroy() end
		end)
	end

	local typeCfg = CaseConfig[c.TypeId]
	_cases[caseId] = nil

	RewardService.OnCaseBroken(player, typeCfg)
end

function CaseService._escape(caseId, player)
	local c = _cases[caseId]
	if not c then return end

	print(string.format("[CaseService] Case %d ESCAPED for %s", caseId, player.Name))

	if c.Part and c.Part.Parent then c.Part:Destroy() end

	local typeCfg = CaseConfig[c.TypeId]
	_cases[caseId] = nil

	RewardService.OnCaseEscaped(player, typeCfg)
end

function CaseService._tick(dt)
	local Players = game:GetService("Players")
	local laneLength = ConveyorService.LaneLength()

	-- Spawn timers
	for userId, timer in pairs(_spawnTimers) do
		local player = Players:GetPlayerByUserId(userId)
		if not player then
			_spawnTimers[userId] = nil
			continue
		end
		if not ConveyorService.IsRunning(player) then continue end

		_spawnTimers[userId] = timer - dt
		if _spawnTimers[userId] <= 0 then
			_spawnTimers[userId] = ProgressionCfg.CaseSpawnInterval

			if countCasesForPlayer(userId) < ProgressionCfg.MaxCasesOnBelt then
				CaseService._spawn(player)
			end
		end
	end

	-- Move all live cases
	for id, c in pairs(_cases) do
		c.Distance += c.Speed * dt

		if c.Distance >= laneLength then
			-- Escaped
			local player = Players:GetPlayerByUserId(c.PlayerId)
			if player then
				CaseService._escape(id, player)
			else
				if c.Part and c.Part.Parent then c.Part:Destroy() end
				_cases[id] = nil
			end
		else
			-- Reposition part
			if c.Part and c.Part.Parent then
				c.Part.Position = ConveyorService.PositionAtDistance(c.Distance)
			end
		end
	end
end

function CaseService._spawn(player)
	local typeCfg = CaseConfig.BasicCase
	local startPos = ConveyorService.PositionAtDistance(0)
	local part     = makeCasePart(typeCfg, startPos)

	local id = nextId()
	_cases[id] = {
		Id       = id,
		PlayerId = player.UserId,
		TypeId   = typeCfg.Id,
		HP       = typeCfg.MaxHP,
		MaxHP    = typeCfg.MaxHP,
		Distance = 0,
		Speed    = typeCfg.Speed,
		Part     = part,
	}
	print(string.format("[CaseService] Spawned case %d for %s", id, player.Name))
end

return CaseService
