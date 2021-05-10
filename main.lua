-- Copyright (c) Jesse Weaver, 2021
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

cute = require "cute"
lick = require "lick"
tove = require "tove"

lick.files = {"board.lua", "graphics.lua", "main.lua", "piece.lua"}
lick.reset = "true"
lick.debug = "true"

board = require "board"
graphics = require "graphics"
piece = require "piece"

DROP_INTERVAL = .5

game = nil
renderers = nil

function love.load(args)
	cute.go(args)

	love.keyboard.setKeyRepeat(true)

	game = {
		dropCountup = DROP_INTERVAL,
		board = board:new {
			width = 8,
			depth = 6
		}
	}

	renderers = {
		graphics.BoardRenderer:new(game.board)
	}
end

function love.resize()
	for _, renderer in ipairs(renderers) do
		renderer:resize()
	end
end

function love.draw()
	love.graphics.setColor(1, 1, 1)

	for _, renderer in ipairs(renderers) do
		renderer:draw()
	end
end

function dropPiece()
	game.dropCountup = 0

	if not game.board.piece then
		game.board:startPiece(piece.random())
	elseif not game.board:dropPiece() then
		game.board:setPiece()
		game.board:clearLines()
		game.board:startPiece(piece.random())
	end
end

function love.update(dt)
	game.dropCountup = game.dropCountup + dt

	if game.dropCountup >= DROP_INTERVAL then
		dropPiece()
	end
end

function love.keypressed(key)
	if key == 'l' then
		game.board:shiftPiece(-1)
	elseif key == 'a' then
		game.board:shiftPiece(1)
	elseif key == 'e' then
		dropPiece()
	elseif key == 'r' then
		game.board:rotatePiece(-1)
	elseif key == 's' then
		game.board:rotatePiece(1)
	end
end
