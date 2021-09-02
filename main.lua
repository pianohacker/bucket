-- Copyright (c) Jesse Weaver, 2021
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local common = require "common"
local cute = require "cute"

local MIN_ASPECT = 1.6

profilerState = {
	fpsEnabled = (os.getenv("BUCKET_SHOW_FPS") and true or false),
	enabled = (os.getenv("BUCKET_PROFILE") and true or false),
	frame = 0,
	reportEvery = 240,
}

local UiShape = common.object:new()

function UiShape:pct(p)
	return self.smallest * p / 100
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
	isMobile = love.system.getOS() == 'Android' or love.system.getOS() == 'iOS',
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

	self.shape = UiShape:from({
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

function love.load(args)
	cute.go(args)

	if profilerState.enabled then
		jit.off()
		profilerState.profiler = require("profile.profile")
		profilerState.profiler.start()
		profilerState.frame = 0
	end

	love.keyboard.setKeyRepeat(true)

	local width, height = love.graphics.getDimensions()
	ui:updateShape(width, height)

	local startScreen
	if args[1] == 'screen' and #args >= 2 then
		startScreen = require("screens/" .. args[2])
	else
		startScreen = require "screens/start"
	end

	ui.screen = startScreen:new()
end

function love.resize()
	local width, height = love.graphics.getDimensions()
	ui:updateShape(width, height)

	ui.screen:resize()
end

function love.draw()
	love.graphics.setColor(1, 1, 1)
	if profilerState.fpsEnabled then
		love.graphics.print("Current FPS: "..tostring(love.timer.getFPS( )), 10, 10)
	end

	ui.screen:draw()
end

function love.update(dt)
	ui.screen:update(dt)

	if profilerState.enabled then
		profilerState.frame = profilerState.frame + 1
		
		if profilerState.frame == profilerState.reportEvery then
			profilerState.frame = 0
			print(profilerState.profiler.report())
			profilerState.profiler.report()
		end
	end
end

function love.keypressed(key)
	ui.screen:keypressed(key)
end

local common = require('common')

function love.mousepressed(x, y)
	ui.screen:mousepressed(x, y)
end
