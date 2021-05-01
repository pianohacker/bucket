module("test.common", package.seeall)

function dedent(s)
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

local function gridFilled(s)
	return s ~= '_' and s ~= ''
end

function grid(gridString)
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

function gridRepr(cols)
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
