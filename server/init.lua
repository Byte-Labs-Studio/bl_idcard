local bridge = require 'bridge.server'
local cards = require 'server.modules.cards'
local shows = require 'server.modules.shows'

local resource = cache.resource

CreateThread(function()
    MySQL.query.await(LoadResourceFile(resource, 'sql/schema.sql'))
end)

bridge.onUse(cards.filter(), shows.use)

AddEventHandler('playerDropped', function()
    shows.drop(source)
    cards.drop(source)
end)

AddEventHandler('onResourceStop', function(name)
    if name == resource then shows.clear() end

end)
