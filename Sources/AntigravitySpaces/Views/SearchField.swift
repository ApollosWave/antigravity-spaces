import Cocoa

/// Custom search text field with Command Equivalent (⌘1-9) interception for quick jumping.
public class SearchField: NSTextField {
    public var onCommandNumber: ((Int) -> Void)?
    
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
