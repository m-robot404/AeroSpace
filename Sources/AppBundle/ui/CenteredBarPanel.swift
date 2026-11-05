import AppKit

/// Allows the workspace bar to occupy the native menu-bar region.
@MainActor
final class CenteredBarPanel: NSPanel {
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        frameRect
    }
}
