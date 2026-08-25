import AppKit

/// Turns raw Markdown into the styled text the editor shows.
///
/// The markers stay in the document - what you see is what the file contains.
/// The single exception is the task box: `- [ ] ` is drawn as a checkbox,
/// because a box has to be clickable. The substitution is length preserving
/// (six characters in, six characters out), so selection and caret arithmetic
/// keep working on the raw text underneath.
enum MarkdownHighlighter {

    static let uncheckedGlyph = "\u{2610}"  // BALLOT BOX
    static let checkedGlyph = "\u{2611}"    // BALLOT BOX WITH CHECK

    /// Styles one paragraph. Called from the text content storage delegate, so
    /// only the paragraphs that actually changed are restyled.
    static func styled(_ source: NSAttributedString, theme: EditorTheme = .standard) -> NSAttributedString {
        let result = NSMutableAttributedString(attributedString: source)
        let full = NSRange(location: 0, length: result.length)

        result.setAttributes([
            .font: theme.font,
            .foregroundColor: theme.text
        ], range: full)

        let raw = source.string
        styleBlock(result, raw: raw, theme: theme)
        styleInline(result, raw: raw, theme: theme)
        return result
    }

    // MARK: - Block level

    private static func styleBlock(_ result: NSMutableAttributedString, raw: String, theme: EditorTheme) {
        let ns = raw as NSString
        let lineText = raw.trimmingCharacters(in: CharacterSet.newlines)
        let lineLength = (lineText as NSString).length
        guard lineLength > 0 else { return }

        if let heading = headingLevel(lineText) {
            result.addAttribute(.font, value: theme.headingFont(level: heading.level),
                                range: NSRange(location: 0, length: lineLength))
            result.addAttribute(.foregroundColor, value: theme.heading,
                                range: NSRange(location: 0, length: lineLength))
            result.addAttribute(.foregroundColor, value: theme.marker,
                                range: NSRange(location: 0, length: heading.markerLength))
            return
        }

        let line = MarkdownLine.parse(lineText)
        switch line.kind {
        case .plain:
            return

        case .bullet, .ordered:
            result.addAttribute(.foregroundColor, value: theme.marker,
                                range: NSRange(location: 0, length: line.prefixLength))

        case .task(_, let done):
            drawTaskBox(in: result, line: line, done: done, theme: theme)
            if done, let struck = TaskToggle.struckThroughRange(of: line, lineStart: 0, lineLength: lineLength) {
                result.addAttributes([
                    .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                    .strikethroughColor: theme.done,
                    .foregroundColor: theme.done
                ], range: struck)
            }
        }
        _ = ns
    }

    /// Replaces `- [ ] ` with `   X  ` - same length, so nothing downstream
    /// has to translate between what is shown and what is stored.
    private static func drawTaskBox(in result: NSMutableAttributedString,
                                    line: MarkdownLine,
                                    done: Bool,
                                    theme: EditorTheme) {
        guard let box = line.boxRange else { return }
        let prefix = NSRange(location: 0, length: line.prefixLength)
        let glyph = done ? checkedGlyph : uncheckedGlyph

        // indent + two blanks for the bullet, the glyph where `[` sat, blanks after.
        let leading = String(repeating: " ", count: box.location)
        let trailing = String(repeating: " ", count: line.prefixLength - box.location - 1)
        let display = leading + glyph + trailing
        guard (display as NSString).length == prefix.length else { return }

        result.replaceCharacters(in: prefix, with: display)
        result.addAttributes([
            .font: theme.font,
            .foregroundColor: theme.box
        ], range: prefix)
    }

    private static func headingLevel(_ line: String) -> (level: Int, markerLength: Int)? {
        let ns = line as NSString
        var hashes = 0
        while hashes < ns.length, ns.character(at: hashes) == 35 { hashes += 1 }  // '#'
        guard hashes > 0, hashes <= 6, hashes < ns.length, ns.character(at: hashes) == 32 else { return nil }
        return (hashes, hashes + 1)
    }

    // MARK: - Inline level

    private enum InlineStyle {
        case bold, italic, strikethrough, code
    }

    /// Order matters: `**` has to be recognised before `*`.
    private static let patterns: [(regex: NSRegularExpression, style: InlineStyle)] = {
        func compile(_ pattern: String) -> NSRegularExpression {
            // The patterns are constants; a failure here is a programming error.
            try! NSRegularExpression(pattern: pattern)
        }
        return [
            (compile(#"(\*\*)([^\s*][^*]*?[^\s*]|[^\s*])(\*\*)"#), .bold),
            (compile(#"(~~)([^\s~][^~]*?[^\s~]|[^\s~])(~~)"#), .strikethrough),
            (compile(#"(?<![*\w])(\*)([^\s*][^*]*?[^\s*]|[^\s*])(\*)(?![*\w])"#), .italic),
            (compile(#"(`)([^`]+)(`)"#), .code)
        ]
    }()

    private static func styleInline(_ result: NSMutableAttributedString, raw: String, theme: EditorTheme) {
        let full = NSRange(location: 0, length: (raw as NSString).length)
        for (regex, style) in patterns {
            for match in regex.matches(in: raw, range: full) {
                guard match.numberOfRanges == 4 else { continue }
                let inner = match.range(at: 2)
                guard inner.location != NSNotFound, inner.upperBound <= result.length else { continue }

                switch style {
                case .bold:
                    addTrait(.bold, to: result, range: inner, theme: theme)
                case .italic:
                    addTrait(.italic, to: result, range: inner, theme: theme)
                case .strikethrough:
                    result.addAttributes([
                        .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                        .strikethroughColor: theme.text
                    ], range: inner)
                case .code:
                    result.addAttributes([
                        .font: theme.monospacedFont,
                        .foregroundColor: theme.code
                    ], range: inner)
                }

                for marker in [match.range(at: 1), match.range(at: 3)]
                where marker.location != NSNotFound && marker.upperBound <= result.length {
                    result.addAttribute(.foregroundColor, value: theme.marker, range: marker)
                }
            }
        }
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
