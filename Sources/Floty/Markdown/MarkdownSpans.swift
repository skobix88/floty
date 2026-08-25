import Foundation

/// Finds inline emphasis in a line of Markdown.
///
/// Shared by the editor, which keeps the markers and dims them, and the
/// preview, which throws them away. One scanner so the two can never disagree
/// about what counts as emphasis.
enum MarkdownSpans {

    enum Style: Equatable {
        case bold, italic, strikethrough, code
    }

    struct Span: Equatable {
        let style: Style
        let opening: NSRange
        let inner: NSRange
        let closing: NSRange
    }

    /// Order matters: `**` has to be recognised before `*`.
    private static let patterns: [(regex: NSRegularExpression, style: Style)] = {
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

    static func scan(_ text: String) -> [Span] {
        let full = NSRange(location: 0, length: (text as NSString).length)
        var spans: [Span] = []
        for (regex, style) in patterns {
            for match in regex.matches(in: text, range: full) {
                guard match.numberOfRanges == 4 else { continue }
                let opening = match.range(at: 1)
                let inner = match.range(at: 2)
                let closing = match.range(at: 3)
                guard opening.location != NSNotFound,
                      inner.location != NSNotFound,
                      closing.location != NSNotFound else { continue }
                spans.append(Span(style: style, opening: opening, inner: inner, closing: closing))
            }
        }
        return spans
    }
}
