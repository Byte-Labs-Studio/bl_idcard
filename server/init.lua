local config = require "shared.config"
local callback = lib.callback


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

    local core = Framework.core
    local player = core.GetPlayer(source)

    local playerCharInfo = player.charinfo
    local charInfo = {
        id = player.id,
        dob = player.dob,
        firstName = playerCharInfo.firstname,
        lastName = playerCharInfo.lastname,
        sex = player.gender,
        imageURL = mugshot
    }

    for _, license in ipairs(licenses) do
        local configType = config.items[license]

        print(license)

        if configType then
            local idType = nil

            if configType.genderIdType then
                idType = configType.genderIdType[charInfo.sex]
            else
                idType = configType.idType
            end

            charInfo.idType = idType
            player.addItem(license, 1, charInfo)
        else
            print('License type not found in config: ' .. license)
            print(json.encode(licenses, {indent = true}))
        end

    end
end
exports('CreateLicense', createLicense)


CreateThread(function()
    local items = config.items
    for k, v in pairs(items) do
        Framework.core.RegisterUsableItem(k, function(source, slot, metadata)
            local target = callback.await('bl_idcard:use', source, k)

            if target then
                TriggerClientEvent('bl_idcard:open', target, metadata)
            end
        end)
    end
end)