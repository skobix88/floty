import Foundation
import Testing
@testable import Floty

@Suite("Aktiver Tab nach dem Löschen")
struct ActiveNoteTests {

    @Test("Eine Notiz im Hintergrund zu löschen verschiebt den Nutzer nicht")
    func keepsCurrent() {
        let result = ActiveNote.afterDeletion(of: "B", at: 1, remaining: ["A", "C"], current: "C")
        #expect(result == "C")
    }

    @Test("Wird der aktive Tab gelöscht, rückt der Nachbar nach")
    func neighbourTakesOver() {
        let result = ActiveNote.afterDeletion(of: "B", at: 1, remaining: ["A", "C"], current: "B")
        #expect(result == "C")
    }

    @Test("War es der letzte Tab, rückt der davor nach")
    func lastOne() {
        let result = ActiveNote.afterDeletion(of: "C", at: 2, remaining: ["A", "B"], current: "C")
        #expect(result == "B")
    }

    @Test("Die letzte Notiz zu löschen lässt nichts aktiv")
    func nothingLeft() {
        #expect(ActiveNote.afterDeletion(of: "A", at: 0, remaining: [], current: "A") == nil)
    }

    @Test("Ein aktiver Tab, den es nicht mehr gibt, wird ersetzt")
    func staleCurrent() {
        let result = ActiveNote.afterDeletion(of: "B", at: 1, remaining: ["A"], current: "Verschwunden")
        #expect(result == "A")
    }
}
