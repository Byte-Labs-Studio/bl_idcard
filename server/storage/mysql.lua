local provider = {}
local legacyTable

local HAS_LEGACY = 'SELECT 1 FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = ? LIMIT 1'
local LEGACY_CARD = 'SELECT `photo` FROM `bl_idcard_photos` WHERE `card_id` = ? LIMIT 1'
local LEGACY_LATEST = 'SELECT `photo` FROM `bl_idcard_photos` WHERE `citizenid` = ? ORDER BY `updated_at` DESC, `id` DESC LIMIT 1'

---@param cardId string?
---@param citizenid string?
---@return string?
function provider.legacy(cardId, citizenid)
    if legacyTable == nil then
        legacyTable = MySQL.scalar.await(HAS_LEGACY, { 'bl_idcard_photos' }) ~= nil
    end

    if not legacyTable then return end

    if cardId then return MySQL.scalar.await(LEGACY_CARD, { cardId }) end

    if citizenid then return MySQL.scalar.await(LEGACY_LATEST, { citizenid }) end

end

---@param body string base64 image bytes
---@param mime string
---@param bytes integer
---@return integer?
function provider.put(body, mime, bytes)
    local id = MySQL.insert.await([[
        INSERT INTO `bl_idcard_photo_store` (`hash`, `mime`, `bytes`, `data`)
        VALUES (UNHEX(SHA2(FROM_BASE64(?), 256)), ?, ?, FROM_BASE64(?))
        ON DUPLICATE KEY UPDATE `id` = LAST_INSERT_ID(`id`), `used_at` = CURRENT_TIMESTAMP
    ]], { body, mime, bytes, body })

    return tonumber(id)
end

---@param id integer
---@return string?, string?
function provider.get(id)
    local row = MySQL.single.await('SELECT `mime`, TO_BASE64(`data`) AS `data` FROM `bl_idcard_photo_store` WHERE `id` = ?', { id })
    if not row or type(row.data) ~= 'string' then return end

    return (row.data:gsub('%s', '')), row.mime
end

---@param id integer
---@return boolean
function provider.exists(id)
    return MySQL.scalar.await('SELECT 1 FROM `bl_idcard_photo_store` WHERE `id` = ?', { id }) ~= nil
end

---@param graceMinutes integer
---@param limit integer
---@return integer
function provider.collect(graceMinutes, limit)
    return MySQL.update.await([[
        DELETE FROM `bl_idcard_photo_store`
        WHERE `used_at` < (CURRENT_TIMESTAMP - INTERVAL ? MINUTE)
          AND NOT EXISTS (SELECT 1 FROM `bl_idcard_cards` c WHERE c.`photo_id` = `bl_idcard_photo_store`.`id`)
          AND NOT EXISTS (SELECT 1 FROM `bl_idcard_profiles` p WHERE p.`photo_id` = `bl_idcard_photo_store`.`id`)
        LIMIT ?
    ]], { graceMinutes, limit }) or 0
end

return provider
