import Cocoa
import CoreGraphics

/// Manages global and local keyboard event monitoring for summoning the switcher HUD.
public class HotkeyService {
    public static let shared = HotkeyService()
    
    public var currentHotkey: HotkeyConfig = HotkeyConfig.defaultHotkey
    public var onHotkeyTriggered: (() -> Void)?
    public var isRecordingActive: (() -> Bool)?
    
    private var eventTap: CFMachPort?
    private var localKeyMonitor: Any?
    
    public init() {}
    
    /// Starts both global session event tap and local application event monitor.
    public func start() {
        setupGlobalTap()
        updateLocalMonitor()
    }
    
    /// Updates the active hotkey configuration and refreshes local monitors.
    public func updateHotkey(_ config: HotkeyConfig) {
        self.currentHotkey = config
        updateLocalMonitor()
    }
    
    private func setupGlobalTap() {
        let mask = (1 << CGEventType.keyDown.rawValue)
        let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                    let service = HotkeyService.shared
                    if let tap = service.eventTap {
                        CGEvent.tapEnable(tap: tap, enable: true)
                    }
                    return Unmanaged.passRetained(event)
                }
                
                if type == .keyDown {
                    let service = HotkeyService.shared
                    
                    // Don't intercept when user is recording a new custom shortcut
                    if service.isRecordingActive?() == true {
                        return Unmanaged.passRetained(event)
                    }
                    
                    if service.currentHotkey.matches(cgEvent: event) {
                        DispatchQueue.main.async {
                            service.onHotkeyTriggered?()
                        }
                        return nil // Swallow event so keystroke isn't typed into background app!
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
    }
    
    private func updateLocalMonitor() {
        if let existing = localKeyMonitor {
            NSEvent.removeMonitor(existing)
            localKeyMonitor = nil
        }
        
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }
            if self.isRecordingActive?() == true {
                return event
            }
            if self.currentHotkey.matches(nsEvent: event) {
                self.onHotkeyTriggered?()
                return nil
            }
            return event
        }
    }
}
