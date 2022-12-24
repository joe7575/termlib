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
	size_x = 60,
	size_y = 20,
})

local Cache = {}    -- [hash] = {}

local function get_mem(pos)
	local hash = minetest.hash_node_position(pos)
	Cache[hash] = Cache[hash] or {}
	return Cache[hash]
end

local function del_mem(pos)
	local hash = minetest.hash_node_position(pos)
	Cache[hash] = nil
end

local HELP = [[        #### Test Terminal ####
Local commands (start with '@'):
- Clear screen with '@cls'
- Output this message with '@help'
- Switch to public use of buttons with '@pub'
- Switch to private use of buttons with '@priv'
- Program a user button with
  '@set <button-num> <button-text> <command>'
]]

local SYNTAX_ERR = "Syntax error, try help"

local function formspec(pos)
	local mem = get_mem(pos)
	return "formspec_version[4]" ..
		"size[14,12]" ..
		term:fs_user_buttons(pos, mem, 0.4, 0.4) ..
		term:fs_size_buttons(pos, mem, 12, 0) ..
		term:fs_window(pos, mem, 0.4, 2) ..
		term:fs_input_with_function_keys(pos, mem, 0.4, 10)
end

local function command(pos, command)
	local mem = get_mem(pos)
	local meta = minetest.get_meta(pos)

	command = command:sub(1,80)
	command = string.trim(command)
	local cmnd, data = command:match('^(%w+)%s*(.*)$')

	if cmnd == "@cls" then
		term:clear_lines(pos, mem)
		meta:set_string("formspec", formspec(pos))
	elseif cmnd == "" then
		output(pos, "$")
	elseif cmnd == "help" then
		if is_ta4 then
			output(pos, HELP_TA4)
		else
			output(pos, HELP_TA3)
		end
	elseif cmnd == "pub" then
		meta:set_int("public", 1)
		output(pos, "$ "..command)
		output(pos, "Switched to public buttons!")
	elseif cmnd == "priv" then
		meta:set_int("public", 0)
		output(pos, "$ "..command)
		output(pos, "Switched to private buttons!")
	elseif cmnd == "connect" and data then
		output(pos, "$ "..command)
		if techage.not_protected(data, owner, owner) then
			local own_num = meta:get_string("node_number")
			local resp = techage.send_single(own_num, data, cmnd)
			if resp then
				meta:set_string("connected_to", data)
				output(pos, "Connected.")
			else
				meta:set_string("connected_to", "")
				output(pos, "Not connected!")
			end
		else
			output(pos, "Protection error!")
		end
	else
		output(pos, "$ "..command)
		local own_num = meta:get_string("node_number")
		local connected_to = meta:contains("connected_to") and meta:get_string("connected_to")
		local bttn_num, label, num, cmnd, payload

		num, cmnd, payload = command:match('^cmd%s+([0-9]+)%s+(%w+)%s*(.*)$')
		if num and cmnd then
			if techage.not_protected(num, owner, owner) then
				local resp = techage.send_single(own_num, num, cmnd, payload)
				if type(resp) == "string" then
					output(pos, resp)
				else
					output(pos, dump(resp))
				end
			end
			return
		end

		num, cmnd = command:match('^turn%s+([0-9]+)%s+([onf]+)$')
		if num and (cmnd == "on" or cmnd == "off") then
			if techage.not_protected(num, owner, owner) then
				local resp = techage.send_single(own_num, num, cmnd)
				output(pos, dump(resp))
			end
			return
		end

		bttn_num, label, cmnd = command:match('^set%s+([1-9])%s+([%w_]+)%s+(.+)$')
		if bttn_num and label and cmnd then
			meta:set_string("bttn_text"..bttn_num, label)
			meta:set_string("bttn_cmnd"..bttn_num, cmnd)
			meta:set_string("formspec", formspec2(meta))
			return
		end

		if server_debug(pos, command, player) then
			return
		end

		if connected_to then
			local cmnd, payload = command:match('^(%w+)%s*(.*)$')
			if cmnd then
				local resp = techage.send_single(own_num, connected_to, cmnd, payload)
				if resp ~= true then
					if type(resp) == "string" then
						output(pos, resp)
					else
						output(pos, dump(resp))
					end
				end
				return
			end
		end

		if command ~= "" then
			output(pos, SYNTAX_ERR)
		end
	end
end

local function register_terminal(name, description, tiles, node_box, selection_box)
	minetest.register_node("termlib:"..name, {
		description = description,
		tiles = tiles,
		drawtype = "nodebox",
		node_box = node_box,
		selection_box = selection_box,

		after_place_node = function(pos, placer)
			local mem = get_mem(pos)
			term:init_block(pos, mem)
			local meta = minetest.get_meta(pos)
			meta:set_string("formspec", formspec(pos))
		end,

		on_receive_fields = function(pos, formname, fields, player)
			local meta = minetest.get_meta(pos)
			local public = meta:get_int("public") == 1
			local protected = minetest.is_protected(pos, player:get_player_name())

			if public or not protected then
				local evt = minetest.explode_table_event(fields.output)
				if evt.type == "DCL" then
					local s = get_line_text(pos, evt.row)
					meta:set_string("command", s)
					meta:set_string("formspec", formspec2(meta))
					return
				elseif (fields.ok or fields.key_enter_field) and fields.cmnd then
					local is_ta4 = string.find(description, "TA4")
					command(pos, fields.cmnd, player:get_player_name(), is_ta4)
					techage.historybuffer_add(pos, fields.cmnd)
					meta:set_string("command", "")
					meta:set_string("formspec", formspec2(meta))
					return
				elseif fields.key_up then
					meta:set_string("command", techage.historybuffer_priv(pos))
					meta:set_string("formspec", formspec2(meta))
					return
				elseif fields.key_down then
					meta:set_string("command", techage.historybuffer_next(pos))
					meta:set_string("formspec", formspec2(meta))
					return
				end
			end
			if public or not protected then
				if fields.bttn1 then send_cmnd(pos, meta, 1)
				elseif fields.bttn2 then send_cmnd(pos, meta, 2)
				elseif fields.bttn3 then send_cmnd(pos, meta, 3)
				elseif fields.bttn4 then send_cmnd(pos, meta, 4)
				elseif fields.bttn5 then send_cmnd(pos, meta, 5)
				elseif fields.bttn6 then send_cmnd(pos, meta, 6)
				elseif fields.bttn7 then send_cmnd(pos, meta, 7)
				elseif fields.bttn8 then send_cmnd(pos, meta, 8)
				elseif fields.bttn9 then send_cmnd(pos, meta, 9)
				end
			end
		end,

		after_dig_node = function(pos, oldnode, oldmetadata)
			techage.remove_node(pos, oldnode, oldmetadata)
		end,

		paramtype = "light",
		use_texture_alpha = techage.CLIP,
		sunlight_propagates = true,
		paramtype2 = "facedir",
		groups = {choppy=2, cracky=2, crumbly=2},
		is_ground_content = false,
		sounds = default.node_sound_metal_defaults(),
	})
end

register_terminal("terminal2", S("TA3 Terminal"), {
		-- up, down, right, left, back, front
		'termlib_terminal2_top.png',
		'termlib_terminal2_side.png',
		'termlib_terminal2_side.png^[transformFX',
		'termlib_terminal2_side.png',
		'termlib_terminal2_back.png',
		"termlib_terminal2_front.png",
	},
	{
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
	{
		type = "fixed",
		fixed = {
			{-12/32, -16/32, -4/32,  12/32, 6/32, 16/32},
		},
	}
)

register_terminal("terminal3", S("TA4 Terminal"), {
		-- up, down, right, left, back, front
		'termlib_terminal1_top.png',
		'termlib_terminal1_bottom.png',
		'termlib_terminal1_side.png',
		'termlib_terminal1_side.png',
		'termlib_terminal1_bottom.png',
		"termlib_terminal1_front.png",
	},
	{
		type = "fixed",
		fixed = {
			{-12/32, -16/32,  -8/32,  12/32, -14/32, 12/32},
			{-12/32, -14/32,  12/32,  12/32,   6/32, 14/32},
		},
	},
	{
		type = "fixed",
		fixed = {
			{-12/32, -16/32,  -8/32,  12/32, -14/32, 12/32},
			{-12/32, -14/32,  12/32,  12/32,   6/32, 14/32},
		},
	}
)
