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
termlib.S = minetest.get_translator("termlib")

local MP = minetest.get_modpath("termlib")

dofile(MP .. "/lib.lua")  -- Helper functions
dofile(MP .. "/api.lua")  -- Interface functions
dofile(MP .. "/commands.lua")  -- Internal commands
dofile(MP .. "/terminal.lua")  -- Example implementation

