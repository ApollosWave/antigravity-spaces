# Antigravity Spaces

### Workspaces, within reach.

[![macOS](https://img.shields.io/badge/macOS-12.0%2B-black?logo=apple&logoColor=white)](https://apple.com)
[![Swift](https://img.shields.io/badge/Swift-5.9%2B-FA7343?logo=swift&logoColor=white)](https://swift.org)
[![Dependencies](https://img.shields.io/badge/Dependencies-0%20external-black)](#)
[![Memory](https://img.shields.io/badge/Memory-%3C8MB-gray)](#)
[![License](https://img.shields.io/badge/License-MIT-black)](LICENSE)

Antigravity Spaces lives quietly in your macOS menu bar. Designed for developers working across multiple repositories simultaneously, it brings order to your active Antigravity IDE workspaces—giving your floating projects some gravity.

![Antigravity Spaces Showcase](assets/showcase.jpg)

---

## Overview

Switching between open projects shouldn't interrupt your concentration. Antigravity Spaces automatically identifies every running Antigravity IDE workspace, formats project hierarchies into clean titles, and gives you a Spotlight-style **Floating Gaussian Blur HUD Switcher** summoned globally via **`⌥A` (Option + A)** or the menu bar.

Filter 20+ active workspaces in milliseconds by project name or active file, jump via **`⌘1` through `⌘9`**, or navigate with arrow keys. No windows hidden behind desktops. No hunting through Mission Control. Just your workspaces, organized and immediately available.

---

## Highlights

- **Floating Frosted Glass HUD.** Raycast/Spotlight-style floating panel with hardware-accelerated macOS Gaussian blur and vibrancy.
- **Global Shortcut (`⌥A`).** Summon the switcher instantly from any space, desktop, or full-screen application without lifting your hands from the keyboard.
- **Real-Time Fuzzy Search.** Type project or file names to filter dozens of open repositories in milliseconds.
- **Instant Keyboard Navigation.** Switch fluidly with `⌘1` through `⌘9`, or cycle with `↑`/`↓` and press `↵ Enter`.
- **Hybrid Menu Bar.** Keep your menu bar glyph (`A↗`) for quick glances or click to toggle the HUD.
- **Zero External Dependencies.** Built in 100% native Swift with AppKit and CoreGraphics. Operates with a memory footprint under 12 MB and 0% idle CPU.
- **Private by Default.** Completely local execution. No telemetry, no network calls, and no analytics.

---

## Installation

### Automated Setup

Clone the repository and run the setup script:

```bash
git clone https://github.com/ApollosWave/antigravity-spaces.git
cd antigravity-spaces
./install.sh
```

The installer compiles the native Swift binary, installs it to `~/.local/bin/antigravity-spaces` (with `aspaces` alias), and configures a lightweight macOS `launchd` service so the switcher is available whenever you log in.

### Build from Source

Build and launch the application directly using Make:

```bash
git clone https://github.com/ApollosWave/antigravity-spaces.git
cd antigravity-spaces

# Compile and start immediately
make run

# Or install and configure launch on login
make autostart
```

---

## System Permissions

Because Antigravity Spaces coordinates window focus across applications, macOS requires standard Accessibility access (if using iTerm or other terminals):

1. When launched for the first time, macOS will display an Accessibility permission request.
2. Select **Open System Settings** (or navigate to **System Settings > Privacy & Security > Accessibility**).
3. Enable access for **antigravity-spaces**.

> [!NOTE]
> The official macOS Terminal app does not require any system or Accessibility permissions.

---

## Command Reference

| Target | Description |
| :--- | :--- |
| `make build` | Compiles the standalone Swift binary with optimizations (`-O`) |
| `make run` | Starts the application process in the background |
| `make stop` | Gracefully terminates the running process |
| `make autostart` | Installs to `~/.local/bin` and activates the login service |
| `make uninstall` | Removes the binary and unloads the launch agent |

---

## Requirements

- macOS Monterey (12.0) or later
- Swift 5.9 or later (included with Xcode Command Line Tools)
- Antigravity IDE

---

## License

MIT License. Designed and maintained by [ApollosWave LLC](https://apolloswave.com).
