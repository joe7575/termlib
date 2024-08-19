--[[
	termlib
	=======

	Copyright (C) 2022-2023 Joachim Stolberg

	GPL v3
	See LICENSE.txt for more information

	Text terminal implementation and library
]]--

termlib.Term = {}
local Term = termlib.Term
local M = minetest.get_meta
local S = termlib.S

local SCREENSAVER_TIME = 60 * 5

local function insert_str(text, pos, str)
	return text:sub(1, pos - 1) .. str .. text:sub(pos + str:len(), -1)
end


function Term:new(attr)
	local o = {
		size_x = attr.size_x or 60,
		size_y = attr.size_y or 20,
		text_size = attr.text_size or 0,
		term_size = attr.term_size or "0,0;12,7.5",
		text_color = attr.text_color or "#FFFFFF",
		background_color = attr.background_color or "#000000",
		font = attr.font or "mono",
		history_enabled = attr.history_enabled or true,
		help_text = {S("Local commands:")},
		registered_commands = {},
	}
	setmetatable(o, self)
	self.__index = self
	termlib.register_internal_commands(o)
	return o
end

-- handler(self, pos, mem, cmnd, payload)
function Term:register_command(command, help_text, handler)
	self.registered_commands[command] = handler
	table.insert(self.help_text, help_text)
end

-- To be overwritten by real backend handlers, based on 'node.name'
-- self: Term instance
-- pos: terminal pos
-- mem: terminal block memory
-- cpu_pos: target pos
-- node: target node
-- str: string to be sent
function Term.send_to_cpu(self, pos, mem, cpu_pos, node, str)
	return false
end

function Term:init_block(pos, mem)
	mem.trm_lines = {}
	mem.trm_cursor_row = 1
	mem.trm_font = self.font
	mem.trm_ttl = 0
	M(pos):set_int("public", 0)
end

function Term:get_text(pos, mem)
	local t = {}
	mem.trm_lines = mem.trm_lines or {}
	for row = 1, self.size_y do
		local line = mem.trm_lines[row] or ""
		t[#t+1] = minetest.formspec_escape(line)
	end
	return table.concat(t, "\n")
end

function Term:clear_lines(pos, mem)
	for row = 1, self.size_y do
		mem.trm_lines[row] = ""
	end
	mem.trm_cursor_row = 1
end

function Term:new_line(pos, mem)
	mem.trm_cursor_row = mem.trm_cursor_row or 1
	if mem.trm_insert_pos then
		mem.trm_cursor_row = mem.trm_insert_row
		mem.trm_lines[mem.trm_cursor_row] = 
			insert_str(mem.trm_lines[mem.trm_cursor_row] or "", mem.trm_insert_pos, mem.trm_lines[0])
		mem.trm_lines[0] = ""
		mem.trm_insert_pos = nil
		mem.trm_insert_row = nil
	elseif mem.trm_cursor_row == 0 then
		local cmd = mem.trm_lines[0]
		mem.trm_lines[0] = ""
		mem.trm_cursor_row = 1
		self:command_handler(pos, mem, cmd)
	elseif mem.trm_cursor_row < self.size_y then
		mem.trm_cursor_row = mem.trm_cursor_row + 1
		return true
	else
		table.remove(mem.trm_lines, 1)
		return true
	end
end

function Term:set_cursor(pos, mem, row)
	row = math.min(row, self.size_y)
	mem.trm_cursor_row = row
end

function Term:ctrl_char(pos, mem, val)
	if val == 0 then
		return false
	elseif val == 7 then  -- bell ('\a')
		termlib.bell(pos, mem)
		return false
	elseif val == 8 then  -- clear screen ('\b')
		self:clear_lines(pos, mem)
		return true
	elseif val == 9 then  -- tab ('\t')
		mem.trm_cursor_row = mem.trm_cursor_row or 1
		local n = 8 - (#mem.trm_lines[mem.trm_cursor_row] % 8)
		for _ = 1,n do
			mem.trm_lines[mem.trm_cursor_row] = mem.trm_lines[mem.trm_cursor_row] .. " "
		end
		return false
	elseif val == 10 then  -- new line ('\n')
		if self:new_line(pos, mem) then
			mem.trm_lines[mem.trm_cursor_row] = ""
		end
		return mem.trm_suppressed ~= true
	elseif val == 13 then  -- carriage return ('\r')
		mem.trm_lines[mem.trm_cursor_row] = ""
		return false
	elseif val == 27 then  -- escape
		mem.trm_escaped = true
		return false
	end
end

function Term:escape_sequence(pos, mem, val)
	local putchar = function(mem, val)
		mem.trm_cursor_row = mem.trm_cursor_row or 1
		mem.trm_lines[mem.trm_cursor_row] = mem.trm_lines[mem.trm_cursor_row] .. string.char(val)
	end

	if not mem.trm_esc_cmnd then
		if val == 1 then
			self:clear_lines(pos, mem)
			mem.trm_escaped = false
			return true
		elseif val == 4 then
			mem.trm_cursor_row = 0
			mem.trm_lines[0] = ""
			mem.trm_escaped = false
		elseif val == 7 then
			mem.trm_cursor_row = math.max(mem.trm_cursor_row - 1, 1)
			mem.trm_lines[mem.trm_cursor_row] = ""
			mem.trm_escaped = false
		else
			mem.trm_esc_cmnd = val
			return false
		end
	elseif mem.trm_insert_pos then -- part of '\27\6\<pos>\<row>'
		mem.trm_insert_row = math.min(val, self.size_y)
		-- Use lines[0] to store the string
		mem.trm_cursor_row = 0
		mem.trm_lines[0] = ""
		mem.trm_esc_cmnd = nil
		mem.trm_escaped = nil
		return false
	else
		if mem.trm_esc_cmnd == 2 then
			mem.trm_cursor_row = math.min(val, self.size_y)
			mem.trm_lines[mem.trm_cursor_row] = ""
			mem.trm_esc_cmnd = nil
			mem.trm_escaped = nil
			return false
		elseif mem.trm_esc_cmnd == 3 then
			if val == 0 then
				mem.trm_font = "normal"
			else
				mem.trm_font = "mono"
			end
			mem.trm_esc_cmnd = nil
			mem.trm_escaped = nil
			return false
		elseif mem.trm_esc_cmnd == 5 then
			mem.trm_suppressed = (val == 1)
			mem.trm_esc_cmnd = nil
			mem.trm_escaped = nil
			return val == 2
		elseif mem.trm_esc_cmnd == 6 then
			mem.trm_insert_pos = math.min(val, self.size_x)
			return false
		else
			putchar(mem, 27)
			putchar(mem, mem.trm_esc_cmnd)
			putchar(mem, val)
			mem.trm_esc_cmnd = nil
			mem.trm_escaped = nil
			return false
		end
	end
end

function Term:trigger_ttl(pos, mem)
	mem.trm_ttl = minetest.get_gametime() + SCREENSAVER_TIME
end

function Term:timeout(mem)
	return mem.trm_ttl < minetest.get_gametime()
end

-- Function returns true, if screen needs to be updated
function Term:put_char(pos, mem, val)
	--print("put_char", val)
	if mem.trm_escaped then
		local res = self:escape_sequence(pos, mem, val)
		return mem.trm_ttl > minetest.get_gametime() and not mem.editing and res
	elseif val < 32 then
		local res = self:ctrl_char(pos, mem, val)
		return mem.trm_ttl and mem.trm_ttl > minetest.get_gametime() and not mem.editing and res
	else
		mem.trm_cursor_row = mem.trm_cursor_row or 1
		mem.trm_lines = mem.trm_lines or {}
                mem.trm_lines[mem.trm_cursor_row] = mem.trm_lines[mem.trm_cursor_row] or ""
		if #mem.trm_lines[mem.trm_cursor_row] < self.size_x then
			mem.trm_lines[mem.trm_cursor_row] = mem.trm_lines[mem.trm_cursor_row] .. string.char(val)
		end
		return false
	end
end

-- Function returns true, if screen needs to be updated
function Term:put_string(pos, mem, s)
	local res = false
	for i = 1, string.len(s) do
		local tmp = self:put_char(pos, mem, s:byte(i))
		res = res or tmp
	end
	return res
end

-- Function returns true, if screen needs to be updated
function Term:write_line(pos, mem, row, s)
	mem.trm_cursor_row =  math.min(row, self.size_y)
	mem.trm_lines = mem.trm_lines or {}
	mem.trm_lines[mem.trm_cursor_row] = ""
	return self:put_string(pos, mem, s)
end

function Term:add_line(pos, mem, s)
	mem.trm_lines = mem.trm_lines or {}
	self:new_line(pos, mem)
	mem.trm_lines[mem.trm_cursor_row] = ""
	return self:put_string(pos, mem, s)
end

function Term:get_char(pos, mem)
	local val = 0
	if mem.trm_input and mem.trm_input ~= "" then
		val = string.byte(mem.trm_input, 1)
		mem.trm_input = string.sub(mem.trm_input, 2)
	end
	return val
end

function Term:font_size(mem)
	mem.trm_text_size = mem.trm_text_size or self.text_size
	local font = mem.trm_font or self.font or "normal"
	return mem.trm_text_size >= 0 and "+" .. mem.trm_text_size or tostring(mem.trm_text_size)
end

function Term:fs_window(pos, mem, x, y)
	local font = mem.trm_font or self.font or "normal"
	local font_size = self:font_size(mem)
	local fs = {
		"container[", x, ",", y, "]",
		"box[", self.term_size, ";", self.background_color, "]",
		"style_type[textarea;font=", font, ";textcolor=", self.text_color,
		";border=false;font_size=", font_size, "]",
		"textarea[", self.term_size, ";;;", self:get_text(pos, mem), "]",
		"container_end[]"
	}
	return table.concat(fs, "")
end

function Term:fs_input(pos, mem, x, y, xoffs)
	local name = mem.editing and "command" or ""
	mem.trm_command = mem.trm_command or ""
	xoffs = xoffs or 0
	local fs = {
		"container[", x, ",", y, "]",
		"button[0.0,0.0;1.5,0.7;esc;ESC]",
		"button[1.5,0.0;1.5,0.7;edit;Edit]",
		"style_type[field;textcolor=#FFFFFF]",
		"field[3.1,0.0;", (5.78 + xoffs), ",0.7;", name, ";;",
		minetest.formspec_escape(mem.trm_command) .. "]",
		"button[", (9.0 + xoffs), ",0.0;1.5,0.7;enter;Enter]",
		"button_exit[", (10.5 + xoffs), ",0.0;1.5,0.7;close;Close]",
		"field_close_on_enter[command;false]",
		"container_end[]"
	}
	return table.concat(fs, "")
end

function Term:fs_input_with_function_keys(pos, mem, x, y, xoffs)
	local name = mem.editing and "command" or ""
	mem.trm_command = mem.trm_command or ""
	xoffs = xoffs or 0
	local fs = {
		"container[", x, ",", y, "]",
		termlib.func_key_bttns(pos, mem, 0.0, 0),
		"button[0.0,0.8;1.5,0.7;esc;ESC]",
		"button[1.5,0.8;1.5,0.7;edit;Edit]",
		"style_type[field;textcolor=#FFFFFF]",
		"field[3.1,0.8;", (5.78 + xoffs), ",0.7;", name, ";;",
		minetest.formspec_escape(mem.trm_command), "]",
		"button[", (8.0 + xoffs), ",0.8;1.5,0.7;enter;Enter]",
		"button_exit[", (10.5 + xoffs), ",0.8;1.5,0.7;close;Close]",
		"field_close_on_enter[command;false]",
		"container_end[]"
	}
	return table.concat(fs, "")
end

function Term:fs_size_buttons(pos, mem, x, y)
	local fs = {
		"container[", x, ",", y, "]",
		"button[0.0,0;0.6,0.6;larger;+]",
		"button[0.6,0;0.6,0.6;smaller;-]",
		"button[1.2,0;0.6,0.6;help;?]",
		"container_end[]"
	}
	return table.concat(fs, "")
end

function Term:command_handler(pos, mem, command)
	command = string.sub(command or "", 1, self.size_x)
	command = string.trim(command)
	local cmnd, payload = command:match('^([%w_@]+)%s*(.*)$')
	if self.registered_commands[cmnd] then
		self:add_line(pos, mem, "$ " .. command)
		self.registered_commands[cmnd](self, pos, mem, cmnd, payload)
		return command
	else
		if not mem.trm_connected then
			self:add_line(pos, mem, "$ " .. command)
		end
		local cpu_pos = termlib.get_cpu_pos(pos)
		if cpu_pos then
			local node = minetest.get_node(cpu_pos)
			if self.send_to_cpu(self, pos, mem, cpu_pos, node, command) == false then
				self:add_line(pos, mem, "Something went wrong...")
			end
		end
	end
end

function Term:on_receive_fields(pos, fields, player, mem)
	local meta = minetest.get_meta(pos)
	local public = meta:get_int("public")
	if public == 2 or
		public == 1 and not minetest.is_protected(pos, player:get_player_name()) or
		public == 0 and player:get_player_name() == meta:get_string("owner") then

		fields = termlib.func_keys(fields)
		--print("on_receive_fields", dump(fields))
		self:trigger_ttl(pos, mem)
		if fields.edit then
			mem.editing = true
		else
			mem.editing = nil
		end
		if fields.key_enter_field or fields.enter then
			local cmnd = self:command_handler(pos, mem, fields.command)
			if cmnd then
				if self.history_enabled then
					termlib.historybuffer_add(mem, cmnd)
				end
			end
			mem.trm_command = ""
		elseif fields.key_up then
			if self.history_enabled then
				mem.trm_command = termlib.historybuffer_priv(mem)
				mem.editing = true
			end
		elseif fields.key_down then
			if self.history_enabled then
				mem.trm_command = termlib.historybuffer_next(mem)
				mem.editing = true
			end
		elseif fields.help then
			self:clear_lines(pos, mem)
			self:put_string(pos, mem, table.concat(self.help_text, "\n"))
		elseif fields.larger then
			mem.trm_text_size = math.min((mem.trm_text_size or 0) + 1, 8)
		elseif fields.smaller then
			mem.trm_text_size = math.max((mem.trm_text_size or 0) - 1, -8)
		elseif fields.quit == "true" then
			mem.trm_ttl = 0
		else
			for i = 1, 8 do
				if fields["bttn" .. i] then
					local cmnd = meta:get_string("bttn_cmnd" .. i)
					self:command_handler(pos, mem, cmnd)
				end
			end
		end
	end
end

function Term:on_rightclick(pos, mem)
	self:trigger_ttl(pos, mem)
end
