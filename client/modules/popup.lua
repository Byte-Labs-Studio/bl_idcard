local shared = require 'configs.shared'
local card = require 'shared.card'

local popup = {}

local resource = cache.resource
local MAX_PHOTO <const> = 512 * 1024

local openId = 0

---@param value any
---@return string?
local function photoOf(value)
    if type(value) ~= 'string' or #value > MAX_PHOTO then return end

    if value:find('^data:image/%a+;base64,') or value:find('^https://') then return value end

end

---@param data table
function popup.open(data)
    openId += 1

    local id = openId

    SendNUIMessage({ action = 'popup', card = card.payload(nil, data), photo = photoOf(data.imageURL) })

    local autoclose = shared.popup.autoclose
    if not autoclose or autoclose <= 0 then return end

    SetTimeout(autoclose, function()
        if openId == id then popup.close() end

    end)

end

function popup.close()
    openId += 1
    SendNUIMessage({ action = 'popup', card = false })
end

RegisterCommand('closeidcard', popup.close, false)
RegisterKeyMapping('closeidcard', locale('keybind.close_popup'), 'keyboard', shared.popup.key)

return popup
