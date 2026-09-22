import Cocoa
import CoreGraphics

/// Configuration data model for global and local summon shortcuts.
public struct HotkeyConfig: Codable, Equatable {
    public var id: String
    public var title: String
    public var shortTitle: String
    public var keyCode: UInt16
    public var requireOption: Bool
    public var requireCommand: Bool
    public var requireControl: Bool
    public var requireShift: Bool
    
    public init(
        id: String,
        title: String,
        shortTitle: String,
        keyCode: UInt16,
        requireOption: Bool,
        requireCommand: Bool,
        requireControl: Bool,
        requireShift: Bool
    ) {
        self.id = id
        self.title = title
        self.shortTitle = shortTitle
        self.keyCode = keyCode
        self.requireOption = requireOption
        self.requireCommand = requireCommand
        self.requireControl = requireControl
        self.requireShift = requireShift
    }
    
    public func matches(cgEvent: CGEvent) -> Bool {
        let flags = cgEvent.flags
        let hasOption = flags.contains(.maskAlternate)
        let hasCommand = flags.contains(.maskCommand)
        let hasControl = flags.contains(.maskControl)
        let hasShift = flags.contains(.maskShift)
        let code = UInt16(cgEvent.getIntegerValueField(.keyboardEventKeycode))
        
        return code == keyCode &&
               hasOption == requireOption &&
               hasCommand == requireCommand &&
               hasControl == requireControl &&
               hasShift == requireShift
    }
    
    public func matches(nsEvent: NSEvent) -> Bool {
        let flags = nsEvent.modifierFlags
        let hasOption = flags.contains(.option)
        let hasCommand = flags.contains(.command)
        let hasControl = flags.contains(.control)
        let hasShift = flags.contains(.shift)
        
        return nsEvent.keyCode == keyCode &&
               hasOption == requireOption &&
               hasCommand == requireCommand &&
               hasControl == requireControl &&
               hasShift == requireShift
    }
    
    public func matchesConfig(_ other: HotkeyConfig) -> Bool {
        return self.keyCode == other.keyCode &&
               self.requireOption == other.requireOption &&
               self.requireCommand == other.requireCommand &&
               self.requireControl == other.requireControl &&
               self.requireShift == other.requireShift
    }
    
    public static func format(keyCode: UInt16, option: Bool, command: Bool, control: Bool, shift: Bool) -> (title: String, shortTitle: String) {
        var mods = ""
        if control { mods += "⌃" }
        if option { mods += "⌥" }
        if shift { mods += "⇧" }
        if command { mods += "⌘" }
        let keyName = KeyCodeHelper.name(for: keyCode)
        let short = "\(mods)\(keyName)"
        return (title: "\(short) (Custom)", shortTitle: short)
    }

    public static let presets: [HotkeyConfig] = [
        HotkeyConfig(id: "opt_space", title: "⌥Space (Option + Space) — Recommended", shortTitle: "⌥Space", keyCode: 49, requireOption: true, requireCommand: false, requireControl: false, requireShift: false),
        HotkeyConfig(id: "shift_space", title: "⇧Space (Shift + Space) — Ergonomic", shortTitle: "⇧Space", keyCode: 49, requireOption: false, requireCommand: false, requireControl: false, requireShift: true),
        HotkeyConfig(id: "opt_s", title: "⌥S (Option + S — Spaces)", shortTitle: "⌥S", keyCode: 1, requireOption: true, requireCommand: false, requireControl: false, requireShift: false),
        HotkeyConfig(id: "opt_w", title: "⌥W (Option + W — Workspaces)", shortTitle: "⌥W", keyCode: 13, requireOption: true, requireCommand: false, requireControl: false, requireShift: false),
        HotkeyConfig(id: "opt_d", title: "⌥D (Option + D)", shortTitle: "⌥D", keyCode: 2, requireOption: true, requireCommand: false, requireControl: false, requireShift: false),
        HotkeyConfig(id: "opt_grave", title: "⌥` (Option + Backtick — Cycle)", shortTitle: "⌥`", keyCode: 50, requireOption: true, requireCommand: false, requireControl: false, requireShift: false),
        HotkeyConfig(id: "opt_tab", title: "⌥Tab (Option + Tab)", shortTitle: "⌥Tab", keyCode: 48, requireOption: true, requireCommand: false, requireControl: false, requireShift: false),
        HotkeyConfig(id: "ctrl_space", title: "⌃Space (Control + Space)", shortTitle: "⌃Space", keyCode: 49, requireOption: false, requireCommand: false, requireControl: true, requireShift: false),
        HotkeyConfig(id: "opt_a", title: "⌥A (Option + A — Classic)", shortTitle: "⌥A", keyCode: 0, requireOption: true, requireCommand: false, requireControl: false, requireShift: false),
        HotkeyConfig(id: "cmd_shift_space", title: "⌘⇧Space (Command + Shift + Space)", shortTitle: "⌘⇧Space", keyCode: 49, requireOption: false, requireCommand: true, requireControl: false, requireShift: true),
        HotkeyConfig(id: "cmd_shift_a", title: "⌘⇧A (Command + Shift + A)", shortTitle: "⌘⇧A", keyCode: 0, requireOption: false, requireCommand: true, requireControl: false, requireShift: true),
        HotkeyConfig(id: "cmd_shift_o", title: "⌘⇧O (Command + Shift + O)", shortTitle: "⌘⇧O", keyCode: 31, requireOption: false, requireCommand: true, requireControl: false, requireShift: true)
    ]
    
    public static var defaultHotkey: HotkeyConfig { presets[0] } // ⌥Space
}
