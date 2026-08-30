import AppKit

/// Keeps the history on disk.
///
/// In Application Support, deliberately not in the notes folder: that one stays
/// free of Floty's own files so Obsidian sees nothing but notes. And not in
/// `UserDefaults` either - images do not belong in a preferences file.
@MainActor
final class ClipboardStore {

    enum StoreError: LocalizedError {
        /// See CLAUDE.md rule 6 - tests never touch real user data.
        case realFolderRefusedInTests(URL)

        var errorDescription: String? {
            switch self {
            case .realFolderRefusedInTests(let url):
                "FLOTY_TESTING=1: refusing to use \(url.path(percentEncoded: false))."
            }
        }
    }

    static let thumbnailSide: CGFloat = 44

    let folder: URL
    private let indexURL: URL

    init(folder: URL? = nil) throws {
        let target = folder ?? Self.defaultFolder
        try Self.refuseRealFolderInTests(target)
        self.folder = target
        self.indexURL = target.appending(path: "index.json")
        // Der Ordner entsteht erst beim ersten Schreiben. Wer die Funktion nie
        // einschaltet, findet auch kein leeres Verzeichnis in seinem
        // Benutzerordner vor.
    }

    private func ensureFolder() throws {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    }

    static var defaultFolder: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser.appending(path: "Library/Application Support")
        return base.appending(path: "Floty/Clipboard", directoryHint: .isDirectory)
    }

    static func refuseRealFolderInTests(_ url: URL) throws {
        guard ProcessInfo.processInfo.environment["FLOTY_TESTING"] == "1" else { return }
        let temporary = URL(filePath: NSTemporaryDirectory())
            .resolvingSymlinksInPath().path(percentEncoded: false)
        let target = url.resolvingSymlinksInPath().path(percentEncoded: false)
        guard target.hasPrefix(temporary) else {
            throw StoreError.realFolderRefusedInTests(url)
        }
    }

    // MARK: - Index

    /// A damaged index yields an empty history rather than a crash - a broken
    /// clipboard log must never keep Floty from starting.
    func loadEntries() -> [ClipboardEntry] {
        guard let data = try? Data(contentsOf: indexURL) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([ClipboardEntry].self, from: data)) ?? []
    }

    func save(_ entries: [ClipboardEntry]) throws {
        try ensureFolder()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(entries).write(to: indexURL, options: .atomic)
    }

    // MARK: - Images

    func imageURL(for id: ClipboardEntry.ID) -> URL {
        folder.appending(path: "\(id.uuidString).png")
    }

    func thumbnailURL(for id: ClipboardEntry.ID) -> URL {
        folder.appending(path: "\(id.uuidString)-thumb.png")
    }

    /// Writes the full image and a small copy for the list, so opening the
    /// window does not mean scaling fifty full-size screenshots.
    func writeImage(_ png: Data, for id: ClipboardEntry.ID) throws {
        try ensureFolder()
        try png.write(to: imageURL(for: id), options: .atomic)
        if let thumbnail = Self.thumbnail(from: png) {
            try? thumbnail.write(to: thumbnailURL(for: id), options: .atomic)
        }
    }

    static func thumbnail(from png: Data) -> Data? {
        guard let source = NSImage(data: png) else { return nil }
        let side = thumbnailSide
        let scale = min(side / max(source.size.width, 1), side / max(source.size.height, 1))
        let size = NSSize(width: max(source.size.width * scale, 1),
                          height: max(source.size.height * scale, 1))

        let result = NSImage(size: size)
        result.lockFocus()
        source.draw(in: NSRect(origin: .zero, size: size))
        result.unlockFocus()

        guard let tiff = result.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff) else { return nil }
        return rep.representation(using: .png, properties: [:])
    }

    /// Removing an entry has to take its files along, otherwise the folder
    /// grows unnoticed.
    func deleteFiles(for entries: [ClipboardEntry]) {
        for entry in entries where entry.kind == .image {
            try? FileManager.default.removeItem(at: imageURL(for: entry.id))
            try? FileManager.default.removeItem(at: thumbnailURL(for: entry.id))
        }
    }

    func clear(_ entries: [ClipboardEntry]) {
        deleteFiles(for: entries)
        try? FileManager.default.removeItem(at: indexURL)
    }

    /// What the folder currently occupies - shown in the settings.
    func occupiedBytes() -> Int {
        let contents = (try? FileManager.default.contentsOfDirectory(
            at: folder, includingPropertiesForKeys: [.fileSizeKey])) ?? []
        return contents.reduce(0) { total, url in
            total + ((try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
        }
    }
}
