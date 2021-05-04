local common = require("test.common")

local piece = require("piece")

notion("initial piece_bounds are correct", function()
	local p1 = piece.I
	check(p1.left).is(2)
	check(p1.right).is(2)
	check(p1.top).is(1)
	check(p1.bottom).is(4)
	check(p1.xOffset).is(1)
	check(p1.yOffset).is(0)
	check(p1.width).is(1)
	check(p1.height).is(4)

	local p2 = piece.T
	check(p2.left).is(2)
	check(p2.right).is(3)
	check(p2.top).is(1)
	check(p2.bottom).is(3)
	check(p2.xOffset).is(1)
	check(p2.yOffset).is(0)
	check(p2.width).is(2)
	check(p2.height).is(3)
end)

notion("rotateLeft works correctly", function()
	local p1 = piece.I
	p1 = p1:rotateLeft()

	check(common.basicColsRepr(p1)).is(common.dedent [[
		____
		____
		xxxx
		____
	]])
	check(p1.left).is(1)
	check(p1.right).is(4)
	check(p1.top).is(3)
	check(p1.bottom).is(3)

	local p2 = piece.T
	p2 = p2:rotateLeft()

	check(common.basicColsRepr(p2)).is(common.dedent [[
		_x_
		xxx
		___
	]])
	check(p2.left).is(1)
	check(p2.right).is(3)
	check(p2.top).is(1)
	check(p2.bottom).is(2)

	local p3 = piece.L
	p3 = p3:rotateLeft()

	check(common.basicColsRepr(p3)).is(common.dedent [[
		__x
		xxx
		___
	]])
	check(p3.left).is(1)
	check(p3.right).is(3)
	check(p3.top).is(1)
	check(p3.bottom).is(2)
end)

notion("rotateRight works correctly", function()
	local p1 = piece.I
	p1 = p1:rotateRight()

	check(common.basicColsRepr(p1)).is(common.dedent [[
		____
		xxxx
		____
		____
	]])
	check(p1.left).is(1)
	check(p1.right).is(4)
	check(p1.top).is(2)
	check(p1.bottom).is(2)

	local p2 = piece.T
	p2 = p2:rotateRight()

	check(common.basicColsRepr(p2)).is(common.dedent [[
		___
		xxx
		_x_
	]])
	check(p2.left).is(1)
	check(p2.right).is(3)
	check(p2.top).is(2)
	check(p2.bottom).is(3)

	local p3 = piece.L
	p3 = p3:rotateRight()

	check(common.basicColsRepr(p3)).is(common.dedent [[
		___
		xxx
		x__
	]])
	check(p3.left).is(1)
	check(p3.right).is(3)
	check(p3.top).is(2)
	check(p3.bottom).is(3)
end)
