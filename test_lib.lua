--[[
	termlib
	=======

	Copyright (C) 2022-2023 Joachim Stolberg

	GPL v3
	See LICENSE.txt for more information

	Library for text terminal implementations
]]--

local MP = '/home/joachim/Projekte/lua/minetest_unittest/lib'

core = {}

dofile(MP.."/chatcommands.lua")
dofile(MP.."/serialize.lua")
dofile(MP.."/misc_helpers.lua")
dofile(MP.."/vector.lua")
dofile(MP.."/item.lua")
dofile(MP.."/misc.lua")
dofile(MP.."/meta.lua")

minetest = core
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function minetest.get_gametime()
	return 0
end

function minetest.get_gametime()
	return 0
end
termlib = {}

dofile("./lib.lua")  -- helper functions
dofile("./api.lua")  -- interface functions

local term = termlib.Term:new({
	size_x = 20,
	size_y = 5,
})

local mem = {}
local pos = {x=0; y=0; z=0}

-- Init
term:init_block(pos, mem)
term:on_rightclick(pos, mem)
term:clear_lines(pos, mem)

-- Empty screen
assert(term:get_text(pos, mem) == "\n\n\n\n")

-- Add few lines
assert(term:put_string(pos, mem, "Hello1") == false)
assert(term:put_char(pos, mem, 10) == true)
assert(term:put_string(pos, mem, "Hello2\n") == true)
assert(term:get_text(pos, mem) == "Hello1\nHello2\n\n\n")

-- Clear screen
assert(term:put_char(pos, mem, 8) == true)
assert(term:get_text(pos, mem) == "\n\n\n\n")

-- Set cursor
term:set_cursor(pos, mem, 5)
assert(term:put_string(pos, mem, "Hello5") == false)
assert(term:get_text(pos, mem) == "\n\n\n\nHello5")

-- Clear line
assert(term:put_char(pos, mem, 12) == true)
assert(term:get_text(pos, mem) == "\n\n\n\n")
assert(term:put_string(pos, mem, "Joe") == false)
assert(term:get_text(pos, mem) == "\n\n\n\nJoe")

-- Set Color
assert(term:put_string(pos, mem, "\27(c@#FFF)") == false)
assert(term:put_string(pos, mem, "\27(b@#000)Test") == false)
print(term:get_text(pos, mem))

-- Clear screen
assert(term:put_string(pos, mem, "\27\1") == true)
assert(term:get_text(pos, mem) == "\n\n\n\n")

-- Invalid Escape Sequences
assert(term:put_string(pos, mem, "\27Joe") == false)
assert(term:put_string(pos, mem, "\27\5Joe") == false)
print(term:get_text(pos, mem))

-- Clear screen
assert(term:put_string(pos, mem, "\b") == true)
assert(term:get_text(pos, mem) == "\n\n\n\n")

-- Test Tabs
assert(term:put_string(pos, mem, "1       2       3       4       5       6       7\n") == true)
assert(term:put_string(pos, mem, "\t1\t55555\t7777777\t88888888\t@\n") == true)
print(term:get_text(pos, mem))


print("Done.")