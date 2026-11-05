local photo = {}

local HEADSHOT_TIMEOUT <const> = 4000
local NUI_TIMEOUT <const> = 5000

---@type table<integer, promise>
local pending = {}
local nextId = 0

---@param handle integer
---@return boolean
local function headshotReady(handle)
    return pcall(lib.waitFor, function()
        return IsPedheadshotReady(handle) and IsPedheadshotValid(handle) or nil
    end, nil, HEADSHOT_TIMEOUT)

end

---@return string?
function photo.capture()
    local ped = cache.ped
    local handle = RegisterPedheadshotTransparent(ped)
    if not handle or handle < 0 then handle = RegisterPedheadshot(ped) end

    if not handle or handle < 0 then return end

    if not headshotReady(handle) then
        UnregisterPedheadshot(handle)

        return
    end

    nextId += 1
    local id = nextId
    local p = promise.new()
    pending[id] = p

    SendNUIMessage({ action = 'photo', id = id, txd = GetPedheadshotTxdString(handle) })

    SetTimeout(NUI_TIMEOUT, function()
        if pending[id] then
            pending[id] = nil
            p:resolve(nil)
        end

    end)

    local data = Citizen.Await(p)
    UnregisterPedheadshot(handle)

    return data
end

---@param body any
function photo.resolve(body)
    local id = type(body) == 'table' and tonumber(body.id)
    local p = id and pending[id]
    if not p then return end

    pending[id] = nil
    p:resolve(type(body.data) == 'string' and body.data or nil)
end

return photo
