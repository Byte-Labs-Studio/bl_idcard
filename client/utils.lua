local Utils = {}
local events = require "client.events"
local promiseId = nil

--- Used to send NUI events to the UI
--- @param action string
--- @param data any
function Utils.SendNUIEvent(action, data)
    SendNUIMessage({
        action = action,
        data = data
    })
end

RegisterNUICallback(events.Receive.resolveBaseUrl, function(url, cb)
    print('here')
	if not promiseId then return end
	promiseId:resolve(url)
    print(url)
	promiseId = nil
    cb(1)
end)

function Utils.GetMugShot()
	if promiseId then return end

	local ped = cache.ped
    local oldMask = GetPedDrawableVariation(ped, 1)
    local hasMask = oldMask ~= 0

    if hasMask then
        SetPedComponentVariation(ped, 1, 0, 0, 2)
    end

	local headShotHandle = RegisterPedheadshotTransparent(ped) or RegisterPedheadshot_3(ped)
	if not lib.waitFor(function()
		if IsPedheadshotReady(headShotHandle) and IsPedheadshotValid(headShotHandle) then return true end
	end, 'couldn\'t load mugshot', 5000) then return end

	local headShotTxd = GetPedheadshotTxdString(headShotHandle)
    print(headShotTxd)
	Utils.SendNUIEvent(events.Send.requestBaseUrl, headShotTxd)
	UnregisterPedheadshot(headShotHandle)
	if hasMask then
        SetPedComponentVariation(ped, 1, oldMask, 0, 2)
    end

	promiseId = promise.new()
    return Citizen.Await(promiseId)
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