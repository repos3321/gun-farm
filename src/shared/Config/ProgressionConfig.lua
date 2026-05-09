-- ProgressionConfig.lua
-- Unlock thresholds and objective targets for this slice.

return {
	-- How many cases must be broken before Slot 2 unlocks
	Slot2UnlockAt = 3,

	-- The objective shown to the player on join
	StarterObjective = {
		Label    = "Break {target} Cases",
		Target   = 3,
	},

	-- Conveyor timing
	CaseSpawnInterval = 4,    -- seconds between case spawns once conveyor is running
	MaxCasesOnBelt    = 4,    -- never spawn more than this many live cases at once

	-- Starting cash for a new session
	StartingCash = 0,
}
