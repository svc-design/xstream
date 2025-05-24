# Makefile for XStream project

FLUTTER = flutter
PROJECT_NAME = XStream

UNAME_S := $(shell uname -s)
UNAME_M := $(shell uname -m)

.PHONY: all macos-intel macos-arm64 windows-x64 linux-x64 linux-arm64 android-arm64 ios-arm64 clean dmg zip-ios

all: macos-intel macos-arm64 windows-x64 linux-x64 linux-arm64 android-arm64 ios-arm64

fix-macos-signing:
	@echo "🧹 Cleaning extended attributes for macOS build..."
	xattr -rc .
	flutter clean
	flutter pub get

macos-intel:
	@if [ "$(UNAME_S)" = "Darwin" ] && [ "$(UNAME_M)" = "x86_64" ]; then \
		echo "Building for macOS (Intel)..."; \
		$(FLUTTER) build macos; \
		brew install create-dmg || true; \
		DMG_NAME=XStream-x86_64.dmg; \
		mkdir -p build/macos/bin; \
		cp build/macos/Build/Products/Release/xstream build/macos/bin/xstream; \
		create-dmg \
			--volname "XStream Installer" \
			--window-pos 200 120 \
			--window-size 800 400 \
			--icon-size 100 \
			--app-drop-link 600 185 \
			build/macos/$$DMG_NAME \
			build/macos/bin; \
	else \
		echo "Skipping macOS Intel build (not on Intel architecture)"; \
	fi

macos-arm64:
	@if [ "$(UNAME_S)" = "Darwin" ] && [ "$(UNAME_M)" = "arm64" ]; then \
		echo "Building for macOS (ARM64)..."; \
		$(FLUTTER) build macos; \
		brew install create-dmg || true; \
		DMG_NAME=XStream-arm64.dmg; \
		mkdir -p build/macos/bin; \
		cp build/macos/Build/Products/Release/xstream build/macos/bin/xstream; \
		create-dmg \
			--volname "XStream Installer" \
			--window-pos 200 120 \
			--window-size 800 400 \
			--icon-size 100 \
			--app-drop-link 600 185 \
			build/macos/$$DMG_NAME \
			build/macos/bin; \
	else \
		echo "Skipping macOS ARM64 build (not on ARM architecture)"; \
	fi



windows-x64:
	@if [ "$(UNAME_S)" = "Linux" ] || [ "$(UNAME_S)" = "Darwin" ]; then \
		echo "Building for Windows (cross-compile)..."; \
		$(FLUTTER) build windows --release; \
	elif [ "$(OS)" = "Windows_NT" ]; then \
		echo "Building for Windows (native)..."; \
		flutter build windows --release; \
	else \
		echo "Windows build not supported on this platform"; \
	fi

linux-x64:
	@if [ "$(UNAME_S)" = "Linux" ]; then \
		echo "Building for Linux x64..."; \
		$(FLUTTER) build linux --release --target-platform=linux-x64; \
		mv build/linux/x64/release/bundle/xstream build/linux/x64/release/bundle/xstream-x64; \
	else \
		echo "Linux x64 build only supported on Linux systems"; \
	fi

linux-arm64:
	@if [ "$(UNAME_S)" = "Linux" ]; then \
		echo "Building for Linux arm64..."; \
		$(FLUTTER) build linux --release --target-platform=linux-arm64; \
		mv build/linux/arm64/release/bundle/xstream build/linux/arm64/release/bundle/xstream-arm64; \
	else \
		echo "Linux arm64 build only supported on Linux systems"; \
	fi

android-arm64:
	@if [ "$(UNAME_S)" = "Linux" ] || [ "$(UNAME_S)" = "Darwin" ]; then \
		echo "Building for Android arm64..."; \
		$(FLUTTER) build apk; \
	else \
		echo "Android build not supported on this platform"; \
	fi

ios-arm64:
	@if [ "$(UNAME_S)" = "Darwin" ]; then \
		echo "Building for iOS arm64..."; \
		$(FLUTTER) build ios --release --no-codesign; \
		cd build/ios/iphoneos && zip -r xstream.app.zip Runner.app; \
	else \
		echo "iOS build only supported on macOS"; \
	fi

clean:
	echo "Cleaning build outputs..."
	$(FLUTTER) clean
	rm -rf macos/Flutter/ephemeral
	xattr -rc .
