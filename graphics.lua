-- Copyright (c) Jesse Weaver, 2021
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

module("graphics", package.seeall)

local std = require("std")
local ui = require "ui"

local function lerp2(a, b, t)
	return {b[1] * t + a[1] * (1-t), b[2] * t + a[2] * (1-t)}
end

local function unpackEachv(input)
	local result = std.list:clone()

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

local Renderer = std.object:clone()

function Renderer:fontDescriptions()
	return {}
end

Renderer.fonts = std.memoized(
	function(self) return ui.shape, self end,
	function(self, s)
		local fonts = {}
		for key, description in pairs(self.fontDescriptions()) do
			local path, relSize = unpack(description)

			fonts[key] = love.graphics.newFont(path, s:pct(relSize))
		end

		return fonts
	end
)

function memoizedCanvasRenderer(key, renderFunc)
	return std.memoized(
		key,
		function(...)
			local canvas = love.graphics.newCanvas()
			love.graphics.setCanvas(canvas)

			renderFunc(...)

			love.graphics.setCanvas()

			return canvas
		end
	)
end

local B_TOP_RADIUS = 0.4 -- Radius of outside of board as a proportion of the screen.
local B_TOP_CORNERNESS = 0.15 -- Amount that corners are drawn out.
local B_BOTTOM_RADIUS = 0.18 -- Radius of bottom of board as a proportion of the screen.
local B_START_ANGLE = -3/4 * math.pi -- The angle of t=1.
local B_GRID_COLOR = "#181818"
local B_BG_PATH_COLOR = "#0B0B0B"
local B_BG_SHADOW_COLOR = "#181818"
local B_BG_BLOCKED_COLOR = "#331111"
local B_GRID_HIGHLIGHT_COLOR = "#888888"

GridLayout = std.object:clone()

BoardRenderer = Renderer:clone()

function BoardRenderer:new(board) 
	return self:extend({
		board = board,
		lastDrawnPieceGeneration = 0,
		lastDrawnGridGeneration = 0,
	})
end

BoardRenderer.gridLayout = std.memoized(
	function() return ui.shape end,
	function(self, s)
		-- Calculate top of board
		local upperGridPositions = std.grid:new(self.board.circumf, self.board.depth)
		local top_radius = s.smallest * (B_TOP_RADIUS + B_TOP_CORNERNESS)
		local b_cornerness = top_radius * B_TOP_CORNERNESS
		local step = 2 * math.pi / self.board.circumf
		for t=1,self.board.circumf do
			local angle = (t - 1) * step + B_START_ANGLE
			local cornerness = (math.abs(math.sin((t - 1) * math.pi / self.board.width))) * b_cornerness
			upperGridPositions[t][self.board.depth] = {
				s.cx + math.cos(angle) * (top_radius - cornerness),
				s.cy + math.sin(angle) * (top_radius - cornerness)
			}
		end

		-- Calculate bottom of board
		local gl = GridLayout:extend({
			board = self.board,
			bottomRadius = s.smallest * B_BOTTOM_RADIUS,
			upperGridPositions = upperGridPositions,
		})

		local t = 1
		-- North
		for x = 1,self.board.width do
			upperGridPositions[t][0] = gl:bottomGridPoint(x, 1)
			t = t + 1
		end

		-- East
		for y = 1,self.board.width do
			upperGridPositions[t][0] = gl:bottomGridPoint(self.board.width+1, y)
			t = t + 1
		end

		-- South
		for x = self.board.width+1,2,-1 do
			upperGridPositions[t][0] = gl:bottomGridPoint(x, self.board.width+1)
			t = t + 1
		end

		-- West
		for y = self.board.width+1,2,-1 do
			upperGridPositions[t][0] = gl:bottomGridPoint(1, y)
			t = t + 1
		end

		for t = 1, self.board.circumf do
			for r = 1, self.board.depth - 1 do
				upperGridPositions[t][r] = lerp2(
					upperGridPositions[t][0],
					upperGridPositions[t][self.board.depth],
					r/self.board.depth
				)
			end
		end

		return gl
	end
)

function GridLayout:bottomGridPoint(x, y)
	local s = ui.shape

	return {
		s.cx + self.bottomRadius * (2 * ((x - 1) / self.board.width) - 1),
		s.cy + self.bottomRadius * (2 * ((y - 1) / self.board.width) - 1),
	}
end

function GridLayout:gridPoint(t, r, side)
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
	local gridLayout = self:gridLayout()
	local side = self.board:side(t)

	love.graphics.polygon(
		'fill',
		unpackEach(
			gridLayout:gridPoint(t+1, r-1, side),
			gridLayout:gridPoint(t, r-1, side),
			gridLayout:gridPoint(t, r, side),
			gridLayout:gridPoint(t+1, r, side)
		)
	)
end

function BoardRenderer:drawSide(side)
	local gridLayout = self:gridLayout()
	local points = std.list:clone()

	points:insert(gridLayout:gridPoint(side * self.board.width + 1, 0, side))
	points:insert(gridLayout:gridPoint((side - 1) * self.board.width + 1, 0, side))

	for t = (side - 1) * self.board.width + 1, side * self.board.width + 1 do
		points:insert(gridLayout:gridPoint(t, self.board.depth, side))
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

BoardRenderer.renderBackgroundGraphics = memoizedCanvasRenderer(
	function(self) return self.board.pieceGeneration, ui.shape end,
	function(self)
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
	end
)

function BoardRenderer:drawSquareGraphics()
	for t, r, color in self.board:iterOccupiedSquares() do
		love.graphics.setColor(hexToRgba(color .. "99"))
		self:drawSquare(t, r)
	end
end

function BoardRenderer:drawGridLineGraphics()
	local gl = self:gridLayout()

	-- Lines up the side of the bucket
	love.graphics.setColor(hexToRgba(B_GRID_COLOR))
	for t=1,self.board.circumf do
		love.graphics.line(
			gl.upperGridPositions[t][0][1],
			gl.upperGridPositions[t][0][2],
			gl.upperGridPositions[t][self.board.depth][1],
			gl.upperGridPositions[t][self.board.depth][2]
		)
	end

	-- Inner grid lines
	for x=2,self.board.width do
		love.graphics.line(unpackEach(
			gl:bottomGridPoint(x, 1),
			gl:bottomGridPoint(x, self.board.width+1)
		))
	end

	for y=2,self.board.width do
		love.graphics.line(unpackEach(
			gl:bottomGridPoint(1, y),
			gl:bottomGridPoint(self.board.width+1, y)
		))
	end

	-- Outer, highlighted grid lines
	love.graphics.setColor(hexToRgba(B_GRID_HIGHLIGHT_COLOR))
	love.graphics.line(unpackEach(
		gl:bottomGridPoint(1, 1),
		gl:bottomGridPoint(1, self.board.width+1)
	))
	love.graphics.line(unpackEach(
		gl:bottomGridPoint(self.board.width+1, 1),
		gl:bottomGridPoint(self.board.width+1, self.board.width+1)
	))
	love.graphics.line(unpackEach(
		gl:bottomGridPoint(1, 1),
		gl:bottomGridPoint(self.board.width+1, 1)
	))
	love.graphics.line(unpackEach(
		gl:bottomGridPoint(1, self.board.width+1),
		gl:bottomGridPoint(self.board.width+1, self.board.width+1)
	))

	-- Horizontal grid lines on outside of bucket
	for r=1,self.board.depth do
		local points = std.list:clone()

		points:insert(lerp2(
			gl.upperGridPositions[self.board.circumf][0],
			gl.upperGridPositions[self.board.circumf][self.board.depth],
			r/self.board.depth
		))
		for t=1,self.board.circumf do
			points:insert(lerp2(
				gl.upperGridPositions[t][0],
				gl.upperGridPositions[t][self.board.depth],
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

BoardRenderer.renderGridGraphics = memoizedCanvasRenderer(
	function(self) return self.board.gridGeneration, ui.shape end,
	function(self)
		self:drawSquareGraphics()
		self:drawGridLineGraphics()
	end
)

BoardRenderer.renderPieceGraphics = memoizedCanvasRenderer(
	function(self) return self.board.pieceGeneration, ui.shape end,
	function(self)
		if not self.board.piece then return end

		love.graphics.setColor(hexToRgba(self.board.piece.color))
		for t, r in self.board:iterPieceSquares() do
			self:drawSquare(t, r)
		end
	end
)

function BoardRenderer:draw()
	local backgroundCanvas = self:renderBackgroundGraphics()
	local pieceCanvas = self:renderPieceGraphics()
	local gridCanvas = self:renderGridGraphics()

	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.setBlendMode('alpha', 'premultiplied')
	love.graphics.draw(backgroundCanvas)
	love.graphics.draw(pieceCanvas)
	love.graphics.draw(gridCanvas)
	love.graphics.setBlendMode('alpha')
end

PieceHintRenderer = Renderer:clone()

function PieceHintRenderer:new(getNextPiece)
	return self:extend({
		getNextPiece = getNextPiece,
	})
end

function PieceHintRenderer:fontDescriptions()
	return {
		main = {"fonts/AlegreyaSansSC-Medium.ttf", 6},
	}
end

function drawPiece(p, pieceX, pieceY, gridSize)
	local xPadding = gridSize * ((4 - p.width) / 2)

	love.graphics.setColor(hexToRgba(p.color .. 'bb'))
	for x = 1,p.width do
		for y = 1,p.height do
			if p[x + p.xOffset][y + p.yOffset] then
				love.graphics.rectangle(
					'fill',
					pieceX + xPadding + (x - 1) * gridSize,
					pieceY + (y - 1) * gridSize,
					gridSize - 1,
					gridSize - 1
				)
			end
		end
	end
end

function PieceHintRenderer:draw()
	local s = ui.shape

	local width = s:pct(20)
	local hintX = s.fullWidth - s:pct(5) - width

	love.graphics.printf(
		"Next",
		self:fonts().main,
		hintX,
		s:pct(3),
		width,
		"center"
	)

	local p = self.getNextPiece()
	local pieceY = s:pct(10)
	local gridSize = width / 4

	drawPiece(p, hintX, pieceY,  gridSize)
end

ScoreRenderer = Renderer:clone()

function ScoreRenderer:new(getLevel, getScore, getClearedLines)
	return self:extend({
		getLevel = getLevel,
		getScore = getScore,
		getClearedLines = getClearedLines,
	})
end

function ScoreRenderer:fontDescriptions()
	return {
		title = {"fonts/AlegreyaSansSC-Light.ttf", 6},
		main = {"fonts/AlegreyaSansSC-Medium.ttf", 5},
	}
end

function ScoreRenderer:draw()
	local s = ui.shape

	local width = s:pct(15)
	local addPct = s:pctAccum()

	love.graphics.setColor(1, 1, 1, 1)

	love.graphics.printf(
		"Level",
		self:fonts().title,
		s:pct(5),
		addPct(3),
		width,
		"left"
	)
	love.graphics.printf(
		self.getLevel(),
		self:fonts().main,
		s:pct(5),
		addPct(5.5),
		width,
		"left"
	)

	love.graphics.printf(
		"Score",
		self:fonts().title,
		s:pct(5),
		addPct(6.5),
		width,
		"left"
	)
	love.graphics.printf(
		self.getScore(),
		self:fonts().main,
		s:pct(5),
		addPct(5.5),
		width,
		"left"
	)

	love.graphics.printf(
		"Lines",
		self:fonts().title,
		s:pct(5),
		addPct(6.5),
		width,
		"left"
	)
	love.graphics.printf(
		self.getClearedLines(),
		self:fonts().main,
		s:pct(5),
		addPct(5.5),
		width,
		"left"
	)
end

StartRenderer = Renderer:clone()

function StartRenderer:fontDescriptions()
	return {
		header = {"fonts/AlegreyaSansSC-Light.ttf", 10},
		start = {"fonts/AlegreyaSansSC-Light.ttf", 5},
	}
end

function StartRenderer:draw()
	local s = ui.shape

	love.graphics.printf(
		"Bucket",
		self:fonts().header,
		s.cx - s:pct(50),
		s.cy - s:pct(20),
		s.smallest,
		"center"
	)

	love.graphics.printf(
		"Press Space to start",
		self:fonts().start,
		s.cx - s:pct(50),
		s.cy + s:pct(10),
		s.smallest,
		"center"
	)
end

LossRenderer = Renderer:clone()

function LossRenderer:new(gameScreen, getOpacity)
	return self:extend({
		gameScreen = gameScreen,
		getOpacity = getOpacity,
	})
end

function LossRenderer:fontDescriptions()
	return {
		main = {"fonts/AlegreyaSansSC-Light.ttf", 10},
	}
end

function LossRenderer:draw()
	local s = ui.shape

	self.gameScreen:draw()

	love.graphics.setColor(0, 0, 0, self.getOpacity())
	love.graphics.rectangle(
		'fill',
		0,
		0,
		s.fullWidth,
		s.fullHeight
	)

	love.graphics.setColor(1, 1, 1, self.getOpacity())
	love.graphics.printf(
		"Game  Over",
		self:fonts().main,
		s.cx - s:pct(50),
		s.cy - s:pct(5),
		s.smallest,
		"center"
	)
end

ButtonsRenderer = Renderer:clone()

function ButtonsRenderer:new(getButtons)
	return self:extend({
		getButtons = getButtons,
	})
end

function ButtonsRenderer:draw()
	love.graphics.setColor(1, 1, 1, .8)
	for _, button in ipairs(self.getButtons()) do
		love.graphics.rectangle(
			'line',
			button.x,
			button.y,
			button.width,
			button.height
		)
	end
end

PieceGalleryRenderer = Renderer:clone()

function PieceGalleryRenderer:new(pieces)
	return self:extend({
		pieces = pieces,
	})
end

function PieceGalleryRenderer:draw()
	local s = ui.shape

	local rows = 1
	local cellSize, columns

	while true do
		cellSize = s.fullHeight / rows
		columns = math.floor(s.fullWidth / cellSize)

		if rows * columns >= #self.pieces then
			break
		else
			rows = rows + 1
		end
	end

	local gridSize = cellSize / 6
	local cellPadding = gridSize / 2

	local pieceI = 1
	for row = 1,rows do
		local pieceY = (row - 1) * cellSize
		for column = 1,columns do
			local pieceX = (column - 1) * cellSize

			drawPiece(self.pieces[pieceI], pieceX, pieceY, gridSize)
			pieceI = pieceI + 1

			if pieceI > #self.pieces then
				break
			end
		end

		if pieceI > #self.pieces then
			break
		end
	end
end
