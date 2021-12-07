-- Copyright (c) Jesse Weaver, 2021
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local MIN_ASPECT = 1.6

local std = require("std")

local UiShape = std.object:clone()

function UiShape:pct(p)
	return self.smallest * p / 100
end

function UiShape:pctAccum()
	local p = 0

	return function(delta)
		p = p + delta
		return self:pct(p)
	end
end

-- This is a poor replacement for an actual gravity/anchor system.
function UiShape:relPctCoords(x, y, width, height)
	local realX
	if x < 0 then
		realX = self.fullWidth - self:pct(-x + width)
	else
		realX = self:pct(x)
	end

	local realY
	if y < 0 then
		realY = self.fullHeight - self:pct(-y + height)
	else
		realY = self:pct(y)
	end

	return realX, realY, self:pct(width), self:pct(height)
end

ui = {
	isMobile = (not not os.getenv("BUCKET_FORCE_MOBILE")) or love.system.getOS() == 'Android' or love.system.getOS() == 'iOS',
}

function ui:switchScreen(newScreen)
	ui.screen = newScreen
end

function ui:updateShape(fullWidth, fullHeight)
	local width, height, orientation
	if fullWidth > fullHeight then
		orientation = 'wide'
		if MIN_ASPECT * fullHeight < fullWidth then
			width = fullHeight * MIN_ASPECT
			height = fullHeight
		else
			width = fullWidth
			height = fullWidth / MIN_ASPECT
		end
	else
		orientation = 'tall'
		if MIN_ASPECT * fullWidth < fullHeight then
			width = fullWidth
			height = fullWidth * MIN_ASPECT
		else
			width = fullHeight / MIN_ASPECT
			height = fullHeight
		end
	end

	self.shape = UiShape:extend({
		cx = fullWidth/2,
		cy = fullHeight/2,
		fullWidth = fullWidth,
		fullHeight = fullHeight,
		smallest = math.min(width, height),
		width = width,
		height = height,
		orientation = orientation,
	})
end

--- A clickable/touchable button.
--
-- All coordinates are given as positive/negative fractions of the screen.
local button = std.object:clone()
ui.button = button

function button:new(x, y, width, height, handler)
	return self:extend({
		x = x,
		y = y,
		width = width,
		height = height,
		handler = handler,
	})
end

function button:within(x, y)
	if x < self.x or x >= self.x + self.width or y < self.y or y >= self.y + self.height then
		return false
	end

	return true
end

function button:pressed()
	self.handler()
end

module("ui")
