# Framework pin

This port is built on [snesrecomp](https://github.com/RetroPortingToolKit/snesrecomp).
The framework is a Git submodule, pinned at:

| Component | Commit |
|---|---|
| `snesrecomp` | [`98f41838443a7cd7f9d56bec41387a6ebfc3bcbc`](https://github.com/RetroPortingToolKit/snesrecomp/commit/98f41838443a7cd7f9d56bec41387a6ebfc3bcbc) |
| `snesrecomp/lib/recomp-net` | `8c76fb643339144a3a84d5ba8f5defe6250dcd26` |
| `snesrecomp/lib/retcomm-rbengine` | `2a03e73693acee0fb78076ea058642c931bef12e` |

The same values are recorded in [`framework_pins.txt`](../framework_pins.txt).
`98f41838` is the framework revision that generated and validated the current
port; it is the parent of the newer framework `main` commits, so it can be
updated later without rewriting history.

## Reproduce the checkout

```sh
git submodule update --init --recursive
bash snesrecomp/tools/ci/record_pins.sh --root . --check framework_pins.txt
```

## Upgrade procedure

Do not mix a framework update with gameplay or documentation changes.

1. Check out the new framework commit inside the submodule:
   ```sh
   git -C snesrecomp fetch origin
   git -C snesrecomp checkout <new-commit>
   git -C snesrecomp submodule update --init --recursive
   ```
2. Regenerate and rebuild:
   ```sh
   tools/regen.sh --rom /path/to/Mr.\ Nutz\ \(USA\)\ \(En,Fr\).sfc
   ./build.sh
   ```
3. Run `tools/smoke.sh` and the manual checks in `docs/PORT_STATUS.md`.
4. Update `framework_pins.txt` from `record_pins.sh` output.
5. Commit the submodule gitlink, `.gitmodules` changes (if any), the generated
   pin file, and the regenerated `recomp/funcs.h`.
6. Keep the old pin in the commit message so a regression can be bisected.

`tools/regen.sh` verifies the ROM against `rom_identity.txt`; a framework
upgrade does not change the ROM identity.
