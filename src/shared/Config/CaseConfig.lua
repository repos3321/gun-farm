-- CaseConfig.lua
-- Stats for each case type that moves through the conveyor.

return {
	BasicCase = {
		Id          = "BasicCase",
		DisplayName = "Basic Case",
		MaxHP       = 100,
		Speed       = 5,       -- studs per second along the lane
		CashReward  = 10,      -- cash awarded on break
		Color       = Color3.fromRGB(180, 100, 40),
		Size        = Vector3.new(2, 2, 2),
	},
}
