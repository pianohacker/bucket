-- Copyright (c) Jesse Weaver, 2021
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.
--
local graphics = require "graphics"
local piece = require "piece"
local std = require "std"

local baseScreen = require "screens/base"

local pieceGalleryScreen = baseScreen:new()

function pieceGalleryScreen:init()
	local pieces = std.list:new()

	for _, set in pairs(piece.PIECE_SETS) do
		for _, p in ipairs(set) do
			pieces:insert(p)
		end
	end

	self.renderers = {
		graphics.PieceGalleryRenderer:new(pieces),
	}

	self.keyInputMap = {}

	baseScreen.init(self)
end

function pieceGalleryScreen:layout()
end

function pieceGalleryScreen:input(input)
end

return pieceGalleryScreen
