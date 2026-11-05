local visuals = require 'client.modules.visuals'

local camera = {}

local HEAD_BONE <const> = 31086
local EASE_MS <const> = 350
local INSPECT_DISTANCE <const> = 0.17
local INSPECT_FOV <const> = 38.0
local INSPECT_TILT <const> = 24.0
local FLIP_MS <const> = 450
local GLANCE_DISTANCE <const> = 0.32
local GLANCE_FOV <const> = 30.0
local GLANCE_GRACE_MS <const> = 1000

---@type integer?
local cam
---@type integer
local session = 0

---@param object integer
---@return vector3 centre, vector3 up
local function frameOf(object)
    local centre = GetEntityCoords(object)
    local up = GetOffsetFromEntityInWorldCoords(object, -1.0, 0.0, 0.0) - centre

    return centre, up
end

---@param v vector3
---@param axis vector3
---@param degrees number
---@return vector3
local function rotate(v, axis, degrees)
    local a = math.rad(degrees)
    local c, s = math.cos(a), math.sin(a)
    local k = axis / #axis

    return v * c + vec3(k.y * v.z - k.z * v.y, k.z * v.x - k.x * v.z, k.x * v.y - k.y * v.x) * s + k * (k.x * v.x + k.y * v.y + k.z * v.z) * (1 - c)
end

---@param fov number
local function open(fov)
    if cam then return end

    cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, fov, false, 2)
    SetCamUseShallowDofMode(cam, true)
    SetCamNearDof(cam, 0.04)
    SetCamFarDof(cam, 0.9)
    SetCamDofStrength(cam, 1.0)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, EASE_MS, true, false)
end

local function close()
    if not cam then return end

    RenderScriptCams(false, true, EASE_MS, true, false)
    DestroyCam(cam, false)
    cam = nil
end

---@param centre vector3
---@param up vector3
---@param viewer vector3
---@param distance number
---@param yaw number
---@param pitch number
local function place(centre, up, viewer, distance, yaw, pitch)
    local facing = viewer - centre
    facing = #facing > 0.001 and facing / #facing or vec3(0.0, 0.0, 1.0)
    local side = vec3(facing.y * up.z - facing.z * up.y, facing.z * up.x - facing.x * up.z, facing.x * up.y - facing.y * up.x)
    if #side < 0.001 then side = vec3(1.0, 0.0, 0.0) end

    local dir = rotate(rotate(facing, up, yaw), side, pitch)
    local pos = centre + dir * distance

    SetCamCoord(cam, pos.x, pos.y, pos.z)
    PointCamAtCoord(cam, centre.x, centre.y, centre.z)
    SetUseHiDof()
end

function camera.stop()
    session += 1
    close()
end

---@param serverId integer
---@param state { back: boolean, flip: fun(back: boolean), done: fun(), keys: table }
function camera.inspect(serverId, state)
    close()
    session += 1
    local current = session
    local visual = visuals.get(serverId)
    if not visual then return state.done() end

    open(INSPECT_FOV)

    local yaw, pitch = 0.0, 0.0
    local spin, spinFrom, spinStart = 0.0, 0.0, 0
    local limit = INSPECT_TILT
    local lastSend = 0
    local keys = state.keys

    CreateThread(function()
        while session == current do
            visual = visuals.get(serverId)
            if not visual or not DoesEntityExist(visual.object) then break end

            DisableAllControlActions(0)
            EnableControlAction(0, 249, true)
            EnableControlAction(0, 245, true)

            yaw = math.max(-limit, math.min(limit, yaw + GetDisabledControlNormal(0, 1) * 6.0)) * 0.985
            pitch = math.max(-limit, math.min(limit, pitch + GetDisabledControlNormal(0, 2) * 6.0)) * 0.985

            if IsDisabledControlJustPressed(0, keys.flip) and spin == 0.0 then
                state.back = not state.back
                state.flip(state.back)
                spinFrom, spinStart = -180.0, GetGameTimer()
                spin = spinFrom
            end

            if spin ~= 0.0 then
                local t = math.min(1.0, (GetGameTimer() - spinStart) / FLIP_MS)
                local eased = t * t * (3 - 2 * t)
                spin = t >= 1.0 and 0.0 or spinFrom * (1 - eased)
            end

            visuals.pose(serverId, state.back, spin)

            if IsDisabledControlJustPressed(0, keys.close) then break end

            local centre, up = frameOf(visual.object)
            place(centre, up, GetPedBoneCoords(cache.ped, HEAD_BONE, 0.0, 0.0, 0.0), INSPECT_DISTANCE, yaw, pitch)

            local now = GetGameTimer()
            if now - lastSend > 33 then
                lastSend = now
                local tx, ty = yaw / limit, pitch / limit
                visuals.send(serverId, { action = 'tilt', x = tx, y = ty, glare = 0.12 + 0.55 * math.min(1.0, math.sqrt(tx * tx + ty * ty)) })
            end

            Wait(0)
        end

        if session == current then
            visuals.pose(serverId, state.back, 0.0)
            visuals.send(serverId, { action = 'tilt', x = 0, y = 0, glare = 0.15 })
            close()
            state.done()
        end

    end)

end

---@param serverId integer
---@param duration integer
---@param closeKey integer
function camera.glance(serverId, duration, closeKey)
    if cam then return end

    session += 1
    local current = session

    CreateThread(function()
        local found = pcall(lib.waitFor, function() return visuals.get(serverId) end, nil, 1500)
        if not found or session ~= current then return end

        open(GLANCE_FOV)
        local finish = GetGameTimer() + duration
        local grace = GetGameTimer() + GLANCE_GRACE_MS
        local seen = false

        while session == current and GetGameTimer() < finish do
            local visual = visuals.get(serverId)
            if not visual or not DoesEntityExist(visual.object) then break end

            if IsControlJustPressed(0, closeKey) then break end

            if visual.pose == 'flash' then
                seen = true
            elseif seen or GetGameTimer() > grace then
                break
            end

            local centre, up = frameOf(visual.object)
            place(centre, up, GetPedBoneCoords(cache.ped, HEAD_BONE, 0.0, 0.0, 0.0), GLANCE_DISTANCE, 0.0, 0.0)

            Wait(0)
        end

        if session == current then close() end

    end)

end

return camera
