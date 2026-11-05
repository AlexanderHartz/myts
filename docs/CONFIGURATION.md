# Configuration

The runtime configuration lives in:

```
kual/extensions/myts/bin/myts.ini
kual/extensions/myts/bin/keydefs.ini
```

On the Kindle, these files must stay together in
`/mnt/us/extensions/myts/bin/`.

## How files are loaded

1. `myts` first tries to open `myts.ini` in the current directory.
2. If it does not exist, it looks next to the executable.
3. `include` files are resolved relative to the executable.
4. The font (`Font`) is opened relative to the **current directory**.

This is why `myts.sh` changes into `bin/` before starting. To use a different
configuration:

```sh
./myts --cfg /path/to/myts.ini
```

## `myts.ini`

### Terminal keys

| Option | Default | Purpose |
|---|---|---|
| `TermEnd` | `Right<` | Leaves the terminal when released. With Shift/Menu/Ctrl/Sym it shows the help screen. |
| `TermEsc` | `Right>` | Sends Escape. |
| `TermCtrl` | `aA` | Ctrl modifier. |
| `TermSym` | `Back` | Symbol modifier. |
| `TermShift` | `Shift` | Shift modifier. |
| `TermFn` | `Menu` | Function-key modifier (F1..F12). |
| `TermLang` | `Sym` | Alt/language modifier while held. |
| `TermHome` | `Home` | Home; with Shift, End. |
| `TermScrollup` | `Left<` | Scroll back. |
| `TermScrolldown` | `Left>` | Scroll forward. |

The values on the right are **key names** defined in `keydefs.ini`, not numeric
codes.

### Symbols

```ini
Symbols = !@#$%^&*()'+#-_()&!?~$|/\"':
```

`Symbols` must contain exactly **28 characters**, one for each key in this
list, in this order:

```
q w e r t y u i o p
a s d f g h j k l D
z x c v b n m .
```

With the default configuration:

```
TermSym + q w e r t y u i o p  ->  ! @ # $ % ^ & * ( )
TermSym + a s d f g h j k l D  ->  ' + # - _ ( ) & ! ?
TermSym + z x c v b n m .      ->  ~ $ | / \ " ' :
```

To use the physical Sym key as the modifier:

```ini
TermSym = Sym
TermLang = Back
```

### Input and output devices

| Option | Default | Purpose |
|---|---|---|
| `KpadIn` | `/dev/input/event0` | Keyboard. |
| `FwIn` | `/dev/input/event1` | Fiveway. |
| `VolIn` | `/dev/input/event2` | Volume. |
| `KpadOut` | `/proc/keypad` | Wake/inject keyboard events. |
| `FwOut` | `/proc/fiveway` | Fiveway output. |
| `VolOut` | `/proc/volume` | Volume output. |
| `SpecialIn` | `/var/tmp/myts.special` | Control FIFO used by `myts.sh`. |

`myts` assumes it is running on a Kindle 3 if it can open all three input
devices.

### Font and screen

| Option | Default | Purpose |
|---|---|---|
| `include` | `keydefs.ini` | Includes the key map. |
| `Font` | `ter-u12n.hex` | Font in `.hex` format. |
| `Encoding` | `UTF8` | Terminal encoding. |
| `FontHeight` | `12` | Character height in pixels. |
| `FontWidth` | `6` | Character width in pixels. |
| `XOffset` | `4` | Horizontal margin. |
| `YOffset` | `4` | Vertical margin. |
| `ScrollbackLines` | `1000` | Scrollback history. |
| `RefreshDelay` | `50` | Refresh delay in milliseconds. |

The maximum supported font width is 8 pixels. With `Encoding = UTF8` only the
first 4096 characters of the font are used.

### Legacy options

`LangSymbols`, `ShiftLangSymbols`, `LangSymbols16` and `ShiftLangSymbols16` are
still read for compatibility, but the current keyboard path does not use them:
`TermLang` generates Alt + key. You can leave them as they are or remove them
if you do not use that feature.

## `keydefs.ini`

### Format

```ini
CODE = name1 name2 ...
```

- `CODE` is an input event code.
- It may have a prefix:
  - `s` to send with Shift.
  - `f` for the fiveway device.
  - `v` for volume.
- If several names are given, codes are assigned sequentially.
- `ROWn` is legacy syntax from the old symbol rows; the current modifier does
  not use it.
- `;` starts a comment and `\` escapes special characters.
- Single-character names are case-sensitive; other names are not.

### Active Kindle 3 codes

| Code | Name |
|---|---|
| `52` | `.` |
| `14` | `Del` |
| `28` | `Enter` |
| `42` | `Shift` |
| `56` | `Alt` |
| `57` | `Space` |
| `139` | `Menu` |
| `126` | `Sym` |
| `190` | `aA` |
| `102` | `Home` |
| `158` | `Back` |
| `193` | `Left<` |
| `104` | `Left>` |
| `109` | `Right<` |
| `191` | `Right>` |
| `f103` | `Up` |
| `f108` | `Down` |
| `f105` | `Left` |
| `f106` | `Right` |
| `f194` | `Select` |
| `v114` | `Vol-` |
| `v115` | `Vol+` |

The Kindle DX codes are kept commented for reference. This fork targets the
Kindle 3.

If a key does not respond as expected, check its real code with `evtest` or
`hexdump` on `/dev/input/event0` and adjust `keydefs.ini`.

### Changing a key

Example: use the physical Sym key as the symbol modifier:

```ini
# myts.ini
TermSym = Sym
TermLang = Back
```

Example: leave the terminal with `Left<`:

```ini
# myts.ini
TermEnd = Left<
```

No rebuild is needed when changing `myts.ini` or `keydefs.ini`; they are
runtime files. Restart `myts` from KUAL (**Stop MyTS**, then **Terminal 1**)
to apply the changes.

## Fonts

`ter-u12n.hex` is a 6x12 font. To convert a BDF font:

```sh
tools/bdf2hex < font.bdf > font.hex
```

Then adjust `myts.ini`:

```ini
Font = font.hex
FontHeight = 12
FontWidth = 6
```
