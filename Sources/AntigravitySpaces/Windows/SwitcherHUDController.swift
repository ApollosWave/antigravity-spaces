import Cocoa

/// Controller managing the switcher HUD panel, workspace filtering, keyboard navigation, and table presentation.
public class SwitcherHUDController: NSObject, NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate {
    public var hudPanel: SwitcherHUDPanel!
    public var searchField: SearchField!
    public var tableView: NSTableView!
    public var scrollView: NSScrollView!
    public var footerLabel: NSTextField!
    
    public var allWorkspaces: [WorkspaceItem] = []
    public var filteredWorkspaces: [WorkspaceItem] = []
    public var selectedIndex: Int = 0
    public var currentHotkey: HotkeyConfig = HotkeyConfig.defaultHotkey
    
    private let blueFolderIcon: NSImage
    
    public init(folderIcon: NSImage) {
        self.blueFolderIcon = folderIcon
        super.init()
        setupHUD()
    }
    
    // MARK: - HUD Setup
    private func setupHUD() {
        let width: CGFloat = 580
        let height: CGFloat = 430
        let margin: CGFloat = 16.0
        let headerHeight: CGFloat = 56.0
        
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
        
        // Dedicated Header View
        let headerView = NSView(frame: NSRect(x: 0, y: height - headerHeight, width: width, height: headerHeight))
        container.addSubview(headerView)
        
        // Header Divider Line
        let divider = NSBox(frame: NSRect(x: 0, y: 0, width: width, height: 1))
        divider.boxType = .separator
        headerView.addSubview(divider)
        
        // Search Icon
        let iconSize: CGFloat = 18.0
        let searchIconView = NSImageView(frame: NSRect(x: 20, y: 19.0, width: iconSize, height: iconSize))
        searchIconView.image = NSImage(systemSymbolName: "magnifyingglass", accessibilityDescription: "Search")
        searchIconView.contentTintColor = NSColor(calibratedRed: 0.30, green: 0.68, blue: 1.0, alpha: 1.0)
        searchIconView.imageScaling = .scaleProportionallyUpOrDown
        headerView.addSubview(searchIconView)
        
        // Search Input Field
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
        
        // ESC Badge
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
        
        footerLabel = NSTextField(labelWithString: "")
        footerLabel.font = NSFont.systemFont(ofSize: 11.0, weight: .medium)
        footerLabel.textColor = NSColor(calibratedWhite: 0.65, alpha: 1.0)
        footerLabel.alignment = .center
        footerLabel.frame = NSRect(x: 0, y: 8, width: width, height: 18)
        footerBox.addSubview(footerLabel)
        updateFooterText()
        
        container.addSubview(footerBox)
    }
    
    public func updateFooterText() {
        footerLabel?.stringValue = "\(currentHotkey.shortTitle) Toggle   •   Tab / ↑↓ Navigate   •   ↵ Switch   •   ⌘1–⌘9 Quick Jump   •   esc Close"
    }
    
    // MARK: - Presentation
    public func toggle() {
        if hudPanel.isVisible {
            hudPanel.orderOut(nil)
        } else {
            show()
        }
    }
    
    public func show() {
        allWorkspaces = WorkspaceDiscoveryService.shared.discoverWorkspaces()
        searchField.stringValue = ""
        filteredWorkspaces = allWorkspaces
        selectedIndex = 0
        tableView.reloadData()
        if !filteredWorkspaces.isEmpty {
            tableView.scrollRowToVisible(0)
        }
        
        let targetDisplayIndex = PreferencesService.shared.loadTargetDisplayIndex()
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
    
    public func activateWorkspace(_ item: WorkspaceItem) {
        hudPanel.orderOut(nil)
        WorkspaceDiscoveryService.shared.activateWorkspace(item)
    }
    
    public func navigateSelection(delta: Int) {
        guard !filteredWorkspaces.isEmpty else { return }
        selectedIndex = (selectedIndex + delta + filteredWorkspaces.count) % filteredWorkspaces.count
        tableView.reloadData()
        tableView.scrollRowToVisible(selectedIndex)
    }
    
    public func activateCurrentSelection() {
        if selectedIndex >= 0 && selectedIndex < filteredWorkspaces.count {
            activateWorkspace(filteredWorkspaces[selectedIndex])
        }
    }
    
    // MARK: - NSTextFieldDelegate
    public func controlTextDidChange(_ obj: Notification) {
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
    
    public func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.insertTab(_:)) {
            navigateSelection(delta: 1)
            return true
        }
        if commandSelector == #selector(NSResponder.insertBacktab(_:)) {
            navigateSelection(delta: -1)
            return true
        }
        if commandSelector == #selector(NSResponder.moveDown(_:)) {
            navigateSelection(delta: 1)
            return true
        }
        if commandSelector == #selector(NSResponder.moveUp(_:)) {
            navigateSelection(delta: -1)
            return true
        }
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            activateCurrentSelection()
            return true
        }
        if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
            hudPanel.orderOut(nil)
            return true
        }
        return false
    }
    
    // MARK: - NSTableViewDataSource & Delegate
    public func numberOfRows(in tableView: NSTableView) -> Int {
        return filteredWorkspaces.count
    }
    
    public func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        let rowView = WorkspaceRowView()
        rowView.isCurrentSelection = (row == selectedIndex)
        return rowView
    }
    
    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < filteredWorkspaces.count else { return nil }
        let item = filteredWorkspaces[row]
        let cell = WorkspaceCellView(folderIcon: blueFolderIcon)
        cell.configure(with: item, slotIndex: row, isSelected: (row == selectedIndex))
        return cell
    }
    
    @objc public func tableRowClicked() {
        let clicked = tableView.clickedRow
        if clicked >= 0 && clicked < filteredWorkspaces.count {
            activateWorkspace(filteredWorkspaces[clicked])
        }
    }
}
