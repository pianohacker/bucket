-- Copyright (c) Jesse Weaver, 2021
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

graphics = {}

function lerp2(a, b, t)
	return b[1] * t + a[1] * (1-t), b[2] * t + a[2] * (1-t)
end

B_TOP_RADIUS = 0.4 -- Radius of outside of board as a proportion of the screen.
B_TOP_CORNERNESS = 0.15 -- Amount that corners are drawn out.
B_BOTTOM_RADIUS = 0.21 -- Radius of bottom of board as a proportion of the screen.
B_START_ANGLE = -3/4 * math.pi -- The angle of t=1.
B_GRID_COLOR = "#222222"
B_GRID_HIGHLIGHT_COLOR = "#888888"

BoardRenderer = {}
BoardRenderer.__index = BoardRenderer
graphics.BoardRenderer = BoardRenderer

function BoardRenderer:new(board) 
	local o = { board = board, lastDrawnGeneration = 0 }
	setmetatable(o, self)
	return o
end

function BoardRenderer:resize()
	self:updateGrid()
end

function BoardRenderer:updateGrid()
	self.graphics = nil

	-- Scale to window
	local SWIDTH, SHEIGHT = love.graphics.getDimensions()
	local SSMALLEST = math.min(SWIDTH, SHEIGHT)
	self.center_x, self.center_y = SWIDTH/2, SHEIGHT/2

	-- Calculate top of board
	self.b_top = {}
	local top_radius = SSMALLEST * (B_TOP_RADIUS + B_TOP_CORNERNESS)
	local b_cornerness = top_radius * B_TOP_CORNERNESS
	local step = 2 * math.pi / self.board.circumf
	for t=1,self.board.circumf do
		angle = (t - 1) * step + B_START_ANGLE
		cornerness = (math.abs(math.sin((t - 1) * math.pi / self.board.width))) * b_cornerness
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
	self.bottom_radius = SSMALLEST * B_BOTTOM_RADIUS

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
		t, r = self.board:normalizePoint(t, r)
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

module("graphics")
