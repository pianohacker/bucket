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
-- point of the the same square. (The top-left of squares on the north side, the top-right
-- of squares on the east side, etc.)

local common = require("common")

board = common.object:new()

function board:init(o)
	self.width = o.width
	self.depth = o.depth
	self.circumf = self.width * 4
	self.rMin = -self.width + 1
	self.gridGeneration = 1
	self.pieceGeneration = 1
	self:clear()
end

function board:clear()
	self.upperGrid = common.grid:new(self.circumf, self.depth, false)
	self.lowerGrid = common.grid:new(self.width, self.width, false)
	self.piece = nil
end

function board:markGridChanged()
	self.gridGeneration = self.gridGeneration + 1
end

function board:markPieceChanged()
	self.pieceGeneration = self.pieceGeneration + 1
end

function board:startPiece(piece, t)
	self:markPieceChanged()

	self.piece = piece
	self.pieceR = self.depth + (piece.top - 1)

	if not t then
		repeat
			t = love.math.random(1, self.circumf)
		until self:side(t) == self:side(t + self.piece.width) and not self:isSideBlocked(self:side(t))
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
				return self:normalizeT(
					pieceT - piece.xOffset + t - 1
				), pieceR - r + 1
			end
		end

		return nil, nil
	end

	return iter, nil, nil
end

function board:iterOccupiedSquares()
	local t = 0
	local r = self.depth
	local x = 0
	local y = 1

	local function iter()
		while r >= 1 do
			t = t + 1
			if t > self.width * 4 then
				t = 1
				r = r - 1
			end

			if r >= 1 and self.upperGrid[t][r] then
				return t, r
			end
		end

		while y <= self.width do
			x = x + 1
			if x > self.width then
				x = 1
				y = y + 1
			end

			if y <= self.width and self.lowerGrid[x][y] then
				return self:gridToRadial(x, y)
			end
		end

		return nil, nil
	end

	return iter, nil, nil
end

function board:pieceWouldCollide(pieceT, pieceR, piece)
	local side = self:side(pieceT)

	for t, r in self:iterPieceSquares(pieceT, pieceR, piece) do
		if r < -self.depth - 1 or self:isGridSquareFilled(t, r) or self:side(t) ~= side then
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
		self:markPieceChanged()

		self.pieceR = newR
		return true
	end
end

function board:shiftPiece(delta)
	self:markPieceChanged()

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
		end

		newT = newT + delta * (self.piece.width - 1)
		newT = self:normalizeT(newT)

		while self:isSideBlocked(self:side(newT)) do
			newT = self:normalizeT(newT + delta * self.width)
		end
	end

	if self:pieceWouldCollide(newT, self.pieceR) then
		return false
	end

	self.pieceT, _ = newT, 1

	return true
end

function board:setPiece()
	self:markGridChanged()
	self:markPieceChanged()

	for t, r in self:iterPieceSquares() do
		self:fillGridSquare(t, r)
	end

	self.piece = nil
end

function board:rotatePiece(direction)
	self:markPieceChanged()

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
			local newTCandidate = self:normalizeT(newTBase + offset * offsetDirection)

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

function board:normalizeT(t)
	return (t - 1) % self.circumf + 1
end

function board:side(t)
	t = self:normalizeT(t)

	return math.floor((t - 1) / self.width) + 1
end

function board:radialToGrid(t, r, side)
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

function board:gridToRadial(x, y)
	local t, r
	if x >= 1 and x <= self.width then
		if y <= self.width then
			-- North
			t = x
			r = 1 - y
		else
			-- South
			t = self.width * 3 - x + 1
			r = y - self.width
		end
	else
		if x < 1 then
			-- West
			r = 1 - x
			t = self.width * 4 - y + 1
		else
			-- East
			r = x - self.width
			t = y + self.width
		end
	end

	return t, r
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

function board:isGridSquareFilled(t, r)
	t = self:normalizeT(t)

	if r > 0 then
		return self.upperGrid[t][r]
	end

	local x, y = self:radialToGrid(t, r)

	return self.lowerGrid[x][y]
end

function board:fillGridSquare(t, r)
	t = self:normalizeT(t)

	if r > 0 then
		self.upperGrid[t][r] = true
	else
		local x, y = self:radialToGrid(t, r)

		self.lowerGrid[x][y] = true
	end
end

function board:clearLines()
	self:markGridChanged()

	local xMap = {}
	local yMap = {}
	local anyCleared = false

	local xRightShift = 0
	for x = math.ceil(self.width/2),1,-1 do
		if self.lowerGrid:col(x):all() then
			xRightShift = xRightShift + 1
			anyCleared = true
		else
			xMap[x] = x + xRightShift
		end
	end
	for x = -self.depth+1,0 do
		xMap[x] = x + xRightShift
	end

	local xLeftShift = 0
	for x = math.ceil(self.width/2)+1,self.width do
		if self.lowerGrid:col(x):all() then
			xLeftShift = xLeftShift + 1
			anyCleared = true
		else
			xMap[x] = x - xLeftShift
		end
	end
	for x = self.width+1,self.width+self.depth do
		xMap[x] = x - xLeftShift
	end

	local yDownShift = 0
	for y = math.ceil(self.width/2),1,-1 do
		if self.lowerGrid:row(y):all() then
			yDownShift = yDownShift + 1
			anyCleared = true
		else
			yMap[y] = y + yDownShift
		end
	end
	for y = -self.depth+1,0 do
		yMap[y] = y + yDownShift
	end

	local yUpShift = 0
	for y = math.ceil(self.width/2)+1,self.width do
		if self.lowerGrid:row(y):all() then
			yUpShift = yUpShift + 1
			anyCleared = true
		else
			yMap[y] = y - yUpShift
		end
	end
	for y = self.width+1,self.width+self.depth do
		yMap[y] = y - yUpShift
	end

	if not anyCleared then
		return
	end

	local oldLowerGrid = self.lowerGrid
	local oldUpperGrid = self.upperGrid
	self:clear()

	for x = 1,self.width do
		for y = 1,self.width do
			local newX = xMap[x]
			local newY = yMap[y]

			if newX and newY then
				self.lowerGrid[newX][newY] = oldLowerGrid[x][y]
			end
		end
	end

	for t = 1,self.circumf do
		for r = 1,self.depth do
			if oldUpperGrid[t][r] then
				local x, y = self:radialToGrid(t, r)

				local newX = xMap[x]
				local newY = yMap[y]

				if newX and newY then
					if newX >= 1 and newX <= self.width and newY >= 1 and newY <= self.width then
						self.lowerGrid[newX][newY] = true
					else
						local newT, newR = self:gridToRadial(newX, newY)
						self.upperGrid[newT][newR] = true
					end
				end
			end
		end
	end
end

function board:isSideBlocked(side)
	for t = (side - 1) * self.width + 1, side * self.width do
		for r = 1, self.depth do
			if self.upperGrid[t][r] then
				return true
			end
		end
	end

	return false
end

module("board")
