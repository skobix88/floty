import Foundation

/// Finds and remembers the folder the notes live in.
///
/// Floty is not sandboxed, so a bookmark is not strictly required today. It is
/// stored anyway: a later move into the sandbox must not fail on data access,
/// and a bookmark survives the folder being moved or renamed in the Finder.
enum FolderAccess {
    /// `~/Library/Mobile Documents/com~apple~CloudDocs` - iCloud Drive as the
    /// Finder shows it. Reached by path rather than through
    /// `urlForUbiquityContainerIdentifier`, because that needs an iCloud
    /// entitlement and therefore a paid developer account.
    static var iCloudDrive: URL? {
        let url = FileManager.default.homeDirectoryForCurrentUser
            .appending(path: "Library/Mobile Documents/com~apple~CloudDocs", directoryHint: .isDirectory)
        return FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) ? url : nil
    }

    /// Where notes go when the user has not picked a folder yet: a `Floty`
    /// folder in iCloud Drive, or in `~/Documents` if iCloud Drive is off.
    static var suggestedFolder: URL {
        let parent = iCloudDrive ?? FileManager.default.homeDirectoryForCurrentUser
            .appending(path: "Documents", directoryHint: .isDirectory)
        return parent.appending(path: "Floty", directoryHint: .isDirectory)
    }

    static func makeBookmark(for url: URL) throws -> Data {
        try url.bookmarkData(options: .withSecurityScope,
                             includingResourceValuesForKeys: nil,
                             relativeTo: nil)
    }

    /// Resolves a stored bookmark. Returns nil if the folder is gone; the
    /// caller then asks the user for a new one instead of guessing.
    static func resolve(bookmark: Data) -> URL? {
        var isStale = false
        guard let url = try? URL(resolvingBookmarkData: bookmark,
                                 options: .withSecurityScope,
                                 relativeTo: nil,
                                 bookmarkDataIsStale: &isStale) else { return nil }
        return url
    }

    @discardableResult
    static func createIfNeeded(_ url: URL) throws -> URL {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
