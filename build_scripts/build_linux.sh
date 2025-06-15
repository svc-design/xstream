#!/usr/bin/env bash
set -e
DIR="$(dirname "$0")/.."
cd "$DIR/go_core"

# Ensure CGO is enabled for Linux builds
if [ "$(go env CGO_ENABLED)" != "1" ]; then
  export CGO_ENABLED=1
fi

# Choose a single compiler toolchain for both Go and Flutter builds.
# Prefer GNU gcc/g++ if available, otherwise fall back to clang/clang++.
if command -v gcc >/dev/null && command -v g++ >/dev/null; then
  CC=$(command -v gcc)
  CXX=$(command -v g++)
elif command -v clang >/dev/null && command -v clang++ >/dev/null; then
  CC=$(command -v clang)
  CXX=$(command -v clang++)
else
  : "${CC:=gcc}"
  : "${CXX:=g++}"
fi

# Disable musl toolchains entirely.
if [[ "$(basename "$CC")" == musl-gcc ]] || [[ "$(basename "$CXX")" == musl-g++ ]]; then
  echo "musl-gcc detected; switching to glibc compiler"
  if command -v gcc >/dev/null && command -v g++ >/dev/null; then
    CC=$(command -v gcc)
    CXX=$(command -v g++)
  else
    CC=$(command -v clang)
    CXX=$(command -v clang++)
  fi
fi

export CC
export CXX

# Respect Flutter's sysroot when cross-compiling so the Go library links against
# the same glibc as the rest of the application.
if [ -n "$FLUTTER_TARGET_PLATFORM_SYSROOT" ]; then
  export CGO_CFLAGS="--sysroot=$FLUTTER_TARGET_PLATFORM_SYSROOT"
  export CGO_LDFLAGS="--sysroot=$FLUTTER_TARGET_PLATFORM_SYSROOT"
fi

CC=$CC GOOS=linux GOARCH=amd64 go build -buildmode=c-shared -o ../bindings/libgo_native_bridge.so

# Copy the library next to the executable so it is bundled with the app
mkdir -p ../linux/lib
cp ../bindings/libgo_native_bridge.so ../linux/lib/
