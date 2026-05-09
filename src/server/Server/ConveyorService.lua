-- ConveyorService.lua
-- Owns the conveyor lane: start/stop, waypoints, movement tick.
-- Movement is driven by CaseService each heartbeat — this module
-- just exposes the waypoints and running state.

local RunService = game:GetService("RunService")

local ConveyorService = {}

-- Per-player conveyor state
-- { [userId] = { Running = bool } }
local _conveyors = {}

-- The lane is defined by a series of world-space CFrame waypoints.
-- In the real game these come from the Workspace model; here we define
-- a straight lane as a fallback so logic works without a map.
-- Main.server.lua can call SetLaneFromWorkspace() after the world loads.
local _laneWaypoints = nil   -- { Vector3, ... }  set from workspace or default

local function buildDefaultLane()
	-- Straight lane: 8 waypoints along the X axis, spaced 5 studs apart
	local pts = {}
	for i = 0, 7 do
		pts[i + 1] = Vector3.new(-20 + i * 5, 1, 0)
	end
	return pts
end

function ConveyorService.Init()
	_laneWaypoints = buildDefaultLane()
end

-- Allow Main to override with workspace-derived waypoints
function ConveyorService.SetLane(waypointList)
	_laneWaypoints = waypointList
end

function ConveyorService.GetLane()
	return _laneWaypoints
end

function ConveyorService.StartForPlayer(player)
	_conveyors[player.UserId] = { Running = true }
	print("[ConveyorService] Conveyor started for", player.Name)
end

function ConveyorService.StopForPlayer(player)
	local c = _conveyors[player.UserId]
	if c then c.Running = false end
end

function ConveyorService.IsRunning(player)
	local c = _conveyors[player.UserId]
	return c and c.Running == true
end

function ConveyorService.Cleanup(player)
	_conveyors[player.UserId] = nil
end

-- Returns the total lane length in studs (used by CaseService to detect escape)
function ConveyorService.LaneLength()
	if not _laneWaypoints or #_laneWaypoints < 2 then return 0 end
	local total = 0
	for i = 2, #_laneWaypoints do
		total += (_laneWaypoints[i] - _laneWaypoints[i-1]).Magnitude
	end
	return total
end

-- Interpolate a world position given a distance along the lane
function ConveyorService.PositionAtDistance(dist)
	local pts = _laneWaypoints
	if not pts or #pts == 0 then return Vector3.zero end
	local remaining = dist
	for i = 2, #pts do
		local seg = (pts[i] - pts[i-1]).Magnitude
		if remaining <= seg then
			local t = remaining / seg
			return pts[i-1]:Lerp(pts[i], t)
		end
		remaining -= seg
	end
	return pts[#pts]   -- past the end
end

return ConveyorService
