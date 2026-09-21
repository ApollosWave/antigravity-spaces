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

// MARK: - Custom Visual Effect View with Rich Dark Frosted Glass
class FrostedGlassView: NSVisualEffectView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.material = .underWindowBackground
        self.blendingMode = .behindWindow
        self.state = .active
        self.appearance = NSAppearance(named: .vibrantDark)
        self.wantsLayer = true
        self.layer?.cornerRadius = 16.0
        self.layer?.masksToBounds = true
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        // Clip all background drawing to the 16px rounded path (eliminates square corner artifacts)
        let clipPath = NSBezierPath(roundedRect: bounds, xRadius: 16.0, yRadius: 16.0)
        clipPath.addClip()
        
        super.draw(dirtyRect)
        
        // Rich, high-contrast dark graphite wash over the Gaussian blur
        NSColor(calibratedRed: 0.11, green: 0.12, blue: 0.15, alpha: 0.88).setFill()
        clipPath.fill()
        
        // Crisp 1px border drawn directly on the rounded curve
        let strokePath = NSBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), xRadius: 15.5, yRadius: 15.5)
        strokePath.lineWidth = 1.0
        NSColor.white.withAlphaComponent(0.18).setStroke()
        strokePath.stroke()
    }
}

// MARK: - Custom Search Field with Command Equivalent Interception
class SearchField: NSTextField {
    var onCommandNumber: ((Int) -> Void)?
    
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.modifierFlags.contains(.command) && !event.modifierFlags.contains(.shift) && !event.modifierFlags.contains(.control) {
            let numMap: [UInt16: Int] = [
                18: 0, 19: 1, 20: 2, 21: 3, 23: 4, 22: 5, 26: 6, 28: 7, 25: 8
            ]
            if let slot = numMap[event.keyCode] {
                onCommandNumber?(slot)
                return true
            }
        }
        return super.performKeyEquivalent(with: event)
    }
}

// MARK: - Floating Switcher HUD Panel
class SwitcherHUDPanel: NSPanel {
    var onCommandNumber: ((Int) -> Void)?
    
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.appearance = NSAppearance(named: .vibrantDark)
        self.isMovableByWindowBackground = true
    }
    
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
    
    override func resignKey() {
        super.resignKey()
        self.orderOut(nil)
    }
    
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.modifierFlags.contains(.command) && !event.modifierFlags.contains(.shift) && !event.modifierFlags.contains(.control) {
            let numMap: [UInt16: Int] = [
                18: 0, 19: 1, 20: 2, 21: 3, 23: 4, 22: 5, 26: 6, 28: 7, 25: 8
            ]
            if let slot = numMap[event.keyCode] {
                onCommandNumber?(slot)
                return true
            }
        }
        return super.performKeyEquivalent(with: event)
    }
}

// MARK: - Workspace Row View with Prominent Selection Capsule
class WorkspaceRowView: NSTableRowView {
    var isCurrentSelection: Bool = false {
        didSet { needsDisplay = true }
    }
    
    override func drawBackground(in dirtyRect: NSRect) {
        super.drawBackground(in: dirtyRect)
        if isCurrentSelection {
            let selectionRect = NSRect(x: 10.0, y: 3.0, width: bounds.width - 20.0, height: bounds.height - 6.0)
            let path = NSBezierPath(roundedRect: selectionRect, xRadius: 8.0, yRadius: 8.0)
            // Vibrant electric-blue selection capsule
            NSColor(calibratedRed: 0.16, green: 0.52, blue: 0.98, alpha: 0.28).setFill()
            path.fill()
            
            let borderPath = NSBezierPath(roundedRect: selectionRect, xRadius: 8.0, yRadius: 8.0)
            borderPath.lineWidth = 1.2
            NSColor(calibratedRed: 0.30, green: 0.68, blue: 1.0, alpha: 0.75).setStroke()
            borderPath.stroke()
        }
    }
}

// MARK: - Workspace Cell View
class WorkspaceCellView: NSTableCellView {
    var iconView: NSImageView!
    var projectLabel: NSTextField!
    var fileLabel: NSTextField!
    var badgeContainer: NSView!
    var badgeLabel: NSTextField!
    
    init(folderIcon: NSImage) {
        super.init(frame: .zero)
        
        iconView = NSImageView(frame: NSRect(x: 20, y: 13, width: 22, height: 22))
        iconView.image = folderIcon
        iconView.imageScaling = .scaleProportionallyUpOrDown
        addSubview(iconView)
        
        projectLabel = NSTextField(labelWithString: "")
        projectLabel.font = NSFont.systemFont(ofSize: 14.0, weight: .semibold)
        projectLabel.textColor = .white
        addSubview(projectLabel)
        
        fileLabel = NSTextField(labelWithString: "")
        fileLabel.font = NSFont.systemFont(ofSize: 11.5, weight: .regular)
        fileLabel.textColor = NSColor(calibratedWhite: 0.70, alpha: 1.0)
        addSubview(fileLabel)
        
        // Shortcut / Switch badge on far right (anchored inside the selection capsule)
        badgeContainer = NSView(frame: .zero)
        badgeContainer.wantsLayer = true
        badgeContainer.layer?.cornerRadius = 5.0
        badgeContainer.autoresizingMask = [.minXMargin]
        
        badgeLabel = NSTextField(labelWithString: "")
        badgeLabel.font = NSFont.monospacedSystemFont(ofSize: 11.5, weight: .semibold)
        badgeLabel.alignment = .center
        badgeContainer.addSubview(badgeLabel)
        addSubview(badgeContainer)
        
        updateLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layout() {
        super.layout()
        updateLayout()
    }
    
    private func updateLayout() {
        let badgeW: CGFloat = 70.0
        let rightMargin: CGFloat = 22.0
        let currentWidth = bounds.width > 0 ? bounds.width : 580.0
        let badgeX = currentWidth - badgeW - rightMargin
        
        badgeContainer.frame = NSRect(x: badgeX, y: 13, width: badgeW, height: 22)
        badgeLabel.frame = NSRect(x: 0, y: 2, width: badgeW, height: 18)
        
        let textWidth = max(50, badgeX - 52 - 12)
        if fileLabel.isHidden {
            projectLabel.frame = NSRect(x: 52, y: 14, width: textWidth, height: 19)
        } else {
            projectLabel.frame = NSRect(x: 52, y: 23, width: textWidth, height: 19)
            fileLabel.frame = NSRect(x: 52, y: 6, width: textWidth, height: 16)
        }
    }
    
    func configure(with item: WorkspaceItem, slotIndex: Int?, isSelected: Bool) {
        projectLabel.stringValue = item.project
        
        if let file = item.file {
            fileLabel.stringValue = file
            fileLabel.isHidden = false
        } else {
            fileLabel.isHidden = true
        }
        updateLayout()
        
        if isSelected {
            projectLabel.textColor = .white
            fileLabel.textColor = NSColor(calibratedRed: 0.60, green: 0.85, blue: 1.0, alpha: 1.0)
            
            badgeContainer.isHidden = false
            badgeContainer.layer?.backgroundColor = NSColor(calibratedRed: 0.16, green: 0.52, blue: 0.98, alpha: 0.35).cgColor
            badgeContainer.layer?.borderWidth = 1.0
            badgeContainer.layer?.borderColor = NSColor(calibratedRed: 0.30, green: 0.68, blue: 1.0, alpha: 0.80).cgColor
            if let slot = slotIndex, slot < 9 {
                badgeLabel.stringValue = "⌘\(slot + 1)  ↵"
            } else {
                badgeLabel.stringValue = "↵ Switch"
            }
            badgeLabel.textColor = NSColor(calibratedRed: 0.40, green: 0.88, blue: 1.0, alpha: 1.0)
        } else {
            projectLabel.textColor = NSColor(calibratedWhite: 0.92, alpha: 1.0)
            fileLabel.textColor = NSColor(calibratedWhite: 0.65, alpha: 1.0)
            
            if let slot = slotIndex, slot < 9 {
                badgeContainer.isHidden = false
                badgeContainer.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.06).cgColor
                badgeContainer.layer?.borderWidth = 1.0
                badgeContainer.layer?.borderColor = NSColor.white.withAlphaComponent(0.12).cgColor
                badgeLabel.stringValue = "⌘ \(slot + 1)"
                badgeLabel.textColor = NSColor(calibratedWhite: 0.70, alpha: 1.0)
            } else {
                badgeContainer.isHidden = true
            }
        }
    }
}

// MARK: - Main Application Delegate & Controller
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate {
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
    
    // Display Preference (-1 = Follow Mouse Cursor / Auto, >= 0 = Specific Display Index)
    var targetDisplayIndex: Int = -1
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        checkAccessibility(prompt: true)
        blueFolderIcon = createBlueFolderIcon()
        
        if let saved = UserDefaults.standard.value(forKey: "antigravity_spaces_display_pref") as? Int {
            targetDisplayIndex = saved
        }
        
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
        let margin: CGFloat = 16.0
        let headerHeight: CGFloat = 56.0
        
        // Window is given a transparent margin to prevent macOS WindowServer from drawing an outer square border
        let panelRect = NSRect(x: 0, y: 0, width: width + margin * 2, height: height + margin * 2)
        hudPanel = SwitcherHUDPanel(contentRect: panelRect)
        hudPanel.onCommandNumber = { [weak self] slot in
            guard let self = self else { return }
            if slot < self.filteredWorkspaces.count {
                self.activateWorkspace(self.filteredWorkspaces[slot])
            }
        }
        
        let rootView = NSView(frame: panelRect)
        rootView.wantsLayer = true
        hudPanel.contentView = rootView
        
        let hudRect = NSRect(x: margin, y: margin, width: width, height: height)
        let container = FrostedGlassView(frame: hudRect)
        rootView.addSubview(container)
        
        // Dedicated Header View with precise vertical alignment
        let headerView = NSView(frame: NSRect(x: 0, y: height - headerHeight, width: width, height: headerHeight))
        container.addSubview(headerView)
        
        // Header Divider Line (at bottom of headerView, y = 0)
        let divider = NSBox(frame: NSRect(x: 0, y: 0, width: width, height: 1))
        divider.boxType = .separator
        headerView.addSubview(divider)
        
        // Centerline of the 56pt header is at y = 28.0
        // Search Icon: size 18x18. Center is 28.0 => y = 19.0
        let iconSize: CGFloat = 18.0
        let searchIconView = NSImageView(frame: NSRect(x: 20, y: 19.0, width: iconSize, height: iconSize))
        searchIconView.image = NSImage(systemSymbolName: "magnifyingglass", accessibilityDescription: "Search")
        searchIconView.contentTintColor = NSColor(calibratedRed: 0.30, green: 0.68, blue: 1.0, alpha: 1.0)
        searchIconView.imageScaling = .scaleProportionallyUpOrDown
        headerView.addSubview(searchIconView)
        
        // Search Input Field: height 26. Center is 28.0 => y = 15.0
        searchField = SearchField(frame: NSRect(x: 52, y: 15.0, width: width - 116, height: 26.0))
        searchField.font = NSFont.systemFont(ofSize: 14.5, weight: .regular)
        searchField.textColor = .white
        searchField.backgroundColor = .clear
        searchField.isBordered = false
        searchField.focusRingType = .none
        searchField.placeholderAttributedString = NSAttributedString(
            string: "Search workspaces... (Tab / ↑↓ to navigate, ↵ to switch)",
            attributes: [
                .foregroundColor: NSColor(calibratedWhite: 0.60, alpha: 1.0),
                .font: NSFont.systemFont(ofSize: 14.0, weight: .regular)
            ]
        )
        searchField.delegate = self
        searchField.onCommandNumber = { [weak self] slot in
            guard let self = self else { return }
            if slot < self.filteredWorkspaces.count {
                self.activateWorkspace(self.filteredWorkspaces[slot])
            }
        }
        headerView.addSubview(searchField)
        
        // ESC Badge: width 34, height 20. Center is 28.0 => y = 18.0 (18pt from top, 18pt from bottom divider)
        let escBadge = NSView(frame: NSRect(x: width - 52, y: 18.0, width: 34, height: 20))
        escBadge.wantsLayer = true
        escBadge.layer?.cornerRadius = 5.0
        escBadge.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.08).cgColor
        escBadge.layer?.borderWidth = 1.0
        escBadge.layer?.borderColor = NSColor.white.withAlphaComponent(0.20).cgColor
        
        let escLabel = NSTextField(labelWithString: "esc")
        escLabel.font = NSFont.monospacedSystemFont(ofSize: 10.5, weight: .semibold)
        escLabel.textColor = NSColor(calibratedWhite: 0.85, alpha: 1.0)
        escLabel.alignment = .center
        escLabel.frame = NSRect(x: 0, y: 2, width: 34, height: 16)
        escBadge.addSubview(escLabel)
        headerView.addSubview(escBadge)
        
        // Workspaces Table View
        scrollView = NSScrollView(frame: NSRect(x: 0, y: 34, width: width, height: height - 90))
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        
        tableView = NSTableView(frame: scrollView.bounds)
        tableView.autoresizingMask = [.width, .height]
        tableView.backgroundColor = .clear
        tableView.headerView = nil
        tableView.rowHeight = 48
        tableView.intercellSpacing = .zero
        
        let col = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("WorkspaceCol"))
        col.width = width
        col.resizingMask = .autoresizingMask
        tableView.addTableColumn(col)
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.target = self
        tableView.action = #selector(tableRowClicked)
        
        scrollView.documentView = tableView
        container.addSubview(scrollView)
        
        // Footer Bar
        let footerBox = NSView(frame: NSRect(x: 0, y: 0, width: width, height: 34))
        footerBox.wantsLayer = true
        footerBox.layer?.cornerRadius = 16.0
        footerBox.layer?.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        footerBox.layer?.masksToBounds = true
        footerBox.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.28).cgColor
        
        let footerDivider = NSBox(frame: NSRect(x: 0, y: 33, width: width, height: 1))
        footerDivider.boxType = .separator
        footerBox.addSubview(footerDivider)
        
        footerLabel = NSTextField(labelWithString: "⌥A Toggle   •   Tab / ↑↓ Navigate   •   ↵ Switch   •   ⌘1–⌘9 Quick Jump   •   esc Close")
        footerLabel.font = NSFont.systemFont(ofSize: 11.0, weight: .medium)
        footerLabel.textColor = NSColor(calibratedWhite: 0.65, alpha: 1.0)
        footerLabel.alignment = .center
        footerLabel.frame = NSRect(x: 0, y: 8, width: width, height: 18)
        footerBox.addSubview(footerLabel)
        
        container.addSubview(footerBox)
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
        if !filteredWorkspaces.isEmpty {
            tableView.scrollRowToVisible(0)
        }
        
        // Determine which screen to display on (User preference or mouse cursor location)
        let screen: NSScreen
        if targetDisplayIndex >= 0 && targetDisplayIndex < NSScreen.screens.count {
            screen = NSScreen.screens[targetDisplayIndex]
        } else {
            let mouseLoc = NSEvent.mouseLocation
            screen = NSScreen.screens.first { NSMouseInRect(mouseLoc, $0.frame, false) }
                ?? NSScreen.main
                ?? NSScreen.screens.first!
        }
        
        let screenRect = screen.visibleFrame
        let hudRect = hudPanel.frame
        let newOrigin = NSPoint(
            x: screenRect.midX - (hudRect.width / 2.0),
            y: screenRect.midY - (hudRect.height / 2.0) + (screenRect.height * 0.12)
        )
        hudPanel.setFrameOrigin(newOrigin)
        
        NSApp.activate(ignoringOtherApps: true)
        hudPanel.makeKeyAndOrderFront(nil)
        hudPanel.invalidateShadow()
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
    
    // MARK: - Selection Navigation (Tab, Shift+Tab, Up, Down)
    func navigateSelection(delta: Int) {
        guard !filteredWorkspaces.isEmpty else { return }
        selectedIndex = (selectedIndex + delta + filteredWorkspaces.count) % filteredWorkspaces.count
        tableView.reloadData()
        tableView.scrollRowToVisible(selectedIndex)
    }
    
    func activateCurrentSelection() {
        if selectedIndex >= 0 && selectedIndex < filteredWorkspaces.count {
            activateWorkspace(filteredWorkspaces[selectedIndex])
        }
    }
    
    // MARK: - NSTextFieldDelegate / Command Interception
    func controlTextDidChange(_ obj: Notification) {
        let query = searchField.stringValue.trimmingCharacters(in: .whitespaces).lowercased()
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
    
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        // Tab key: Cycle down
        if commandSelector == #selector(NSResponder.insertTab(_:)) {
            navigateSelection(delta: 1)
            return true
        }
        // Shift + Tab key: Cycle up
        if commandSelector == #selector(NSResponder.insertBacktab(_:)) {
            navigateSelection(delta: -1)
            return true
        }
        // Down Arrow
        if commandSelector == #selector(NSResponder.moveDown(_:)) {
            navigateSelection(delta: 1)
            return true
        }
        // Up Arrow
        if commandSelector == #selector(NSResponder.moveUp(_:)) {
            navigateSelection(delta: -1)
            return true
        }
        // Enter / Return
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            activateCurrentSelection()
            return true
        }
        // Escape
        if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
            hudPanel.orderOut(nil)
            return true
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
        
        // HUD Display Selection Submenu
        let displayMenu = NSMenu()
        let autoItem = NSMenuItem(title: "Follow Mouse Cursor (Auto)", action: #selector(setDisplayPreference(_:)), keyEquivalent: "")
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
            let item = NSMenuItem(title: title, action: #selector(setDisplayPreference(_:)), keyEquivalent: "")
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
    
    @objc func setDisplayPreference(_ sender: NSMenuItem) {
        targetDisplayIndex = sender.tag
        UserDefaults.standard.set(targetDisplayIndex, forKey: "antigravity_spaces_display_pref")
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
