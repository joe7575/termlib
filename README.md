# Terminal Library [termlib]

**A Library for Minetest text terminals**

This mod comes with a example terminal to be used with TechAge, TechPack, or
Beduino Controllers.

![screenshot_1](./screenshot_1.png)

![screenshot_2](./screenshot_2.png)


### Features

- Screen memory handling, configurable size
- Programmable function keys (F1 - F8)
- Command history buffer
- Escape sequences for clear screen, goto line, ...

### TechAge/TechPack Lua Controller Example

This is the code for the screenshot 2.

- `$put_str(s)` is used to output text
- `$get_str()` is used to read/input text

**Init Code:**

```lua
cnt = 0

$put_str("\b")  -- clear screen
$put_str("+----------------------------------------------------------+\n")
$put_str("|                Termlib Terminal Demo                     |\n")
$put_str("+----------------------------------------------------------+\n")

$put_str("\nThe screen size is 60 characters x 20 lines.\n")
$put_str("The input field has a history buffer.\n")
$put_str("The function keys can be labeled and programmed.\n")

$put_str("\27\2\20This is line 20!")
```

**Loop Code:**

```lua
$put_str("\27\2\12")
$put_str("\tThe counter is " .. cnt .. "\n")
cnt = cnt + 1

s = $get_str()
if s then
    if string.len(s) == 1 and string.byte(s, 1) > 127 then
        $print("Function key code: " .. string.byte(s, 1))
    else
        $print(s)
    end
end
```


### Beduino Controller Example

The same code for the Beduino controller.
Note that the escape sequences are in octal notation!

```c
import "stdio.asm"
import "os.c"

var cnt = 0;

func init() {
  setstdout(2);  // use external terminal for stdout
  putstr("\b");  // clear screen
  putstr("+----------------------------------------------------------+\n");
  putstr("|                Termlib Terminal Demo                     |\n");
  putstr("+----------------------------------------------------------+\n");

  putstr("\nThe screen size is 60 characters x 20 lines.\n");
  putstr("The input field has a history buffer.\n");
  putstr("The function keys can be labeled and programmed.\n");

  putstr("\033\002\024This is line 20!");
}

func loop() {
  var c;

  putstr("\033\002\014");
  putstr("\tThe counter is ");
  putnum(cnt);
  putchar('\n');

  cnt = cnt + 1;

  c = getchar();
  while(c > 0) {
    if(c > 127) {
      putstr("Num: ");
      putnum(c);
    } else {
      putchar(c);
    }
  }
  sleep(10);
}
```

### License

Copyright (C) 2022-2023 Joachim Stolberg

Code: Licensed under the GNU GPL version 3 or later. See LICENSE.txt

Textures: CC BY-SA 3.0


### Dependencies

Required: none
Optional: techage, techpack (sl_conttroller), beduino


### History

- 2022-12-31  V1.01  * Add support for TechPack sl_controller
- 2022-12-26  V1.00  * First version
