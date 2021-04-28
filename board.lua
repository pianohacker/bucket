board = {}

-- Board logic and drawing
--
-- The Bucket board uses a radial coordinate system, (t, r), where t is between 1 and B_CIRCUMF,
-- inclusive and r is between -B_WIDTH + 1 and B_DEPTH, inclusive.
--
-- For example, if B_CIRCUMF were 8, B_WIDTH were 2, and B_DEPTH were 2, the board would look like this:
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

B_TOP_RADIUS = 0.4 -- Radius of outside of board as a proportion of the screen.
B_TOP_CORNERNESS = 0.15 -- Amount that corners are drawn out.
B_BOTTOM_RADIUS = 0.21 -- Radius of bottom of board as a proportion of the screen.
B_WIDTH = 8 -- Number of tiles across and down on the bottom of the board.
B_DEPTH = 6 -- Number of tiles up each of the sides.
B_START_ANGLE = -3/4 * math.pi -- The angle of t=1.
B_CIRCUMF = B_WIDTH*4
B_R_MIN = -B_WIDTH + 1

B_GRID_COLOR = "#222222"
B_GRID_HIGHLIGHT_COLOR = "#888888"

function lerp2(a, b, t)
	return b[1] * t + a[1] * (1-t), b[2] * t + a[2] * (1-t)
end

function side(t)
	t, _ = normalizePoint(t, 1)

	return math.floor(t - 1) / B_WIDTH + 1
end

function board:clear()
	self.upper_grid = {}
	for t = 1,B_CIRCUMF do
		self.upper_grid[t] = {}
		for r = 1,B_DEPTH do
			self.upper_grid[t][r] = false
		end
	end

	self.lower_grid = {}
	for x = 1,B_WIDTH do
		self.lower_grid[x] = {}
		for y = 1,B_WIDTH do
			self.lower_grid[x][y] = false
		end
	end

	self.piece = nil
end

function board:startPiece(piece)
	self.graphics = nil

	self.piece = piece
	self.piece_t = love.math.random(1, B_CIRCUMF)
	self.piece_r = B_DEPTH
	self.piece_w = #piece
	self.piece_h = #piece[1]
end

function board:dropPiece(piece)
	new_r = self.piece_r - 1

	if new_r - self.piece_h < -B_WIDTH then
		return false
	else
		self.graphics = nil

		self.piece_r = new_r
		return true
	end
end

function board:normalizePoint(t, r) 
	t = (t - 1) % 32 + 1
	return t, r
end

function board:denormalizePoint(t, r, targetSideT)
	if r >= 1 then
		return t, r
	end

	if side(t) == side(targetSideT) then
		return t, r
	end

	
end

function board:isSquareFilled(t, r)
	t, r = self:normalizePoint(t, r)

	if board.piece then
		trans_t, trans_r = self:denormalizePoint(t, r, board.piece_t)

		if (
			(t >= board.piece_t and t < board.piece_t + board.piece_w) and
			(r > board.piece_r - board.piece_h and r <= board.piece_r)
		) then
			if board.piece[t - board.piece_t + 1][1 + (board.piece_r - r)] then
				return true
			end
		end
	end

	if r > 0 then
		return self.upper_grid[t][r]
	end

	local x, y
	if t <= 8 then
		-- North
		x = t - 1
		y = -r
	elseif t <= 16 then
		-- East
		x = 8 + r
		y = t - 9
	elseif t <= 24 then
		-- South
		x = 8 - (t - 17)
		y = 8 + r
	else
		-- West
		x = -r
		y = 8 - (t - 25)
	end

	return self.lower_grid[x + 1][y + 1]
end

function board:bottomGridPoint(x, y)
	return {
		self.center_x + self.bottom_radius * (2 * (x / B_WIDTH) - 1),
		self.center_y + self.bottom_radius * (2 * (y / B_WIDTH) - 1),
	}
end

function board:gridPoint(t, r, sameSideAsT)
	sameSideAsT = sameSideAsT or t

	sameSideAsT, r = self:normalizePoint(sameSideAsT, r)

	-- Coordinates on the sides of the bucket are easy.
	if r > 0 then
		t, r = self:normalizePoint(t, r)
		return {lerp2(self.b_bottom[t], self.b_top[t], r/B_DEPTH)}
	end

	if sameSideAsT <= 8 then
		-- North
		return board:bottomGridPoint(
			t - 1,
			-r
		)
	elseif sameSideAsT <= 16 then
		-- East
		return board:bottomGridPoint(
			8 + r,
			t - 9
		)
	elseif sameSideAsT <= 24 then
		-- South
		return board:bottomGridPoint(
			8 - (t - 17),
			8 + r
		)
	else
		-- West
		return board:bottomGridPoint(
			-r,
			8 - (t - 25)
		)
	end
end

function board:updateGrid()
	self.graphics = nil

	-- Scale to window
	local SWIDTH, SHEIGHT = love.graphics.getDimensions()
	local SSMALLEST = math.min(SWIDTH, SHEIGHT)
	self.center_x, self.center_y = SWIDTH/2, SHEIGHT/2

	-- Calculate top of board
	self.b_top = {}
	local top_radius = SSMALLEST * (B_TOP_RADIUS + B_TOP_CORNERNESS)
	local b_cornerness = top_radius * B_TOP_CORNERNESS
	local step = 2 * math.pi / B_CIRCUMF
	for t=1,B_CIRCUMF do
		angle = (t - 1) * step + B_START_ANGLE
		cornerness = (math.abs(math.sin((t - 1) * math.pi / B_WIDTH))) * b_cornerness
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
	for x = 0,B_WIDTH do
		table.insert(self.b_bottom, self:bottomGridPoint(x, 0))
	end

	-- East
	for y = 1,B_WIDTH do
		table.insert(self.b_bottom, self:bottomGridPoint(B_WIDTH, y))
	end

	-- South
	for x = B_WIDTH-1,1,-1 do
		table.insert(self.b_bottom, self:bottomGridPoint(x, B_WIDTH))
	end

	-- West
	for y = B_WIDTH,1,-1 do
		table.insert(self.b_bottom, self:bottomGridPoint(0, y))
	end
end

function board:drawSquare(t, r)
	self.graphics:moveTo(unpack(self:gridPoint(t, r, t)))
	self.graphics:lineTo(unpack(self:gridPoint(t+1, r, t)))
	self.graphics:lineTo(unpack(self:gridPoint(t+1, r-1, t)))
	self.graphics:lineTo(unpack(self:gridPoint(t, r-1, t)))
end

function board:updateSquareGraphics()
	for t = 1,B_CIRCUMF do
		for r = 1,B_DEPTH do
			if self:isSquareFilled(t, r) then
				self:drawSquare(t, r)
			end
		end
	end

	for t = 1,B_WIDTH do
		for r = B_R_MIN,0 do
			if self:isSquareFilled(t, r) then
				self:drawSquare(t, r)
			end
		end
	end

	self.graphics:setFillColor("#ffffff88")
	self.graphics:fill()
end

function board:updateGridGraphics()
	-- Lines up the side of the bucket
	self.graphics:setLineColor(B_GRID_COLOR)
	for t=1,B_CIRCUMF do
		self.graphics:moveTo(self.b_bottom[t][1], self.b_bottom[t][2])
		self.graphics:lineTo(self.b_top[t][1], self.b_top[t][2])
	end
	self.graphics:stroke()

	-- Inner grid lines
	self.graphics:setLineColor(B_GRID_COLOR)
	for x=1,B_WIDTH-1 do
		self.graphics:moveTo(unpack(self:bottomGridPoint(x, 0)))
		self.graphics:lineTo(unpack(self:bottomGridPoint(x, B_WIDTH)))
	end

	for y=1,B_WIDTH-1 do
		self.graphics:moveTo(unpack(self:bottomGridPoint(0, y)))
		self.graphics:lineTo(unpack(self:bottomGridPoint(B_WIDTH, y)))
	end
	self.graphics:stroke()

	-- Outer, highlighted grid lines
	self.graphics:setLineColor(B_GRID_HIGHLIGHT_COLOR)
	self.graphics:moveTo(unpack(self:bottomGridPoint(0, 0)))
	self.graphics:lineTo(unpack(self:bottomGridPoint(0, B_WIDTH)))
	self.graphics:moveTo(unpack(self:bottomGridPoint(B_WIDTH, 0)))
	self.graphics:lineTo(unpack(self:bottomGridPoint(B_WIDTH, B_WIDTH)))
	self.graphics:moveTo(unpack(self:bottomGridPoint(0, 0)))
	self.graphics:lineTo(unpack(self:bottomGridPoint(B_WIDTH, 0)))
	self.graphics:moveTo(unpack(self:bottomGridPoint(0, B_WIDTH)))
	self.graphics:lineTo(unpack(self:bottomGridPoint(B_WIDTH, B_WIDTH)))

	self.graphics:setLineColor(B_GRID_HIGHLIGHT_COLOR)
	self.graphics:stroke()

	-- Horizontal grid lines on outside of bucket
	for r=1,B_DEPTH do
		self.graphics:moveTo(lerp2(self.b_bottom[#self.b_bottom], self.b_top[#self.b_top], r/B_DEPTH))
		for t=1,B_CIRCUMF do
			self.graphics:lineTo(lerp2(self.b_bottom[t], self.b_top[t], r/B_DEPTH))
		end

		if r == B_DEPTH then
			self.graphics:setLineColor(B_GRID_HIGHLIGHT_COLOR)
		else
			self.graphics:setLineColor(B_GRID_COLOR)
		end
		self.graphics:stroke()
	end
end

function board:updateGraphics()
	if not self.b_top then
		self:updateGrid()
	end

	self.graphics = tove.newGraphics()

	self:updateSquareGraphics()

	self:updateGridGraphics()
end

function board:draw()
	if not self.graphics then
		self:updateGraphics()
	end

	self.graphics:draw()
end

module("board")
