--[[
	termlib
	=======

	Copyright (C) 2022-2023 Joachim Stolberg

	GPL v3
	See LICENSE.txt for more information

	Library for text terminal implementations
]]--

termlib.Term = {}
local Term = termlib.Term 
local M = minetest.get_meta

local SCREENSAVER_TIME = 60 * 5

function Term:new(attr)
	local o = {
		size_x = attr.size_x or 64,
		size_y = attr.size_y or 24,
		text_size = attr.text_size or 0,
		term_size = attr.term_size or "0,0;12,7.5",
		text_color = attr.text_color or "#FFFFFF",
		background_color = attr.background_color or "#000000",
		font = attr.font or "mono",
		help_text = attr.help_text or "Sorry, no help available.",
	}
	setmetatable(o, self)
	self.__index = self
	return o
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
	mem.trm_cursor_row = mem.trm_cursor_row or 0
	if mem.trm_cursor_row < self.size_y then
		mem.trm_cursor_row = mem.trm_cursor_row + 1
	else
		table.remove(mem.trm_lines, 1)
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
	elseif val == 8 then  -- backspace ('\b')
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
		self:new_line(pos, mem)
		mem.trm_lines[mem.trm_cursor_row] = ""
		return true
	elseif val == 12 then  -- carriage return ('\r')
		mem.trm_lines[mem.trm_cursor_row] = ""
		return true
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
		else
			mem.trm_esc_cmnd = val
			return false
		end
	else
		if mem.trm_esc_cmnd == 2 then
			mem.trm_cursor_row = math.min(val, self.size_y)
			mem.trm_lines[mem.trm_cursor_row] = ""
			mem.trm_esc_cmnd = nil
			mem.trm_escaped = nil
			return true
		elseif mem.trm_esc_cmnd == 3 then
			if val == 0 then
				mem.trm_font = "normal"
			else
				mem.trm_font = "mono"
			end
			mem.trm_esc_cmnd = nil
			mem.trm_escaped = nil
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

-- Function returns true, if screen needs to be updated
function Term:put_char(pos, mem, val)
	if mem.trm_escaped then
		local res = self:escape_sequence(pos, mem, val)
		return mem.trm_ttl > minetest.get_gametime() and res
	elseif val < 32 then
		local res = self:ctrl_char(pos, mem, val)
		return mem.trm_ttl and mem.trm_ttl > minetest.get_gametime() and res
	else
		mem.trm_cursor_row = mem.trm_cursor_row or 1
		mem.trm_lines = mem.trm_lines or {}
		mem.trm_lines[mem.trm_cursor_row] = mem.trm_lines[mem.trm_cursor_row] .. string.char(val)
		return false
	end
end

-- Function returns true, if screen needs to be updated
function Term:put_string(pos, mem, s)
	local res = false
	for i = 1, string.len(s) do
		res = res or self:put_char(pos, mem, s:byte(i))
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

function Term:fs_window(pos, mem, x, y)
	mem.trm_text_size = mem.trm_text_size or self.text_size
	local font = mem.trm_font or self.font or "normal"
	local font_size = mem.trm_text_size >= 0 and "+" .. mem.trm_text_size or tostring(mem.trm_text_size)
	return "container[" .. x .. "," .. y .. "]" ..
		"box[" .. self.term_size .. ";" .. self.background_color .. "]" ..
		"style_type[textarea;font=" .. font .. ";textcolor=" .. self.text_color ..
		";border=false;font_size="  .. font_size .. "]" ..
		"textarea[" .. self.term_size .. ";;;" .. self:get_text(pos, mem) .. "]" ..
		"container_end[]"
end

function Term:fs_input(pos, mem, x, y)
	mem.trm_command = mem.trm_command or ""
	return "container[" .. x .. "," .. y .. "]" ..
		"style_type[field;textcolor=#FFFFFF]" ..
		"field[0,0.7;6.9,0.8;command;;" .. minetest.formspec_escape(mem.trm_command) .. "]" ..
		"button[7.0,0.7;1.7,0.8;enter;Enter]" ..
		"field_close_on_enter[command;false]" ..
		"container_end[]"
end

function Term:fs_input_with_function_keys(pos, mem, x, y)
	mem.trm_command = mem.trm_command or ""
	return "container[" .. x .. "," .. y .. "]" ..
		"button[0.0,0;1.3,0.6;esc;ESC]" ..
		"button[1.4,0;1.3,0.6;f1;F1]" ..
		"button[2.8,0;1.3,0.6;f2;F2]" ..
		"button[4.2,0;1.3,0.6;f3;F3]" ..
		"button[5.6,0;1.3,0.6;f4;F4]" ..
		"button[7.0,0;1.7,0.6;close;Close]" ..
		"style_type[field;textcolor=#FFFFFF]" ..
		"field[0,0.7;6.9,0.8;command;;" .. minetest.formspec_escape(mem.trm_command) .. "]" ..
		"button[7.0,0.7;1.7,0.8;enter;Enter]" ..
		"field_close_on_enter[command;false]" ..
		"container_end[]"
end

function Term:fs_size_buttons(pos, mem, x, y)
	return "container[" .. x .. "," .. y .. "]" ..
		"button[0.0,0;0.6,0.6;larger;+]" ..
		"button[0.6,0;0.6,0.6;smaller;-]" ..
		"container_end[]"
end

function Term:fs_user_buttons(pos, mem, x, y)
	local meta = minetest.get_meta(pos)
	local t = {}
	for i = 1, 9 do
		local x = ((i - 1) % 3) * 3.3
		local y = math.floor((i - 1) / 3) * 0.6
		local text = termlib.get_user_button_string(meta, i, "User" .. i)
		t[#t+1] = "button[" .. x .. "," .. y .. ";3.3,0.6;bttn" .. i .. ";" .. text .. "]"
	end
	return "container[" .. x .. "," .. y .. "]" ..
		table.concat(t, "") ..
		"container_end[]"
end

function Term:internal_commands(pos, mem, meta, command)
	if command == "@cls" then
		self:clear_lines(pos, mem)
	elseif command == "@help" then
		self:clear_lines(pos, mem)
		self:put_string(pos, mem, self.help_text)
	elseif command == "@pub" then
		meta:set_int("public", 2)
		self:put_string(pos, mem, "$ "..command)
		self:put_string(pos, mem, "Switched to public mode!")
	elseif command == "@prot" then
		meta:set_int("public", 1)
		self:put_string(pos, mem, "$ "..command)
		self:put_string(pos, mem, "Switched to protected mode!")
	elseif command == "@priv" then
		meta:set_int("public", 0)
		self:put_string(pos, mem, "$ "..command)
		self:put_string(pos, mem, "Switched to private mode!")
	else
		local bttn_num, label, cmnd = command:match('^@set%s+([1-9])%s+([%w_]+)%s+(.+)$')
		if bttn_num and label and cmnd then
			meta:set_string("bttn_text"..bttn_num, label)
			meta:set_string("bttn_cmnd"..bttn_num, cmnd)
		else
			print("cmd: " .. command)
		end
	end
	
end


function Term:on_receive_fields(pos, formname, fields, player, mem, command_handler)
	local meta = minetest.get_meta(pos)
	local public = meta:get_int("public")
	if public == 2 or 
		public == 1 and not minetest.is_protected(pos, player:get_player_name()) or
		public == 0 and player:get_player_name() == meta:get_string("owner") then

		fields = termlib.function_keys(fields)
		print("on_receive_fields", mem.trm_input)
		mem.trm_ttl = minetest.get_gametime() + SCREENSAVER_TIME

		if fields.key_enter_field or fields.enter then
			mem.trm_input = string.sub(fields.command or "", 1, self.size_x)
			mem.trm_input = string.trim(mem.trm_input)
			self:add_line(pos, mem, "$ " .. mem.trm_input)
			if mem.trm_input:byte(1) == 64 then -- "@"
				self:internal_commands(pos, mem, meta, mem.trm_input)
			else
				command_handler(pos, mem, mem.trm_input)
			end
			termlib.historybuffer_add(mem, mem.trm_input)
			mem.trm_command = ""
		elseif fields.key_up then
			mem.trm_command = termlib.historybuffer_priv(mem)
		elseif fields.key_down then
			mem.trm_command = termlib.historybuffer_next(mem)
		elseif fields.larger then
			mem.trm_text_size = math.min((mem.trm_text_size or 0) + 1, 8)
		elseif fields.smaller then
			mem.trm_text_size = math.max((mem.trm_text_size or 0) - 1, -8)
		elseif fields.close then
			mem.trm_active = false
		elseif fields.exit then
			mem.trm_input = fields.command or ""
		elseif fields.bttn1 then command_handler(pos, mem, meta:get_string("bttn_cmnd1"))
		elseif fields.bttn2 then command_handler(pos, mem, meta:get_string("bttn_cmnd2"))
		elseif fields.bttn3 then command_handler(pos, mem, meta:get_string("bttn_cmnd3"))
		elseif fields.bttn4 then command_handler(pos, mem, meta:get_string("bttn_cmnd4"))
		elseif fields.bttn5 then command_handler(pos, mem, meta:get_string("bttn_cmnd5"))
		elseif fields.bttn6 then command_handler(pos, mem, meta:get_string("bttn_cmnd6"))
		elseif fields.bttn7 then command_handler(pos, mem, meta:get_string("bttn_cmnd7"))
		elseif fields.bttn8 then command_handler(pos, mem, meta:get_string("bttn_cmnd8"))
		elseif fields.bttn9 then command_handler(pos, mem, meta:get_string("bttn_cmnd9"))
		end
	end
end

function Term:on_rightclick(pos, mem)
	mem.trm_ttl = minetest.get_gametime() + SCREENSAVER_TIME
end
