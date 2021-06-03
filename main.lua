-- Copyright (c) Jesse Weaver, 2021
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local cute = require "cute"
local lick = require "lick"

lick.files = {"main.lua"}
lick.reset = "true"
lick.debug = "true"

function lickRequire(module)
	table.insert(lick.files, module:gsub('[.]', '/') .. ".lua")

	return require(module)
end

local startScreen = lickRequire "screens/start"

screen = nil
profilerState = {
	fpsEnabled = (os.getenv("BUCKET_SHOW_FPS") and true or false),
	enabled = (os.getenv("BUCKET_PROFILE") and true or false),
	frame = 0,
	reportEvery = 240,
}

core = {}

function core.switchScreen(newScreen)
	screen = newScreen:new()
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

	screen = startScreen:new()
end

function love.resize()
	for _, renderer in ipairs(screen.renderers) do
		renderer:resize()
	end
end

function love.draw()
	love.graphics.setColor(1, 1, 1)
	if profilerState.fpsEnabled then
		love.graphics.print("Current FPS: "..tostring(love.timer.getFPS( )), 10, 10)
	end

	for _, renderer in ipairs(screen.renderers) do
		renderer:draw()
	end
end

function love.update(dt)
	screen:update(dt)

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
	screen:keypressed(key)
end
