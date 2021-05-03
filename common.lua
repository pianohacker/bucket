module("common", package.seeall)

function dump(...)
	local vars = {...}

	local info = debug.getinfo(2)
	io.write(string.format("%s:%d: ", info.source, info.currentline))

	local variables = {}
	local idx = 1

	while true do
		local var, value = debug.getlocal(2, idx)

		if var then
			variables[var] = value
		else
			break
		end

		idx = idx + 1
	end

	for i, var in ipairs(vars) do
		io.write(string.format("%s = %s", var, variables[var]))

		if i ~= #vars then
			io.write(", ")
		end
	end

	io.write("\n")
end
