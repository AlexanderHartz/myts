# Guide for agents and contributors

This file summarizes the repository rules and the commands to use when working
on it without breaking Kindle 3 + KUAL support.

## Goal

Keep `myts` buildable and runnable on a Kindle 3 through KUAL, with a package
ready to copy to `/mnt/us/extensions/myts`.

## Invariants

- The binary must be **soft-float**. The Kindle 3 does not reliably run
  hard-float (VFP) binaries. Do not switch to a `gnueabihf` toolchain and do
  not add `-mfloat-abi=hard`.
- Do not reintroduce launchpad or launchpad configuration. KUAL control is
  handled by `kual/extensions/myts/myts.sh`.
- The runtime files (`myts`, `myts.ini`, `keydefs.ini`, `ter-u12n.hex`) must
  stay together in `kual/extensions/myts/bin/`.
- `myts.sh` starts `myts` from that directory because the font is looked up
  relative to the current directory. Do not remove that `cd` without adapting
  the code.
- The control channel is the FIFO `/var/tmp/myts.special`, configured through
  `SpecialIn` in `myts.ini`. The script creates the FIFO, sends `A1`/`A2`/`A3`
  and wakes the process with `echo send 0 > /proc/keypad`.
- Do not manually edit `build/`, `dist/` or `toolchain/`; they are generated
  artifacts ignored by git.
- Do not commit unless explicitly asked.

## Common commands

```sh
make k3      # Kindle 3 build: downloads the toolchain, builds and updates the extension
make         # native build on an ARM host with musl-gcc; leaves build/myts
make kual    # copies build/myts to kual/extensions/myts/bin/myts
make zip     # creates dist/myts-kual.zip with extensions/myts
make clean   # removes build/ and dist/; keeps the extension binary
```

## Minimum verification

After changing code or configuration:

```sh
make k3
file kual/extensions/myts/bin/myts
readelf -h kual/extensions/myts/bin/myts | grep Flags
sh -n kual/extensions/myts/myts.sh
python3 -m json.tool kual/extensions/myts/menu.json >/dev/null
```

`readelf` must show `ELF 32-bit LSB executable, ARM, EABI5` and `soft-float
ABI`. If it shows `hard-float ABI` or VFP instructions, the binary is not valid
for this fork.

If QEMU is available, a quick test is to run the binary with a test
configuration and check that it loads `ter-u12n.hex` and enters the `select`
loop without `SIGILL` or `SIGSEGV`.

## Code structure

- `src/myts.c`: program entry point, event loop, sessions and timers.
- `src/myts_app.c`: main application: keyboard input, terminal sessions,
  `EVIOCGRAB` capture, screen painting and the control channel. It was
  previously named `launchpad.c`; the name was changed when the external
  launcher was removed.
- `src/config.c` / `src/config.h`: configuration reader with sections and
  `include` support.
- `src/terminal.c` / `src/terminal.h`: terminal emulator, PTY and scrollback.
- `src/screen.c` / `src/screen.h`: framebuffer and eink updates.
- `src/pixop.c` / `src/pixop.h`: pixel copying and image helpers.
- `src/font.c` / `src/font.h`: `.hex` font loading.
- `src/dynstring.c` / `src/dynstring.h`: dynamic strings.
- `src/linux/`: kernel headers used by the eink framebuffer.
- `tools/bdf2hex`: BDF-to-`.hex` font converter.
- `kual/extensions/myts/`: package copied to the Kindle.

## Code conventions

- Follow the existing style: C with tabs and static functions for internal
  helpers.
- Do not add new external dependencies without a strong reason.
- Keep configuration changes compatible with `myts.ini` and `keydefs.ini`, and
  update the documentation if their meaning changes.
- Kindle 3 key symbols are documented in `docs/CONFIGURATION.md`; if you change
  `keydefs.ini`, update that document.

## Documentation

- `README.md`: landing page and quick start.
- `docs/STRUCTURE.md`: repository map and architecture.
- `docs/BUILD.md`: building and packaging.
- `docs/INSTALL.md`: installing on the Kindle.
- `docs/USAGE.md`: usage and keyboard.
- `docs/CONFIGURATION.md`: configuration reference.
- `docs/TROUBLESHOOTING.md`: diagnostics.

If a change affects how the program is built, installed or used, update the
corresponding document in the same change.
