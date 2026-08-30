import AppKit
import SwiftUI

/// Holds the settings window.
///
/// Unlike the panel this one activates Floty: a settings window the user cannot
/// click into would be pointless, and it is a deliberate detour anyway.
@MainActor
final class SettingsWindowController {

    private var window: NSWindow?
    private let settings: AppSettings
    private let clipboard: ClipboardWatcher?
    private let onNotesFolderChanged: (URL) -> Void

    init(settings: AppSettings,
         clipboard: ClipboardWatcher?,
         onNotesFolderChanged: @escaping (URL) -> Void) {
        self.settings = settings
        self.clipboard = clipboard
        self.onNotesFolderChanged = onNotesFolderChanged
    }

    func show() {
        let window = window ?? makeWindow()
        self.window = window
        NSApp.activate(ignoringOtherApps: true)
        window.center()
        window.makeKeyAndOrderFront(nil)
    }

    private func makeWindow() -> NSWindow {
        let view = SettingsView(settings: settings,
                                clipboard: clipboard,
                                onNotesFolderChanged: onNotesFolderChanged)
        let window = NSWindow(contentViewController: NSHostingController(rootView: view))
        window.title = String(localized: "Floty-Einstellungen")
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        return window
    }
}
