-- GunService.lua
-- Each placed gun fires at the nearest case in range on its own cooldown.
-- Reads slot state from SlotService, finds cases via CaseService.

local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local SlotService    -- injected
local CaseService    -- injected

local GunConfig = require(ReplicatedStorage.Shared.Config.GunConfig)

local GunService = {}

-- Per-placed-gun fire timer: { [userId_slotNumber] = timeUntilNextShot }
local _cooldowns = {}

-- World positions for each slot index.
-- If your map has Parts named "Slot1", "Slot2" etc. under workspace.Farm,
-- Main can call GunService.SetSlotPositions() after the world loads.
-- Fallback: positions alongside the default lane.
local _slotPositions = {
	[1] = Vector3.new(-20, 1, -6),   -- slightly to the side of lane start
	[2] = Vector3.new(-10, 1, -6),
}

function GunService.Init(slotService, caseService)
	SlotService = slotService
	CaseService = caseService

	RunService.Heartbeat:Connect(function(dt)
		GunService._tick(dt)
	end)
end

function GunService.SetSlotPositions(posTable)
	_slotPositions = posTable
end

function GunService._tick(dt)
	for _, player in ipairs(Players:GetPlayers()) do
		local slots = SlotService.GetSlots(player)
		if not slots then continue end

		for slotNum, slot in pairs(slots) do
			if slot.GunId and not slot.Locked then
				local key = player.UserId .. "_" .. slotNum
				_cooldowns[key] = (_cooldowns[key] or 0) - dt

				if _cooldowns[key] <= 0 then
					GunService._tryShoot(player, slotNum, slot.GunId, key)
				end
			end
		end
	end
end

function GunService._tryShoot(player, slotNum, gunId, cooldownKey)
	local cfg        = GunConfig[gunId]
	if not cfg then return end

	local gunPos     = _slotPositions[slotNum]
	if not gunPos then return end

	local target = CaseService.GetNearestCaseInRange(player.UserId, gunPos, cfg.Range)
	if not target then
		-- No target; keep polling every 0.25 s to avoid tight spin
		_cooldowns[cooldownKey] = 0.25
		return
	end

	-- Reset cooldown for fire rate
	_cooldowns[cooldownKey] = 1 / cfg.FireRate

	-- Apply damage (server-side, no projectile travel time this slice)
	CaseService.Damage(target.Id, cfg.Damage, player)

	-- Visual: create a thin bullet Part that fades quickly
	GunService._shootVFX(gunPos, target.Part and target.Part.Position or gunPos, cfg.BulletColor)
end

function GunService._shootVFX(from, to, color)
	-- A thin beam Part for visual feedback only; no gameplay effect
	local mid    = (from + to) * 0.5
	local length = (to - from).Magnitude
	if length < 0.1 then return end

	local bullet = Instance.new("Part")
	bullet.Anchored   = true
	bullet.CanCollide = false
	bullet.Size       = Vector3.new(0.1, 0.1, length)
	bullet.Color      = color
	bullet.Material   = Enum.Material.Neon
	bullet.CFrame     = CFrame.lookAt(mid, to) * CFrame.new(0, 0, -length / 2)
	bullet.Parent     = workspace

	task.delay(0.08, function()
		if bullet and bullet.Parent then bullet:Destroy() end
	end)
end

return GunService
