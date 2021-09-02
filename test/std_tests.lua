-- Copyright (c) Jesse Weaver, 2021
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local std = require("std")
local lu = require('luaunit.luaunit')

notion("list:fromTable can build a disconnected list from a table", function()
	local reference = std.list:new()
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

notion("list:extend adds elements to a list in place", function()
	local real = std.list:fromTable({1, 2, 3})
	real:extend({4, 5})
	lu.assertEquals(real, std.list:fromTable({1, 2, 3, 4, 5}))

	real = std.list:fromTable({1, 2})
	real:extend(std.list:fromTable({3, 4, 5}))
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
