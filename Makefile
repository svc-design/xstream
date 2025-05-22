# Makefile for XStream project

# Define variables
FLUTTER = flutter
PROJECT_NAME = XStream

# Detect the platform
UNAME_S := $(shell uname -s)
UNAME_M := $(shell uname -m)

# Targets
.PHONY: all macos-intel macos-arm64 windows linux android ios clean

all: macos-intel macos-arm64 windows linux android ios

fix-macos-signing:
	@echo "🧹 Cleaning extended attributes for macOS build..."
	xattr -rc .
	flutter clean
	flutter pub get

# MacOS Intel build
macos-intel:
	@if [ "$(UNAME_S)" = "Darwin" ] && [ "$(UNAME_M)" = "x86_64" ]; then \
		echo "Building for MacOS (Intel)..."; \
		$(FLUTTER) build macos; \
	else \
		echo "Skipping MacOS Intel build (not on Intel architecture)"; \
	fi

# MacOS ARM64 build
macos-arm64:
	@if [ "$(UNAME_S)" = "Darwin" ] && [ "$(UNAME_M)" = "arm64" ]; then \
		echo "Building for MacOS (ARM64)..."; \
		$(FLUTTER) build macos; \
	else \
		echo "Skipping MacOS ARM64 build (not on ARM architecture)"; \
	fi

# Windows build
windows:
	@if [ "$(UNAME_S)" = "Linux" ] || [ "$(UNAME_S)" = "Darwin" ]; then \
		echo "Building for Windows..."; \
		$(FLUTTER) build windows; \
	else \
		echo "Windows build not supported on this platform"; \
	fi

# Linux build
linux:
	@if [ "$(UNAME_S)" = "Linux" ]; then \
		echo "Building for Linux..."; \
		$(FLUTTER) build linux; \
	else \
		echo "Linux build only supported on Linux systems"; \
	fi

# Android build
android:
	@if [ "$(UNAME_S)" = "Linux" ] || [ "$(UNAME_S)" = "Darwin" ]; then \
		echo "Building for Android..."; \
		$(FLUTTER) build apk; \
	else \
		echo "Android build not supported on this platform"; \
	fi

# iOS build
ios:
	@if [ "$(UNAME_S)" = "Darwin" ]; then \
		echo "Building for iOS..."; \
		$(FLUTTER) build ios; \
	else \
		echo "iOS build only supported on MacOS"; \
	fi

# Clean all builds
clean:
	echo "Cleaning build outputs..."
	$(FLUTTER) clean
	rm -rf macos/Flutter/ephemeral
	xattr -rc .
