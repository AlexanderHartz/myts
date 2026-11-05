# Troubleshooting

## Quick checks

From a shell on the Kindle:

```sh
cat /tmp/myts.log
ps | grep myts
ls -l /var/tmp/myts.special /var/tmp/myts.pid
ls -l /mnt/us/extensions/myts/bin
```

The launcher log is always the first place to look.

## The terminal does not appear after tapping Terminal 1

- Wait a few seconds: the launcher waits 3 s before opening the terminal.
- Check that the process is alive:

  ```sh
  ps | grep myts
  ```

- Check that the FIFO exists:

  ```sh
  ls -l /var/tmp/myts.special
  ```

- Check the log:

  ```sh
  cat /tmp/myts.log
  ```

- Run the launcher manually to see the error:

  ```sh
  sh /mnt/us/extensions/myts/myts.sh 1
  ```

- If the log says `cannot create special fifo`, make sure `/var/tmp` exists
  and is writable. KUAL runs the extension as root.
- If the process exists but does not respond, try **Stop MyTS** and then
  **Terminal 1** again.

## "No font found" or the terminal closes immediately

`myts` opens the font in the current directory. Check:

```sh
ls -l /mnt/us/extensions/myts/bin/ter-u12n.hex
```

Always run the launcher rather than the binary from another directory.
`myts.sh` changes into `bin/` precisely for this reason.

## "Illegal instruction" or the binary does not start

The binary must be soft-float and static. Verify it on your PC, using a copy of
the binary:

```sh
file myts
readelf -h myts | grep Flags
```

It must say `soft-float ABI`. If it says `hard-float ABI`, rebuild with
`make k3`; do not use a `gnueabihf` toolchain.

## "Permission denied"

- Check permissions:

  ```sh
  ls -l /mnt/us/extensions/myts/myts.sh
  ls -l /mnt/us/extensions/myts/bin/myts
  ```

- `myts.sh` tries to `chmod +x` the binary automatically.
- If `/mnt/us` is mounted without execute permission, copy the binary and the
  files from `bin/` to `/tmp`, make them executable and test from there to
  isolate the problem.

## Some keys do not work

- Make sure you are using the Kindle 3 codes in `bin/keydefs.ini`
  (`Sym = 126`, `Back = 158`, `Home = 102`, etc.).
- Check the real event code:

  ```sh
  evtest /dev/input/event0
  ```

  or, if `evtest` is not available:

  ```sh
  hexdump -C /dev/input/event0
  ```

- Adjust `keydefs.ini` or the key names in `myts.ini`.

## Symbols are shifted or wrong

`Symbols` must contain exactly 28 characters in this order:

```
q w e r t y u i o p
a s d f g h j k l D
z x c v b n m .
```

If one character is missing or extra, every following symbol is shifted. Also
check that `TermSym` points to the key you are using (`Back` or `Sym`).

## I cannot leave the terminal

- The exit key is the one configured in `TermEnd` (`Right<` by default).
- If it does not respond, use **Stop MyTS** from KUAL.
- As a last resort, from SSH:

  ```sh
  killall myts
  rm -f /var/tmp/myts.special /var/tmp/myts.pid
  ```

## The KUAL menu is not restored when leaving the terminal

`myts` saves the framebuffer when it opens a terminal and restores it on exit.
If the screen looks wrong:

1. Tap **Stop MyTS**.
2. Reopen KUAL or press Home/Menu to force a refresh.
3. If the problem persists, restart the Kindle.

## KUAL does not show the extension

Check the paths on the Kindle:

```sh
ls -l /mnt/us/extensions/myts/config.xml
ls -l /mnt/us/extensions/myts/menu.json
```

And validate the JSON on your PC before copying:

```sh
python3 -m json.tool kual/extensions/myts/menu.json >/dev/null
```

The `myts` directory must be directly inside `/mnt/us/extensions/`, not inside
an extra directory.

## Full recovery

From a shell on the Kindle:

```sh
killall myts 2>/dev/null
rm -f /var/tmp/myts.special /var/tmp/myts.pid
```

Then return to KUAL and open **Terminal 1**. If the system becomes unstable,
restart the Kindle.
