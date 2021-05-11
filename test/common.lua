-- Copyright (c) Jesse Weaver, 2021
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

module("test.common", package.seeall)

local common = require("common")

function dedent(s)
	local sep = s:match("^(%s+)[^%s]")

	for lead in s:gmatch("\n(%s+)[^%s]") do
		if lead and #lead ~= 0 then
			if not sep or #lead < #sep then
				sep = lead
			end
		end
	end

	if not sep then
		return s
	end

	local result = common.list:new()

	local pos = 1
	local nextstart, nextend = s:find(sep)

	if sep:sub(1, 1) ~= "\n" then
		sep = "\n" .. sep
	end

	while nextstart do
		if nextstart ~= pos then
			local chunk = s:sub(pos, nextstart - 1)

			if not chunk:match("^%s+$") then
				result:insert(chunk)
			end
		end

		pos = nextend + 1
		nextstart, nextend = s:find(sep, pos)
	end

	if pos ~= #s then
		local chunk = string.sub(s, pos)

		if not chunk:match("^%s+$") then
			result:insert(chunk)
		end
	end

	result, _ = result:concat("\n"):gsub("%s+$", "", 1)

	return result
end

-- [top][bottom]
local CHAR_MAPPING = {
	[false] = {
		[false] = " ",
		[true] = "▄",
	},
	[true] = {
		[false] = "▀",
		[true] = "█",
	},
}

local function gridFilled(s)
	return s == CHAR_MAPPING[true][true] or s == CHAR_MAPPING[true][false], s == CHAR_MAPPING[true][true] or s == CHAR_MAPPING[false][true]
end

function grid(gridString)
	local lines = common.list:new()
	for str in string.gmatch(dedent(gridString), "([^\n]+)") do
		lines:insert(str)
	end

	local rows = {}
	for y, line in ipairs(lines) do
		rows[y*2-1] = {}
		rows[y*2] = {}

		local x = 1
		local pos = 1
		while pos <= #line do
			if line:sub(pos, pos) == ' ' then
				rows[y*2-1][x], rows[y*2][x] = false, false
				pos = pos + 1
			else
				rows[y*2-1][x], rows[y*2][x] = gridFilled(line:sub(pos, pos+2))
				pos = pos + 3
			end
			x = x + 1
		end
	end

	local depth = 0
	while not rows[1][depth + 1] and depth < #rows[1] do
		depth = depth + 1
	end

	assert(depth ~= #rows[1])

	local width = #rows[1] - depth - 2

	local upperGrid = common.grid:new(width*4, depth, false)
	local lowerGrid = common.grid:new(width, width, false)

	assert(#rows == math.ceil((1 + depth + width + depth + 1)/2)*2)
	assert(#rows[1] == depth + 1 + width + 1)
	assert(#rows[depth + 1] == 1 + depth + width + depth + 1)

	for t = 1,width do
		for r = 1,depth do
			upperGrid[t][r] = rows[1 + depth - r + 1][depth + 1 + t]
		end
	end

	for t = width+1,width*2 do
		for r = 1,depth do
			upperGrid[t][r] = rows[1 + depth + t - width][1 + depth + width + r]
		end
	end

	for t = width*2+1,width*3 do
		for r = 1,depth do
			upperGrid[t][r] = rows[1 + depth + width + r][depth + 1 + width + 1 - (t - width * 2)]
		end
	end

	for t = width*3+1,width*4 do
		for r = 1,depth do
			upperGrid[t][r] = rows[1 + depth + width + 1 - (t - width * 3)][1 + depth + 1 - r]
		end
	end

	for x = 1,width do
		for y = 1,width do
			lowerGrid[x][y] = rows[1 + depth + y][1 + depth + x]
		end
	end

	return upperGrid, lowerGrid
end

function basicColsRepr(cols)
	local result = common.list:new()

	for y = 1,#cols[1] do
		local line = common.list:new()

		for x = 1,#cols do
			if cols[x][y] then
				line[x] = 'x'
			else
				line[x] = '_'
			end
		end

		result:insert(line:concat(""))
	end

	return result:concat("\n")
end

function basicGridRepr(rows)
	local result = {}

	for y = 1,#rows do
		local line = {}

		for x = 1,#rows[y] do
			if rows[y][x] then
				line[x] = x % 10
			else
				line[x] = '_'
			end
		end

		result:insert(string.format("%2d: ", y) .. line:concat(""))
	end

	return result:concat("\n")
end

function gridRepr(upper, lower)
	local depth = upper.height
	local width = lower.width

	local outGrid = common.list:new()

	local function topOrBottomRow(r, tStart, tEnd, tDelta)
		local row = common.list:new()

		for _ = 1,depth do
			row:insert(r == 1)
		end
		row:insert(true)
		for t = tStart,tEnd,tDelta do
			row:insert(upper[t][r])
		end
		row:insert(true)
		if r == 1 then
			for _ = 1,depth do
				row:insert(true)
			end
		end

		return row
	end

	local firstLastRow = common.list:new()
	for _ = 1,depth do
		firstLastRow:insert(false)
	end
	for _ = 1,width+2 do
		firstLastRow:insert(true)
	end
	outGrid:insert(firstLastRow)

	for r = depth,1,-1 do
		outGrid:insert(topOrBottomRow(r, 1, width, 1))
	end

	for y = 1,width do
		local row = common.list:new()

		row:insert(true)

		for r = depth,1,-1 do
			row:insert(upper[width * 4 + 1 - y][r])
		end

		for x = 1,width do
			row:insert(lower[x][y])
		end

		for r = 1,depth do
			row:insert(upper[width + y][r])
		end

		row:insert(true)

		outGrid:insert(row)
	end

	for r = 1,depth do
		outGrid:insert(topOrBottomRow(r, width*3, width*2+1, -1))
	end

	outGrid:insert(firstLastRow)

	if #outGrid % 2 == 1 then
		outGrid:insert({})
	end

	local result = common.list:new()

	for y = 1,#outGrid,2 do
		local line = ""

		for x = 1,math.max(#outGrid[y], #outGrid[y+1]) do
			line = line .. CHAR_MAPPING[
				outGrid[y][x] or false
			][
				outGrid[y + 1][x] or false
			]
		end

		result:insert(line)
	end

	return result:concat("\n")
end

function gridReflectY(cols)
	local result = {}

	for x = 1,#cols do
		result[x] = {}

		for y = #cols[1],1,-1 do
			result[x][#cols[1] - y + 1] = cols[x][y]
		end
	end

	return result
end
