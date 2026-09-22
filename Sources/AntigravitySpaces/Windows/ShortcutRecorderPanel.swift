import Cocoa

/// Floating custom shortcut recorder panel allowing users to press and bind any key combination.
public class ShortcutRecorderPanel: NSPanel {
    public var onShortcutRecorded: ((HotkeyConfig) -> Void)?
    private var pendingConfig: HotkeyConfig?
    
    private var containerView: FrostedGlassView!
    private var keyDisplayLabel: NSTextField!
    private var saveButton: NSButton!
    private var statusLabel: NSTextField!
    
    public init() {
        let width: CGFloat = 440
        let height: CGFloat = 230
        let margin: CGFloat = 16.0
        let panelRect = NSRect(x: 0, y: 0, width: width + margin * 2, height: height + margin * 2)
        
        super.init(
            contentRect: panelRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.level = .floating
        self.appearance = NSAppearance(named: .vibrantDark)
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        let rootView = NSView(frame: panelRect)
        self.contentView = rootView
        
        containerView = FrostedGlassView(frame: NSRect(x: margin, y: margin, width: width, height: height))
        rootView.addSubview(containerView)
        
        let titleLabel = NSTextField(labelWithString: "Record Custom Shortcut")
        titleLabel.font = NSFont.systemFont(ofSize: 16.0, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.alignment = .center
        titleLabel.frame = NSRect(x: 20, y: height - 42, width: width - 40, height: 22)
        containerView.addSubview(titleLabel)
        
        statusLabel = NSTextField(labelWithString: "Press any key combination (e.g. ⇧Space, ⌥Space, ⌥S, ⌘⇧P)...")
        statusLabel.font = NSFont.systemFont(ofSize: 12.0, weight: .regular)
        statusLabel.textColor = NSColor(calibratedWhite: 0.65, alpha: 1.0)
        statusLabel.alignment = .center
        statusLabel.frame = NSRect(x: 20, y: height - 68, width: width - 40, height: 18)
        containerView.addSubview(statusLabel)
        
        // Key combo display box
        let displayBox = NSView(frame: NSRect(x: 40, y: height - 132, width: width - 80, height: 50))
        displayBox.wantsLayer = true
        displayBox.layer?.cornerRadius = 10.0
        displayBox.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.08).cgColor
        displayBox.layer?.borderWidth = 1.2
        displayBox.layer?.borderColor = NSColor(calibratedRed: 0.30, green: 0.68, blue: 1.0, alpha: 0.5).cgColor
        
        keyDisplayLabel = NSTextField(labelWithString: "Type shortcut...")
        keyDisplayLabel.font = NSFont.monospacedSystemFont(ofSize: 19.0, weight: .bold)
        keyDisplayLabel.textColor = NSColor(calibratedRed: 0.35, green: 0.75, blue: 1.0, alpha: 1.0)
        keyDisplayLabel.alignment = .center
        keyDisplayLabel.frame = NSRect(x: 0, y: 12, width: width - 80, height: 26)
        displayBox.addSubview(keyDisplayLabel)
        containerView.addSubview(displayBox)
        
        // Buttons
        let btnY: CGFloat = 18.0
        let btnH: CGFloat = 30.0
        
        let cancelBtn = NSButton(title: "Cancel (Esc)", target: self, action: #selector(cancelClicked))
        cancelBtn.bezelStyle = .rounded
        cancelBtn.frame = NSRect(x: 35, y: btnY, width: 110, height: btnH)
        containerView.addSubview(cancelBtn)
        
        let defaultBtn = NSButton(title: "Reset (⌥Space)", target: self, action: #selector(resetDefaultClicked))
        defaultBtn.bezelStyle = .rounded
        defaultBtn.frame = NSRect(x: 155, y: btnY, width: 130, height: btnH)
        containerView.addSubview(defaultBtn)
        
        saveButton = NSButton(title: "Save", target: self, action: #selector(saveClicked))
        saveButton.bezelStyle = .rounded
        saveButton.frame = NSRect(x: 295, y: btnY, width: 105, height: btnH)
        saveButton.isEnabled = false
        saveButton.keyEquivalent = "\r"
        containerView.addSubview(saveButton)
    }
    
    public override var canBecomeKey: Bool { true }
    public override var canBecomeMain: Bool { true }
    
    public override func resignKey() {
        super.resignKey()
        self.orderOut(nil)
    }
    
    public func present(on screen: NSScreen? = nil) {
        pendingConfig = nil
        keyDisplayLabel.stringValue = "Type shortcut..."
        saveButton.isEnabled = false
        statusLabel.stringValue = "Press any key combination (e.g. ⇧Space, ⌥Space, ⌥S, ⌘⇧P)..."
        
        let mouseLoc = NSEvent.mouseLocation
        let targetScreen = screen ?? NSScreen.screens.first { NSMouseInRect(mouseLoc, $0.frame, false) } ?? NSScreen.main ?? NSScreen.screens.first!
        let screenRect = targetScreen.visibleFrame
        let panelRect = self.frame
        let origin = NSPoint(
            x: screenRect.midX - (panelRect.width / 2.0),
            y: screenRect.midY - (panelRect.height / 2.0) + (screenRect.height * 0.08)
        )
        self.setFrameOrigin(origin)
        NSApp.activate(ignoringOtherApps: true)
        self.makeKeyAndOrderFront(nil)
        self.invalidateShadow()
    }
    
    public override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Esc
            cancelClicked()
            return
        }
        
        if event.keyCode == 36 && saveButton.isEnabled { // Return
            saveClicked()
            return
        }
        
        let flags = event.modifierFlags
        let hasOpt = flags.contains(.option)
        let hasCmd = flags.contains(.command)
        let hasCtrl = flags.contains(.control)
        let hasShift = flags.contains(.shift)
        
        // Shift alone is valid when paired with Space (49), Tab (48), Grave (50), or Function keys (96-122)
        let isAllowedShiftKey = (event.keyCode == 49) // Space
                              || (event.keyCode == 48) // Tab
                              || (event.keyCode == 50) // Grave / Backtick
                              || (event.keyCode >= 96 && event.keyCode <= 122) // F-keys
        
        guard hasOpt || hasCmd || hasCtrl || (hasShift && isAllowedShiftKey) else {
            if hasShift && !isAllowedShiftKey {
                statusLabel.stringValue = "⚠️ Shift alone can only be combined with Space, Tab, `, or F-keys."
            } else {
                statusLabel.stringValue = "⚠️ Shortcut must include a modifier: ⌥, ⌘, ⌃, or ⇧ (with Space)."
            }
            return
        }
        
        let (title, short) = HotkeyConfig.format(
            keyCode: event.keyCode,
            option: hasOpt,
            command: hasCmd,
            control: hasCtrl,
            shift: hasShift
        )
        
        let config = HotkeyConfig(
            id: "custom_\(event.keyCode)_\(hasOpt ? 1 : 0)\(hasCmd ? 1 : 0)\(hasCtrl ? 1 : 0)\(hasShift ? 1 : 0)",
            title: title,
            shortTitle: short,
            keyCode: event.keyCode,
            requireOption: hasOpt,
            requireCommand: hasCmd,
            requireControl: hasCtrl,
            requireShift: hasShift
        )
        
        pendingConfig = config
        keyDisplayLabel.stringValue = short
        statusLabel.stringValue = "Press 'Save' or ↵ Enter to apply shortcut."
        saveButton.isEnabled = true
    }
    
    @objc private func cancelClicked() {
        self.orderOut(nil)
    }
    
    @objc private func resetDefaultClicked() {
        onShortcutRecorded?(HotkeyConfig.defaultHotkey)
        self.orderOut(nil)
    }
    
    @objc private func saveClicked() {
        if let config = pendingConfig {
            onShortcutRecorded?(config)
        }
        self.orderOut(nil)
    }
}
