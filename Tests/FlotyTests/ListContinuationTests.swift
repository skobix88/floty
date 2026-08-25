import Foundation
import Testing
@testable import Floty

@Suite("Enter in Listen")
struct ListContinuationTests {

    private func result(_ text: String, caret: Int) -> ListContinuation.Edit? {
        ListContinuation.onReturn(in: text, selection: NSRange(location: caret, length: 0))
    }

    @Test("Nummerierte Liste wird fortgesetzt")
    func continuesOrdered() {
        let text = "3. Dritter"
        let edit = result(text, caret: text.utf16.count)
        #expect(edit?.replacement == "\n4. ")
    }

    @Test("Checkbox-Liste wird fortgesetzt")
    func continuesTask() {
        let text = "- [x] erledigt"
        let edit = result(text, caret: text.utf16.count)
        #expect(edit?.replacement == "\n- [ ] ")
    }

    @Test("Enter auf leerem Listenelement beendet die Liste")
    func endsList() {
        let text = "- [ ] "
        let edit = result(text, caret: text.utf16.count)
        #expect(edit?.replacement == "")
        #expect(edit?.range == NSRange(location: 0, length: 6))
    }

    @Test("Normaler Text bekommt normales Enter")
    func plainText() {
        #expect(result("nur Text", caret: 8) == nil)
    }

    @Test("Enter mitten in der Zeile dupliziert den Marker nicht")
    func caretInsideLine() {
        #expect(result("- Milch und Butter", caret: 7) == nil)
    }

    @Test("Fortsetzung in der zweiten Zeile nutzt deren Marker")
    func secondLine() {
        let text = "Einkauf\n- Milch"
        let edit = result(text, caret: text.utf16.count)
        #expect(edit?.replacement == "\n- ")
    }
}
