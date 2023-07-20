--[[
	termlib
	=======

	Copyright (C) 2022-2023 Joachim Stolberg

	GPL v3
	See LICENSE.txt for more information

	Library for text terminal implementations
]]--

local M = minetest.get_meta

local term = termlib.Term:new({
	size_x = 120,
	size_y = 20,
	text_color = "#FFFFFF",
	background_color = "#25516C",
})
termlib.term = term

function termlib.formspec(pos)
	local mem = termlib.get_mem(pos)
	return "formspec_version[4]" ..
		"size[12.8,10.5]" ..
		term:fs_size_buttons(pos, mem, 10.6, 0.1) ..
		term:fs_window(pos, mem, 0.4, 0.8) ..
		term:fs_input_with_function_keys(pos, mem, 0.4, 8.6)
end

minetest.register_node("termlib:terminal1", {
	description = "Termlib Terminal\n(left-click to preconnect to CPU)",
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
	node_box = 	{
		type = "fixed",
		fixed = {
			{-12/32, -16/32, -12/32,   12/32, -14/32,  0/32},  -- keyboard
			{-12/32,  -8/32,   8/32,   12/32,  12/32, 10/32},  -- screen
			{-1/32,  -16/32,  10/32,    1/32,   4/32, 12/32},  -- neck
			{-8/32,  -16/32,   4/32,    8/32, -15/32, 14/32},  -- base
		},
	},
	selection_box = {
		type = "fixed",
		fixed = {
			{-12/32, -16/32, -12/32,   12/32, -14/32,  0/32},  -- keyboard
			{-12/32,  -8/32,   8/32,   12/32,  12/32, 10/32},  -- screen
		},
	},

	after_place_node = function(pos, placer, itemstack)
		local mem = termlib.get_mem(pos)
		local meta = M(pos)
		term:init_block(pos, mem)
		termlib.preserve_cpu_pos(pos, itemstack)
		meta:set_string("formspec", termlib.formspec(pos))
		meta:set_string("owner", placer:get_player_name())
		meta:set_string("infotext", "Termlib Terminal")
	end,

	on_use = function(itemstack, user, pointed_thing)
		if pointed_thing.type == "node" then
			local name = user and user:get_player_name()
			local cpu_pos = pointed_thing.under
			if not user or minetest.is_protected(cpu_pos, user:get_player_name()) then
				minetest.chat_send_player(name, "[termlib] Position protected!")
				return
			end
			termlib.set_cpu_pos(itemstack, cpu_pos)

			local node = minetest.get_node(cpu_pos)
			local ndef = minetest.registered_nodes[node.name] or {}
			local desc = ndef.description or "unknown"
			minetest.chat_send_player(name, "[termlib] Preconnected to " .. desc)
		end
		return itemstack
	end,

	on_receive_fields = function(pos, formname, fields, player)
		local mem = termlib.get_mem(pos)
		term:on_receive_fields(pos, fields, player, mem)
		M(pos):set_string("formspec", termlib.formspec(pos))
	end,

	on_rightclick = function(pos, node, clicker)
		local mem = termlib.get_mem(pos)
		term:trigger_ttl(pos, mem)
		M(pos):set_string("formspec", termlib.formspec(pos))
	end,

	after_dig_node = function(pos, oldnode, oldmetadata)
		termlib.del_mem(pos)
	end,

	paramtype = "light",
	use_texture_alpha = "clip",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	groups = {choppy=2, cracky=2, crumbly=2},
	is_ground_content = false,
	sounds = default.node_sound_metal_defaults(),
})
