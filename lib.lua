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

local BUFFER_DEPTH = 10

function termlib.bell(pos)
	minetest.sound_play("termlib_beep", {
		pos = pos,
		gain = 1,
		max_hear_distance = 5})
end

function termlib.get_bttn_string(meta, num, default)
	local s = meta:get_string("bttn_text"..num)
	if not s or s == "" then
		return default
	end
	return s
end

function termlib.func_keys(fields)
	if fields.esc then
		fields.command = ""
		fields.enter = true
	elseif fields.bttn1 then
		fields.command = "\128"
		fields.enter = true
	elseif fields.bttn2 then
		fields.command = "\129"
		fields.enter = true
	elseif fields.bttn3 then
		fields.command = "\130"
		fields.enter = true
	elseif fields.bttn4 then
		fields.command = "\131"
		fields.enter = true
	elseif fields.bttn5 then
		fields.command = "\132"
		fields.enter = true
	elseif fields.bttn6 then
		fields.command = "\133"
		fields.enter = true
	elseif fields.bttn7 then
		fields.command = "\134"
		fields.enter = true
	elseif fields.bttn8 then
		fields.command = "\135"
		fields.enter = true
	end
	return fields
end

function termlib.func_key_bttns(pos, mem, x, y)
	local meta = minetest.get_meta(pos)
	local t = {}
	for i = 1, 8 do
		local x = (i - 1) * 1.5
		local text = termlib.get_bttn_string(meta, i, "F" .. i)
		t[#t+1] = "button[" .. x .. "," .. y .. ";1.5,0.7;bttn" .. i .. ";" .. text .. "]"
	end
	return "container[" .. x .. "," .. y .. "]" ..
		table.concat(t, "") ..
		"container_end[]"
end

function termlib.command_handler(self, pos, mem, command)
	command = string.sub(command or "", 1, self.size_x)
	command = string.trim(command)
	local cmnd, payload = command:match('^([%w_@]+)%s*(.*)$')
	if self.registered_commands[cmnd] then
		self:add_line(pos, mem, "$ " .. command)
		self.registered_commands[cmnd](self, pos, mem, cmnd, payload)
		return command
	else
		self.external_commands(self, pos, mem, command)
	end
end

function termlib.historybuffer_add(mem, s)
	mem.trm_lHisbuf = mem.trm_lHisbuf or {}
	mem.trm_tHisbuf = mem.trm_tHisbuf or {}
	
	if #s > 2 then
		if not mem.trm_tHisbuf[s] then
			table.insert(mem.trm_lHisbuf, s)
			mem.trm_tHisbuf[s] = true
			if #mem.trm_lHisbuf > BUFFER_DEPTH then
				mem.trm_tHisbuf[mem.trm_lHisbuf[1]] = nil
				table.remove(mem.trm_lHisbuf, 1)
			end
			mem.trm_lHisbuf_idx = #mem.trm_lHisbuf + 1
		else
			mem.trm_lHisbuf_idx = mem.trm_lHisbuf_idx + 1
		end
	end
end

function termlib.historybuffer_priv(mem)
	mem.trm_lHisbuf = mem.trm_lHisbuf or {}
	mem.trm_lHisbuf_idx = mem.trm_lHisbuf_idx or 1
	
	mem.trm_lHisbuf_idx = math.max(1, mem.trm_lHisbuf_idx - 1)
	return mem.trm_lHisbuf[mem.trm_lHisbuf_idx]
end

function termlib.historybuffer_next(mem)
	mem.trm_lHisbuf = mem.trm_lHisbuf or {}
	mem.trm_lHisbuf_idx = mem.trm_lHisbuf_idx or 1
	
	mem.trm_lHisbuf_idx = math.min(#mem.trm_lHisbuf, mem.trm_lHisbuf_idx + 1)
	return mem.trm_lHisbuf[mem.trm_lHisbuf_idx]
end
