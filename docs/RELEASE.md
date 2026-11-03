# Release checklist

The player-facing artifact is a **setup pack**: a host built without recompiled
code, plus the framework sources, the recompiler and (by default) the
`cmake-clang-v1` toolchain. The player supplies their own ROM; the launcher
generates, rebuilds and relaunches into the playable game. A pack never
contains a ROM, `src/gen/*.c` or `recomp/funcs.h`.

## 1. Preflight

- physical controller: jump, run/attack, pause, shoulder buttons if used;
- listen to the audio on a real output device;
- play through the first level;
- launcher `Settings` and `Mods` panels;
- fullscreen on a real window manager;
- `tools/smoke.sh` and `tools/audio_probe.sh` on the release commit;
- `git status` is clean and `main` is pushed.

The automatable checks and their evidence are in
[`PORT_STATUS.md`](PORT_STATUS.md).

## 2. Pick the version

Edit `VERSION` (for example `1.0.0`), update the date in
[`PORT_STATUS.md`](PORT_STATUS.md), commit and push. The release workflow
uses `VERSION` when there is no `v*` tag yet, and it stamps the same value
into the setup host's lobby pin.

## 3. Local Linux dry run

Build the setup host from a tree with no generated code:

```sh
if [ -d src/gen ]; then mv src/gen /tmp/gen-bak; fi
if [ -f recomp/funcs.h ]; then mv recomp/funcs.h /tmp/funcs-h-bak; fi
cmake -S . -B build-setup -G Ninja -DCMAKE_BUILD_TYPE=Release \
  -DSNESRECOMP_SETUP_HOST=ON
cmake --build build-setup --parallel
if [ -d /tmp/gen-bak ]; then mv /tmp/gen-bak src/gen; fi
if [ -f /tmp/funcs-h-bak ]; then mv /tmp/funcs-h-bak recomp/funcs.h; fi
```

Fetch the toolchain pack and package with it embedded:

```sh
snesrecomp/tools/ci/fetch_toolchain.sh --artifact linux-x64 --tag v1.0.14
RETCOMM_TOOLCHAIN_DIR="$PWD/.cache/toolchain-pack" \
  scripts/package_release.sh build-setup linux-x64 --embed-toolchain
```

`package_release.sh` runs the SDK generate smoke test and refuses ROM-derived
output. Check the zip:

```sh
unzip -l dist/MrNutz-<version>-linux-x64.zip | grep -E \
  'MrNutzRecomp$|assets/fonts/|toolchain/bin/cmake|src/gen/|funcs\.h|\.sfc'
```

Then unzip to a temporary directory, run the setup host, and exercise
**Generate & rebuild** once with a legally owned ROM. It must regenerate,
compile and relaunch into a launcher with `PLAY`.

## 4. Publish

Use the **Release** workflow (Actions → Release → Run workflow):

- `version`: the value in `VERSION` (or leave empty to bump the latest tag);
- `publish_release`: on;
- `embed_toolchain`: on;
- `toolchain_tag`: pinned (for example `v1.0.14`) for a reproducible pack.

The workflow builds Linux, Windows and macOS packs, tags the commit as
`vX.Y.Z` only after all builds succeed, and publishes the zips with
`SHA256SUMS`. Windows and macOS builds are produced by CI but remain outside
the validated scope of this repository.
