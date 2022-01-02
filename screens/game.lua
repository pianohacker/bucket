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
local pauseScreen = require "screens/pause"

local CLEAR_SCORES = {
	10,
	25,
	40,
	60,
	100,
	150,
}
local LEVEL_ADVANCE_LINES = 5

local function dropIntervalForLevel(level)
	level = math.min(level, 10)

	return .2 + .8 * ((10 - level) / 9) ^ 2
end

local gameScreen = baseScreen:clone()

function gameScreen:new()
	return self:extend(function(o)
		o.timers = {
			drop = anim.interval:new(dropIntervalForLevel(1)),
			flashCleared = anim.sharpInOutTransition:new(.05, .4):asStopped()
		}
		o.timers.drop:increment(dropIntervalForLevel(1))

		o.board = board:new {
			width = 8,
			depth = 10
		}
		o.lost = false
		o.score = 0
		o.clearedLines = 0
		o.level = 1
		o.lastClearedLines = {}

		o.renderers = {
			graphics.BoardRenderer:new(
				o.board,
				function()
					if o.timers.flashCleared:finished() then
						return
					end

					return o.timers.flashCleared:range(0, 1), o.lastClearedLines
				end
			),
			graphics.PieceHintRenderer:new(
				function() return o.pieceBag:peek() end
			),
			graphics.ScoreRenderer:new(
				function() return o.level end,
				function() return o.score end,
				function() return o.clearedLines end
			),
			graphics.ButtonsRenderer:new(
				function() return o:layout().buttons end
			)
		}

		o.pieceBag = piece.MultiBag:new({
			[piece.PIECE_SETS.TRI] = 2,
			[piece.PIECE_SETS.TET] = 7,
			[piece.PIECE_SETS.PENT] = 1,
		})

		o.keyInputMap = {
			l = 'MOVE_LEFT',
			a = 'MOVE_RIGHT',
			e = 'DROP',
			r = 'ROTATE_LEFT',
			s = 'ROTATE_RIGHT',
			escape = 'PAUSE',
		}
	end)
end

gameScreen.layout = std.memoized(
	function() return ui.shape end,
	function(self)
		if not ui.isMobile then
			return { buttons = {} }
		end

		return {
			buttons = {
				self:newInputButton(5, -5, 25, 18, 'DROP', '↓' ),
				self:newInputButton(5, -27, 10, 18, 'ROTATE_LEFT', '↙'),
				self:newInputButton(20, -27, 10, 18, 'ROTATE_RIGHT', '↘'),
				self:newInputSliderButton(-5, -5, 25, 40, 8, 'MOVE_RIGHT', 'MOVE_LEFT'),
			},
		}
	end
)

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
		self:updateScore(#horizCleared, #vertCleared)

		local justClearedLines = #horizCleared + #vertCleared
		self.clearedLines = self.clearedLines + justClearedLines

		if justClearedLines ~= 0 then
			self.lastClearedLines = {horizCleared, vertCleared}
			self.timers.flashCleared:restart()
		end

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
			ui:addScreen(lossScreen:new())
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
	elseif input == 'PAUSE' then
		ui:addScreen(pauseScreen:new())
	end
end

return gameScreen
