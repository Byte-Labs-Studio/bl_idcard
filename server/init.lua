local config = require 'configs.server'
local bridge = require 'bridge.server'
local photos = require 'server.modules.photos'
local cards = require 'server.modules.cards'
local shows = require 'server.modules.shows'

local resource = cache.resource

CreateThread(function()
    for statement in LoadResourceFile(resource, 'sql/schema.sql'):gmatch('[^;]+') do
        if statement:find('%S') then MySQL.query.await(statement) end

    end

    local hours = (config.photos.cleanup or {}).intervalHours or 0
    if hours <= 0 then return end

    while true do
        Wait(hours * 3600000)

        local removed = photos.collect()
        if removed > 0 then lib.print.info(('removed %d unused photos'):format(removed)) end

    end

end)

bridge.onUse(cards.filter(), shows.use)

AddEventHandler('playerDropped', function()
    shows.drop(source)
    cards.drop(source)
end)

AddEventHandler('onResourceStop', function(name)
    if name == resource then shows.clear() end

end)
