#!/usr/bin/env busted
-- luacheck: std busted

package.path = "../?.lua;" .. package.path
local func = require("func")

local before_infect_metatable = debug.getmetatable(function()end)

require("infect")

describe("infect", function()
	it("change function metatable", function()
		local function_metatable = debug.getmetatable(function()end)

		assert.not_equal(before_infect_metatable, function_metatable)
	end)

	describe("function metatable", function()
		it("has bind", function()
			local mt_bind = describe.bind

			assert.is_function(mt_bind)
			assert.equal(func.bind, mt_bind)
		end)

		it("has partial", function()
			local mt_partial = describe.partial

			assert.is_function(mt_partial)
			assert.equal(func.partial, mt_partial)
		end)
	end)
end)

-- TODO: move thoses functions in a helper function module

local function add(a, b)
	return a + b
end

local function add_multi(acc, b, ...)
	if not b then
		return acc
	end
	return add_multi(acc + b, ...)
end

local function to_str(a, b)
	return tostring(a) .. ":" .. tostring(b)
end

local function to_multi_str(...)
	local nb_args = select("#", ...)
	if nb_args == 0 then
		return ""
	end

	local str = tostring(select(1, ...))
	for i = 2, nb_args do
		str = str .. ":" .. tostring(select(i, ...))
	end
	return str
end


describe("bind", function()

	it("create new function", function()
		local new_func = add:bind("A.", 2)
		assert.is_function(new_func)
	end)

	it("block args on empty format", function()
		local nothing = to_multi_str:bind("")
		assert.equal("", nothing())
		assert.equal("", nothing("useless", "args"))
	end)

	it("single argument", function()
		local add_2 = add:bind("A.", 2)
		assert.equal(5, add_2(3))
		assert.equal(6, add_2(4))
		assert.equal(0, add_2(-2))
		assert.equal(2, add_2(0))
	end)

	describe("discard useless arguments", function()
		it("for bind", function()
			local add_2 = add:bind("A.", 2, "here", "are", 5, "useless", "args")
			assert.equal(10, add_2(8))
		end)

		it("for generated function", function()
			local add_2 = add:bind("A.", 2)
			assert.equal(5, add_2(3, "useless argument"))
		end)
	end)

	it("multiple following argument", function()
		local add_2_3 = add_multi:bind("AA.", 2, 3)
		assert.equal(5, add_2_3(0))
		assert.equal(2, add_2_3(-3))
		assert.equal(3, add_2_3(-2))
	end)

	describe("pending arguments", function()
		it("as first arguments", function()
			local before_bind = to_multi_str:bind("~A", "before-bind")
			assert.equal("1:2:3:before-bind", before_bind(1, 2, 3))
			assert.equal("before-bind", before_bind())
		end)

		it("as last arguments", function()
			local after_bind = to_multi_str:bind("A~", "after-bind")
			assert.equal("after-bind:1:2:3", after_bind(1, 2, 3))
			assert.equal("after-bind", after_bind())
		end)
	end)

	describe("handle nil as last argument", function()
		it("in pending args", function()
			local log = to_str:bind("A~", "[LOG]")
			assert.equal("[LOG]:bla", log("bla"))
		end)

		it("in placeholder", function()
			local append_nil = to_str:bind(".A", nil)
			assert.equal("42:nil", append_nil(42))
		end)

		it("in generated function", function()
			local prepend_nil = to_str:bind(".A", 42)
			assert.equal("nil:42", prepend_nil(nil))
		end)

		it("everywheeere", function()
			local append_nil = to_str:bind(".A", nil)
			assert.equal("nil:nil", append_nil(nil))
		end)
	end)

	it("mixes multiple argument with pending arguments", function()
		local nums = to_multi_str:bind("A..A.A~", "one", "four", "six")
		assert.equal("one:2:3:four:5:six:7:8:9", nums(2, 3, 5, 7, 8, 9))
	end)

end)

describe("partial", function()
	it("create new function", function()
		local new_func = print:partial("bla")
		assert.is_function(new_func)
	end)

	it("return original func on no arg", function()
		local new_func = print:partial()

		assert.equal(print, new_func)
	end)

	it("single arg", function()
		local log = to_multi_str:partial("LOG")
		assert.equal("LOG:string", log("string"))
	end)

	describe("multi args", function()
		it("in placeholder", function()
			local log = to_multi_str:partial("LOG", "LEVEL", "VERBOSE")
			assert.equal("LOG:LEVEL:VERBOSE:string", log("string"))

			local array = {}
			assert.equal("LOG:LEVEL:VERBOSE:" .. tostring(array), log(array))
		end)

		it("in generated function", function()
			local log = to_multi_str:partial("LOG")
			assert.equal("LOG:some:debug:nil:log", log("some", "debug", nil, "log"))
		end)
	end)
end)

