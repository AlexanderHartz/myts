# Installing on the Kindle 3

## Requirements

- Kindle 3 with jailbreak.
- KUAL installed and working.
- The `kual/extensions/myts` directory from this repository, or
  `dist/myts-kual.zip`.

There is no need to stop the Kindle framework. `myts.sh` is designed to run
`myts` alongside the normal system.

## USB installation

1. Connect the Kindle to the computer over USB.
2. Copy the `kual/extensions/myts` directory into `/mnt/us/extensions/` so
   that the result is:

   ```
   /mnt/us/extensions/myts/
   ├── config.xml
   ├── menu.json
   ├── myts.sh
   └── bin/
       ├── myts
       ├── myts.ini
       ├── keydefs.ini
       └── ter-u12n.hex
   ```

3. Safely eject the Kindle.
4. Open KUAL and enter **MyTS Terminal**.
5. Choose **Terminal 1**.

You can also extract `dist/myts-kual.zip` at the root of the Kindle: the zip
contains `extensions/myts/`, so the files land in the right place.

## Permissions

The `/mnt/us` partition normally mounts files as executable. `myts.sh` also
checks the binary and runs `chmod +x` if needed. KUAL runs the extension with
root permissions, which are required to open `/dev/fb0`, `/dev/input/event*`
and `/proc/keypad`.

## First run

When you tap **Terminal 1**, `myts.sh`:

1. Creates the FIFO `/var/tmp/myts.special`.
2. Starts `myts` in the background.
3. Waits one second for it to be ready.
4. After about three seconds, writes `A1` to the FIFO to open the terminal.

The short delay is intentional: it lets KUAL finish refreshing the screen
before `myts` draws the terminal. After that, KUAL stays in the background and
the screen shows the terminal.

The launcher log is written to:

```
/tmp/myts.log
```

## Updating

1. In KUAL, tap **Stop MyTS**.
2. Copy the new `kual/extensions/myts` directory over the old one.
3. Open **Terminal 1** again.

If you only updated the binary, you can copy
`kual/extensions/myts/bin/myts` directly.

## Uninstalling

1. In KUAL, tap **Stop MyTS**.
2. Delete `/mnt/us/extensions/myts`.
3. Optionally remove the temporary files:

```sh
rm -f /var/tmp/myts.special /var/tmp/myts.pid /tmp/myts.log
```

## Checking the installation

From a shell on the Kindle (SSH or USB networking):

```sh
ls -l /mnt/us/extensions/myts
ls -l /mnt/us/extensions/myts/bin
sh /mnt/us/extensions/myts/myts.sh 1
cat /tmp/myts.log
ps | grep myts
```

## Installation problems

### MyTS does not appear in KUAL

Check that `config.xml` and `menu.json` are directly in
`/mnt/us/extensions/myts/` (not inside an extra subdirectory). On your PC,
validate the JSON before copying:

```sh
python3 -m json.tool kual/extensions/myts/menu.json >/dev/null
```

### Nothing happens when tapping a terminal

Run the launcher manually and check the log:

```sh
sh /mnt/us/extensions/myts/myts.sh 1
cat /tmp/myts.log
ps | grep myts
```

If the log says the font is missing, make sure `ter-u12n.hex` is in
`/mnt/us/extensions/myts/bin/`.

### `Permission denied` or `Illegal instruction`

- `Permission denied`: the binary is not executable or the partition is
  mounted without execute permission. `myts.sh` tries `chmod +x`; if the
  problem persists, copy the binary and the files from `bin/` to `/tmp` and run
  it from there only as a test.
- `Illegal instruction`: you are probably using a hard-float binary. Rebuild
  with `make k3` and verify on the PC with `readelf` that it is soft-float.
