import AppKit

/// Hands a note over to Obsidian: capture here, file it there.
///
/// The note is written into a folder inside the vault and then opened through
/// `obsidian://`. Writing the file rather than stuffing the text into the URL
/// keeps long notes and special characters intact, and works even when Obsidian
/// is not running. The URL scheme is a local hand-off, not a network call.
enum ObsidianBridge {

    enum HandoverError: LocalizedError {
        case noVaultFolder

        var errorDescription: String? {
            switch self {
            case .noVaultFolder:
                String(localized: "Es ist noch kein Obsidian-Vault gewählt. Das steht in den Einstellungen unter „Ablage“.")
            }
        }
    }

    /// Never overwrite something already in the vault - that folder belongs to
    /// the user's permanent notes, not to Floty.
    static func uniqueFileName(for name: String, existing: Set<String>) -> String {
        let base = NoteFile.sanitized(name: name) ?? "Floty"
        var candidate = "\(base).\(NoteFile.fileExtension)"
        var index = 2
        while existing.contains(candidate) {
            candidate = "\(base) \(index).\(NoteFile.fileExtension)"
            index += 1
        }
        return candidate
    }

    static func openURL(for file: URL) -> URL? {
        var components = URLComponents()
        components.scheme = "obsidian"
        components.host = "open"
        components.queryItems = [URLQueryItem(name: "path", value: file.path(percentEncoded: false))]
        return components.url
    }

    @discardableResult
    static func handOver(text: String, named name: String, to vault: URL?) throws -> URL {
        guard let vault else { throw HandoverError.noVaultFolder }
        try FileManager.default.createDirectory(at: vault, withIntermediateDirectories: true)

        let existing = Set((try? FileManager.default.contentsOfDirectory(
            atPath: vault.path(percentEncoded: false))) ?? [])
        let target = vault.appending(path: uniqueFileName(for: name, existing: existing))

        try Data(text.utf8).write(to: target, options: .atomic)
        if let url = openURL(for: target) {
            NSWorkspace.shared.open(url)
        }
        return target
    }
}
