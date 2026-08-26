import AppKit
import Testing
@testable import Floty

@Suite("Ordner merken")
struct FolderAccessTests {

    /// Der Fehler, den es hier zu verhindern gilt: ein Lesezeichen ließ sich
    /// anlegen, aber nicht wieder auflösen (NSCocoaErrorDomain 259), weil es
    /// mit `.withSecurityScope` erzeugt wurde. Der Ordner las sich danach als
    /// „nicht gewählt" zurück.
    @Test("Ein Lesezeichen lässt sich anlegen und wieder auflösen")
    func roundTrip() throws {
        let folder = URL(filePath: NSTemporaryDirectory())
            .appending(path: "FlotyBookmark-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FolderAccess.createIfNeeded(folder)
        defer { try? FileManager.default.removeItem(at: folder) }

        let bookmark = try FolderAccess.makeBookmark(for: folder)
        let resolved = FolderAccess.resolve(bookmark: bookmark)

        #expect(resolved?.resolvingSymlinksInPath() == folder.resolvingSymlinksInPath())
    }

    @Test("Ein Lesezeichen überlebt das Umbenennen des Ordners")
    func survivesRename() throws {
        let parent = URL(filePath: NSTemporaryDirectory())
            .appending(path: "FlotyBookmark-\(UUID().uuidString)", directoryHint: .isDirectory)
        let before = parent.appending(path: "Vorher", directoryHint: .isDirectory)
        let after = parent.appending(path: "Nachher", directoryHint: .isDirectory)
        try FolderAccess.createIfNeeded(before)
        defer { try? FileManager.default.removeItem(at: parent) }

        let bookmark = try FolderAccess.makeBookmark(for: before)
        try FileManager.default.moveItem(at: before, to: after)

        #expect(FolderAccess.resolve(bookmark: bookmark)?.lastPathComponent == "Nachher")
    }

    @Test("Kaputte Daten ergeben nil statt eines Absturzes")
    func rejectsGarbage() {
        #expect(FolderAccess.resolve(bookmark: Data([0x00, 0x01, 0x02])) == nil)
    }

    @Test("Das Menüleisten-Symbol liegt im Bündel und ist eine Schablone")
    func menuBarIconExists() {
        let icon = NSImage(named: "MenuBarIcon")
        #expect(icon != nil, "MenuBarIcon fehlt im Asset-Katalog")
        #expect(icon?.isTemplate == true, "muss Schablone sein, sonst ignoriert es Hell/Dunkel")
    }
}
