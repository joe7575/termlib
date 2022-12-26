--[[
	termlib
	=======

	Copyright (C) 2022-2023 Joachim Stolberg

	GPL v3
	See LICENSE.txt for more information

	Library for text terminal implementations
]]--

local M = minetest.get_meta
local storage = minetest.get_mod_storage()

local term = termlib.Term:new({
	size_x = 60,
	size_y = 20,
})

local Data = minetest.deserialize(storage:get_string("Data")) or {}
minetest.register_on_shutdown(function()
	storage:set_string("Data", minetest.serialize(Data))
end)


local function get_mem(pos)
	local hash = minetest.hash_node_position(pos)
	Data[hash] = Data[hash] or {}
	return Data[hash]
end

local function del_mem(pos)
	local hash = minetest.hash_node_position(pos)
	Data[hash] = nil
end


local function formspec1(pos)
	local mem = get_mem(pos)
	return "formspec_version[4]" ..
		"size[12.8,12]" ..
		term:fs_user_buttons(pos, mem, 0.4, 0.4) ..
		term:fs_size_buttons(pos, mem, 11.2, 0.4) ..
		term:fs_window(pos, mem, 0.4, 2.4) ..
		term:fs_input_with_function_keys(pos, mem, 0.4, 10.1)
end

local function formspec2(pos)
	local mem = get_mem(pos)
	return "formspec_version[4]" ..
		"size[12.8,9.7]" ..
		term:fs_size_buttons(pos, mem, 11.2, 0.1) ..
		term:fs_window(pos, mem, 0.4, 0.8) ..
		term:fs_input(pos, mem, 0.4, 7.8)
end

local function command_handler(pos, mem, command)
	print("cmd: " .. command)
end

minetest.register_node("termlib:terminal1", {
	description = "Terminal1",
	tiles = {
		-- up, down, right, left, back, front
		'termlib_terminal1_top.png',
		'termlib_terminal1_bottom.png',
		'termlib_terminal1_side.png',
		'termlib_terminal1_side.png',
		'termlib_terminal1_bottom.png',
		"termlib_terminal1_front.png",
	},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-12/32, -16/32,  -8/32,  12/32, -14/32, 12/32},
			{-12/32, -14/32,  12/32,  12/32,   6/32, 14/32},
		},
	},
	selection_box = {
		type = "fixed",
		fixed = {
			{-12/32, -16/32,  -8/32,  12/32, -14/32, 12/32},
			{-12/32, -14/32,  12/32,  12/32,   6/32, 14/32},
		},
	},
	after_place_node = function(pos, placer)
		local mem = get_mem(pos)
		term:init_block(pos, mem)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", formspec1(pos))
		meta:set_string("owner", placer:get_player_name())
		meta:set_string("infotext","Termlib Terminal1")
	end,

	on_receive_fields = function(pos, formname, fields, player)
		local mem = get_mem(pos)
		term:on_receive_fields(pos, formname, fields, player, mem, command_handler)
		M(pos):set_string("formspec", formspec1(pos))
	end,

	after_dig_node = function(pos, oldnode, oldmetadata)
		del_mem(pos)
	end,

	paramtype = "light",
	use_texture_alpha = "clip",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	stack_max = 1,
	groups = {choppy=2, cracky=2, crumbly=2},
	is_ground_content = false
})

minetest.register_node("termlib:terminal2", {
	description = "Terminal2",
	tiles = {
		-- up, down, right, left, back, front
		'termlib_terminal2_top.png',
		'termlib_terminal2_side.png',
		'termlib_terminal2_side.png^[transformFX',
		'termlib_terminal2_side.png',
		'termlib_terminal2_back.png',
		"termlib_terminal2_front.png",
	},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-12/32, -16/32, -16/32,  12/32, -14/32, 16/32},
			{-12/32, -14/32,  -3/32,  12/32,   6/32, 16/32},
			{-10/32, -12/32,  14/32,  10/32,   4/32, 18/32},
			{-12/32,   4/32,  -4/32,  12/32,   6/32, 16/32},
			{-12/32, -16/32,  -4/32, -10/32,   6/32, 16/32},
			{ 10/32, -16/32,  -4/32,  12/32,   6/32, 16/32},
			{-12/32, -14/32,  -4/32,  12/32, -12/32, 16/32},
		},
	},
	selection_box = {
		type = "fixed",
		fixed = {
			{-12/32, -16/32, -4/32,  12/32, 6/32, 16/32},
		},
	},
	after_place_node = function(pos, placer)
		local mem = get_mem(pos)
		term:init_block(pos, mem)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", formspec2(pos))
		meta:set_string("owner", placer:get_player_name())
		meta:set_string("infotext","Termlib Terminal2")
	end,

	on_receive_fields = function(pos, formname, fields, player)
		local mem = get_mem(pos)
		term:on_receive_fields(pos, formname, fields, player, mem, command_handler)
		M(pos):set_string("formspec", formspec2(pos))
	end,

	after_dig_node = function(pos, oldnode, oldmetadata)
		del_mem(pos)
	end,

	paramtype = "light",
	use_texture_alpha = "clip",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	stack_max = 1,
	groups = {choppy=2, cracky=2, crumbly=2},
	is_ground_content = false
})

minetest.register_node("termlib:terminal3", {
	description = "Terminal3",
	tiles = {
		-- up, down, right, left, back, front
		'termlib_terminal3_top.png',
		'termlib_terminal3_top.png',
		'termlib_terminal3_side.png',
		'termlib_terminal3_side.png',
		'termlib_terminal3_side.png',
		"termlib_terminal3_front.png",
	},
	after_place_node = function(pos, placer)
		local mem = get_mem(pos)
		term:init_block(pos, mem)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", formspec1(pos))
		meta:set_string("owner", placer:get_player_name())
		meta:set_string("infotext","Termlib Terminal3")
	end,

	on_receive_fields = function(pos, formname, fields, player)
		local mem = get_mem(pos)
		term:on_receive_fields(pos, formname, fields, player, mem, command_handler)
		M(pos):set_string("formspec", formspec1(pos))
	end,

	after_dig_node = function(pos, oldnode, oldmetadata)
		del_mem(pos)
	end,

	paramtype2 = "facedir",
	stack_max = 1,
	groups = {choppy=2, cracky=2, crumbly=2},
	is_ground_content = false
})

