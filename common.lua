module("common", package.seeall)

function dump(...)
	local exprs = {...}

	local info = debug.getinfo(2)
	io.write(string.format("%s:%d: ", info.source, info.currentline))

	local scope = {}
	local idx = 1

	while true do
		local var, value = debug.getlocal(2, idx)

		if var then
			scope[var] = value
		else
			break
		end

		idx = idx + 1
	end

	setmetatable(scope, {__index = getfenv(2)})

	for i, expr in ipairs(exprs) do
		local chunk = loadstring("return " .. expr)
		setfenv(chunk, scope)
		local result = chunk()
		io.write(string.format("%s = %s", expr, result))

		if i ~= #exprs then
			io.write(", ")
		end
	end

	io.write("\n")
end
