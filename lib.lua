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

function termlib.get_user_button_string(meta, num, default)
	local s = meta:get_string("bttn_text"..num)
	if not s or s == "" then
		return default
	end
	return s
end
