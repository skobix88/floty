import AppKit
import UniformTypeIdentifiers

/// "Export as .md" - a save panel, nothing more.
///
/// The notes folder is visible in the Finder anyway, so this is for putting a
/// copy somewhere else, not for getting at the file in the first place.
@MainActor
enum NoteExport {

    /// Returns the written file, or nil when the user cancelled.
    @discardableResult
    static func save(text: String, named name: String) throws -> URL? {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "\(name).\(NoteFile.fileExtension)"
        panel.allowedContentTypes = [UTType(filenameExtension: NoteFile.fileExtension) ?? .plainText]
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false

        guard panel.runModal() == .OK, let url = panel.url else { return nil }
        try Data(text.utf8).write(to: url, options: .atomic)
        return url
    }
}
