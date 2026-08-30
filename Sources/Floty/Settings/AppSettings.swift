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
        static let clipboardEnabled = "clipboardEnabled"
        static let clipboardPaused = "clipboardPaused"
        static let clipboardMaxCount = "clipboardMaxCount"
        static let clipboardMaxMegabytes = "clipboardMaxMegabytes"
        static let clipboardExcludedApps = "clipboardExcludedApps"
        static let clipboardWarningSeen = "clipboardWarningSeen"
    }

    /// How far the slider may go towards transparent. Only the backdrop fades,
    /// never the text, so even the low end stays readable.
    static let minimumOpacity: Double = 0.08

    @ObservationIgnored private let defaults: UserDefaults

    var panelOpacity: Double { didSet { defaults.set(panelOpacity, forKey: Key.panelOpacity) } }
    var isPinned: Bool { didSet { defaults.set(isPinned, forKey: Key.isPinned) } }
    var tint: PanelTint { didSet { defaults.set(tint.rawValue, forKey: Key.tint) } }

    // MARK: - Zwischenablage
    //
    // Standardmäßig aus. Eine Aktualisierung darf nicht dazu führen, dass Floty
    // plötzlich alles mitschreibt, was der Nutzer kopiert.
    var clipboardEnabled: Bool { didSet { defaults.set(clipboardEnabled, forKey: Key.clipboardEnabled) } }
    var clipboardPaused: Bool { didSet { defaults.set(clipboardPaused, forKey: Key.clipboardPaused) } }
    var clipboardMaxCount: Int { didSet { defaults.set(clipboardMaxCount, forKey: Key.clipboardMaxCount) } }
    var clipboardMaxMegabytes: Int { didSet { defaults.set(clipboardMaxMegabytes, forKey: Key.clipboardMaxMegabytes) } }
    var clipboardExcludedApps: [String] { didSet { defaults.set(clipboardExcludedApps, forKey: Key.clipboardExcludedApps) } }
    var clipboardWarningSeen: Bool { didSet { defaults.set(clipboardWarningSeen, forKey: Key.clipboardWarningSeen) } }

    var clipboardLimits: ClipboardHistory.Limits {
        ClipboardHistory.Limits(maxCount: clipboardMaxCount,
                                maxTotalBytes: clipboardMaxMegabytes * 1024 * 1024,
                                maxItemBytes: 20 * 1024 * 1024)
    }
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
        clipboardEnabled = defaults.bool(forKey: Key.clipboardEnabled)
        clipboardPaused = defaults.bool(forKey: Key.clipboardPaused)
        clipboardMaxCount = defaults.object(forKey: Key.clipboardMaxCount) as? Int ?? 50
        clipboardMaxMegabytes = defaults.object(forKey: Key.clipboardMaxMegabytes) as? Int ?? 200
        clipboardExcludedApps = defaults.stringArray(forKey: Key.clipboardExcludedApps) ?? []
        clipboardWarningSeen = defaults.bool(forKey: Key.clipboardWarningSeen)
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
