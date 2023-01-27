--[[
	termlib
	=======

	Copyright (C) 2022-2023 Joachim Stolberg

	GPL v3
	See LICENSE.txt for more information

	Backend for the Beduino controller
]]--

local M = minetest.get_meta
local term = termlib.term

local CmndBuffer = {}
local orig_send_to_cpu = term.send_to_cpu
local orig_putchar = beduino.lib.putchar

term.send_to_cpu = function(self, pos, mem, cpu_pos, node, command)
	if node.name == "beduino:controller" then
		local hash = minetest.hash_node_position(cpu_pos)
		CmndBuffer[hash] = command
		return true
	else
		return orig_send_to_cpu(self, pos, mem, cpu_pos, node, command)
	end
end

beduino.lib.putchar = function(cpu_pos, val)
	local term_pos = termlib.get_terminal_pos(cpu_pos)
	if term_pos then
		local mem = termlib.get_mem(term_pos)
		if mem.trm_connected then
			if term:put_char(term_pos, mem, val) then
				M(term_pos):set_string("formspec", termlib.formspec(term_pos))
				return 1, 1000
			end
			return 1, 200
		end
	else
		return orig_putchar(cpu_pos, val)
	end
end

local function getchar(cpu_pos)
	local stdout = M(cpu_pos):get_int("stdout")
	if stdout == 2 then
		local hash = minetest.hash_node_position(cpu_pos)
		if CmndBuffer[hash] and CmndBuffer[hash]:len() > 0 then
			local val = CmndBuffer[hash]:byte(1)
			CmndBuffer[hash] = CmndBuffer[hash]:sub(2, -1)
			return val, 200
		end
		return 0, 200  -- no char
	end
	return 0, 200  -- no char
end

beduino.lib.register_SystemHandler(2, function(cpu_pos, address, regA, regB, regC)
	return getchar(cpu_pos)
end)
