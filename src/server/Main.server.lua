-- Main.server.lua
-- Bootstrap: require and init all services in dependency order.
-- Nothing gameplay-specific lives here — only wiring.

local ServerScriptService = game:GetService("ServerScriptService")
local Players             = game:GetService("Players")

local Server = ServerScriptService:WaitForChild("Server")

-- Load modules
local PlayerDataService = require(Server:WaitForChild("PlayerDataService"))
local ConveyorService   = require(Server:WaitForChild("ConveyorService"))
local CrateService      = require(Server:WaitForChild("CrateService"))
local SlotService       = require(Server:WaitForChild("SlotService"))
local RewardService     = require(Server:WaitForChild("RewardService"))
local CaseService       = require(Server:WaitForChild("CaseService"))
local GunService        = require(Server:WaitForChild("GunService"))

-- ── Init order matters ──────────────────────────────────────────────────────

PlayerDataService.Init()
ConveyorService.Init()

-- Services that need dependencies injected
CrateService.Init(PlayerDataService)
SlotService.Init(PlayerDataService)
RewardService.Init(PlayerDataService, SlotService)
CaseService.Init(ConveyorService, RewardService)
GunService.Init(SlotService, CaseService)

-- ── Optional: read slot positions from Workspace ────────────────────────────
-- If you have a Folder named "Farm" under Workspace containing Parts named
-- "Slot1", "Slot2", GunService will use their world positions.
-- Otherwise the defaults in GunService are used.
task.defer(function()
	local farm = workspace:FindFirstChild("Farm")
	if farm then
		local posTable = {}
		for i = 1, 10 do
			local part = farm:FindFirstChild("Slot" .. i)
			if part then
				posTable[i] = part.Position
			end
		end
		if next(posTable) then
			GunService.SetSlotPositions(posTable)
		end

		-- Also build the conveyor lane from a path folder if present
		-- Expects Workspace.Farm.ConveyorPath with children named "P1", "P2", ... in order
		local path = farm:FindFirstChild("ConveyorPath")
		if path then
			local waypoints = {}
			local i = 1
			while true do
				local pt = path:FindFirstChild("P" .. i)
				if not pt then break end
				table.insert(waypoints, pt.Position)
				i += 1
			end
			if #waypoints >= 2 then
				ConveyorService.SetLane(waypoints)
			end
		end
	end
end)

-- ── Per-player lifecycle ─────────────────────────────────────────────────────
-- When a gun is placed in Slot 1, start the conveyor + case spawning.
-- We watch the SlotState remote echo for simplicity; alternatively
-- SlotService could fire a callback.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function onSlotGunPlaced(player)
	if not ConveyorService.IsRunning(player) then
		ConveyorService.StartForPlayer(player)
		CaseService.StartSpawningForPlayer(player)
	end
end

-- Poll slot state every 0.5 s — lightweight, avoids adding callback hooks to SlotService.
-- Fires once and then never again per player once the conveyor is running.
local _started = {}

local RunService = game:GetService("RunService")
RunService.Heartbeat:Connect(function()
	for _, player in ipairs(Players:GetPlayers()) do
		if not _started[player.UserId] then
			local slots = SlotService.GetSlots(player)
			if slots and slots[1] and slots[1].GunId ~= nil then
				_started[player.UserId] = true
				onSlotGunPlaced(player)
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	ConveyorService.StopForPlayer(player)
	ConveyorService.Cleanup(player)
	CaseService.StopSpawningForPlayer(player)
	CaseService.CleanupForPlayer(player)
	_started[player.UserId] = nil
end)

print("[Main] My Gun Farm server initialised ✓")
