# Repository structure and architecture

This document explains where everything lives and how the pieces fit together
at runtime.

## Repository tree

```
.
├── Makefile
├── README.md
├── AGENTS.md
├── docs/
│   ├── STRUCTURE.md
│   ├── BUILD.md
│   ├── INSTALL.md
│   ├── USAGE.md
│   ├── CONFIGURATION.md
│   └── TROUBLESHOOTING.md
├── src/
│   ├── myts.c
│   ├── myts_app.c
│   ├── config.c / config.h
│   ├── terminal.c / terminal.h
│   ├── screen.c / screen.h
│   ├── pixop.c / pixop.h
│   ├── font.c / font.h
│   ├── dynstring.c / dynstring.h
│   ├── myts.h
│   └── linux/
│       ├── einkfb.h
│       └── fb.h
├── tools/
│   └── bdf2hex
├── kual/
│   └── extensions/
│       └── myts/
│           ├── config.xml
│           ├── menu.json
│           ├── myts.sh
│           └── bin/
│               ├── myts
│               ├── myts.ini
│               ├── keydefs.ini
│               └── ter-u12n.hex
├── build/        (generated, ignored)
├── dist/         (generated, ignored)
└── toolchain/    (downloaded, ignored)
```

## Source files

| File | Responsibility |
|---|---|
| `src/myts.c` | `main()`, `select()` event loop, timers and session list. |
| `src/myts_app.c` | Main application. Reads configuration, opens input devices, manages terminal sessions, captures the keyboard with `EVIOCGRAB`, paints the screen and processes the control channel. It was previously named `launchpad.c`. |
| `src/config.c` / `config.h` | Sectioned configuration parser with `include` and escaped values. |
| `src/terminal.c` / `terminal.h` | Terminal emulator, PTY (`forkpty`), ANSI sequence handling and scrollback. |
| `src/screen.c` / `screen.h` | Opens `/dev/fb0`, maps the framebuffer and sends eink updates. |
| `src/pixop.c` / `pixop.h` | Pixel copying and image helpers. |
| `src/font.c` / `font.h` | `.hex` font loading. |
| `src/dynstring.c` / `dynstring.h` | Dynamic strings used for the saved framebuffer and other buffers. |
| `src/myts.h` | Shared structures (`struct app`, `struct sess`, global arguments). |
| `src/linux/` | Vendored kernel headers for the eink framebuffer (`fb.h`, `einkfb.h`). |

## KUAL package

| File | Purpose |
|---|---|
| `kual/extensions/myts/config.xml` | Declares the extension to KUAL and points to the JSON menu. |
| `kual/extensions/myts/menu.json` | Menu: Terminal 1/2/3, Stop MyTS and Restart MyTS. |
| `kual/extensions/myts/myts.sh` | Launcher. Creates the FIFO, starts `myts`, sends the command to open a terminal and manages the process. |
| `kual/extensions/myts/bin/myts` | Compiled Kindle 3 binary (soft-float, static). |
| `kual/extensions/myts/bin/myts.ini` | Device, key, font and scrollback configuration. |
| `kual/extensions/myts/bin/keydefs.ini` | Kindle 3 key names and codes. |
| `kual/extensions/myts/bin/ter-u12n.hex` | Default 6x12 font. |

On the Kindle, this directory is copied as-is to `/mnt/us/extensions/myts`.

## Tools and build outputs

| Path | Purpose |
|---|---|
| `Makefile` | Build, toolchain download, KUAL copy and packaging. |
| `tools/bdf2hex` | Converts a BDF font to the `.hex` format used by `myts`. |
| `build/` | Object files and intermediate binary. Removed by `make clean`. |
| `dist/` | `myts-kual.zip`, ready to install. Removed by `make clean`. |
| `toolchain/` | `armv6-linux-musleabi` toolchain downloaded by `make k3`. |

## Execution flow

```
KUAL
  │
  ├─ runs /mnt/us/extensions/myts/myts.sh 1
  │     ├─ creates /var/tmp/myts.special (FIFO)
  │     ├─ starts bin/myts in the background
  │     ├─ stores the PID in /var/tmp/myts.pid
  │     └─ queues a helper that writes "A1" to the FIFO after 3 s
  │
  └─ the helper wakes myts with: echo send 0 > /proc/keypad
        │
        └─ myts reads "A1", opens the framebuffer, creates/reuses terminal 1,
           saves the current screen and captures the keyboard with EVIOCGRAB
```

Pressing the key configured as `TermEnd` (default `Right<`) restores the saved
framebuffer, releases input capture and shows the KUAL menu again. The `myts`
process stays alive so terminals 2 and 3 can be opened without restarting it.

`Stop MyTS` sends the termination signal and removes the FIFO and PID file.
`Restart MyTS` does the same and starts again with terminal 1.

## Control channel

`myts` does not open a terminal by itself. It waits for a command on the FIFO
configured by `SpecialIn` in `myts.ini`, which defaults to
`/var/tmp/myts.special`.

- The first byte of the command must be `A`.
- The second byte is the terminal number (`1`, `2` or `3`).
- The rest is ignored.

The FIFO descriptor is **not included in the main `select()` loop**. That is
why `myts.sh` also writes to `/proc/keypad` afterwards to generate an event and
wake the process. Both steps are required.

## Configuration and font lookup

- `myts` first tries to open `myts.ini` in the current directory.
- If it does not exist, it looks next to the executable (`/proc/self/exe`).
- `include` files (for example `keydefs.ini`) are resolved relative to the
  executable.
- The font is opened relative to the **current directory**, not the executable.
  This is why `myts.sh` changes into `bin/` before starting.

You can force a different configuration with:

```sh
./myts --cfg /path/to/myts.ini
```

## Framebuffer and terminal

- `screen.c` opens `/dev/fb0` and uses eink ioctls to update regions.
- `myts_app.c` saves the current screen before entering terminal mode and
  restores it on exit.
- `terminal.c` creates a PTY with `forkpty()` and runs `/bin/sh`.
- Shell output is rendered with the `.hex` font and the helpers in `pixop.c`.

## Why the binary must be soft-float

The Kindle 3 userspace is EABI soft-float. A hard-float binary may contain VFP
instructions and expect a different ABI, which can cause failures or `SIGILL`
on the device. The Makefile uses `armv6-linux-musleabi`, which produces a
static soft-float binary.
