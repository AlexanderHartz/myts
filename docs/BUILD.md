# Building and packaging

## Requirements

To build on a Linux x86_64 PC:

- `make`
- `curl`
- `tar`
- `zip`
- internet access the first time (to download the toolchain)

The native ARM build also requires `musl-gcc`.

## Kindle 3 build (recommended)

```sh
make k3
```

This command:

1. Downloads the `armv6-linux-musleabi` toolchain into `toolchain/` if needed.
2. Compiles every source file in `src/` with static soft-float musl.
3. Writes the intermediate binary to `build/myts`.
4. Copies it to `kual/extensions/myts/bin/myts`.

The toolchain is downloaded from:

```
https://musl.cc/armv6-linux-musleabi-cross.tgz
```

If you already have the toolchain and only want to check that it is present:

```sh
make toolchain
```

## Native build on an ARM host

If you work on a Raspberry Pi or another ARM Linux host with `musl-gcc`:

```sh
make
```

The result is `build/myts`. To copy it into the KUAL extension:

```sh
make kual
```

On a normal x86_64 PC, `make` will fail because `musl-gcc` is not available;
use `make k3`.

## Packaging

```sh
make zip
```

Generates `dist/myts-kual.zip`, containing `extensions/myts/` with the binary
and all runtime files. This command does not rebuild: it packages whatever is
currently in `kual/extensions/myts`.

## Cleaning

```sh
make clean
```

Removes `build/` and `dist/`. It does **not** remove the prebuilt binary at
`kual/extensions/myts/bin/myts`, so the extension remains usable.

## Verifying the binary

```sh
file kual/extensions/myts/bin/myts
readelf -h kual/extensions/myts/bin/myts | grep Flags
readelf -A kual/extensions/myts/bin/myts | grep -E 'CPU_arch|FP_arch|VFP'
```

You should see:

- `ELF 32-bit LSB executable, ARM, EABI5`
- `statically linked`
- `soft-float ABI`
- a compatible architecture (`v5T` or `v6`)
- no VFP instructions

If it shows `hard-float ABI` or `VFP`, the binary is not valid for this fork.

## Quick configuration and menu checks

```sh
sh -n kual/extensions/myts/myts.sh
python3 -m json.tool kual/extensions/myts/menu.json >/dev/null
```

## Common problems

### `make k3` cannot download the toolchain

Check your connection and make sure `curl` and `tar` are installed. If the
download was interrupted, remove `toolchain/` and run `make k3` again.

### `make` says `musl-gcc: not found`

You are on an x86_64 host without native musl. Use `make k3`.

### The binary does not start on the Kindle

Check with `readelf` that it is soft-float. Do not use `gnueabihf` toolchains
or add `-mfloat-abi=hard`.

### `zip: command not found`

Install `zip` or package the `kual/extensions/myts` directory manually.
