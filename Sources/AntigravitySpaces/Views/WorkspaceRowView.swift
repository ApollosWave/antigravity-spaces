import Cocoa

/// Table row view rendering a prominent electric-blue selection capsule.
public class WorkspaceRowView: NSTableRowView {
    public var isCurrentSelection: Bool = false {
        didSet { needsDisplay = true }
    }
    
    public override func drawBackground(in dirtyRect: NSRect) {
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
