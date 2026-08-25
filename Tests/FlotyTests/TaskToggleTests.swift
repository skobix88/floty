import Foundation
import Testing
@testable import Floty

@Suite("Checkboxen umschalten")
struct TaskToggleTests {

    @Test("Offen wird erledigt und zurück")
    func toggles() {
        let open = "- [ ] Aufgabe"
        let toDone = TaskToggle.edit(in: open, at: 3)
        #expect(toDone?.replacement == "[x]")
        #expect(toDone?.range == NSRange(location: 2, length: 3))

        let done = "- [x] Aufgabe"
        #expect(TaskToggle.edit(in: done, at: 3)?.replacement == "[ ]")
    }

    @Test("Zeile ohne Checkbox bleibt unangetastet")
    func noTask() {
        #expect(TaskToggle.edit(in: "einfach Text", at: 2) == nil)
    }

    @Test("Umschalten trifft die richtige Zeile")
    func secondLine() {
        let text = "- [ ] eins\n- [ ] zwei"
        let edit = TaskToggle.edit(in: text, at: 14)
        #expect(edit?.range == NSRange(location: 13, length: 3))
    }

    @Test("Durchgestrichen wird nur der Text hinter dem Marker")
    func strikethroughRange() {
        let line = MarkdownLine.parse("- [x] Aufgabe")
        let range = TaskToggle.struckThroughRange(of: line, lineStart: 0, lineLength: 13)
        #expect(range == NSRange(location: 6, length: 7))
    }

    @Test("Offene Aufgabe wird nicht durchgestrichen")
    func openTaskNotStruck() {
        let line = MarkdownLine.parse("- [ ] Aufgabe")
        #expect(TaskToggle.struckThroughRange(of: line, lineStart: 0, lineLength: 13) == nil)
    }
}
