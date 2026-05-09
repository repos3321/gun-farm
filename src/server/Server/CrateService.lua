-- CrateService.lua
-- Handles the FREE GUN CRATE claim.
-- This slice: one free crate per session, always gives Starter Pistol.

local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local Players            = game:GetService("Players")

local PlayerDataService  -- injected by Main
local GunConfig          = require(ReplicatedStorage.Shared.Config.GunConfig)

-- RemoteEvent wired up in Main so the client button can fire it
local CrateRemote        -- set in Init

local _claimed = {}  -- { [userId] = true } — one free crate per session

local CrateService = {}

function CrateService.Init(playerDataService)
	PlayerDataService = playerDataService

	-- Create the RemoteEvent if it doesn't already exist
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotes then
		remotes = Instance.new("Folder")
		remotes.Name = "Remotes"
		remotes.Parent = ReplicatedStorage
	end

	CrateRemote = remotes:FindFirstChild("ClaimFreeCrate")
	if not CrateRemote then
		CrateRemote = Instance.new("RemoteEvent")
		CrateRemote.Name = "ClaimFreeCrate"
		CrateRemote.Parent = remotes
	end

	CrateRemote.OnServerEvent:Connect(function(player)
		CrateService.ClaimFree(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		_claimed[player.UserId] = nil
	end)
end

-- Returns gunId string on success, nil if already claimed
function CrateService.ClaimFree(player)
	if _claimed[player.UserId] then
		warn("[CrateService] Player already claimed free crate:", player.Name)
		return nil
	end

	_claimed[player.UserId] = true

	local gunId = "StarterPistol"   -- guaranteed this slice
	PlayerDataService.AddGun(player, gunId)

	print(string.format("[CrateService] %s claimed free crate → %s", player.Name, gunId))

	-- Tell the client what they got so the UI can react
	local remotes = ReplicatedStorage.Remotes
	local notify = remotes:FindFirstChild("CrateResult")
	if not notify then
		notify = Instance.new("RemoteEvent")
		notify.Name = "CrateResult"
		notify.Parent = remotes
	end
	notify:FireClient(player, gunId, GunConfig[gunId].DisplayName)

	return gunId
end

function CrateService.HasClaimed(player)
	return _claimed[player.UserId] == true
end

return CrateService
