local photo = {}

local HEADSHOT_TIMEOUT <const> = 4000
local NUI_TIMEOUT <const> = 5000
local MAX_SOURCE <const> = 768 * 1024

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

---@param message table
---@return string?
local function encode(message)
    nextId += 1

    local id = nextId
    local p = promise.new()

    pending[id] = p
    message.action = 'photo'
    message.id = id
    SendNUIMessage(message)

    SetTimeout(NUI_TIMEOUT, function()
        if pending[id] then
            pending[id] = nil
            p:resolve(nil)
        end

    end)

    return Citizen.Await(p)
end

---@param source? string
---@return string?
function photo.capture(source)
    if type(source) == 'string' then
        if #source > MAX_SOURCE or not source:find('^data:image/') then return end

        return encode({ source = source })
    end

    local ped = cache.ped
    local handle = RegisterPedheadshotTransparent(ped)
    if not handle or handle < 0 then handle = RegisterPedheadshot(ped) end

    if not handle or handle < 0 then return end

    if not headshotReady(handle) then
        UnregisterPedheadshot(handle)

        return
    end

    local data = encode({ txd = GetPedheadshotTxdString(handle) })
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
