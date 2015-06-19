local cached

local function bitness()
    if cached then return cached end

    local dump = string.dump(function() end)

    local size

    -- check signature
    if dump:sub(2, 4) == "Lua" then
        local version = dump:sub(5,5):byte()

        if version == 0x51 or version == 0x52 then
            size = dump:sub(9,9):byte()
        elseif version == 0x53 then
            size = dump:sub(14,14):byte()
        else
            error("Unknown Lua version (".._VERSION..")")
        end
    elseif dump:sub(2, 3) == "LJ" then
        local ffi = require "ffi"
        size = (ffi.abi("32bit") and 4) or (ffi.abi("64bit") and 8)
    else
        error("Unknown Lua version")
    end

    cached = (size == 4 and 32) or
                (size == 8 and 64) or error("Unknown bitness")

    return cached
end

return bitness
