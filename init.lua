local _, lib_fullpath = ...

local function lib_require(lib_module)
	local lib_dir = lib_fullpath:match("(.*/)") or "."

	local old_package_path = package.path
	package.path = lib_dir .. "/?.lua"
	local loaded = require(lib_module)
	package.path = old_package_path

	return loaded
end

return lib_require("func")
