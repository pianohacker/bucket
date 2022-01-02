-- Copyright (c) Jesse Weaver, 2021
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

module("std", package.seeall)

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

--- Basic prototype-OOP base object. 
object = {}
--- Make a child of this object without any changes.
function object:clone()
	return self:extend({})
end

--- Make a child of this object with extra fields.
-- All special metatable keys (__index, __add, etc.) can be set on the object or any of its parents
-- and will be copied to the resulting object's metatable.
--
-- The metatable will also have an extra key, _parent, pointing to the parent object.
--
-- @param o Either a table of extra fields to be added to the resulting object, or a function that
-- will be called with the object before it is returned.
function object:extend(o)
	local constructor = nil

	if type(o) == 'function' then
		constructor = o
		o = {}
	else
		o = o or {}
	end

	local function child__index(child, key)
		if key ~= '__index' and child.__index then
			local value = child:__index(key)

			if value ~= nil then
				return value
			end
		end

		if self[key] ~= nil then
			return self[key]
		end
	end
	-- First, set a bare metatable that can walk up the chain...
	setmetatable(o, {__index = child__index})

	-- Then, pull in any magic methods from the resulting object.
	setmetatable(o, {
		__add = o.__add,
		__sub = o.__sub,
		__mul = o.__mul,
		__div = o.__div,
		__mod = o.__mod,
		__pow = o.__pow,
		__unm = o.__unm,
		__concat = o.__concat,
		__len = o.__len,
		__eq = o.__eq,
		__lt = o.__lt,
		__le = o.__le,
		__index = child__index,
		__newindex = o.__newindex,
		__call = o.__call,
		_parent = self,
	})

	-- Finally, call the constructor if any.
	if constructor then
		constructor(o)
	end

	return o
end

--- Returns true if this object is the same as o, or inherits from o.
function object:inherits(o)
	local obj = self

	while obj ~= nil do
		if obj == o then
			return true
		end

		obj = (getmetatable(obj) or {})._parent
	end

	return false
end

local function memoizedBase(keyFunc, func, getKeysAndVals, setKeysAndVals)
	return function(...)
		local key = {keyFunc(...)}
		local keyMatches = true

		local lastKey, lastVals = getKeysAndVals(...)
		for i, x in ipairs(key) do
			if lastKey[i] ~= x then
				keyMatches = false
				break
			end
		end

		if not keyMatches then
			lastKey = key
			local args = list:fromTable({...})
			args:insertAll(key)
			lastVals = {func(unpack(args))}
			setKeysAndVals(lastKey, lastVals, ...)
		end

		return unpack(lastVals)
	end
end

--- Create a function memoized against the given key function.
-- `func` will be called only once, and its result cached, as long as the result of `keyFunc` does
-- not change.
function memoized(keyFunc, func)
	local lastKey = {}
	local lastVals

	return memoizedBase(
		keyFunc,
		func,
		function() return lastKey, lastVals end,
		function(k, v)
			lastKey = k
			lastVals = v
		end
	)
end

--- Create a member function memoized against the given key function.
-- Similar to `memoized`, but results are cached per-object.
function memoizedMember(keyFunc, func)
	local lastKeys = {}
	local lastVals = {}

	return memoizedBase(
		keyFunc,
		func,
		function(self)
			return lastKeys[self] or {}, lastVals[self]
		end,
		function(k, v, self)
			lastKeys[self] = k
			lastVals[self] = v
		end
	)
end

--- Light wrapper around list tables.
list = object:clone()
list.concat = table.concat
list.insert = table.insert
list.maxn = table.maxn
list.remove = table.remove
list.sort = table.sort

--- Creates a list from the given table.
function list:fromTable(t)
	local o = {}

	for i, x in ipairs(t) do
		o[i] = x
	end

	return self:extend(o)
end

--- Returns an iterator over the values of the list.
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

--- Returns true if all members of the list are true.
function list:all()
	for x in self:values() do
		if not x then
			return false
		end
	end

	return true
end

--- Shuffles the list in-place.
function list:shuffle()
	for i = 1,#self do
		local j = love.math.random(i, #self)

		local x = self[i]
		self[i] = self[j]
		self[j] = x
	end
end

--- Reverses the list in-place.
function list:reverse()
	for i = 1,math.floor(#self/2) do
		local j = #self - i + 1

		local x = self[i]
		self[i] = self[j]
		self[j] = x
	end
end

--- Appends all elements from the given list/table to the list.
function list:insertAll(t)
	for _, x in ipairs(t) do
		self:insert(x)
	end
end

--- Removes all elements.
function list:removeAll()
	for i = 1,#self do
		self[i] = nil
	end
end

--- 2D grid of a fixed size.
-- If `DEBUG_ASSERTS` is true, will check bounds on all accesses.
grid = object:clone()

local function newCheckedGridColumn(g, x)
	return object:extend({
		_checkCoords = function(self, y, op)
			if x < 1 or x > g.width or y < 1 or y > g.height then
				error(string.format("attempt to %s grid at out-of-bounds (%d, %d)", op, x, y), 3)
			end
		end,

		__index = function(self, y)
			if type(y) == "number" then
				self:_checkCoords(y, "get")
				return g[x][y]
			end
		end,

		__newindex = function(self, y, val)
			if type(y) == "number" then
				self:_checkCoords(y, "set")
				g[x][y] = val
			else
				rawset(self, y, val)
			end
		end,
	})
end


function newCheckedGrid(g)
	local ncg = object:extend({
		__index = function(_, x)
			if type(x) == "number" then
				return newCheckedGridColumn(g, x)
			else
				return g[x]
			end
		end,

		clear = function(_)
			g:clear()
		end,
	})
	return ncg
end

function grid:new(width, height, default)
	local o = self:extend({
		width = width,
		height = height,
		default = default,
	})
	o:clear()

	if DEBUG_ASSERTS then
		return newCheckedGrid(o)
	else
		return o
	end
end

function grid:clear()
	for x = 1,self.width do
		self[x] = {}
		for y = 1,self.height do
			self[x][y] = self.default
		end
	end
end

--- Returns all values in the given row as a `list`.
function grid:row(y)
	local result = list:clone()

	for x = 1,self.width do
		result:insert(self[x][y])
	end

	return result
end

--- Returns all values in the given column as a `list`.
function grid:col(x)
	local result = list:clone()

	for y = 1,self.height do
		result:insert(self[x][y])
	end

	return result
end
