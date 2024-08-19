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
	elseif fields.bttn1 == "F1" then
		fields.command = "\128"
		fields.enter = true
	elseif fields.bttn2 == "F2" then
		fields.command = "\129"
		fields.enter = true
	elseif fields.bttn3 == "F3" then
		fields.command = "\130"
		fields.enter = true
	elseif fields.bttn4 == "F4" then
		fields.command = "\131"
		fields.enter = true
	elseif fields.bttn5 == "F5" then
		fields.command = "\132"
		fields.enter = true
	elseif fields.bttn6 == "F6" then
		fields.command = "\133"
		fields.enter = true
	elseif fields.bttn7 == "F7" then
		fields.command = "\134"
		fields.enter = true
	elseif fields.bttn8 == "F8" then
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

--------------------------------------------------------------------------------
-- Memory Management (Storage)
--------------------------------------------------------------------------------
local storage = minetest.get_mod_storage()

local Data = minetest.deserialize(storage:get_string("Data")) or {}

minetest.register_on_shutdown(function()
	storage:set_string("Data", minetest.serialize(Data))
end)

function termlib.get_mem(pos)
	local hash = minetest.hash_node_position(pos)
	Data[hash] = Data[hash] or {}
	return Data[hash]
end

function termlib.del_mem(pos)
	local hash = minetest.hash_node_position(pos)
	Data[hash] = nil
end

--------------------------------------------------------------------------------
-- Terminal & CPU positioning
--------------------------------------------------------------------------------
local PosCache = {}

function termlib.set_terminal_pos(cpu_pos, term_pos)
	M(cpu_pos):set_string("trm_term_pos", P2S(term_pos))
end

function termlib.set_cpu_pos(itemstack, cpu_pos)
	itemstack:get_meta():set_string("trm_cpu_pos", P2S(cpu_pos))
end

function termlib.get_terminal_pos(cpu_pos)
	local hash = minetest.hash_node_position(cpu_pos)
	if not PosCache[hash] then
		PosCache[hash] = S2P(M(cpu_pos):get_string("trm_term_pos"))
	end
	return PosCache[hash]
end

function termlib.get_cpu_pos(term_pos)
	local hash = minetest.hash_node_position(term_pos)
	if not PosCache[hash] then
		PosCache[hash] = S2P(M(term_pos):get_string("trm_cpu_pos"))
	end
	return PosCache[hash]
end

function termlib.restore_cpu_pos(pos, itemstack)
	local imeta = itemstack:get_meta()
	if imeta then
		M(pos):set_string("trm_cpu_pos", imeta:get_string("trm_cpu_pos"))
	end
end

function termlib.preserve_metadata(pos, oldnode, oldmetadata, drops)
	local trm_cpu_pos = oldmetadata and oldmetadata.trm_cpu_pos
	local connected_to = oldmetadata and oldmetadata.connected_to
	if trm_cpu_pos and connected_to then
		local stack_meta = drops[1]:get_meta()
		stack_meta:set_int("trm_cpu_pos", trm_cpu_pos)
		local ndef = minetest.registered_nodes[oldnode.name]
		if ndef and ndef.connection then
			stack_meta:set_string("description", ndef.description .. " (connected to " .. connected_to .. ")")
		end
	end
end

function termlib.get_node_name(pos)
	local name = minetest.get_node(pos).name
	if name then
		local ndef = minetest.registered_nodes[name]
		return ndef and ndef.description
	end
end
--------------------------------------------------------------------------------
-- History Buffer
--------------------------------------------------------------------------------
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
