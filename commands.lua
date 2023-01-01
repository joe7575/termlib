--[[
	termlib
	=======

	Copyright (C) 2022-2023 Joachim Stolberg

	GPL v3
	See LICENSE.txt for more information

	Local/internal terminal commands
]]--

-- for lazy programmers
local M = minetest.get_meta

local HELP = [[Escape Sequences:

 Chars            | Description
------------------+-------------------------------------
 \33\1            | Clear screen
 \33\2\<row>      | Set cursor to row <row> (1 - 20)
 \33\3\<font>     | 0 = normal, 1 = mono
 \n               | New line + Carriage Return
 \t               | Tab (8 chars)
 \r               | Carriage Return (rewrite line)
 \a               | bell (sound)
 \b               | Clear screen
]]

function termlib.register_internal_commands(self)
	self:register_command("@cls", 
		"- Clear screen with '@cls'",
		function(self, pos, mem, cmnd)
			self:clear_lines(pos, mem)
		end)
	self:register_command("@publ", 
		"- Switch to public mode with '@publ'",
		function(self, pos, mem, cmnd)
			M(pos):set_int("public", 2)
			self:add_line(pos, mem, "Switched to public mode!")
		end)
	self:register_command("@prot", 
		"- Switch to protected mode with '@prot'",
		function(self, pos, mem, cmnd)
			M(pos):set_int("public", 1)
			self:add_line(pos, mem, "Switched to protected mode!")
		end)
	self:register_command("@priv", 
		"- Switch to private mode with '@priv'",
		function(self, pos, mem, cmnd)
			M(pos):set_int("public", 0)
			self:add_line(pos, mem, "Switched to private mode!")
		end)
	self:register_command("@set", 
		"- Program a function button with\n  '@set <button> <new-button-text> <command>'\n    Example: @set F1 CLS @cls",
		function(self, pos, mem, cmnd, payload)
			local bttn_num, label, cmd = payload:match('^F([1-8])%s+([%w_]+)%s+(.+)$')
			if bttn_num and label and cmnd then
				M(pos):set_string("bttn_text"..bttn_num, label)
				M(pos):set_string("bttn_cmnd"..bttn_num, cmd)
			else
				self:add_line(pos, mem, "Invalid syntax!")
			end
		end)
	self:register_command("@connect", 
		"- Connect to the CPU/machine/block with '@connect'",
		function(self, pos, mem, cmnd)
			local cpu_pos = termlib.get_cpu_pos(pos)
			if cpu_pos then
				termlib.set_terminal_pos(cpu_pos, pos)
				self:add_line(pos, mem, "Connected.")
				mem.trm_connected = true
			else
				self:add_line(pos, mem, "No valid CPU/machine/block position.")
				mem.trm_connected = nil
			end
		end)
	self:register_command("@disconnect", 
		"- Disconnect from the CPU/machine/block with '@disconnect'",
		function(self, pos, mem, cmnd)
			self:add_line(pos, mem, "Disconnected.")
			mem.trm_connected = nil
		end)
	self:register_command("@help", 
		"- Output further help with '@help'\n  see also': https://github.com/joe7575/termlib",
		function(self, pos, mem, cmnd)
			self:clear_lines(pos, mem)
			self:put_string(pos, mem, HELP)
		end)
end
