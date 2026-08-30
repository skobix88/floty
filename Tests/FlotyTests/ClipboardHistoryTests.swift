import Foundation
import Testing
@testable import Floty

@Suite("Zwischenablage – Namen")
struct ClipboardEntryNameTests {

    @Test("Der Name ist die erste Zeile, die etwas enthält")
    func firstMeaningfulLine() {
        #expect(ClipboardEntry.name(for: "Hallo Welt") == "Hallo Welt")
        #expect(ClipboardEntry.name(for: "\n\n   \nHallo Welt\nzweite Zeile") == "Hallo Welt")
    }

    @Test("Leerraum wird zusammengezogen")
    func collapsesWhitespace() {
        #expect(ClipboardEntry.name(for: "    let   x =\t42") == "let x = 42")
    }

    @Test("Lange Zeilen werden gekürzt")
    func shortens() {
        let long = String(repeating: "a", count: 200)
        let name = ClipboardEntry.name(for: long)
        #expect(name.count == ClipboardEntry.nameLimit)
        #expect(name.hasSuffix("…"))
    }

    @Test("Leerer Text bekommt trotzdem einen Namen")
    func emptyText() {
        #expect(!ClipboardEntry.name(for: "").isEmpty)
        #expect(!ClipboardEntry.name(for: "   \n  \t ").isEmpty)
    }

    @Test("Bilder heißen nach ihren Maßen")
    func imageName() {
        #expect(ClipboardEntry.name(forImageWidth: 1920, height: 1080).contains("1920"))
        #expect(ClipboardEntry.name(forImageWidth: 1920, height: 1080).contains("1080"))
    }

    @Test("Gleicher Inhalt ergibt denselben Fingerabdruck, anderer nicht")
    func fingerprints() {
        #expect(ClipboardEntry.text("Hallo").fingerprint == ClipboardEntry.text("Hallo").fingerprint)
        #expect(ClipboardEntry.text("Hallo").fingerprint != ClipboardEntry.text("Hallo!").fingerprint)
    }
}

@Suite("Zwischenablage – Verlauf")
struct ClipboardHistoryTests {

    private let limits = ClipboardHistory.Limits(maxCount: 3,
                                                 maxTotalBytes: 100,
                                                 maxItemBytes: 40)

    @Test("Neues steht oben")
    func newestFirst() {
        var history = ClipboardHistory()
        history.insert(ClipboardEntry.text("eins"), limits: limits)
        history.insert(ClipboardEntry.text("zwei"), limits: limits)
        #expect(history.entries.map(\.name) == ["zwei", "eins"])
    }

    @Test("Eine Wiederholung wandert nach oben, statt sich zu verdoppeln")
    func duplicatesMoveUp() {
        var history = ClipboardHistory()
        history.insert(ClipboardEntry.text("eins"), limits: limits)
        history.insert(ClipboardEntry.text("zwei"), limits: limits)
        let change = history.insert(ClipboardEntry.text("eins"), limits: limits)

        #expect(history.entries.map(\.name) == ["eins", "zwei"])
        #expect(history.entries.count == 2)
        // Der alte Eintrag muss gemeldet werden, damit seine Bilddatei mitgeht.
        #expect(change.dropped.count == 1)
    }

    @Test("Die Anzahl begrenzt den Verlauf")
    func countLimit() {
        var history = ClipboardHistory()
        for index in 1...5 {
            history.insert(ClipboardEntry.text("Eintrag \(index)"), limits: limits)
        }
        #expect(history.entries.count == 3)
        #expect(history.entries.first?.name == "Eintrag 5")
    }

    @Test("Die Gesamtgröße begrenzt ebenfalls")
    func sizeLimit() {
        var history = ClipboardHistory()
        let big = ClipboardEntry.image(data: Data(repeating: 0, count: 39), width: 10, height: 10)
        let big2 = ClipboardEntry.image(data: Data(repeating: 1, count: 39), width: 10, height: 10)
        let big3 = ClipboardEntry.image(data: Data(repeating: 2, count: 39), width: 10, height: 10)
        history.insert(big, limits: limits)
        history.insert(big2, limits: limits)
        let change = history.insert(big3, limits: limits)

        // 3 × 39 = 117 > 100, der älteste fällt heraus.
        #expect(history.entries.count == 2)
        #expect(history.totalBytes <= limits.maxTotalBytes)
        #expect(change.dropped.count == 1)
    }

    @Test("Ein einzelnes zu großes Objekt wird gar nicht erst aufgenommen")
    func oversizedRefused() {
        var history = ClipboardHistory()
        let huge = ClipboardEntry.image(data: Data(repeating: 0, count: 41), width: 4000, height: 4000)
        let change = history.insert(huge, limits: limits)

        #expect(change.accepted == false)
        #expect(history.entries.isEmpty)
    }

    @Test("Löschen entfernt genau einen Eintrag")
    func remove() {
        var history = ClipboardHistory()
        history.insert(ClipboardEntry.text("eins"), limits: limits)
        history.insert(ClipboardEntry.text("zwei"), limits: limits)
        let removed = history.remove(history.entries[0].id)

        #expect(removed?.name == "zwei")
        #expect(history.entries.map(\.name) == ["eins"])
        #expect(history.remove(UUID()) == nil)
    }

    @Test("Leeren gibt alles zurück, damit die Dateien mitgehen")
    func removeAll() {
        var history = ClipboardHistory()
        history.insert(ClipboardEntry.text("eins"), limits: limits)
        history.insert(ClipboardEntry.text("zwei"), limits: limits)
        let removed = history.removeAll()

        #expect(removed.count == 2)
        #expect(history.entries.isEmpty)
    }

    @Test("Die Suche greift auf Name und Inhalt, ohne auf Schreibweise zu achten")
    func search() {
        var history = ClipboardHistory()
        history.insert(ClipboardEntry.text("Einkaufsliste\nMilch und Butter"), limits: limits)
        history.insert(ClipboardEntry.text("Telefonnummer"), limits: limits)

        #expect(history.filtered(by: "einkauf").count == 1)
        #expect(history.filtered(by: "MILCH").count == 1, "Inhalt muss mitdurchsucht werden")
        #expect(history.filtered(by: "  ").count == 2, "leere Suche zeigt alles")
        #expect(history.filtered(by: "kommtnichtvor").isEmpty)
    }
}

@Suite("Zwischenablage – was aufgenommen werden darf")
struct PasteboardPolicyTests {

    @Test("Gewöhnlicher Text wird aufgenommen")
    func plainText() {
        #expect(PasteboardPolicy.shouldRecord(types: ["public.utf8-plain-text"],
                                              source: "com.apple.Safari",
                                              excludedApps: []))
    }

    @Test("Als verborgen markierte Inhalte werden abgelehnt")
    func concealed() {
        for marker in PasteboardPolicy.refusedTypes {
            #expect(!PasteboardPolicy.shouldRecord(types: ["public.utf8-plain-text", marker],
                                                   source: "com.agilebits.onepassword7",
                                                   excludedApps: []),
                    "\(marker) hätte abgelehnt werden müssen")
        }
    }

    @Test("Programme auf der Ausschlussliste werden übergangen")
    func excludedApp() {
        #expect(!PasteboardPolicy.shouldRecord(types: ["public.utf8-plain-text"],
                                               source: "com.apple.Terminal",
                                               excludedApps: ["com.apple.Terminal"]))
        #expect(PasteboardPolicy.shouldRecord(types: ["public.utf8-plain-text"],
                                              source: "com.apple.Safari",
                                              excludedApps: ["com.apple.Terminal"]))
    }

    @Test("Ohne erkennbare Quelle wird aufgenommen statt verworfen")
    func unknownSource() {
        // macOS verrät nicht zuverlässig, wer kopiert hat. Im Zweifel aufnehmen,
        // sonst fehlten Einträge ohne erkennbaren Grund.
        #expect(PasteboardPolicy.shouldRecord(types: ["public.utf8-plain-text"],
                                              source: nil,
                                              excludedApps: ["com.apple.Terminal"]))
    }
}
