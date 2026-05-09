-- PlayerDataService.lua
-- Owns all mutable per-player state for this session.
-- No saving this slice — everything lives here until the player leaves.

local Players = game:GetService("Players")

local PlayerDataService = {}

-- { [userId] = { Cash, OwnedGuns, BrokenCases } }
local _data = {}

local function newProfile()
	return {
		Cash        = 0,
		OwnedGuns   = {},   -- list of gunIds the player owns
		BrokenCases = 0,
	}
end

function PlayerDataService.Init()
	Players.PlayerAdded:Connect(function(player)
		_data[player.UserId] = newProfile()
	end)

	Players.PlayerRemoving:Connect(function(player)
		_data[player.UserId] = nil
	end)

	-- Seed anyone already in the server (Studio test)
	for _, player in ipairs(Players:GetPlayers()) do
		if not _data[player.UserId] then
			_data[player.UserId] = newProfile()
		end
	end
end

function PlayerDataService.Get(player)
	return _data[player.UserId]
end

function PlayerDataService.AddCash(player, amount)
	local d = _data[player.UserId]
	if not d then return end
	d.Cash += amount
	return d.Cash
end

function PlayerDataService.AddGun(player, gunId)
	local d = _data[player.UserId]
	if not d then return end
	table.insert(d.OwnedGuns, gunId)
end

function PlayerDataService.HasGun(player, gunId)
	local d = _data[player.UserId]
	if not d then return false end
	for _, id in ipairs(d.OwnedGuns) do
		if id == gunId then return true end
	end
	return false
end

function PlayerDataService.IncrementBrokenCases(player)
	local d = _data[player.UserId]
	if not d then return 0 end
	d.BrokenCases += 1
	return d.BrokenCases
end

return PlayerDataService
