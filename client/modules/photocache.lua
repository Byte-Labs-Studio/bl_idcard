local config = require 'configs.client'

local photocache = {}

local PHOTO_EVENT <const> = ('%s:server:photo'):format(cache.resource)
local RETRY_MS <const> = 3000

---@type table<integer, string>
local entries = {}
---@type integer[]
local order = {}
---@type table<integer, promise>
local loading = {}
---@type table<integer, integer>
local failedAt = {}

---@param id integer
local function touch(id)
    for i = #order, 1, -1 do
        if order[i] == id then
            table.remove(order, i)

            break
        end

    end

    order[#order + 1] = id
end

---@param id integer
---@param photo string
local function remember(id, photo)
    entries[id] = photo
    touch(id)

    while #order > math.max(1, config.photoCache or 32) do
        entries[table.remove(order, 1)] = nil
    end

end

---@param id integer
---@return string?
function photocache.peek(id)
    return entries[id]
end

---@param token string
---@param id integer
---@return string?
function photocache.get(token, id)
    local cached = entries[id]

    if cached then
        touch(id)

        return cached
    end

    local pending = loading[id]
    if pending then return Citizen.Await(pending) end

    if failedAt[id] and GetGameTimer() - failedAt[id] < RETRY_MS then return end

    pending = promise.new()
    loading[id] = pending

    local ok, result = pcall(lib.callback.await, PHOTO_EVENT, false, token, id)
    local photo = ok and type(result) == 'table' and result.ok and type(result.photo) == 'string' and result.photo or nil

    if photo then
        failedAt[id] = nil
        remember(id, photo)
    else
        failedAt[id] = GetGameTimer()
    end

    loading[id] = nil
    pending:resolve(photo)

    return photo
end

function photocache.clear()
    entries = {}
    order = {}
    failedAt = {}
end

return photocache
