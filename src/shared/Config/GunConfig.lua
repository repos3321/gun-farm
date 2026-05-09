-- GunConfig.lua
-- All gun definitions. Add new guns here when new crates are introduced.

return {
	StarterPistol = {
		Id          = "StarterPistol",
		DisplayName = "Starter Pistol",
		Damage      = 25,      -- HP per shot
		FireRate    = 1.2,     -- shots per second
		Range       = 20,      -- studs; how far along the lane it can target
		BulletColor = Color3.fromRGB(255, 220, 50),
		Rarity      = "Common",
	},
}
