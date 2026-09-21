PREFIX      ?= $(HOME)/.local
BIN_DIR     ?= $(PREFIX)/bin
PLIST_DIR   ?= $(HOME)/Library/LaunchAgents
PLIST_NAME  ?= com.apolloswave.antigravity-spaces.plist
BINARY_NAME ?= antigravity-spaces
SHORT_NAME  ?= aspaces

all: build

build:
	@echo "==> Compiling native Swift binary..."
	@mkdir -p .cache/swift
	swiftc -O -module-cache-path ./.cache/swift -o $(BINARY_NAME) main.swift
	@echo "==> Build complete: $(BINARY_NAME)"

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

.PHONY: all build install autostart run stop uninstall
