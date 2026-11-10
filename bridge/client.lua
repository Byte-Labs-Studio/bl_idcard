local bridge = {}

local INVENTORY <const> = exports.bl_bridge:getFramework('inventory')
local BUSY_KEY <const> = (INVENTORY == 'qb-inventory' or INVENTORY == 'ps-inventory') and 'inv_busy' or 'invBusy'

local busy = false

---@param text string
---@param kind? 'error'|'info'|'success'
function bridge.notify(text, kind)
    kind = kind or 'info'

    Framework.notify({ title = locale('notify.title'), description = text, type = kind == 'info' and 'inform' or kind, status = kind })
end

---@param value boolean
function bridge.setBusy(value)
    if value == busy then return end

    if not value and LocalPlayer.state[BUSY_KEY] ~= true then
        busy = false

        return
    end

    if value and LocalPlayer.state[BUSY_KEY] == true then return end

    busy = value
    LocalPlayer.state:set(BUSY_KEY, value, false)
end

function bridge.displayMetadata()
    if INVENTORY ~= 'ox_inventory' then return end

    exports.ox_inventory:displayMetadata({
        firstName = locale('metadata.first_name'),
        lastName = locale('metadata.last_name'),
        dob = locale('metadata.dob'),
        cardId = locale('metadata.number'),
        expires = locale('metadata.expires'),
    })
end

return bridge
