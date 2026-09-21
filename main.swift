import Cocoa
import CoreGraphics
import ApplicationServices

// MARK: - Workspace Data Model
struct WorkspaceItem {
    let rawTitle: String
    let project: String
    let file: String?
    let pid: pid_t
    let windowRef: AXUIElement
}

// MARK: - Custom Visual Effect View with Gaussian Frosted Glass
class FrostedGlassView: NSVisualEffectView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.material = .hudWindow
        self.blendingMode = .behindWindow
        self.state = .active
        self.wantsLayer = true
        self.layer?.cornerRadius = 16.0
        self.layer?.masksToBounds = true
        self.layer?.borderWidth = 1.0
        self.layer?.borderColor = NSColor.white.withAlphaComponent(0.12).cgColor
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        // Subtle dark tint over Gaussian blur for rich contrast
        NSColor(calibratedWhite: 0.10, alpha: 0.45).setFill()
        dirtyRect.fill(using: .sourceOver)
    }
}

// MARK: - Search Text Field with Key Delegation
protocol SearchFieldDelegate: AnyObject {
    func searchFieldDidPressKey(event: NSEvent) -> Bool
    func searchFieldTextDidChange(text: String)
}

class SearchField: NSTextField {
    weak var keyDelegate: SearchFieldDelegate?
    
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if let handled = keyDelegate?.searchFieldDidPressKey(event: event), handled {
            return true
        }
        return super.performKeyEquivalent(with: event)
    }
    
    override func textDidChange(_ notification: Notification) {
        super.textDidChange(notification)
        keyDelegate?.searchFieldTextDidChange(text: stringValue)
    }
}

// MARK: - Floating Switcher HUD Panel
class SwitcherHUDPanel: NSPanel {
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.isMovableByWindowBackground = true
    }
    
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
    
    override func resignKey() {
        super.resignKey()
        // Auto-dismiss when losing focus
        self.orderOut(nil)
    }
    
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // ESC
            self.orderOut(nil)
            return
        }
        super.keyDown(with: event)
    }
}

// MARK: - Workspace Row View
class WorkspaceRowView: NSTableRowView {
    var isCurrentSelection: Bool = false {
        didSet { needsDisplay = true }
    }
    
    override func drawSelection(in dirtyRect: NSRect) {
        // Custom sleek rounded selection highlight
        let selectionRect = NSRect(x: 8.0, y: 3.0, width: bounds.width - 16.0, height: bounds.height - 6.0)
        let path = NSBezierPath(roundedRect: selectionRect, xRadius: 8.0, yRadius: 8.0)
        NSColor(calibratedRed: 0.16, green: 0.65, blue: 0.98, alpha: 0.28).setFill()
        path.fill()
        
        let borderPath = NSBezierPath(roundedRect: selectionRect, xRadius: 8.0, yRadius: 8.0)
        borderPath.lineWidth = 1.0
        NSColor(calibratedRed: 0.16, green: 0.65, blue: 0.98, alpha: 0.50).setStroke()
        borderPath.stroke()
    }
}

// MARK: - Workspace Cell View
class WorkspaceCellView: NSTableCellView {
    var iconView: NSImageView!
    var projectLabel: NSTextField!
    var fileLabel: NSTextField!
    var shortcutBadge: NSTextField!
    
    init(folderIcon: NSImage) {
        super.init(frame: .zero)
        
        iconView = NSImageView(frame: NSRect(x: 18, y: 12, width: 22, height: 22))
        iconView.image = folderIcon
        iconView.imageScaling = .scaleProportionallyUpOrDown
        addSubview(iconView)
        
        projectLabel = NSTextField(labelWithString: "")
        projectLabel.font = NSFont.systemFont(ofSize: 13.5, weight: .semibold)
        projectLabel.textColor = .white
        projectLabel.frame = NSRect(x: 48, y: 22, width: 380, height: 18)
        addSubview(projectLabel)
        
        fileLabel = NSTextField(labelWithString: "")
        fileLabel.font = NSFont.systemFont(ofSize: 11.0, weight: .regular)
        fileLabel.textColor = NSColor(calibratedWhite: 0.65, alpha: 1.0)
        fileLabel.frame = NSRect(x: 48, y: 6, width: 380, height: 16)
        addSubview(fileLabel)
        
        shortcutBadge = NSTextField(labelWithString: "")
        shortcutBadge.font = NSFont.monospacedSystemFont(ofSize: 11.5, weight: .medium)
        shortcutBadge.textColor = NSColor(calibratedWhite: 0.60, alpha: 1.0)
        shortcutBadge.alignment = .right
        shortcutBadge.frame = NSRect(x: 480, y: 14, width: 65, height: 18)
        addSubview(shortcutBadge)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with item: WorkspaceItem, slotIndex: Int?, isSelected: Bool) {
        projectLabel.stringValue = item.project
        if let file = item.file {
            fileLabel.stringValue = file
            fileLabel.isHidden = false
            projectLabel.frame = NSRect(x: 48, y: 23, width: 420, height: 18)
        } else {
            fileLabel.isHidden = true
            projectLabel.frame = NSRect(x: 48, y: 14, width: 420, height: 18)
        }
        
        if isSelected {
            shortcutBadge.stringValue = "↵"
            shortcutBadge.textColor = NSColor(calibratedRed: 0.40, green: 0.85, blue: 1.0, alpha: 1.0)
        } else if let slot = slotIndex, slot < 9 {
            shortcutBadge.stringValue = "⌘ \(slot + 1)"
            shortcutBadge.textColor = NSColor(calibratedWhite: 0.55, alpha: 1.0)
        } else {
            shortcutBadge.stringValue = ""
        }
    }
}

// MARK: - Main Application Delegate & Controller
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, NSTableViewDataSource, NSTableViewDelegate, SearchFieldDelegate {
    var statusItem: NSStatusItem!
    let menu = NSMenu()
    var blueFolderIcon: NSImage!
    
    // Switcher HUD UI
    var hudPanel: SwitcherHUDPanel!
    var searchField: SearchField!
    var tableView: NSTableView!
    var scrollView: NSScrollView!
    var footerLabel: NSTextField!
    
    // Workspace Cache
    var allWorkspaces: [WorkspaceItem] = []
    var filteredWorkspaces: [WorkspaceItem] = []
    var selectedIndex: Int = 0
    
    // HotKey event tap
    var eventTap: CFMachPort?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        checkAccessibility(prompt: true)
        blueFolderIcon = createBlueFolderIcon()
        
        setupStatusItem()
        setupHUD()
        setupGlobalHotKey()
    }
    
    // MARK: - Vector Icon Creation
    func createTrayIcon() -> NSImage {
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
    
    func createBlueFolderIcon() -> NSImage {
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
    
    // MARK: - Status Bar Setup
    func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = createTrayIcon()
            button.imagePosition = .imageOnly
            button.toolTip = "Antigravity Spaces (⌥A)"
            button.target = self
            button.action = #selector(statusItemClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        menu.delegate = self
    }
    
    @objc func statusItemClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp {
            statusItem.menu = menu
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
        } else {
            toggleHUD()
        }
    }
    
    // MARK: - Setup Gaussian Frosted Glass HUD
    func setupHUD() {
        let width: CGFloat = 580
        let height: CGFloat = 430
        let rect = NSRect(x: 0, y: 0, width: width, height: height)
        
        hudPanel = SwitcherHUDPanel(contentRect: rect)
        
        let container = FrostedGlassView(frame: rect)
        container.autoresizingMask = [.width, .height]
        hudPanel.contentView = container
        
        // Search Icon
        let iconSize: CGFloat = 16
        let searchIconView = NSImageView(frame: NSRect(x: 20, y: height - 44, width: iconSize, height: iconSize))
        searchIconView.image = NSImage(systemSymbolName: "magnifyingglass", accessibilityDescription: "Search")
        searchIconView.contentTintColor = NSColor(calibratedWhite: 0.65, alpha: 1.0)
        container.addSubview(searchIconView)
        
        // Search Input Field
        searchField = SearchField(frame: NSRect(x: 46, y: height - 50, width: width - 110, height: 28))
        searchField.font = NSFont.systemFont(ofSize: 15.0, weight: .regular)
        searchField.textColor = .white
        searchField.backgroundColor = .clear
        searchField.isBordered = false
        searchField.focusRingType = .none
        searchField.placeholderAttributedString = NSAttributedString(
            string: "Search workspaces... (↑/↓ to navigate, ↵ to switch)",
            attributes: [
                .foregroundColor: NSColor(calibratedWhite: 0.50, alpha: 1.0),
                .font: NSFont.systemFont(ofSize: 14.0, weight: .regular)
            ]
        )
        searchField.keyDelegate = self
        container.addSubview(searchField)
        
        // ESC Badge on right
        let escBadge = NSTextField(labelWithString: "esc")
        escBadge.font = NSFont.monospacedSystemFont(ofSize: 10.5, weight: .medium)
        escBadge.textColor = NSColor(calibratedWhite: 0.50, alpha: 1.0)
        escBadge.alignment = .center
        escBadge.frame = NSRect(x: width - 48, y: height - 44, width: 30, height: 16)
        escBadge.wantsLayer = true
        escBadge.layer?.cornerRadius = 4.0
        escBadge.layer?.borderWidth = 1.0
        escBadge.layer?.borderColor = NSColor(calibratedWhite: 0.30, alpha: 1.0).cgColor
        container.addSubview(escBadge)
        
        // Divider Line
        let divider = NSBox(frame: NSRect(x: 0, y: height - 58, width: width, height: 1))
        divider.boxType = .separator
        container.addSubview(divider)
        
        // Workspaces Table View
        scrollView = NSScrollView(frame: NSRect(x: 0, y: 32, width: width, height: height - 91))
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        
        tableView = NSTableView(frame: scrollView.bounds)
        tableView.backgroundColor = .clear
        tableView.headerView = nil
        tableView.rowHeight = 46
        tableView.intercellSpacing = .zero
        
        let col = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("WorkspaceCol"))
        col.width = width
        tableView.addTableColumn(col)
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.target = self
        tableView.action = #selector(tableRowClicked)
        
        scrollView.documentView = tableView
        container.addSubview(scrollView)
        
        // Footer Bar
        let footerDivider = NSBox(frame: NSRect(x: 0, y: 31, width: width, height: 1))
        footerDivider.boxType = .separator
        container.addSubview(footerDivider)
        
        footerLabel = NSTextField(labelWithString: "⌥A Toggle Switcher   •   ↑↓ Navigate   •   ↵ Focus   •   ⌘1–⌘9 Quick Switch")
        footerLabel.font = NSFont.systemFont(ofSize: 10.5, weight: .regular)
        footerLabel.textColor = NSColor(calibratedWhite: 0.45, alpha: 1.0)
        footerLabel.alignment = .center
        footerLabel.frame = NSRect(x: 0, y: 8, width: width, height: 16)
        container.addSubview(footerLabel)
    }
    
    // MARK: - Global Hotkey Listener (Option + A)
    func setupGlobalHotKey() {
        let mask = (1 << CGEventType.keyDown.rawValue)
        let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                if type == .keyDown {
                    let flags = event.flags
                    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
                    
                    let hasOption = flags.contains(.maskAlternate)
                    let hasCommand = flags.contains(.maskCommand)
                    let hasControl = flags.contains(.maskControl)
                    
                    // Key code 0 is 'A'. Option + A summons the HUD!
                    if hasOption && !hasCommand && !hasControl && keyCode == 0 {
                        DispatchQueue.main.async {
                            if let delegate = NSApp.delegate as? AppDelegate {
                                delegate.toggleHUD()
                            }
                        }
                        return nil // Swallow event so 'å' is not typed into background app!
                    }
                }
                return Unmanaged.passRetained(event)
            },
            userInfo: nil
        )

        if let tap = tap {
            self.eventTap = tap
            let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            CGEvent.tapEnable(tap: tap, enable: true)
        }
        
        // Also listen locally when app is active
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.contains(.option) && 
               !event.modifierFlags.contains(.command) && 
               !event.modifierFlags.contains(.control) && 
               event.keyCode == 0 {
                self?.toggleHUD()
                return nil
            }
            return event
        }
    }
    
    // MARK: - HUD Presentation & Window Positioning
    func toggleHUD() {
        if hudPanel.isVisible {
            hudPanel.orderOut(nil)
        } else {
            showHUD()
        }
    }
    
    func showHUD() {
        refreshWorkspaces()
        searchField.stringValue = ""
        filteredWorkspaces = allWorkspaces
        selectedIndex = 0
        tableView.reloadData()
        
        // Center on the active screen
        let screen = NSScreen.main ?? NSScreen.screens.first!
        let screenRect = screen.visibleFrame
        let hudRect = hudPanel.frame
        let newOrigin = NSPoint(
            x: screenRect.midX - (hudRect.width / 2.0),
            y: screenRect.midY - (hudRect.height / 2.0) + (screenRect.height * 0.12)
        )
        hudPanel.setFrameOrigin(newOrigin)
        
        NSApp.activate(ignoringOtherApps: true)
        hudPanel.makeKeyAndOrderFront(nil)
        hudPanel.makeFirstResponder(searchField)
    }
    
    // MARK: - Workspace Discovery
    func refreshWorkspaces() {
        let runningApps = NSWorkspace.shared.runningApplications
        let myPid = ProcessInfo.processInfo.processIdentifier
        let antigravityApps = runningApps.filter { app in
            guard app.processIdentifier != myPid else { return false }
            let name = app.localizedName ?? ""
            let bundle = app.bundleIdentifier ?? ""
            if name.localizedCaseInsensitiveContains("helper") || bundle.localizedCaseInsensitiveContains("helper") {
                return false
            }
            return name.localizedCaseInsensitiveContains("antigravity") || 
                   bundle.localizedCaseInsensitiveContains("antigravity") ||
                   name == "Electron"
        }
        
        var discovered: [WorkspaceItem] = []
        
        for app in antigravityApps {
            let pid = app.processIdentifier
            let appRef = AXUIElementCreateApplication(pid)
            var windowsRef: AnyObject?
            
            let result = AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute as CFString, &windowsRef)
            if result == .success, let windows = windowsRef as? [AXUIElement] {
                for win in windows {
                    var titleRef: AnyObject?
                    if AXUIElementCopyAttributeValue(win, kAXTitleAttribute as CFString, &titleRef) == .success,
                       let title = titleRef as? String, !title.isEmpty {
                        let (project, file) = parseWorkspaceTitle(title)
                        discovered.append(WorkspaceItem(
                            rawTitle: title,
                            project: project,
                            file: file,
                            pid: pid,
                            windowRef: win
                        ))
                    }
                }
            }
        }
        
        self.allWorkspaces = discovered
        self.filteredWorkspaces = discovered
    }
    
    func parseWorkspaceTitle(_ rawTitle: String) -> (project: String, file: String?) {
        var clean = rawTitle
        for suffix in [" — Antigravity", " - Antigravity", " — Visual Studio Code", " - Visual Studio Code"] {
            if clean.hasSuffix(suffix) {
                clean = String(clean.dropLast(suffix.count))
            }
        }
        clean = clean.trimmingCharacters(in: CharacterSet(charactersIn: "●* ").union(.whitespacesAndNewlines))
        
        let separators = [" — ", " – ", " - "]
        for sep in separators {
            if clean.contains(sep) {
                let parts = clean.components(separatedBy: sep).map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                if parts.count >= 2 {
                    let first = parts.first!
                    let last = parts.last!
                    
                    let isFile = { (s: String) -> Bool in
                        let lower = s.lowercased()
                        let knownFiles = ["makefile", "dockerfile", "gemfile", "rakefile", "procfile", "license", "readme"]
                        if knownFiles.contains(lower) { return true }
                        let ext = (s as NSString).pathExtension
                        return !ext.isEmpty && ext.count <= 6 && !ext.contains(" ")
                    }
                    
                    if isFile(last) && !isFile(first) {
                        return (project: first, file: last)
                    } else if isFile(first) && !isFile(last) {
                        return (project: last, file: first)
                    } else {
                        return (project: last, file: first)
                    }
                }
            }
        }
        return (project: clean, file: nil)
    }
    
    // MARK: - Activation & Window Focus
    func activateWorkspace(_ item: WorkspaceItem) {
        hudPanel.orderOut(nil)
        
        if let app = NSRunningApplication(processIdentifier: item.pid) {
            if #available(macOS 14.0, *) {
                app.activate()
            } else {
                app.activate(options: [.activateIgnoringOtherApps])
            }
        }
        AXUIElementPerformAction(item.windowRef, kAXRaiseAction as CFString)
    }
    
    // MARK: - SearchFieldDelegate
    func searchFieldTextDidChange(text: String) {
        let query = text.trimmingCharacters(in: .whitespaces).lowercased()
        if query.isEmpty {
            filteredWorkspaces = allWorkspaces
        } else {
            filteredWorkspaces = allWorkspaces.filter { item in
                let matchProject = item.project.lowercased().contains(query)
                let matchFile = item.file?.lowercased().contains(query) ?? false
                return matchProject || matchFile
            }
        }
        selectedIndex = 0
        tableView.reloadData()
        if !filteredWorkspaces.isEmpty {
            tableView.scrollRowToVisible(0)
        }
    }
    
    func searchFieldDidPressKey(event: NSEvent) -> Bool {
        // Down Arrow
        if event.keyCode == 125 {
            if !filteredWorkspaces.isEmpty {
                selectedIndex = (selectedIndex + 1) % filteredWorkspaces.count
                tableView.reloadData()
                tableView.scrollRowToVisible(selectedIndex)
            }
            return true
        }
        // Up Arrow
        if event.keyCode == 126 {
            if !filteredWorkspaces.isEmpty {
                selectedIndex = (selectedIndex - 1 + filteredWorkspaces.count) % filteredWorkspaces.count
                tableView.reloadData()
                tableView.scrollRowToVisible(selectedIndex)
            }
            return true
        }
        // Enter / Return
        if event.keyCode == 36 {
            if selectedIndex >= 0 && selectedIndex < filteredWorkspaces.count {
                activateWorkspace(filteredWorkspaces[selectedIndex])
            }
            return true
        }
        // Escape
        if event.keyCode == 53 {
            hudPanel.orderOut(nil)
            return true
        }
        // Command + 1..9
        if event.modifierFlags.contains(.command) {
            let numMap: [UInt16: Int] = [
                18: 0, 19: 1, 20: 2, 21: 3, 23: 4, 22: 5, 26: 6, 28: 7, 25: 8
            ]
            if let slot = numMap[event.keyCode], slot < filteredWorkspaces.count {
                activateWorkspace(filteredWorkspaces[slot])
                return true
            }
        }
        return false
    }
    
    // MARK: - NSTableViewDataSource & Delegate
    func numberOfRows(in tableView: NSTableView) -> Int {
        return filteredWorkspaces.count
    }
    
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        let rowView = WorkspaceRowView()
        rowView.isCurrentSelection = (row == selectedIndex)
        return rowView
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < filteredWorkspaces.count else { return nil }
        let item = filteredWorkspaces[row]
        let cell = WorkspaceCellView(folderIcon: blueFolderIcon)
        cell.configure(with: item, slotIndex: row, isSelected: (row == selectedIndex))
        return cell
    }
    
    @objc func tableRowClicked() {
        let clicked = tableView.clickedRow
        if clicked >= 0 && clicked < filteredWorkspaces.count {
            activateWorkspace(filteredWorkspaces[clicked])
        }
    }
    
    // MARK: - Menu Bar Dropdown Delegate
    func menuWillOpen(_ menu: NSMenu) {
        refreshMenu()
    }
    
    func refreshMenu() {
        menu.removeAllItems()
        
        let hudItem = NSMenuItem(title: "Open Switcher HUD", action: #selector(openHUDFromMenu), keyEquivalent: "a")
        hudItem.keyEquivalentModifierMask = [.option]
        hudItem.target = self
        menu.addItem(hudItem)
        menu.addItem(NSMenuItem.separator())
        
        let header = NSMenuItem(title: "Active Antigravity Spaces", action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)
        menu.addItem(NSMenuItem.separator())
        
        let isTrusted = AXIsProcessTrusted()
        if !isTrusted {
            let warn = NSMenuItem(title: "⚠️ Accessibility Permission Needed", action: #selector(openAccessibilitySettings), keyEquivalent: "")
            warn.target = self
            menu.addItem(warn)
            let grant = NSMenuItem(title: "Click to grant in System Settings", action: #selector(openAccessibilitySettings), keyEquivalent: "")
            grant.target = self
            menu.addItem(grant)
            menu.addItem(NSMenuItem.separator())
        }
        
        refreshWorkspaces()
        
        if allWorkspaces.isEmpty {
            if isTrusted {
                let emptyItem = NSMenuItem(title: "No Antigravity spaces detected", action: nil, keyEquivalent: "")
                emptyItem.isEnabled = false
                menu.addItem(emptyItem)
            }
        } else {
            for (index, item) in allWorkspaces.enumerated() {
                let key = index < 9 ? "\(index + 1)" : ""
                let menuItem = NSMenuItem(title: item.project, action: #selector(menuItemSelected(_:)), keyEquivalent: key)
                menuItem.image = blueFolderIcon
                menuItem.representedObject = item
                menuItem.target = self
                menu.addItem(menuItem)
            }
        }
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Spaces", action: #selector(quitApp), keyEquivalent: "q"))
    }
    
    @objc func openHUDFromMenu() {
        showHUD()
    }
    
    @objc func menuItemSelected(_ sender: NSMenuItem) {
        guard let item = sender.representedObject as? WorkspaceItem else { return }
        activateWorkspace(item)
    }
    
    @objc func openAccessibilitySettings() {
        checkAccessibility(prompt: true)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @discardableResult
    func checkAccessibility(prompt: Bool) -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
    
    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
