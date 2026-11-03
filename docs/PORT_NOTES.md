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
| `$10C2` | WRAM-resident code | old report claimed it never loaded | No |

If a value is needed for a new hook, confirm it in a running build with a save
state, the debug server, or a bounded `--script` probe before adding it back to
`src/variables.h`.

## Old known issues

These were reported against the previous host. Re-test before fixing; the
framework migration may already have resolved them.

- Title-screen cursor blink: manual pixel clearing caused full-screen flicker.
- Framerate stutter despite a stable FPS counter.
- WRAM code at `$10C2` not loading during initialization.
- Gamepad mapping did not match the old custom input layout.

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

Observed with the pre-cleanup binary:

| Frame | Scene |
|---|---|
| 900 | title screen |
| 1800 | "WOODY LAND JOURNEY: 1" level card |
| 2500 | level 1 gameplay |

The route is a smoke test, not a full gameplay validation.
