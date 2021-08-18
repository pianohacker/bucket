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

local CLEAR_SCORES = {
	10,
	25,
	40,
	60,
	100,
	150,
}
local LEVEL_ADVANCE_LINES = 2

local function dropIntervalForLevel(level)
	level = math.min(level, 10)

	return .2 + .3 * ((10 - level) / 9) ^ 2
end

local gameScreen = baseScreen:new()

function gameScreen:init()
	self.dropInterval = common.interval:new(dropIntervalForLevel(1))
	self.dropInterval:increment(dropIntervalForLevel(1))

	self.board = board:new {
		width = 10,
		depth = 10
	}
	self.lost = false
	self.score = 0
	self.clearedLines = 0
	self.level = 1

	self.renderers = {
		graphics.BoardRenderer:new(self.board),
		graphics.PieceHintRenderer:new(
			function() return self.pieceBag:peek() end
		),
		graphics.ScoreRenderer:new(
			function() return self.level end,
			function() return self.score end,
			function() return self.clearedLines end
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

	local cleared = horizCleared + vertCleared + horizAndVerticalBonus
	local clearScore = CLEAR_SCORES[cleared]
	if clearScore == nil then
		clearScore = CLEAR_SCORES[#CLEAR_SCORES] * 2 ^ (cleared - #CLEAR_SCORES)
	end

	self.score = self.score + clearScore
end

function gameScreen:dropPiece()
	if not self.board.piece then
		self.board:startPiece(self.pieceBag:pick())
	elseif not self.board:dropPiece() then
		self.board:setPiece()
		local horizCleared, vertCleared = self.board:clearLines()
		self:updateScore(horizCleared, vertCleared)
		local justClearedLines = horizCleared + vertCleared
		self.clearedLines = self.clearedLines + justClearedLines

		if math.floor((self.clearedLines + justClearedLines) / LEVEL_ADVANCE_LINES) > math.floor(self.clearedLines / LEVEL_ADVANCE_LINES) then
			self.level = self.level + 1
			self.dropInterval:reset()
			self.dropInterval:resize(dropIntervalForLevel(self.level))
		end

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
