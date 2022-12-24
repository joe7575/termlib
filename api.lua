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

local SCREENSAVER_TIME = 60 * 5

function Term:new(attr)
	local o = {
		size_x = attr.size_x or 64,
		size_y = attr.size_y or 24,
		text_size = attr.text_size or 0,
		term_size = attr.term_size or "0,0;10,9",
		text_color = "\027(c@" .. (attr.text_color or "#FFFFFF") .. ")",
		background_color = attr.background_color or "#000000",
		font = attr.font or "mono",
	}
	setmetatable(o, self)
	self.__index = self
	return o
end

function Term:init_block(pos, mem)
	mem.trm_lines = mem.trm_lines or {}
	mem.trm_cursor_row = mem.trm_cursor_row or 1
	mem.trm_font = mem.trm_font or self.font
	mem.trm_ttl = mem.trm_ttl or 0
end

function Term:get_text(pos, mem)
	local t = {}
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
	mem.trm_lines[mem.trm_cursor_row] = ""
	return self:put_string(pos, mem, s)
end

function Term:add_line(pos, mem, s)
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
	mem.trm_textsize = mem.trm_textsize or self.textsize
	local font = mem.trm_font or self.font or "normal"
	return "container[" .. x .. "," .. y .. "]" ..
		"box[" .. self.term_size .. ";" .. self.background_color .. "]" ..
		"style_type[textarea;font=" .. font .. ";textcolor=" .. self.text_color ..
		";border=false;font_size="  .. mem.trm_textsize .. "]" ..
		"textarea[" .. self.term_size .. ";;Terminal;" .. self:get_text(mem) .. "]" ..
		"container_end[]"
end

function Term:fs_input(pos, mem, x, y)
	mem.trm_command = mem.trm_command or ""
	return "container[" .. x .. "," .. y .. "]" ..
		"style_type[field;textcolor=#000000]" ..
		"field[0,0;5.9,0.8;command;;" .. minetest.formspec_escape(mem.trm_command) .. "]" ..
		"button[6.0,0;1.7,1;enter;Enter]" ..
		"field_close_on_enter[command;false]" ..
		"container_end[]"
end

function Term:fs_input_with_function_keys(pos, mem, x, y)
	mem.trm_command = mem.trm_command or ""
	return "container[" .. x .. "," .. y .. "]" ..
		"button[0.0,0;1.1,1;esc;ESC]" ..
		"button[1.2,0;1.1,1;f1;F1]" ..
		"button[2.4,0;1.1,1;f2;F2]" ..
		"button[3.6,0;1.1,1;f3;F3]" ..
		"button[4.8,0;1.1,1;f4;F4]" ..
		"button[6.0,0;1.7,1;close;Close]" ..
		"style_type[field;textcolor=#000000]" ..
		"field[0,1;5.9,0.8;command;;" .. minetest.formspec_escape(mem.trm_command) .. "]" ..
		"button[6.0,1;1.7,1;enter;Enter]" ..
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
		local x = ((i % 3) + 1) * 3.3
		local y = (math.floor(i % 3) + 1) * 0.6
		local text = termlib.get_user_button_string(meta, i, "User" .. i)
		t[#t+1] = "button[" .. x .. "," .. y .. ";3.3,1;bttn" .. i .. ";" .. text .. "]"
	end
	return "container[" .. x .. "," .. y .. "]" ..
		table.concat(t, "") ..
		"container_end[]"
end

function Term:on_receive_fields(pos, fields, mem)
	fields = termlib.function_keys(fields)
	print("on_receive_fields", mem.trm_input)
	mem.trm_ttl = minetest.get_gametime() + SCREENSAVER_TIME

	if fields.key_enter_field or fields.enter then
		mem.trm_input = string.sub(fields.command or "", 1, self.size_x)
		termlib.historybuffer_add(pos, mem.trm_input)
		mem.trm_command = ""
	elseif fields.key_up then
		mem.trm_command = termlib.historybuffer_priv(pos)
	elseif fields.key_down then
		mem.trm_command = termlib.historybuffer_next(pos)
	elseif fields.larger then
		mem.trm_textsize = math.min(mem.trm_textsize + 1, 8)
	elseif fields.smaller then
		mem.trm_textsize = math.max(mem.trm_textsize - 1, -8)
	elseif fields.close then
		mem.trm_active = false
	elseif fields.exit then
		mem.trm_input = fields.command or ""
	elseif fields.quit then
		mem.trm_ttl = 0
	end
end

function Term:on_rightclick(pos, mem)
	mem.trm_ttl = minetest.get_gametime() + SCREENSAVER_TIME
end
