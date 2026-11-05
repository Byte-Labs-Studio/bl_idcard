local cards = require 'server.modules.cards'
local shows = require 'server.modules.shows'
local photos = require 'server.modules.photos'

local resource = cache.resource
local POSES <const> = { hold = true, flash = true, inspect = true }
local TOKEN_LENGTH <const> = 16

---@param name string
---@return string
local function event(name)
    return ('%s:%s'):format(resource, name)
end

RegisterNetEvent(event('server:pose'), function(pose, back)
    local src = source
    if type(pose) ~= 'string' or not POSES[pose] or type(back) ~= 'boolean' then return end

    shows.pose(src, pose, back)
end)

RegisterNetEvent(event('server:putAway'), function()
    local src = source
    if shows.throttle(src, 'putAway', 500) then shows.putAway(src) end

end)

RegisterNetEvent(event('server:offer'), function(target)
    local src = source
    if type(target) ~= 'number' or math.floor(target) ~= target or target <= 0 or target > 65535 then return end

    if shows.throttle(src, 'offer', 1500) then shows.offer(src, target) end

end)

RegisterNetEvent(event('server:answer'), function(accept)
    local src = source
    if type(accept) == 'boolean' then shows.answer(src, accept) end

end)

RegisterNetEvent(event('server:giveBack'), function()
    local src = source
    if shows.throttle(src, 'giveBack', 1500) then shows.giveBack(src) end

end)

lib.callback.register(event('server:card'), function(src, token)
    if type(token) ~= 'string' or #token ~= TOKEN_LENGTH then return { ok = false, reason = 'bad_request' } end

    if not shows.exists(token) then
        if not shows.throttle(src, 'cardMiss', 500) then return { ok = false, reason = 'cooldown' } end

        return { ok = false, reason = 'not_found' }
    end

    if not shows.throttle(src, ('card:%s'):format(token), 2000) then return { ok = false, reason = 'cooldown' } end

    return shows.card(src, token)
end)

lib.callback.register(event('server:photo'), function(src, token, photoId)
    if type(photoId) ~= 'number' or photoId ~= photoId or photoId < 1 or photoId > 4294967295 then return { ok = false, reason = 'bad_request' } end

    photoId = math.tointeger(photoId)
    if type(token) ~= 'string' or #token ~= TOKEN_LENGTH or not photoId or photoId < 1 then return { ok = false, reason = 'bad_request' } end

    if not shows.photoBudget(src) then return { ok = false, reason = 'cooldown' } end

    return shows.photo(src, token, photoId)
end)

exports('updatePhoto', function(src)
    return cards.retake(src)
end)

exports('issueCard', function(src, name)
    return cards.issue(src, name) ~= nil
end)

---@param src integer
---@param licenses string|string[]
---@return table?
local function createLicense(src, licenses)
    local list = type(licenses) == 'table' and licenses or { licenses }
    local first

    for i = 1, #list do
        local name = list[i]

        if cards.exists(name) then
            local metadata = cards.issue(src, name)

            first = first or metadata
        else
            lib.print.warn(('createLicense: %s is not in configs/server.lua items'):format(tostring(name)))
        end

    end

    return first
end

exports('createLicense', createLicense)

lib.addCommand('giveidcard', {
    help = locale('command.issueid'),
    params = {
        { name = 'target', type = 'playerId', help = locale('command.target') },
        { name = 'license', type = 'string', help = locale('command.card'), optional = true },
    },
    restricted = 'group.admin',
}, function(src, args)
    local name = args.license or 'id_card'

    if not cards.exists(name) then
        if src > 0 then shows.notify(src, locale('notify.unknown_card'), 'error') end

        return
    end

    CreateThread(function()
        local ok = cards.issue(args.target, name) ~= nil
        if src > 0 then shows.notify(src, locale(ok and 'notify.card_issued' or 'notify.card_not_issued'), ok and 'success' or 'error') end

    end)

end)

lib.addCommand('idcardphoto', {
    help = locale('command.idcardphoto'),
    params = {
        { name = 'target', type = 'playerId', help = locale('command.target') },
    },
    restricted = 'group.admin',
}, function(src, args)
    CreateThread(function()
        local ok = cards.retake(args.target) ~= nil
        if src > 0 then shows.notify(src, locale(ok and 'notify.photo_updated' or 'notify.photo_failed'), ok and 'success' or 'error') end

    end)

end)

lib.addCommand('idcardcleanup', {
    help = locale('command.idcardcleanup'),
    restricted = 'group.admin',
}, function(src)
    CreateThread(function()
        local removed = photos.collect()
        if src > 0 then shows.notify(src, locale('notify.cleanup_done', removed), 'success') end

        lib.print.info(('removed %d unused photos'):format(removed))
    end)

end)
