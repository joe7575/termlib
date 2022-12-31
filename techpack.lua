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
local term = termlib.term

term:register_command("@connect", 
	"- Connect to a CPU/machine with '@connect <number>'",
	function(self, pos, mem, cmnd, number)
		if number then
			if tubelib.check_numbers(number) then
				local info = tubelib.get_node_info(number)
				if info and info.name == "sl_controller:controller" then
					M(pos):set_string("connected_to", number)
					M(info.pos):set_string("terminal_pos", P2S(pos))
					term:add_line(pos, mem, "Connected.")
					mem.trm_connected = true
				else
					M(pos):set_string("connected_to", "")
					term:add_line(pos, mem, "Not connected.")
					mem.trm_connected = nil
				end
			else
				term:add_line(pos, mem, "Protection error!")
			end
		end
	end)

term:register_command("@disconnect", 
	"- Disconnect from a block with '@disconnect'",
	function(self, pos, mem, cmnd)
		M(pos):set_string("connected_to", "")
		term:add_line(pos, mem, "Not connected.")
		mem.trm_connected = nil
	end)

term:register_command("@send", 
	"- Send a TA command with '@send <num> <cmd> [<data>]'\n    Example: @send 1234 on",
	function(self, pos, mem, cmnd, param)
		if param then
			local owner = M(pos):get_string("owner")
			local num, cmnd, payload = param:match('^([0-9]+)%s+(%w+)%s*(.*)$')
			if num and cmnd then
				if techage.not_protected(num, owner) then
					local resp = tubelib.send_request(num, cmnd, payload)
					if type(resp) == "string" then
						term:add_line(pos, mem, resp)
					else
						term:add_line(pos, mem, dump(resp))
					end
				else
					term:add_line(pos, mem, "Destination block is protected")
				end
			else
				term:add_line(pos, mem, "Syntax error!")
			end
		end
	end)

local function command_handler(self, pos, mem, command)
	--print("command_handler", dump(command))
	if mem.trm_connected then
		local number = M(pos):get_string("connected_to")
		tubelib.send_request(number, "term", command)
	else
		term:add_line(pos, mem, "$ " .. command)
	end
end

-- Post register the command handler
term.external_commands = command_handler

sl_controller.register_function("get_str", {
	cmnd = function(self)
		return sl_controller.get_command(self.meta.number)
	end,
	help = ' $get_str()  --> text string or nil\n'..
		' Read an entered string (command) from the Terminal.\n'..
		' example: s = $get_str()\n'..
		" The Terminal has to be connected to the controller."
})


sl_controller.register_action("put_str", {
	cmnd = function(self, text)
		text = tostring(text or "")
		local pos = S2P(M(self.meta.pos):get_string("terminal_pos"))
		if pos then
			local mem = termlib.get_mem(pos)
			if mem.trm_connected then
				if term:put_string(pos, mem, text) then
					M(pos):set_string("formspec", termlib.formspec(pos))
				end
			end
		end
	end,
	help = " $put_str(text)\n"..
		' Send a text string to the terminal.\n'..
		' example: $put_str("Hello " .. name)'
})

minetest.register_craft({
	output = "termlib:terminal1",
	recipe = {
		{"", "sl_controller:terminal", ""},
		{"", "techage:ta4_ramchip", ""},
		{"", "", ""},
	},
})

