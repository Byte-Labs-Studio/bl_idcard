local config = require 'configs.client'
local shared = require 'configs.shared'
local bridge = require 'bridge.client'
local camera = require 'client.modules.camera'
local visuals = require 'client.modules.visuals'

local holder = {}

local resource = cache.resource
local GRACE_MS <const> = 1000

local KEYS <const> = {
    flash = 38,
    inspect = 23,
    flip = 22,
    close = 194,
    accept = 38,
}

local BLOCKED <const> = { 24, 25, 37, 44, 140, 141, 142, 143, 257, 263, 264, KEYS.flash, KEYS.inspect, KEYS.close }

local GIVE <const> = {
    dict = 'mp_common',
    giver = 'givetake1_a',
    taker = 'givetake1_b',
    durationMs = 1800,
}

local WINDOW <const> = {
    driver = 'issue_ticket_crim',
    other = 'issue_ticket_cop',
    startPhase = 0.745,
    durationMs = 1700,
    std = 'veh@busted_std',
    low = 'veh@busted_low',
    van = 'veh@busted_van',
    lowClasses = { [6] = true, [7] = true },
    vanClasses = { [10] = true, [11] = true, [12] = true, [17] = true, [19] = true, [20] = true },
}

---@param ... string key and locale name pairs
---@return string
local function lines(...)
    local args = { ... }
    local out = {}

    for i = 1, #args, 2 do
        out[#out + 1] = ('[%s] %s'):format(args[i], locale(('prompt.%s'):format(args[i + 1])))
    end

    return table.concat(out, '  \n')
end

local GIVE_LABEL <const> = shared.handover == 'give' and 'give_away' or 'hand_over'

local PROMPTS <const> = shared.handover and {
    own = lines('E', 'show', '{give}', GIVE_LABEL, 'F', 'look', 'BACKSPACE', 'put_away'),
    ownSeated = lines('{give}', GIVE_LABEL, 'F', 'look', 'BACKSPACE', 'put_away'),
    other = lines('F', 'look', '{give}', 'hand_over', 'BACKSPACE', 'hand_back'),
    inspect = lines('MOUSE', 'tilt', 'SPACE', 'flip', 'BACKSPACE', 'done'),
    offer = lines('E', 'take', 'BACKSPACE', 'refuse'),
    look = lines('F', 'look_at'),
} or {
    own = lines('E', 'show', 'F', 'look', 'BACKSPACE', 'put_away'),
    ownSeated = lines('F', 'look', 'BACKSPACE', 'put_away'),
    other = lines('F', 'look', 'BACKSPACE', 'hand_back'),
    inspect = lines('MOUSE', 'tilt', 'SPACE', 'flip', 'BACKSPACE', 'done'),
    offer = lines('E', 'take', 'BACKSPACE', 'refuse'),
    look = lines('F', 'look_at'),
}

---@class IdCardHolding
---@field token string
---@field own boolean
---@field mode 'hold'|'flash'|'inspect'
---@field back boolean
---@field anim { dict: string, clip: string }?
---@field flashUntil integer
---@field pauseUntil integer
---@field inputAfter integer

---@type IdCardHolding?
local holding
---@type { token: string, from: integer, expires: integer }?
local offer
---@type { holder: integer, expires: integer }?
local look
---@type string?
local shown
---@type CKeybind
local handoverKey

---@param name string
---@return string
local function event(name)
    return ('%s:%s'):format(resource, name)
end

---@param text string?
local function prompt(text)
    if shown == text then return end

    shown = text

    if text then
        lib.showTextUI((text:gsub('{give}', handoverKey:getCurrentKey())), { position = 'left-center' })
    else
        lib.hideTextUI()
    end

end

---@return boolean
local function isDriver()
    return cache.vehicle ~= false and cache.seat == -1
end

---@return boolean
local function canShow()
    return not IsPedInAnyVehicle(cache.ped, false) or isDriver()
end

---@param mode 'hold'|'flash'|'inspect'
---@return { dict: string, clip: string }
local function poseAnim(mode)
    if IsPedInAnyVehicle(cache.ped, false) then return mode == 'flash' and config.poses.windowShow or config.poses.car end

    return config.poses[mode] or config.poses.hold
end

---@param vehicle integer
---@return string
local function windowDict(vehicle)
    local class = vehicle ~= 0 and GetVehicleClass(vehicle) or -1

    if WINDOW.lowClasses[class] then return WINDOW.low end

    if WINDOW.vanClasses[class] then return WINDOW.van end

    return WINDOW.std
end

---@param anim { dict: string, clip: string }
local function play(anim)
    local ped = cache.ped

    if holding and holding.anim and (holding.anim.dict ~= anim.dict or holding.anim.clip ~= anim.clip) then
        StopAnimTask(ped, holding.anim.dict, holding.anim.clip, 2.0)
    end

    lib.playAnim(ped, anim.dict, anim.clip, 3.0, 3.0, -1, 49)

    if holding then holding.anim = { dict = anim.dict, clip = anim.clip } end

end

local function sendPose()
    if holding then TriggerServerEvent(event('server:pose'), holding.mode, holding.back) end

end

function holder.stop()
    local current = holding
    if not current then return end

    holding = nil
    camera.stop()
    lib.disableControls:Remove(BLOCKED)
    handoverKey:disable(true)
    prompt(offer and PROMPTS.offer or nil)

    if current.anim then StopAnimTask(cache.ped, current.anim.dict, current.anim.clip, 2.0) end

    bridge.setBusy(false)
end

local function startInspect()
    if not holding or holding.mode ~= 'hold' then return end

    holding.mode = 'inspect'
    sendPose()
    prompt(PROMPTS.inspect)

    local token = holding.token

    camera.inspect(cache.serverId, {
        back = holding.back,
        keys = KEYS,
        flip = function(back)
            if not holding or holding.token ~= token then return end

            holding.back = back
            sendPose()
        end,

        done = function()
            if not holding or holding.token ~= token then return end

            holding.mode = 'hold'
            holding.inputAfter = GetGameTimer() + 300
            sendPose()
        end,

    })
end

local function startFlash()
    if not holding or holding.mode ~= 'hold' or not canShow() then return end

    holding.mode = 'flash'
    holding.back = false

    if isDriver() then RollDownWindow(cache.vehicle, 0) end

    holding.flashUntil = GetGameTimer() + shared.flashTime
    play(poseAnim('flash'))
    sendPose()
end

local function handOver()
    if not holding or holding.mode ~= 'hold' or not shared.handover then return end

    local player = lib.getClosestPlayer(GetEntityCoords(cache.ped), config.giveDistance, false)
    if not player then
        return bridge.notify(locale('notify.nobody_close'), 'error')
    end

    TriggerServerEvent(event('server:offer'), GetPlayerServerId(player))
end

handoverKey = lib.addKeybind({
    name = ('%s_handover'):format(resource),
    description = locale('keybind.hand_over'),
    defaultMapper = 'keyboard',
    defaultKey = 'G',
    disabled = true,
    onPressed = function()
        if holding and holding.mode == 'hold' and not offer and GetGameTimer() >= holding.inputAfter then handOver() end

    end,

})

local function putAway()
    if not holding then return end

    TriggerServerEvent(event(holding.own and 'server:putAway' or 'server:giveBack'))
end

---@param now integer
local function handleInput(now)
    prompt(offer and PROMPTS.offer or (holding.own and (canShow() and PROMPTS.own or PROMPTS.ownSeated) or PROMPTS.other))

    if offer or now < holding.inputAfter then return end

    if holding.own and IsDisabledControlJustPressed(0, KEYS.flash) then
        startFlash()
    elseif IsDisabledControlJustPressed(0, KEYS.inspect) then
        startInspect()
    elseif IsDisabledControlJustPressed(0, KEYS.close) then
        putAway()
    end

end

local function keepAnim()
    local ped = cache.ped
    local want = poseAnim(holding.mode == 'flash' and 'flash' or 'hold')
    local car = config.poses.car

    if not IsEntityPlayingAnim(ped, want.dict, want.clip, 3) then play(want) end

    if want ~= car and IsEntityPlayingAnim(ped, car.dict, car.clip, 3) then
        StopAnimTask(ped, car.dict, car.clip, 4.0)
    end

end

---@param token string
---@param own boolean
function holder.start(token, own)
    if holding then holder.stop() end

    holding = { token = token, own = own, mode = 'hold', back = false, flashUntil = 0, pauseUntil = 0, inputAfter = GetGameTimer() + 400 }
    bridge.setBusy(true)
    lib.disableControls:Add(BLOCKED)
    handoverKey:disable(false)
    SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`, true)
    play(poseAnim('hold'))

    CreateThread(function()
        local nextCheck = 0

        while holding and holding.token == token do
            local now = GetGameTimer()

            lib.disableControls()

            if holding.mode == 'hold' then
                handleInput(now)
            elseif holding.mode == 'flash' then
                prompt(nil)

                if now >= holding.flashUntil then
                    holding.mode = 'hold'
                    play(poseAnim('hold'))
                    sendPose()
                end

            end

            if holding and now >= nextCheck and now >= holding.pauseUntil then
                nextCheck = now + 500
                keepAnim()
            end

            Wait(0)
        end

    end)

end

---@param token string
function holder.release(token)
    if holding and holding.token == token then holder.stop() end

end

---@param side 'driver'|'other'
---@param ped integer
local function windowHandoff(side, ped)
    local me = cache.ped
    local vehicle = side == 'driver' and (cache.vehicle or 0) or (ped ~= 0 and GetVehiclePedIsIn(ped, false) or 0)
    local dict = windowDict(vehicle)
    local clip = side == 'driver' and WINDOW.driver or WINDOW.other

    if side == 'driver' and vehicle ~= 0 then
        RollDownWindow(vehicle, 0)
    elseif ped ~= 0 then
        TaskTurnPedToFaceEntity(me, ped, 500)
    end

    lib.playAnim(me, dict, clip, 4.0, 4.0, WINDOW.durationMs, 48)
    pcall(lib.waitFor, function() return IsEntityPlayingAnim(me, dict, clip, 3) or nil end, nil, 500)
    SetEntityAnimCurrentTime(me, dict, clip, WINDOW.startPhase)
end

---@param role 'giver'|'taker'
---@param other integer
---@param side 'driver'|'other'|nil
function holder.handoff(role, other, side)
    local player = GetPlayerFromServerId(other)
    local ped = player ~= -1 and GetPlayerPed(player) or 0

    if side == 'driver' or side == 'other' then
        if holding then holding.pauseUntil = GetGameTimer() + WINDOW.durationMs + 100 end

        return windowHandoff(side, ped)
    end

    if holding then holding.pauseUntil = GetGameTimer() + GIVE.durationMs end

    if ped ~= 0 and not cache.vehicle then TaskTurnPedToFaceEntity(cache.ped, ped, 600) end

    lib.playAnim(cache.ped, GIVE.dict, role == 'giver' and GIVE.giver or GIVE.taker, 8.0, -8.0, GIVE.durationMs, 48)
end

---@param token string
---@param from integer
---@param time integer
function holder.offer(token, from, time)
    offer = { token = token, from = from, expires = GetGameTimer() + time }
    local current = offer

    CreateThread(function()
        while offer == current do
            if GetGameTimer() > current.expires then
                offer = nil
                TriggerServerEvent(event('server:answer'), false)
                break
            end

            if not holding then prompt(PROMPTS.offer) end

            DisableControlAction(0, KEYS.accept, true)
            DisableControlAction(0, KEYS.close, true)

            if IsDisabledControlJustPressed(0, KEYS.accept) then
                offer = nil
                TriggerServerEvent(event('server:answer'), true)
            elseif IsDisabledControlJustPressed(0, KEYS.close) then
                offer = nil
                TriggerServerEvent(event('server:answer'), false)
            end

            Wait(0)
        end

        if not holding then prompt(nil) end

    end)

end

---@param token string
function holder.cancelOffer(token)
    if offer and offer.token == token then offer = nil end

end

---@param serverId integer
function holder.glance(serverId)
    if holding then return end

    look = { holder = serverId, expires = GetGameTimer() + shared.flashTime }
    local current = look
    local grace = GetGameTimer() + GRACE_MS
    local seen = false

    CreateThread(function()
        while look == current and not holding and GetGameTimer() < current.expires do
            if visuals.isShowing(serverId) then
                seen = true
            elseif seen or GetGameTimer() > grace then
                break
            end

            if not offer then
                prompt(PROMPTS.look)
                DisableControlAction(0, KEYS.inspect, true)

                if IsDisabledControlJustPressed(0, KEYS.inspect) then
                    look = nil
                    prompt(nil)

                    return camera.glance(serverId, shared.flashTime, KEYS.close)
                end

            end

            Wait(0)
        end

        if look == current then look = nil end

        if shown == PROMPTS.look then prompt(nil) end

    end)

end

function holder.teardown()
    holder.stop()
    prompt(nil)
end

return holder
