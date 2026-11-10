local core = Framework.core

local bridge = {}

local INVENTORY <const> = exports.bl_bridge:getFramework('inventory')
local TITLE <const> = 'ID'

---@param src integer
---@return table?
local function player(src)
    local ok, result = pcall(core.GetPlayer, src)
    if ok then return result end

end

---@param entry any
---@return { name: string, slot: integer, metadata: table }?
local function normalize(entry)
    if type(entry) ~= 'table' or not entry.name then return end

    local metadata = entry.metadata or entry.info

    return { name = entry.name, slot = tonumber(entry.slot), metadata = type(metadata) == 'table' and metadata or {} }
end

---@param src integer
---@return table
local function items(src)
    local owner = player(src)
    local list = owner and owner.items

    if type(list) == 'function' then list = list() end

    return type(list) == 'table' and list or {}
end

---@param src integer
---@return { charinfo: table, id: string, dob: string?, gender: string? }?
function bridge.character(src)
    local owner = player(src)
    if not owner then return end

    return { charinfo = owner.charinfo or {}, id = owner.id, dob = owner.dob, gender = owner.gender }
end

---@param src integer
---@param slot integer
---@return { name: string, slot: integer, metadata: table }?
function bridge.getSlot(src, slot)
    if INVENTORY == 'ox_inventory' then return normalize(exports.ox_inventory:GetSlot(src, slot)) end

    if INVENTORY == 'qb-inventory' or INVENTORY == 'ps-inventory' then
        local ok, item = pcall(function() return exports[INVENTORY]:GetItemBySlot(src, slot) end)
        if ok then return normalize(item) end

    end

    for _, entry in pairs(items(src)) do
        local item = normalize(entry)
        if item and item.slot == slot then return item end

    end

end

---@param src integer
---@param name string
---@param cardId? string
---@return integer?, table?
function bridge.findSlot(src, name, cardId)
    local first

    for _, entry in pairs(items(src)) do
        local item = normalize(entry)

        if item and item.name == name and item.slot then
            if cardId and item.metadata.cardId == cardId then return item.slot, item.metadata end

            first = first or item
        end

    end

    if first and not cardId then return first.slot, first.metadata end

end

---@param src integer
---@param slot integer
---@param metadata table
---@return boolean
function bridge.setMetadata(src, slot, metadata)
    local owner = player(src)
    if not owner or not owner.setMetaData then return false end

    owner.setMetaData(slot, metadata)

    return true
end

---@param src integer
---@param name string
---@param metadata table
---@return boolean
function bridge.canCarry(src, name, metadata)
    local owner = player(src)
    if not owner or not owner.canCarryItem or INVENTORY == 'codem-inventory' then return owner ~= nil end

    return owner.canCarryItem(name, 1, metadata) and true or false
end

---@param src integer
---@param name string
---@param metadata table
---@return boolean
function bridge.addItem(src, name, metadata)
    local owner = player(src)
    if not owner or not owner.addItem then return false end

    return owner.addItem(name, 1, metadata) and true or false
end

---@param src integer
---@param name string
---@param slot integer
---@return boolean
function bridge.removeItem(src, name, slot)
    local owner = player(src)
    if not owner or not owner.removeItem then return false end

    return owner.removeItem(name, 1, slot) and true or false
end

---@param src integer
---@param text string
---@param kind? 'error'|'info'|'success'
function bridge.notify(src, text, kind)
    kind = kind or 'info'

    Framework.notify(src, { title = TITLE, description = text, type = kind == 'info' and 'inform' or kind, status = kind })
end

---@param src integer
---@return boolean
function bridge.incapacitated(src)
    local state = Player(src).state

    if state.isDead or state.dead or state.isCuffed or state.cuffed or state.handcuffed then return true end

    local ped = GetPlayerPed(src)

    return ped ~= 0 and GetEntityHealth(ped) <= 0
end

---@param names table<string, true>
---@param handler fun(src: integer, name: string, slot: integer)
function bridge.onUse(names, handler)
    for name in pairs(names) do
        core.RegisterUsableItem(name, function(src, slot)
            slot = tonumber(slot) or bridge.findSlot(src, name)
            if not slot then return end

            CreateThread(function()
                handler(src, name, slot)
            end)

        end)

    end

end

return bridge
