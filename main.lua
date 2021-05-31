-- Copyright (c) Jesse Weaver, 2021
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

cute = require "cute"
lick = require "lick"
tove = require "tove"

lick.files = {"main.lua"}
lick.reset = "true"
lick.debug = "true"

function lickRequire(module)
	table.insert(lick.files, module:gsub('[.]', '/') .. ".lua")

	return require(module)
end

gameScreen = lickRequire "screens/game"

screen = nil

function love.load(args)
	cute.go(args)

	love.keyboard.setKeyRepeat(true)

	screen = gameScreen:new()
end

function love.resize()
	for _, renderer in ipairs(screen.renderers) do
		renderer:resize()
	end
end

function love.draw()
	love.graphics.setColor(1, 1, 1)

	for _, renderer in ipairs(screen.renderers) do
		renderer:draw()
	end
end

function love.update(dt)
	screen:update(dt)
end

function love.keypressed(key)
	screen:keypressed(key)
end
