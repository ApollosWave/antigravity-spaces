import Cocoa

/// Application lifecycle coordinator wiring together the services, HUD switcher, recorder, and status bar.
public class AppDelegate: NSObject, NSApplicationDelegate {
    public var statusBarController: StatusBarController!
    public var switcherController: SwitcherHUDController!
    public var recorderPanel: ShortcutRecorderPanel!
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        WorkspaceDiscoveryService.checkAccessibility(prompt: true)
        
        let hotkey = PreferencesService.shared.loadHotkey()
        let displayIndex = PreferencesService.shared.loadTargetDisplayIndex()
        
        // Initialize Status Bar
        statusBarController = StatusBarController()
        statusBarController.currentHotkey = hotkey
        statusBarController.targetDisplayIndex = displayIndex
        
        // Initialize Switcher HUD Controller
        switcherController = SwitcherHUDController(folderIcon: statusBarController.blueFolderIcon)
        switcherController.currentHotkey = hotkey
        switcherController.updateFooterText()
        
        // Initialize Shortcut Recorder Panel
        recorderPanel = ShortcutRecorderPanel()
        recorderPanel.onShortcutRecorded = { [weak self] newConfig in
            self?.applyHotkey(newConfig)
        }
        
        // Configure Status Bar Callbacks
        statusBarController.onOpenHUD = { [weak self] in
            self?.switcherController.show()
        }
        statusBarController.onSetShortcut = { [weak self] preset in
            self?.applyHotkey(preset)
        }
        statusBarController.onOpenShortcutRecorder = { [weak self] in
            self?.recorderPanel.present()
        }
        statusBarController.onSetDisplayPreference = { [weak self] index in
            self?.statusBarController.targetDisplayIndex = index
            PreferencesService.shared.saveTargetDisplayIndex(index)
        }
        statusBarController.onActivateWorkspace = { [weak self] item in
            self?.switcherController.activateWorkspace(item)
        }
        statusBarController.onQuit = {
            NSApplication.shared.terminate(nil)
        }
        
        // Configure Hotkey Service
        let hotkeyService = HotkeyService.shared
        hotkeyService.currentHotkey = hotkey
        hotkeyService.onHotkeyTriggered = { [weak self] in
            self?.switcherController.toggle()
        }
        hotkeyService.isRecordingActive = { [weak self] in
            return self?.recorderPanel.isVisible == true
        }
        hotkeyService.start()
    }
    
    public func applyHotkey(_ config: HotkeyConfig) {
        PreferencesService.shared.saveHotkey(config)
        HotkeyService.shared.updateHotkey(config)
        
        switcherController.currentHotkey = config
        switcherController.updateFooterText()
        
        statusBarController.currentHotkey = config
        statusBarController.updateTooltip()
    }
}
