local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local claimRemote = remotes:WaitForChild("ClaimFreeCrate")
local playerUpdate = remotes:WaitForChild("PlayerUpdate")
local crateResult = remotes:WaitForChild("CrateResult")

local gui = Instance.new("ScreenGui")
gui.Name = "GunFarmHUD"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local cashLabel = Instance.new("TextLabel")
cashLabel.Name = "CashLabel"
cashLabel.Size = UDim2.fromOffset(220, 44)
cashLabel.Position = UDim2.fromOffset(18, 18)
cashLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
cashLabel.BackgroundTransparency = 0.2
cashLabel.TextColor3 = Color3.fromRGB(90, 255, 120)
cashLabel.TextStrokeTransparency = 0
cashLabel.TextScaled = true
cashLabel.Font = Enum.Font.GothamBlack
cashLabel.Text = "$0"
cashLabel.Parent = gui

local objectiveLabel = Instance.new("TextLabel")
objectiveLabel.Name = "ObjectiveLabel"
objectiveLabel.Size = UDim2.fromOffset(380, 52)
objectiveLabel.Position = UDim2.new(0.5, -190, 0, 18)
objectiveLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
objectiveLabel.BackgroundTransparency = 0.2
objectiveLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
objectiveLabel.TextStrokeTransparency = 0
objectiveLabel.TextScaled = true
objectiveLabel.Font = Enum.Font.GothamBold
objectiveLabel.Text = "Claim FREE GUN CRATE"
objectiveLabel.Parent = gui

local claimButton = Instance.new("TextButton")
claimButton.Name = "ClaimButton"
claimButton.Size = UDim2.fromOffset(230, 52)
claimButton.Position = UDim2.fromOffset(18, 72)
claimButton.BackgroundColor3 = Color3.fromRGB(35, 190, 80)
claimButton.TextColor3 = Color3.fromRGB(255, 255, 255)
claimButton.TextStrokeTransparency = 0
claimButton.TextScaled = true
claimButton.Font = Enum.Font.GothamBlack
claimButton.Text = "FREE GUN CRATE"
claimButton.Parent = gui

local popup = Instance.new("TextLabel")
popup.Name = "Popup"
popup.Size = UDim2.fromOffset(320, 60)
popup.Position = UDim2.new(0.5, -160, 0, 82)
popup.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
popup.BackgroundTransparency = 0.25
popup.TextColor3 = Color3.fromRGB(255, 230, 80)
popup.TextStrokeTransparency = 0
popup.TextScaled = true
popup.Font = Enum.Font.GothamBlack
popup.Text = ""
popup.Visible = false
popup.Parent = gui

claimButton.Activated:Connect(function()
	claimRemote:FireServer()
end)

playerUpdate.OnClientEvent:Connect(function(payload)
	cashLabel.Text = "$" .. tostring(payload.cash or 0)
	objectiveLabel.Text = payload.objective or "..."

	if payload.hasStarterPistol then
		claimButton.Text = "STARTER OWNED"
		claimButton.BackgroundColor3 = Color3.fromRGB(70, 80, 95)
	end
end)

crateResult.OnClientEvent:Connect(function(payload)
	popup.Text = payload.message or ("Unlocked " .. tostring(payload.displayName or payload.gunId))
	popup.Visible = true

	task.delay(1.8, function()
		popup.Visible = false
	end)
end)
