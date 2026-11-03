# Mr. Nutz (SNES) Recompilation

A native recompilation of **Mr. Nutz** (USA, `Mr. Nutz (USA) (En,Fr).sfc`) using
[snesrecomp](https://github.com/RetroPortingToolKit/snesrecomp).

> **You must legally own a copy of the game.** No ROM data is distributed with
> this project, in the repository or in any release. Generated C is produced
> locally from your own ROM and is never committed.

## Status

The game boots, reaches the title screen, starts a game and renders level 1.
Input, audio, save states, the launcher, pause, the save-state browser, rewind
and a 30-minute soak test have been validated, and a fresh clone has been
verified end to end with the pinned submodules, regeneration, build and smoke
test. Physical gamepad buttons, the launcher's Settings/Mods panels, the
full-chapter playthrough and fullscreen on a real window manager still need a
session with a real display and controller. The setup pack's Generate & rebuild
path has been exercised end to end from an unpacked zip.

This is a work in progress. See [`docs/PORT_STATUS.md`](docs/PORT_STATUS.md) for
the detailed state and [`docs/PORT_NOTES.md`](docs/PORT_NOTES.md) for the
addresses and known issues carried over from the previous host.

## Framework

This port is built on
[snesrecomp](https://github.com/RetroPortingToolKit/snesrecomp), pinned as a Git
submodule at:

- [`98f41838443a7cd7f9d56bec41387a6ebfc3bcbc`](https://github.com/RetroPortingToolKit/snesrecomp/commit/98f41838443a7cd7f9d56bec41387a6ebfc3bcbc)

The same pin is recorded in [`framework_pins.txt`](framework_pins.txt) and
explained in [`docs/FRAMEWORK.md`](docs/FRAMEWORK.md). `98f41838` is the
framework revision that generated and validated the current port. Upstream
`main` has newer commits; updating the framework is a separate change that must
be regenerated and revalidated.

## ROM identity

| | |
|---|---|
| File | `Mr. Nutz (USA) (En,Fr).sfc` |
| Mapping | LoROM |
| Region | USA |
| Size | 1,048,576 bytes |
| CRC32 | `a99bdd9a` |
| SHA-256 | `3472dd574b50aed2fa998f464398db4fbb00f5a300a672c3737ee9336a008a16` |

`tools/regen.sh` verifies the ROM against `rom_identity.txt` before generating
`src/gen/`.

## Build

Prerequisites: CMake, Ninja, a C/C++ compiler, Python 3.11+ and a Rust
toolchain. SDL3 is fetched by the framework when no system package is found.

```sh
git submodule update --init --recursive
tools/regen.sh --rom /path/to/Mr.\ Nutz\ \(USA\)\ \(En,Fr\).sfc
./build.sh
```

The result is `build/MrNutzRecomp`.

On an immutable Fedora/Bazzite host, build inside the `distrobox` container
described in [`docs/BUILD.md`](docs/BUILD.md).

## Run

```sh
./build/MrNutzRecomp
./build/MrNutzRecomp /path/to/Mr.\ Nutz\ \(USA\)\ \(En,Fr\).sfc
```

With no ROM argument, the launcher opens a ROM picker and caches the verified
path in `rom.cfg` beside the executable.

## Controls

Keyboard and gamepad use the framework's standard SNES mapping. Defaults are
documented in [`docs/CONTROLS.md`](docs/CONTROLS.md); rebind them in
`keybinds.ini` and `config.ini` beside the executable.

System shortcuts include `F11` for the save-state menu, `F12` for rewind,
`Shift+P` for pause, `Tab` for turbo and `F` for performance display.

## Layout

| Path | What lives there |
|---|---|
| `recomp/` | Analysis input: `bank*.cfg`, `symbols.toml`, generated `funcs.h` |
| `rom_identity.txt` | ROM digests — read by the build, `tools/regen.sh` and CI |
| `src/main.c` | Host shim and game identity |
| `src/game_rtl.c` | The actual port: frame driver hooks |
| `src/host_contract.c` | Trace hooks for production builds |
| `src/gen_stubs.c` | Hand-written bodies for unresolved generated code |
| `src/gen/` | Generated C; never committed — regenerate locally |
| `snesrecomp/` | Framework submodule, pinned by `framework_pins.txt` |
| `recomp-ui/` | Pre-boot launcher submodule (ROM picker, Generate & rebuild) |
| `tools/` | `regen.sh`, `smoke.sh`, `audio_probe.sh` |
| `scripts/` | `package_release.sh` — player-facing setup pack |
| `docs/` | Build, framework pin, controls, coverage, port status and notes |
| `LICENSE` | PolyForm Noncommercial 1.0.0 for the project's own code |

## Smoke test

```sh
tools/smoke.sh /path/to/Mr.\ Nutz\ \(USA\)\ \(En,Fr\).sfc
```

The test boots headlessly, reaches the title screen, starts a game, enters
level 1 and writes a screenshot. It does not validate audio or a physical
gamepad.

`tools/audio_probe.sh` captures the native DSP output over the same route,
writes a WAV and fails if the stream is silent. It does not replace listening
on a real output device.

## Distribution

`scripts/package_release.sh` builds a **setup pack**: the setup host, the
recompiler and this source tree. The player supplies their own ROM and the
launcher generates and rebuilds locally. No ROM, `src/gen/` or
`recomp/funcs.h` is included in the zip.

## License

This project's own source code and documentation are released under the
[**PolyForm Noncommercial License 1.0.0**](LICENSE). Commercial use is not
permitted; personal, educational and community use is welcome.

The `snesrecomp` framework is a separate work under the same license family;
see `snesrecomp/LICENSE`. ROM data and generated recompiler output are not
covered by either license and are never distributed here.
