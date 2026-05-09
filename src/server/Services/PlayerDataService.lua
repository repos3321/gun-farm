local PlayerDataService = {}

function PlayerDataService:Init(services)
	self.Services = services
	self.DataByPlayer = {}
end

function PlayerDataService:PlayerAdded(player)
	if self.DataByPlayer[player] then
		return self.DataByPlayer[player]
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	local cash = leaderstats:FindFirstChild("Cash")
	if not cash then
		cash = Instance.new("IntValue")
		cash.Name = "Cash"
		cash.Value = 0
		cash.Parent = leaderstats
	end

	local broken = leaderstats:FindFirstChild("CasesBroken")
	if not broken then
		broken = Instance.new("IntValue")
		broken.Name = "CasesBroken"
		broken.Value = 0
		broken.Parent = leaderstats
	end

	local escaped = leaderstats:FindFirstChild("Escaped")
	if not escaped then
		escaped = Instance.new("IntValue")
		escaped.Name = "Escaped"
		escaped.Value = 0
		escaped.Parent = leaderstats
	end

	local data = {
		Cash = cash,
		CasesBroken = broken,
		Escaped = escaped,

		OwnedGuns = {},
		PlacedGuns = {},
		Slots = {},
		UnlockedSlots = {
			[1] = true,
			[2] = false,
		},

		ClaimedFreeCrate = false,
	}

	self.DataByPlayer[player] = data
	return data
end

function PlayerDataService:PlayerRemoving(player)
	self.DataByPlayer[player] = nil
end

function PlayerDataService:GetData(player)
	return self.DataByPlayer[player] or self:PlayerAdded(player)
end

function PlayerDataService:AddCash(player, amount)
	local data = self:GetData(player)
	data.Cash.Value += math.floor(amount)
	return data.Cash.Value
end

function PlayerDataService:GetCash(player)
	return self:GetData(player).Cash.Value
end

function PlayerDataService:GiveGun(player, gunId)
	local data = self:GetData(player)
	data.OwnedGuns[gunId] = true
	return true
end

function PlayerDataService:OwnsGun(player, gunId)
	local data = self:GetData(player)
	return data.OwnedGuns[gunId] == true
end

function PlayerDataService:IsGunPlaced(player, gunId)
	local data = self:GetData(player)
	return data.PlacedGuns[gunId] ~= nil
end

function PlayerDataService:MarkGunPlaced(player, gunId, slotId)
	local data = self:GetData(player)
	data.PlacedGuns[gunId] = slotId
	data.Slots[slotId] = gunId
end

function PlayerDataService:UnmarkGunPlaced(player, gunId)
	local data = self:GetData(player)
	local slotId = data.PlacedGuns[gunId]
	data.PlacedGuns[gunId] = nil

	if slotId then
		data.Slots[slotId] = nil
	end
end

function PlayerDataService:GetPlacedSlotForGun(player, gunId)
	local data = self:GetData(player)
	return data.PlacedGuns[gunId]
end

function PlayerDataService:IsSlotOccupied(player, slotId)
	local data = self:GetData(player)
	return data.Slots[slotId] ~= nil
end

function PlayerDataService:GetSlotGun(player, slotId)
	local data = self:GetData(player)
	return data.Slots[slotId]
end

function PlayerDataService:IncrementBrokenCases(player)
	local data = self:GetData(player)
	data.CasesBroken.Value += 1
	return data.CasesBroken.Value
end

function PlayerDataService:IncrementEscaped(player)
	local data = self:GetData(player)
	data.Escaped.Value += 1
	return data.Escaped.Value
end

function PlayerDataService:GetBrokenCases(player)
	return self:GetData(player).CasesBroken.Value
end

function PlayerDataService:HasUnlockedSlot(player, slotId)
	local data = self:GetData(player)
	return data.UnlockedSlots[slotId] == true
end

function PlayerDataService:UnlockSlot(player, slotId)
	local data = self:GetData(player)
	data.UnlockedSlots[slotId] = true
end

return PlayerDataService
