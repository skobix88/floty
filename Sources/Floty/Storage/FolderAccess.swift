import Foundation

/// Finds and remembers the folder the notes live in.
///
/// A bookmark is stored next to the plain path because it survives the folder
/// being moved or renamed in the Finder, which a path does not.
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

    /// Plain bookmarks, deliberately not security scoped.
    ///
    /// `.withSecurityScope` belongs to sandboxed apps. Outside the sandbox
    /// creating one appears to work, but resolving it again fails with
    /// NSCocoaErrorDomain 259 - the folder then silently reads back as "not
    /// chosen". Should Floty ever move into the sandbox, this is the one place
    /// that has to change.
    static func makeBookmark(for url: URL) throws -> Data {
        try url.bookmarkData(options: [],
                             includingResourceValuesForKeys: nil,
                             relativeTo: nil)
    }

    /// Resolves a stored bookmark. Returns nil if the folder is gone; the
    /// caller then asks the user for a new one instead of guessing.
    static func resolve(bookmark: Data) -> URL? {
        var isStale = false
        guard let url = try? URL(resolvingBookmarkData: bookmark,
                                 options: [],
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
