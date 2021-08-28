-- Copyright (c) Jesse Weaver, 2021
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

module("common", package.seeall)

--- Dump out multiple expressions.
-- Prints out the value of multiple expressions, given as strings.
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
		local chunk, err = loadstring("return " .. expr)

		if err then
			io.write(string.format("%s = err: %s", expr, err))
		else
			setfenv(chunk, scope)
			local result = chunk()
			io.write(string.format("%s = %s", expr, result))
		end

		if i ~= #exprs then
			io.write(", ")
		end
	end

	io.write("\n")
end

object = {}
function object:new(...)
	return self:from({}, ...)
end
function object:from(o, ...)
	local metatable = {
		__add = self.__add,
		__sub = self.__sub,
		__mul = self.__mul,
		__div = self.__div,
		__mod = self.__mod,
		__pow = self.__pow,
		__unm = self.__unm,
		__concat = self.__concat,
		__len = self.__len,
		__eq = self.__eq,
		__lt = self.__lt,
		__le = self.__le,
		__index = self.__index or self,
		__newindex = self.__newindex,
		__call = self.__call,
	}
	setmetatable(o, metatable)

	if o.init then
		o:init(...)
	end

	return o
end

list = object:new()
list.concat = table.concat
list.insert = table.insert
list.maxn = table.maxn
list.remove = table.remove
list.sort = table.sort

function list:fromTable(t)
	local o = self:new()

	for i, x in ipairs(t) do
		o[i] = x
	end

	return o
end

function list:values()
	local i = 0

	local function iter()
		i = i + 1
		if i <= #self then
			return self[i]
		else
			return nil
		end
	end

	return iter
end

function list:all()
	for x in self:values() do
		if not x then
			return false
		end
	end

	return true
end

function list:shuffle()
	for i = 1,#self do
		local j = love.math.random(i, #self)

		local x = self[i]
		self[i] = self[j]
		self[j] = x
	end
end

function list:reverse()
	for i = 1,math.floor(#self/2) do
		local j = #self - i + 1

		local x = self[i]
		self[i] = self[j]
		self[j] = x
	end
end

function list:extend(t)
	for _, x in ipairs(t) do
		self:insert(x)
	end
end

grid = object:new()

local checkedGridColumn = {}
function checkedGridColumn:new(g, x)
	local o = {
		g = g,
		x = x,
	}
	setmetatable(o, checkedGridColumn)
	return o
end

function checkedGridColumn:_checkCoords(y, op)
	if self.x < 1 or self.x > self.g.width or y < 1 or y > self.g.height then
		error(string.format("attempt to %s grid at out-of-bounds (%d, %d)", op, self.x, y), 3)
	end
end

function checkedGridColumn:__index(y)
	if type(y) == "number" then
		self:_checkCoords(y, "get")
		return self.g[self.x][y]
	elseif rawget(self, y) then
		return rawget(self, y)
	else
		return checkedGridColumn[y]
	end
end

function checkedGridColumn:__newindex(y, val)
	if type(y) == "number" then
		self:_checkCoords(y, "set")
		self.g[self.x][y] = val
	else
		rawset(self, y, val)
	end
end

local checkedGrid = object:new()

function checkedGrid:init(g)
	self.g = g
end
function checkedGrid:__index(x)
	if type(x) == "number" then
		return checkedGridColumn:new(self.g, x)
	elseif rawget(self, x) then
		return rawget(self, x)
	elseif checkedGrid[x] then
		return checkedGrid[x]
	else
		return self.g[x]
	end
end

function grid:new(...)
	local o = object.new(grid, ...)
	o:clear()

	if DEBUG_ASSERTS then
		return checkedGrid:new(o)
	else
		return o
	end
end

function grid:init(width, height, default)
	self.width = width
	self.height = height
	self.default = default
end

function grid:clear()
	for x = 1,self.width do
		self[x] = {}
		for y = 1,self.height do
			self[x][y] = self.default
		end
	end
end

function grid:row(y)
	local result = list:new()

	for x = 1,self.width do
		result:insert(self[x][y])
	end

	return result
end

function grid:col(x)
	local result = list:new()

	for y = 1,self.height do
		result:insert(self[x][y])
	end

	return result
end

interval = object:new()

function interval:init(length)
	self.length = length
	self.elapsed = 0
end

function interval:resize(length)
	self.length = length
end

function interval:increment(dt)
	if self.stopped then return false end

	self.elapsed = self.elapsed + dt
end

function interval:firing()
	if self.paused or self.stopped then return false end

	if self.elapsed >= self.length then
		self.elapsed = 0
		return true
	end

	return false
end

function interval:pause()
	self.paused = true
end

function interval:stop()
	self.stopped = true
end

function interval:start()
	self.stopped = false
	self.paused = false
end

function interval:reset()
	self.elapsed = 0
end

linearTransition = object:new()

function linearTransition:init(length)
	self.length = length
	self.elapsed = 0
end

function linearTransition:increment(dt)
	self.elapsed = math.min(self.elapsed + dt, self.length)
end

function linearTransition:range(min, max)
	return min + (max - min) * self.elapsed / self.length
end

--- A clickable/touchable button.
--
-- All coordinates are given as positive/negative fractions of the screen.
button = object:new()

function button:init(x, y, width, height, handler)
	self.x = x
	self.y = y
	self.width = width
	self.height = height
	self.handler = handler
end

function button:within(x, y)
	if x < self.x or x >= self.x + self.width or y < self.y or y >= self.y + self.height then
		return false
	end

	return true
end

function button:pressed()
	self.handler()
end
