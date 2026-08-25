import Foundation
import Testing
@testable import Floty

@Suite("Tab-Reihenfolge")
struct NoteOrderTests {

    private func notes(_ names: [String]) -> [NoteFile] {
        names.map { NoteFile(url: URL(filePath: "/tmp/\($0).md")) }
    }

    @Test("Die gemerkte Reihenfolge gewinnt")
    func honoursPreferred() {
        let arranged = NoteOrder.arrange(notes(["A", "B", "C"]), preferring: ["C", "A", "B"])
        #expect(arranged.map(\.name) == ["C", "A", "B"])
    }

    @Test("Unbekannte Notizen hängen sich hinten an, alphabetisch")
    func unknownGoLast() {
        let arranged = NoteOrder.arrange(notes(["Zebra", "B", "Anton"]), preferring: ["B"])
        #expect(arranged.map(\.name) == ["B", "Anton", "Zebra"])
    }

    @Test("Namen in der Reihenfolge, die es nicht mehr gibt, stören nicht")
    func staleNamesIgnored() {
        let arranged = NoteOrder.arrange(notes(["A", "B"]), preferring: ["Weg", "B", "Auch weg", "A"])
        #expect(arranged.map(\.name) == ["B", "A"])
    }

    @Test("Ohne gemerkte Reihenfolge wird natürlich sortiert")
    func naturalSort() {
        let arranged = NoteOrder.arrange(notes(["Notiz 10", "Notiz 2"]), preferring: [])
        #expect(arranged.map(\.name) == ["Notiz 2", "Notiz 10"])
    }

    @Test("Verschieben nach links und rechts")
    func moving() {
        #expect(NoteOrder.moving(["A", "B", "C"], name: "C", by: -1) == ["A", "C", "B"])
        #expect(NoteOrder.moving(["A", "B", "C"], name: "A", by: 1) == ["B", "A", "C"])
    }

    @Test("An den Enden passiert nichts")
    func clampedAtEnds() {
        #expect(NoteOrder.moving(["A", "B"], name: "A", by: -1) == ["A", "B"])
        #expect(NoteOrder.moving(["A", "B"], name: "B", by: 1) == ["A", "B"])
        #expect(NoteOrder.moving(["A", "B"], name: "Unbekannt", by: 1) == ["A", "B"])
    }
}
