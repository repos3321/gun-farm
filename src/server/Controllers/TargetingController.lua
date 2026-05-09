local TargetingController = {}
TargetingController.__index = TargetingController

function TargetingController.new(plotController)
	local self = setmetatable({}, TargetingController)
	self.Plot = plotController
	return self
end

function TargetingController:GetTargetForSlot(slotController)
	local muzzlePosition = slotController:GetMuzzlePosition()
	if not muzzlePosition then
		return nil
	end

	local bestCase = nil
	local bestProgress = -math.huge

	for _, caseData in ipairs(self.Plot.Conveyor:GetAliveCases()) do
		if caseData.Core and caseData.Core.Parent then
			local distance = (caseData.Core.Position - muzzlePosition).Magnitude

			if distance <= slotController.Range and caseData.Progress > bestProgress then
				bestCase = caseData
				bestProgress = caseData.Progress
			end
		end
	end

	return bestCase
end

return TargetingController
