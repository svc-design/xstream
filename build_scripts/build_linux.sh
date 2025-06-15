#!/usr/bin/env bash
set -e
DIR="$(dirname "$0")/.."
cd "$DIR/go_core"

# Ensure CGO is enabled for Linux builds
if [ "$(go env CGO_ENABLED)" != "1" ]; then
  export CGO_ENABLED=1
fi


# Prefer the clang toolchain bundled with Flutter so the generated library
# links against the same glibc version as the Flutter build.
FLUTTER_BIN=$(command -v flutter || true)
if [ -n "$FLUTTER_BIN" ]; then
  FLUTTER_ROOT=$(readlink -f "$FLUTTER_BIN")
  FLUTTER_ROOT=$(dirname "$FLUTTER_ROOT")
  FLUTTER_ROOT=$(dirname "$FLUTTER_ROOT")
  FLUTTER_ROOT=${FLUTTER_ROOT%/bin}
  CANDIDATE_CC="$FLUTTER_ROOT/usr/bin/clang"
  CANDIDATE_CXX="$FLUTTER_ROOT/usr/bin/clang++"
  if [ -x "$CANDIDATE_CC" ] && [ -x "$CANDIDATE_CXX" ]; then
    CC="$CANDIDATE_CC"
    CXX="$CANDIDATE_CXX"
  fi
fi

: "${CC:=$(command -v clang)}"
: "${CXX:=$(command -v clang++)}"
if [ -z "$CC" ] || [ -z "$CXX" ]; then
  echo "clang/clang++ are required" >&2
  exit 1
fi

export CC
export CXX

CC=$CC GOOS=linux GOARCH=amd64 go build -buildmode=c-shared -o ../bindings/libgo_native_bridge.so

# Copy the library next to the executable so it is bundled with the app
mkdir -p ../linux/lib
cp ../bindings/libgo_native_bridge.so ../linux/lib/
