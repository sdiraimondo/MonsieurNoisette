#!/usr/bin/env sh
# Configure and build MrNutzRecomp.
#
# The framework fetches SDL3 when no system package is found, so no local
# SDL3 prefix is required. Set SDL3_DIR only when you intentionally want to
# use a specific SDL3 installation.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
BUILD_DIR=${BUILD_DIR:-"$ROOT/build"}
GENERATOR=${CMAKE_GENERATOR:-Ninja}
BUILD_TYPE=${CMAKE_BUILD_TYPE:-Release}

CMAKE_ARGS="-S $ROOT -B $BUILD_DIR -G $GENERATOR -DCMAKE_BUILD_TYPE=$BUILD_TYPE"
if [ -n "${SDL3_DIR:-}" ]; then
    CMAKE_ARGS="$CMAKE_ARGS -DSDL3_DIR=$SDL3_DIR"
fi

# shellcheck disable=SC2086
cmake $CMAKE_ARGS
cmake --build "$BUILD_DIR" --config "$BUILD_TYPE" --parallel
