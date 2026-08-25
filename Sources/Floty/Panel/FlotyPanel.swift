import AppKit

/// The floating scratchpad window.
///
/// A non-activating panel: typing into it must not deactivate whatever the user
/// was working in. It still has to become key, otherwise it could not take
/// keyboard input at all.
final class FlotyPanel: NSPanel {

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView, .resizable, .closable],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        hidesOnDeactivate = false
        isMovableByWindowBackground = true
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        // Floty draws its own header, see PanelView.
        standardWindowButton(.closeButton)?.isHidden = true
        standardWindowButton(.miniaturizeButton)?.isHidden = true
        standardWindowButton(.zoomButton)?.isHidden = true

        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        // Stays visible while the user switches spaces or works full screen.
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        minSize = NSSize(width: 280, height: 200)
        animationBehavior = .utilityWindow
        // Floty remembers the position itself; AppKit's window restoration
        // would fight it and can put the panel on a screen that is gone.
        isRestorable = false
    }
}
