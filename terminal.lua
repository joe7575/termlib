--[[
	termlib
	=======

	Copyright (C) 2022-2023 Joachim Stolberg

	GPL v3
	See LICENSE.txt for more information

	Library for text terminal implementations
]]--

local M = minetest.get_meta
local P2S = function(pos) if pos then return minetest.pos_to_string(pos) end end
local S2P = minetest.string_to_pos

local term = termlib.Term:new({
	size_x = 60,
	size_y = 20,
	text_color = "#FFFFFF",
	background_color = "#25516C",
})

if minetest.global_exists("techage") then
	term:register_command("@connect", 
		"- Connect to a CPU/machine with '@connect <number>'",
		function(self, pos, nvm, cmnd, number)
			if number then
				local owner = M(pos):get_string("owner")
				if techage.not_protected(number, owner, owner) then
					local info = techage.get_node_info(number)
					if info and info.name == "techage:ta4_lua_controller" then
						M(pos):set_string("connected_to", number)
						M(info.pos):set_string("terminal_pos", P2S(pos))
						term:add_line(pos, nvm, "Connected.")
						nvm.trm_connected = true
					else
						M(pos):set_string("connected_to", "")
						term:add_line(pos, nvm, "Not connected.")
						nvm.trm_connected = nil
					end
				else
					term:add_line(pos, nvm, "Protection error!")
				end
			end
		end)
	term:register_command("@disconnect", 
		"- Disconnect from a block with '@disconnect'",
		function(self, pos, nvm, cmnd)
			M(pos):set_string("connected_to", "")
			term:add_line(pos, nvm, "Not connected.")
			nvm.trm_connected = nil
		end)
	term:register_command("@send", 
		"- Send a TA command with '@send <num> <cmd> [<data>]'\n    Example: @send 1234 on",
		function(self, pos, nvm, cmnd, param)
			if param then
				local owner = M(pos):get_string("owner")
				local num, cmnd, payload = param:match('^([0-9]+)%s+(%w+)%s*(.*)$')
				if num and cmnd then
					if techage.not_protected(num, owner) then
						local resp = techage.send_single("0", num, cmnd, payload)
						if type(resp) == "string" then
							term:add_line(pos, nvm, resp)
						else
							term:add_line(pos, nvm, dump(resp))
						end
					else
						term:add_line(pos, nvm, "Destination block is protected")
					end
				else
					term:add_line(pos, nvm, "Syntax error!")
				end
			end
		end)
end

local function formspec(pos)
	local nvm = techage.get_nvm(pos)
	return "formspec_version[4]" ..
		"size[12.8,10.5]" ..
		term:fs_size_buttons(pos, nvm, 10.6, 0.1) ..
		term:fs_window(pos, nvm, 0.4, 0.8) ..
		term:fs_input_with_function_keys(pos, nvm, 0.4, 8.6)
end


local function command_handler(self, pos, nvm, command)
	--print("command_handler", dump(command))
	if nvm.trm_connected then
		local number = M(pos):get_string("connected_to")
		techage.send_single(0, number, "term", command)
	else
		term:add_line(pos, nvm, "$ " .. command)
	end
end

-- Post register the command handler
term.external_commands = command_handler

minetest.register_node("termlib:terminal1", {
	description = "Termlib Terminal",
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

	after_place_node = function(pos, placer)
		local nvm = techage.get_nvm(pos)
		local meta = M(pos)
		term:init_block(pos, nvm)
		meta:set_string("formspec", formspec(pos))
		meta:set_string("owner", placer:get_player_name())
		meta:set_string("infotext", "Termlib Terminal")
	end,

	on_receive_fields = function(pos, formname, fields, player)
		local nvm = techage.get_nvm(pos)
		term:on_receive_fields(pos, fields, player, nvm)
		M(pos):set_string("formspec", formspec(pos))
	end,
	
	on_rightclick = function(pos, node, clicker)
		local nvm = techage.get_nvm(pos)
		term:trigger_ttl(pos, nvm)
		M(pos):set_string("formspec", formspec(pos))
	end,
	
	after_dig_node = function(pos, oldnode, oldmetadata)
		local info = techage.get_node_info(oldmetadata.number)
		if info and info.name == "techage:ta4_lua_controller" then
			M(info.pos):set_string("terminal_pos", "")
		end
		techage.remove_node(pos, oldnode, oldmetadata)
		techage.del_mem(pos)
	end,

	paramtype = "light",
	use_texture_alpha = "clip",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	groups = {choppy=2, cracky=2, crumbly=2},
	is_ground_content = false,
	sounds = default.node_sound_metal_defaults(),
})

if minetest.global_exists("techage") then
	minetest.register_craft({
		output = "termlib:terminal1",
		recipe = {
			{"", "techage:ta4_display", ""},
			{"dye:black", "techage:ta4_wlanchip", "default:copper_ingot"},
			{"", "techage:aluminum", ""},
		},
	})

	techage.lua_ctlr.register_function("get_str", {
		cmnd = function(self)
			return techage.lua_ctlr.get_command(self.meta.number)
		end,
		help = ' $get_str()  --> text string or nil\n'..
			' Read an entered string (command) from the Terminal.\n'..
			' example: s = $get_str()\n'..
			" The Terminal has to be connected to the controller."
	})


	techage.lua_ctlr.register_action("put_str", {
		cmnd = function(self, text)
			text = tostring(text or "")
			local pos = S2P(M(self.meta.pos):get_string("terminal_pos"))
			local nvm = techage.get_nvm(pos)
			if nvm.trm_connected then
				if term:put_string(pos, nvm, text) then
					M(pos):set_string("formspec", formspec(pos))
				end
			end
		end,
		help = " $put_str(text)\n"..
			' Send a text string to the terminal.\n'..
			' example: $put_str("Hello " .. name)'
	})
end

