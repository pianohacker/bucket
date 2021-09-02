-- Copyright (c) Jesse Weaver, 2021
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.
--
local ui = require "ui"
local graphics = require "graphics"

local baseScreen = require "screens/base"

local startScreen = baseScreen:new()

function startScreen:init()
	self.renderers = {
		graphics.StartRenderer:new(),
	}

	self.keyInputMap = {
		space = 'START',
	}

	baseScreen.init(self)
end

function startScreen:layout()
	local s = ui.shape

	self.buttons = {
		ui.button:new(
			0,
			0,
			s.fullWidth,
			s.fullHeight,
			function() self:input('START') end
		),
	}
end

function startScreen:input(input)
	if input == 'START' then
		local gameScreen = require "screens/game"
		ui:switchScreen(gameScreen:new())
	end
end

return startScreen
