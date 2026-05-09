local CrateService = {}

function CrateService:Init(services)
	self.Services = services
	self.ClaimFreeCrateRemote = services.Remotes:WaitForChild("ClaimFreeCrate")
	self.CrateResultRemote = services.Remotes:WaitForChild("CrateResult")

	self.ClaimFreeCrateRemote.OnServerEvent:Connect(function(player)
		self:ClaimFreeCrate(player)
	end)
end

function CrateService:ClaimFreeCrate(player)
	local dataService = self.Services.PlayerDataService
	local data = dataService:GetData(player)

	if data.ClaimedFreeCrate and dataService:OwnsGun(player, "StarterPistol") then
		self.CrateResultRemote:FireClient(player, {
			gunId = "StarterPistol",
			displayName = "Starter Pistol",
			alreadyOwned = true,
			message = "You already have Starter Pistol",
		})

		self.Services.RewardService:PushUpdate(player)
		return false
	end

	data.ClaimedFreeCrate = true
	dataService:GiveGun(player, "StarterPistol")

	print("[CrateService] Gave StarterPistol to", player.Name)

	self.CrateResultRemote:FireClient(player, {
		gunId = "StarterPistol",
		displayName = "Starter Pistol",
		alreadyOwned = false,
		message = "Starter Pistol unlocked",
	})

	if self.Services.PlotService then
		self.Services.PlotService:RefreshPlayerPlot(player)
	end

	self.Services.RewardService:PushUpdate(player)
	return true
end

return CrateService
