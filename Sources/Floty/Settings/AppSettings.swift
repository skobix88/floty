import AppKit
import Observation

/// Everything the user configures. Backed by `UserDefaults`, because all of it
/// has to survive an update - see CLAUDE.md rule 4.
@MainActor
@Observable
final class AppSettings {

    private enum Key {
        static let notesFolderBookmark = "notesFolderBookmark"
        static let notesFolderPath = "notesFolderPath"
        static let vaultFolderBookmark = "vaultFolderBookmark"
        static let vaultFolderPath = "vaultFolderPath"
        static let panelOpacity = "panelOpacity"
        static let isPinned = "isPinned"
        static let hidesOnClickOutside = "hidesOnClickOutside"
        static let panelFrame = "panelFrame"
        static let activeNoteName = "activeNoteName"
        static let noteOrder = "noteOrder"
        static let tint = "tint"
    }

    /// How far the slider may go towards transparent. The blurred backdrop
    /// underneath keeps the text readable even at the low end.
    static let minimumOpacity: Double = 0.22

    @ObservationIgnored private let defaults: UserDefaults

    var panelOpacity: Double { didSet { defaults.set(panelOpacity, forKey: Key.panelOpacity) } }
    var isPinned: Bool { didSet { defaults.set(isPinned, forKey: Key.isPinned) } }
    var tint: PanelTint { didSet { defaults.set(tint.rawValue, forKey: Key.tint) } }
    var hidesOnClickOutside: Bool { didSet { defaults.set(hidesOnClickOutside, forKey: Key.hidesOnClickOutside) } }
    var activeNoteName: String? { didSet { defaults.set(activeNoteName, forKey: Key.activeNoteName) } }
    /// Tab order by note name. Device local on purpose: the notes folder stays
    /// free of Floty's own files so Obsidian sees nothing but notes.
    var noteOrder: [String] { didSet { defaults.set(noteOrder, forKey: Key.noteOrder) } }

    /// Stored, not computed: `@Observable` only tracks stored properties, and a
    /// computed one would leave the settings window showing a stale value after
    /// the user picked a folder.
    var notesFolder: URL? {
        didSet { persist(notesFolder, path: Key.notesFolderPath, bookmark: Key.notesFolderBookmark) }
    }
    /// Where "hand over to Obsidian" writes to. Nil until the user picks one.
    var vaultFolder: URL? {
        didSet { persist(vaultFolder, path: Key.vaultFolderPath, bookmark: Key.vaultFolderBookmark) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let storedOpacity = defaults.object(forKey: Key.panelOpacity) as? Double
        panelOpacity = storedOpacity ?? 0.85
        isPinned = defaults.bool(forKey: Key.isPinned)
        tint = PanelTint(rawValue: defaults.string(forKey: Key.tint) ?? "") ?? .neutral
        hidesOnClickOutside = defaults.object(forKey: Key.hidesOnClickOutside) as? Bool ?? true
        activeNoteName = defaults.string(forKey: Key.activeNoteName)
        noteOrder = defaults.stringArray(forKey: Key.noteOrder) ?? []
        notesFolder = Self.loadFolder(defaults, path: Key.notesFolderPath, bookmark: Key.notesFolderBookmark)
        vaultFolder = Self.loadFolder(defaults, path: Key.vaultFolderPath, bookmark: Key.vaultFolderBookmark)
    }

    // MARK: - Folders

    /// The bookmark is tried first because it survives a move in the Finder;
    /// the plain path is the fallback when it cannot be resolved any more.
    private static func loadFolder(_ defaults: UserDefaults, path: String, bookmark: String) -> URL? {
        if let data = defaults.data(forKey: bookmark), let url = FolderAccess.resolve(bookmark: data) {
            return url
        }
        guard let stored = defaults.string(forKey: path) else { return nil }
        return URL(filePath: stored, directoryHint: .isDirectory)
    }

    private func persist(_ url: URL?, path: String, bookmark: String) {
        guard let url else {
            defaults.removeObject(forKey: path)
            defaults.removeObject(forKey: bookmark)
            return
        }
        defaults.set(url.path(percentEncoded: false), forKey: path)
        if let data = try? FolderAccess.makeBookmark(for: url) {
            defaults.set(data, forKey: bookmark)
        } else {
            // Der Pfad allein reicht; ein altes, unpassendes Lesezeichen nicht.
            defaults.removeObject(forKey: bookmark)
        }
    }

    // MARK: - Panel geometry

    var panelFrame: NSRect? {
        get {
            guard let stored = defaults.string(forKey: Key.panelFrame) else { return nil }
            let frame = NSRectFromString(stored)
            return frame.isEmpty ? nil : frame
        }
        set {
            guard let newValue else { return }
            defaults.set(NSStringFromRect(newValue), forKey: Key.panelFrame)
        }
    }
}
