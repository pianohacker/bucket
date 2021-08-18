-- Copyright (c) Jesse Weaver, 2021
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local common = require("common")
local lu = require('luaunit.luaunit')

notion("list:fromTable can build a disconnected list from a table", function()
	local reference = common.list:new()
	reference:insert(4)
	reference:insert(3)
	reference:insert(1)
	reference:insert(2)

	local source = {4, 3, 1, 2}

	lu.assertEquals(common.list:fromTable(source), reference)

	source[4] = nil

	lu.assertEquals(common.list:fromTable({4, 3, 1, 2}), reference)
end)

notion("list:all returns true only if all values truthy", function()
	check(common.list:fromTable({false, true, false}):all()):is(false)
	check(common.list:fromTable({true, true, true}):all()):is(true)
end)

notion("list:reverse reverses the list in place", function()
	local real = common.list:fromTable({1, 2, 3, 4, 5})
	real:reverse()
	lu.assertEquals(real, common.list:fromTable({5, 4, 3, 2, 1}))

	real = common.list:fromTable({1, 2, 3, 4, 5, 6})
	real:reverse()
	lu.assertEquals(real, common.list:fromTable({6, 5, 4, 3, 2, 1}))

	real = common.list:fromTable({})
	real:reverse()
	lu.assertEquals(real, common.list:fromTable({}))
end)

notion("list:extend adds elements to a list in place", function()
	local real = common.list:fromTable({1, 2, 3})
	real:extend({4, 5})
	lu.assertEquals(real, common.list:fromTable({1, 2, 3, 4, 5}))

	real = common.list:fromTable({1, 2})
	real:extend(common.list:fromTable({3, 4, 5}))
	lu.assertEquals(real, common.list:fromTable({1, 2, 3, 4, 5}))
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

notion("interval fires at or after given interval and automatically resets", function()
	local i = common.interval:new(.8)
	i:increment(.2)
	check(i:firing()):is(false)
	i:increment(.3)
	check(i:firing()):is(false)
	i:increment(.2)
	check(i:firing()):is(false)
	i:increment(.25)
	check(i:firing()):is(true)

	i:increment(.8)
	check(i:firing()):is(true)
end)

notion("interval can be paused", function()
	-- Incrementing after pause
	local i = common.interval:new(.8)
	i:pause()
	i:increment(.9)
	check(i:firing()):is(false)

	i:start()
	check(i:firing()):is(true)

	-- Incrementing before pause
	i = common.interval:new(.8)
	i:increment(.9)
	i:pause()
	check(i:firing()):is(false)
end)

notion("interval can be stopped and resets when stopped", function()
	local i = common.interval:new(.8)
	i:stop()
	i:increment(.9)
	check(i:firing()):is(false)

	i:start()
	check(i:firing()):is(false)

	i:increment(.8)
	check(i:firing()):is(true)
end)

notion("interval can be reset", function()
	local i = common.interval:new(.8)
	i:increment(.9)

	i:reset()
	check(i:firing()):is(false)

	i:increment(.8)
	check(i:firing()):is(true)
end)

notion("interval can be resized", function()
	local i = common.interval:new(.8)
	i:increment(.7)

	check(i:firing()):is(false)
	i:resize(.6)
	check(i:firing()):is(true)

	i:reset()
	check(i:firing()):is(false)
	i:increment(.9)
	check(i:firing()):is(true)
end)
