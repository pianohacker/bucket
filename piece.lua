-- These pieces must be symmetric, for easy rotation.
local PIECES = {
	{
		{0,1,0,0},
		{0,1,0,0},
		{0,1,0,0},
		{0,1,0,0},
	},
	{
		{0,1,0},
		{0,1,1},
		{0,1,0},
	},
	{
		{0,1,0},
		{0,1,0},
		{0,1,1},
	},
	{
		{0,1,0},
		{0,1,0},
		{1,1,0},
	},
	{
		{0,1,0},
		{0,1,1},
		{0,0,1}
	},
	{
		{0,1,0},
		{1,1,0},
		{1,0,0}
	}
}

piece = {}
piece.__index = piece

function piece.random()
	return piece.pick(love.math.random(1, #PIECES))
end

local function newPiece()
	local o = {}
	setmetatable(o, piece)

	return o
end

function piece.pick(index)
	local piece_yx = PIECES[index]
	assert(#piece_yx == #piece_yx[1])

	local piece_xy = newPiece()

	for x = 1,#piece_yx[1] do
		piece_xy[x] = {}

		for y = 1,#piece_yx do
			piece_xy[x][y] = piece_yx[y][x] == 1
		end
	end

	piece_xy:setBounds()

	return piece_xy
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

module("piece")
