local config = require 'configs.server'

local photos = {}

local resource = cache.resource
local MIN_LENGTH <const> = 200
local MAX_LENGTH <const> = 512 * 1024
local CACHE_SIZE <const> = 64
local FIVEMANAGE_URL <const> = 'https://api.fivemanage.com/api/v3/file/base64'
local BASE64 <const> = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

---@type table<string, string|false>
local cache = {}
---@type string[]
local order = {}

---@param cardId string
---@param photo string|false
local function remember(cardId, photo)
    if cache[cardId] == nil then
        order[#order + 1] = cardId

        if #order > CACHE_SIZE then cache[table.remove(order, 1)] = nil end

    end

    cache[cardId] = photo
end

---@param data string
---@return string
local function encode(data)
    local out = {}

    for i = 1, #data, 3 do
        local a, b, c = data:byte(i, i + 2)
        local n = (a << 16) | ((b or 0) << 8) | (c or 0)

        out[#out + 1] = BASE64:sub((n >> 18) + 1, (n >> 18) + 1)
            .. BASE64:sub(((n >> 12) & 63) + 1, ((n >> 12) & 63) + 1)
            .. (b and BASE64:sub(((n >> 6) & 63) + 1, ((n >> 6) & 63) + 1) or '=')
            .. (c and BASE64:sub((n & 63) + 1, (n & 63) + 1) or '=')
    end

    return table.concat(out)
end

---@param data any
---@return boolean
local function isDataUri(data)
    if type(data) ~= 'string' or #data < MIN_LENGTH or #data > MAX_LENGTH then return false end

    local body = data:match('^data:image/webp;base64,(.+)$') or data:match('^data:image/png;base64,(.+)$')
        or data:match('^data:image/jpeg;base64,(.+)$')

    return body ~= nil and body:find('^[%w%+/]+=*$') ~= nil
end

---@param data any
---@return boolean
local function isUrl(data)
    return type(data) == 'string' and #data <= 512 and data:find('^https://[%w%-%.]+/[%w%-%._~/%%]+$') ~= nil
end

---@param data any
---@return boolean
function photos.isValid(data)
    return isDataUri(data) or isUrl(data)
end

---@param photo string
---@param cardId string
---@return string?
local function upload(photo, cardId)
    local key = GetConvar('bl_idcard:fivemanage', '')
    if key == '' then
        lib.print.warn('photos.storage is "fivemanage" but the convar bl_idcard:fivemanage is not set; saving to the database')

        return
    end

    local p = promise.new()

    PerformHttpRequest(FIVEMANAGE_URL, function(status, body)
        local ok, response = pcall(json.decode, body or '')
        local url = ok and type(response) == 'table' and type(response.data) == 'table' and response.data.url

        if status ~= 200 or not isUrl(url) then
            lib.print.warn(('fivemanage upload failed (HTTP %s)'):format(status))
            url = nil
        end

        p:resolve(url)
    end, 'POST', json.encode({
        base64 = photo,
        filename = ('%s.%s'):format(cardId, photo:match('^data:image/(%a+);') or 'png'),
        path = config.photos.fivemanagePath,
    }), { ['Content-Type'] = 'application/json', ['Authorization'] = key })

    return Citizen.Await(p)
end

---@param cardId string
---@return boolean
function photos.exists(cardId)
    if cache[cardId] then return true end

    return MySQL.scalar.await('SELECT 1 FROM `bl_idcard_photos` WHERE `card_id` = ?', { cardId }) ~= nil
end

---@param cardId string
---@param citizenid string
---@param photo string
---@return string?
function photos.save(cardId, citizenid, photo)
    if not photos.isValid(photo) then return end

    if config.photos.storage == 'fivemanage' and isDataUri(photo) then photo = upload(photo, cardId) or photo end

    MySQL.insert.await(
        'INSERT INTO `bl_idcard_photos` (`card_id`, `citizenid`, `photo`) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE `photo` = VALUES(`photo`)',
        { cardId, citizenid, photo }
    )
    remember(cardId, photo)

    return photo
end

---@param cardId string
---@return string?
function photos.get(cardId)
    if type(cardId) ~= 'string' or cardId == '' then return end

    local cached = cache[cardId]
    if cached ~= nil then return cached or nil end

    local photo = MySQL.scalar.await('SELECT `photo` FROM `bl_idcard_photos` WHERE `card_id` = ?', { cardId })
    remember(cardId, type(photo) == 'string' and photo or false)

    return photo
end

---@param citizenid string?
---@return string?
function photos.latest(citizenid)
    if type(citizenid) ~= 'string' or citizenid == '' then return end

    return MySQL.scalar.await('SELECT `photo` FROM `bl_idcard_photos` WHERE `citizenid` = ? ORDER BY `updated_at` DESC LIMIT 1', { citizenid })
end

---@param imageURL any
---@return string?
function photos.legacy(imageURL)
    if type(imageURL) ~= 'string' or imageURL == '' then return end

    if photos.isValid(imageURL) then return imageURL end

    local name = imageURL:match('([%w_%-]+)%.png$') or imageURL:match('^([%w_%-]+)$')
    local handle = name and io.open(('%s/web/mugshots/%s.png'):format(GetResourcePath(resource), name), 'rb')
    if not handle then return end

    local file = handle:read(MAX_LENGTH)
    handle:close()

    if not file or file:sub(2, 4) ~= 'PNG' then return end

    local photo = 'data:image/png;base64,' .. encode(file)
    if isDataUri(photo) then return photo end

end

return photos
