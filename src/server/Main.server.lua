local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local function getOrCreateFolder(parent, name)
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("Folder") then
		return existing
	end

	if existing then
		existing:Destroy()
	end

	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

local function getOrCreateRemote(parent, name)
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end

	if existing then
		existing:Destroy()
	end

	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = parent
	return remote
end

local remotes = getOrCreateFolder(ReplicatedStorage, "Remotes")
getOrCreateRemote(remotes, "ClaimFreeCrate")
getOrCreateRemote(remotes, "CrateResult")
getOrCreateRemote(remotes, "PlayerUpdate")

local ServicesFolder = script.Parent:WaitForChild("Services")

local PlayerDataService = require(ServicesFolder:WaitForChild("PlayerDataService"))
local RewardService = require(ServicesFolder:WaitForChild("RewardService"))
local CrateService = require(ServicesFolder:WaitForChild("CrateService"))
local PlotService = require(ServicesFolder:WaitForChild("PlotService"))

local services = {
	PlayerDataService = PlayerDataService,
	RewardService = RewardService,
	CrateService = CrateService,
	PlotService = PlotService,
	Remotes = remotes,
}

PlayerDataService:Init(services)
RewardService:Init(services)
CrateService:Init(services)
PlotService:Init(services)

Players.PlayerAdded:Connect(function(player)
	PlayerDataService:PlayerAdded(player)
	PlotService:PlayerAdded(player)
	RewardService:PushUpdate(player)
end)

Players.PlayerRemoving:Connect(function(player)
	PlotService:PlayerRemoving(player)
	PlayerDataService:PlayerRemoving(player)
end)

for _, player in ipairs(Players:GetPlayers()) do
	PlayerDataService:PlayerAdded(player)
	PlotService:PlayerAdded(player)
	RewardService:PushUpdate(player)
end

print("[MyGunFarm] Plot-controller shooting slice loaded")
