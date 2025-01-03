local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local resourcePath = GetResourcePath(cache.resource)
local imagePath = '/web/mugshots'

local function base64Decode(data)
    data = data:gsub('[^'..b..'=]', '')
    return (data:gsub('.', function(x)
        if x == '=' then return '' end
        local r, f = '', (b:find(x) - 1)
        for i = 6, 1, -1 do r = r .. (f % 2^i - f % 2^(i-1) > 0 and '1' or '0') end
        return r
    end):gsub('%d%d%d%d%d%d%d%d', function(x)
        return string.char(tonumber(x, 2))
    end))
end

local function saveBase64AsPng(base64String, imageName)
    local updatedPath = resourcePath:match("resources/.*")
    local base64Data = base64String:gsub("^data:image/png;base64,", "")
    local decodedData = base64Decode(base64Data)
    local file = io.open(('%s/%s/%s.png'):format(updatedPath, imagePath, imageName), "wb")
    if file then
        file:write(decodedData)
        file:close()
        return true
    else
        return false
    end
end

return saveBase64AsPng