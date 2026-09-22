import Cocoa

/// Custom visual effect view with hardware-accelerated vibrant dark frosted glass.
public class FrostedGlassView: NSVisualEffectView {
    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.material = .underWindowBackground
        self.blendingMode = .behindWindow
        self.state = .active
        self.appearance = NSAppearance(named: .vibrantDark)
        self.wantsLayer = true
        self.layer?.cornerRadius = 16.0
        self.layer?.masksToBounds = true
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    public override func draw(_ dirtyRect: NSRect) {
        // Clip all background drawing to the 16px rounded path (eliminates square corner artifacts)
        let clipPath = NSBezierPath(roundedRect: bounds, xRadius: 16.0, yRadius: 16.0)
        clipPath.addClip()
        
        super.draw(dirtyRect)
        
        // Rich, high-contrast dark graphite wash over the Gaussian blur
        NSColor(calibratedRed: 0.11, green: 0.12, blue: 0.15, alpha: 0.88).setFill()
        clipPath.fill()
        
        // Crisp 1px border drawn directly on the rounded curve
        let strokePath = NSBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), xRadius: 15.5, yRadius: 15.5)
        strokePath.lineWidth = 1.0
        NSColor.white.withAlphaComponent(0.18).setStroke()
        strokePath.stroke()
    }
}
