-- Copyright (c) Jesse Weaver, 2021
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local cute = require("cute")
local inspect = require("inspect")
local lu = require("luaunit.luaunit")

local board = require("board")
local piece = require("piece")

local common = require("test.common")

notion("radialToGrid translates accurately", function()
	local b = board:new {width = 5, depth = 3}

	check(b:radialToGrid(3, 0)):is(3, 1)
	check(b:radialToGrid(5, -2)):is(5, 3)

	check(b:radialToGrid(6, -2)):is(3, 1)
	check(b:radialToGrid(10, -4)):is(1, 5)

	check(b:radialToGrid(12, -2)):is(4, 3)
	check(b:radialToGrid(13, 0)):is(3, 5)

	check(b:radialToGrid(18, -3)):is(4, 3)
	check(b:radialToGrid(20, 0)):is(1, 1)
end)

notion("radialToGrid with fixed side translates correctly at edge", function()
	local b = board:new {width = 5, depth = 3}

	check(b:radialToGrid(20, 0, 4)):is(1, 1)
	check(b:radialToGrid(21, 0, 4)):is(1, 0)
end)

notion("remapPoint translates correctly to all sides", function()
	local b = board:new {width = 5, depth = 3}

	check(b:remapPoint(2, 0, 1)):is(2, 0)
	check(b:remapPoint(2, 0, 2)):is(6, -3)
	check(b:remapPoint(2, 0, 3)):is(14, -4)
	check(b:remapPoint(2, 0, 4)):is(20, -1)

	check(b:remapPoint(12, -4, 1)):is(4, 0)
	check(b:remapPoint(12, -4, 2)):is(6, -1)
	check(b:remapPoint(12, -4, 3)):is(12, -4)
	check(b:remapPoint(12, -4, 4)):is(20, -3)
end)

notion("gridToRadial translates accurately", function()
	local b = board:new {width = 5, depth = 3}

	check(b:gridToRadial(2, 0)):is(2, 1)
	check(b:gridToRadial(4, -1)):is(4, 2)
	check(b:gridToRadial(3, 2)):is(3, -1)
	check(b:gridToRadial(5, 5)):is(5, -4)

	check(b:gridToRadial(6, 2)):is(7, 1)
	check(b:gridToRadial(8, 4)):is(9, 3)

	check(b:gridToRadial(2, 6)):is(14, 1)
	check(b:gridToRadial(4, 8)):is(12, 3)

	check(b:gridToRadial(0, 2)):is(19, 1)
	check(b:gridToRadial(-2, 4)):is(17, 3)
end)

function boardFrom(gridString)
	local upper, lower = common.grid(gridString)

	local b = board:new {width = lower.width, depth = upper.height}
	b.upperGrid = upper
	b.lowerGrid = lower

	return b
end

function checkBoardGridIs(b, gridString)
	gridString = common.dedent(gridString)

	check(
		common.gridRepr(b.upperGrid, b.lowerGrid)
	):errorOffset(1):is(gridString)
end

notion("unobstructed piece movement succeeds", function()
	local b = board:new {width = 5, depth = 3}

	b:startPiece(piece.TRI.J, 3)
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

	b:startPiece(piece.TET.Z, 7)
	check(b:rotatePiece(1)):is(true)
	check(b:dropPiece()):is(true)
	check(b:dropPiece()):is(true)
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

	b:startPiece(piece.TET.T, 18)
	check(b:rotatePiece(-1)):is(true)
	check(b:dropPiece()):is(true)
	check(b:dropPiece()):is(true)
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

notion("pieces move completely across edges", function()
	local b = board:new {width = 5, depth = 4}

	-- Moving left across an edge
	b:startPiece(piece.TET.I, 1)
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
	b:startPiece(piece.TET.I, 20)
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
	b:startPiece(piece.TET.I, 12)
	b:rotatePiece(1)
	b:shiftPiece(-1)
	b:setPiece()
	checkBoardGridIs(b, [[
		    ██▀▀▀▀█
		    ██    █
		█████▀    ▀▀▀▀█
		█           █ █
		█           █ █
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
	b:startPiece(piece.TET.S, 3)
	check(b:dropPiece()):is(true)
	check(b:dropPiece()):is(true)
	check(b:dropPiece()):is(true)
	check(b:dropPiece()):is(false)
	check(b:shiftPiece(1)):is(true)
	check(b:shiftPiece(-1)):is(true)
	check(b:shiftPiece(-1)):is(false)
	check(b:rotatePiece(1)):is(false)
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
	b:startPiece(piece.TET.S, 1)
	check(b:dropPiece()):is(true)
	check(b:rotatePiece(-1)):is(true)
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
	b:startPiece(piece.TET.Z, 4)
	check(b:rotatePiece(1)):is(true)
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
	b:startPiece(piece.TET.I, 10)
	check(b:rotatePiece(1)):is(true)
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

	b:startPiece(piece.TET.I, 3)
	check(b:rotatePiece(-1)):is(false)
	check(b:rotatePiece(1)):is(false)
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

	-- Unsuccessfully rotating at the bottom
	local b = board:new {width = 5, depth = 3}
	b:startPiece(piece.TET.T, 16)
	check(b:rotatePiece(-1)):is(true)
	check(b:dropPiece()):is(true)
	check(b:dropPiece()):is(true)
	check(b:dropPiece()):is(true)
	check(b:dropPiece()):is(true)
	check(b:dropPiece()):is(true)
	check(b:dropPiece()):is(true)
	check(b:dropPiece()):is(false)
	check(b:rotatePiece(-1)):is(false)
	b:setPiece()

	checkBoardGridIs(b, [[
	     █▀▀▀▀▀█
	  ▄▄▄█     █▄▄▄
	  █           █
	  █      ▄█   █
	  █▄▄▄    ▀▄▄▄█
	     █     █
	     ▀▀▀▀▀▀▀
	]])
end)

notion("isGridSquareFilled finds filled squares in bottom and wall from all sides", function()
	local b = board:new {width = 5, depth = 3}

	for _, t in ipairs({2, 7, 12, 17}) do
		b:startPiece(piece.TET.S, t)
		b:dropPiece()
		b:setPiece()

		check(
			b:isGridSquareFilled(t, 2), b:isGridSquareFilled(t + 1, 2),
			b:isGridSquareFilled(t, 1), b:isGridSquareFilled(t + 1, 1),
			b:isGridSquareFilled(t, 0), b:isGridSquareFilled(t + 1, 0)
		):is(
			true, false,
			true, true,
			false, true
		)
	end
end)

notion("clearLines clears and shifts lines in bottom", function()
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

	-- Clearing and shifting in X
	b = boardFrom [[
		   █▀▀▀▀▀█
		▄▄▄█     █▄▄▄
		█   ▄██▄▄   █
		█   ▀▀▀██   █
		█▄▄▄  ▀▀ ▄▄▄█
		   █     █
		   ▀▀▀▀▀▀▀
	]]
	b:clearLines()
	checkBoardGridIs(b, [[
		   █▀▀▀▀▀█
		▄▄▄█     █▄▄▄
		█           █
		█    ▀▀▄▄   █
		█▄▄▄  ▀▀ ▄▄▄█
		   █     █
		   ▀▀▀▀▀▀▀
	]])

	b = boardFrom [[
		   █▀▀▀▀▀█
		▄▄▄█     █▄▄▄
		█   ▀██▀▀   █
		█   ▄▄▄██   █
		█▄▄▄ ▀▀▀ ▄▄▄█
		   █     █
		   ▀▀▀▀▀▀▀
	]]
	b:clearLines()
	checkBoardGridIs(b, [[
		   █▀▀▀▀▀█
		▄▄▄█     █▄▄▄
		█    ▄▄     █
		█    ▄▄█▀   █
		█▄▄▄     ▄▄▄█
		   █     █
		   ▀▀▀▀▀▀▀
	]])

	-- Clearing and shifting in X and Y
	b = boardFrom [[
		   █▀▀▀▀▀█
		▄▄▄█     █▄▄▄
		█   ▀██▀▀   █
		█   ▄█▄██   █
		█▄▄▄ ▀▀▀ ▄▄▄█
		   █     █
		   ▀▀▀▀▀▀▀
	]]
	b:clearLines()
	checkBoardGridIs(b, [[
		   █▀▀▀▀▀█
		▄▄▄█     █▄▄▄
		█     ▄     █
		█     ▄█▀   █
		█▄▄▄     ▄▄▄█
		   █     █
		   ▀▀▀▀▀▀▀
	]])
end)

notion("clearLines clears and shifts squares on walls", function()
	-- Line through west, bottom, and east
	local b = boardFrom [[
		   █▀▀▀▀▀█
		▄▄▄█     █▄▄▄
		█           █
		█▀▀▀▀▀▀▀▀▀▀▀█
		█▄▄▄     ▄▄▄█
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

	-- Line through north, bottom, and south
	local b = boardFrom [[
		   █▀▀█▀▀█
		▄▄▄█  █  █▄▄▄
		█     █     █
		█     █     █
		█▄▄▄  █  ▄▄▄█
		   █  █  █
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

	-- Almost maximum fill
	local b = boardFrom [[
		   ██▀█▀██
		▄▄▄█▄▀▄▀▄█▄▄▄
		█▀▄▀██▄██▄▀▄█
		█▀▄▀▄███▀▄▀▄█
		██▄█▀█▀█▀▄█▄█
		   █▀▄▀▄▀█
		   ▀▀▀▀▀▀▀
	]]
	b:clearLines()
	checkBoardGridIs(b, [[
		   █▀▀▀▀▀█
		▄▄▄█ ▀▀▀ █▄▄▄
		█ ▄ ▄█▀█ ▄  █
		█ ▀▄▀▄█▀▄▀▄ █
		█▄▄▄ ▄▄▄ ▄▄▄█
		   █     █
		   ▀▀▀▀▀▀▀
	]])

	-- Basic simultaneous pattern
	local b = boardFrom [[
		   ██▀▀▀██
		▄▄▄██   ▄█▄▄▄
		█▀ ▀  █  ▀▀▀█
		█   ▀▀█▀▀   █
		████▄ ▀ ▄█▄██
		   █▄   ██
		   ▀▀▀▀▀▀▀
	]]
	b:clearLines()
	checkBoardGridIs(b, [[
		   █▀▀▀▀▀█
		▄▄▄█ █  ▀█▄▄▄
		█ ▄ ▄▀  ▀▄▄▄█
		█           █
		█▄██▀▄  ▄█▄██
		   █ ▄  ██
		   ▀▀▀▀▀▀▀
	]])
end)

notion("clearLines returns the number of lines cleared in each direction", function()
	local b = boardFrom [[
		   █▀▀▀▀▀█
		▄▄▄█     █▄▄▄
		█    █ █    █
		█    ███    █
		█▄▄▄ ▀ ▀ ▄▄▄█
		   █     █
		   ▀▀▀▀▀▀▀
	]]
	check(b:clearLines()):is(0, 2)

	b = boardFrom [[
		   █▀▀▀▀▀█
		▄▄▄█     █▄▄▄
		█   ▄▄▄▄▄   █
		█   ▄██▄▄   █
		█▄▄▄     ▄▄▄█
		   █     █
		   ▀▀▀▀▀▀▀
	]]
	check(b:clearLines()):is(2, 0)

	b = boardFrom [[
		   █▀▀▀▀▀█
		▄▄▄█     █▄▄▄
		█     █     █
		█   ▀▀█▀▀   █
		█▄▄▄  ▀  ▄▄▄█
		   █     █
		   ▀▀▀▀▀▀▀
	]]
	check(b:clearLines()):is(1, 1)
end)

notion("isSideBlocked detects squares anywhere in side", function()
	local b = boardFrom [[
		   █▀▀█▀▀█
		▄▄▄█  █  █▄▄▄
		█     █     █
		█   ▀▀█▀▀   █
		█▄▄▄  █  ▄▄▄█
		   █  █  █
		   ▀▀▀▀▀▀▀
	]]
	check(b:isSideBlocked(1)):is(true)
	check(b:isSideBlocked(2)):is(false)
	check(b:isSideBlocked(3)):is(true)
	check(b:isSideBlocked(4)):is(false)

	b = boardFrom [[
		   █▀▀▀▀▀█
		▄▄▄█     █▄▄▄
		█▀▀▀     ▀▀▀█
		█           █
		████     ████
		   █     █
		   ▀▀▀▀▀▀▀
	]]
	check(b:isSideBlocked(1)):is(false)
	check(b:isSideBlocked(2)):is(true)
	check(b:isSideBlocked(3)):is(false)
	check(b:isSideBlocked(4)):is(true)

	b = boardFrom [[
		   █▀▀▀▀▀█
		▄▄▄█     █▄▄▄
		█           █
		█▀       ▀  █
		█▄▄▄     ▄▄▄█
		   █  ▀  █
		   ▀▀▀▀▀▀▀
	]]
	check(b:isSideBlocked(1)):is(false)
	check(b:isSideBlocked(2)):is(true)
	check(b:isSideBlocked(3)):is(true)
	check(b:isSideBlocked(4)):is(true)
end)

notion("pieces skip blocked sides during movement", function()
	local b = boardFrom [[
		   █▀▀▀▀▀█
		▄▄▄█     █▄▄▄
		█           █
		█  ▀     ▀  █
		█▄▄▄     ▄▄▄█
		   █     █
		   ▀▀▀▀▀▀▀
	]]

	-- Shifting pieces clockwise
	b:startPiece(piece.TET.O, 4)
	b:shiftPiece(1)
	b:setPiece()
	checkBoardGridIs(b, [[
		   █▀▀▀▀▀█
		▄▄▄█     █▄▄▄
		█           █
		█  ▀     ▀  █
		█▄▄▄     ▄▄▄█
		   █   ███
		   ▀▀▀▀▀▀▀
	]])

	-- Shifting pieces counterclockwise
	b = boardFrom [[
		   █▀▀▀▀▀█
		▄▄▄█     █▄▄▄
		█           █
		█  ▀     ▀  █
		█▄▄▄     ▄▄▄█
		   █     █
		   ▀▀▀▀▀▀▀
	]]
	b:startPiece(piece.TET.O, 1)
	b:shiftPiece(-1)
	b:setPiece()
	checkBoardGridIs(b, [[
		   █▀▀▀▀▀█
		▄▄▄█     █▄▄▄
		█           █
		█  ▀     ▀  █
		█▄▄▄     ▄▄▄█
		   ███   █
		   ▀▀▀▀▀▀▀
	]])

	-- Shifting pieces clockwise through two blocked sides
	b = boardFrom [[
		   █▀▀▀▀▀█
		▄▄▄█     █▄▄▄
		█           █
		█        ▀  █
		█▄▄▄  ▄  ▄▄▄█
		   █     █
		   ▀▀▀▀▀▀▀
	]]
	b:startPiece(piece.TET.O, 4)
	b:shiftPiece(1)
	b:setPiece()
	checkBoardGridIs(b, [[
		   █▀▀▀▀▀█
		▄▄▄█     █▄▄▄
		█           █
		█▄▄      ▀  █
		███▄  ▄  ▄▄▄█
		   █     █
		   ▀▀▀▀▀▀▀
	]])

	-- Shifting pieces counterclockwise through two blocked sides
	b = boardFrom [[
		   █▀▀▀▀▀█
		▄▄▄█     █▄▄▄
		█           █
		█        ▀  █
		█▄▄▄  ▄  ▄▄▄█
		   █     █
		   ▀▀▀▀▀▀▀
	]]
	b:startPiece(piece.TET.O, 16)
	b:shiftPiece(-1)
	b:setPiece()
	checkBoardGridIs(b, [[
		   █▀▀▀███
		▄▄▄█   ▀▀█▄▄▄
		█           █
		█        ▀  █
		█▄▄▄  ▄  ▄▄▄█
		   █     █
		   ▀▀▀▀▀▀▀
	]])
end)

notion("pieces never start on blocked sides", function()
	local b = boardFrom [[
		   █▀▀▀▀▀█
		▄▄▄█     █▄▄▄
		█           █
		█  ▀     ▀  █
		█▄▄▄     ▄▄▄█
		   █     █
		   ▀▀▀▀▀▀▀
	]]

	local oldrandom = love.math.random
	local randomOffset = 1
	local randomValues = {6, 18, 3}

	common.withFieldReplaced(
		love.math, 'random', function()
			local val = randomValues[randomOffset]
			randomOffset = (randomOffset % #randomValues) + 1
			return val
		end,
		function()
			b:startPiece(piece.TET.T)
			b:setPiece()
			checkBoardGridIs(b, [[
				   █▀▀█▀▀█
				▄▄▄█  █▀ █▄▄▄
				█           █
				█  ▀     ▀  █
				█▄▄▄     ▄▄▄█
				   █     █
				   ▀▀▀▀▀▀▀
			]])
		end
	)
end)

local function collectIter(f, s, var)
	local testVal = {}
	local vals = {var}

	while true do
		vals = {f(s, vals[1])}
		if vals[1] == nil then break end

		if #vals > 1 then
			table.insert(testVal, vals)
		else
			table.insert(testVal, vals[1])
		end
	end

	return testVal
end

notion("iterPieceSquares returns exactly the squares occupied by a piece", function()
	local b = board:new({ width = 5, depth = 3})

	b:startPiece(piece.TET.T, 3)
	lu.assertItemsEquals(collectIter(b:iterPieceSquares()), {{3, 3}, {3, 2}, {4, 2}, {3, 1}})

	b:dropPiece()
	b:rotatePiece(1)
	lu.assertItemsEquals(collectIter(b:iterPieceSquares()), {{2, 1}, {3, 1}, {4, 1}, {3, 0}})
end)

notion("iterOccupiedSquares returns exactly the squares already occupied", function()
	local b = boardFrom [[
		   █▀▀▀█▀█
		▄▄▄█  ▀▀ █▄▄▄
		██  ▄    ▄  █
		█  ▀█   █▀  █
		█▄▄▄ █   ▄▄▄█
		   █  ▀▀ █
		   ▀▀▀▀▀▀▀
	]]

	lu.assertItemsEquals(
		collectIter(b:iterOccupiedSquares()),
		{
			{1, -1, true},
			{1, -2, true},
			{1, -3, true},
			{2, -4, true},
			{3, 2, true},
			{4, 3, true},
			{4, 2, true},
			{5, -2, true},
			{5, -3, true},
			{7, 1, true},
			{8, 1, true},
			{12, 2, true},
			{13, 2, true},
			{14, 1, true},
			{18, 1, true},
			{19, 3, true},
			{20, 3, true},
		}
	)
end)
