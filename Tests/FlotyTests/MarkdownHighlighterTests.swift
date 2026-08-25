import AppKit
import Testing
@testable import Floty

@Suite("Hervorhebung")
struct MarkdownHighlighterTests {

    private func styled(_ raw: String) -> NSAttributedString {
        MarkdownHighlighter.styled(NSAttributedString(string: raw))
    }

    @Test("Die Länge bleibt gleich – sonst verrutscht die Auswahl")
    func lengthIsPreserved() {
        for raw in ["- [ ] Aufgabe", "- [x] erledigt", "# Titel", "**fett** und *kursiv*",
                    "~~weg~~", "`code`", "", "   - [ ] eingerückt", "**offen"] {
            #expect(styled(raw).length == (raw as NSString).length, "\(raw)")
        }
    }

    @Test("Checkbox wird als Kästchen gezeichnet, nicht gespeichert")
    func checkboxIsDrawn() {
        #expect(styled("- [ ] Aufgabe").string == "  \u{2610}   Aufgabe")
        #expect(styled("- [x] Aufgabe").string == "  \u{2611}   Aufgabe")
    }

    @Test("Erledigte Aufgabe wird durchgestrichen, offene nicht")
    func strikethrough() {
        let done = styled("- [x] Aufgabe")
        let attributes = done.attributes(at: 8, effectiveRange: nil)
        #expect(attributes[.strikethroughStyle] as? Int == NSUnderlineStyle.single.rawValue)

        let open = styled("- [ ] Aufgabe")
        #expect(open.attributes(at: 8, effectiveRange: nil)[.strikethroughStyle] == nil)
    }

    @Test("Fett und kursiv setzen echte Schriftschnitte")
    func emphasis() {
        let bold = styled("**fett**")
        let boldFont = bold.attribute(.font, at: 3, effectiveRange: nil) as? NSFont
        #expect(boldFont?.fontDescriptor.symbolicTraits.contains(.bold) == true)

        let italic = styled("*kursiv*")
        let italicFont = italic.attribute(.font, at: 3, effectiveRange: nil) as? NSFont
        #expect(italicFont?.fontDescriptor.symbolicTraits.contains(.italic) == true)
    }

    @Test("Marker bleiben im Text stehen, nur blasser")
    func markersStayVisible() {
        let result = styled("**fett**")
        #expect(result.string == "**fett**")
        let markerColor = result.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? NSColor
        let textColor = result.attribute(.foregroundColor, at: 3, effectiveRange: nil) as? NSColor
        #expect(markerColor != textColor)
    }

    @Test("Unvollständige Marker stürzen nicht ab und formatieren nicht")
    func incompleteMarkers() {
        let result = styled("**offen")
        #expect(result.string == "**offen")
        let font = result.attribute(.font, at: 4, effectiveRange: nil) as? NSFont
        #expect(font?.fontDescriptor.symbolicTraits.contains(.bold) == false)
    }

    @Test("Überschrift wird größer gesetzt")
    func heading() {
        let result = styled("# Titel")
        let font = result.attribute(.font, at: 3, effectiveRange: nil) as? NSFont
        #expect((font?.pointSize ?? 0) > EditorTheme.standard.baseSize)
    }
}
