import AppKit
import KeyboardShortcuts
import Observation

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var settings: AppSettings?
    private var store: NoteStore?
    private var panelController: PanelController?
    private var menuBarController: MenuBarController?
    private var settingsWindowController: SettingsWindowController?
    private var clipboardWatcher: ClipboardWatcher?
    private var clipboardWindowController: ClipboardWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // The unit test bundle is hosted by this app, so launching would
        // otherwise open the real notes folder. See CLAUDE.md rule 6.
        guard !NoteStore.isTesting else { return }

        NSApp.setActivationPolicy(.accessory)

        let settings = AppSettings()
        self.settings = settings

        let folder = settings.notesFolder ?? FolderAccess.suggestedFolder
        guard let store = makeStore(folder: folder, settings: settings) else {
            presentFolderFailure(folder)
            return
        }
        settings.notesFolder = folder
        self.store = store

        let clipboard = setUpClipboard(settings: settings)

        let settingsWindowController = SettingsWindowController(
            settings: settings,
            clipboard: clipboard,
            onNotesFolderChanged: { [weak self] url in self?.changeNotesFolder(to: url) }
        )
        self.settingsWindowController = settingsWindowController

        let panelController = PanelController(store: store, settings: settings) {
            settingsWindowController.show()
        }
        self.panelController = panelController

        menuBarController = MenuBarController(
            onToggle: { panelController.toggle() },
            onOpenSettings: { settingsWindowController.show() },
            onOpenClipboard: { [weak self] in self?.openClipboard() },
            isClipboardEnabled: { settings.clipboardEnabled }
        )

        KeyboardShortcuts.onKeyUp(for: .togglePanel) { panelController.toggle() }
        KeyboardShortcuts.onKeyUp(for: .toggleClipboard) { [weak self] in self?.openClipboard() }

        observePinState(settings: settings, panelController: panelController)
        panelController.show()
    }

    func applicationWillTerminate(_ notification: Notification) {
        store?.flush()
    }

    // MARK: - Notes folder

    /// Builds a store and makes sure the user always has at least one note to
    /// type into - an empty scratchpad with no tab would be a dead end.
    private func makeStore(folder: URL, settings: AppSettings) -> NoteStore? {
        guard let store = try? NoteStore(folder: folder) else { return nil }
        store.preferredOrder = settings.noteOrder
        if store.notes.isEmpty {
            _ = try? store.addNote(named: String(localized: "Notiz"))
        }
        settings.noteOrder = store.preferredOrder
        let names = Set(store.notes.map(\.name))
        if let active = settings.activeNoteName, names.contains(active) {
            // keep it
        } else {
            settings.activeNoteName = store.notes.first?.name
        }
        return store
    }

    private func changeNotesFolder(to url: URL) {
        guard let settings, let panelController else { return }
        settings.noteOrder = []
        settings.activeNoteName = nil
        guard let newStore = makeStore(folder: url, settings: settings) else {
            presentFolderFailure(url)
            return
        }
        store = newStore
        panelController.replaceStore(newStore)
    }

    // MARK: - Zwischenablage

    /// Der Verlauf wird immer aufgebaut, aber nichts läuft, solange die Funktion
    /// ausgeschaltet ist: kein Timer, kein Fenster, kein Menüeintrag.
    private func setUpClipboard(settings: AppSettings) -> ClipboardWatcher? {
        guard let store = try? ClipboardStore() else { return nil }
        let watcher = ClipboardWatcher(store: store,
                                       limits: settings.clipboardLimits,
                                       excludedApps: Set(settings.clipboardExcludedApps))
        clipboardWatcher = watcher
        clipboardWindowController = ClipboardWindowController(watcher: watcher, settings: settings)
        applyClipboardSettings(settings)
        observeClipboardSettings(settings)
        return watcher
    }

    private func applyClipboardSettings(_ settings: AppSettings) {
        guard let watcher = clipboardWatcher else { return }
        watcher.excludedApps = Set(settings.clipboardExcludedApps)
        watcher.applyLimits(settings.clipboardLimits)
        if settings.clipboardEnabled && !settings.clipboardPaused {
            watcher.start()
        } else {
            watcher.stop()
        }
    }

    private func observeClipboardSettings(_ settings: AppSettings) {
        withObservationTracking {
            _ = settings.clipboardEnabled
            _ = settings.clipboardPaused
            _ = settings.clipboardMaxCount
            _ = settings.clipboardMaxMegabytes
            _ = settings.clipboardExcludedApps
        } onChange: {
            Task { @MainActor [weak self] in
                self?.applyClipboardSettings(settings)
                self?.observeClipboardSettings(settings)
            }
        }
    }

    private func openClipboard() {
        guard settings?.clipboardEnabled == true else { return }
        clipboardWindowController?.toggle()
    }

    // MARK: - Pin

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
    }
}
