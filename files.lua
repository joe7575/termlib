--[[
	termlib
	=======

	Copyright (C) 2022-2023 Joachim Stolberg

	GPL v3
	See LICENSE.txt for more information

	Demo program for the Beduino controller
]]--

local termlib1_c = [[
// termlib Demo V2.1
// Connect the termlib terminal to the Beduino controller
// and start the program with 'Execute'.
import "sys/stdio.asm"
import "sys/os.c"

var percent = 0;
var prop_idx = 0;
var prop_arr[] = {'-', '/', '|', '\'};

func gotoxy(x, y) {
  putstr("\033\006");
  putchar(x);
  putchar(y);
}

func init() {
  setstdout(2);  // Use external terminal for stdout
  putstr("\b");  // Clear screen
  putstr("+----------------------------------------------------------+\n");
  putstr("|                Termlib Terminal Demo                     |\n");
  putstr("+----------------------------------------------------------+\n");

  putstr("\nThe screen size is 60 characters x 20 lines.\n");
  putstr("The input field has a history buffer.\n");
  putstr("The function keys can be labeled and programmed.\n");
  putstr("See: https://github.com/joe7575/termlib\n");

  // fill line 14 with blanks
  gotoxy(1, 14);
  putstr("                                                     \n");
}

func loop() {
  var i;
  var c;

  // Bar graph in line 14
  gotoxy(1, 14);
  putchar('[');
  for(i = 0; i < percent; i++) {
    putchar('#');
  }
  if(percent == 0) {
    putstr("]                                         \n");
  } else {
    putstr("]\n");
  }
  gotoxy(38, 14);
  putnum(percent);
  putstr(" %\n");

  percent = (percent + 1) % 30;

  // Propeller in line 16
  gotoxy(1, 16);
  putchar('[');
  putchar(prop_arr[prop_idx]);
  putstr("]\n");
  prop_idx = (prop_idx + 1) % 4;

  // Terminal input in line 18
  c = getchar();
  if(c > 0) {
    gotoxy(1, 18);
    putstr("Input: ");
     if(c > 127) {
      putnum(c);
    } else {
      while(c > 0) {
        putchar(c);
        c = getchar();
      }
    }
    putstr("       \n");
  }
  sleep(2);
}

]]

vm16.register_ro_file("beduino", "demo/termlib1.c", termlib1_c)