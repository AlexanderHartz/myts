# Using the terminal in KUAL

## KUAL menu

| Entry | Action |
|---|---|
| **Terminal 1** | Opens terminal 1 or returns to it if it already exists. |
| **Terminal 2** | Opens terminal 2 or returns to it. |
| **Terminal 3** | Opens terminal 3 or returns to it. |
| **Stop MyTS** | Terminates the `myts` process and cleans up the FIFO/PID. |
| **Restart MyTS** | Restarts `myts` and opens terminal 1. |

The terminal takes about **3 seconds** to appear. This is normal: the launcher
waits for KUAL to finish refreshing the screen before drawing the terminal.

## Leaving a terminal

Press the key configured as `TermEnd`. The default is `Right<` (Kindle 3 code
109). If you prefer another key, change it in `bin/myts.ini`:

```ini
TermEnd = Left<
```

On exit, `myts` restores the screen that was visible before (the KUAL menu) and
releases keyboard capture. The process stays alive so terminals 2 and 3 can be
opened later. To terminate it completely, use **Stop MyTS**.

## Multiple terminals

You can switch between terminals 1, 2 and 3 from KUAL. Each one keeps its own
shell and scrollback.

## Keyboard

The default configuration is designed for the Kindle 3 physical keyboard.

### Function keys (Menu + key)

```
Menu + q w e r t y u i o p  ->  F1 F2 F3 F4 F5 F6 F7 F8 F9 F10
Menu + a s d f g h j k l    ->  ` % ^ < > [ ] = F11 F12
Menu + z x c v b n m        ->  Tab ; , ( ) { }
```

### Numbers

```
Alt + q w e r t y u i o p  ->  1 2 3 4 5 6 7 8 9 0
```

### Symbols (Back + key)

Hold the key configured as `TermSym` (default **Back**) and press one of these
keys:

```
Back + q w e r t y u i o p  ->  ! @ # $ % ^ & * ( )
Back + a s d f g h j k l D  ->  ' + # - _ ( ) & ! ?
Back + z x c v b n m .      ->  ~ $ | / \ " ' :
```

The exact sequence is defined by `Symbols` in `bin/myts.ini`. It must contain
28 characters, in this order:

```
q w e r t y u i o p
a s d f g h j k l D
z x c v b n m .
```

If you prefer the physical **Sym** key instead of Back, change:

```ini
TermSym = Sym
TermLang = Back
```

### Navigation and editing

| Key | Effect |
|---|---|
| Fiveway arrows | Left / right / up / down in the shell |
| Shift + up/down | PgUp / PgDn |
| Home | Home |
| Shift + Home | End |
| `TermScrollup` (`Left<` by default) | Scroll back |
| `TermScrolldown` (`Left>` by default) | Scroll forward |
| `TermEsc` (`Right>` by default) | Send Escape |
| `TermCtrl` (`aA`) + letter | Send Ctrl + letter |
| `Del` | Delete / backspace |
| Enter | Send Enter |
| Space | Space |

Pressing a key that sends a character returns to the bottom of the scrollback
if you were scrolled up.

### Keyboard help

Hold **Menu** and press `TermEnd` (`Right<` by default) to display the key map
on screen. Release the keys or press the combination again to return.

### Sym as language/Alt

With the default configuration, the physical **Sym** key is assigned to
`TermLang`: while held, letters are sent with Alt (Escape + letter).
`Shift + Sym` toggles a lock for that mode. If you do not use it, you can
reassign `TermLang` or swap it with `TermSym`.

## Log

The launcher writes to:

```
/tmp/myts.log
```

If something fails, check that file first. To run the launcher manually:

```sh
sh /mnt/us/extensions/myts/myts.sh 1
```

## Usage problems

### The terminal does not appear

- Wait a few seconds; the 3-second delay is normal.
- Check that `myts` is running: `ps | grep myts`.
- Check `/tmp/myts.log`.
- Make sure the FIFO `/var/tmp/myts.special` exists.
- Make sure `/proc/keypad` exists; it is what wakes the process.

### Some keys do not behave as expected

The Kindle 3 key codes are in `bin/keydefs.ini`. If a key does not match, you
can inspect the real event code with `evtest` or `hexdump` on
`/dev/input/event0`, then adjust `keydefs.ini` or `myts.ini`.

### Symbols do not match

Check that `Symbols` contains exactly 28 characters and that the order is the
one shown above. One extra or missing character shifts every symbol after it.

### I cannot leave the terminal

Check the `TermEnd` value in `bin/myts.ini` and press that key. If the keyboard
does not respond, use **Stop MyTS** from KUAL.
