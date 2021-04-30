local cute = require("cute")
local inspect = require("inspect")

local board = require("board")

notion("radialToGrid works correctly", function()
	local b = board:new {width = 5, depth = 3}

	check(b:radialToGrid(3, 0)).is(3, 1)
	check(b:radialToGrid(5, -2)).is(5, 3)

	check(b:radialToGrid(6, -2)).is(3, 1)
	check(b:radialToGrid(10, -4)).is(1, 5)

	check(b:radialToGrid(12, -2)).is(4, 3)
	check(b:radialToGrid(13, 0)).is(3, 5)

	check(b:radialToGrid(18, -3)).is(4, 3)
	check(b:radialToGrid(20, 0)).is(1, 1)
end)

notion("radialToGrid with fixed side works correctly at edge", function()
	local b = board:new {width = 5, depth = 3}

	check(b:radialToGrid(20, 0, 4)).is(1, 1)
	check(b:radialToGrid(21, 0, 4)).is(1, 0)
end)

notion("remapPoint works correctly", function()
	local b = board:new {width = 5, depth = 3}

	check(b:remapPoint(2, 0, 1)).is(2, 0)
	check(b:remapPoint(2, 0, 2)).is(6, -3)
	check(b:remapPoint(2, 0, 3)).is(14, -4)
	check(b:remapPoint(2, 0, 4)).is(20, -1)

	check(b:remapPoint(12, -4, 1)).is(4, 0)
	check(b:remapPoint(12, -4, 2)).is(6, -1)
	check(b:remapPoint(12, -4, 3)).is(12, -4)
	check(b:remapPoint(12, -4, 4)).is(20, -3)
end)

local function dedent(s)
	local sep = s:match("^%s+")

	if not sep then
		sep = s:match("\n%s+")
		if not sep then
			return s
		end
	end

	local result = {}

	local pos = 1
	local nextstart, nextend = s:find(sep)

	if sep:sub(1, 1) ~= "\n" then
		sep = "\n" .. sep
	end

	while nextstart do
		if nextstart ~= pos then
			local chunk = s:sub(pos, nextstart - 1)

			if not chunk:match("^%s+$") then
				table.insert(result, chunk)
			end
		end

		pos = nextend + 1
		nextstart, nextend = s:find(sep, pos)
	end

	if pos ~= #s then
		local chunk = string.sub(s, pos)

		if not chunk:match("^%s+$") then
			table.insert(result, chunk)
		end
	end

	result, _ = table.concat(result, "\n"):gsub("%s+$", "", 1)

	return result
end

notion("dedent works correctly", function()
	check(dedent([[
		abc
		def
			ced
	]])).is("abc\ndef\n\tced")
	check(dedent([[123
		abc
		def
			ced
	]])).is("123\nabc\ndef\n\tced")
end)

local function gridFilled(s)
	return s ~= '_' and s ~= ''
end

local function grid(gridString)
	local lines = {}
	for str in string.gmatch(dedent(gridString), "([^\n]+)") do
		table.insert(lines, str)
	end

	local result = {}

	local pos = 1
	while pos < #lines do
		local cols = {}

		for x = 1,#lines[pos] do
			cols[x] = {gridFilled(lines[pos]:sub(x, x))}
		end

		for y = 2,#lines do
			pos = pos + 1

			local line = lines[pos]
			if not line or #line ~= #cols then
				break
			end

			for x = 1,#line do
				cols[x][y] = gridFilled(line:sub(x, x))
			end
		end

		table.insert(result, cols)
	end

	return unpack(result)
end

notion("grid works correctly for a single grid", function()
	local g = grid [[
		_x
		xx
		x_
		x_
	]]

	check(g[1]).shallowMatches({false, true, true, true})
	check(g[2]).shallowMatches({true, true, false, false})
end)

notion("grid works correctly for multiple grids", function()
	local g1, g2 = grid [[
		_x
		_x
		x_
		xx
		x_xx
		___x
	]]

	check(g1[1]).shallowMatches({false, false, true, true})
	check(g1[2]).shallowMatches({true, true, false, true})

	check(g2[1]).shallowMatches({true, false})
	check(g2[2]).shallowMatches({false, false})
	check(g2[3]).shallowMatches({true, false})
	check(g2[4]).shallowMatches({true, true})
end)

local function gridRepr(cols)
	local result = {}

	for y = 1,#cols[1] do
		local line = {}

		for x = 1,#cols do
			if cols[x][y] then
				line[x] = 'x'
			else
				line[x] = '_'
			end
		end

		table.insert(result, table.concat(line, ""))
	end

	return table.concat(result, "\n")
end

local function gridReflectY(cols)
	local result = {}

	for x = 1,#cols do
		result[x] = {}

		for y = #cols[1],1,-1 do
			result[x][#cols[1] - y + 1] = cols[x][y]
		end
	end

	return result
end

notion("piece movement works correctly", function()
	local b = board:new {width = 5, depth = 3}

	b:startPiece(grid [[
		_x
		xx
	]], 3)
	b:setPiece()
	check(gridRepr(gridReflectY(b.upper_grid))).is(dedent [[
		___x________________
		__xx________________
		____________________
	]])

	b:startPiece(grid [[
		_x
		xx
	]], 7)
	b:dropPiece()
	b:dropPiece()
	b:setPiece()
	check(gridRepr(gridReflectY(b.upper_grid))).is(dedent [[
		___x________________
		__xx________________
		_______x____________
	]])
	check(gridRepr(b.lower_grid)).is(dedent [[
		_____
		____x
		____x
		_____
		_____
	]])
end)

notion("piece movement blocked by collision", function()
	local b = board:new {width = 5, depth = 3}

	b:startPiece(grid [[
		_x
		xx
	]], 7)
	b:dropPiece()
	b:dropPiece()
	b:dropPiece()
	b:dropPiece()
	b:setPiece()
	check(gridRepr(gridReflectY(b.upper_grid))).is(dedent [[
		____________________
		____________________
		____________________
	]])
	check(gridRepr(b.lower_grid)).is(dedent [[
		_____
		__x__
		__xx_
		_____
		_____
	]])

	b:startPiece(grid [[
		_x
		xx
	]], 4)
	check(b:dropPiece()).is(true)
	check(b:dropPiece()).is(true)
	check(b:dropPiece()).is(true)
	check(b:dropPiece()).is(false)
end)
