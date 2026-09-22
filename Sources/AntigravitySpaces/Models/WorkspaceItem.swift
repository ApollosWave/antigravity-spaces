import Foundation
import ApplicationServices

/// Represents an active Antigravity IDE project window.
public struct WorkspaceItem: Equatable {
    public let rawTitle: String
    public let project: String
    public let file: String?
    public let pid: pid_t
    public let windowRef: AXUIElement
    
    public init(rawTitle: String, project: String, file: String?, pid: pid_t, windowRef: AXUIElement) {
        self.rawTitle = rawTitle
        self.project = project
        self.file = file
        self.pid = pid
        self.windowRef = windowRef
    }
    
    public static func == (lhs: WorkspaceItem, rhs: WorkspaceItem) -> Bool {
        return lhs.pid == rhs.pid && lhs.rawTitle == rhs.rawTitle
    }
}
