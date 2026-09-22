import Cocoa

/// Floating non-activating panel for the switcher overlay.
public class SwitcherHUDPanel: NSPanel {
    public var onCommandNumber: ((Int) -> Void)?
    
    public init(contentRect: NSRect) {
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
    
    public override var canBecomeKey: Bool { true }
    public override var canBecomeMain: Bool { true }
    
    public override func resignKey() {
        super.resignKey()
        self.orderOut(nil)
    }
    
    public override func performKeyEquivalent(with event: NSEvent) -> Bool {
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
