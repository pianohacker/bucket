local cute = require("cute")
local inspect = require("inspect")

local board = require("board")

local common = require("test.common")

notion("radialToGrid works correctly", function()
	local b = board:new {width = 5, depth = 3}

	check(b:radialToGrid(3, 0)).is(3, 1)
	check(b:radialToGrid(5, -2)).is(5, 3)

	check(b:radialToGrid(6, -2)).is(3, 1)
	check(b:radialToGrid(10, -4)).is(1, 5)

	check(b:radialToGrid(12, -2)).is(4, 3)
	check(b:radialToGrid(13, 0)).is(3, 5)

	check(b:radialToGrid(18, -3)).is(4, 3)
	check(b:radialToGrid(20, 0)).is(1, 1)
end)

notion("radialToGrid with fixed side works correctly at edge", function()
	local b = board:new {width = 5, depth = 3}

	check(b:radialToGrid(20, 0, 4)).is(1, 1)
	check(b:radialToGrid(21, 0, 4)).is(1, 0)
end)

notion("remapPoint works correctly", function()
	local b = board:new {width = 5, depth = 3}

	check(b:remapPoint(2, 0, 1)).is(2, 0)
	check(b:remapPoint(2, 0, 2)).is(6, -3)
	check(b:remapPoint(2, 0, 3)).is(14, -4)
	check(b:remapPoint(2, 0, 4)).is(20, -1)

	check(b:remapPoint(12, -4, 1)).is(4, 0)
	check(b:remapPoint(12, -4, 2)).is(6, -1)
	check(b:remapPoint(12, -4, 3)).is(12, -4)
	check(b:remapPoint(12, -4, 4)).is(20, -3)
end)

notion("piece movement works correctly", function()
	local b = board:new {width = 5, depth = 3}

	b:startPiece(common.grid [[
		_x
		xx
	]], 3)
	b:setPiece()
	check(common.gridRepr(common.gridReflectY(b.upper_grid))).is(common.dedent [[
		___x________________
		__xx________________
		____________________
	]])

	b:startPiece(common.grid [[
		_x
		xx
	]], 7)
	b:dropPiece()
	b:dropPiece()
	b:setPiece()
	check(common.gridRepr(common.gridReflectY(b.upper_grid))).is(common.dedent [[
		___x________________
		__xx________________
		_______x____________
	]])
	check(common.gridRepr(b.lower_grid)).is(common.dedent [[
		_____
		____x
		____x
		_____
		_____
	]])
end)

notion("piece movement blocked by collision", function()
	local b = board:new {width = 5, depth = 3}

	b:startPiece(common.grid [[
		_x
		xx
	]], 7)
	b:dropPiece()
	b:dropPiece()
	b:dropPiece()
	b:dropPiece()
	b:dropPiece()
	b:setPiece()
	check(common.gridRepr(common.gridReflectY(b.upper_grid))).is(common.dedent [[
		____________________
		____________________
		____________________
	]])
	check(common.gridRepr(b.lower_grid)).is(common.dedent [[
		_____
		_x___
		_xx__
		_____
		_____
	]])

	b:startPiece(common.grid [[
		_x
		xx
	]], 3)
	check(b:dropPiece()).is(true)
	check(b:dropPiece()).is(true)
	check(b:dropPiece()).is(true)
	check(b:dropPiece()).is(false)
	check(b:shiftPiece(1)).is(true)
	check(b:shiftPiece(-1)).is(true)
	check(b:shiftPiece(-1)).is(false)
end)
