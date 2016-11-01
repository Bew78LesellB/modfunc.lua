local packargs = {}

function packargs.pack(...)
	return table.pack(...)
end

--
-- replace table.unpack as it doesn't handle nil values at the end of varargs..
--
-- ex: those 2 are the same with builtin table.unpack:
-- table.unpack(table.pack(1, 2, nil))
-- table.unpack(table.pack(1, 2))
--
function packargs.unpack(pack)
	local nb_args = pack.n

	local function unpack_n(n)
		if n >= nb_args then
			return pack[n]
		end
		return pack[n], unpack_n(n + 1)
	end
	return unpack_n(1)
end

function packargs.unpack_multi(...)
	return packargs.unpack(packargs.concat(...))
end

function packargs.append(pack, data)
	pack.n = pack.n + 1
	pack[pack.n] = data
end

function packargs.append_multi(pack, nb_insert, ...)
	nb_insert = nb_insert > 0 and nb_insert or 0

	for i = 1, nb_insert do
		packargs.append(pack, select(i, ...))
	end
end

function packargs.concat(...)
	local nb_pack = select("#", ...)

	if nb_pack == 0 then
		return nil
	end

	if nb_pack == 1 then
		return select(1, ...)
	end

	local all_pack = packargs.pack()
	for i = 1, nb_pack do
		local current_pack = select(i, ...)
		for arg_no = 1, current_pack.n do
			all_pack.n = all_pack.n + 1
			all_pack[all_pack.n] = current_pack[arg_no]
		end
	end

	return all_pack
end

return packargs
