# Port notes

Working notes carried over from the previous host. Treat every address below as
**unverified** unless the validation column says otherwise; the old port had a
large speculative WRAM map and that caused wrong conclusions.

## ROM identity

| Field | Value |
|---|---|
| ROM | `Mr. Nutz (USA) (En,Fr).sfc` |
| Size | 1,048,576 bytes |
| Mapping | LoROM |
| CRC32 | `a99bdd9a` |
| SHA-256 | `3472dd574b50aed2fa998f464398db4fbb00f5a300a672c3737ee9336a008a16` |
| Reset vector | `$00:80B5` |
| Native NMI | `$00:8349` |
| Native IRQ | `$00:83B3` |

## Old NMI path (from the previous analysis)

```text
$00:8349  JML $80:834D
$80:834D  PHA/PHX/PHY/PHD/PHB
          JMP ($01DC)
$01DC     = $8357 -> JML $9DB413
$9DB413   reads V counter, subtracts $E0
          V=$E0/$E1/$E2 -> JMP ($01DE) = $9D:E1B6 (frame processing)
          otherwise     -> enable NMI, RTI
```

The framework's beam-aligned driver now owns this timing. Do not reintroduce a
manual beam advance or a custom NMI loop without evidence that the shared driver
fails for this title.

## WRAM addresses from the old port

| Address | Old name | Meaning | Validated? |
|---|---|---|---|
| `$0B9D` | `waiting_for_vblank` | main-loop vblank flag | No |
| `$057E` | `game_mode_ptr` | mode dispatch pointer (`$D0E8`, `$CC08`, `$D1D7`) | No |
| `$01DC` | `nmi_vector` | NMI entry vector (`$8357`, `$835B`) | No |
| `$01DE` | `frame_proc_vec` | frame-processing vector (`$E1B6`) | No |
| `$1A7F` | `inidisp_shadow` | shadow copied to `$2100` | No |
| `$00EC` | `music_track_id` | music track byte (old MP3 plan) | No |
| `$0570` | `blink_timer` | 16-bit title blink timer | No |
| `$056E`/`$056F` | blink sub/fade counters | title blink state | No |
| `$10C2` | WRAM-resident code | old report claimed it never loaded | No — see below |

If a value is needed for a new hook, confirm it in a running build with a save
state, the debug server, or a bounded `--script` probe before adding it back to
`src/variables.h`.

## Old known issues

These were reported against the previous host. They were re-tested during the
Phase 1 validation (2026-11-03):

- **Title-screen cursor blink** — not reproduced. Frames 700–1080 were dumped:
  no black frame after the logo, and the title's mean brightness stays at
  108–109/255.
- **Framerate stutter** — not observed in a 30-minute soak (59.5 fps average).
  A per-frame jitter histogram is not instrumented, so only average pacing is
  proven.
- **WRAM code at `$10C2`** — not reproducible. A full WRAM write trace
  (`SNESRECOMP_WRAM_TRACE_FILE`, `$0000`–`$1FFF`) over 2 500 frames shows the
  byte is never written, and the ROM contains no `$7E10C2` reference. The old
  claim was a false lead; do not add it back to `src/variables.h`.
- **Gamepad mapping** — the old custom layout was removed. The framework uses
  the standard SNES mapping; the DualSense Edge is detected and assigned to
  player 1. Physical button checks remain manual.

## Current validation route

`tools/smoke.sh` runs:

```text
wait 950
press start 2
wait 900
press right 60
wait 100
press right+a 2
wait 100
press right 100
wait 300
quit
```

Observed with the pinned framework:

| Frame | Scene |
|---|---|
| 880 | title screen |
| 1800 | "WOODY LAND JOURNEY: 1" level card |
| 2500 | level 1 gameplay |

The route is a smoke test, not a full gameplay validation.

`tools/audio_probe.sh` uses a longer version of the same route and captures
the native DSP stream. The capture is 40.2 s long with 21 audible seconds,
matching the logo jingle, title theme, level card and level 1 music.
