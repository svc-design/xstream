#!/usr/bin/env bash
set -e
DIR="$(dirname "$0")/.."
cd "$DIR/go_core"
GOOS=windows GOARCH=amd64 go build -buildmode=c-shared -ldflags="-linkmode external -extldflags '-static'" -o ../bindings/libbridge.dll
