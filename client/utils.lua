local Utils = {}

--- Used to send NUI events to the UI
--- @param action string
--- @param data any
function Utils.SendNUIEvent(action, data)
    SendNUIMessage({
        action = action,
        data = data
    })
end

function Utils.GetMugShot()
    local oldMask = GetPedDrawableVariation(cache.ped, 1)
    local hasMask = oldMask ~= 0

    if hasMask then
        SetPedComponentVariation(cache.ped, 1, 0, 0, 2)
    end

    local mugshot = exports['MugShotBase64']:GetMugShotBase64(cache.ped, false)

    if hasMask then
        SetPedComponentVariation(cache.ped, 1, oldMask, 0, 2)
    end

    return mugshot
end

local function rotationToDirection(rotation)
	local adjustedRotation = 
	{ 
		x = (math.pi / 180) * rotation.x, 
		y = (math.pi / 180) * rotation.y, 
		z = (math.pi / 180) * rotation.z 
	}
	local direction = 
	{
		x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)), 
		y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)), 
		z = math.sin(adjustedRotation.x)
	}
	return direction
end

local function rayCastGamePlayCamera(distance)
	local cameraRotation = GetGameplayCamRot()
	local cameraCoord = GetGameplayCamCoord()
	local direction = rotationToDirection(cameraRotation)
	local destination = 
	{ 
		x = cameraCoord.x + direction.x * distance, 
		y = cameraCoord.y + direction.y * distance, 
		z = cameraCoord.z + direction.z * distance 
	}
	local a, b, c, d, e = GetShapeTestResult(StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, -1, -1, 1))
	return b, c, e
end

function Utils.GetPlayerLookingAt()
    local config = require "shared.config"
    local range = config.range

    local hit, _, entity = rayCastGamePlayCamera(range)

		if hit and IsEntityAPed(entity) then
            local isPlayer = IsPedAPlayer(entity)
            if isPlayer then
                local serverId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(entity))
                return serverId
            end

		end

end

return Utils