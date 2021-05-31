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
	self.lastDrawnGeneration = 0
end

function BoardRenderer:resize()
	self:updateGrid()
end

function BoardRenderer:updateGrid()
	self.graphics = nil

	-- Scale to window
	local size
	self.center_x, self.center_y, size = getCenterAndSize()

	-- Calculate top of board
	self.b_top = {}
	local top_radius = size * (B_TOP_RADIUS + B_TOP_CORNERNESS)
	local b_cornerness = top_radius * B_TOP_CORNERNESS
	local step = 2 * math.pi / self.board.circumf
	for t=1,self.board.circumf do
		local angle = (t - 1) * step + B_START_ANGLE
		local cornerness = (math.abs(math.sin((t - 1) * math.pi / self.board.width))) * b_cornerness
		table.insert(
			self.b_top,
			{
				self.center_x + math.cos(angle) * (top_radius - cornerness),
				self.center_y + math.sin(angle) * (top_radius - cornerness)
			}
		)
	end

	-- Calculate bottom of board
	self.b_bottom = {}
	self.bottom_radius = size * B_BOTTOM_RADIUS

	-- North
	for x = 1,self.board.width do
		table.insert(self.b_bottom, self:bottomGridPoint(x, 1))
	end

	-- East
	for y = 1,self.board.width do
		table.insert(self.b_bottom, self:bottomGridPoint(self.board.width+1, y))
	end

	-- South
	for x = self.board.width+1,2,-1 do
		table.insert(self.b_bottom, self:bottomGridPoint(x, self.board.width+1))
	end

	-- West
	for y = self.board.width+1,2,-1 do
		table.insert(self.b_bottom, self:bottomGridPoint(1, y))
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
		return {lerp2(self.b_bottom[t], self.b_top[t], r/self.board.depth)}
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

function BoardRenderer:drawSquare(t, r)
	local side = self.board:side(t)

	self.graphics:moveTo(unpack(self:gridPoint(t, r, side)))
	self.graphics:lineTo(unpack(self:gridPoint(t+1, r, side)))
	self.graphics:lineTo(unpack(self:gridPoint(t+1, r-1, side)))
	self.graphics:lineTo(unpack(self:gridPoint(t, r-1, side)))
end

function BoardRenderer:drawSide(side)
	self.graphics:moveTo(unpack(self:gridPoint(side * self.board.width + 1, 0, side)))
	self.graphics:lineTo(unpack(self:gridPoint((side - 1) * self.board.width + 1, 0, side)))

	for t = (side - 1) * self.board.width + 1, side * self.board.width + 1 do
		self.graphics:lineTo(unpack(self:gridPoint(t, self.board.depth, side)))
	end
end

function BoardRenderer:updateBackgroundGraphics()
	if self.board.pieceR - self.board.piece.height >= 0 then
		self:drawSide(self.board:side(self.board.pieceT))
	end

	self.graphics:moveTo(unpack(self:bottomGridPoint(1, 1)))
	self.graphics:lineTo(unpack(self:bottomGridPoint(self.board.width + 1, 1)))
	self.graphics:lineTo(unpack(self:bottomGridPoint(self.board.width + 1, self.board.width + 1)))
	self.graphics:lineTo(unpack(self:bottomGridPoint(1, self.board.width + 1)))

	self.graphics:setFillColor(B_BG_HIGHLIGHT_COLOR)

	self.graphics:fill()

	self.graphics:setFillColor(B_BG_BLOCKED_COLOR)
	for side = 1,4 do
		if self.board:isSideBlocked(side) then
			self:drawSide(side)
			self.graphics:fill()
		end
	end
end

function BoardRenderer:updateSquareGraphics()
	for t = 1,self.board.circumf do
		for r = 1,self.board.depth do
			if self.board:isSquareFilled(t, r) then
				self:drawSquare(t, r)
			end
		end
	end

	for t = 1,self.board.width do
		for r = self.board.rMin,0 do
			if self.board:isSquareFilled(t, r) then
				self:drawSquare(t, r)
			end
		end
	end

	self.graphics:setFillColor("#ffffff88")
	self.graphics:fill()
end

function BoardRenderer:updateGridGraphics()
	-- Lines up the side of the bucket
	self.graphics:setLineColor(B_GRID_COLOR)
	for t=1,self.board.circumf do
		self.graphics:moveTo(self.b_bottom[t][1], self.b_bottom[t][2])
		self.graphics:lineTo(self.b_top[t][1], self.b_top[t][2])
	end
	self.graphics:stroke()

	-- Inner grid lines
	self.graphics:setLineColor(B_GRID_COLOR)
	for x=2,self.board.width do
		self.graphics:moveTo(unpack(self:bottomGridPoint(x, 1)))
		self.graphics:lineTo(unpack(self:bottomGridPoint(x, self.board.width+1)))
	end

	for y=2,self.board.width do
		self.graphics:moveTo(unpack(self:bottomGridPoint(1, y)))
		self.graphics:lineTo(unpack(self:bottomGridPoint(self.board.width+1, y)))
	end
	self.graphics:stroke()

	-- Outer, highlighted grid lines
	self.graphics:setLineColor(B_GRID_HIGHLIGHT_COLOR)
	self.graphics:moveTo(unpack(self:bottomGridPoint(1, 1)))
	self.graphics:lineTo(unpack(self:bottomGridPoint(1, self.board.width+1)))
	self.graphics:moveTo(unpack(self:bottomGridPoint(self.board.width+1, 1)))
	self.graphics:lineTo(unpack(self:bottomGridPoint(self.board.width+1, self.board.width+1)))
	self.graphics:moveTo(unpack(self:bottomGridPoint(1, 1)))
	self.graphics:lineTo(unpack(self:bottomGridPoint(self.board.width+1, 1)))
	self.graphics:moveTo(unpack(self:bottomGridPoint(1, self.board.width+1)))
	self.graphics:lineTo(unpack(self:bottomGridPoint(self.board.width+1, self.board.width+1)))

	self.graphics:setLineColor(B_GRID_HIGHLIGHT_COLOR)
	self.graphics:stroke()

	-- Horizontal grid lines on outside of bucket
	for r=1,self.board.depth do
		self.graphics:moveTo(lerp2(self.b_bottom[#self.b_bottom], self.b_top[#self.b_top], r/self.board.depth))
		for t=1,self.board.circumf do
			self.graphics:lineTo(lerp2(self.b_bottom[t], self.b_top[t], r/self.board.depth))
		end

		if r == self.board.depth then
			self.graphics:setLineColor(B_GRID_HIGHLIGHT_COLOR)
		else
			self.graphics:setLineColor(B_GRID_COLOR)
		end
		self.graphics:stroke()
	end
end

function BoardRenderer:updateGraphics()
	if not self.b_top then
		self:updateGrid()
	end

	self.graphics = tove.newGraphics()

	self:updateBackgroundGraphics()
	self:updateSquareGraphics()
	self:updateGridGraphics()

	self.lastDrawnGeneration = self.board.generation
end

function BoardRenderer:draw()
	if not self.graphics or self.lastDrawnGeneration < self.board.generation then
		self:updateGraphics()
	end

	self.graphics:draw()
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
