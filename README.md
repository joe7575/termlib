# Terminal Library [termlib]

**A Library for Minetest text terminals**

This mod comes with a example terminal to be used with TechAge, TechPack, and
Beduino Controllers.

![screenshot_1](./screenshot_1.png)

![screenshot_2](./screenshot_2.png)


### Features

- Screen memory handling, configurable size.
- Programmable function keys (F1 - F8). Example: `@set F1 CLS @cls`
- Command history buffer.
- Escape sequences for clear screen, goto line, ...

### Instructions

- Preconnect the terminal with the target controller. Therefore, left-click on the target controller with the wielded terminal.

- Place the terminal block and open the terminal menu.

- Click the "Edit" button, enter the command `@connect` and click "Enter". The terminal is now connected to the controller.

- Copy the code from below and start the demo (works for Techage/TechPack Lua controllers and for the Beduino controller).

### Escape and Control Charcters

| Characters (decimal notation) | Description                                                  |
| ----------------------------- | ------------------------------------------------------------ |
| \27\1                         | Clear screen                                                 |
| \27\2\<row>                   | Set cursor to row \<row> (1 - 20)                            |
| \27\3\<font>                  | 0 = normal, 1 = mono                                         |
| \27\4\<command>\n             | Execute the command.<br />Example: "\27\4@set F1 CLS @cls\n" |
| \n                            | New line + carriage return                                   |
| \t                            | Tab (up to 8 chars)                                          |
| \r                            | Carriage return (to rewrite line)                            |
| \a                            | Bell (sound)                                                 |
| \b                            | Clear screen                                                 |
| 128                           | Control character for the buttonm "F1"                       |
| 129                           | Control character for the buttonm "F2"                       |
| 130                           | Control character for the buttonm "F3"                       |
| 131                           | Control character for the buttonm "F4"                       |
| 132                           | Control character for the buttonm "F5"                       |
| 133                           | Control character for the buttonm "F6"                       |
| 134                           | Control character for the buttonm "F7"                       |
| 135                           | Control character for the buttonm "F8"                       |

### 

### Hints

- The terminal font size can be changed with the "+" and "-" buttons.
- The "?" button outputs the help text.
- The screen size is 60 characters x 20 lines.
- The function keys can be labeled and programmed. See help text.
- To send a string/characters to the controller, enter the string into the edit field and press "Enter".
- The "ESC" button cancels the editing mode, so that no characters are sent to the controller.
- The terminal output can be forced with a '\n' or '\r'. The output of a string like "Hello world" is not yet displayed, so output either "Hello world\n" or "\rHello world".
- The terminal can also be used to connect directly to Techage blocks with command interface.
- Using the escape sequence `\27\4\<command>\n`, the given command is executed like commands entered in the terminal. This makes it possible, for example, to program the function keys.

### TechAge/TechPack Lua Controller Example

This is the code for the screenshot 2 example.

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

- 2023-01-01  V1.02  * Add support for Beduino controllers
- 2022-12-31  V1.01  * Add support for TechPack sl_controllers
- 2022-12-26  V1.00  * First version
