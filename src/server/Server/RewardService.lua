-- RewardService.lua
-- Handles what happens after a case breaks or escapes.
-- Awards cash, increments broken-case counter, triggers slot unlocks,
-- and fires UI updates to the client.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local PlayerDataService  -- injected
local SlotService        -- injected

local ProgressionCfg = require(ReplicatedStorage.Shared.Config.ProgressionConfig)

local RewardService = {}

-- RemoteEvent: fires to the owning client with { Cash, BrokenCases, Event }
local UpdateRemote

function RewardService.Init(playerDataService, slotService)
	PlayerDataService = playerDataService
	SlotService       = slotService

	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotes then
		remotes = Instance.new("Folder")
		remotes.Name = "Remotes"
		remotes.Parent = ReplicatedStorage
	end

	UpdateRemote = remotes:FindFirstChild("PlayerUpdate")
	if not UpdateRemote then
		UpdateRemote = Instance.new("RemoteEvent")
		UpdateRemote.Name = "PlayerUpdate"
		UpdateRemote.Parent = remotes
	end
end

function RewardService.OnCaseBroken(player, caseTypeCfg)
	-- Cash
	local newCash = PlayerDataService.AddCash(player, caseTypeCfg.CashReward)

	-- Broken-case count
	local broken = PlayerDataService.IncrementBrokenCases(player)

	print(string.format("[RewardService] %s broke a case | cash=%d broken=%d",
		player.Name, newCash, broken))

	-- Check for Slot 2 unlock
	if broken == ProgressionCfg.Slot2UnlockAt then
		SlotService.UnlockSlot(player, 2)
		RewardService._fireUpdate(player, newCash, broken, "Slot2Unlocked")
	else
		RewardService._fireUpdate(player, newCash, broken, "CaseBroken")
	end
end

function RewardService.OnCaseEscaped(player, _caseTypeCfg)
	-- No penalty this slice; just update display
	local d = PlayerDataService.Get(player)
	if not d then return end
	RewardService._fireUpdate(player, d.Cash, d.BrokenCases, "CaseEscaped")
end

function RewardService._fireUpdate(player, cash, brokenCases, event)
	if UpdateRemote then
		UpdateRemote:FireClient(player, {
			Cash        = cash,
			BrokenCases = brokenCases,
			Target      = ProgressionCfg.Slot2UnlockAt,
			Event       = event,
		})
	end
end

return RewardService
