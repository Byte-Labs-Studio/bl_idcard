local config = require 'configs.server'
local shared = require 'configs.shared'
local card = require 'shared.card'
local bridge = require 'bridge.server'
local photos = require 'server.modules.photos'

local cards = {}

local YEAR <const> = 365 * 24 * 60 * 60
local PHOTO_EVENT <const> = ('%s:client:photo'):format(cache.resource)

---@type table<integer, true>
local locked = {}

---@param value any
---@param fallback string
---@return string
local function text(value, fallback)
    if type(value) ~= 'string' or value == '' then return fallback end

    return value:sub(1, 40)
end

---@param prefix string
---@return string
local function newCardId(prefix)
    for _ = 1, 20 do
        local id = ('%s%07d'):format(prefix, math.random(0, 9999999))
        if not photos.cardExists(id) then return id end

    end

    return ('%s%s'):format(prefix, lib.string.random('11111111'))
end

---@param src integer
---@param source? string
---@return string?
local function capturePhoto(src, source)
    local ok, data = pcall(lib.callback.await, PHOTO_EVENT, src, source)
    if ok and photos.inspect(data) then return data end

end

---@param src integer
---@param citizenid string
---@param retake? boolean
---@return integer?
local function currentPhoto(src, citizenid, retake)
    local photoId = not retake and photos.current(citizenid)
    if photoId then return photoId end

    local data = capturePhoto(src)
    photoId = data and photos.store(data)

    if photoId then
        photos.setCurrent(citizenid, photoId)

        return photoId
    end

    return photos.current(citizenid)
end

---@param src integer
---@param name string
---@return table?
local function character(src, name)
    local player = shared.items[name] and bridge.character(src)
    if not player then return end

    local charinfo = player.charinfo
    local sex = card.formatSex(player.gender or charinfo.gender)

    return {
        id = player.id,
        firstName = text(charinfo.firstname, 'UNKNOWN'),
        lastName = text(charinfo.lastname, 'UNKNOWN'),
        dob = card.formatDob(player.dob or charinfo.birthdate),
        sex = sex == 'F' and 'female' or 'male',
        nationality = text(charinfo.nationality, shared.issuer.country),
        idType = card.idTypeFor(name, sex),
    }
end

---@param name string
---@param metadata table
---@return table
local function finish(name, metadata)
    local item = shared.items[name]
    local issued = os.time()

    metadata.cardId = newCardId(item.prefix or 'X')
    metadata.issued = os.date('%m/%d/%Y', issued)
    metadata.expires = os.date('%m/%d/%Y', issued + (item.years or 5) * YEAR)
    metadata.class = metadata.class or item.class
    metadata.dd = lib.string.random('AAAA1111'):upper()
    metadata.description = ('%s %s'):format(metadata.firstName, metadata.lastName)

    return metadata
end

---@param src integer
---@param name string
---@return table?
local function issue(src, name)
    local base = character(src, name)
    if not base then return end

    local metadata = finish(name, base)
    if not bridge.canCarry(src, name, metadata) then return end

    metadata.photoId = currentPhoto(src, metadata.id, config.photos.retakeOnIssue)

    if not bridge.addItem(src, name, metadata) then return end

    photos.link(metadata.cardId, metadata.id, metadata.photoId)

    return metadata
end

---@param src integer
---@param name string
---@param slot integer
---@return table?
local function blankSlot(src, name, slot)
    local item = bridge.getSlot(src, slot)
    if item and item.name == name and not item.metadata.cardId then return item.metadata end

end

---@param src integer
---@param name string
---@param slot integer
---@return table?
local function stamp(src, name, slot)
    local current = blankSlot(src, name, slot)
    if not current then return end

    local fresh = character(src, name)
    if not fresh then return end

    current = card.normalize(current)

    local legacy = current.firstName ~= nil
    local merged = {}

    for key, value in pairs(current) do merged[key] = value end

    for key, value in pairs(fresh) do
        if merged[key] == nil or not legacy then merged[key] = value end

    end

    finish(name, merged)

    local citizenid = merged.id or fresh.id
    local old = photos.legacy(current.imageURL or current.mugShot)
    local converted = old and capturePhoto(src, old)
    local photoId = converted and photos.store(converted)

    if not photoId then
        photoId = citizenid == fresh.id and currentPhoto(src, citizenid) or photos.current(citizenid)
    elseif not photos.current(citizenid) then
        photos.setCurrent(citizenid, photoId)
    end

    if not blankSlot(src, name, slot) then return end

    merged.photoId = photoId
    merged.imageURL = nil
    merged.mugShot = nil

    if not bridge.setMetadata(src, slot, merged) then return end

    photos.link(merged.cardId, citizenid, photoId)

    return merged
end

---@param src integer
---@return boolean
function cards.isBusy(src)
    return locked[src] == true
end

---@param name string
---@return boolean
function cards.exists(name)
    return shared.items[name] ~= nil
end

---@param name string
---@return string
function cards.label(name)
    return shared.items[name].label or name
end

---@param src integer
---@param name string
---@return table?
function cards.issue(src, name)
    if not shared.items[name] or locked[src] then return end

    locked[src] = true

    local ok, metadata = pcall(issue, src, name)

    locked[src] = nil

    if not ok then lib.print.error(metadata) end

    return ok and metadata or nil
end

---@param src integer
---@param name string
---@param slot integer
---@return table?
function cards.stamp(src, name, slot)
    if locked[src] then return end

    locked[src] = true

    local ok, metadata = pcall(stamp, src, name, slot)

    locked[src] = nil

    if not ok then lib.print.error(metadata) end

    return ok and metadata or nil
end

---@param metadata table
---@return integer?
function cards.photoId(metadata)
    local photoId, known = photos.forCard(metadata.cardId)
    if photoId then return photoId end

    local citizenid = metadata.id or metadata.citizenid

    photoId = photos.current(citizenid)

    if not photoId then return end

    if known then photos.fill(metadata.cardId, photoId) else photos.link(metadata.cardId, citizenid, photoId) end

    return photoId
end

---@param src integer
---@return integer?
function cards.retake(src)
    local player = bridge.character(src)
    if not player or not player.id then return end

    return currentPhoto(src, player.id, true)
end

cards.payload = card.payload

---@return table<string, true>
function cards.filter()
    local filter = {}

    for name in pairs(shared.items) do filter[name] = true end

    return filter
end

---@param src integer
function cards.drop(src)
    locked[src] = nil
end

return cards
