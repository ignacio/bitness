local match = {
	x86 = 32,
	x64 = 64
}

local detected_arch = require("bitness")()

print("Detected arch is "..tostring(detected_arch))
print("APPVEYOR?", os.getenv("APPVEYOR"))
print("TRAVIS?", os.getenv("TRAVIS"))
print("PLATFORM?", os.getenv("PLATFORM"))

if os.getenv("APPVEYOR") then
	local os_arch = os.getenv("PLATFORM"):lower()
	assert(match[os_arch] == detected_arch)

elseif os.getenv("TRAVIS") then
	-- travis images are always 64 bits
	assert(match["x64"] == detected_arch)
end
