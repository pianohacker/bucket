-- Copyright (c) Jesse Weaver, 2021
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local anim = require "anim"
local board = require "board"
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
	self.timers = {
		drop = anim.interval:new(dropIntervalForLevel(1))
	}
	self.timers.drop:increment(dropIntervalForLevel(1))

	self.board = board:new {
		width = 8,
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
		graphics.ButtonsRenderer:new(
			function() return self.buttons end
		)
	}

	self.pieceBag = piece.MultiBag:new({
		[piece.PIECE_SETS.TRI] = 2,
		[piece.PIECE_SETS.TET] = 7,
		[piece.PIECE_SETS.PENT] = 1,
	})

	self.keyInputMap = {
		l = 'MOVE_LEFT',
		a = 'MOVE_RIGHT',
		e = 'DROP',
		r = 'ROTATE_LEFT',
		s = 'ROTATE_RIGHT',
	}

	baseScreen.init(self)
end

function gameScreen:layout()
	self.buttons = {
		self:newInputButton(5, -5, 10, 10, 'MOVE_LEFT'),
		self:newInputButton(20, -5, 10, 10, 'MOVE_RIGHT'),
		self:newInputButton(-5, -5, 25, 10, 'DROP'),
		self:newInputButton(-20, -20, 10, 10, 'ROTATE_LEFT'),
		self:newInputButton(-5, -20, 10, 10, 'ROTATE_RIGHT'),
	}
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
			self.timers.drop:reset()
			self.timers.drop:resize(dropIntervalForLevel(self.level))
		end

		local allBlocked = true
		for side = 1, 4 do
			if not self.board:isSideBlocked(side) then
				allBlocked = false
			end
		end

		if allBlocked then
			ui:switchScreen(lossScreen:new(self))
			return
		end

		self.board:startPiece(self.pieceBag:pick())
	end
end

function gameScreen:update(dt)
	baseScreen.update(self, dt)

	if self.timers.drop:firing() then
		self:dropPiece()
	end
end

function gameScreen:input(input)
	if input == 'MOVE_LEFT' then
		self.board:shiftPiece(-1)
	elseif input == 'MOVE_RIGHT' then
		self.board:shiftPiece(1)
	elseif input == 'DROP' then
		self.timers.drop:reset()
		self:dropPiece()
	elseif input == 'ROTATE_LEFT' then
		self.board:rotatePiece(-1)
	elseif input == 'ROTATE_RIGHT' then
		self.board:rotatePiece(1)
	end
end

return gameScreen
