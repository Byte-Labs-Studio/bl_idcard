local config = require 'configs.server'
local shared = require 'configs.shared'
local bridge = require 'bridge.server'
local cards = require 'server.modules.cards'
local photos = require 'server.modules.photos'

local shows = {}

local resource = cache.resource
local STATE <const> = ('%s:show'):format(resource)
local GIVE_SWAP_MS <const> = 900
local WINDOW_SWAP_MS <const> = 820

---@class IdCardShow
---@field token string
---@field owner integer
---@field holder integer
---@field name string
---@field slot integer
---@field cardId string
---@field metadata table
---@field photoId integer?
---@field card table
---@field pose string
---@field back boolean
---@field moving boolean

---@type table<string, IdCardShow>
local active = {}
---@type table<integer, string>
local byOwner = {}
---@type table<integer, string>
local byHolder = {}
---@type table<integer, { token: string, from: integer, expires: integer }>
local offers = {}
---@type table<integer, string>
local incoming = {}
---@type table<integer, table<string, integer>>
local last = {}
---@type table<integer, { pose: string, back: boolean }>
local queuedPose = {}
---@type table<integer, { tokens: number, updated: integer }>
local photoBudgets = {}
local watching = false

---@param name string
---@return string
local function event(name)
    return ('%s:%s'):format(resource, name)
end

shows.notify = bridge.notify

local notify = bridge.notify
local incapacitated = bridge.incapacitated

---@param src integer
---@param key string
---@param wait integer
---@return boolean
function shows.throttle(src, key, wait)
    local now = GetGameTimer()
    local entry = last[src]

    if not entry then
        entry = {}
        last[src] = entry
    end

    if entry[key] and now - entry[key] < wait then return false end

    entry[key] = now

    return true
end

---@param src integer
---@return boolean
function shows.photoBudget(src)
    local now = GetGameTimer()
    local budget = photoBudgets[src]

    if not budget then
        budget = { tokens = 8, updated = now }
        photoBudgets[src] = budget
    end

    budget.tokens = math.min(8, budget.tokens + math.max(0, now - budget.updated) * 0.008)
    budget.updated = now
    if budget.tokens < 1 then return false end

    budget.tokens = budget.tokens - 1

    return true
end

---@param src integer
---@return boolean
local function online(src)
    return src > 0 and GetPlayerName(src) ~= nil and GetPlayerPed(src) ~= 0
end

---@param a integer
---@param b integer
---@param range number
---@return boolean
local function near(a, b, range)
    if not online(a) or not online(b) then return false end

    if GetPlayerRoutingBucket(a) ~= GetPlayerRoutingBucket(b) then return false end

    return #(GetEntityCoords(GetPlayerPed(a)) - GetEntityCoords(GetPlayerPed(b))) <= range
end

---@param show IdCardShow
local function publish(show)
    Player(show.holder).state:set(STATE, { token = show.token, pose = show.pose, back = show.back }, true)
end

---@param holder integer
local function clearState(holder)
    if GetPlayerName(holder) then Player(holder).state:set(STATE, nil, true) end

end

---@param show IdCardShow
---@param message? string
local function finish(show, message)
    if active[show.token] ~= show then return end

    active[show.token] = nil

    if byOwner[show.owner] == show.token then byOwner[show.owner] = nil end

    if byHolder[show.holder] == show.token then byHolder[show.holder] = nil end

    for target, offer in pairs(offers) do
        if offer.token == show.token then
            offers[target] = nil
            TriggerClientEvent(event('client:offerCancel'), target, show.token)
        end

    end

    for target, token in pairs(incoming) do
        if token == show.token then incoming[target] = nil end

    end

    local key = ('card:%s'):format(show.token)

    for _, entry in pairs(last) do entry[key] = nil end

    clearState(show.holder)
    TriggerClientEvent(event('client:release'), show.holder, show.token)

    if message and online(show.owner) then notify(show.owner, message) end

end

---@param src integer
---@return boolean
function shows.free(src)
    return not byOwner[src] and not byHolder[src] and not offers[src] and not incoming[src]
        and not cards.isBusy(src) and not incapacitated(src)
end

---@param src integer
---@return boolean
local function isDriver(src)
    local ped = GetPlayerPed(src)
    local vehicle = GetVehiclePedIsIn(ped, false)

    return vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == ped
end

---@param src integer
---@return boolean
local function onFoot(src)
    return GetVehiclePedIsIn(GetPlayerPed(src), false) == 0
end

---@param a integer
---@param b integer
---@return integer?
local function windowDriver(a, b)
    if isDriver(a) and onFoot(b) then return a end

    if isDriver(b) and onFoot(a) then return b end

end

---@param src integer
---@param direction vector3
---@param minDot number
---@param footOnly boolean
---@return integer?
local function nearestToward(src, direction, minDot, footOnly)
    local origin = GetEntityCoords(GetPlayerPed(src))
    local bucket = GetPlayerRoutingBucket(src)
    local nearby = lib.getNearbyPlayers(origin, config.tolerance.flash)
    local best, bestDistance

    for i = 1, #nearby do
        local target = nearby[i]
        local offset = target.coords - origin
        local distance = #offset

        if target.id ~= src and distance > 0.1 and GetPlayerRoutingBucket(target.id) == bucket
            and (not footOnly or onFoot(target.id))
            and (offset.x * direction.x + offset.y * direction.y) / distance > minDot
            and (not bestDistance or distance < bestDistance) then
            best, bestDistance = target.id, distance
        end

    end

    return best
end

---@param src integer
---@return integer?
local function viewer(src)
    local heading = math.rad(GetEntityHeading(GetPlayerPed(src)))

    if isDriver(src) then
        return nearestToward(src, vec3(-math.cos(heading), -math.sin(heading), 0.0), 0.3, true)
    end

    return nearestToward(src, vec3(-math.sin(heading), math.cos(heading), 0.0), 0.4, false)
end

local function watch()
    if watching then return end

    watching = true

    CreateThread(function()
        while next(active) do
            Wait(1000)

            for _, show in pairs(active) do
                if not online(show.owner) then
                    finish(show)
                elseif not show.moving then
                    local item = bridge.getSlot(show.owner, show.slot)
                    local lent = show.holder ~= show.owner

                    if not item or item.name ~= show.name or item.metadata.cardId ~= show.cardId then
                        finish(show)
                    elseif lent and not online(show.holder) then
                        finish(show, locale('notify.returned'))
                    elseif lent and not near(show.owner, show.holder, config.tolerance.keep) then
                        notify(show.holder, locale('notify.gave_back'))
                        finish(show, locale('notify.returned'))
                    elseif incapacitated(show.holder) then
                        finish(show, lent and locale('notify.returned') or nil)
                    end

                end

            end

            local now = GetGameTimer()

            for target, offer in pairs(offers) do
                if now > offer.expires + 2000 then offers[target] = nil end

            end

        end

        watching = false
    end)

end

---@param show IdCardShow
---@param target integer
---@return boolean
local function transfer(show, target)
    local item = bridge.getSlot(show.owner, show.slot)
    if not item or item.name ~= show.name or item.metadata.cardId ~= show.cardId then return false end

    if not bridge.canCarry(target, show.name, item.metadata) then return false end

    if not bridge.removeItem(show.owner, show.name, show.slot) then return false end

    if not bridge.addItem(target, show.name, item.metadata) then
        bridge.addItem(show.owner, show.name, item.metadata)

        return false
    end

    local slot = bridge.findSlot(target, show.name, show.cardId)
    if not slot then return false end

    if byOwner[show.owner] == show.token then byOwner[show.owner] = nil end

    notify(show.owner, locale('notify.gave_away', cards.label(show.name)))

    show.owner = target
    show.slot = slot
    byOwner[target] = show.token

    return true
end

---@param show IdCardShow
---@param holder integer
local function moveTo(show, holder)
    local from = show.holder
    local driver = windowDriver(from, holder)

    show.moving = true
    incoming[holder] = show.token
    TriggerClientEvent(event('client:handoff'), from, 'giver', holder, driver and (driver == from and 'driver' or 'other') or nil)
    TriggerClientEvent(event('client:handoff'), holder, 'taker', from, driver and (driver == holder and 'driver' or 'other') or nil)

    SetTimeout(driver and WINDOW_SWAP_MS or GIVE_SWAP_MS, function()
        if incoming[holder] == show.token then incoming[holder] = nil end

        if active[show.token] ~= show then return end

        show.moving = false

        local taken = byHolder[holder] or (holder ~= show.owner and byOwner[holder])

        if taken or not near(from, holder, config.tolerance.handover) then
            return finish(show, locale('notify.interrupted'))
        end

        if shared.handover == 'give' and holder ~= show.owner and not transfer(show, holder) then
            return finish(show, locale('notify.interrupted'))
        end

        if byHolder[from] == show.token then byHolder[from] = nil end

        clearState(from)
        TriggerClientEvent(event('client:release'), from, show.token)

        show.holder = holder
        show.pose = 'hold'
        show.back = false
        byHolder[holder] = show.token

        publish(show)
        TriggerClientEvent(event('client:hold'), holder, show.token, holder == show.owner)
    end)

end

---@param src integer
---@return IdCardShow?
local function heldBy(src)
    local token = byHolder[src]
    local show = token and active[token]
    if show and show.holder == src and not show.moving then return show end

end

---@param src integer
---@param pose string
---@param back boolean
---@return IdCardShow?
local function applyPose(src, pose, back)
    local show = heldBy(src)
    if not show then return end

    if pose == 'flash' and (show.owner ~= src or not (onFoot(src) or isDriver(src))) then return end

    show.pose = pose
    show.back = back
    publish(show)

    return show
end

---@param src integer
---@param name string
---@param slot integer
function shows.use(src, name, slot)
    if not cards.exists(name) or not shows.free(src) then return end

    local item = bridge.getSlot(src, slot)
    if not item or item.name ~= name then return end

    local metadata = item.metadata

    if not metadata.cardId then
        metadata = cards.stamp(src, name, slot)
        if not metadata then return notify(src, locale('notify.issue_failed'), 'error') end

        notify(src, locale('notify.issued', cards.label(name)), 'success')
    end

    local photoId = cards.photoId(metadata, src)
    local current = bridge.getSlot(src, slot)
    if not current or current.name ~= name or current.metadata.cardId ~= metadata.cardId or not shows.free(src) then return end

    local token = lib.string.random('................')

    ---@type IdCardShow
    local show = {
        token = token,
        owner = src,
        holder = src,
        name = name,
        slot = slot,
        cardId = metadata.cardId,
        metadata = metadata,
        photoId = photoId,
        card = cards.payload(name, metadata),
        pose = 'hold',
        back = false,
        moving = false,
    }

    active[token] = show
    byOwner[src] = token
    byHolder[src] = token

    publish(show)
    TriggerClientEvent(event('client:hold'), src, token, true)
    watch()
end

---@param src integer
---@param pose string
---@param back boolean
function shows.pose(src, pose, back)
    if not shows.throttle(src, 'pose', 150) then
        if not queuedPose[src] then
            SetTimeout(160, function()
                local queued = queuedPose[src]
                queuedPose[src] = nil
                if queued then applyPose(src, queued.pose, queued.back) end

            end)

        end

        queuedPose[src] = { pose = pose, back = back }

        return
    end

    queuedPose[src] = nil

    local show = applyPose(src, pose, back)
    if not show or pose ~= 'flash' or not shows.throttle(src, 'flash', shared.flashTime) then return end

    local target = viewer(src)
    if target then TriggerClientEvent(event('client:glance'), target, src, show.token) end

end

---@param src integer
function shows.putAway(src)
    local show = heldBy(src)
    if show and show.owner == src then finish(show) end

end

---@param src integer
---@param target integer
function shows.offer(src, target)
    local show = heldBy(src)
    if not show or target == src or not shared.handover then return end

    if not near(src, target, config.tolerance.give) then
        return notify(src, locale('notify.nobody_close'), 'error')
    end

    local returning = target == show.owner and byOwner[target] == show.token
    local ready = returning and not byHolder[target] and not offers[target] and not incoming[target]
        and not cards.isBusy(target) and not incapacitated(target)

    if not ready and not shows.free(target) then
        return notify(src, locale('notify.busy_target'), 'error')
    end

    offers[target] = { token = show.token, from = src, expires = GetGameTimer() + config.offerTime }
    TriggerClientEvent(event('client:offer'), target, show.token, src, config.offerTime)
    notify(src, locale('notify.holding_out'))
end

---@param src integer
---@param accept boolean
function shows.answer(src, accept)
    local offer = offers[src]
    if not offer then return end

    offers[src] = nil

    local show = active[offer.token]
    if not show or show.holder ~= offer.from or show.moving then return end

    if not accept then return notify(offer.from, locale('notify.refused')) end

    if GetGameTimer() > offer.expires or not near(src, offer.from, config.tolerance.give) or incapacitated(src) then
        return notify(src, locale('notify.too_late'), 'error')
    end

    moveTo(show, src)
end

---@param src integer
function shows.giveBack(src)
    local show = heldBy(src)
    if not show or show.owner == src then return end

    if not near(src, show.owner, config.tolerance.give) then
        return notify(src, locale('notify.get_closer'), 'error')
    end

    if byHolder[show.owner] or offers[show.owner] then
        return notify(src, locale('notify.hands_full'), 'error')
    end

    moveTo(show, show.owner)
end

---@param src integer
---@param token string
---@return { ok: boolean, reason?: string, holder?: integer, card?: table, cardId?: string, photoId?: integer }
function shows.card(src, token)
    local show = active[token]
    if not show then return { ok = false, reason = 'not_found' } end

    if not near(src, show.holder, config.tolerance.view) then return { ok = false, reason = 'too_far' } end

    return { ok = true, holder = show.holder, card = show.card, cardId = show.cardId, photoId = show.photoId }
end

---@param src integer
---@param token string
---@param photoId integer|string
---@return { ok: boolean, reason?: string, photo?: string }
function shows.photo(src, token, photoId)
    local show = active[token]
    if not show or not show.photoId or show.photoId ~= photoId then return { ok = false, reason = 'not_found' } end

    if not near(src, show.holder, config.tolerance.view) then return { ok = false, reason = 'too_far' } end

    local budget = photoBudgets[src]
    local holder = show.holder
    local photo = type(photoId) == 'number' and photos.get(photoId) or cards.legacyPhoto(show.metadata)
    if active[token] ~= show or show.holder ~= holder or photoBudgets[src] ~= budget then return { ok = false, reason = 'not_found' } end

    if not near(src, holder, config.tolerance.view) then return { ok = false, reason = 'too_far' } end

    if not photo then return { ok = false, reason = 'missing' } end

    return { ok = true, photo = photo }
end

---@param token string
---@return boolean
function shows.exists(token)
    return active[token] ~= nil
end

---@param src integer
function shows.drop(src)
    offers[src] = nil
    last[src] = nil
    photoBudgets[src] = nil
    incoming[src] = nil
    queuedPose[src] = nil

    local owned = byOwner[src] and active[byOwner[src]]
    if owned then finish(owned) end

    local held = byHolder[src] and active[byHolder[src]]
    if held then finish(held, locale('notify.returned')) end

end

function shows.clear()
    for _, show in pairs(active) do clearState(show.holder) end

end

return shows
