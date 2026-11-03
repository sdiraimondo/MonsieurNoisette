#!/usr/bin/env sh
# Audio probe: capture the native S-DSP output for a fixed title -> level 1
# route and check that it is not silent.
#
# This bypasses the host's resampler and writes the samples the DSP produced
# (s16 stereo, ~32040 Hz), so it validates the emulated audio path rather than
# the SDL device. Listening is still the final check; this catches "no sound
# at all" and gross rate problems.
#
# Requires a legally owned ROM. Usage:
#   tools/audio_probe.sh [/path/to/Mr.\ Nutz\ (USA)\ (En,Fr).sfc]
#
# Environment:
#   SNESRECOMP_ROM  ROM path when no argument is given
#   BUILD_DIR       build directory (default: build)
#   AUDIO_DIR       directory for the capture (default: a temp dir)
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
BUILD_DIR=${BUILD_DIR:-"$ROOT/build"}
BIN="$BUILD_DIR/MrNutzRecomp"
ROM=${1:-${SNESRECOMP_ROM:-"$ROOT/ROM/Mr. Nutz (USA) (En,Fr).sfc"}}

if [ ! -x "$BIN" ]; then
    echo "audio_probe: $BIN not found; run ./build.sh first" >&2
    exit 1
fi
if [ ! -f "$ROM" ]; then
    echo "audio_probe: ROM not found: $ROM" >&2
    echo "audio_probe: pass a path, set SNESRECOMP_ROM, or place the ROM in ROM/" >&2
    exit 1
fi

case "$ROM" in
    /*) ;;
    *) ROM="$(CDPATH= cd -- "$(dirname -- "$ROM")" && pwd)/$(basename -- "$ROM")" ;;
esac

OUT_DIR=${AUDIO_DIR:-"$(mktemp -d "${TMPDIR:-/tmp}/mrnutz-audio.XXXXXX")"}
mkdir -p "$OUT_DIR"
RAW="$OUT_DIR/dsp.raw"
WAV="$OUT_DIR/dsp.wav"
SCRIPT="$OUT_DIR/route.txt"
LOG="$OUT_DIR/run.log"

cat > "$SCRIPT" <<'EOF'
# Reach level 1 so the capture covers the title theme and the level theme.
wait 950
press start 2
wait 900
press right 60
wait 500
quit
EOF

set +e
(
    cd "$BUILD_DIR"
    SDL_VIDEODRIVER=dummy \
    SDL_AUDIO_DRIVER=dummy \
    SNESRECOMP_DSPOUT="$RAW" \
    SNESRECOMP_RUN_FRAMES=4000 \
    ./MrNutzRecomp --no-launcher --script "$SCRIPT" "$ROM"
) > "$LOG" 2>&1
STATUS=$?
set -e

if [ "$STATUS" -ne 0 ]; then
    echo "audio_probe: game exited with status $STATUS" >&2
    tail -30 "$LOG" >&2
    exit "$STATUS"
fi
if [ ! -s "$RAW" ]; then
    echo "audio_probe: no DSP output written" >&2
    tail -30 "$LOG" >&2
    exit 1
fi

python3 - "$RAW" "$WAV" <<'PY'
import array
import math
import sys
import wave

raw_path, wav_path = sys.argv[1], sys.argv[2]
rate = 32040
samples = array.array("h")
with open(raw_path, "rb") as f:
    samples.frombytes(f.read())
frames = len(samples) // 2
if frames == 0:
    raise SystemExit("audio_probe: empty capture")

peak = max(max(samples), -min(samples))
acc = 0
for v in samples:
    acc += v * v
rms = math.sqrt(acc / len(samples))

# Count whole seconds with a non-trivial signal.
second = rate * 2
loud_seconds = 0
for start in range(0, len(samples) - second + 1, second):
    seg = samples[start:start + second]
    a = 0
    for v in seg:
        a += v * v
    if math.sqrt(a / len(seg)) > 20.0:
        loud_seconds += 1

with wave.open(wav_path, "wb") as w:
    w.setnchannels(2)
    w.setsampwidth(2)
    w.setframerate(rate)
    w.writeframes(samples.tobytes())

print(f"audio_probe: {frames / rate:.1f}s captured, peak={peak}, rms={rms:.1f}, "
      f"audible_seconds={loud_seconds}")
if peak < 100 or loud_seconds < 3:
    raise SystemExit("audio_probe: FAIL — the DSP output is silent or nearly silent")
print("audio_probe: PASS")
PY

echo "audio_probe: log $LOG"
echo "audio_probe: wav $WAV"
