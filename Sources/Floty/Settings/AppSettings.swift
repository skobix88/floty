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
        static let panelOpacity = "panelOpacity"
        static let isPinned = "isPinned"
        static let hidesOnClickOutside = "hidesOnClickOutside"
        static let panelFrame = "panelFrame"
        static let activeNoteName = "activeNoteName"
    }

    /// Below this the text stops being readable on a busy desktop.
    static let minimumOpacity: Double = 0.45

    @ObservationIgnored private let defaults: UserDefaults

    var panelOpacity: Double { didSet { defaults.set(panelOpacity, forKey: Key.panelOpacity) } }
    var isPinned: Bool { didSet { defaults.set(isPinned, forKey: Key.isPinned) } }
    var hidesOnClickOutside: Bool { didSet { defaults.set(hidesOnClickOutside, forKey: Key.hidesOnClickOutside) } }
    var activeNoteName: String? { didSet { defaults.set(activeNoteName, forKey: Key.activeNoteName) } }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let storedOpacity = defaults.object(forKey: Key.panelOpacity) as? Double
        panelOpacity = storedOpacity ?? 0.85
        isPinned = defaults.bool(forKey: Key.isPinned)
        hidesOnClickOutside = defaults.object(forKey: Key.hidesOnClickOutside) as? Bool ?? true
        activeNoteName = defaults.string(forKey: Key.activeNoteName)
    }

    // MARK: - Notes folder

    /// The folder notes live in. Resolved from a bookmark so a move in the
    /// Finder does not break it; the plain path is a fallback for the case
    /// where the bookmark cannot be resolved any more.
    var notesFolder: URL? {
        get {
            if let bookmark = defaults.data(forKey: Key.notesFolderBookmark),
               let url = FolderAccess.resolve(bookmark: bookmark) {
                return url
            }
            if let path = defaults.string(forKey: Key.notesFolderPath) {
                return URL(filePath: path, directoryHint: .isDirectory)
            }
            return nil
        }
        set {
            guard let newValue else {
                defaults.removeObject(forKey: Key.notesFolderBookmark)
                defaults.removeObject(forKey: Key.notesFolderPath)
                return
            }
            defaults.set(newValue.path(percentEncoded: false), forKey: Key.notesFolderPath)
            defaults.set(try? FolderAccess.makeBookmark(for: newValue), forKey: Key.notesFolderBookmark)
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
