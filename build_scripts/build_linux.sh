#!/usr/bin/env bash
set -e
DIR="$(dirname "$0")/.."
cd "$DIR/go_core"
CC=musl-gcc GOOS=linux GOARCH=amd64 go build -buildmode=c-shared -o ../bindings/libbridge.so
