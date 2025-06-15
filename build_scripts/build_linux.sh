#!/usr/bin/env bash
set -e
DIR="$(dirname "$0")/.."
cd "$DIR/go_core"

# Ensure CGO is enabled for Linux builds
if [ "$(go env CGO_ENABLED)" != "1" ]; then
  export CGO_ENABLED=1
fi

# Use the host compiler to build the shared library.
# Derive CC from CXX so both compilers come from the same toolchain.
: "${CXX:=clang++}"
: "${CC:=gcc}"
case "$(basename "$CXX")" in
  clang++)
    CC="$(dirname "$CXX")/clang"
    ;;
  g++)
    CC="$(dirname "$CXX")/gcc"
    ;;
esac
if [ "$(basename "$CC")" = "musl-gcc" ]; then
  if [ "$(basename "$CXX")" = "clang++" ]; then
    echo "musl-gcc detected; switching to clang for glibc build"
    CC=clang
  else
    echo "musl-gcc detected; switching to gcc for glibc build"
    CC=gcc
  fi
fi

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
