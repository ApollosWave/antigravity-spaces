PREFIX      ?= $(HOME)/.local
BIN_DIR     ?= $(PREFIX)/bin
PLIST_DIR   ?= $(HOME)/Library/LaunchAgents
PLIST_NAME  ?= com.apolloswave.antigravity-spaces.plist
BINARY_NAME ?= antigravity-spaces
SHORT_NAME  ?= aspaces
APP_NAME    ?= Antigravity Spaces
APP_BUNDLE  ?= $(APP_NAME).app
DMG_NAME    ?= Antigravity-Spaces.dmg
VERSION     ?= 1.1.0

SWIFT_SOURCES = $(wildcard Sources/AntigravitySpaces/**/*.swift Sources/AntigravitySpaces/*.swift)

all: build

build:
	@echo "==> Compiling native Swift binary (modular architecture)..."
	@mkdir -p .cache/swift
	swiftc -O -module-cache-path ./.cache/swift -o $(BINARY_NAME) $(SWIFT_SOURCES)
	@echo "==> Build complete: $(BINARY_NAME)"

app: build
	@echo "==> Packaging $(APP_BUNDLE)..."
	@rm -rf "$(APP_BUNDLE)"
	@mkdir -p "$(APP_BUNDLE)/Contents/MacOS"
	@mkdir -p "$(APP_BUNDLE)/Contents/Resources"
	@cp $(BINARY_NAME) "$(APP_BUNDLE)/Contents/MacOS/$(BINARY_NAME)"
	@if [ -f assets/AppIcon.icns ]; then cp assets/AppIcon.icns "$(APP_BUNDLE)/Contents/Resources/AppIcon.icns"; fi
	@echo '<?xml version="1.0" encoding="UTF-8"?>' > "$(APP_BUNDLE)/Contents/Info.plist"
	@echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' >> "$(APP_BUNDLE)/Contents/Info.plist"
	@echo '<plist version="1.0"><dict>' >> "$(APP_BUNDLE)/Contents/Info.plist"
	@echo '  <key>CFBundleExecutable</key><string>$(BINARY_NAME)</string>' >> "$(APP_BUNDLE)/Contents/Info.plist"
	@echo '  <key>CFBundleIdentifier</key><string>com.apolloswave.antigravity-spaces</string>' >> "$(APP_BUNDLE)/Contents/Info.plist"
	@echo '  <key>CFBundleName</key><string>$(APP_NAME)</string>' >> "$(APP_BUNDLE)/Contents/Info.plist"
	@echo '  <key>CFBundleIconFile</key><string>AppIcon</string>' >> "$(APP_BUNDLE)/Contents/Info.plist"
	@echo '  <key>CFBundleVersion</key><string>$(VERSION)</string>' >> "$(APP_BUNDLE)/Contents/Info.plist"
	@echo '  <key>CFBundleShortVersionString</key><string>$(VERSION)</string>' >> "$(APP_BUNDLE)/Contents/Info.plist"
	@echo '  <key>CFBundlePackageType</key><string>APPL</string>' >> "$(APP_BUNDLE)/Contents/Info.plist"
	@echo '  <key>LSUIElement</key><true/>' >> "$(APP_BUNDLE)/Contents/Info.plist"
	@echo '</dict></plist>' >> "$(APP_BUNDLE)/Contents/Info.plist"
	@codesign --force --deep --sign - "$(APP_BUNDLE)" 2>/dev/null || true
	@rm -f $(BINARY_NAME)
	@echo "==> Created $(APP_BUNDLE)"

dmg: app
	@echo "==> Building release disk image $(DMG_NAME)..."
	@rm -rf .build_dmg $(DMG_NAME)
	@mkdir -p .build_dmg
	@cp -R "$(APP_BUNDLE)" .build_dmg/
	@ln -s /Applications .build_dmg/Applications
	@hdiutil create -volname "$(APP_NAME)" -srcfolder .build_dmg -ov -format UDZO $(DMG_NAME)
	@rm -rf .build_dmg
	@echo "==> Release DMG ready: $(DMG_NAME)"

install: build
	@echo "==> Installing binary to $(BIN_DIR)..."
	@mkdir -p $(BIN_DIR)
	@cp $(BINARY_NAME) $(BIN_DIR)/$(BINARY_NAME)
	@ln -sf $(BIN_DIR)/$(BINARY_NAME) $(BIN_DIR)/$(SHORT_NAME)
	@echo "==> Installed: $(BIN_DIR)/$(BINARY_NAME) and alias $(BIN_DIR)/$(SHORT_NAME)"

autostart: install
	@echo "==> Setting up macOS launchd service for automatic login..."
	@mkdir -p $(PLIST_DIR)
	@echo '<?xml version="1.0" encoding="UTF-8"?>' > $(PLIST_DIR)/$(PLIST_NAME)
	@echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' >> $(PLIST_DIR)/$(PLIST_NAME)
	@echo '<plist version="1.0"><dict>' >> $(PLIST_DIR)/$(PLIST_NAME)
	@echo '  <key>Label</key><string>com.apolloswave.antigravity-spaces</string>' >> $(PLIST_DIR)/$(PLIST_NAME)
	@echo '  <key>ProgramArguments</key><array><string>$(BIN_DIR)/$(BINARY_NAME)</string></array>' >> $(PLIST_DIR)/$(PLIST_NAME)
	@echo '  <key>RunAtLoad</key><true/>' >> $(PLIST_DIR)/$(PLIST_NAME)
	@echo '  <key>KeepAlive</key><true/>' >> $(PLIST_DIR)/$(PLIST_NAME)
	@echo '</dict></plist>' >> $(PLIST_DIR)/$(PLIST_NAME)
	@launchctl unload $(PLIST_DIR)/$(PLIST_NAME) 2>/dev/null || true
	@launchctl load $(PLIST_DIR)/$(PLIST_NAME)
	@echo "==> Service enabled and started!"

run: build
	@pkill -f $(BINARY_NAME) 2>/dev/null || true
	./$(BINARY_NAME) &

stop:
	@pkill -f $(BINARY_NAME) || echo "Not running."

uninstall: stop
	@rm -f $(BIN_DIR)/$(BINARY_NAME) $(BIN_DIR)/$(SHORT_NAME)
	@launchctl unload $(PLIST_DIR)/$(PLIST_NAME) 2>/dev/null || true
	@rm -f $(PLIST_DIR)/$(PLIST_NAME)
	@echo "==> Uninstalled completely."

clean:
	@rm -rf $(BINARY_NAME) .build_dmg .cache .build
	@echo "==> Cleaned temporary build caches and intermediate files."

distclean: clean
	@rm -rf "$(APP_BUNDLE)" $(DMG_NAME)
	@echo "==> Cleaned release artifacts ($(APP_BUNDLE), $(DMG_NAME))."

.PHONY: all build app dmg install autostart run stop uninstall clean distclean

