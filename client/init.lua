local utils = require "client.utils"
local events = require "client.events"
local config = require "shared.config"
local callback = lib.callback
local SendNUIEvent in utils
local Send, Receive in events

local currentCardPopup = nil

---@param data IDInfo
local function openCardPopup(data)
    currentCardPopup = data
    SendNUIEvent(Send.cardData, data)
end

local function closeCardPopup()
    if currentCardPopup == nil then return end
    currentCardPopup = nil
    SendNUIEvent(Send.cardData, nil)
end

---@param data IDInfo
RegisterNetEvent('bl_idcard:open', function(data)
    openCardPopup(data)

    local popupConfig = config.popup

    if popupConfig.autoclose then
        SetTimeout(popupConfig.autoclose, function()
            closeCardPopup()
        end)
    end
end)

callback.register('bl_idcard:use', function(itemName)
    local configType = config.items[itemName]
    local ped = cache.ped
    local prop = configType.prop
    if prop then
        local playerCoords = GetEntityCoords(ped)
        local obj = CreateObject(prop, playerCoords.x, playerCoords.y, playerCoords.z + 0.2, true, true, true)
        local bone = GetPedBoneIndex(ped, 57005)
        AttachEntityToEntity(obj, ped, bone, 0.1000, 0.0200, -0.0300, -90.000, 170.000, 78.999, true, true, false, true, 1, true)
        SetModelAsNoLongerNeeded(obj)

        SetTimeout(2500, function()
            DeleteEntity(obj)
            ClearPedTasks(ped)
        end)
    end

    local anim = config.animation
    if anim then
        lib.requestAnimDict(anim.dict)
        TaskPlayAnim(ped, anim.dict, anim.clip, 3.0, -1, -1, 50, -1, false, false, false)
    end

    local target = utils.GetPlayerLookingAt()

    if not target then
        Framework.notify({
            title = "Nobody around",
            description = "Look at who you want to show it to."
        })
        return cache.serverId
    end

    return target
end)

callback.register('bl_idcard:cb:getMugShot', function()
    return utils.GetMugShot()
end)

RegisterCommand('closeidcard', closeCardPopup, false)

RegisterKeyMapping('closeidcard', 'Close ID Card Popup', 'keyboard', config.popup.key)

RegisterNUICallback(Receive.loaded, function(_, cb)
    cb(1)
    SendNUIEvent(Send.config, config.idTypes)
end)