local cute = require("cute")
local inspect = require("inspect")

local board = require("board")
local piece = require("piece")

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

	b:startPiece(piece.MINI_J, 3)
	b:setPiece()
	check(common.gridRepr(common.gridReflectY(b.upper_grid))).is(common.dedent [[
		___x________________
		__xx________________
		____________________
	]])

	b:startPiece(piece.Z, 7)
	b:rotatePieceRight()
	b:dropPiece()
	b:dropPiece()
	b:setPiece()
	check(common.gridRepr(common.gridReflectY(b.upper_grid))).is(common.dedent [[
		___x________________
		__xx________________
		______xx____________
	]])
	check(common.gridRepr(b.lower_grid)).is(common.dedent [[
		_____
		_____
		____x
		____x
		_____
	]])
end)

notion("piece movement across edges works correctly", function()
	local b = board:new {width = 5, depth = 4}

	-- Moving left across an edge
	b:startPiece(piece.I, 1)
	b:shiftPiece(-1)
	b:setPiece()
	check(common.gridRepr(common.gridReflectY(b.upper_grid))).is(common.dedent [[
		___________________x
		___________________x
		___________________x
		___________________x
	]])

	-- Moving right across an edge
	b:startPiece(piece.I, 20)
	b:shiftPiece(1)
	b:setPiece()
	check(common.gridRepr(common.gridReflectY(b.upper_grid))).is(common.dedent [[
		x__________________x
		x__________________x
		x__________________x
		x__________________x
	]])

	-- Moving left across an edge after rotation
	b:startPiece(piece.I, 7)
	b:rotatePieceRight()
	b:shiftPiece(-1)
	b:setPiece()
	check(common.gridRepr(common.gridReflectY(b.upper_grid))).is(common.dedent [[
		x__________________x
		xxxxx______________x
		x__________________x
		x__________________x
	]])

	b:startPiece(piece.I, 6)
	check(b:dropPiece()).is(true)
	check(b:dropPiece()).is(true)
	check(b:dropPiece()).is(true)
	check(b:dropPiece()).is(true)
	check(b:dropPiece()).is(true)
	check(b:dropPiece()).is(false)
	b:setPiece()
	check(common.gridRepr(common.gridReflectY(b.upper_grid))).is(common.dedent [[
		x__________________x
		xxxxx______________x
		x__________________x
		x__________________x
	]])
	check(common.gridRepr(b.lower_grid)).is(common.dedent [[
		xxxx_
		_____
		_____
		_____
		_____
	]])
end)

notion("piece movement blocked by collision", function()
	local b = board:new {width = 5, depth = 3}

	b:startPiece(piece.MINI_J, 7)
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

	b:startPiece(piece.MINI_J, 3)
	check(b:dropPiece()).is(true)
	check(b:dropPiece()).is(true)
	check(b:dropPiece()).is(true)
	check(b:dropPiece()).is(false)
	check(b:shiftPiece(1)).is(true)
	check(b:shiftPiece(-1)).is(true)
	check(b:shiftPiece(-1)).is(false)
end)

notion("isSquareFilled works correctly", function()
	local b = board:new {width = 5, depth = 3}

	for _, t in ipairs({2, 7, 12, 17}) do
		b:startPiece(piece.S, t)
		b:dropPiece()

		check(
			b:isSquareFilled(t, 2), b:isSquareFilled(t + 1, 2),
			b:isSquareFilled(t, 1), b:isSquareFilled(t + 1, 1),
			b:isSquareFilled(t, 0), b:isSquareFilled(t + 1, 0)
		).is(
			true, false,
			true, true,
			false, true
		)

		b:setPiece()

		check(
			b:isSquareFilled(t, 2), b:isSquareFilled(t + 1, 2),
			b:isSquareFilled(t, 1), b:isSquareFilled(t + 1, 1),
			b:isSquareFilled(t, 0), b:isSquareFilled(t + 1, 0)
		).is(
			true, false,
			true, true,
			false, true
		)
	end
end)
