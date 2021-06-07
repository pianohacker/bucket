-- Copyright (c) Jesse Weaver, 2021
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local hsluv = require('hsluv.hsluv')

-- These pieces must be in square grids, for easy rotation.
local PIECE_GRIDS = {
	TRI = {
		color = {
			S = 50,
			L = 75,
		},
		I = {
			{0,1,0},
			{0,1,0},
			{0,1,0},
		},
		J = {
			{0,1},
			{1,1},
		},
		L = {
			{1,0},
			{1,1},
		},
	},
	TET = {
		color = {
			S = 100,
			L = 50,
		},
		I = {
			{0,1,0,0},
			{0,1,0,0},
			{0,1,0,0},
			{0,1,0,0},
		},
		J = {
			{0,1,0},
			{0,1,0},
			{1,1,0},
		},
		L = {
			{0,1,0},
			{0,1,0},
			{0,1,1},
		},
		O = {
			{1,1},
			{1,1},
		},
		S = {
			{0,1,0},
			{0,1,1},
			{0,0,1}
		},
		Z = {
			{0,1,0},
			{1,1,0},
			{1,0,0}
		},
		T = {
			{0,1,0},
			{0,1,1},
			{0,1,0},
		},
	},
}

PIECES = {}

piece = {} 
piece.__index = piece
 
function piece.random()
	return PIECES[love.math.random(1, #PIECES)]
end

local function newPiece()
	local o = {}
	setmetatable(o, piece)

	return o
end

function piece:setBounds()
	self.left = #self
	self.right = 1
	self.top = #self[1]
	self.bottom = 1

	for x = 1,#self do
		for y = 1,#self[1] do
			if self[x][y] then
				self.left = math.min(self.left, x)
				self.top = math.min(self.top, y)
				self.right = math.max(self.right, x)
				self.bottom = math.max(self.bottom, y)
			end
		end
	end

	self.width = self.right - self.left + 1
	self.height = self.bottom - self.top + 1
	self.xOffset = self.left - 1
	self.yOffset = self.top - 1
end

function piece:rotateLeft()
	local rotPiece = newPiece()

	--  4321
	-- a____
	-- b____
	-- c____
	-- d____
	--
	-- rotates to:
	--
	--  abcd
	-- 1____
	-- 2____
	-- 3____
	-- 4____

	for x = 1,#self[1] do
		rotPiece[x] = {}
		for y = 1,#self do
			rotPiece[x][y] = self[#self[1] - y + 1][x]
		end
	end

	rotPiece:setBounds()

	return rotPiece
end

function piece:rotateRight()
	local rotPiece = newPiece()

	--  1234
	-- d____
	-- c____
	-- b____
	-- a____
	--
	-- rotates to:
	--
	--  abcd
	-- 1____
	-- 2____
	-- 3____
	-- 4____

	for x = 1,#self[1] do
		rotPiece[x] = {}
		for y = 1,#self do
			rotPiece[x][y] = self[y][#self - x + 1]
		end
	end

	rotPiece:setBounds()

	return rotPiece
end

for category_name, piece_grids in pairs(PIECE_GRIDS) do
	piece[category_name] = {}

	local numPieces = 0
	for _, _ in pairs(piece_grids) do
		numPieces = numPieces + 1
	end
	numPieces = numPieces - 1 -- Ignore `color` key
	local H = 0
	local Hstep = 360 / numPieces

	for name, piece_yx in pairs(piece_grids) do
		if name == 'color' then goto continue end

		assert(#piece_yx == #piece_yx[1])

		local piece_xy = newPiece()

		for x = 1,#piece_yx[1] do
			piece_xy[x] = {}

			for y = 1,#piece_yx do
				piece_xy[x][y] = piece_yx[y][x] == 1
			end
		end

		piece_xy:setBounds()

		piece_xy.color = hsluv.hsluv_to_hex({
			H,
			piece_grids.color.S,
			piece_grids.color.L,
		})
		H = H + Hstep

		table.insert(PIECES, piece_xy)
		piece[category_name][name] = piece_xy

		::continue::
	end
end

module("piece")
