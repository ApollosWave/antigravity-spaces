import Cocoa

/// Manages the macOS system menu bar status item, custom vector tray icon, and dynamic dropdown menu.
public class StatusBarController: NSObject, NSMenuDelegate {
    public var statusItem: NSStatusItem!
    public let menu = NSMenu()
    
    public var onOpenHUD: (() -> Void)?
    public var onSetShortcut: ((HotkeyConfig) -> Void)?
    public var onOpenShortcutRecorder: (() -> Void)?
    public var onSetDisplayPreference: ((Int) -> Void)?
    public var onActivateWorkspace: ((WorkspaceItem) -> Void)?
    public var onQuit: (() -> Void)?
    
    public var currentHotkey: HotkeyConfig = HotkeyConfig.defaultHotkey
    public var targetDisplayIndex: Int = -1
    public var blueFolderIcon: NSImage!
    
    public override init() {
        super.init()
        self.blueFolderIcon = createBlueFolderIcon()
        setupStatusItem()
    }
    
    // MARK: - Status Bar Item Setup
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = createTrayIcon()
            button.imagePosition = .imageOnly
            button.toolTip = "Antigravity Spaces (\(currentHotkey.shortTitle))"
            button.target = self
            button.action = #selector(statusItemClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        menu.delegate = self
    }
    
    public func updateTooltip() {
        statusItem?.button?.toolTip = "Antigravity Spaces (\(currentHotkey.shortTitle))"
    }
    
    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp {
            statusItem.menu = menu
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
        } else {
            onOpenHUD?()
        }
    }
    
    // MARK: - Menu Delegate & Dynamic Construction
    public func menuWillOpen(_ menu: NSMenu) {
        refreshMenu()
    }
    
    public func refreshMenu() {
        menu.removeAllItems()
        
        let hudItem = NSMenuItem(title: "Open Switcher", action: #selector(openHUDAction), keyEquivalent: "")
        hudItem.target = self
        menu.addItem(hudItem)
        menu.addItem(NSMenuItem.separator())
        
        // Shortcut Selection Submenu
        let shortcutMenu = NSMenu()
        for preset in HotkeyConfig.presets {
            let item = NSMenuItem(title: preset.title, action: #selector(setShortcutAction(_:)), keyEquivalent: "")
            item.representedObject = preset
            item.target = self
            if currentHotkey.matchesConfig(preset) {
                item.state = .on
            }
            shortcutMenu.addItem(item)
        }
        shortcutMenu.addItem(NSMenuItem.separator())
        
        let isPreset = HotkeyConfig.presets.contains(where: { currentHotkey.matchesConfig($0) })
        let customItemTitle = isPreset ? "Record Custom Shortcut..." : "Custom: \(currentHotkey.shortTitle) (Record New...)"
        let customItem = NSMenuItem(title: customItemTitle, action: #selector(openRecorderAction), keyEquivalent: "")
        customItem.target = self
        if !isPreset {
            customItem.state = .on
        }
        shortcutMenu.addItem(customItem)
        
        let shortcutParent = NSMenuItem(title: "Shortcut (\(currentHotkey.shortTitle))", action: nil, keyEquivalent: "")
        shortcutParent.submenu = shortcutMenu
        menu.addItem(shortcutParent)
        menu.addItem(NSMenuItem.separator())
        
        // HUD Display Selection Submenu
        let displayMenu = NSMenu()
        let autoItem = NSMenuItem(title: "Follow Mouse Cursor (Auto)", action: #selector(setDisplayAction(_:)), keyEquivalent: "")
        autoItem.tag = -1
        autoItem.target = self
        if targetDisplayIndex == -1 {
            autoItem.state = .on
        }
        displayMenu.addItem(autoItem)
        displayMenu.addItem(NSMenuItem.separator())
        
        for (idx, screen) in NSScreen.screens.enumerated() {
            let res = "\(Int(screen.frame.width)) × \(Int(screen.frame.height))"
            let title = "Display \(idx + 1): \(screen.localizedName) (\(res))"
            let item = NSMenuItem(title: title, action: #selector(setDisplayAction(_:)), keyEquivalent: "")
            item.tag = idx
            item.target = self
            if targetDisplayIndex == idx {
                item.state = .on
            }
            displayMenu.addItem(item)
        }
        
        let displayParent = NSMenuItem(title: "HUD Display", action: nil, keyEquivalent: "")
        displayParent.submenu = displayMenu
        menu.addItem(displayParent)
        menu.addItem(NSMenuItem.separator())
        
        let header = NSMenuItem(title: "Active Antigravity Spaces", action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)
        menu.addItem(NSMenuItem.separator())
        
        let isTrusted = WorkspaceDiscoveryService.checkAccessibility(prompt: false)
        if !isTrusted {
            let warn = NSMenuItem(title: "⚠️ Accessibility Permission Needed", action: #selector(openAccessibilitySettings), keyEquivalent: "")
            warn.target = self
            menu.addItem(warn)
            let grant = NSMenuItem(title: "Click to grant in System Settings", action: #selector(openAccessibilitySettings), keyEquivalent: "")
            grant.target = self
            menu.addItem(grant)
            menu.addItem(NSMenuItem.separator())
        }
        
        let workspaces = WorkspaceDiscoveryService.shared.discoverWorkspaces()
        if workspaces.isEmpty {
            if isTrusted {
                let emptyItem = NSMenuItem(title: "No Antigravity spaces detected", action: nil, keyEquivalent: "")
                emptyItem.isEnabled = false
                menu.addItem(emptyItem)
            }
        } else {
            for (index, item) in workspaces.enumerated() {
                let key = index < 9 ? "\(index + 1)" : ""
                let menuItem = NSMenuItem(title: item.project, action: #selector(workspaceSelectedAction(_:)), keyEquivalent: key)
                menuItem.image = blueFolderIcon
                menuItem.representedObject = item
                menuItem.target = self
                menu.addItem(menuItem)
            }
        }
        
        menu.addItem(NSMenuItem.separator())
        let loginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLoginAction), keyEquivalent: "")
        loginItem.target = self
        loginItem.state = LaunchAtLoginService.isEnabled ? .on : .off
        menu.addItem(loginItem)
        
        let quitItem = NSMenuItem(title: "Quit Spaces", action: #selector(quitAction), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }
    
    // MARK: - Action Selectors
    @objc private func openHUDAction() {
        onOpenHUD?()
    }
    
    @objc private func setShortcutAction(_ sender: NSMenuItem) {
        guard let preset = sender.representedObject as? HotkeyConfig else { return }
        onSetShortcut?(preset)
    }
    
    @objc private func openRecorderAction() {
        onOpenShortcutRecorder?()
    }
    
    @objc private func setDisplayAction(_ sender: NSMenuItem) {
        onSetDisplayPreference?(sender.tag)
    }
    
    @objc private func workspaceSelectedAction(_ sender: NSMenuItem) {
        guard let item = sender.representedObject as? WorkspaceItem else { return }
        onActivateWorkspace?(item)
    }
    
    @objc private func openAccessibilitySettings() {
        WorkspaceDiscoveryService.checkAccessibility(prompt: true)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc private func toggleLaunchAtLoginAction() {
        _ = LaunchAtLoginService.toggle()
        refreshMenu()
    }
    
    @objc private func quitAction() {
        if let onQuit = onQuit {
            onQuit()
        } else {
            NSApplication.shared.terminate(nil)
        }
    }
    
    // MARK: - Vector Icon Creation
    public func createTrayIcon() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            let font = NSFont.systemFont(ofSize: 13, weight: .black)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: NSColor.black
            ]
            let aString = NSAttributedString(string: "A", attributes: attrs)
            aString.draw(at: NSPoint(x: 1.0, y: 1.5))
            
            let arrow = NSBezierPath()
            arrow.lineWidth = 1.7
            arrow.lineCapStyle = .round
            arrow.lineJoinStyle = .round
            
            arrow.move(to: NSPoint(x: 9.0, y: 8.0))
            arrow.line(to: NSPoint(x: 15.2, y: 14.8))
            
            arrow.move(to: NSPoint(x: 11.5, y: 14.8))
            arrow.line(to: NSPoint(x: 15.2, y: 14.8))
            arrow.line(to: NSPoint(x: 15.2, y: 11.1))
            
            NSColor.black.setStroke()
            arrow.stroke()
            return true
        }
        image.isTemplate = true
        return image
    }
    
    public func createBlueFolderIcon() -> NSImage {
        let size = NSSize(width: 20, height: 20)
        let img = NSImage(size: size, flipped: false) { rect in
            guard let _ = NSGraphicsContext.current?.cgContext else { return false }
            let folderBlue = NSColor(calibratedRed: 0.16, green: 0.65, blue: 0.98, alpha: 1.0)
            let tabBlue = NSColor(calibratedRed: 0.10, green: 0.52, blue: 0.85, alpha: 1.0)
            
            let tabRect = NSRect(x: 1.5, y: 7.0, width: 8.0, height: 10.0)
            let tabPath = NSBezierPath(roundedRect: tabRect, xRadius: 2.2, yRadius: 2.2)
            tabBlue.setFill()
            tabPath.fill()
            
            let bodyRect = NSRect(x: 1.5, y: 2.0, width: 17.0, height: 12.0)
            let bodyPath = NSBezierPath(roundedRect: bodyRect, xRadius: 2.5, yRadius: 2.5)
            folderBlue.setFill()
            bodyPath.fill()
            
            let lipRect = NSRect(x: 2.0, y: 9.5, width: 16.0, height: 3.5)
            let lipPath = NSBezierPath(roundedRect: lipRect, xRadius: 1.5, yRadius: 1.5)
            NSColor.white.withAlphaComponent(0.24).setFill()
            lipPath.fill()
            return true
        }
        img.isTemplate = false
        return img
    }
}
