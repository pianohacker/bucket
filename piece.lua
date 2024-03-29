-- Copyright (c) Jesse Weaver, 2021
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local std = require('std')
local hsluv = require('hsluv.hsluv')

-- These pieces must be in square grids, for easy rotation.
local PIECES = {
	TRI = {
		I = {
			{0,1,0},
			{0,1,0},
			{0,1,0},
			color = {0, 0, 80},
		},
		J = {
			{0,1},
			{1,1},
			color = {0, 15, 60},
		},
		L = {
			{1,0},
			{1,1},
			color = {180, 15, 60},
		},
	},
	TET = {
		color = {
			S = 75,
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
	PENT = {
		color = {
			S = 100,
			L = 40,
			Hstart = 30,
		},
		F = {
			{0,1,1},
			{1,1,0},
			{0,1,0},
		},
		Fp = {
			{1,1,0},
			{0,1,1},
			{0,1,0},
		},
		I = {
			{0,0,1,0,0},
			{0,0,1,0,0},
			{0,0,1,0,0},
			{0,0,1,0,0},
			{0,0,1,0,0},
		},
		L = {
			{0,1,0,0},
			{0,1,0,0},
			{0,1,0,0},
			{0,1,1,0},
		},
		Lp = {
			{0,0,1,0},
			{0,0,1,0},
			{0,0,1,0},
			{0,1,1,0},
		},
		N = {
			{0,0,1,0},
			{0,0,1,0},
			{0,1,1,0},
			{0,1,0,0},
		},
		Np = {
			{0,1,0,0},
			{0,1,0,0},
			{0,1,1,0},
			{0,0,1,0},
		},
		P = {
			{0,1,1},
			{0,1,1},
			{0,1,0},
		},
		Pp = {
			{1,1,0},
			{1,1,0},
			{0,1,0},
		},
		T = {
			{1,1,1},
			{0,1,0},
			{0,1,0},
		},
		U = {
			{1,0,1},
			{1,1,1},
			{0,0,0},
		},
		V = {
			{1,0,0},
			{1,0,0},
			{1,1,1},
		},
		W = {
			{1,0,0},
			{1,1,0},
			{0,1,1},
		},
		X = {
			{0,1,0},
			{1,1,1},
			{0,1,0},
		},
		Y = {
			{0,0,1,0},
			{0,1,1,0},
			{0,0,1,0},
			{0,0,1,0},
		},
		Yp = {
			{0,1,0,0},
			{0,1,1,0},
			{0,1,0,0},
			{0,1,0,0},
		},
		Z = {
			{1,1,0},
			{0,1,0},
			{0,1,1},
		},
		Zp = {
			{0,1,1},
			{0,1,0},
			{1,1,0},
		},
	},
}

piece = {}
piece.__index = piece

piece.PIECE_SETS = {}

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

function piece:rotate(direction)
	local rotPiece = newPiece()

	if direction == -1 then -- Left
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
	elseif direction == 1 then -- Right
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
	end

	rotPiece:setBounds()
	rotPiece.color = self.color

	return rotPiece
end

for category_name, piece_grids in pairs(PIECES) do
	piece[category_name] = {}
	piece.PIECE_SETS[category_name] = {}

	local numPieces = 0
	for _, _ in pairs(piece_grids) do
		numPieces = numPieces + 1
	end
	numPieces = numPieces - 1 -- Ignore `color` key
	local H = (piece_grids.color or {}).Hstart or 0
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

		if piece_yx.color then
			piece_xy.color = hsluv.hsluv_to_hex(piece_yx.color)
		else
			piece_xy.color = hsluv.hsluv_to_hex({
				H,
				piece_grids.color.S,
				piece_grids.color.L,
			})
		end
		H = (H + Hstep) % 360

		piece_xy.category = category_name

		table.insert(piece.PIECE_SETS[category_name], piece_xy)
		piece[category_name][name] = piece_xy

		::continue::
	end
end

local Bag = std.object:clone()
piece.Bag = Bag

function Bag:new(values, setLength)
	setLength = setLength or #values

	return self:extend({
		values = std.list:fromTable(values),
		setLength = setLength,
		pos = setLength + 1,
	})
end

function Bag:pick()
	if self.pos > self.setLength then
		self.values:shuffle()
		self.pos = 1
	end

	local val = self.values[self.pos]
	self.pos = self.pos + 1
	return val
end

local MultiBag = std.object:clone()
piece.MultiBag = MultiBag

function MultiBag:new(valueBags)
	return self:extend(function(o)
		o.valueBags = std.list:clone()

		local setMap = std.list:clone()
		local setIndex = 1
		for set, weight in pairs(valueBags) do
			o.valueBags:insert(Bag:new(set))

			for _ = 1, weight do
				setMap:insert(setIndex)
			end

			setIndex = setIndex + 1
		end

		o.setIndexBag = Bag:new(setMap)
	end)
end

function MultiBag:pick()
	if self.peeked then
		local x = self.peeked
		self.peeked = nil
		return x
	end

	local setIndex = self.setIndexBag:pick()

	return self.valueBags[setIndex]:pick()
end

function MultiBag:peek()
	if not self.peeked then
		self.peeked = self:pick()
	end

	return self.peeked
end

module("piece")
