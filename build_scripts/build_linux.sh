#!/usr/bin/env bash
set -e
DIR="$(dirname "$0")/.."
cd "$DIR/go_core"

# Ensure CGO is enabled when building with musl
if [ "$(go env CGO_ENABLED)" != "1" ]; then
  export CGO_ENABLED=1
fi

CC=musl-gcc GOOS=linux GOARCH=amd64 go build -buildmode=c-shared -o ../bindings/libbridge.so
