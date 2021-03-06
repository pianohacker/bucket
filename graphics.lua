-- Copyright (c) Jesse Weaver, 2021
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

module("graphics", package.seeall)

local common = require("common")

local function lerp2(a, b, t)
	return {b[1] * t + a[1] * (1-t), b[2] * t + a[2] * (1-t)}
end

local MIN_ASPECT = 1.6

local function unpackEachv(input)
	local result = common.list:new()

	for _, t in ipairs(input) do
		for _, x in ipairs(t) do
			result:insert(x)
		end
	end

	return unpack(result)
end

local function unpackEach(...)
	return unpackEachv({...})
end

local RendererLayout = common.object:new()

function RendererLayout:pct(p)
	return self.smallest * p / 100
end

local Renderer = common.object:new()

function Renderer:init()
	self.fontDescriptions = self.fontDescriptions or {}
	self.fonts = {}

	self:resize()
end

function Renderer:updateLayout()
	local fullWidth, fullHeight = love.graphics.getDimensions()

	local width, height, shape
	if fullWidth > fullHeight then
		shape = 'wide'
		if MIN_ASPECT * fullHeight < fullWidth then
			width = fullHeight * MIN_ASPECT
			height = fullHeight
		else
			width = fullWidth
			height = fullWidth / MIN_ASPECT
		end
	else
		shape = 'tall'
		if MIN_ASPECT * fullWidth < fullHeight then
			width = fullWidth
			height = fullWidth * MIN_ASPECT
		else
			width = fullHeight / MIN_ASPECT
			height = fullHeight
		end
	end

	self.layout = RendererLayout:from({
		cx = fullWidth/2,
		cy = fullHeight/2,
		fullWidth = fullWidth,
		fullHeight = fullHeight,
		smallest = math.min(width, height),
		width = width,
		height = height,
		shape = shape,
	})
end

function Renderer:resize()
	self:updateLayout()

	local l = self.layout

	for key, description in pairs(self.fontDescriptions) do
		local path, relSize = unpack(description)

		self.fonts[key] = love.graphics.newFont(path, l:pct(relSize))
	end
end

local B_TOP_RADIUS = 0.4 -- Radius of outside of board as a proportion of the screen.
local B_TOP_CORNERNESS = 0.15 -- Amount that corners are drawn out.
local B_BOTTOM_RADIUS = 0.21 -- Radius of bottom of board as a proportion of the screen.
local B_START_ANGLE = -3/4 * math.pi -- The angle of t=1.
local B_GRID_COLOR = "#181818"
local B_BG_PATH_COLOR = "#0B0B0B"
local B_BG_SHADOW_COLOR = "#181818"
local B_BG_BLOCKED_COLOR = "#331111"
local B_GRID_HIGHLIGHT_COLOR = "#888888"

BoardRenderer = Renderer:new()

function BoardRenderer:init(board) 
	self.board = board
	self.lastDrawnPieceGeneration = 0
	self.lastDrawnGridGeneration = 0

	Renderer.init(self)
end

function BoardRenderer:resize()
	self:updateGrid()

	Renderer.resize(self)
end

function BoardRenderer:updateGrid()
	self.lastDrawnGridGeneration = 0
	self.lastDrawnPieceGeneration = 0

	-- Scale to window
	local l = self.layout

	-- Calculate top of board
	self.upperGridPositions = common.grid:new(self.board.circumf, self.board.depth)
	local top_radius = l.smallest * (B_TOP_RADIUS + B_TOP_CORNERNESS)
	local b_cornerness = top_radius * B_TOP_CORNERNESS
	local step = 2 * math.pi / self.board.circumf
	for t=1,self.board.circumf do
		local angle = (t - 1) * step + B_START_ANGLE
		local cornerness = (math.abs(math.sin((t - 1) * math.pi / self.board.width))) * b_cornerness
		self.upperGridPositions[t][self.board.depth] = {
			l.cx + math.cos(angle) * (top_radius - cornerness),
			l.cy + math.sin(angle) * (top_radius - cornerness)
		}
	end

	-- Calculate bottom of board
	self.bottom_radius = l.smallest * B_BOTTOM_RADIUS

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
			self.upperGridPositions[t][r] = lerp2(
				self.upperGridPositions[t][0],
				self.upperGridPositions[t][self.board.depth],
				r/self.board.depth
			)
		end
	end
end

function BoardRenderer:bottomGridPoint(x, y)
	local l = self.layout

	return {
		l.cx + self.bottom_radius * (2 * ((x - 1) / self.board.width) - 1),
		l.cy + self.bottom_radius * (2 * ((y - 1) / self.board.width) - 1),
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

	love.graphics.polygon(
		'fill',
		unpackEach(
			self:gridPoint(t+1, r-1, side),
			self:gridPoint(t, r-1, side),
			self:gridPoint(t, r, side),
			self:gridPoint(t+1, r, side)
		)
	)
end

function BoardRenderer:drawSide(side)
	local points = common.list:new()

	points:insert(self:gridPoint(side * self.board.width + 1, 0, side))
	points:insert(self:gridPoint((side - 1) * self.board.width + 1, 0, side))

	for t = (side - 1) * self.board.width + 1, side * self.board.width + 1 do
		points:insert(self:gridPoint(t, self.board.depth, side))
	end

	love.graphics.polygon('fill', unpackEachv(points))
end

local function hexToRgba(hex)
	hex = hex:gsub('#', '')

	local r = tonumber("0x" .. hex:sub(1, 2))
	local g = tonumber("0x" .. hex:sub(3, 4))
	local b = tonumber("0x" .. hex:sub(5, 6))
	local a = tonumber("0x" .. hex:sub(7, 8))

	if a ~= nil then
		return r/255, g/255, b/255, a/255
	else
		return r/255, g/255, b/255
	end
end

function BoardRenderer:drawPieceShadow()
	local pieceSide = self.board:side(self.board.pieceT)

	local lowestPieceR = {}
	local minPieceT = 1/0
	local maxPieceT = -1/0

	for t, r in self.board:iterPieceSquares() do
		if not lowestPieceR[t] or r < lowestPieceR[t] then
			lowestPieceR[t] = r
		end

		if t < minPieceT then minPieceT = t end
		if t > maxPieceT then maxPieceT = t end
	end

	local highestFallenPieceR = {}
	local fallenPieceR = self.board.pieceR

	while not self.board:pieceWouldCollide(self.board.pieceT, fallenPieceR - 1) do
		fallenPieceR = fallenPieceR - 1
	end

	love.graphics.setColor(hexToRgba(B_BG_SHADOW_COLOR))
	for t, r in self.board:iterPieceSquares(self.board.pieceT, fallenPieceR) do
		if not highestFallenPieceR[t] or r > highestFallenPieceR[t] then
			highestFallenPieceR[t] = r
		end
		self:drawSquare(t, r)
	end

	love.graphics.setColor(hexToRgba(B_BG_PATH_COLOR))
	for t = minPieceT,maxPieceT do
		for r = lowestPieceR[t] - 1, highestFallenPieceR[t] + 1, -1 do
			self:drawSquare(t, r)
		end
	end
end

function BoardRenderer:updateBackgroundGraphics()
	self.backgroundCanvas = love.graphics.newCanvas()
	love.graphics.setCanvas(self.backgroundCanvas)

	if true then
		if self.board.piece then
			self:drawPieceShadow()
		end
	else
		love.graphics.setColor(hexToRgba(B_BG_PATH_COLOR))
		if self.board.piece and self.board.pieceR - self.board.piece.height >= 0 then
			self:drawSide(self.board:side(self.board.pieceT))
		end

		love.graphics.polygon(
			'fill',
			unpackEach(
				self:bottomGridPoint(1, 1),
				self:bottomGridPoint(self.board.width + 1, 1),
				self:bottomGridPoint(self.board.width + 1, self.board.width + 1),
				self:bottomGridPoint(1, self.board.width + 1)
			)
		)
	end

	love.graphics.setColor(hexToRgba(B_BG_BLOCKED_COLOR))
	for side = 1,4 do
		if self.board:isSideBlocked(side) then
			self:drawSide(side)
		end
	end

	love.graphics.setCanvas()
end

function BoardRenderer:drawSquareGraphics()
	for t, r, color in self.board:iterOccupiedSquares() do
		love.graphics.setColor(hexToRgba(color .. "99"))
		self:drawSquare(t, r)
	end
end

function BoardRenderer:drawGridLineGraphics()
	-- Lines up the side of the bucket
	love.graphics.setColor(hexToRgba(B_GRID_COLOR))
	for t=1,self.board.circumf do
		love.graphics.line(
			self.upperGridPositions[t][0][1],
			self.upperGridPositions[t][0][2],
			self.upperGridPositions[t][self.board.depth][1],
			self.upperGridPositions[t][self.board.depth][2]
		)
	end

	-- Inner grid lines
	for x=2,self.board.width do
		love.graphics.line(unpackEach(
			self:bottomGridPoint(x, 1),
			self:bottomGridPoint(x, self.board.width+1)
		))
	end

	for y=2,self.board.width do
		love.graphics.line(unpackEach(
			self:bottomGridPoint(1, y),
			self:bottomGridPoint(self.board.width+1, y)
		))
	end

	-- Outer, highlighted grid lines
	love.graphics.setColor(hexToRgba(B_GRID_HIGHLIGHT_COLOR))
	love.graphics.line(unpackEach(
		self:bottomGridPoint(1, 1),
		self:bottomGridPoint(1, self.board.width+1)
	))
	love.graphics.line(unpackEach(
		self:bottomGridPoint(self.board.width+1, 1),
		self:bottomGridPoint(self.board.width+1, self.board.width+1)
	))
	love.graphics.line(unpackEach(
		self:bottomGridPoint(1, 1),
		self:bottomGridPoint(self.board.width+1, 1)
	))
	love.graphics.line(unpackEach(
		self:bottomGridPoint(1, self.board.width+1),
		self:bottomGridPoint(self.board.width+1, self.board.width+1)
	))

	-- Horizontal grid lines on outside of bucket
	for r=1,self.board.depth do
		local points = common.list:new()

		points:insert(lerp2(
			self.upperGridPositions[self.board.circumf][0],
			self.upperGridPositions[self.board.circumf][self.board.depth],
			r/self.board.depth
		))
		for t=1,self.board.circumf do
			points:insert(lerp2(
				self.upperGridPositions[t][0],
				self.upperGridPositions[t][self.board.depth],
				r/self.board.depth
			))
		end

		if r == self.board.depth then
			love.graphics.setColor(hexToRgba(B_GRID_HIGHLIGHT_COLOR))
		else
			love.graphics.setColor(hexToRgba(B_GRID_COLOR))
		end
		love.graphics.line(unpackEachv(points))
	end
end

function BoardRenderer:updateGridGraphics()
	self.gridCanvas = love.graphics.newCanvas()
	love.graphics.setCanvas(self.gridCanvas)

	self:drawSquareGraphics()
	self:drawGridLineGraphics()

	love.graphics.setCanvas()
end

function BoardRenderer:updatePieceGraphics()
	self.pieceCanvas = love.graphics.newCanvas()

	if not self.board.piece then return end

	love.graphics.setCanvas(self.pieceCanvas)

	love.graphics.setColor(hexToRgba(self.board.piece.color))
	for t, r in self.board:iterPieceSquares() do
		self:drawSquare(t, r)
	end

	love.graphics.setCanvas()
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

	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.setBlendMode('alpha', 'premultiplied')
	love.graphics.draw(self.backgroundCanvas)
	love.graphics.draw(self.pieceCanvas)
	love.graphics.draw(self.gridCanvas)
	love.graphics.setBlendMode('alpha')
end

PieceHintRenderer = Renderer:new()

function PieceHintRenderer:init(getNextPiece)
	self.getNextPiece = getNextPiece

	self.fontDescriptions = {
		main = {"fonts/AlegreyaSansSC-Light.ttf", 5},
	}

	Renderer.init(self)
end

function PieceHintRenderer:draw()
	local l = self.layout

	local width = l:pct(15)
	local hintX = l.fullWidth - l:pct(5) - width

	love.graphics.printf(
		"Next",
		self.fonts.main,
		hintX,
		l:pct(3),
		width,
		"center"
	)

	local p = self.getNextPiece()
	local pieceY = l:pct(9)
	local gridSize = width / 4
	local xPadding = gridSize * ((4 - p.width) / 2)

	love.graphics.setColor(hexToRgba(p.color .. 'bb'))
	for x = 1,p.width do
		for y = 1,p.height do
			if p[x + p.xOffset][y + p.yOffset] then
				love.graphics.rectangle(
					'fill',
					hintX + xPadding + (x - 1) * gridSize,
					pieceY + (y - 1) * gridSize,
					gridSize - 1,
					gridSize - 1
				)
			end
		end
	end
end

StartRenderer = Renderer:new()

function StartRenderer:init()
	self.fontDescriptions = {
		header = {"fonts/AlegreyaSansSC-Light.ttf", 10},
		start = {"fonts/AlegreyaSansSC-Light.ttf", 5},
	}

	Renderer.init(self)
end

function StartRenderer:draw()
	local l = self.layout

	love.graphics.printf(
		"Bucket",
		self.fonts.header,
		l.cx - l:pct(50),
		l.cy - l:pct(20),
		l.smallest,
		"center"
	)

	love.graphics.printf(
		"Press Enter or Space to start",
		self.fonts.start,
		l.cx - l:pct(50),
		l.cy + l:pct(10),
		l.smallest,
		"center"
	)
end

LossRenderer = Renderer:new()

function LossRenderer:init(gameScreen)
	self.gameScreen = gameScreen

	self.fontDescriptions = {
		main = {"fonts/AlegreyaSansSC-Light.ttf", 10},
	}

	Renderer.init(self)
end

function LossRenderer:resize()
	self.gameScreen:resize()

	Renderer.resize(self)
end

function LossRenderer:draw()
	local l = self.layout

	self.gameScreen:draw()

	love.graphics.setColor(0, 0, 0, .9)
	love.graphics.rectangle(
		'fill',
		0,
		0,
		l.fullWidth,
		l.fullHeight
	)

	love.graphics.setColor(1, 1, 1)
	love.graphics.printf(
		"Game Over",
		self.fonts.main,
		l.cx - l:pct(50),
		l.cy - l:pct(5),
		l.smallest,
		"center"
	)
end
