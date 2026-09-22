import Cocoa

// MARK: - Command Line Interface Arguments
let args = CommandLine.arguments

if args.contains("--help") || args.contains("-h") {
    print("""
    Antigravity Spaces — Fast, Keyboard-First Workspaces Switcher for Antigravity IDE
    
    Usage:
      antigravity-spaces [options]
      
    Options:
      --hotkey <id|name>   Set summon shortcut (e.g. 'opt_space', 'shift_space', 'opt_s', 'opt_w')
      --list-hotkeys       List all available shortcut presets
      --help, -h           Show this help message
    """)
    exit(0)
}

if args.contains("--list-hotkeys") {
    print("Available Shortcut Presets:")
    for preset in HotkeyConfig.presets {
        let pad = String(repeating: " ", count: max(1, 18 - preset.id.count))
        print("  • \(preset.id)\(pad): \(preset.title)")
    }
    exit(0)
}

if let idx = args.firstIndex(of: "--hotkey"), idx + 1 < args.count {
    let target = args[idx + 1].lowercased()
    if let found = HotkeyConfig.presets.first(where: {
        $0.id.lowercased() == target ||
        $0.shortTitle.lowercased() == target ||
        $0.title.lowercased().contains(target)
    }) {
        PreferencesService.shared.saveHotkey(found)
        print("==> Shortcut configured to: \(found.title)")
    } else {
        print("Unknown hotkey preset: '\(target)'. Run with --list-hotkeys to see options.")
        exit(1)
    }
    if !args.contains("--daemon") && !args.contains("--run") && args.count <= 3 {
        print("Setting saved! Select from Menu Bar > Shortcut or restart Antigravity Spaces to apply.")
        exit(0)
    }
}

// MARK: - Application Lifecycle
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
