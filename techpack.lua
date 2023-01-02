--[[
	termlib
	=======

	Copyright (C) 2022-2023 Joachim Stolberg

	GPL v3
	See LICENSE.txt for more information

	Backend for the TechPack SaferLua Controller
]]--

local M = minetest.get_meta
local term = termlib.term

local orig_send_to_cpu = term.send_to_cpu

term.send_to_cpu = function(self,pos, mem, cpu_pos, node, command)
	if node.name == "sl_controller:controller" then
		local number = tubelib.get_node_number(cpu_pos)
		if number then
			return tubelib.send_request(number, "term", command)
		else
			term:add_line(pos, mem, "Target block has no tubelib number")
			return false
		end
	else
		return orig_send_to_cpu(self, pos, mem, cpu_pos, node, command)
	end
end

sl_controller.register_function("get_str", {
	cmnd = function(self)
		return sl_controller.get_command(self.meta.number)
	end,
	help = ' $get_str()  --> text string or nil\n'..
		' Read an entered string (command) from the terminal.\n'..
		' example: s = $get_str()\n'..
		" The terminal has to be connected to the controller."
})


sl_controller.register_action("put_str", {
	cmnd = function(self, text)
		text = tostring(text or "")
		local term_pos = termlib.get_terminal_pos(self.meta.pos)
		if term_pos then
			local mem = termlib.get_mem(term_pos)
			if mem.trm_connected then
				if term:put_string(term_pos, mem, text) then
					M(term_pos):set_string("formspec", termlib.formspec(term_pos))
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

