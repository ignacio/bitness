local match = {
	x86 = 32,
	x64 = 64
}

local detected_arch = require("bitness")()

if os.getenv("APPVEYOR") then
	local os_arch = os.getenv("PLATFORM")
	assert(match[os_arch] == detected_arch)

elseif os.getenv("TRAVIS") then
	-- travis images are always 64 bits
	assert(match["x64"] == detected_arch)
end
