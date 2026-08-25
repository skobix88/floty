import AppKit

/// The rendered view behind the eye button: Markdown as it should look, with
/// the markers gone.
///
/// This is the one place where text is deliberately *not* one to one with the
/// file - it is read only, so nothing can be lost that way.
enum PreviewRenderer {

    static func render(_ markdown: String, theme: EditorTheme = .standard) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let lines = markdown.components(separatedBy: "\n")
        for (index, line) in lines.enumerated() {
            result.append(renderLine(line, theme: theme))
            if index < lines.count - 1 {
                result.append(NSAttributedString(string: "\n"))
            }
        }
        return result
    }

    private static func renderLine(_ line: String, theme: EditorTheme) -> NSAttributedString {
        let result = NSMutableAttributedString(string: line, attributes: [
            .font: theme.font,
            .foregroundColor: theme.text
        ])
        guard result.length > 0 else { return result }

        // Inline first: the ranges come from the untouched line. The block
        // prefix is replaced afterwards, because that shifts everything.
        applyInline(to: result, raw: line, theme: theme)

        if let heading = headingPrefix(line) {
            result.addAttributes([
                .font: theme.headingFont(level: heading.level),
                .foregroundColor: theme.heading
            ], range: NSRange(location: 0, length: result.length))
            result.replaceCharacters(in: NSRange(location: 0, length: heading.length), with: "")
            return result
        }

        let parsed = MarkdownLine.parse(line)
        switch parsed.kind {
        case .plain:
            return result

        case .task(_, let done):
            if done {
                result.addAttributes([
                    .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                    .strikethroughColor: theme.done,
                    .foregroundColor: theme.done
                ], range: NSRange(location: parsed.prefixLength,
                                  length: result.length - parsed.prefixLength))
            }
            let glyph = done ? MarkdownHighlighter.checkedGlyph : MarkdownHighlighter.uncheckedGlyph
            replacePrefix(in: result, length: parsed.prefixLength,
                          with: parsed.indent + glyph + " ", color: theme.box, theme: theme)

        case .bullet:
            replacePrefix(in: result, length: parsed.prefixLength,
                          with: parsed.indent + "\u{2022} ", color: theme.marker, theme: theme)

        case .ordered(let number, _):
            replacePrefix(in: result, length: parsed.prefixLength,
                          with: parsed.indent + "\(number). ", color: theme.marker, theme: theme)
        }
        return result
    }

    private static func replacePrefix(in result: NSMutableAttributedString,
                                      length: Int,
                                      with replacement: String,
                                      color: NSColor,
                                      theme: EditorTheme) {
        guard length <= result.length else { return }
        result.replaceCharacters(in: NSRange(location: 0, length: length), with: replacement)
        result.addAttributes([
            .font: theme.font,
            .foregroundColor: color
        ], range: NSRange(location: 0, length: (replacement as NSString).length))
    }

    /// Applies emphasis, then removes the markers back to front so the earlier
    /// ranges stay valid while deleting.
    private static func applyInline(to result: NSMutableAttributedString, raw: String, theme: EditorTheme) {
        let spans = MarkdownSpans.scan(raw)
        for span in spans where span.inner.upperBound <= result.length {
            switch span.style {
            case .bold:
                addTrait(.bold, to: result, range: span.inner, theme: theme)
            case .italic:
                addTrait(.italic, to: result, range: span.inner, theme: theme)
            case .strikethrough:
                result.addAttributes([
                    .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                    .strikethroughColor: theme.text
                ], range: span.inner)
            case .code:
                result.addAttributes([
                    .font: theme.monospacedFont,
                    .foregroundColor: theme.code
                ], range: span.inner)
            }
        }

        let markers = spans
            .flatMap { [$0.opening, $0.closing] }
            .filter { $0.upperBound <= result.length }
            .sorted { $0.location > $1.location }
        for marker in markers {
            result.replaceCharacters(in: marker, with: "")
        }
    }

    private static func headingPrefix(_ line: String) -> (level: Int, length: Int)? {
        let ns = line as NSString
        var hashes = 0
        while hashes < ns.length, ns.character(at: hashes) == 35 { hashes += 1 }  // '#'
        guard hashes > 0, hashes <= 6, hashes < ns.length, ns.character(at: hashes) == 32 else { return nil }
        return (hashes, hashes + 1)
    }

    private static func addTrait(_ trait: NSFontDescriptor.SymbolicTraits,
                                 to text: NSMutableAttributedString,
                                 range: NSRange,
                                 theme: EditorTheme) {
        text.enumerateAttribute(.font, in: range) { value, subrange, _ in
            let current = (value as? NSFont) ?? theme.font
            var traits = current.fontDescriptor.symbolicTraits
            traits.insert(trait)
            let descriptor = current.fontDescriptor.withSymbolicTraits(traits)
            if let font = NSFont(descriptor: descriptor, size: current.pointSize) {
                text.addAttribute(.font, value: font, range: subrange)
            }
        }
    }
}
