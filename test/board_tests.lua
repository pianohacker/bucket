-- Copyright (c) Jesse Weaver, 2021
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

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

function boardFrom(gridString)
	local upper, lower = common.grid(gridString)

	local b = board:new {width = #lower, depth = #upper[1]}
	b.upper_grid = upper
	b.lower_grid = lower

	return b
end

function checkBoardGridIs(b, gridString)
	gridString = common.dedent(gridString)

	check(
		common.gridRepr(b.upper_grid, b.lower_grid)
	).errorOffset(1).is(gridString)
end

notion("piece movement works correctly", function()
	local b = board:new {width = 5, depth = 3}

	b:startPiece(piece.MINI_J, 3)
	b:setPiece()
	checkBoardGridIs(b, [[
		   █▀▀▀█▀█
		▄▄▄█  ▀▀ █▄▄▄
		█           █
		█           █
		█▄▄▄     ▄▄▄█
		   █     █
		   ▀▀▀▀▀▀▀
	]])

	b:startPiece(piece.Z, 7)
	check(b:rotatePiece(1)).is(true)
	check(b:dropPiece()).is(true)
	check(b:dropPiece()).is(true)
	b:setPiece()
	checkBoardGridIs(b, [[
		   █▀▀▀█▀█
		▄▄▄█  ▀▀ █▄▄▄
		█        ▄  █
		█       █▀  █
		█▄▄▄     ▄▄▄█
		   █     █
		   ▀▀▀▀▀▀▀
	]])

	b:startPiece(piece.T, 18)
	check(b:rotatePiece(-1)).is(true)
	check(b:dropPiece()).is(true)
	check(b:dropPiece()).is(true)
	b:setPiece()
	checkBoardGridIs(b, [[
		   █▀▀▀█▀█
		▄▄▄█  ▀▀ █▄▄▄
		█   ▄    ▄  █
		█  ▀█   █▀  █
		█▄▄▄     ▄▄▄█
		   █     █
		   ▀▀▀▀▀▀▀
	]])
end)

notion("piece movement across edges works correctly", function()
	local b = board:new {width = 5, depth = 4}

	-- Moving left across an edge
	b:startPiece(piece.I, 1)
	b:shiftPiece(-1)
	b:setPiece()
	checkBoardGridIs(b, [[
		    █▀▀▀▀▀█
		    █     █
		█████     ▀▀▀▀█
		█             █
		█             █
		▀▀▀▀█     █▀▀▀▀
		    █     █
		    ▀▀▀▀▀▀▀
	]])

	-- Moving right across an edge
	b:startPiece(piece.I, 20)
	b:shiftPiece(1)
	b:setPiece()
	checkBoardGridIs(b, [[
		    ██▀▀▀▀█
		    ██    █
		█████▀    ▀▀▀▀█
		█             █
		█             █
		▀▀▀▀█     █▀▀▀▀
		    █     █
		    ▀▀▀▀▀▀▀
	]])

	-- Moving left across an edge after rotation
	b:startPiece(piece.I, 7)
	b:rotatePiece(1)
	b:shiftPiece(-1)
	b:setPiece()
	checkBoardGridIs(b, [[
		    ██▀▀▀▀█
		    ██▀▀▀▀█
		█████▀    ▀▀▀▀█
		█             █
		█             █
		▀▀▀▀█     █▀▀▀▀
		    █     █
		    ▀▀▀▀▀▀▀
	]])

	b:startPiece(piece.I, 6)
	check(b:dropPiece()).is(true)
	check(b:dropPiece()).is(true)
	check(b:dropPiece()).is(true)
	check(b:dropPiece()).is(true)
	check(b:dropPiece()).is(true)
	check(b:dropPiece()).is(false)
	b:setPiece()
	checkBoardGridIs(b, [[
		    ██▀▀▀▀█
		    ██▀▀▀▀█
		██████▄▄▄ ▀▀▀▀█
		█             █
		█             █
		▀▀▀▀█     █▀▀▀▀
		    █     █
		    ▀▀▀▀▀▀▀
	]])
end)

notion("piece movement blocked by collision", function()
	local b = boardFrom [[
		   █▀▀▀▀▀█
		▄▄▄█     █▄▄▄
		█    ▄      █
		█    ▀▀     █
		█▄▄▄     ▄▄▄█
		   █     █
		   ▀▀▀▀▀▀▀
	]]

	-- Rotating next to a piece
	b:startPiece(piece.S, 3)
	check(b:dropPiece()).is(true)
	check(b:dropPiece()).is(true)
	check(b:dropPiece()).is(true)
	check(b:dropPiece()).is(false)
	check(b:shiftPiece(1)).is(true)
	check(b:shiftPiece(-1)).is(true)
	check(b:shiftPiece(-1)).is(false)
	check(b:rotatePiece(1)).is(false)
	b:setPiece()
	checkBoardGridIs(b, [[
	     █▀▀▀▀▀█
	  ▄▄▄█     █▄▄▄
	  █    ▄█▄    █
	  █    ▀▀▀    █
	  █▄▄▄     ▄▄▄█
	     █     █
	     ▀▀▀▀▀▀▀
	]])

	-- Rotating next to an edge
	-- Kick to the right
	b = board:new {width = 5, depth = 3}
	b:startPiece(piece.S, 1)
	check(b:dropPiece()).is(true)
	check(b:rotatePiece(-1)).is(true)
	b:setPiece()
	checkBoardGridIs(b, [[
	     █▀▀▀▀▀█
	  ▄▄▄█▄█▀  █▄▄▄
	  █           █
	  █           █
	  █▄▄▄     ▄▄▄█
	     █     █
	     ▀▀▀▀▀▀▀
	]])

	-- Kick to the left
	b:startPiece(piece.Z, 4)
	check(b:rotatePiece(1)).is(true)
	b:setPiece()
	checkBoardGridIs(b, [[
	     █▀▀██▀█
	  ▄▄▄█▄█▀▀▀█▄▄▄
	  █           █
	  █           █
	  █▄▄▄     ▄▄▄█
	     █     █
	     ▀▀▀▀▀▀▀
	]])

	-- Kick two to the left
	b:startPiece(piece.I, 10)
	check(b:rotatePiece(1)).is(true)
	b:setPiece()
	checkBoardGridIs(b, [[
	     █▀▀██▀█
	  ▄▄▄█▄█▀▀▀█▄▄▄
	  █         ▄ █
	  █         █ █
	  █▄▄▄     ▄█▄█
	     █     █
	     ▀▀▀▀▀▀▀
	]])

	-- Unsuccessfully rotating next to an edge
	b = boardFrom [[
	     █▀▀▀▀▀█
	  ▄▄▄███ ███▄▄▄
	  █           █
	  █           █
	  █▄▄▄     ▄▄▄█
	     █     █
	     ▀▀▀▀▀▀▀
	]]

	b:startPiece(piece.I, 3)
	check(b:rotatePiece(-1)).is(false)
	check(b:rotatePiece(1)).is(false)
	b:setPiece()
	checkBoardGridIs(b, [[
	     █▀▀█▀▀█
	  ▄▄▄███████▄▄▄
	  █     ▀     █
	  █           █
	  █▄▄▄     ▄▄▄█
	     █     █
	     ▀▀▀▀▀▀▀
	]])
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

notion("clearLines works correctly", function()
	-- Basic clearing in Y
	local b = boardFrom [[
		   █▀▀▀▀▀█
		▄▄▄█     █▄▄▄
		█    ██     █
		█    ██     █
		█▄▄▄ ▀▀  ▄▄▄█
		   █     █
		   ▀▀▀▀▀▀▀
	]]
	b:clearLines()
	checkBoardGridIs(b, [[
	     █▀▀▀▀▀█
	  ▄▄▄█     █▄▄▄
	  █           █
	  █           █
	  █▄▄▄     ▄▄▄█
	     █     █
	     ▀▀▀▀▀▀▀
	]])

	-- Clearing and shifting in Y
	b = boardFrom [[
		   █▀▀▀▀▀█
		▄▄▄█     █▄▄▄
		█    ███▄   █
		█   ███ ▀   █
		█▄▄▄ ▀▀  ▄▄▄█
		   █     █
		   ▀▀▀▀▀▀▀
	]]
	b:clearLines()
	checkBoardGridIs(b, [[
	     █▀▀▀▀▀█
	  ▄▄▄█     █▄▄▄
	  █      █▄   █
	  █     █ ▀   █
	  █▄▄▄     ▄▄▄█
	     █     █
	     ▀▀▀▀▀▀▀
	]])

	b = boardFrom [[
		   █▀▀▀▀▀█
		▄▄▄█     █▄▄▄
		█   █ ██▄   █
		█   ██ █▀   █
		█▄▄▄▀  ▀ ▄▄▄█
		   █     █
		   ▀▀▀▀▀▀▀
	]]
	b:clearLines()
	checkBoardGridIs(b, [[
	     █▀▀▀▀▀█
	  ▄▄▄█     █▄▄▄
	  █     █▄    █
	  █    █ ▀    █
	  █▄▄▄     ▄▄▄█
	     █     █
	     ▀▀▀▀▀▀▀
	]])
end)
