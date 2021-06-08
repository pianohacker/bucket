-- Copyright (c) Jesse Weaver, 2021
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local common = require("test.common")

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
