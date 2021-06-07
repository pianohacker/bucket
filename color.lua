-- Copyright (c) Jesse Weaver, 2021
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

module("color", package.seeall)

local function foldNanToZero(x)
	if x ~= x then
		return 0
	end

	return x
end

-- Standard illuminant D65
-- XYZ must be [0, 1] for rgb conversion
local Xr = 95.0489 / 100
local Yr = 100 / 100
local Zr = 108.8840 / 100
local u0 = (4*Xr) / (Xr + 15*Yr + 3*Zr)
local v0 = (9*Yr) / (Xr + 15*Yr + 3*Zr)

-- From http://www.brucelindbloom.com/index.html?Eqn_RGB_XYZ_Matrix.html
-- For sRGB
local M11, M12, M13 =  3.2404542, -1.5371385, -0.4985314
local M21, M22, M23 = -0.9692660,  1.8760108,  0.0415560
local M31, M32, M33 =  0.0556434, -0.2040259,  1.0572252

local gamma_inv = 1/2.2

-- Thanks to http://www.brucelindbloom.com/index.html?Math.html
local eps = 216/24389
local kappa = 24389/27
--- Translates CIELCHuv to sRGB.
function cielchToRgb(L, C, H)
	-- LCHuv -> Luv
	H = math.rad(H)
	local u = C * math.cos(H)
	local v = C * math.sin(H)

	-- Luv -> XYZ
	local Y
	if L > kappa * eps then
		Y = ((L+16)/116)^3
	else
		Y = L/kappa
	end

	local a = foldNanToZero((((52*L) / (u + 13*L*u0) - 1))/3)
	local b = -5*Y
	local c = -1/3
	local d = foldNanToZero(Y * ((39*L) / (v+13*L*v0) - 5))

	local X = (d-b) / (a-c)
	local Z = X*a + b

	-- XYZ -> Linear srgb
	local r = M11 * X + M12 * Y + M13 * Z
	local g = M21 * X + M22 * Y + M23 * Z
	local b_ = M31 * X + M32 * Y + M33 * Z

	-- Linear srgb -> sRGB
	local R = math.floor(math.pow(r, gamma_inv) * 255 + 0.5)
	local G = math.floor(math.pow(g, gamma_inv) * 255 + 0.5)
	local B = math.floor(math.pow(b_, gamma_inv) * 255 + 0.5)

	print()
	common.dump("L", "C", "H")
	common.dump("a", "b", "c", "d")
	common.dump("X", "Y", "Z")
	common.dump("r", "g", "b_")
	common.dump("R", "G", "B")
	print()

	return string.format("#%02X%02X%02X", R, G, B)
end

--- Translates CIELCHab to sRGB.
function cielchabToRgb(L, C, H)
	-- LCHab -> Lab
	H = math.rad(H)
	local a = C * math.cos(H)
	local b = C * math.sin(H)

	-- Lab -> XYZ
	local fy = (L + 16) / 116
	local fx = a/500 + fy
	local fz = fy - b/200

	local xr = math.pow(fx, 3)
	if xr <= eps then
		xr = (116 * fz - 16) / kappa
	end

	local yr
	if L > kappa * eps then
		yr = math.pow((L + 16)/116, 3)
	else
		yr = L/kappa
	end

	local zr = math.pow(fz, 3)
	if zr <= eps then
		zr = (116 * fz - 16) / kappa
	end

	local X = Xr * xr
	local Y = Yr * yr
	local Z = Zr * zr

	local r = M11 * X + M12 * Y + M13 * Z
	local g = M21 * X + M22 * Y + M23 * Z
	local b_ = M31 * X + M32 * Y + M33 * Z

	local R = math.floor(math.pow(r, gamma_inv) * 255 + 0.5)
	local G = math.floor(math.pow(g, gamma_inv) * 255 + 0.5)
	local B = math.floor(math.pow(b_, gamma_inv) * 255 + 0.5)

	return string.format("#%02X%02X%02X", R, G, B)
end
