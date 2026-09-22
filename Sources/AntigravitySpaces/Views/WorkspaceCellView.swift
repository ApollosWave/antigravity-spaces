import Cocoa

/// Table cell view displaying the workspace folder icon, project title, file name, and shortcut badge.
public class WorkspaceCellView: NSTableCellView {
    public var iconView: NSImageView!
    public var projectLabel: NSTextField!
    public var fileLabel: NSTextField!
    public var badgeContainer: NSView!
    public var badgeLabel: NSTextField!
    
    public init(folderIcon: NSImage) {
        super.init(frame: .zero)
        
        iconView = NSImageView(frame: NSRect(x: 20, y: 13, width: 22, height: 22))
        iconView.image = folderIcon
        iconView.imageScaling = .scaleProportionallyUpOrDown
        addSubview(iconView)
        
        projectLabel = NSTextField(labelWithString: "")
        projectLabel.font = NSFont.systemFont(ofSize: 14.0, weight: .semibold)
        projectLabel.textColor = .white
        addSubview(projectLabel)
        
        fileLabel = NSTextField(labelWithString: "")
        fileLabel.font = NSFont.systemFont(ofSize: 11.5, weight: .regular)
        fileLabel.textColor = NSColor(calibratedWhite: 0.70, alpha: 1.0)
        addSubview(fileLabel)
        
        // Shortcut / Switch badge on far right (anchored inside the selection capsule)
        badgeContainer = NSView(frame: .zero)
        badgeContainer.wantsLayer = true
        badgeContainer.layer?.cornerRadius = 5.0
        badgeContainer.autoresizingMask = [.minXMargin]
        
        badgeLabel = NSTextField(labelWithString: "")
        badgeLabel.font = NSFont.monospacedSystemFont(ofSize: 11.5, weight: .semibold)
        badgeLabel.alignment = .center
        badgeContainer.addSubview(badgeLabel)
        addSubview(badgeContainer)
        
        updateLayout()
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layout() {
        super.layout()
        updateLayout()
    }
    
    private func updateLayout() {
        let badgeW: CGFloat = 70.0
        let rightMargin: CGFloat = 22.0
        let currentWidth = bounds.width > 0 ? bounds.width : 580.0
        let badgeX = currentWidth - badgeW - rightMargin
        
        badgeContainer.frame = NSRect(x: badgeX, y: 13, width: badgeW, height: 22)
        badgeLabel.frame = NSRect(x: 0, y: 2, width: badgeW, height: 18)
        
        let textWidth = max(50, badgeX - 52 - 12)
        if fileLabel.isHidden {
            projectLabel.frame = NSRect(x: 52, y: 14, width: textWidth, height: 19)
        } else {
            projectLabel.frame = NSRect(x: 52, y: 23, width: textWidth, height: 19)
            fileLabel.frame = NSRect(x: 52, y: 6, width: textWidth, height: 16)
        }
    }
    
    public func configure(with item: WorkspaceItem, slotIndex: Int?, isSelected: Bool) {
        projectLabel.stringValue = item.project
        
        if let file = item.file {
            fileLabel.stringValue = file
            fileLabel.isHidden = false
        } else {
            fileLabel.isHidden = true
        }
        updateLayout()
        
        if isSelected {
            projectLabel.textColor = .white
            fileLabel.textColor = NSColor(calibratedRed: 0.60, green: 0.85, blue: 1.0, alpha: 1.0)
            
            badgeContainer.isHidden = false
            badgeContainer.layer?.backgroundColor = NSColor(calibratedRed: 0.16, green: 0.52, blue: 0.98, alpha: 0.35).cgColor
            badgeContainer.layer?.borderWidth = 1.0
            badgeContainer.layer?.borderColor = NSColor(calibratedRed: 0.30, green: 0.68, blue: 1.0, alpha: 0.80).cgColor
            if let slot = slotIndex, slot < 9 {
                badgeLabel.stringValue = "⌘\(slot + 1)  ↵"
            } else {
                badgeLabel.stringValue = "↵ Switch"
            }
            badgeLabel.textColor = NSColor(calibratedRed: 0.40, green: 0.88, blue: 1.0, alpha: 1.0)
        } else {
            projectLabel.textColor = NSColor(calibratedWhite: 0.92, alpha: 1.0)
            fileLabel.textColor = NSColor(calibratedWhite: 0.65, alpha: 1.0)
            
            if let slot = slotIndex, slot < 9 {
                badgeContainer.isHidden = false
                badgeContainer.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.06).cgColor
                badgeContainer.layer?.borderWidth = 1.0
                badgeContainer.layer?.borderColor = NSColor.white.withAlphaComponent(0.12).cgColor
                badgeLabel.stringValue = "⌘ \(slot + 1)"
                badgeLabel.textColor = NSColor(calibratedWhite: 0.70, alpha: 1.0)
            } else {
                badgeContainer.isHidden = true
            }
        }
    }
}
