#!/usr/bin/env sh
# Headless smoke test: boot -> title -> start -> level 1.
#
# Requires a legally owned ROM. The ROM is never copied into the repository.
#
# Usage:
#   tools/smoke.sh [/path/to/Mr.\ Nutz\ (USA)\ (En,Fr).sfc]
#
# Environment:
#   SNESRECOMP_ROM  ROM path when no argument is given
#   BUILD_DIR       build directory (default: build)
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
BUILD_DIR=${BUILD_DIR:-"$ROOT/build"}
BIN="$BUILD_DIR/MrNutzRecomp"
ROM=${1:-${SNESRECOMP_ROM:-"$ROOT/ROM/Mr. Nutz (USA) (En,Fr).sfc"}}

if [ ! -x "$BIN" ]; then
    echo "smoke: $BIN not found; run ./build.sh first" >&2
    exit 1
fi
if [ ! -f "$ROM" ]; then
    echo "smoke: ROM not found: $ROM" >&2
    echo "smoke: pass a path, set SNESRECOMP_ROM, or place the ROM in ROM/" >&2
    exit 1
fi

# The host anchors its working directory to the executable's directory, so a
# relative ROM path would resolve under build/. Make it absolute first.
case "$ROM" in
    /*) ;;
    *) ROM="$(CDPATH= cd -- "$(dirname -- "$ROM")" && pwd)/$(basename -- "$ROM")" ;;
esac

OUT_DIR=${SMOKE_DIR:-"$(mktemp -d "${TMPDIR:-/tmp}/mrnutz-smoke.XXXXXX")"}
mkdir -p "$OUT_DIR"
SCRIPT="$OUT_DIR/route.txt"
SHOT="$OUT_DIR/level1.ppm"
LOG="$OUT_DIR/run.log"

cat > "$SCRIPT" <<'EOF'
# Title appears around frame 900. Start the game, let the level card finish,
# then move right and jump so the route exercises input and scrolling.
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
EOF

set +e
(
    cd "$BUILD_DIR"
    SDL_VIDEODRIVER=dummy \
    SDL_AUDIODRIVER=dummy \
    SNESRECOMP_RUN_FRAMES=4000 \
    SNESRECOMP_SCREENSHOT="$SHOT" \
    SNESRECOMP_SCREENSHOT_FRAME=2500 \
    ./MrNutzRecomp --no-launcher --script "$SCRIPT" "$ROM"
) > "$LOG" 2>&1
STATUS=$?
set -e

if [ "$STATUS" -ne 0 ]; then
    echo "smoke: game exited with status $STATUS" >&2
    tail -30 "$LOG" >&2
    exit "$STATUS"
fi
if [ ! -s "$SHOT" ]; then
    echo "smoke: no screenshot was written: $SHOT" >&2
    tail -30 "$LOG" >&2
    exit 1
fi

python3 - "$SHOT" <<'PY'
import sys

path = sys.argv[1]
with open(path, "rb") as f:
    blob = f.read()
if not blob.startswith(b"P6"):
    raise SystemExit(f"smoke: unexpected screenshot header: {blob[:16]!r}")
parts = blob.split(b"\n", 3)
if len(parts) < 4:
    raise SystemExit("smoke: truncated PPM header")
w, h = (int(v) for v in parts[1].split()[:2])
pixels = parts[3]
if len(pixels) < w * h * 3:
    raise SystemExit("smoke: truncated PPM body")
sample = pixels[::max(1, len(pixels) // 4096)]
non_black = sum(1 for b in sample if b > 8)
if non_black * 100 < len(sample):
    raise SystemExit("smoke: screenshot is almost entirely black")
print(f"smoke: screenshot {w}x{h}, {non_black}/{len(sample)} sampled bytes non-black")
PY

echo "smoke: PASS"
echo "smoke: log        $LOG"
echo "smoke: screenshot $SHOT"
