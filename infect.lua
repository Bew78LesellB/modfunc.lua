if not debug or not debug.setmetatable then
	return
end

local bind = require("func").bind
local partial = require("func").partial

local function_mt = {
	__index = {
		bind = bind,
		partial = partial,
	},
}

debug.setmetatable(function() end, function_mt)


