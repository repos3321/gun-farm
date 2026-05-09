local RewardService = {}

function RewardService:Init(services)
	self.Services = services
	self.PlayerUpdate = services.Remotes:WaitForChild("PlayerUpdate")
end

function RewardService:AwardCaseBreak(player, rewardAmount)
	local data = self.Services.PlayerDataService
	data:AddCash(player, rewardAmount)
	return data:IncrementBrokenCases(player)
end

function RewardService:AwardEscape(player)
	return self.Services.PlayerDataService:IncrementEscaped(player)
end

function RewardService:GetObjectiveText(player)
	local dataService = self.Services.PlayerDataService
	local data = dataService:GetData(player)

	if dataService:HasUnlockedSlot(player, 2) then
		return "Slot 2 Unlocked"
	end

	if not data.OwnedGuns.StarterPistol then
		return "Claim FREE GUN CRATE"
	end

	if not data.PlacedGuns.StarterPistol then
		return "Place Starter Pistol"
	end

	local broken = math.clamp(data.CasesBroken.Value, 0, 3)
	return string.format("Break 3 cases: %d / 3", broken)
end

function RewardService:PushUpdate(player, overrideObjective)
	if not player or not player.Parent then
		return
	end

	local data = self.Services.PlayerDataService:GetData(player)

	self.PlayerUpdate:FireClient(player, {
		cash = data.Cash.Value,
		casesBroken = data.CasesBroken.Value,
		escaped = data.Escaped.Value,
		objective = overrideObjective or self:GetObjectiveText(player),
		hasStarterPistol = data.OwnedGuns.StarterPistol == true,
		starterPistolPlaced = data.PlacedGuns.StarterPistol ~= nil,
		slot2Unlocked = data.UnlockedSlots[2] == true,
	})
end

return RewardService
