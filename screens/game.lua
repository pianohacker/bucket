-- Copyright (c) Jesse Weaver, 2021
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local board = lickRequire "board"
local common = lickRequire "common"
local graphics = lickRequire "graphics"
local piece = lickRequire "piece"

local DROP_INTERVAL = .5

local gameScreen = common.object:new()

function gameScreen:init()
	self.dropInterval = common.interval:new(DROP_INTERVAL)
	self.dropInterval:increment(DROP_INTERVAL)

	self.board = board:new {
		width = 8,
		depth = 6
	}
	self.lost = false

	self.renderers = {
		graphics.BoardRenderer:new(self.board),
		-- graphics.LossOverlayRenderer:new(function() return self.lost end),
	}
end

function gameScreen:dropPiece()
	if not self.board.piece then
		self.board:startPiece(piece.random())
	elseif not self.board:dropPiece() then
		self.board:setPiece()
		self.board:clearLines()
		self.board:startPiece(piece.random())
	end
end

function gameScreen:update(dt)
	self.dropInterval:increment(dt)

	if self.dropInterval:firing() then
		self:dropPiece()
	end
end

function gameScreen:keypressed(key)
	if key == 'l' then
		self.board:shiftPiece(-1)
	elseif key == 'a' then
		self.board:shiftPiece(1)
	elseif key == 'e' then
		self.dropInterval:reset()
		self:dropPiece()
	elseif key == 'r' then
		self.board:rotatePiece(-1)
	elseif key == 's' then
		self.board:rotatePiece(1)
	end
end

return gameScreen
