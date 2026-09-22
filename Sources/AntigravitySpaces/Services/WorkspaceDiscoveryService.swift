import Cocoa
import ApplicationServices

/// Discovers running Antigravity IDE instances, parses their window titles, and raises selected windows.
public class WorkspaceDiscoveryService {
    public static let shared = WorkspaceDiscoveryService()
    
    public init() {}
    
    /// Queries the system for all running Antigravity IDE workspace windows.
    public func discoverWorkspaces() -> [WorkspaceItem] {
        let runningApps = NSWorkspace.shared.runningApplications
        let myPid = ProcessInfo.processInfo.processIdentifier
        let antigravityApps = runningApps.filter { app in
            guard app.processIdentifier != myPid else { return false }
            let name = app.localizedName ?? ""
            let bundle = app.bundleIdentifier ?? ""
            if name.localizedCaseInsensitiveContains("helper") || bundle.localizedCaseInsensitiveContains("helper") {
                return false
            }
            let isAntigravity = name.localizedCaseInsensitiveContains("antigravity") || 
                               bundle.localizedCaseInsensitiveContains("antigravity")
            if isAntigravity { return true }
            
            // In development mode, raw Electron builds might be used; only inspect if bundle contains antigravity
            if name == "Electron" && bundle.localizedCaseInsensitiveContains("antigravity") {
                return true
            }
            return false
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
        
        return discovered
    }
    
    /// Parses clean project name and active file name from raw macOS window title strings.
    public func parseWorkspaceTitle(_ rawTitle: String) -> (project: String, file: String?) {
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
    
    /// Activates the target application and raises the specific window to front.
    public func activateWorkspace(_ item: WorkspaceItem) {
        if let app = NSRunningApplication(processIdentifier: item.pid) {
            if #available(macOS 14.0, *) {
                app.activate()
            } else {
                app.activate(options: [.activateIgnoringOtherApps])
            }
        }
        AXUIElementPerformAction(item.windowRef, kAXRaiseAction as CFString)
    }
    
    /// Verifies if accessibility permissions have been granted.
    @discardableResult
    public static func checkAccessibility(prompt: Bool) -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
}
