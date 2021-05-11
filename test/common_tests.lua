-- Copyright (c) Jesse Weaver, 2021
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local common = require("common")

notion("list:all returns true only if all values truthy", function()
	check(common.list:from({false, true, false}):all()):is(false)
	check(common.list:from({true, true, true}):all()):is(true)
end)

notion("grid starts out cleared", function()
	local g = common.grid:new(7, 5, "default")

	for x = 1,7 do
		for y = 1,5 do
			check(g[x][y]):is("default")
		end
	end
end)

notion("grid:clear resets grid", function()
	local g = common.grid:new(7, 5, "default")
	g[2][3] = "not default"
	g:clear()
	check(g[2][3]):is("default")
end)

notion("grid indexing unchecked without DEBUG_ASSERTS", function()
	DEBUG_ASSERTS = false
	local g = common.grid:new(7, 5, "default")
	_ = g[4][10]
	g[4][10] = 1
	DEBUG_ASSERTS = true
end)

notion("grid indexing checked with DEBUG_ASSERTS", function()
	local g = common.grid:new(7, 5, "default")

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
	local g = common.grid:new(7, 5, 0)

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
