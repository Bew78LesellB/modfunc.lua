local packargs = require("packargs")

--
-- placeholder_format string format:
--
-- '.' is a placeholder for futur call
-- 'A' is a given argument
-- '~' is the rest of the varargs
--
-- simple example:
-- ----------------------------------------
-- function myfunc(a, b, c, d)
--   print(a, b, c, d)
-- end
--
-- local newfunc = myfunc:bind("...A", 42)
-- newfunc(1, 2, 3)
-- => prints: "1 2 3 42"
--
-- If you don't know how many argument there is after the last known argument,
-- put '~' in the placeholder_format string
--
-- last varargs with nil example:
-- ----------------------------------------
-- local debug_print = print:bind("A.A~", "DEBUG:", "OTHER")
-- debug_print(1, 2, nil, 4)
-- => prints: "DEBUG: 1 OTHER 2 nil 4"
--
-- implementation details for debug_print :
-- ----------------------------------------
-- -> placeholders == {n = 2, "DEBUG:", "OTHER"}
-- -> ... == 1, 2, nil, 4
-- -> args == {n = 6, "DEBUG:", 1, "OTHER", 2, nil, 4}
--

local func = {}

function func.bind(self, placeholder_format, ...)
	if #placeholder_format == 0 then
		return function()
			return self()
		end
	end

	local placeholders = packargs.pack(...)

	return function(...)
		local args = packargs.pack()
		local arg_idx = 1
		local placeholder_idx = 1

		for c in placeholder_format:gmatch "." do
			if c == 'A' then
				packargs.append(args, placeholders[placeholder_idx])
				placeholder_idx = placeholder_idx + 1
			elseif c == '.' then
				packargs.append(args, select(arg_idx, ...))
				arg_idx = arg_idx + 1
			elseif c == '~' then
				local nb_pending = select("#", select(arg_idx, ...))
				packargs.append_multi(args, nb_pending, select(arg_idx, ...))
			end
		end
		return self(packargs.unpack(args))
	end
end

function func.partial(self, ...)
	if select("#", ...) == 0 then
		return self
	end

	local placeholders = packargs.pack(...)

	return function(...)
		local args = packargs.pack(...)
		return self(packargs.unpack_multi(placeholders, args))
	end
end

return func

