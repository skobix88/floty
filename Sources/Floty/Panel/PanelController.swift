import AppKit
import SwiftUI

/// Shows, hides and remembers the panel.
@MainActor
final class PanelController: NSObject, NSWindowDelegate {

    private let store: NoteStore
    private let settings: AppSettings
    private var panel: FlotyPanel?
    private var pinObservation: NSKeyValueObservation?

    init(store: NoteStore, settings: AppSettings) {
        self.store = store
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
        applyLevel()
        // orderFrontRegardless keeps the app in the background; makeKey then
        // gives the panel keyboard focus without activating Floty.
        panel.orderFrontRegardless()
        panel.makeKey()
    }

    func hide() {
        store.flush()
        panel?.orderOut(nil)
    }

    /// Called when the pin state changes, so the level follows immediately.
    func applyLevel() {
        panel?.level = settings.isPinned ? .floating : .normal
    }

    private func makePanel() -> FlotyPanel {
        let frame = PanelPlacement.resolve(
            stored: settings.panelFrame,
            screens: NSScreen.screens.map(\.visibleFrame),
            fallback: defaultFrame()
        )
        let panel = FlotyPanel(contentRect: frame)
        panel.delegate = self
        panel.contentView = NSHostingView(rootView: PanelView(
            store: store,
            settings: settings,
            onClose: { [weak self] in self?.hide() }
        ))
        panel.setFrame(frame, display: false)
        return panel
    }

    /// Opens where the user is looking: the screen the pointer is on, not
    /// whichever screen AppKit happens to call main.
    private func defaultFrame() -> NSRect {
        let pointer = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { $0.frame.contains(pointer) }
            ?? NSScreen.main
            ?? NSScreen.screens.first
        guard let screen else {
            return NSRect(origin: .zero, size: PanelPlacement.defaultSize)
        }
        return PanelPlacement.defaultFrame(in: screen.visibleFrame)
    }

    // MARK: - NSWindowDelegate

    func windowDidResignKey(_ notification: Notification) {
        guard settings.hidesOnClickOutside, !settings.isPinned else { return }
        hide()
    }

    func windowDidMove(_ notification: Notification) { rememberFrame() }
    func windowDidResize(_ notification: Notification) { rememberFrame() }

    private func rememberFrame() {
        guard let panel, panel.isVisible else { return }
        settings.panelFrame = panel.frame
    }
}
