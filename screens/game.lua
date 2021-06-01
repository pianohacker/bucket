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
	self.dropCountup = DROP_INTERVAL
	self.board = board:new {
		width = 8,
		depth = 30
	}

	self.renderers = {
		graphics.BoardRenderer:new(self.board)
	}
end

function gameScreen:dropPiece()
	self.dropCountup = 0

	if not self.board.piece then
		self.board:startPiece(piece.random())
	elseif not self.board:dropPiece() then
		self.board:setPiece()
		self.board:clearLines()
		self.board:startPiece(piece.random())
	end
end

function gameScreen:update(dt)
	self.dropCountup = self.dropCountup + dt

	if self.dropCountup >= DROP_INTERVAL then
		self:dropPiece()
	end
end

function gameScreen:keypressed(key)
	if key == 'l' then
		self.board:shiftPiece(-1)
	elseif key == 'a' then
		self.board:shiftPiece(1)
	elseif key == 'e' then
		self:dropPiece()
	elseif key == 'r' then
		self.board:rotatePiece(-1)
	elseif key == 's' then
		self.board:rotatePiece(1)
	end
end

return gameScreen
