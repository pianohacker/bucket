-- Copyright (c) Jesse Weaver, 2021
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local cute = require "cute"
local ui = require "ui"

profilerState = {
	fpsEnabled = (os.getenv("BUCKET_SHOW_FPS") and true or false),
	enabled = (os.getenv("BUCKET_PROFILE") and true or false),
	frame = 0,
	reportEvery = 60,
}

function love.load(args)
	cute.go(args)

	if profilerState.enabled then
		profilerState.frame = 0
		-- jit.off()
		-- profilerState.profiler = require("profile.profile")
		-- profilerState.profiler.start()
		profilerState.profiler = require("profiler")
		profilerState.profiler.start()
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

	ui:switchScreen(startScreen:new())
end

function love.resize()
	local width, height = love.graphics.getDimensions()
	ui:resize(width, height)
end

function love.draw()
	love.graphics.setColor(1, 1, 1)
	if profilerState.fpsEnabled then
		love.graphics.print("Current FPS: "..tostring(love.timer.getFPS( )), 10, 10)
	end

	ui:draw()
end

function love.update(dt)
	ui:update(dt)

	if profilerState.enabled then
		profilerState.frame = profilerState.frame + 1
		
		if profilerState.frame == profilerState.reportEvery then
			profilerState.frame = 0
			print(("-"):rep(tonumber(os.getenv("COLUMNS") or "80")))
			print(profilerState.profiler.format_result())
			-- print(profilerState.profiler.report())
			-- profilerState.profiler.report()
		end
	end
end

function love.keypressed(key)
	ui:keypressed(key)
end

function love.mousepressed(x, y, button, isTouch)
	if button ~= 1 or isTouch then return end

	ui:pressed(1, x, y)
end

function love.mousemoved(x, y, _, _, isTouch)
	if isTouch then return end

	ui:moved(1, x, y)
end

function love.mousereleased(x, y, button, isTouch)
	if button ~= 1 or isTouch then return end

	ui:released(1, x, y)
end

function love.touchpressed(id, x, y)
	ui:pressed(id, x, y)
end

function love.touchmoved(id, x, y)
	ui:moved(id, x, y)
end

function love.touchreleased(id, x, y)
	ui:released(id, x, y)
end
