import Foundation
import Testing
@testable import Floty

@Suite("Zeilen-Parser")
struct MarkdownLineTests {

    @Test("Aufzählung wird erkannt")
    func bullet() {
        let line = MarkdownLine.parse("- Milch")
        #expect(line.kind == .bullet(marker: "-"))
        #expect(line.prefixLength == 2)
        #expect(line.content == "Milch")
        #expect(line.continuationPrefix == "- ")
    }

    @Test("Nummerierte Liste zählt hoch")
    func ordered() {
        let line = MarkdownLine.parse("3. Dritter Punkt")
        #expect(line.kind == .ordered(number: 3, delimiter: "."))
        #expect(line.continuationPrefix == "4. ")
    }

    @Test("Einrückung bleibt in der Fortsetzung erhalten")
    func indentedOrdered() {
        let line = MarkdownLine.parse("    2) x")
        #expect(line.continuationPrefix == "    3) ")
    }

    @Test("Offene und erledigte Aufgabe")
    func tasks() {
        let open = MarkdownLine.parse("- [ ] Aufgabe")
        #expect(open.kind == .task(bullet: "-", done: false))
        #expect(open.prefixLength == 6)
        #expect(open.boxRange == NSRange(location: 2, length: 3))
        #expect(open.continuationPrefix == "- [ ] ")

        let done = MarkdownLine.parse("- [x] Aufgabe")
        #expect(done.kind == .task(bullet: "-", done: true))
        // Eine erledigte Aufgabe setzt sich als offene fort, nicht als erledigte.
        #expect(done.continuationPrefix == "- [ ] ")
    }

    @Test("Großes X zählt ebenfalls als erledigt")
    func upperCaseX() {
        #expect(MarkdownLine.parse("- [X] a").kind == .task(bullet: "-", done: true))
    }

    @Test("Unvollständige Marker bleiben normaler Text")
    func notMarkers() {
        #expect(MarkdownLine.parse("-Milch").kind == .plain)
        #expect(MarkdownLine.parse("1.Punkt").kind == .plain)
        #expect(MarkdownLine.parse("").kind == .plain)
        #expect(MarkdownLine.parse("- [y] a").kind == .bullet(marker: "-"))
    }

    @Test("Leeres Listenelement wird als solches erkannt")
    func emptyItems() {
        #expect(MarkdownLine.parse("- ").isEmptyItem)
        #expect(MarkdownLine.parse("- [ ] ").isEmptyItem)
        #expect(MarkdownLine.parse("7. ").isEmptyItem)
        #expect(MarkdownLine.parse("- x").isEmptyItem == false)
    }
}
