-- GunFarmClient.client.lua
-- Minimal client: renders the FREE CRATE button, slot prompts,
-- cash display, and objective tracker.
-- Server is authoritative for everything. Client only displays + fires remotes.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for Remotes folder
local remotes        = ReplicatedStorage:WaitForChild("Remotes")
local ClaimCrateRE   = remotes:WaitForChild("ClaimFreeCrate")
local CrateResultRE  = remotes:WaitForChild("CrateResult")
local PlaceGunRE     = remotes:WaitForChild("PlaceGun")
local SlotStateRE    = remotes:WaitForChild("SlotState")
local PlayerUpdateRE = remotes:WaitForChild("PlayerUpdate")

-- ── Build ScreenGui ──────────────────────────────────────────────────────────

local gui = Instance.new("ScreenGui")
gui.Name            = "GunFarmHUD"
gui.ResetOnSpawn    = false
gui.IgnoreGuiInset  = true
gui.Parent          = playerGui

-- ── Cash label (top-left) ────────────────────────────────────────────────────

local cashLabel = Instance.new("TextLabel")
cashLabel.Name              = "CashLabel"
cashLabel.Size              = UDim2.new(0, 200, 0, 40)
cashLabel.Position          = UDim2.new(0, 16, 0, 16)
cashLabel.BackgroundColor3  = Color3.fromRGB(20, 20, 20)
cashLabel.BackgroundTransparency = 0.3
cashLabel.TextColor3        = Color3.fromRGB(255, 215, 0)
cashLabel.Font              = Enum.Font.GothamBold
cashLabel.TextSize          = 20
cashLabel.Text              = "💰 $0"
cashLabel.TextXAlignment    = Enum.TextXAlignment.Left
cashLabel.Parent            = gui

local cashPad = Instance.new("UIPadding")
cashPad.PaddingLeft = UDim.new(0, 8)
cashPad.Parent = cashLabel

local cashCorner = Instance.new("UICorner")
cashCorner.CornerRadius = UDim.new(0, 8)
cashCorner.Parent = cashLabel

-- ── Objective label (top-centre) ─────────────────────────────────────────────

local objLabel = Instance.new("TextLabel")
objLabel.Name              = "ObjLabel"
objLabel.Size              = UDim2.new(0, 260, 0, 44)
objLabel.Position          = UDim2.new(0.5, -130, 0, 16)
objLabel.BackgroundColor3  = Color3.fromRGB(20, 20, 20)
objLabel.BackgroundTransparency = 0.3
objLabel.TextColor3        = Color3.new(1, 1, 1)
objLabel.Font              = Enum.Font.Gotham
objLabel.TextSize          = 18
objLabel.Text              = "🎯 Break 3 cases: 0 / 3"
objLabel.Parent            = gui

local objCorner = Instance.new("UICorner")
objCorner.CornerRadius = UDim.new(0, 8)
objCorner.Parent = objLabel

-- ── FREE CRATE button (centre-bottom) ────────────────────────────────────────

local crateFrame = Instance.new("Frame")
crateFrame.Name                  = "CrateFrame"
crateFrame.Size                  = UDim2.new(0, 280, 0, 80)
crateFrame.Position              = UDim2.new(0.5, -140, 1, -110)
crateFrame.BackgroundColor3      = Color3.fromRGB(255, 180, 0)
crateFrame.Parent                = gui

local crateCorner = Instance.new("UICorner")
crateCorner.CornerRadius = UDim.new(0, 12)
crateCorner.Parent = crateFrame

local crateBtn = Instance.new("TextButton")
crateBtn.Size               = UDim2.new(1, 0, 1, 0)
crateBtn.BackgroundTransparency = 1
crateBtn.Font               = Enum.Font.GothamBold
crateBtn.TextSize            = 22
crateBtn.TextColor3          = Color3.fromRGB(20, 20, 20)
crateBtn.Text                = "🎁 FREE GUN CRATE"
crateBtn.Parent              = crateFrame

-- ── Slot panel (right side) ───────────────────────────────────────────────────

local slotPanel = Instance.new("Frame")
slotPanel.Name               = "SlotPanel"
slotPanel.Size               = UDim2.new(0, 160, 0, 200)
slotPanel.Position           = UDim2.new(1, -176, 0.5, -100)
slotPanel.BackgroundTransparency = 1
slotPanel.Parent             = gui

local slotLayout = Instance.new("UIListLayout")
slotLayout.SortOrder    = Enum.SortOrder.LayoutOrder
slotLayout.Padding      = UDim.new(0, 8)
slotLayout.Parent       = slotPanel

local slotFrames = {}

local function makeSlotFrame(slotNum)
	local f = Instance.new("Frame")
	f.Size             = UDim2.new(1, 0, 0, 90)
	f.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	f.LayoutOrder      = slotNum
	f.Parent           = slotPanel

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = f

	local title = Instance.new("TextLabel")
	title.Name              = "Title"
	title.Size              = UDim2.new(1, 0, 0.4, 0)
	title.BackgroundTransparency = 1
	title.TextColor3        = Color3.new(1, 1, 1)
	title.Font              = Enum.Font.GothamBold
	title.TextSize          = 15
	title.Text              = "SLOT " .. slotNum
	title.Parent            = f

	local status = Instance.new("TextLabel")
	status.Name              = "Status"
	status.Size              = UDim2.new(1, 0, 0.35, 0)
	status.Position          = UDim2.new(0, 0, 0.4, 0)
	status.BackgroundTransparency = 1
	status.TextColor3        = Color3.fromRGB(180, 180, 180)
	status.Font              = Enum.Font.Gotham
	status.TextSize          = 13
	status.Text              = "Empty"
	status.Parent            = f

	local btn = Instance.new("TextButton")
	btn.Name                = "PlaceBtn"
	btn.Size                = UDim2.new(0.85, 0, 0.28, 0)
	btn.Position            = UDim2.new(0.075, 0, 0.7, 0)
	btn.BackgroundColor3    = Color3.fromRGB(0, 170, 90)
	btn.TextColor3          = Color3.new(1, 1, 1)
	btn.Font                = Enum.Font.GothamBold
	btn.TextSize            = 13
	btn.Text                = "Place Gun"
	btn.Visible             = false
	btn.Parent              = f

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 6)
	btnCorner.Parent = btn

	slotFrames[slotNum] = { Frame = f, Status = status, PlaceBtn = btn }
	return f
end

makeSlotFrame(1)
makeSlotFrame(2)

-- ── Toast notification ────────────────────────────────────────────────────────

local toastLabel = Instance.new("TextLabel")
toastLabel.Name              = "Toast"
toastLabel.Size              = UDim2.new(0, 300, 0, 50)
toastLabel.Position          = UDim2.new(0.5, -150, 0.7, 0)
toastLabel.BackgroundColor3  = Color3.fromRGB(30, 30, 30)
toastLabel.BackgroundTransparency = 0.1
toastLabel.TextColor3        = Color3.fromRGB(255, 215, 0)
toastLabel.Font              = Enum.Font.GothamBold
toastLabel.TextSize          = 20
toastLabel.Text              = ""
toastLabel.Visible           = false
toastLabel.Parent            = gui

local toastCorner = Instance.new("UICorner")
toastCorner.CornerRadius = UDim.new(0, 10)
toastCorner.Parent = toastLabel

local function showToast(msg, duration)
	toastLabel.Text    = msg
	toastLabel.Visible = true
	task.delay(duration or 2.5, function()
		toastLabel.Visible = false
	end)
end

-- ── Client state ──────────────────────────────────────────────────────────────

local _ownedGuns   = {}   -- { gunId = DisplayName }
local _crateUsed   = false

-- ── Logic ─────────────────────────────────────────────────────────────────────

-- CRATE button
crateBtn.MouseButton1Click:Connect(function()
	if _crateUsed then return end
	ClaimCrateRE:FireServer()
end)

-- Server tells us what we got from the crate
CrateResultRE.OnClientEvent:Connect(function(gunId, displayName)
	_ownedGuns[gunId] = displayName
	_crateUsed = true

	-- Hide crate button
	crateFrame.Visible = false

	showToast("🎉 Got: " .. displayName .. "!", 3)

	-- Show Place button on Slot 1 if it's empty
	local s1 = slotFrames[1]
	if s1 and s1.Status.Text == "Empty" then
		s1.PlaceBtn.Visible = true
		s1.PlaceBtn.Text    = "Place " .. displayName
	end
end)

-- Place gun buttons
for slotNum, sf in pairs(slotFrames) do
	sf.PlaceBtn.MouseButton1Click:Connect(function()
		-- Find first owned gun (this slice: only one possible)
		local gunId = next(_ownedGuns)
		if gunId then
			PlaceGunRE:FireServer(slotNum, gunId)
			sf.PlaceBtn.Visible = false
		end
	end)
end

-- Server sends full slot state after any change
SlotStateRE.OnClientEvent:Connect(function(payload)
	for _, slotData in ipairs(payload) do
		local sf = slotFrames[slotData.SlotNumber]
		if not sf then continue end

		if slotData.Locked then
			sf.Frame.BackgroundColor3 = Color3.fromRGB(60, 30, 30)
			sf.Status.Text            = "🔒 Locked"
			sf.PlaceBtn.Visible       = false

		elseif slotData.GunId then
			sf.Frame.BackgroundColor3 = Color3.fromRGB(30, 70, 30)
			sf.Status.Text            = "✅ " .. slotData.GunId
			sf.PlaceBtn.Visible       = false

		else
			-- Unlocked + empty
			sf.Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
			sf.Status.Text            = "Empty"
			-- Show place button only if we have a gun to put here
			local gunId = next(_ownedGuns)
			if gunId then
				sf.PlaceBtn.Visible = true
				sf.PlaceBtn.Text    = "Place " .. _ownedGuns[gunId]
			end
		end
	end
end)

-- Server sends reward/progress updates
PlayerUpdateRE.OnClientEvent:Connect(function(data)
	cashLabel.Text = "💰 $" .. data.Cash
	objLabel.Text  = string.format("🎯 Break %d cases: %d / %d",
		data.Target, data.BrokenCases, data.Target)

	if data.Event == "Slot2Unlocked" then
		showToast("🔓 Slot 2 UNLOCKED!", 3.5)
	elseif data.Event == "CaseBroken" then
		showToast("+$" .. 10, 1.2)   -- simple cash feedback
	end
end)

print("[GunFarmClient] HUD ready ✓")
