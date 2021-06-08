-- Copyright (c) Jesse Weaver, 2021
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

module("graphics", package.seeall)

local common = require("common")
local tove = require("tove")

local function lerp2(a, b, t)
	return b[1] * t + a[1] * (1-t), b[2] * t + a[2] * (1-t)
end

local function getCenterAndSize()
	local SWIDTH, SHEIGHT = love.graphics.getDimensions()
	return SWIDTH/2, SHEIGHT/2, math.min(SWIDTH, SHEIGHT)
end

local B_TOP_RADIUS = 0.4 -- Radius of outside of board as a proportion of the screen.
local B_TOP_CORNERNESS = 0.15 -- Amount that corners are drawn out.
local B_BOTTOM_RADIUS = 0.21 -- Radius of bottom of board as a proportion of the screen.
local B_START_ANGLE = -3/4 * math.pi -- The angle of t=1.
local B_GRID_COLOR = "#181818"
local B_BG_HIGHLIGHT_COLOR = "#111111"
local B_BG_BLOCKED_COLOR = "#331111"
local B_GRID_HIGHLIGHT_COLOR = "#888888"

BoardRenderer = common.object:new()

function BoardRenderer:init(board) 
	self.board = board
	self.lastDrawnPieceGeneration = 0
	self.lastDrawnGridGeneration = 0
end

function BoardRenderer:resize()
	self:updateGrid()
end

function BoardRenderer:updateGrid()
	self.gridGraphics = nil

	-- Scale to window
	local size
	self.center_x, self.center_y, size = getCenterAndSize()

	-- Calculate top of board
	self.upperGridPositions = common.grid:new(self.board.circumf, self.board.depth)
	local top_radius = size * (B_TOP_RADIUS + B_TOP_CORNERNESS)
	local b_cornerness = top_radius * B_TOP_CORNERNESS
	local step = 2 * math.pi / self.board.circumf
	for t=1,self.board.circumf do
		local angle = (t - 1) * step + B_START_ANGLE
		local cornerness = (math.abs(math.sin((t - 1) * math.pi / self.board.width))) * b_cornerness
		self.upperGridPositions[t][self.board.depth] = {
			self.center_x + math.cos(angle) * (top_radius - cornerness),
			self.center_y + math.sin(angle) * (top_radius - cornerness)
		}
	end

	-- Calculate bottom of board
	self.bottom_radius = size * B_BOTTOM_RADIUS

	local t = 1
	-- North
	for x = 1,self.board.width do
		self.upperGridPositions[t][0] = self:bottomGridPoint(x, 1)
		t = t + 1
	end

	-- East
	for y = 1,self.board.width do
		self.upperGridPositions[t][0] = self:bottomGridPoint(self.board.width+1, y)
		t = t + 1
	end

	-- South
	for x = self.board.width+1,2,-1 do
		self.upperGridPositions[t][0] = self:bottomGridPoint(x, self.board.width+1)
		t = t + 1
	end

	-- West
	for y = self.board.width+1,2,-1 do
		self.upperGridPositions[t][0] = self:bottomGridPoint(1, y)
		t = t + 1
	end

	for t = 1, self.board.circumf do
		for r = 1, self.board.depth - 1 do
			self.upperGridPositions[t][r] = {lerp2(
				self.upperGridPositions[t][0],
				self.upperGridPositions[t][self.board.depth],
				r/self.board.depth
			)}
		end
	end
end

function BoardRenderer:bottomGridPoint(x, y)
	return {
		self.center_x + self.bottom_radius * (2 * ((x - 1) / self.board.width) - 1),
		self.center_y + self.bottom_radius * (2 * ((y - 1) / self.board.width) - 1),
	}
end

function BoardRenderer:gridPoint(t, r, side)
	side = side or self.board:side(t)

	-- Coordinates on the sides of the bucket are easy.
	if r > 0 then
		t = self.board:normalizeT(t)
		return self.upperGridPositions[t][r]
	end

	local x, y = self.board:radialToGrid(t, r, side)

	if side == 1 then
		-- North
	elseif side == 2 then
		-- East
		x = x + 1
	elseif side == 3 then
		-- South
		x = x + 1
		y = y + 1
	else
		-- West
		y = y + 1
	end

	return self:bottomGridPoint(x, y)
end

function BoardRenderer:drawSquare(t, r, graphics)
	local side = self.board:side(t)

	graphics:moveTo(unpack(self:gridPoint(t, r, side)))
	graphics:lineTo(unpack(self:gridPoint(t+1, r, side)))
	graphics:lineTo(unpack(self:gridPoint(t+1, r-1, side)))
	graphics:lineTo(unpack(self:gridPoint(t, r-1, side)))
end

function BoardRenderer:drawSide(side)
	self.backgroundGraphics:moveTo(unpack(self:gridPoint(side * self.board.width + 1, 0, side)))
	self.backgroundGraphics:lineTo(unpack(self:gridPoint((side - 1) * self.board.width + 1, 0, side)))

	for t = (side - 1) * self.board.width + 1, side * self.board.width + 1 do
		self.backgroundGraphics:lineTo(unpack(self:gridPoint(t, self.board.depth, side)))
	end
end

function BoardRenderer:updateBackgroundGraphics()
	self.backgroundGraphics = tove.newGraphics()
	self.backgroundGraphics:setDisplay('mesh')

	if self.board.piece and self.board.pieceR - self.board.piece.height >= 0 then
		self:drawSide(self.board:side(self.board.pieceT))
	end

	self.backgroundGraphics:moveTo(unpack(self:bottomGridPoint(1, 1)))
	self.backgroundGraphics:lineTo(unpack(self:bottomGridPoint(self.board.width + 1, 1)))
	self.backgroundGraphics:lineTo(unpack(self:bottomGridPoint(self.board.width + 1, self.board.width + 1)))
	self.backgroundGraphics:lineTo(unpack(self:bottomGridPoint(1, self.board.width + 1)))

	self.backgroundGraphics:setFillColor(B_BG_HIGHLIGHT_COLOR)

	self.backgroundGraphics:fill()

	self.backgroundGraphics:setFillColor(B_BG_BLOCKED_COLOR)
	for side = 1,4 do
		if self.board:isSideBlocked(side) then
			self:drawSide(side)
			self.backgroundGraphics:fill()
		end
	end
end

local function hexToRgba(hex)
	hex = hex:gsub('#', '')
	return tonumber("0x" .. hex:sub(1, 2)) / 255,
			tonumber("0x" .. hex:sub(3, 4)) / 255,
			tonumber("0x" .. hex:sub(5, 6)) / 255,
			tonumber("0x" .. hex:sub(7, 8)) / 255
end

function BoardRenderer:updateSquareGraphics()
	for t, r, color in self.board:iterOccupiedSquares() do
		self:drawSquare(t, r, self.gridGraphics)
		self.gridGraphics:setFillColor(hexToRgba(color .. "99"))
		self.gridGraphics:fill()
	end
end

function BoardRenderer:updateGridLineGraphics()
	-- Lines up the side of the bucket
	self.gridGraphics:setLineColor(B_GRID_COLOR)
	for t=1,self.board.circumf do
		self.gridGraphics:moveTo(self.upperGridPositions[t][0][1], self.upperGridPositions[t][0][2])
		self.gridGraphics:lineTo(self.upperGridPositions[t][self.board.depth][1], self.upperGridPositions[t][self.board.depth][2])
	end
	self.gridGraphics:stroke()

	-- Inner grid lines
	self.gridGraphics:setLineColor(B_GRID_COLOR)
	for x=2,self.board.width do
		self.gridGraphics:moveTo(unpack(self:bottomGridPoint(x, 1)))
		self.gridGraphics:lineTo(unpack(self:bottomGridPoint(x, self.board.width+1)))
	end

	for y=2,self.board.width do
		self.gridGraphics:moveTo(unpack(self:bottomGridPoint(1, y)))
		self.gridGraphics:lineTo(unpack(self:bottomGridPoint(self.board.width+1, y)))
	end
	self.gridGraphics:stroke()

	-- Outer, highlighted grid lines
	self.gridGraphics:setLineColor(B_GRID_HIGHLIGHT_COLOR)
	self.gridGraphics:moveTo(unpack(self:bottomGridPoint(1, 1)))
	self.gridGraphics:lineTo(unpack(self:bottomGridPoint(1, self.board.width+1)))
	self.gridGraphics:moveTo(unpack(self:bottomGridPoint(self.board.width+1, 1)))
	self.gridGraphics:lineTo(unpack(self:bottomGridPoint(self.board.width+1, self.board.width+1)))
	self.gridGraphics:moveTo(unpack(self:bottomGridPoint(1, 1)))
	self.gridGraphics:lineTo(unpack(self:bottomGridPoint(self.board.width+1, 1)))
	self.gridGraphics:moveTo(unpack(self:bottomGridPoint(1, self.board.width+1)))
	self.gridGraphics:lineTo(unpack(self:bottomGridPoint(self.board.width+1, self.board.width+1)))

	self.gridGraphics:setLineColor(B_GRID_HIGHLIGHT_COLOR)
	self.gridGraphics:stroke()

	-- Horizontal grid lines on outside of bucket
	for r=1,self.board.depth do
		self.gridGraphics:moveTo(lerp2(
			self.upperGridPositions[self.board.circumf][0],
			self.upperGridPositions[self.board.circumf][self.board.depth],
			r/self.board.depth
		))
		for t=1,self.board.circumf do
			self.gridGraphics:lineTo(lerp2(
				self.upperGridPositions[t][0],
				self.upperGridPositions[t][self.board.depth],
				r/self.board.depth
			))
		end

		if r == self.board.depth then
			self.gridGraphics:setLineColor(B_GRID_HIGHLIGHT_COLOR)
		else
			self.gridGraphics:setLineColor(B_GRID_COLOR)
		end
		self.gridGraphics:stroke()
	end
end

function BoardRenderer:updateGridGraphics()
	self.gridGraphics = tove.newGraphics()
	self.gridGraphics:setDisplay('mesh')

	self:updateSquareGraphics()
	self:updateGridLineGraphics()
end

function BoardRenderer:updatePieceGraphics()
	self.pieceGraphics = tove.newGraphics()
	self.pieceGraphics:setDisplay('mesh')

	if not self.board.piece then return end

	for t, r in self.board:iterPieceSquares() do
		self:drawSquare(t, r, self.pieceGraphics)
	end

	self.pieceGraphics:setFillColor(self.board.piece.color)
	self.pieceGraphics:fill()
end

function BoardRenderer:draw()
	if not self.upperGridPositions then
		self:updateGrid()
	end

	if self.lastDrawnPieceGeneration < self.board.pieceGeneration then
		self:updateBackgroundGraphics()
		self:updatePieceGraphics()
	end

	if self.lastDrawnGridGeneration < self.board.gridGeneration then
		self:updateGridGraphics()
	end

	self.lastDrawnPieceGeneration = self.board.pieceGeneration
	self.lastDrawnGridGeneration = self.board.gridGeneration

	self.backgroundGraphics:draw()
	self.pieceGraphics:draw()
	self.gridGraphics:draw()
end

StartRenderer = common.object:new()

function StartRenderer:init()
	self:resize()
end

function StartRenderer:resize()
	local cx, cy, size = getCenterAndSize()

	self.headerFont = love.graphics.newFont("fonts/AlegreyaSansSC-Light.ttf", size * .1)
	self.startFont = love.graphics.newFont("fonts/AlegreyaSansSC-Light.ttf", size * .05)
end

function StartRenderer:draw()
	local cx, cy, size = getCenterAndSize()

	love.graphics.printf(
		"Bucket",
		self.headerFont,
		cx - size/2,
		cy - size * .2,
		size,
		"center"
	)

	love.graphics.printf(
		"Press Enter or Space to start",
		self.startFont,
		cx - size/2,
		cy + size * .1,
		size,
		"center"
	)
end

LossRenderer = common.object:new()

function LossRenderer:init(gameScreen)
	self.gameScreen = gameScreen

	self:resize()
end

function LossRenderer:resize()
	self.gameScreen:resize()

	local _, _, size = getCenterAndSize()

	self.font = love.graphics.newFont("fonts/AlegreyaSansSC-Light.ttf", size * .1)
end

function LossRenderer:draw()
	local cx, cy, size = getCenterAndSize()
	local width, height = love.graphics.getDimensions()

	self.gameScreen:draw()

	love.graphics.setColor(0, 0, 0, .9)
	love.graphics.rectangle('fill', 0, 0, width, height)

	love.graphics.setColor(1, 1, 1)
	love.graphics.printf(
		"Game Over",
		self.font,
		cx - size/2,
		cy - size * .05,
		size,
		"center"
	)
end
