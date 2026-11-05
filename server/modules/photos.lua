local config = require 'configs.server'

local photos = {}

local resource = cache.resource
local provider = require(('server.storage.%s'):format(config.photos.provider or 'mysql'))

local MAX_BYTES <const> = 60 * 1024
local MIN_BYTES <const> = 128
local MAX_SIZE <const> = 256
local MAX_LEGACY <const> = 512 * 1024
local HEADER_CHARS <const> = 4096
local CACHE_SIZE <const> = 64
local BASE64 <const> = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

---@type table<integer, string|false>
local stored = {}
---@type integer[]
local order = {}
---@type table<integer, promise>
local loading = {}
---@type table<integer, integer>
local decodeMap = {}

for i = 1, #BASE64 do decodeMap[BASE64:byte(i)] = i - 1 end

---@param id integer
---@param value string|false
local function remember(id, value)
    if stored[id] == nil then
        order[#order + 1] = id

        if #order > CACHE_SIZE then stored[table.remove(order, 1)] = nil end

    end

    stored[id] = value
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

---@param body string
---@return string
local function decode(body)
    local out = {}

    for i = 1, #body - 3, 4 do
        local a, b = decodeMap[body:byte(i)], decodeMap[body:byte(i + 1)]
        local c, d = decodeMap[body:byte(i + 2)], decodeMap[body:byte(i + 3)]
        if not a or not b then break end

        local n = (a << 18) | (b << 12) | ((c or 0) << 6) | (d or 0)

        out[#out + 1] = string.char(n >> 16)

        if c then out[#out + 1] = string.char((n >> 8) & 255) end

        if d then out[#out + 1] = string.char(n & 255) end

    end

    return table.concat(out)
end

---@param s string
---@param i integer
---@return integer
local function u16be(s, i)
    return (s:byte(i) << 8) | s:byte(i + 1)
end

---@param s string
---@param i integer
---@return integer
local function u32be(s, i)
    return (s:byte(i) << 24) | (s:byte(i + 1) << 16) | (s:byte(i + 2) << 8) | s:byte(i + 3)
end

---@param s string
---@param i integer
---@return integer
local function u24le(s, i)
    return s:byte(i) | (s:byte(i + 1) << 8) | (s:byte(i + 2) << 16)
end

---@param s string
---@param i integer
---@return integer
local function u32le(s, i)
    return u24le(s, i) | (s:byte(i + 3) << 24)
end

---@param head string
---@param bytes integer
---@return integer?, integer?
local function webpSize(head, bytes)
    if #head < 30 or head:sub(1, 4) ~= 'RIFF' or head:sub(9, 12) ~= 'WEBP' or u32le(head, 5) + 8 ~= bytes then return end

    local chunk = head:sub(13, 16)

    if chunk == 'VP8X' then return u24le(head, 25) + 1, u24le(head, 28) + 1 end

    if chunk == 'VP8 ' and head:sub(24, 26) == '\157\1\42' then
        return (head:byte(27) | (head:byte(28) << 8)) & 0x3fff, (head:byte(29) | (head:byte(30) << 8)) & 0x3fff
    end

    if chunk == 'VP8L' and head:byte(21) == 0x2f then
        local bits = u32le(head, 22)

        return (bits & 0x3fff) + 1, ((bits >> 14) & 0x3fff) + 1
    end

end

---@param head string
---@return integer?, integer?
local function jpegSize(head)
    if head:sub(1, 3) ~= '\255\216\255' then return end

    local i = 3

    while i + 8 <= #head do
        if head:byte(i) ~= 0xff then return end

        local marker = head:byte(i + 1)

        if marker == 0xc0 or marker == 0xc1 or marker == 0xc2 then return u16be(head, i + 7), u16be(head, i + 5) end

        i = i + 2 + u16be(head, i + 2)
    end

end

---@param head string
---@return integer?, integer?
local function pngSize(head)
    if #head < 24 or head:sub(1, 8) ~= '\137PNG\r\n\26\n' or head:sub(13, 16) ~= 'IHDR' then return end

    return u32be(head, 17), u32be(head, 21)
end

---@param data any
---@param legacy? boolean
---@return { body: string, mime: string, bytes: integer }?
function photos.inspect(data, legacy)
    local limit = legacy and MAX_LEGACY or MAX_BYTES
    if type(data) ~= 'string' or #data > limit * 4 // 3 + 64 then return end

    local body = data:match('^data:image/%a+;base64,([%w%+/]+=?=?)$')
    if not body or #body % 4 ~= 0 then return end

    local padding = body:sub(-2) == '==' and 2 or body:sub(-1) == '=' and 1 or 0
    local bytes = #body // 4 * 3 - padding
    if bytes < MIN_BYTES or bytes > limit then return end

    local head = decode(body:sub(1, HEADER_CHARS))
    local width, height = webpSize(head, bytes)
    local mime = width and 'image/webp'

    if not width then
        width, height = jpegSize(head)
        mime = width and 'image/jpeg'

        if width and decode(body:sub(-4)):sub(-2) ~= '\255\217' then return end

    end

    if not width and legacy then
        width, height = pngSize(head)
        mime = width and 'image/png'
    end

    if not width or width < 1 or height < 1 then return end

    if not legacy and (width > MAX_SIZE or height > MAX_SIZE) then return end

    return { body = body, mime = mime, bytes = bytes }
end

---@param data string
---@return integer?
function photos.store(data)
    local image = photos.inspect(data)
    if not image then return end

    local id = provider.put(image.body, image.mime, image.bytes)
    if id then remember(id, ('data:%s;base64,%s'):format(image.mime, image.body)) end

    return id
end

---@param id any
---@return string?
function photos.get(id)
    id = math.tointeger(tonumber(id))
    if not id or id < 1 then return end

    local cached = stored[id]
    if cached ~= nil then return cached or nil end

    local pending = loading[id]
    if pending then return Citizen.Await(pending) end

    pending = promise.new()
    loading[id] = pending

    local ok, body, mime = pcall(provider.get, id)
    local value = ok and body and mime and ('data:%s;base64,%s'):format(mime, body) or nil

    remember(id, value or false)
    loading[id] = nil
    pending:resolve(value)

    return value
end

---@param citizenid string?
---@return integer?
function photos.current(citizenid)
    if type(citizenid) ~= 'string' or citizenid == '' then return end

    return MySQL.scalar.await('SELECT `photo_id` FROM `bl_idcard_profiles` WHERE `citizenid` = ?', { citizenid })
end

---@param citizenid string
---@param photoId integer
function photos.setCurrent(citizenid, photoId)
    MySQL.insert.await(
        'INSERT INTO `bl_idcard_profiles` (`citizenid`, `photo_id`) VALUES (?, ?) ON DUPLICATE KEY UPDATE `photo_id` = VALUES(`photo_id`)',
        { citizenid, photoId }
    )
end

---@param cardId string
---@return boolean
function photos.cardExists(cardId)
    return MySQL.scalar.await('SELECT 1 FROM `bl_idcard_cards` WHERE `card_id` = ?', { cardId }) ~= nil
end

---@param cardId string
---@param citizenid string?
---@param photoId integer?
---@return boolean
function photos.link(cardId, citizenid, photoId)
    return pcall(MySQL.insert.await,
        'INSERT INTO `bl_idcard_cards` (`card_id`, `citizenid`, `photo_id`) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE `card_id` = `card_id`',
        { cardId, citizenid or '', photoId })
end

---@param cardId string
---@param photoId integer
function photos.fill(cardId, photoId)
    MySQL.update.await('UPDATE `bl_idcard_cards` SET `photo_id` = ? WHERE `card_id` = ? AND `photo_id` IS NULL', { photoId, cardId })
end

---@param cardId string?
---@return integer?, boolean
function photos.forCard(cardId)
    if type(cardId) ~= 'string' or cardId == '' then return nil, false end

    local row = MySQL.single.await('SELECT `photo_id` FROM `bl_idcard_cards` WHERE `card_id` = ?', { cardId })
    if not row then return nil, false end

    return row.photo_id, true
end

---@param imageURL any
---@return string?
function photos.legacy(imageURL)
    if type(imageURL) ~= 'string' or imageURL == '' then return end

    if photos.inspect(imageURL, true) then return imageURL end

    local name = imageURL:match('([%w_%-]+)%.png$') or imageURL:match('^([%w_%-]+)$')
    local handle = name and io.open(('%s/web/mugshots/%s.png'):format(GetResourcePath(resource), name), 'rb')
    if not handle then return end

    local file = handle:read(MAX_LEGACY + 1)
    handle:close()

    if not file or #file > MAX_LEGACY then return end

    local photo = 'data:image/png;base64,' .. encode(file)
    if photos.inspect(photo, true) then return photo end

end

---@return integer
function photos.collect()
    local settings = config.photos.cleanup or {}
    local total = 0

    for _ = 1, 20 do
        local removed = provider.collect(settings.graceMinutes or 60, 500)
        total = total + removed

        if removed < 500 then break end

    end

    local kept = {}

    for i = 1, #order do
        local id = order[i]

        if stored[id] then kept[#kept + 1] = id else stored[id] = nil end

    end

    order = kept

    return total
end

return photos
