import Foundation
import Testing
@testable import Floty

@Suite("Obsidian-Übergabe")
struct ObsidianBridgeTests {

    @Test("Ein freier Name wird unverändert genommen")
    func plainName() {
        #expect(ObsidianBridge.uniqueFileName(for: "Einkauf", existing: []) == "Einkauf.md")
    }

    @Test("Eine vorhandene Vault-Notiz wird nie überschrieben")
    func neverOverwrites() {
        let existing: Set<String> = ["Einkauf.md"]
        #expect(ObsidianBridge.uniqueFileName(for: "Einkauf", existing: existing) == "Einkauf 2.md")
    }

    @Test("Mehrfache Übergabe zählt weiter hoch")
    func countsUp() {
        let existing: Set<String> = ["Einkauf.md", "Einkauf 2.md", "Einkauf 3.md"]
        #expect(ObsidianBridge.uniqueFileName(for: "Einkauf", existing: existing) == "Einkauf 4.md")
    }

    @Test("Schrägstriche im Namen legen keine Unterordner an")
    func sanitizes() {
        #expect(ObsidianBridge.uniqueFileName(for: "Mo/Di", existing: []) == "Mo-Di.md")
    }

    @Test("Ein unbrauchbarer Name fällt auf Floty zurück")
    func fallbackName() {
        #expect(ObsidianBridge.uniqueFileName(for: "   ", existing: []) == "Floty.md")
    }

    @Test("Die URL trägt den vollständigen Pfad und ist korrekt kodiert")
    func openURL() {
        let file = URL(filePath: "/Users/x/Vault/Mein Einkauf.md")
        let url = ObsidianBridge.openURL(for: file)
        #expect(url?.scheme == "obsidian")
        #expect(url?.host == "open")
        #expect(url?.absoluteString.contains("Mein%20Einkauf.md") == true)
    }

    @Test("Ohne gewählten Vault wird nichts geschrieben, sondern gemeldet")
    func refusesWithoutVault() {
        #expect(throws: ObsidianBridge.HandoverError.self) {
            try ObsidianBridge.handOver(text: "x", named: "y", to: nil)
        }
    }

    @Test("Die Notiz landet im Vault, mit unverändertem Inhalt")
    func writesIntoVault() throws {
        let vault = URL(filePath: NSTemporaryDirectory())
            .appending(path: "FlotyVault-\(UUID().uuidString)", directoryHint: .isDirectory)
        let written = try ObsidianBridge.handOver(text: "- [ ] Milch", named: "Einkauf", to: vault)

        #expect(written.lastPathComponent == "Einkauf.md")
        #expect(try String(contentsOf: written, encoding: .utf8) == "- [ ] Milch")

        // Ein zweites Mal darf die erste Datei nicht anfassen.
        let second = try ObsidianBridge.handOver(text: "anderer Text", named: "Einkauf", to: vault)
        #expect(second.lastPathComponent == "Einkauf 2.md")
        #expect(try String(contentsOf: written, encoding: .utf8) == "- [ ] Milch")

        try? FileManager.default.removeItem(at: vault)
    }
}
