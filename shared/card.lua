local shared = require 'configs.shared'

local card = {}

local THEME_KEYS <const> = {
    'title', 'titleColour', 'label', 'subtitle', 'agency', 'legal', 'stamp', 'profileStamp', 'signature',
    'bgColour', 'bgColourSecondary', 'textColour',
}

---@param dob any
---@return string
function card.formatDob(dob)
    if type(dob) == 'number' then return os.date('%m/%d/%Y', math.floor(dob > 1e11 and dob / 1000 or dob)) end

    if type(dob) ~= 'string' or dob == '' then return '-' end

    local y, m, d = dob:match('^(%d%d%d%d)%-(%d%d?)%-(%d%d?)')
    if y then return ('%02d/%02d/%s'):format(tonumber(m), tonumber(d), y) end

    return dob:sub(1, 10)
end

---@param gender any
---@return string
function card.formatSex(gender)
    local value = tostring(gender or ''):lower()

    if value == '1' or value == 'f' or value:find('^female') or value:find('^woman') then return 'F' end

    if value == '' then return '-' end

    return 'M'
end

---@param name string
---@param sex string
---@return string?
function card.idTypeFor(name, sex)
    local item = shared.items[name]
    if not item then return end

    local byGender = item.genderIdType

    if byGender then return sex == 'F' and byGender.female or byGender.male end

    return item.idType
end

---@param idType any
---@return string?
function card.itemFor(idType)
    for name, item in pairs(shared.items) do
        local byGender = item.genderIdType

        if item.idType == idType or (byGender and (byGender.female == idType or byGender.male == idType)) then return name end

    end

end

---@param name string?
---@param idType any
---@param sex any
---@return table
local function themeFor(name, idType, sex)
    local _, first = next(shared.idTypes)
    local theme = shared.idTypes[idType] or (name and shared.idTypes[card.idTypeFor(name, card.formatSex(sex))]) or first or {}
    local out = {}

    for i = 1, #THEME_KEYS do out[THEME_KEYS[i]] = theme[THEME_KEYS[i]] end

    return out
end

---@param metadata table
---@return table
function card.normalize(metadata)
    local out = {}

    for key, value in pairs(metadata) do out[key] = value end

    out.id = out.id or out.citizenid
    out.firstName = out.firstName or out.firstname
    out.lastName = out.lastName or out.lastname
    out.dob = out.dob or out.birthdate
    out.sex = out.sex or out.gender

    return out
end

---@param name string?
---@param metadata table
---@return table
function card.payload(name, metadata)
    metadata = card.normalize(metadata)
    name = shared.items[name] and name or card.itemFor(metadata.idType)

    local item = name and shared.items[name] or {}
    local class = metadata.class or item.class
    local details = {}

    if class then details[#details + 1] = { label = 'CLASS', value = class } end

    details[#details + 1] = { label = 'ISSUED', value = metadata.issued }
    details[#details + 1] = { label = 'EXPIRES', value = metadata.expires }

    return {
        theme = themeFor(name, metadata.idType, metadata.sex),
        numberLabel = item.numberLabel or 'ID',
        state = shared.issuer.state,
        country = shared.issuer.country,
        emblem = shared.issuer.emblem,
        number = metadata.cardId or metadata.id,
        citizenid = metadata.id,
        firstname = metadata.firstName,
        lastname = metadata.lastName,
        birthdate = card.formatDob(metadata.dob),
        sex = card.formatSex(metadata.sex),
        nationality = metadata.nationality or shared.issuer.country,
        issued = metadata.issued,
        expires = metadata.expires,
        class = class,
        dd = metadata.dd,
        details = details,
    }
end

return card
