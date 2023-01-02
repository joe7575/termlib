--[[
	termlib
	=======

	Copyright (C) 2022-2023 Joachim Stolberg

	GPL v3
	See LICENSE.txt for more information

	Backend for the TechAge Lua Controller
]]--

local M = minetest.get_meta
local term = termlib.term

local orig_send_to_cpu = term.send_to_cpu

term.send_to_cpu = function(self,pos, mem, cpu_pos, node, command)
	if node.name == "techage:ta4_lua_controller" then
		local number = techage.get_node_number(cpu_pos)
		if number then
			return techage.send_single(0, number, "term", command)
		else
			term:add_line(pos, mem, "Target block has no techage number")
			return false
		end
	else
		return orig_send_to_cpu(self, pos, mem, cpu_pos, node, command)
	end
end

term:register_command("@send",
	"- Send a TA command with '@send <num> <cmd> [<data>]'\n    Example: @send 1234 on",
	function(self, pos, mem, cmnd, param)
		if param then
			local owner = M(pos):get_string("owner")
			local num, cmnd, payload = param:match('^([0-9]+)%s+(%w+)%s*(.*)$')
			if num and cmnd then
				if techage.not_protected(num, owner) then
					local resp = techage.send_single("0", num, cmnd, payload)
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
		{"", "techage:ta4_terminal", ""},
		{"", "techage:ta4_ramchip", ""},
		{"", "", ""},
	},
})

