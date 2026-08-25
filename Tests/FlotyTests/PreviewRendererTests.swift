import AppKit
import Testing
@testable import Floty

@Suite("Vorschau")
struct PreviewRendererTests {

    private func rendered(_ markdown: String) -> NSAttributedString {
        PreviewRenderer.render(markdown)
    }

    @Test("Inline-Marker verschwinden, der Text bleibt")
    func stripsInlineMarkers() {
        #expect(rendered("**fett** und *kursiv*").string == "fett und kursiv")
        #expect(rendered("~~weg~~").string == "weg")
        #expect(rendered("`code`").string == "code")
    }

    @Test("Formatierung wird trotzdem angewandt")
    func stillFormats() {
        let bold = rendered("**fett**")
        let font = bold.attribute(.font, at: 0, effectiveRange: nil) as? NSFont
        #expect(font?.fontDescriptor.symbolicTraits.contains(.bold) == true)
    }

    @Test("Überschriften verlieren die Rauten")
    func headings() {
        let result = rendered("## Titel")
        #expect(result.string == "Titel")
        let font = result.attribute(.font, at: 0, effectiveRange: nil) as? NSFont
        #expect((font?.pointSize ?? 0) > EditorTheme.standard.baseSize)
    }

    @Test("Aufgaben werden zu Kästchen, erledigte durchgestrichen")
    func tasks() {
        #expect(rendered("- [ ] Milch").string == "\u{2610} Milch")
        let done = rendered("- [x] Milch")
        #expect(done.string == "\u{2611} Milch")
        #expect(done.attribute(.strikethroughStyle, at: 2, effectiveRange: nil) != nil)
    }

    @Test("Aufzählungen bekommen einen Punkt, Nummern bleiben Nummern")
    func lists() {
        #expect(rendered("- Milch").string == "\u{2022} Milch")
        #expect(rendered("3. Milch").string == "3. Milch")
    }

    @Test("Mehrere Zeilen bleiben mehrere Zeilen")
    func multipleLines() {
        #expect(rendered("# Titel\n- [ ] Milch\nText").string == "Titel\n\u{2610} Milch\nText")
    }

    @Test("Formatierung innerhalb einer Aufgabe überlebt beide Umbauten")
    func formattingInsideTask() {
        #expect(rendered("- [ ] **Milch** holen").string == "\u{2610} Milch holen")
    }

    @Test("Unvollständige Marker bleiben unverändert stehen")
    func incompleteMarkers() {
        #expect(rendered("**offen").string == "**offen")
    }

    @Test("Leerer Text ergibt leere Vorschau")
    func empty() {
        #expect(rendered("").string == "")
    }
}
