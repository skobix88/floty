import AppKit
import SwiftUI

/// The window the clipboard history lives in.
///
/// A picker, not a place to stay: it opens, you choose, it closes. No pin, no
/// remembered position - it always appears where the eye already looks.
@MainActor
final class ClipboardWindowController: NSObject, NSWindowDelegate {

    private static let size = NSSize(width: 380, height: 460)

    private let watcher: ClipboardWatcher
    private let settings: AppSettings
    private var panel: NSPanel?

    init(watcher: ClipboardWatcher, settings: AppSettings) {
        self.watcher = watcher
        self.settings = settings
        super.init()
    }

    var isVisible: Bool { panel?.isVisible ?? false }

    func toggle() {
        if isVisible { hide() } else { show() }
    }

    func show() {
        let panel = panel ?? makePanel()
        self.panel = panel
        panel.setFrame(placement(), display: false)
        // Rebuilt every time: the list starts with an empty search field and the
        // newest entry selected, which is what you want on every opening.
        panel.contentView = makeContentView()
        panel.orderFrontRegardless()
        panel.makeKey()
    }

    func hide() {
        panel?.orderOut(nil)
    }

    private func choose(_ entry: ClipboardEntry) {
        watcher.copyToPasteboard(entry)
        hide()
    }

    // MARK: - Building

    private func makePanel() -> NSPanel {
        let panel = NSPanel(contentRect: NSRect(origin: .zero, size: Self.size),
                            styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView],
                            backing: .buffered,
                            defer: false)
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isRestorable = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.delegate = self
        return panel
    }

    private func makeContentView() -> NSView {
        NSHostingView(rootView: ClipboardListView(
            watcher: watcher,
            settings: settings,
            onChoose: { [weak self] in self?.choose($0) },
            onClose: { [weak self] in self?.hide() }
        ))
    }

    private func placement() -> NSRect {
        guard let screen = NSScreen.screens.first else {
            return NSRect(origin: .zero, size: Self.size)
        }
        return PanelPlacement.pickerFrame(in: screen.visibleFrame, size: Self.size)
    }

    // MARK: - NSWindowDelegate

    /// Unlike the scratchpad this always disappears on losing focus - it is a
    /// dialog. The decision waits one turn of the run loop for the same reason
    /// as in PanelController: a menu taking focus must not close it.
    func windowDidResignKey(_ notification: Notification) {
        Task { @MainActor [weak self] in
            guard let self, let panel, panel.isVisible else { return }
            if let key = NSApp.keyWindow, key !== panel { return }
            self.hide()
        }
    }
}
