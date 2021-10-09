-- Copyright (c) Jesse Weaver, 2021
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local std = require("std")
local lu = require('luaunit.luaunit')

notion("object:extend makes a descendent object without copying fields", function()
	local o1 = std.object:clone()
	o1.a = 1

	local o2 = o1:extend()
	check(o2.a):is(1)

	o1.a = 2
	check(o2.a):is(2)

	o2.a = 3
	check(o1.a):is(2)
end)

notion("object:extend includes any specified fields", function()
	local o1 = std.object:extend({
		a = 1,
	})
	check(o1.a):is(1)

	local o2 = o1:extend({
		b = 2,
	})
	check(o2.a):is(1)
	check(o2.b):is(2)
end)

notion("object:extend may take a constructor", function()
	local o1 = std.object:extend(function(self)
		self.a = 1
		self.b = self.a + 1
	end)
	check(o1.a):is(1)
	check(o1.b):is(2)
end)

notion("object constructor can call methods", function()
	local o1 = std.object:extend({
		a = function() end,
	})

	o1:extend(function(self)
		self:a()
	end)
end)

notion("object supports a custom __index", function()
	local o1 = std.object:extend({
		__index = function(_, key)
			return key
		end
	})
	check(o1.someRandomKey):is("someRandomKey")
end)

notion("object falls back to normal access if custom access returns nothing", function()
	local o1 = std.object:extend({
		__index = function(_, key)
			if key == 'a' then
				return 1
			end
		end,
		b = 2
	})

	check(o1.a):is(1)
	check(o1.b):is(2)
end)

notion("memoized calls a function once while its key stays the same", function()
	local key = 0
	local timesCalled = 0
	local f = std.memoized(
		function() return key end,
		function()
			timesCalled = timesCalled + 1
		end
	)

	f()
	f()
	check(timesCalled):is(1)
	key = 1
	f()
	check(timesCalled):is(2)
end)

notion("memoized saves the last returned value", function()
	local lastI = 0
	local function i()
		lastI = lastI + 1
		return lastI
	end

	local key = 'first'
	local f = std.memoized(
		function() return key end,
		function()
			return i()
		end
	)

	check(f()):is(1)
	check(f()):is(1)
	key = 'second'
	check(f()):is(2)
end)

notion("memoized can return multiple values", function()
	local f = std.memoized(
		function() return 0 end,
		function()
			return 1, 2
		end
	)

	check(f()):is(1, 2)
	check(f()):is(1, 2)
end)

notion("memoized forwards arguments", function()
	local f = std.memoized(
		function() return 0 end,
		function(a, b)
			return a, b
		end
	)

	check(f(1, 2)):is(1, 2)
	check(f()):is(1, 2)
end)

notion("memoized forwards arguments to key function", function()
	local f = std.memoized(
		function(a, b) return a + b end,
		function(a, b, c)
			return a, b, c
		end
	)

	check(f(1, 2, 3)):is(1, 2, 3)
	check(f(1, 2, 4)):is(1, 2, 3)
	check(f(2, 1, 5)):is(1, 2, 3)
	check(f(1, 1, 6)):is(1, 1, 6)
end)

notion("memoized forwards results of key function to function", function()
	local f = std.memoized(
		function(a, b) return a + b end,
		function(a, b, c, d)
			return a, b, c, d
		end
	)

	check(f(1, 2, 4)):is(1, 2, 4, 3)
	check(f(3, 0, 4)):is(1, 2, 4, 3)
	check(f(6, 1, 5)):is(6, 1, 5, 7)
end)

notion("memoized key function can return multiple values", function()
	local f = std.memoized(
		function(a, b) return a, b end,
		function(a, b, c)
			return a, b, c
		end
	)

	check(f(1, 2, 3)):is(1, 2, 3)
	check(f(1, 2, 4)):is(1, 2, 3)
	check(f(1, 3, 5)):is(1, 3, 5)
end)

notion("memoizedMember calls a function once per object", function()
	local key = 0
	local result = 0

	local base = std.object:extend({
		memoized = std.memoizedMember(
			function() return key end,
			function() return result end
		)
	})

	local o1 = base:extend({o = 1})
	local o2 = base:extend({o = 2})

	check(o1:memoized()):is(0)
	check(o2:memoized()):is(0)

	result = 1
	check(o1:memoized()):is(0)
	check(o2:memoized()):is(0)

	key = 1
	check(o1:memoized()):is(1)
	check(o2:memoized()):is(1)

	key = 2
	result = 2
	check(o1:memoized()):is(2)

	result = 3
	check(o2:memoized()):is(3)
end)

notion("list:fromTable can build a disconnected list from a table", function()
	local reference = std.list:clone()
	reference:insert(4)
	reference:insert(3)
	reference:insert(1)
	reference:insert(2)

	local source = {4, 3, 1, 2}

	lu.assertEquals(std.list:fromTable(source), reference)

	source[4] = nil

	lu.assertEquals(std.list:fromTable({4, 3, 1, 2}), reference)
end)

notion("list:all returns true only if all values truthy", function()
	check(std.list:fromTable({false, true, false}):all()):is(false)
	check(std.list:fromTable({true, true, true}):all()):is(true)
end)

notion("list:reverse reverses the list in place", function()
	local real = std.list:fromTable({1, 2, 3, 4, 5})
	real:reverse()
	lu.assertEquals(real, std.list:fromTable({5, 4, 3, 2, 1}))

	real = std.list:fromTable({1, 2, 3, 4, 5, 6})
	real:reverse()
	lu.assertEquals(real, std.list:fromTable({6, 5, 4, 3, 2, 1}))

	real = std.list:fromTable({})
	real:reverse()
	lu.assertEquals(real, std.list:fromTable({}))
end)

notion("list:insertAll adds elements to a list in place", function()
	local real = std.list:fromTable({1, 2, 3})
	real:insertAll({4, 5})
	lu.assertEquals(real, std.list:fromTable({1, 2, 3, 4, 5}))

	real = std.list:fromTable({1, 2})
	real:insertAll(std.list:fromTable({3, 4, 5}))
	lu.assertEquals(real, std.list:fromTable({1, 2, 3, 4, 5}))
end)

notion("grid starts out cleared", function()
	local g = std.grid:new(7, 5, "default")

	for x = 1,7 do
		for y = 1,5 do
			check(g[x][y]):is("default")
		end
	end
end)

notion("grid:clear resets grid", function()
	local g = std.grid:new(7, 5, "default")
	g[2][3] = "not default"
	g:clear()
	check(g[2][3]):is("default")
end)

notion("grid indexing unchecked without DEBUG_ASSERTS", function()
	DEBUG_ASSERTS = false
	local g = std.grid:new(7, 5, "default")
	_ = g[4][10]
	g[4][10] = 1
	DEBUG_ASSERTS = true
end)

notion("grid indexing checked with DEBUG_ASSERTS", function()
	local g = std.grid:new(7, 5, "default")

	local success, err = pcall(function()
		_ = g[4][10]
	end)
	check(success):is(false)
	check(err):stringContains("attempt to get grid at out-of-bounds (4, 10)")

	success, err = pcall(function()
		g[4][10] = 1
	end)
	check(success):is(false)
	check(err):stringContains("attempt to set grid at out-of-bounds (4, 10)")
end)

notion("grid indexing checked with DEBUG_ASSERTS after clear", function()
	local g = std.grid:new(7, 5, "default")

	local success, err = pcall(function()
		_ = g[4][10]
	end)
	check(success):is(false)
	check(err):stringContains("attempt to get grid at out-of-bounds (4, 10)")
end)

notion("grid column and row accessors work correctly", function()
	local g = std.grid:new(7, 5, 0)

	g[1][2] = 1
	g[1][3] = 1
	g[3][3] = 1
	g[7][4] = 1

	check(g:row(1)):shallowMatches({0,0,0,0,0,0,0})
	check(g:row(2)):shallowMatches({1,0,0,0,0,0,0})
	check(g:row(3)):shallowMatches({1,0,1,0,0,0,0})
	check(g:row(4)):shallowMatches({0,0,0,0,0,0,1})
	check(g:row(5)):shallowMatches({0,0,0,0,0,0,0})

	check(g:col(1)):shallowMatches({0,1,1,0,0})
	check(g:col(2)):shallowMatches({0,0,0,0,0})
	check(g:col(3)):shallowMatches({0,0,1,0,0})
	check(g:col(4)):shallowMatches({0,0,0,0,0})
	check(g:col(5)):shallowMatches({0,0,0,0,0})
	check(g:col(6)):shallowMatches({0,0,0,0,0})
	check(g:col(7)):shallowMatches({0,0,0,1,0})
end)
