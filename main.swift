import Cocoa
import CoreGraphics
import ApplicationServices

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    var statusItem: NSStatusItem!
    let menu = NSMenu()
    var blueFolderIcon: NSImage!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        checkAccessibility(prompt: true)
        
        blueFolderIcon = createBlueFolderIcon()
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = createTrayIcon()
            button.imagePosition = .imageOnly
            button.toolTip = "Antigravity Spaces (⌘1-⌘9)"
        }
        
        menu.delegate = self
        statusItem.menu = menu
        refreshMenu()
    }
    
    // Custom vector template icon: Bold 'A' with ascending levitation arrow (A↗)
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
    
    // Vibrant Apple Electric Blue folder icon (isTemplate = false to preserve color)
    func createBlueFolderIcon() -> NSImage {
        let size = NSSize(width: 16, height: 16)
        let img = NSImage(size: size, flipped: false) { rect in
            guard let _ = NSGraphicsContext.current?.cgContext else { return false }
            
            // Vibrant Apple electric folder blue
            let folderBlue = NSColor(calibratedRed: 0.16, green: 0.65, blue: 0.98, alpha: 1.0)
            let tabBlue = NSColor(calibratedRed: 0.10, green: 0.52, blue: 0.85, alpha: 1.0)
            
            // Draw folder back tab (top-left tab)
            let tabRect = NSRect(x: 1.0, y: 5.5, width: 7.0, height: 8.5)
            let tabPath = NSBezierPath(roundedRect: tabRect, xRadius: 2.0, yRadius: 2.0)
            tabBlue.setFill()
            tabPath.fill()
            
            // Draw main folder body
            let bodyRect = NSRect(x: 1.0, y: 1.5, width: 14.0, height: 10.0)
            let bodyPath = NSBezierPath(roundedRect: bodyRect, xRadius: 2.0, yRadius: 2.0)
            folderBlue.setFill()
            bodyPath.fill()
            
            // Subtle folder front lip highlight for Apple 3D depth
            let lipRect = NSRect(x: 1.5, y: 8.0, width: 13.0, height: 3.0)
            let lipPath = NSBezierPath(roundedRect: lipRect, xRadius: 1.2, yRadius: 1.2)
            NSColor.white.withAlphaComponent(0.22).setFill()
            lipPath.fill()
            
            return true
        }
        img.isTemplate = false // Crucial: false guarantees macOS keeps the folder vivid electric blue in menu!
        return img
    }
    
    func menuWillOpen(_ menu: NSMenu) {
        refreshMenu()
    }
    
    func refreshMenu() {
        menu.removeAllItems()
        
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
        
        var foundWindows: [(title: String, pid: pid_t)] = []
        
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
                        foundWindows.append((title: title, pid: pid))
                    }
                }
            }
        }
        
        if foundWindows.isEmpty {
            if isTrusted {
                let emptyItem = NSMenuItem(title: "No Antigravity spaces detected", action: nil, keyEquivalent: "")
                emptyItem.isEnabled = false
                menu.addItem(emptyItem)
            }
        } else {
            for (index, win) in foundWindows.enumerated() {
                let cleanTitle = formatProjectTitle(win.title)
                let key = index < 9 ? "\(index + 1)" : ""
                let item = NSMenuItem(title: cleanTitle, action: #selector(windowSelected(_:)), keyEquivalent: key)
                item.image = blueFolderIcon // Attach crisp blue folder icon
                item.representedObject = win
                item.target = self
                menu.addItem(item)
            }
        }
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Spaces", action: #selector(quitApp), keyEquivalent: "q"))
    }
    
    // Extracts ONLY the project workspace name (no file names)
    func formatProjectTitle(_ rawTitle: String) -> String {
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
                        return first
                    } else {
                        return last
                    }
                }
            }
        }
        return clean
    }
    
    @objc func windowSelected(_ sender: NSMenuItem) {
        guard let win = sender.representedObject as? (title: String, pid: pid_t) else { return }
        
        if let app = NSRunningApplication(processIdentifier: win.pid) {
            if #available(macOS 14.0, *) {
                app.activate()
            } else {
                app.activate(options: [.activateIgnoringOtherApps])
            }
        }
        
        let appRef = AXUIElementCreateApplication(win.pid)
        var windowsRef: AnyObject?
        if AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute as CFString, &windowsRef) == .success,
           let windows = windowsRef as? [AXUIElement] {
            for window in windows {
                var titleRef: AnyObject?
                if AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleRef) == .success,
                   let title = titleRef as? String, title == win.title {
                    AXUIElementPerformAction(window, kAXRaiseAction as CFString)
                    break
                }
            }
        }
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
