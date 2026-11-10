local config = require 'configs.client'
local photocache = require 'client.modules.photocache'

local visuals = {}

local resource = cache.resource
local PAGE <const> = ('https://cfx-nui-%s/web/card.html'):format(resource)
local CARD_EVENT <const> = ('%s:server:card'):format(resource)
local MODEL_PREFIX <const> = 'bl_idcard_'
local POOL <const> = 8
local TEXTURE_WIDTH <const> = 1024
local TEXTURE_HEIGHT <const> = 1346
local RETRY_MS <const> = 3000
local TICK_MS <const> = 150

---@class IdCardSlot
---@field index integer
---@field model integer
---@field txd string
---@field dui table?
---@field pageReady boolean
---@field rendered boolean
---@field owner integer?

---@class IdCardVisual
---@field serverId integer
---@field token string
---@field slot IdCardSlot
---@field object integer
---@field pose string
---@field back boolean
---@field attached string?
---@field ped integer
---@field spin number

---@type IdCardSlot[]
local slots = {}
---@type table<integer, { token: string, pose: string, back: boolean }>
local holders = {}
---@type table<integer, IdCardVisual>
local active = {}
---@type table<string, { holder: integer, card: table, photoId: integer|string? }>
local cardData = {}
---@type table<string, integer>
local failedAt = {}
---@type table<string, boolean>
local fetching = {}
---@type table<integer, boolean>
local building = {}
local watching = false

for i = 1, POOL do
    local name = ('%s%d'):format(MODEL_PREFIX, i)
    slots[i] = { index = i, model = joaat(name), txd = name, pageReady = false, rendered = false }
end

---@return IdCardSlot?
local function takeSlot()
    for i = 1, #slots do
        if not slots[i].owner then return slots[i] end

    end

end

---@param slot IdCardSlot
local function ensurePage(slot)
    if slot.dui then return end

    slot.pageReady = false
    slot.dui = lib.dui:new({
        url = ('%s?id=%d&res=%s'):format(PAGE, slot.index, resource),
        width = TEXTURE_WIDTH,
        height = TEXTURE_HEIGHT,
    })
end

---@param slot IdCardSlot
---@param field 'pageReady'|'rendered'
---@param timeout integer
---@return boolean
local function waitFor(slot, field, timeout)
    return pcall(lib.waitFor, function() return slot[field] or nil end, nil, timeout)
end

---@param token string
---@param serverId integer
---@return { holder: integer, card: table, photoId: integer|string? }?, string?
local function fetchCard(token, serverId)
    local cached = cardData[token]
    if cached and cached.holder == serverId then return cached end

    if fetching[token] then return end

    if failedAt[token] and GetGameTimer() - failedAt[token] < RETRY_MS then return end

    fetching[token] = true
    local result = lib.callback.await(CARD_EVENT, false, token)
    fetching[token] = nil

    if type(result) ~= 'table' or not result.ok or type(result.card) ~= 'table' or result.holder ~= serverId then
        failedAt[token] = GetGameTimer()

        return nil, type(result) == 'table' and result.reason or nil
    end

    local photoId = type(result.photoId) == 'string' and result.photoId or math.tointeger(result.photoId)

    cardData[token] = { holder = serverId, card = result.card, photoId = photoId }

    return cardData[token]
end

---@param visual IdCardVisual
local function attach(visual)
    local ped = visual.ped
    local car = config.poses.car
    local seated = IsPedInAnyVehicle(ped, false)
    local inCar = seated and visual.pose ~= 'flash' and IsEntityPlayingAnim(ped, car.dict, car.clip, 3)
    local pose = inCar and car or (seated and visual.pose == 'flash' and config.poses.windowShow) or config.poses[visual.pose] or config.poses.hold
    local key = ('%s:%s:%s:%.1f'):format(visual.pose, visual.back, inCar, visual.spin)
    if visual.attached == key then return end

    local rotation = pose.rotation
    local yaw = rotation.z + (visual.back and 180.0 or 0.0) + visual.spin

    AttachEntityToEntity(visual.object, ped, GetPedBoneIndex(ped, pose.bone),
        pose.offset.x, pose.offset.y, pose.offset.z, rotation.x, rotation.y, yaw,
        false, false, false, false, 2, true)

    visual.attached = key
end

---@param serverId integer
local function remove(serverId)
    local visual = active[serverId]
    if not visual then return end

    active[serverId] = nil

    if DoesEntityExist(visual.object) then DeleteEntity(visual.object) end

    RemoveReplaceTexture(visual.slot.txd, visual.slot.txd)
    SetModelAsNoLongerNeeded(visual.slot.model)
    visual.slot.owner = nil
end

---@param token string
local function forget(token)
    for _, state in pairs(holders) do
        if state.token == token then return end

    end

    cardData[token] = nil
    failedAt[token] = nil
end

---@param slot IdCardSlot
---@param serverId integer
local function release(slot, serverId)
    slot.owner = nil
    building[serverId] = nil
end

---@param serverId integer
---@param state { token: string, pose: string, back: boolean }
---@param ped integer
local function build(serverId, state, ped)
    building[serverId] = true

    local data, reason = fetchCard(state.token, serverId)

    if reason == 'not_found' then
        building[serverId] = nil

        return visuals.update(serverId, nil)
    end

    local slot = data and takeSlot()
    if not slot then
        building[serverId] = nil

        return
    end

    slot.owner = serverId

    if data.photoId and not photocache.peek(data.photoId) then
        CreateThread(function() photocache.get(state.token, data.photoId) end)
    end

    ensurePage(slot)

    if not waitFor(slot, 'pageReady', 5000) then
        slot.dui:remove()
        slot.dui = nil

        return release(slot, serverId)
    end

    local current = holders[serverId]
    if not current or current.token ~= state.token then return release(slot, serverId) end

    if not pcall(lib.requestModel, slot.model) then return release(slot, serverId) end

    local photo = data.photoId and photocache.peek(data.photoId)

    slot.rendered = false
    slot.dui:sendMessage({ action = 'card', card = data.card, photo = photo })

    if data.photoId and not photo then
        local token, dui = state.token, slot.dui

        CreateThread(function()
            local loaded = photocache.get(token, data.photoId)
            local now = holders[serverId]

            if loaded and now and now.token == token and slot.dui == dui then
                dui:sendMessage({ action = 'card', card = data.card, photo = loaded })
            end

        end)

    end

    waitFor(slot, 'rendered', 3000)
    slot.dui:sendMessage({ action = 'tilt', x = 0, y = 0, glare = 0.15 })

    current = holders[serverId]
    if not current or current.token ~= state.token or not DoesEntityExist(ped) then
        SetModelAsNoLongerNeeded(slot.model)

        return release(slot, serverId)
    end

    AddReplaceTexture(slot.txd, slot.txd, slot.dui.dictName, slot.dui.txtName)

    local coords = GetEntityCoords(ped)
    local object = CreateObjectNoOffset(slot.model, coords.x, coords.y, coords.z, false, false, false)

    if object == 0 then
        RemoveReplaceTexture(slot.txd, slot.txd)
        SetModelAsNoLongerNeeded(slot.model)

        return release(slot, serverId)
    end

    SetEntityCollision(object, false, false)
    SetEntityCompletelyDisableCollision(object, false, false)

    active[serverId] = {
        serverId = serverId,
        token = current.token,
        slot = slot,
        object = object,
        pose = current.pose,
        back = current.back,
        ped = ped,
        spin = 0.0,
    }

    attach(active[serverId])
    building[serverId] = nil
end

local function tick()
    local origin = GetEntityCoords(cache.ped)

    for serverId, state in pairs(holders) do
        local player = GetPlayerFromServerId(serverId)
        local ped = player ~= -1 and GetPlayerPed(player) or 0
        local visual = active[serverId]

        if ped == 0 or not DoesEntityExist(ped) or #(GetEntityCoords(ped) - origin) > config.viewDistance then
            if visual then remove(serverId) end

        elseif visual then
            if visual.ped ~= ped then
                visual.ped = ped
                visual.attached = nil
            end

            attach(visual)
        elseif not building[serverId] then
            CreateThread(function() build(serverId, state, ped) end)

        end

    end

    for serverId in pairs(active) do
        if not holders[serverId] then remove(serverId) end

    end

end

local function watch()
    if watching then return end

    watching = true

    CreateThread(function()
        while next(holders) or next(active) do
            tick()
            Wait(TICK_MS)
        end

        watching = false
    end)

end

---@param serverId integer
---@return IdCardVisual?
function visuals.get(serverId)
    return active[serverId]
end

---@param serverId integer
---@return boolean
function visuals.isShowing(serverId)
    local state = holders[serverId]

    return state ~= nil and state.pose == 'flash'
end

---@param serverId integer
---@param message table
function visuals.send(serverId, message)
    local visual = active[serverId]
    if visual and visual.slot.dui then visual.slot.dui:sendMessage(message) end

end

---@param serverId integer
---@param back boolean
---@param spin number
function visuals.pose(serverId, back, spin)
    local visual = active[serverId]
    if not visual then return end

    visual.back = back
    visual.spin = spin
    attach(visual)
end

---@param index integer
function visuals.pageReady(index)
    local slot = slots[index]
    if slot then slot.pageReady = true end

end

---@param index integer
function visuals.rendered(index)
    local slot = slots[index]
    if slot then slot.rendered = true end

end

---@param serverId integer
---@param value any
function visuals.update(serverId, value)
    local previous = holders[serverId]

    if type(value) ~= 'table' or type(value.token) ~= 'string' then
        holders[serverId] = nil
        remove(serverId)
        if previous then forget(previous.token) end

        return
    end

    holders[serverId] = { token = value.token, pose = value.pose or 'hold', back = value.back == true }

    if previous and previous.token ~= value.token then
        remove(serverId)
        forget(previous.token)
    end

    local visual = active[serverId]
    if visual then
        visual.pose = holders[serverId].pose
        visual.back = holders[serverId].back
    end

    watch()
end

function visuals.stop()
    for serverId in pairs(active) do remove(serverId) end

    for i = 1, #slots do
        if slots[i].dui then slots[i].dui:remove() end

    end

    photocache.clear()
end

return visuals
