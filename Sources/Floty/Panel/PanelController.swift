import AppKit
import SwiftUI

/// Shows, hides and remembers the panel.
@MainActor
final class PanelController: NSObject, NSWindowDelegate {

    private var store: NoteStore
    private let settings: AppSettings
    private let onOpenSettings: () -> Void
    private var panel: FlotyPanel?

    init(store: NoteStore, settings: AppSettings, onOpenSettings: @escaping () -> Void) {
        self.store = store
        self.settings = settings
        self.onOpenSettings = onOpenSettings
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
        panel.onSettingsShortcut = { [weak self] in self?.onOpenSettings() }
        panel.contentView = makeContentView()
        panel.setFrame(frame, display: false)
        return panel
    }

    /// Opens where the user is looking: the screen the pointer is on, not
    /// whichever screen AppKit happens to call main.
    private func makeContentView() -> NSView {
        NSHostingView(rootView: PanelView(
            store: store,
            settings: settings,
            onClose: { [weak self] in self?.hide() }
        ))
    }

    /// Used when the user picks a different notes folder. The window stays put,
    /// only its contents are rebuilt.
    func replaceStore(_ newStore: NoteStore) {
        store.flush()
        store = newStore
        panel?.contentView = makeContentView()
    }

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
        // The focus change is not finished yet: a sheet is not attached to the
        // panel at this instant, and a window of ours that is taking over is
        // not key yet. Deciding now would hide the panel the moment a
        // confirmation dialog opens - taking the dialog down with it.
        Task { @MainActor [weak self] in
            self?.hideIfTheUserLeft()
        }
    }

    /// Hide only when the focus really went to another application - not to a
    /// sheet on the panel, a menu, or Floty's own settings window.
    private func hideIfTheUserLeft() {
        guard let panel, panel.isVisible else { return }
        guard settings.hidesOnClickOutside, !settings.isPinned else { return }
        guard panel.attachedSheet == nil else { return }
        if let key = NSApp.keyWindow, key !== panel { return }
        hide()
    }

    func windowDidMove(_ notification: Notification) { rememberFrame() }
    func windowDidResize(_ notification: Notification) { rememberFrame() }

    private func rememberFrame() {
        guard let panel, panel.isVisible else { return }
        settings.panelFrame = panel.frame
    }
}
