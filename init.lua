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
termlib.version = 1.01
termlib.S = minetest.get_translator("termlib")

local MP = minetest.get_modpath("termlib")

dofile(MP .. "/lib.lua")  -- Helper functions
dofile(MP .. "/api.lua")  -- Interface functions
dofile(MP .. "/commands.lua")  -- Internal commands
dofile(MP .. "/terminal.lua")  -- Example implementation
if minetest.global_exists("techage") then
	dofile(MP .. "/techage.lua")  -- TechAge backend
end
if minetest.global_exists("sl_controller") then
	dofile(MP .. "/techpack.lua")  -- TechPack backend
end
if minetest.global_exists("beduino") then
	dofile(MP .. "/beduino.lua")  -- Beduino backend
end
