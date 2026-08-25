import Foundation
import Testing
@testable import Floty

@Suite("Notizablage")
@MainActor
struct NoteStoreTests {

    /// Jeder Test bekommt einen eigenen Ordner unterhalb des Temp-Verzeichnisses.
    private func makeStore() throws -> NoteStore {
        let folder = URL(filePath: NSTemporaryDirectory())
            .appending(path: "FlotyTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        return try NoteStore(folder: folder)
    }

    @Test("Der echte Notizordner wird unter FLOTY_TESTING abgelehnt")
    func refusesRealFolder() {
        #expect(NoteStore.isTesting, "Das Testschema muss FLOTY_TESTING=1 setzen.")
        let home = FileManager.default.homeDirectoryForCurrentUser.appending(path: "Documents/Floty")
        #expect(throws: NoteStore.StoreError.self) {
            try NoteStore.refuseRealFolderInTests(home)
        }
        #expect(throws: Never.self) {
            try NoteStore.refuseRealFolderInTests(URL(filePath: NSTemporaryDirectory()).appending(path: "x"))
        }
    }

    @Test("Anlegen, schreiben, wieder einlesen")
    func writeAndRead() throws {
        let store = try makeStore()
        let note = try store.addNote(named: "Notiz")
        store.setText("- [ ] Milch", for: note.id)
        store.save(note.id)

        let onDisk = try String(contentsOf: note.url, encoding: .utf8)
        #expect(onDisk == "- [ ] Milch")

        let reopened = try NoteStore(folder: store.folder)
        #expect(reopened.notes.map(\.name) == ["Notiz"])
        #expect(reopened.text(for: reopened.notes[0].id) == "- [ ] Milch")
    }

    @Test("Eine unveränderte Notiz wird nicht neu geschrieben")
    func untouchedFileKeepsItsTimestamp() throws {
        let store = try makeStore()
        let note = try store.addNote(named: "Ruhig")
        store.setText("Inhalt", for: note.id)
        store.save(note.id)

        let attributes = try FileManager.default.attributesOfItem(atPath: note.url.path(percentEncoded: false))
        let firstWrite = attributes[.modificationDate] as? Date

        store.setText("Inhalt", for: note.id)
        store.save(note.id)

        let after = try FileManager.default.attributesOfItem(atPath: note.url.path(percentEncoded: false))
        #expect(after[.modificationDate] as? Date == firstWrite)
    }

    @Test("Umbenennen benennt die Datei um")
    func rename() throws {
        let store = try makeStore()
        let note = try store.addNote(named: "Alt")
        store.setText("Text", for: note.id)
        let renamed = try store.rename(note.id, to: "Neu")

        #expect(renamed.name == "Neu")
        #expect(FileManager.default.fileExists(atPath: renamed.url.path(percentEncoded: false)))
        #expect(!FileManager.default.fileExists(atPath: note.url.path(percentEncoded: false)))
        #expect(store.text(for: note.id) == "Text")
    }

    @Test("Doppelte Namen und unbrauchbare Namen werden abgelehnt")
    func nameConflicts() throws {
        let store = try makeStore()
        try store.addNote(named: "Einkauf")
        #expect(throws: NoteStore.StoreError.self) { try store.addNote(named: "Einkauf") }
        #expect(throws: NoteStore.StoreError.self) { try store.addNote(named: "   ") }
    }

    @Test("Schrägstriche im Namen werden ersetzt statt Ordner anzulegen")
    func sanitizesNames() throws {
        let store = try makeStore()
        let note = try store.addNote(named: "Mo/Di")
        #expect(note.name == "Mo-Di")
        #expect(note.url.deletingLastPathComponent() == store.folder)
    }

    @Test("Löschen heißt Papierkorb, nicht Vernichten")
    func deleteMovesToTrash() throws {
        let store = try makeStore()
        let note = try store.addNote(named: "Weg")
        try store.moveToTrash(note.id)
        #expect(store.notes.isEmpty)
        #expect(!FileManager.default.fileExists(atPath: note.url.path(percentEncoded: false)))
    }

    @Test("Eine von außen dazugelegte Datei wird ein weiterer Tab")
    func picksUpForeignFile() throws {
        let store = try makeStore()
        try store.addNote(named: "Eigen")
        let foreign = store.folder.appending(path: "VomZweitenMac.md")
        try "Hallo".write(to: foreign, atomically: true, encoding: .utf8)

        store.reloadFromDisk()
        #expect(store.notes.map(\.name).sorted() == ["Eigen", "VomZweitenMac"])
    }

    @Test("Andere Dateitypen im Ordner werden ignoriert")
    func ignoresNonMarkdown() throws {
        let store = try makeStore()
        try "x".write(to: store.folder.appending(path: "notiz.txt"), atomically: true, encoding: .utf8)
        store.reloadFromDisk()
        #expect(store.notes.isEmpty)
    }
}
