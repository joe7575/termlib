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
	minetest.sound_play("vm16_beep", {
		pos = pos,
		gain = 1,
		max_hear_distance = 5})
end

function termlib.function_keys(fields)
	if fields.esc then
		fields.command = "\027"
		fields.enter = true
	elseif fields.f1 then
		fields.command = "\028"
		fields.enter = true
	elseif fields.f2 then
		fields.command = "\029"
		fields.enter = true
	elseif fields.f3 then
		fields.command = "\030"
		fields.enter = true
	elseif fields.f4 then
		fields.command = "\031"
		fields.enter = true
	end
	return fields
end

function termlib.historybuffer_add(pos, s)
	local mem = pdp13.get_mem(pos)
	mem.trm_hisbuf = mem.trm_hisbuf or {}
	
	if #s > 2 then
		table.insert(mem.trm_hisbuf, s)
		if #mem.trm_hisbuf > BUFFER_DEPTH then
			table.remove(mem.trm_hisbuf, 1)
		end
		mem.trm_hisbuf_idx = #mem.trm_hisbuf + 1
	end
end

function termlib.historybuffer_priv(pos)
	local mem = pdp13.get_mem(pos)
	mem.trm_hisbuf = mem.trm_hisbuf or {}
	mem.trm_hisbuf_idx = mem.trm_hisbuf_idx or 1
	
	mem.trm_hisbuf_idx = math.max(1, mem.trm_hisbuf_idx - 1)
	return mem.trm_hisbuf[mem.trm_hisbuf_idx]
end

function termlib.historybuffer_next(pos)
	local mem = pdp13.get_mem(pos)
	mem.trm_hisbuf = mem.trm_hisbuf or {}
	mem.trm_hisbuf_idx = mem.trm_hisbuf_idx or 1
	
	mem.trm_hisbuf_idx = math.min(#mem.trm_hisbuf, mem.trm_hisbuf_idx + 1)
	return mem.trm_hisbuf[mem.trm_hisbuf_idx]
end

function termlib.get_user_button_string(meta, num, default)
	local s = meta:get_string("bttn_text"..num)
	if not s or s == "" then
		return default
	end
	return s
end
