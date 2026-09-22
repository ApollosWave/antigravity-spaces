import Foundation
import ServiceManagement

/// Manages macOS Launch at Login via modern Apple SMAppService (macOS 13+).
public class LaunchAtLoginService {
    public static var isEnabled: Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        }
        return false
    }
    
    @discardableResult
    public static func toggle() -> Bool {
        if #available(macOS 13.0, *) {
            do {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                    return false
                } else {
                    try SMAppService.mainApp.register()
                    return true
                }
            } catch {
                NSLog("AntigravitySpaces: Failed to toggle Launch at Login: \(error.localizedDescription)")
                return SMAppService.mainApp.status == .enabled
            }
        }
        return false
    }
}
