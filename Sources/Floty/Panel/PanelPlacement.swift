import Foundation

/// Where the panel goes. Pure geometry, so it can be checked without a display.
///
/// The point of the visibility test: a remembered position must never strand
/// the panel where the user cannot reach it - on a screen that has since been
/// disconnected, or off the edge after a resolution change. A scratchpad you
/// cannot find is worse than one that moved.
enum PanelPlacement {

    static let defaultSize = NSSize(width: 380, height: 460)
    /// Distance from the top right corner of the screen.
    static let inset: CGFloat = 40
    /// How much of the panel has to be reachable for a position to count.
    static let minimumVisible = NSSize(width: 160, height: 90)

    static func defaultFrame(in visibleFrame: NSRect) -> NSRect {
        NSRect(
            x: visibleFrame.maxX - defaultSize.width - inset,
            y: visibleFrame.maxY - defaultSize.height - inset,
            width: defaultSize.width,
            height: defaultSize.height
        )
    }

    /// Returns the stored frame when enough of it is on one of the screens,
    /// otherwise the fallback.
    static func resolve(stored: NSRect?, screens: [NSRect], fallback: NSRect) -> NSRect {
        guard let stored, !stored.isEmpty else { return fallback }
        let reachable = screens.contains { screen in
            let overlap = stored.intersection(screen)
            return overlap.width >= minimumVisible.width && overlap.height >= minimumVisible.height
        }
        return reachable ? stored : fallback
    }
}
