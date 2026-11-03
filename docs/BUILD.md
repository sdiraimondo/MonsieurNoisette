# Build

The project builds on Linux. Windows and macOS are not validated targets yet.

## Requirements

- CMake 3.20+
- Ninja
- a C/C++ compiler
- Python 3.11+ (regeneration)
- Rust toolchain (the framework's native analyzer builds on demand)
- the SDL3 development dependencies. The build fetches SDL3 when no system
  package is found, but it still needs the X11/Wayland/audio/udev headers.

On an immutable Fedora/Bazzite host the supported path is a `distrobox`
container. This is the container used during the initial port:

```sh
distrobox create --name mrnutz-build --image fedora-toolbox:44
distrobox enter mrnutz-build
```

Inside the container:

```sh
sudo dnf install -y \
  cmake ninja-build gcc gcc-c++ make git python3 \
  mesa-libGL-devel mesa-libEGL-devel mesa-libGLES-devel \
  libX11-devel libXext-devel libXrandr-devel libXi-devel \
  libXcursor-devel libXinerama-devel libXfixes-devel \
  wayland-devel wayland-protocols-devel libxkbcommon-devel \
  alsa-lib-devel pipewire-devel pulseaudio-libs-devel \
  systemd-devel libusb1-devel dbus-devel \
  jack-audio-connection-kit-devel
```

Then, from the repository root:

```sh
distrobox enter mrnutz-build -- sh -c \
  'cd /path/to/MonsieurNoisette && ./build.sh'
```

## Normal build

```sh
git submodule update --init --recursive
tools/regen.sh --rom /path/to/Mr.\ Nutz\ \(USA\)\ \(En,Fr\).sfc
./build.sh
```

The result is `build/MrNutzRecomp`.

`build.sh` uses Ninja and Release by default. Override with
`CMAKE_GENERATOR`, `CMAKE_BUILD_TYPE`, or `BUILD_DIR`. Set `SDL3_DIR` only if
you want to use a specific SDL3 install; otherwise CMake fetches the pinned
framework dependency.

## ROM handling

No ROM is committed or shipped. `tools/regen.sh` verifies the ROM against
`rom_identity.txt` before generating `src/gen/`. `src/gen/` and
`recomp/funcs.h` are generated from copyrighted ROM data and are gitignored.

The framework compiles against the ROM at runtime; `rom.cfg` and the launcher
cache the path beside the executable and are also gitignored.

## Smoke test

```sh
tools/smoke.sh /path/to/Mr.\ Nutz\ \(USA\)\ \(En,Fr\).sfc
```

This boots headlessly, reaches the title screen, starts the game, enters
level 1, and writes a screenshot. It does not validate audio or a real gamepad.

## Audio probe

```sh
tools/audio_probe.sh /path/to/Mr.\ Nutz\ \(USA\)\ \(En,Fr\).sfc
```

This captures the native S-DSP output (s16 stereo, 32 040 Hz) over the title
and level 1, writes a WAV beside the capture, and fails when the stream is
silent. It proves the emulated audio path works; listening is still the final
check.

## Virtual display checks

The ImGui launcher and the in-game overlays can be exercised without a
physical monitor. Force the X11 backend, because SDL3 otherwise prefers a
Wayland session if one is present:

```sh
Xvfb :99 -screen 0 1280x1024x24 -nolisten tcp &
cd build
DISPLAY=:99 SDL_VIDEODRIVER=x11 SDL_AUDIO_DRIVER=dummy \
  ./MrNutzRecomp --launcher ../ROM/Mr.\ Nutz\ \(USA\)\ \(En,Fr\).sfc
# from another shell, once the launcher is visible:
DISPLAY=:99 import -window root /tmp/launcher.png
```

`PLAY` starts the game; `xdotool` can then drive the keyboard. The framework's
virtual-pad self-test checks the modal panels end to end:

```sh
DISPLAY=:99 SDL_VIDEODRIVER=x11 SDL_AUDIO_DRIVER=dummy \
  SNESRECOMP_OVERLAY_SELFTEST_PAD=1200 SNESRECOMP_RUN_FRAMES=1500 \
  ./MrNutzRecomp --no-launcher ../ROM/Mr.\ Nutz\ \(USA\)\ \(En,Fr\).sfc
```

It must print
`[overlay_selftest_pad] ok: browser and rewind both opened and closed from the pad`.
This path uses a virtual controller; it does not replace a physical pad check.

## Setup pack

The player-facing zip is a setup pack: a host built without generated code,
the framework sources and the recompiler. The player's own ROM is recompiled
on first run. Build it from a tree with no `src/gen/*.c` and no
`recomp/funcs.h`:

```sh
cmake -S . -B build-setup -G Ninja -DCMAKE_BUILD_TYPE=Release \
  -DSNESRECOMP_SETUP_HOST=ON
cmake --build build-setup --parallel
scripts/package_release.sh build-setup linux-x64 --embed-toolchain
```

`--embed-toolchain` copies the `cmake-clang-v1` pack named by
`RETCOMM_TOOLCHAIN_DIR` into the zip; fetch it with
`snesrecomp/tools/ci/fetch_toolchain.sh --artifact linux-x64`. Without it the
zip is much smaller, but the first run must download the pack, or fall back to
the system cmake/compiler, which then needs the OpenGL development headers.
The GitHub release workflow embeds the pack and passes the matching artifact
tag. `scripts/package_release.sh` runs the SDK generate smoke test and refuses
to package a ROM, `src/gen/` or `recomp/funcs.h`.
