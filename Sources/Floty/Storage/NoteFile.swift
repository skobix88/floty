import Foundation

/// One note: exactly one Markdown file on disk.
/// The tab name is the file name, so the notes folder stays free of metadata
/// and remains usable from Obsidian or any other editor.
struct NoteFile: Identifiable, Hashable, Sendable {
    /// Stable across renames within a session; the URL is not.
    let id: UUID
    var url: URL

    /// File name without the `.md` extension - this is what the tab shows.
    var name: String { url.deletingPathExtension().lastPathComponent }

    init(id: UUID = UUID(), url: URL) {
        self.id = id
        self.url = url
    }
}

extension NoteFile {
    static let fileExtension = "md"

    /// Characters that cannot appear in a file name. `/` is the path separator,
    /// `:` is what the Finder still shows as `/`.
    static let forbiddenNameCharacters = CharacterSet(charactersIn: "/:")

    /// Turns arbitrary user input into a usable file name, or nil if nothing
    /// usable remains.
    static func sanitized(name: String) -> String? {
        let cleaned = name
            .components(separatedBy: forbiddenNameCharacters)
            .joined(separator: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? nil : cleaned
    }
}
