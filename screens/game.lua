-- Copyright (c) Jesse Weaver, 2021
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local board = require "board"
local common = require "common"
local graphics = require "graphics"
local piece = require "piece"

local baseScreen = require "screens/base"
local lossScreen = require "screens/loss"

local DROP_INTERVAL = .5
local BASE_SCORE = 10

local gameScreen = baseScreen:new()

function gameScreen:init()
	self.dropInterval = common.interval:new(DROP_INTERVAL)
	self.dropInterval:increment(DROP_INTERVAL)

	self.board = board:new {
		width = 10,
		depth = 10
	}
	self.lost = false
	self.score = 0

	self.renderers = {
		graphics.BoardRenderer:new(self.board),
		graphics.PieceHintRenderer:new(
			function() return self.pieceBag:peek() end
		),
		graphics.ScoreRenderer:new(
			function() return self.score end
		),
	}

	self.pieceBag = piece.MultiBag:new({
		[piece.PIECE_SETS.TRI] = 2,
		[piece.PIECE_SETS.TET] = 7,
		[piece.PIECE_SETS.PENT] = 1,
	})
end

function gameScreen:updateScore(horizCleared, vertCleared)
	local horizAndVerticalBonus = 0
	if horizCleared ~= 0 and vertCleared ~= 0 then
		horizAndVerticalBonus = 1
	end

	if horizCleared == 0 and vertCleared == 0 then
		return
	end

	self.score = self.score + BASE_SCORE * 2 ^ (horizCleared + vertCleared + horizAndVerticalBonus - 1)
end

function gameScreen:dropPiece()
	if not self.board.piece then
		self.board:startPiece(self.pieceBag:pick())
	elseif not self.board:dropPiece() then
		self.board:setPiece()
		local horizCleared, vertCleared = self.board:clearLines()
		self:updateScore(horizCleared, vertCleared)

		local allBlocked = true
		for side = 1, 4 do
			if not self.board:isSideBlocked(side) then
				allBlocked = false
			end
		end

		if allBlocked then
			core.switchScreen(lossScreen:new(self))
			return
		end

		self.board:startPiece(self.pieceBag:pick())
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
