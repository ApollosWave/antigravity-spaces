import Foundation

/// Manages persistent user preferences via UserDefaults.
public class PreferencesService {
    public static let shared = PreferencesService()
    
    private let defaults = UserDefaults.standard
    private let displayPrefKey = "antigravity_spaces_display_pref"
    private let hotkeyConfigKey = "antigravity_spaces_hotkey_config"
    private let hotkeyStringKey = "antigravity_spaces_hotkey"
    
    public init() {}
    
    // MARK: - Display Preferences (-1 = Auto/Mouse, >=0 = Specific Screen Index)
    public func loadTargetDisplayIndex() -> Int {
        if let saved = defaults.value(forKey: displayPrefKey) as? Int {
            return saved
        }
        return -1
    }
    
    public func saveTargetDisplayIndex(_ index: Int) {
        defaults.set(index, forKey: displayPrefKey)
    }
    
    // MARK: - Hotkey Configuration
    public func loadHotkey() -> HotkeyConfig {
        if let data = defaults.data(forKey: hotkeyConfigKey),
           let config = try? JSONDecoder().decode(HotkeyConfig.self, from: data) {
            return config
        }
        if let str = defaults.string(forKey: hotkeyStringKey) {
            if let found = HotkeyConfig.presets.first(where: {
                $0.id.lowercased() == str.lowercased() ||
                $0.shortTitle.lowercased() == str.lowercased()
            }) {
                return found
            }
        }
        return HotkeyConfig.defaultHotkey
    }
    
    public func saveHotkey(_ config: HotkeyConfig) {
        if let data = try? JSONEncoder().encode(config) {
            defaults.set(data, forKey: hotkeyConfigKey)
            defaults.set(config.id, forKey: hotkeyStringKey)
        }
    }
}
