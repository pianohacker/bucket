local common = require("test.common")

local piece = require("piece")

notion("pick calculates bounds correctly", function()
	local p1 = piece.pick(1)
	check(p1.left).is(2)
	check(p1.right).is(2)
	check(p1.top).is(1)
	check(p1.bottom).is(4)

	local p2 = piece.pick(2)
	check(p2.left).is(2)
	check(p2.right).is(3)
	check(p2.top).is(1)
	check(p2.bottom).is(3)
end)

notion("rotateLeft works correctly", function()
	local p1 = piece.pick(1)
	p1 = p1:rotateLeft()

	check(common.gridRepr(p1)).is(common.dedent [[
		____
		____
		xxxx
		____
	]])
	check(p1.left).is(1)
	check(p1.right).is(4)
	check(p1.top).is(3)
	check(p1.bottom).is(3)

	local p2 = piece.pick(2)
	p2 = p2:rotateLeft()

	check(common.gridRepr(p2)).is(common.dedent [[
		_x_
		xxx
		___
	]])
	check(p2.left).is(1)
	check(p2.right).is(3)
	check(p2.top).is(1)
	check(p2.bottom).is(2)

	local p3 = piece.pick(3)
	p3 = p3:rotateLeft()

	check(common.gridRepr(p3)).is(common.dedent [[
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
	local p1 = piece.pick(1)
	p1 = p1:rotateRight()

	check(common.gridRepr(p1)).is(common.dedent [[
		____
		xxxx
		____
		____
	]])
	check(p1.left).is(1)
	check(p1.right).is(4)
	check(p1.top).is(2)
	check(p1.bottom).is(2)

	local p2 = piece.pick(2)
	p2 = p2:rotateRight()

	check(common.gridRepr(p2)).is(common.dedent [[
		___
		xxx
		_x_
	]])
	check(p2.left).is(1)
	check(p2.right).is(3)
	check(p2.top).is(2)
	check(p2.bottom).is(3)

	local p3 = piece.pick(3)
	p3 = p3:rotateRight()

	check(common.gridRepr(p3)).is(common.dedent [[
		___
		xxx
		x__
	]])
	check(p3.left).is(1)
	check(p3.right).is(3)
	check(p3.top).is(2)
	check(p3.bottom).is(3)
end)
