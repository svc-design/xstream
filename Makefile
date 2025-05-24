# Makefile for XStream project

FLUTTER = flutter
PROJECT_NAME = XStream

UNAME_S := $(shell uname -s)
UNAME_M := $(shell uname -m)

.PHONY: all macos-intel macos-arm64 windows-x64 linux-x64 linux-arm64 android-arm64 ios-arm64 clean

# Aliases for CI
macos-x64: macos-intel
macos-arm64: macos-arm64
windows-x64: windows-x64
linux-x64: linux-x64
linux-arm64: linux-arm64
android-arm64: android-arm64
ios-arm64: ios-arm64

all: macos-intel macos-arm64 windows-x64 linux-x64 linux-arm64 android-arm64 ios-arm64

fix-macos-signing:
	@echo "🧹 Cleaning extended attributes for macOS build..."
	xattr -rc .
	flutter clean
	flutter pub get

macos-intel:
	@if [ "$(UNAME_S)" = "Darwin" ] && [ "$(UNAME_M)" = "x86_64" ]; then \
		echo "Building for macOS (Intel)..."; \
		$(FLUTTER) build macos --release; \
		brew install create-dmg || true; \
		DMG_NAME=XStream-x86_64.dmg; \
		create-dmg \
			--volname "XStream Installer" \
			--window-pos 200 120 \
			--window-size 800 400 \
			--icon-size 100 \
			--app-drop-link 600 185 \
			build/macos/$$DMG_NAME \
			build/macos/Build/Products/Release/Runner.app; \
	else \
		echo "Skipping macOS Intel build (not on Intel architecture)"; \
	fi

macos-arm64:
	@if [ "$(UNAME_S)" = "Darwin" ] && [ "$(UNAME_M)" = "arm64" ]; then \
		echo "Building for macOS (ARM64)..."; \
		$(FLUTTER) build macos --release; \
		brew install create-dmg || true; \
		DMG_NAME=XStream-arm64.dmg; \
		create-dmg \
			--volname "XStream Installer" \
			--window-pos 200 120 \
			--window-size 800 400 \
			--icon-size 100 \
			--app-drop-link 600 185 \
			build/macos/$$DMG_NAME \
			build/macos/Build/Products/Release/Runner.app; \
	else \
		echo "Skipping macOS ARM64 build (not on ARM architecture)"; \
	fi

windows-x64:
	@if [ "$(UNAME_S)" = "Windows_NT" ] || [ "$(OS)" = "Windows_NT" ]; then \
		echo "Building for Windows (native)..."; \
		flutter build windows --release; \
	else \
		echo "Windows build only supported on native Windows systems"; \
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
		if [ "$(UNAME_M)" = "aarch64" ] || [ "$(UNAME_M)" = "arm64" ]; then \
			echo "Building for Linux arm64..."; \
			$(FLUTTER) build linux --release --target-platform=linux-arm64; \
			mv build/linux/arm64/release/bundle/xstream build/linux/arm64/release/bundle/xstream-arm64; \
		else \
			echo "❌ Cross-build from x64 to arm64 is not supported. Please run this on an arm64 host."; \
			exit 0; \
		fi \
	else \
		echo "Linux arm64 build only supported on Linux systems"; \
	fi

android-arm64:
	@if [ "$(UNAME_S)" = "Linux" ] || [ "$(UNAME_S)" = "Darwin" ]; then \
		echo "Building for Android arm64..."; \
		$(FLUTTER) build apk --release; \
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
