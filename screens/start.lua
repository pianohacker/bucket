-- Copyright (c) Jesse Weaver, 2021
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.
--
local common = require "common"
local graphics = require "graphics"

local baseScreen = require "screens/base"

local startScreen = baseScreen:new()

function startScreen:init()
	self.renderers = {
		graphics.StartRenderer:new(),
	}
end

function startScreen:update()
end

function startScreen:keypressed(key)
	if key == 'space' or key == 'enter' then
		local gameScreen = require "screens/game"
		core.switchScreen(gameScreen:new())
	end
end

return startScreen
