lick = require "lick"
tove = require "tove"

lick.files = {"board.lua", "main.lua", "piece.lua"}
lick.reset = "true"
lick.debug = "true"

board = require "board"
piece = require "piece"

dropInterval = .5
dropCountup = .5

function love.load()
	board:updateGrid()
	board:clear()

	dropCountup = dropInterval
end

function love.resize()
	board:updateGrid()
end

function love.draw()
	love.graphics.setColor(1, 1, 1)
	board:draw()
end

function dropPiece()
	if not board.piece or not board:dropPiece() then
		board:startPiece(piece.random())
	end
end

function love.update(dt)
	dropCountup = dropCountup + dt

	if dropCountup >= dropInterval then
		dropCountup = 0
		dropPiece()
	end
end
