-- SlotService.lua
-- Manages gun slot state: which gun is in each slot, locked/unlocked.
-- This slice has Slot 1 (always open) and Slot 2 (locked until 3 breaks).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local PlayerDataService  -- injected
local GunConfig

local SlotService = {}

-- Per-player slot state
-- { [userId] = { [slotNumber] = { GunId = string | nil, Locked = bool } } }
local _slots = {}

local SLOT_COUNT = 2

-- RemoteEvents
local PlaceGunRemote    -- client fires: (slotNumber, gunId)
local SlotStateRemote   -- server fires to client: full slot table

local function defaultSlots()
	return {
		[1] = { GunId = nil, Locked = false },
		[2] = { GunId = nil, Locked = true  },
	}
end

function SlotService.Init(playerDataService)
	PlayerDataService = playerDataService
	GunConfig = require(ReplicatedStorage.Shared.Config.GunConfig)

	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotes then
		remotes = Instance.new("Folder")
		remotes.Name = "Remotes"
		remotes.Parent = ReplicatedStorage
	end

	PlaceGunRemote = remotes:FindFirstChild("PlaceGun")
	if not PlaceGunRemote then
		PlaceGunRemote = Instance.new("RemoteEvent")
		PlaceGunRemote.Name = "PlaceGun"
		PlaceGunRemote.Parent = remotes
	end

	SlotStateRemote = remotes:FindFirstChild("SlotState")
	if not SlotStateRemote then
		SlotStateRemote = Instance.new("RemoteEvent")
		SlotStateRemote.Name = "SlotState"
		SlotStateRemote.Parent = remotes
	end

	PlaceGunRemote.OnServerEvent:Connect(function(player, slotNumber, gunId)
		SlotService.PlaceGun(player, slotNumber, gunId)
	end)

	Players.PlayerAdded:Connect(function(player)
		_slots[player.UserId] = defaultSlots()
	end)

	Players.PlayerRemoving:Connect(function(player)
		_slots[player.UserId] = nil
	end)

	-- Studio hot-join
	for _, p in ipairs(Players:GetPlayers()) do
		if not _slots[p.UserId] then
			_slots[p.UserId] = defaultSlots()
		end
	end
end

-- Called by server (GunService needs to read this) and by client request
function SlotService.GetSlots(player)
	return _slots[player.UserId]
end

-- Returns true if a gun was successfully placed
function SlotService.PlaceGun(player, slotNumber, gunId)
	local slots = _slots[player.UserId]
	if not slots then return false end

	local slot = slots[slotNumber]
	if not slot then
		warn("[SlotService] Invalid slot number:", slotNumber)
		return false
	end
	if slot.Locked then
		warn("[SlotService] Slot is locked:", slotNumber)
		return false
	end
	if slot.GunId ~= nil then
		warn("[SlotService] Slot already occupied:", slotNumber)
		return false
	end
	if not PlayerDataService.HasGun(player, gunId) then
		warn("[SlotService] Player doesn't own gun:", gunId)
		return false
	end
	if not GunConfig[gunId] then
		warn("[SlotService] Unknown gunId:", gunId)
		return false
	end

	slot.GunId = gunId
	print(string.format("[SlotService] %s placed %s in slot %d", player.Name, gunId, slotNumber))

	SlotService._pushState(player)
	return true
end

-- Called by RewardService after enough cases broken
function SlotService.UnlockSlot(player, slotNumber)
	local slots = _slots[player.UserId]
	if not slots or not slots[slotNumber] then return end
	slots[slotNumber].Locked = false
	print(string.format("[SlotService] Slot %d unlocked for %s", slotNumber, player.Name))
	SlotService._pushState(player)
end

-- Push current slot state to the owning client
function SlotService._pushState(player)
	local slots = _slots[player.UserId]
	if slots and SlotStateRemote then
		-- Serialise to a plain table (Instance refs not needed — client uses this for UI only)
		local payload = {}
		for i = 1, SLOT_COUNT do
			payload[i] = {
				SlotNumber = i,
				GunId      = slots[i] and slots[i].GunId or nil,
				Locked     = slots[i] and slots[i].Locked or false,
			}
		end
		SlotStateRemote:FireClient(player, payload)
	end
end

-- Convenience: does Slot 1 have a gun placed?
function SlotService.Slot1HasGun(player)
	local slots = _slots[player.UserId]
	return slots and slots[1] and slots[1].GunId ~= nil
end

return SlotService
