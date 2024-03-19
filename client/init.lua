local utils = require "client.utils"
local events = require "client.events"
local config = require "shared.config"
local callback = lib.callback
local SendNUIEvent in utils
local Send, Receive in events

local isCardOpen = false
local cardObject = 0

---@param data IDInfo
local function openCardPopup(data)
    isCardOpen = true
    SendNUIEvent(Send.cardData, data)
end

local function clearPed()
    if DoesEntityExist(cardObject) then
        SetEntityAsMissionEntity(cardObject, true, true)
        DeleteEntity(cardObject)
    end
    ClearPedTasks(cache.ped)
end

local function closeCardPopup()
    isCardOpen = false
    clearPed()
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

RegisterNUICallback(Receive.loaded, function(_, cb)
    cb(1)
    SendNUIEvent(Send.config, config.idTypes)
end)

callback.register('bl_idcard:use', function(itemName)
    if isCardOpen then return end
    local configType = config.items[itemName]
    local ped = cache.ped
    local prop = configType.prop
    if prop then
        local playerCoords = GetEntityCoords(ped)
        cardObject = CreateObject(prop, playerCoords.x, playerCoords.y, playerCoords.z + 0.2, true, true, true)
        local bone = GetPedBoneIndex(ped, 57005)
        AttachEntityToEntity(cardObject, ped, bone, 0.1000, 0.0200, -0.0300, -90.000, 170.000, 78.999, true, true, false, true, 1, true)
        SetModelAsNoLongerNeeded(cardObject)
    end

    local anim = config.animation
    if anim then
        lib.requestAnimDict(anim.dict)
        TaskPlayAnim(ped, anim.dict, anim.clip, 1.0, 1.0, 10000, 63, 0.0, false, false, false)
    end

    SetTimeout(3000, function()
        clearPed()
    end)

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

