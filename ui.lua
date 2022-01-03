-- Copyright (c) Jesse Weaver, 2021
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local MIN_ASPECT = 16/9

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
	screenStack = std.list:clone(),
}

function ui:clearStack(newScreen)
	ui.screenStack:removeAll()
end

function ui:addScreen(newScreen)
	ui.screenStack:insert(newScreen)
end

function ui:removeScreen(screenParent)
	for i, screen in ipairs(ui.screenStack) do
		if screen:inherits(screenParent) then
			ui.screenStack:remove(i)
			return
		end
	end

	print("WARNING: failed to find matching screen to remove")
end

function ui:stackTop()
	return ui.screenStack[#ui.screenStack]
end

function ui:switchScreen(newScreen)
	ui:clearStack()
	ui:addScreen(newScreen)
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

function ui:resize(width, height)
	ui:updateShape(width, height)

	for screen in ui.screenStack:values() do
		screen:resize()
	end
end

function ui:draw()
	for screen in ui.screenStack:values() do
		screen:draw()
	end
end

function ui:update(dt)
	ui:stackTop():update(dt)
end

function ui:keypressed(key)
	ui:stackTop():keypressed(key)
end

function ui:pressed(id, x, y)
	ui:stackTop():pressed(id, x, y)
end

function ui:moved(id, x, y)
	ui:stackTop():moved(id, x, y)
end

function ui:released(id, x, y)
	ui:stackTop():released(id, x, y)
end

function ui:unfocused()
	ui:stackTop():unfocused()
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

function button:pressed(_, x, y)
	if self:within(x, y) then
		self.handler()
	end
end

function button:moved(_, _)
end

function button:released(_, _)
end

local sliderButton = button:clone()
ui.sliderButton = sliderButton

function sliderButton:new(x, y, width, height, steps, upHandler, downHandler)
	return self:extend({
		x = x,
		y = y,
		width = width,
		height = height,
		stepLength = height / steps,
		upHandler = upHandler,
		downHandler = downHandler,
	})
end

function sliderButton:pressed(id, x, y)
	if self.pressedId ~= nil then
		return
	end

	if self:within(x, y) then
		self.pressedId = id
		self.pressedAt = {x, y}
		self.lastAt = {x, y}
	else
		self.pressedAt = nil
	end
end

function sliderButton:stepsBetween(oldY, newY)
	local absSteps = math.floor(math.abs(oldY - newY) / self.stepLength)

	if newY < oldY then
		return -absSteps
	else
		return absSteps
	end
end

function sliderButton:moved(id, x, y)
	if self.pressedId == nil or id ~= self.pressedId then
		return
	end

	local _, pressedY = unpack(self.pressedAt)
	local _, lastY = unpack(self.lastAt)
	self.lastAt = {x, y}

	local lastSteps = self:stepsBetween(pressedY, lastY)
	local newSteps = self:stepsBetween(pressedY, y)

	for _ = lastSteps,newSteps+1,-1 do
		self.upHandler()
	end

	for _ = lastSteps,newSteps-1 do
		self.downHandler()
	end
end

function sliderButton:released(id, _, _)
	if id == self.pressedId then
		self.pressedId = nil
	end
end

module("ui")
