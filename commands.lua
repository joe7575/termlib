--[[
	termlib
	=======

	Copyright (C) 2022-2023 Joachim Stolberg

	GPL v3
	See LICENSE.txt for more information

	Library for text terminal implementations
]]--

-- for lazy programmers
local M = minetest.get_meta
local P2S = function(pos) if pos then return minetest.pos_to_string(pos) end end
local S2P = minetest.string_to_pos


function termlib.register_internal_commands(self)
	self:register_command("@cls", 
		"- Clear screen with '@cls'",
		function(self, pos, meta, mem, cmnd)
			self:clear_lines(pos, mem)
		end)
	self:register_command("@help", 
		"- Output this message with '@help'",
		function(self, pos, meta, mem, cmnd)
			self:clear_lines(pos, mem)
			self:put_string(pos, mem, table.concat(self.help_text, "\n"))
		end)
	self:register_command("@publ", 
		"- Switch to public mode with '@publ'",
		function(self, pos, meta, mem, cmnd)
			meta:set_int("public", 2)
			self:add_line(pos, mem, "Switched to public mode!")
		end)
	self:register_command("@prot", 
		"- Switch to protected mode with '@prot'",
		function(self, pos, meta, mem, cmnd)
			meta:set_int("public", 1)
			self:add_line(pos, mem, "Switched to protected mode!")
		end)
	self:register_command("@priv", 
		"- Switch to private mode with '@priv'",
		function(self, pos, meta, mem, cmnd)
			meta:set_int("public", 0)
			self:add_line(pos, mem, "Switched to private mode!")
		end)
	self:register_command("@set", 
		"- Program a function button with\n  '@set <button> <new-button-text> <command>'\n    Example: @set F1 CLS @cls",
		function(self, pos, meta, mem, cmnd)
			local bttn_num, label, cmd = cmnd:match('^@set%s+F([1-9])%s+([%w_]+)%s+(.+)$')
			if bttn_num and label and cmnd then
				meta:set_string("bttn_text"..bttn_num, label)
				meta:set_string("bttn_cmnd"..bttn_num, cmnd)
			else
				self:add_line(pos, mem, "Invalid syntax!")
			end
		end)
end
