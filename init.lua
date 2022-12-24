--[[
	termlib
	=======

	Copyright (C) 2022-2023 Joachim Stolberg

	GPL v3
	See LICENSE.txt for more information

	Library for text terminal implementations
]]--

termlib = {}

-- Version for compatibility checks, see readme.md
termlib.version = 1.0

local MP = minetest.get_modpath("termlib")
dofile(MP.."/lib.lua")  -- helper functions
dofile(MP.."/api.lua")  -- interface functions

-- Only for testing/demo purposes
if minetest.settings:get_bool("termlib_testingblock_enabled") == true then
	dofile(MP .. "/terminals.lua")
end

