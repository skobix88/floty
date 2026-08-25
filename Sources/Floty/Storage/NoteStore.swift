import Foundation

/// Owns the notes folder: one Markdown file per note, nothing else.
///
/// Writing always goes through `NSFileCoordinator` because the folder normally
/// lives in iCloud Drive and macOS syncs it behind our back. Writes are atomic
/// and debounced, so a burst of keystrokes produces one file version, not fifty.
@MainActor
@Observable
final class NoteStore {

    enum StoreError: LocalizedError {
        /// See CLAUDE.md rule 6: tests never touch the real notes folder.
        case realFolderRefusedInTests(URL)
        case nameUnusable(String)
        case nameTaken(String)

        var errorDescription: String? {
            switch self {
            case .realFolderRefusedInTests(let url):
                "FLOTY_TESTING=1: refusing to use \(url.path(percentEncoded: false)) - tests must run against a temporary folder."
            case .nameUnusable(let name):
                "\"\(name)\" cannot be used as a file name."
            case .nameTaken(let name):
                "A note called \"\(name)\" already exists."
            }
        }
    }

    /// How long typing has to pause before the file is written.
    static let saveDelay: Duration = .milliseconds(500)

    let folder: URL
    private(set) var notes: [NoteFile] = []
    private(set) var lastError: Error?

    /// Text per note, kept in memory while the app runs.
    private var texts: [NoteFile.ID: String] = [:]
    /// What is currently on disk, so an untouched note is never rewritten.
    private var savedTexts: [NoteFile.ID: String] = [:]
    private var saveTasks: [NoteFile.ID: Task<Void, Never>] = [:]

    // MARK: - Setup

    init(folder: URL) throws {
        try Self.refuseRealFolderInTests(folder)
        self.folder = folder
        try FolderAccess.createIfNeeded(folder)
        reloadFromDisk()
    }

    static var isTesting: Bool {
        ProcessInfo.processInfo.environment["FLOTY_TESTING"] == "1"
    }

    /// Under `FLOTY_TESTING=1` only folders below the temporary directory are
    /// accepted. That makes the rule mechanical instead of a promise.
    static func refuseRealFolderInTests(_ url: URL) throws {
        guard isTesting else { return }
        let temporary = URL(filePath: NSTemporaryDirectory())
            .resolvingSymlinksInPath().path(percentEncoded: false)
        let target = url.resolvingSymlinksInPath().path(percentEncoded: false)
        guard target.hasPrefix(temporary) else {
            throw StoreError.realFolderRefusedInTests(url)
        }
    }

    // MARK: - Reading

    /// Picks up notes added by another Mac through iCloud, and the extra file
    /// iCloud Drive leaves behind when it cannot merge a conflict.
    func reloadFromDisk() {
        let found = (try? FileManager.default.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
        )) ?? []

        let markdown = found
            .filter { $0.pathExtension.lowercased() == NoteFile.fileExtension }
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }

        var known = Dictionary(uniqueKeysWithValues: notes.map { ($0.url, $0) })
        notes = markdown.map { url in
            if let existing = known.removeValue(forKey: url) { return existing }
            return NoteFile(url: url)
        }
    }

    func text(for id: NoteFile.ID) -> String {
        if let cached = texts[id] { return cached }
        guard let note = notes.first(where: { $0.id == id }) else { return "" }
        let loaded = read(note.url) ?? ""
        texts[id] = loaded
        savedTexts[id] = loaded
        return loaded
    }

    private func read(_ url: URL) -> String? {
        var coordinatorError: NSError?
        var contents: String?
        NSFileCoordinator().coordinate(readingItemAt: url, options: [], error: &coordinatorError) { target in
            contents = try? String(contentsOf: target, encoding: .utf8)
        }
        return contents
    }

    // MARK: - Writing

    func setText(_ text: String, for id: NoteFile.ID) {
        guard texts[id] != text else { return }
        texts[id] = text
        scheduleSave(id)
    }

    private func scheduleSave(_ id: NoteFile.ID) {
        saveTasks[id]?.cancel()
        saveTasks[id] = Task { [weak self] in
            try? await Task.sleep(for: Self.saveDelay)
            guard !Task.isCancelled else { return }
            self?.save(id)
        }
    }

    /// Writes everything with pending changes. Called when the panel hides and
    /// when the app quits - a scratchpad must never lose the last sentence.
    func flush() {
        for id in texts.keys { save(id) }
    }

    func save(_ id: NoteFile.ID) {
        saveTasks[id]?.cancel()
        saveTasks[id] = nil
        guard let note = notes.first(where: { $0.id == id }),
              let text = texts[id],
              savedTexts[id] != text else { return }

        var coordinatorError: NSError?
        var writeError: Error?
        NSFileCoordinator().coordinate(writingItemAt: note.url, options: .forReplacing, error: &coordinatorError) { target in
            do { try Data(text.utf8).write(to: target, options: .atomic) }
            catch { writeError = error }
        }
        if let error = coordinatorError ?? (writeError as NSError?) {
            lastError = error
            return
        }
        savedTexts[id] = text
    }

    // MARK: - Notes

    @discardableResult
    func addNote(named rawName: String) throws -> NoteFile {
        guard let name = NoteFile.sanitized(name: rawName) else {
            throw StoreError.nameUnusable(rawName)
        }
        let url = folder.appending(path: "\(name).\(NoteFile.fileExtension)")
        guard !FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) else {
            throw StoreError.nameTaken(name)
        }
        try Data().write(to: url, options: .atomic)
        let note = NoteFile(url: url)
        notes.append(note)
        texts[note.id] = ""
        savedTexts[note.id] = ""
        return note
    }

    @discardableResult
    func rename(_ id: NoteFile.ID, to rawName: String) throws -> NoteFile {
        guard let index = notes.firstIndex(where: { $0.id == id }) else {
            throw StoreError.nameUnusable(rawName)
        }
        guard let name = NoteFile.sanitized(name: rawName) else {
            throw StoreError.nameUnusable(rawName)
        }
        let target = folder.appending(path: "\(name).\(NoteFile.fileExtension)")
        guard target != notes[index].url else { return notes[index] }
        guard !FileManager.default.fileExists(atPath: target.path(percentEncoded: false)) else {
            throw StoreError.nameTaken(name)
        }
        save(id)
        try FileManager.default.moveItem(at: notes[index].url, to: target)
        notes[index].url = target
        return notes[index]
    }

    /// Moves the file to the trash. Never `unlink` - see CLAUDE.md rule 1.
    func moveToTrash(_ id: NoteFile.ID) throws {
        guard let index = notes.firstIndex(where: { $0.id == id }) else { return }
        saveTasks[id]?.cancel()
        saveTasks[id] = nil
        try FileManager.default.trashItem(at: notes[index].url, resultingItemURL: nil)
        notes.remove(at: index)
        texts[id] = nil
        savedTexts[id] = nil
    }
}
