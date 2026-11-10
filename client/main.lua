local visuals = require 'client.modules.visuals'
local holder = require 'client.modules.holder'
local photo = require 'client.modules.photo'
local camera = require 'client.modules.camera'
local popup = require 'client.modules.popup'
local bridge = require 'bridge.client'

local resource = cache.resource
local STATE <const> = ('%s:show'):format(resource)

---@param name string
---@return string
local function event(name)
    return ('%s:%s'):format(resource, name)
end

RegisterNUICallback('cardReady', function(body, cb)
    cb(1)

    local index = type(body) == 'table' and tonumber(body.id)
    if index then visuals.pageReady(index) end

end)

RegisterNUICallback('cardRendered', function(body, cb)
    cb(1)

    local index = type(body) == 'table' and tonumber(body.id)
    if index then visuals.rendered(index) end

end)

RegisterNUICallback('photo', function(body, cb)
    cb(1)
    photo.resolve(body)
end)

RegisterNUICallback('photoReady', function(_, cb)
    photo.markReady()
    cb(1)
end)

lib.callback.register(event('client:photo'), photo.capture)

AddStateBagChangeHandler(STATE, nil, function(bagName, _, value)
    local player = GetPlayerFromStateBagName(bagName)
    if player ~= 0 then visuals.update(GetPlayerServerId(player), value) end

end)

local players = GetActivePlayers()

for i = 1, #players do
    local serverId = GetPlayerServerId(players[i])
    local value = Player(serverId).state[STATE]
    if value then visuals.update(serverId, value) end

end

RegisterNetEvent(event('client:hold'), function(token, own)
    if type(token) == 'string' then holder.start(token, own == true) end

end)

RegisterNetEvent(event('client:release'), function(token)
    holder.release(token)
end)

RegisterNetEvent(event('client:handoff'), function(role, other, side)
    if type(other) == 'number' then holder.handoff(role, other, side) end

end)

RegisterNetEvent(event('client:offer'), function(token, from, time)
    if type(token) == 'string' and type(time) == 'number' then holder.offer(token, from, time) end

end)

RegisterNetEvent(event('client:offerCancel'), function(token)
    holder.cancelOffer(token)
end)

RegisterNetEvent(event('open'), function(data)
    if type(data) == 'table' then popup.open(data) end

end)

RegisterNetEvent(event('client:glance'), function(serverId)
    if type(serverId) == 'number' then holder.glance(serverId) end

end)

bridge.displayMetadata()

RegisterNetEvent('onPlayerDropped', function(serverId)
    visuals.update(serverId, nil)
end)

AddEventHandler('onResourceStop', function(name)
    if name ~= resource then return end

    holder.teardown()
    popup.close()
    camera.stop()
    visuals.stop()
end)
