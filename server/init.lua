local config = require "shared.config"
local callback = lib.callback
local core = Framework.core
local unSavedMugshots = {}

local function decodeBase(mugshot, itemImage)
    local decodeBase64 = require'server.decoder'
    decodeBase64(mugshot, itemImage)
    return itemImage
end

---comment
---@param source number
---@param licenses string | table The key in Config.items
local function createLicense(source, licenses)
    if type(licenses) == 'string' then
        licenses = {licenses}
    end

    local mugshot = callback.await('bl_idcard:cb:getMugShot', source)
    if not mugshot then
        print('Mugshot for license creation not found. Source: ' .. source .. ' | ' .. GetPlayerName(source))
        return
    end

    local player = core.GetPlayer(source)
    local itemImage = decodeBase(mugshot, ('%s_mugshot'):format(player.id))

    unSavedMugshots[itemImage] = mugshot
    local playerCharInfo = player.charinfo
    local charInfo = {
        id = player.id,
        dob = player.dob,
        firstName = playerCharInfo.firstname,
        lastName = playerCharInfo.lastname,
        sex = player.gender,
        imageURL = itemImage
    }

    for _, license in ipairs(licenses) do
        local configType = config.items[license]

        if configType then
            local idType = configType.genderIdType and configType.genderIdType[charInfo.sex] or configType.idType

            charInfo.idType = idType
            player.addItem(license, 1, charInfo)
            return charInfo
        else
            print('License type not found in config: ' .. license)
        end
    end
end
exports('createLicense', createLicense)

lib.addCommand('giveidcard', {
    help = 'Gives an item to a player',
    params = {
        {
            name = 'target',
            type = 'playerId',
            help = 'Target player\'s server id',
        },
        {
            name = 'license',
            type = 'string',
            help = 'License Name: [id_card, driver_license]',
        },
    },
    restricted = not config.Debug and 'group.admin'
}, function(source, args, raw)
    createLicense(args.target, args.license)
end)

CreateThread(function()
    local items = config.items
    for k, v in pairs(items) do
        core.RegisterUsableItem(k, function(source, slotId, metadata)

            local idType = metadata?.idType
            local player
            if not idType then
                player = core.GetPlayer(source)
                player.removeItem(k, 1)
                metadata = createLicense(source, k)
            end

            local target = callback.await('bl_idcard:use', source, k)

            if target and metadata then
                local base64Code = metadata.imageURL
                if base64Code and base64Code:find("data:image/png;base64") then
                    player = player or core.GetPlayer(source)
                    local itemImage = decodeBase(base64Code, ('%s_mugshot'):format(player.id))
                    metadata.imageURL = itemImage
                    unSavedMugshots[itemImage] = base64Code
                    player.setMetaData(slotId, metadata)
                end

                metadata.imageURL = unSavedMugshots[metadata.imageURL] or metadata.imageURL
                TriggerClientEvent('bl_idcard:open', target, metadata)
            end
        end)
    end
end)