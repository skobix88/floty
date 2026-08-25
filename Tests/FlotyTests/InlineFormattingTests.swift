import Foundation
import Testing
@testable import Floty

@Suite("Schnellformatierung")
struct InlineFormattingTests {

    @Test("Auswahl wird eingefasst")
    func wraps() {
        let edit = InlineFormatting.apply(.bold, to: "Milch kaufen", selection: NSRange(location: 0, length: 5))
        #expect(edit.replacement == "**Milch**")
        #expect(edit.selection == NSRange(location: 2, length: 5))
    }

    @Test("Ohne Auswahl landet der Cursor zwischen den Markern")
    func emptySelection() {
        let edit = InlineFormatting.apply(.italic, to: "", selection: NSRange(location: 0, length: 0))
        #expect(edit.replacement == "**")
        #expect(edit.selection == NSRange(location: 1, length: 0))
    }

    @Test("Erneutes Anwenden entfernt die Marker wieder")
    func unwrapsInsideSelection() {
        let text = "**Milch**"
        let edit = InlineFormatting.apply(.bold, to: text, selection: NSRange(location: 0, length: 9))
        #expect(edit.replacement == "Milch")
    }

    @Test("Marker außerhalb der Auswahl werden ebenfalls entfernt")
    func unwrapsOutsideSelection() {
        let text = "~~Milch~~"
        let edit = InlineFormatting.apply(.strikethrough, to: text, selection: NSRange(location: 2, length: 5))
        #expect(edit.range == NSRange(location: 0, length: 9))
        #expect(edit.replacement == "Milch")
    }

    @Test("Zeilen werden zu Aufgaben und wieder zurück")
    func toggleTaskLines() {
        let text = "Milch\nButter"
        let toTasks = InlineFormatting.toggleTaskLines(in: text, selection: NSRange(location: 0, length: 12))
        #expect(toTasks.replacement == "- [ ] Milch\n- [ ] Butter")

        let back = InlineFormatting.toggleTaskLines(in: toTasks.replacement,
                                                    selection: NSRange(location: 0, length: (toTasks.replacement as NSString).length))
        #expect(back.replacement == "Milch\nButter")
    }

    @Test("Gemischte Auswahl macht alles zur Aufgabe")
    func mixedSelection() {
        let text = "- [ ] Milch\nButter"
        let edit = InlineFormatting.toggleTaskLines(in: text, selection: NSRange(location: 0, length: 18))
        #expect(edit.replacement == "- [ ] Milch\n- [ ] Butter")
    }
}
