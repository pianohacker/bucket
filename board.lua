-- Copyright (c) Jesse Weaver, 2021
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

-- Board logic and drawing
--
-- The Bucket board uses a radial coordinate system, (t, r), where t is between 1 and self.circumf,
-- inclusive and r is between -self.width + 1 and self.depth, inclusive.
--
-- For example, if self.circumf were 8, self.width were 2, and self.depth were 2, the board would look like this:
--
--                    ( 1, 2)  ( 2, 2)
--                    ( 1, 1)  ( 2, 1)
--                  /------------------\
-- ( 8, 2)  ( 8, 1) | ( 1, 0)  ( 2, 0) | ( 3, 1)  ( 3, 2)
-- ( 7, 2)  ( 7, 1) | ( 1,-1)  ( 2,-1) | ( 4, 1)  ( 4, 2)
--                  \------------------/
--                    ( 6, 1)  ( 5, 1)
--                    ( 6, 2)  ( 5, 2)
--
-- Note that the coordinates at the bottom of the board are aliased; (2, 0) could also be
-- represented as (3, 0), (5, -1), and (8, -1). This is intentional, to allow for easier  checking
-- of pieces as they rotate around the board.
--
-- Note that when these coordinates are used to refer to specific points, they refer to the far-left
-- point of the the same square. (The top-left of squares on the north or bottom sides, the top-right
-- of squares on the east side, etc.)

local common = require("common")

board = {}
board.__index = board

function board:new(o)
	o.circumf = o.width * 4
	o.rMin = -o.width + 1
	o.generation = 1

	setmetatable(o, self)

	o:clear()

	return o
end

function board:clear()
	self.upper_grid = {}
	for t = 1,self.circumf do
		self.upper_grid[t] = {}
		for r = 1,self.depth do
			self.upper_grid[t][r] = false
		end
	end

	self.lower_grid = {}
	for x = 1,self.width do
		self.lower_grid[x] = {}
		for y = 1,self.width do
			self.lower_grid[x][y] = false
		end
	end

	self.piece = nil
end

function board:markChanged()
	self.generation = self.generation + 1
end

function board:startPiece(piece, t)
	self:markChanged()

	self.piece = piece
	self.pieceR = self.depth + (piece.top - 1)

	if not t then
		repeat
			t = love.math.random(1, self.circumf)
		until self:side(t) == self:side(t + self.piece.width)
	end

	self.pieceT = t
end

function board:iterPieceSquares(pieceT, pieceR, piece)
	pieceT = pieceT or self.pieceT
	pieceR = pieceR or self.pieceR
	piece = piece or self.piece

	local t = 0
	local r = 1

	local function iter()
		while r <= #piece[1] do
			t = t + 1
			if t > #piece then
				t = 1
				r = r + 1
			end

			if r <= #piece[1] and piece[t][r] then
				return self:normalizePoint(
					pieceT - piece.xOffset + t - 1,
					pieceR - r + 1
				)
			end
		end

		return nil, nil
	end

	return iter, nil, nil
end

function board:pieceWouldCollide(pieceT, pieceR, piece)
	local side = self:side(pieceT)

	for t, r in self:iterPieceSquares(pieceT, pieceR, piece) do
		if self:isGridSquareFilled(t, r) or self:side(t) ~= side then
			return true
		end
	end

	return false
end

function board:dropPiece()
	local newR = self.pieceR - 1

	if newR - self.piece.height < -self.width or self:pieceWouldCollide(self.pieceT, newR) then
		return false
	else
		self:markChanged()

		self.pieceR = newR
		return true
	end
end

function board:shiftPiece(delta)
	self:markChanged()

	local inBottom = self.pieceR - self.piece.height < 0
	local newT = self.pieceT + delta
	local newTFar -- The furthest t covered by the piece
	if delta == -1 then
		newTFar = newT
	elseif delta == 1 then
		newTFar = newT + self.piece.right - self.piece.xOffset - 1
	end

	if self:side(self.pieceT) ~= self:side(newTFar) then
		if inBottom then
			return false
		else
			newT = newT + delta * (self.piece.width - 1)
		end
	end

	if self:pieceWouldCollide(newT, self.pieceR) then
		return false
	end

	self.pieceT, _ = self:normalizePoint(newT, 1)

	return true
end

function board:setPiece()
	self:markChanged()

	for t, r in self:iterPieceSquares() do
		self:fillGridSquare(t, r)
	end

	self.piece = nil
end

function board:rotatePiece(direction)
	self:markChanged()

	local piece
	if direction == -1 then
		piece = self.piece:rotateLeft()
	else
		piece = self.piece:rotateRight()
	end

	local newTBase = self.pieceT - self.piece.xOffset + piece.xOffset
	local newT

	for offset = 0,math.floor(piece.width / 2) do
		for offsetDirection = -1,1,2 do
			local newTCandidate, _ = self:normalizePoint(newTBase + offset * offsetDirection, 1)

			if not self:pieceWouldCollide(newTCandidate, self.pieceR, piece) then
				newT = newTCandidate
				break
			end
		end

		if newT ~= nil then
			break
		end
	end

	if newT == nil then
		return false
	end

	self.pieceT = newT
	self.piece = piece

	return true
end

function board:normalizePoint(t, r)
	t = (t - 1) % self.circumf + 1
	return t, r
end

function board:side(t)
	t, _ = self:normalizePoint(t, 1)

	return math.floor((t - 1) / self.width) + 1
end

function board:radialToGrid(t, r, side)
	assert(r < 1, "radial coordinate not on bottom of board")

	side = side or self:side(t)

	local x, y
	if side == 1 then
		-- North
		x = t
		y = 1 - r
	elseif side == 2 then
		-- East
		x = self.width + r
		y = t - self.width
	elseif side == 3 then
		-- South
		x = self.width * 3 - t + 1
		y = self.width + r
	else
		-- West
		x = 1 - r
		y = self.width * 4 - t + 1
	end

	return x, y
end

function board:remapPoint(t, r, targetSide)
	if r >= 1 then
		return t, r
	end

	if self:side(t) == targetSide then
		return t, r
	end

	local x, y = self:radialToGrid(t, r)

	if targetSide == 1 then
		-- North
		t = x
		r = 1 - y
	elseif targetSide == 2 then
		-- East
		t = y + self.width
		r = x - self.width
	elseif targetSide == 3 then
		-- South
		t = self.width * 3 - x + 1
		r = y - self.width
	else
		-- West
		r = 1 - x
		t = self.width * 4 - y + 1
	end

	return t, r
end

function board:isSquareFilled(t, r)
	t, r = self:normalizePoint(t, r)

	if self.piece then
		local transT, transR = self:remapPoint(t, r, self:side(self.pieceT))
		transT = transT + self.piece.xOffset

		if (
			(transT >= self.pieceT and transT < self.pieceT + #self.piece) and
			(transR > self.pieceR - #self.piece[1] and transR <= self.pieceR)
		) then
			if self.piece[transT - self.pieceT + 1][1 + (self.pieceR - transR)] then
				return true
			end
		end
	end

	return self:isGridSquareFilled(t, r)
end

function board:isGridSquareFilled(t, r)
	t, r = self:normalizePoint(t, r)

	if r > 0 then
		return self.upper_grid[t][r]
	end

	local x, y = self:radialToGrid(t, r)

	return self.lower_grid[x][y]
end

function board:fillGridSquare(t, r)
	t, r = self:normalizePoint(t, r)

	if r > 0 then
		self.upper_grid[t][r] = true
	else
		local x, y = self:radialToGrid(t, r)

		self.lower_grid[x][y] = true
	end
end

module("board")
