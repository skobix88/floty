import AppKit
import KeyboardShortcuts
import Observation

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var settings: AppSettings?
    private var store: NoteStore?
    private var panelController: PanelController?
    private var menuBarController: MenuBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // The unit test bundle is hosted by this app, so launching would
        // otherwise open the real notes folder. See CLAUDE.md rule 6.
        guard !NoteStore.isTesting else { return }

        NSApp.setActivationPolicy(.accessory)

        let settings = AppSettings()
        self.settings = settings

        let folder = settings.notesFolder ?? FolderAccess.suggestedFolder
        guard let store = try? NoteStore(folder: folder) else {
            presentFolderFailure(folder)
            return
        }
        settings.notesFolder = folder
        self.store = store

        if store.notes.isEmpty {
            _ = try? store.addNote(named: String(localized: "Notiz"))
        }
        settings.activeNoteName = settings.activeNoteName ?? store.notes.first?.name

        let panelController = PanelController(store: store, settings: settings)
        self.panelController = panelController
        menuBarController = MenuBarController { panelController.toggle() }

        KeyboardShortcuts.onKeyUp(for: .togglePanel) { panelController.toggle() }

        observePinState(settings: settings, panelController: panelController)
        panelController.show()
    }

    func applicationWillTerminate(_ notification: Notification) {
        store?.flush()
    }

    /// The pin toggle lives in SwiftUI; the window level does not. Observation
    /// re-arms itself after every change.
    private func observePinState(settings: AppSettings, panelController: PanelController) {
        withObservationTracking {
            _ = settings.isPinned
        } onChange: {
            Task { @MainActor [weak self] in
                panelController.applyLevel()
                self?.observePinState(settings: settings, panelController: panelController)
            }
        }
    }

    private func presentFolderFailure(_ folder: URL) {
        let alert = NSAlert()
        alert.messageText = String(localized: "Der Notizordner ist nicht erreichbar.")
        alert.informativeText = folder.path(percentEncoded: false)
        alert.alertStyle = .critical
        alert.runModal()
        NSApp.terminate(nil)
    }
}
