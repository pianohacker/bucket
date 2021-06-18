-- Copyright (c) Jesse Weaver, 2021
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local common = require("test.common")
local lu = require("luaunit.luaunit")

local piece = require("piece")

notion("initial piece bounds are correct", function()
	local p1 = piece.TET.I
	check(p1.left):is(2)
	check(p1.right):is(2)
	check(p1.top):is(1)
	check(p1.bottom):is(4)
	check(p1.xOffset):is(1)
	check(p1.yOffset):is(0)
	check(p1.width):is(1)
	check(p1.height):is(4)

	local p2 = piece.TET.T
	check(p2.left):is(2)
	check(p2.right):is(3)
	check(p2.top):is(1)
	check(p2.bottom):is(3)
	check(p2.xOffset):is(1)
	check(p2.yOffset):is(0)
	check(p2.width):is(2)
	check(p2.height):is(3)
end)

notion("rotation works correctly and updates bounds", function()
	local p1 = piece.TET.I
	p1 = p1:rotate(-1)

	check(common.basicColsRepr(p1)):is(common.dedent [[
		____
		____
		xxxx
		____
	]])
	check(p1.left):is(1)
	check(p1.right):is(4)
	check(p1.top):is(3)
	check(p1.bottom):is(3)

	local p2 = piece.TET.T
	p2 = p2:rotate(-1)

	check(common.basicColsRepr(p2)):is(common.dedent [[
		_x_
		xxx
		___
	]])
	check(p2.left):is(1)
	check(p2.right):is(3)
	check(p2.top):is(1)
	check(p2.bottom):is(2)

	local p3 = piece.TET.L
	p3 = p3:rotate(-1)

	check(common.basicColsRepr(p3)):is(common.dedent [[
		__x
		xxx
		___
	]])
	check(p3.left):is(1)
	check(p3.right):is(3)
	check(p3.top):is(1)
	check(p3.bottom):is(2)

	local p4 = piece.TET.I
	p4 = p4:rotate(1)

	check(common.basicColsRepr(p4)):is(common.dedent [[
		____
		xxxx
		____
		____
	]])
	check(p4.left):is(1)
	check(p4.right):is(4)
	check(p4.top):is(2)
	check(p4.bottom):is(2)

	local p5 = piece.TET.T
	p5 = p5:rotate(1)

	check(common.basicColsRepr(p5)):is(common.dedent [[
		___
		xxx
		_x_
	]])
	check(p5.left):is(1)
	check(p5.right):is(3)
	check(p5.top):is(2)
	check(p5.bottom):is(3)

	local p6 = piece.TET.L
	p6 = p6:rotate(1)

	check(common.basicColsRepr(p6)):is(common.dedent [[
		___
		xxx
		x__
	]])
	check(p6.left):is(1)
	check(p6.right):is(3)
	check(p6.top):is(2)
	check(p6.bottom):is(3)
end)

notion("piece rotation preserves color", function()
	local p = piece.TET.L

	check(p:rotate(1).color):is(p.color)
end)

notion("piece bag with a given size contains that many unique elements", function()
	local source = {}
	for i = 1,1000 do table.insert(source, i) end

	local picked = 400
	local bag = piece.Bag:new(source, picked)

	local seen = {}

	for _ = 1,picked do
		local x = bag:pick()

		if seen[x] then
			error("duplicate element " .. x)
		end

		seen[x] = 1
	end
end)

notion("piece MultiBag contains weighted number of each category", function()
	local bag = piece.MultiBag:new({
		[piece.PIECE_SETS.TRI] = 2,
		[piece.PIECE_SETS.TET] = 6,
		[piece.PIECE_SETS.PENT] = 7,
	})

	local weightTotal = 2 + 6 + 7

	local real = {}
	for _ = 1,1000 do
		local category = bag:pick().category
		real[category] = (real[category] or 0) + 1
	end

	lu.assertAlmostEquals(real.TRI, 2 / weightTotal * 1000, 10)
	lu.assertAlmostEquals(real.TET, 6 / weightTotal * 1000, 10)
	lu.assertAlmostEquals(real.PENT, 7 / weightTotal * 1000, 10)
end)

notion("piece MultiBag exhausts a set before reusing it", function()
	local bag = piece.MultiBag:new({
		[{1,4,7,10,13}] = 4,
		[{2,5,8,11,14}] = 5,
		[{3,6,9,12,15}] = 2,
	})

	local seen = {}
	local numSeen = 0
	while numSeen < 5 do
		local x = bag:pick()

		if x % 3 == 0 then
			if seen[x] then
				error("duplicate element " .. x .. " after " .. numSeen .. " picks")
			else
				seen[x] = 1
				numSeen = numSeen + 1
			end
		end
	end
end)

notion("piece MultiBag can have a weight longer than a set's weight", function()
	local bag = piece.MultiBag:new({
		[{2,5}] = 4,
		[{1,6}] = 6,
	})

	for _ = 1,10 do
		lu.assertNotEquals(bag:pick(), nil)
	end
end)

notion("piece MultiBag can peek at the next piece", function()
	local bag = piece.MultiBag:new({
		[{1,4,7,10,13}] = 4,
		[{2,5,8,11,14}] = 5,
		[{3,6,9,12,15}] = 2,
	})

	local peeked = bag:peek()
	local picked = bag:pick()
	lu.assertEquals(peeked, picked)
end)

notion("piece MultiBag peeking only looks one forward", function()
	local bag = piece.MultiBag:new({
		[{1,4,7,10,13}] = 4,
		[{2,5,8,11,14}] = 5,
		[{3,6,9,12,15}] = 2,
	})

	local firstPeeked = bag:peek()
	local secondPeeked = bag:peek()
	local picked = bag:pick()

	lu.assertEquals(firstPeeked, secondPeeked)
	lu.assertEquals(firstPeeked, picked)
end)
