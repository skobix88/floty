import AppKit
import Testing
@testable import Floty

@Suite("Zwischenablage – Ablage")
@MainActor
struct ClipboardStoreTests {

    private func makeStore() throws -> ClipboardStore {
        let folder = URL(filePath: NSTemporaryDirectory())
            .appending(path: "FlotyClipboard-\(UUID().uuidString)", directoryHint: .isDirectory)
        return try ClipboardStore(folder: folder)
    }

    private func png(width: Int, height: Int) -> Data {
        let image = NSImage(size: NSSize(width: width, height: height))
        image.lockFocus()
        NSColor.systemBlue.setFill()
        NSRect(x: 0, y: 0, width: width, height: height).fill()
        image.unlockFocus()
        let rep = NSBitmapImageRep(data: image.tiffRepresentation!)!
        return rep.representation(using: .png, properties: [:])!
    }

    @Test("Der echte Ordner wird unter FLOTY_TESTING abgelehnt")
    func refusesRealFolder() {
        #expect(throws: ClipboardStore.StoreError.self) {
            try ClipboardStore.refuseRealFolderInTests(ClipboardStore.defaultFolder)
        }
    }

    @Test("Schreiben und wieder einlesen")
    func roundTrip() throws {
        let store = try makeStore()
        let entries = [ClipboardEntry.text("Hallo"), ClipboardEntry.text("Welt")]
        try store.save(entries)

        let reopened = try ClipboardStore(folder: store.folder)
        #expect(reopened.loadEntries().map(\.name) == ["Hallo", "Welt"])
        #expect(reopened.loadEntries().first?.text == "Hallo")
    }

    @Test("Ein leerer Ordner ergibt einen leeren Verlauf")
    func emptyFolder() throws {
        #expect(try makeStore().loadEntries().isEmpty)
    }

    @Test("Eine kaputte Indexdatei führt zu leerem Verlauf, nicht zum Absturz")
    func brokenIndex() throws {
        let store = try makeStore()
        try FileManager.default.createDirectory(at: store.folder, withIntermediateDirectories: true)
        try Data("das ist kein JSON".utf8)
            .write(to: store.folder.appending(path: "index.json"))
        #expect(store.loadEntries().isEmpty)
    }

    @Test("Ein Bild bekommt Vollbild und Miniatur")
    func writesImageAndThumbnail() throws {
        let store = try makeStore()
        let data = png(width: 400, height: 200)
        let entry = ClipboardEntry.image(data: data, width: 400, height: 200)
        try store.writeImage(data, for: entry.id)

        #expect(FileManager.default.fileExists(atPath: store.imageURL(for: entry.id).path(percentEncoded: false)))
        #expect(FileManager.default.fileExists(atPath: store.thumbnailURL(for: entry.id).path(percentEncoded: false)))

        // Die Miniatur muss deutlich kleiner sein, sonst hätte sie keinen Zweck.
        let thumb = NSImage(contentsOf: store.thumbnailURL(for: entry.id))
        #expect((thumb?.size.width ?? 999) <= ClipboardStore.thumbnailSide)
    }

    @Test("Einen Eintrag zu löschen nimmt Bild und Miniatur mit")
    func deleteTakesFilesAlong() throws {
        let store = try makeStore()
        let data = png(width: 100, height: 100)
        let entry = ClipboardEntry.image(data: data, width: 100, height: 100)
        try store.writeImage(data, for: entry.id)

        store.deleteFiles(for: [entry])

        #expect(!FileManager.default.fileExists(atPath: store.imageURL(for: entry.id).path(percentEncoded: false)))
        #expect(!FileManager.default.fileExists(atPath: store.thumbnailURL(for: entry.id).path(percentEncoded: false)))
    }

    @Test("Leeren entfernt Index und Bilddateien")
    func clearRemovesEverything() throws {
        let store = try makeStore()
        let data = png(width: 50, height: 50)
        let entry = ClipboardEntry.image(data: data, width: 50, height: 50)
        try store.writeImage(data, for: entry.id)
        try store.save([entry])

        store.clear([entry])

        #expect(store.loadEntries().isEmpty)
        #expect(store.occupiedBytes() == 0)
    }

    @Test("Der belegte Platz wächst mit den Bildern")
    func occupiedBytesGrows() throws {
        let store = try makeStore()
        #expect(store.occupiedBytes() == 0)

        let data = png(width: 300, height: 300)
        let entry = ClipboardEntry.image(data: data, width: 300, height: 300)
        try store.writeImage(data, for: entry.id)

        #expect(store.occupiedBytes() >= data.count)
    }
}

@Suite("Zwischenablage – nichts tun, solange nichts passiert")
@MainActor
struct ClipboardStoreIdleTests {

    @Test("Ein Verlauf, der nie beschrieben wird, legt keinen Ordner an")
    func noFolderUntilUsed() throws {
        let folder = URL(filePath: NSTemporaryDirectory())
            .appending(path: "FlotyIdle-\(UUID().uuidString)", directoryHint: .isDirectory)
        let store = try ClipboardStore(folder: folder)

        #expect(!FileManager.default.fileExists(atPath: folder.path(percentEncoded: false)),
                "Ausgeschaltet darf nichts im Benutzerordner entstehen")
        #expect(store.loadEntries().isEmpty)
        #expect(store.occupiedBytes() == 0)

        try store.save([ClipboardEntry.text("jetzt aber")])
        #expect(FileManager.default.fileExists(atPath: folder.path(percentEncoded: false)))
        try? FileManager.default.removeItem(at: folder)
    }
}
