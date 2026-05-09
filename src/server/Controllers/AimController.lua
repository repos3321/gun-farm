local AimController = {}
AimController.__index = AimController

function AimController.new(plotController)
	local self = setmetatable({}, AimController)
	self.Plot = plotController
	return self
end

function AimController:AimAt(gunModel, targetPosition)
	if not gunModel or not gunModel.Parent then
		return
	end

	local pivot = gunModel:GetAttribute("PivotPosition")
	if typeof(pivot) ~= "Vector3" then
		local primary = gunModel.PrimaryPart
		if primary then
			pivot = primary.Position
		else
			return
		end
	end

	local lookTarget = Vector3.new(targetPosition.X, pivot.Y, targetPosition.Z)
	local cf = CFrame.lookAt(pivot, lookTarget)

	gunModel:PivotTo(cf)
end

return AimController
