import Foundation

/// What a single line of Markdown starts with.
///
/// Deliberately hand written and line based: Floty needs list markers, task
/// boxes and inline emphasis, nothing else. A full Markdown parser would be
/// larger than this whole app.
struct MarkdownLine: Equatable {

    enum Kind: Equatable {
        case plain
        /// `- `, `* ` or `+ `
        case bullet(marker: String)
        /// `1. ` or `1) `
        case ordered(number: Int, delimiter: String)
        /// `- [ ] ` or `- [x] `
        case task(bullet: String, done: Bool)
    }

    /// Leading spaces and tabs.
    let indent: String
    let kind: Kind
    /// UTF-16 length of indent plus marker: where the content starts.
    let prefixLength: Int
    /// Everything after the marker.
    let content: String
    /// The `[ ]` / `[x]` box, relative to the start of the line. Nil unless task.
    let boxRange: NSRange?

    var isEmptyItem: Bool {
        kind != .plain && content.trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// The marker a new line below this one should start with.
    /// Nil for plain lines - there is nothing to continue.
    var continuationPrefix: String? {
        switch kind {
        case .plain:
            nil
        case .bullet(let marker):
            indent + marker + " "
        case .ordered(let number, let delimiter):
            indent + "\(number + 1)\(delimiter) "
        case .task(let bullet, _):
            indent + bullet + " [ ] "
        }
    }

    // MARK: - Parsing

    private enum C {
        static let space: unichar = 32, tab: unichar = 9
        static let dash: unichar = 45, star: unichar = 42, plus: unichar = 43
        static let dot: unichar = 46, paren: unichar = 41
        static let open: unichar = 91, close: unichar = 93
        static let lowerX: unichar = 120, upperX: unichar = 88
        static let zero: unichar = 48, nine: unichar = 57
    }

    static func parse(_ line: String) -> MarkdownLine {
        let ns = line as NSString
        var i = 0
        while i < ns.length, ns.character(at: i) == C.space || ns.character(at: i) == C.tab { i += 1 }
        let indent = ns.substring(to: i)

        func plain() -> MarkdownLine {
            MarkdownLine(indent: indent, kind: .plain, prefixLength: 0, content: line, boxRange: nil)
        }
        func rest(from index: Int) -> String { ns.substring(from: index) }

        guard i < ns.length else { return plain() }
        let first = ns.character(at: i)

        // `- `, `* `, `+ ` - possibly followed by a task box.
        if first == C.dash || first == C.star || first == C.plus {
            guard i + 1 < ns.length, ns.character(at: i + 1) == C.space else { return plain() }
            let bullet = ns.substring(with: NSRange(location: i, length: 1))
            let afterBullet = i + 2

            // `[ ]` / `[x]` followed by a space.
            if afterBullet + 3 < ns.length,
               ns.character(at: afterBullet) == C.open,
               ns.character(at: afterBullet + 2) == C.close,
               ns.character(at: afterBullet + 3) == C.space {
                let mark = ns.character(at: afterBullet + 1)
                let done: Bool?
                switch mark {
                case C.space: done = false
                case C.lowerX, C.upperX: done = true
                default: done = nil
                }
                if let done {
                    let prefix = afterBullet + 4
                    return MarkdownLine(
                        indent: indent,
                        kind: .task(bullet: bullet, done: done),
                        prefixLength: prefix,
                        content: rest(from: prefix),
                        boxRange: NSRange(location: afterBullet, length: 3)
                    )
                }
            }

            return MarkdownLine(
                indent: indent,
                kind: .bullet(marker: bullet),
                prefixLength: afterBullet,
                content: rest(from: afterBullet),
                boxRange: nil
            )
        }

        // `1. ` / `1) `
        var digitEnd = i
        while digitEnd < ns.length,
              ns.character(at: digitEnd) >= C.zero, ns.character(at: digitEnd) <= C.nine {
            digitEnd += 1
        }
        guard digitEnd > i, digitEnd + 1 < ns.length else { return plain() }
        let delimiterChar = ns.character(at: digitEnd)
        guard delimiterChar == C.dot || delimiterChar == C.paren,
              ns.character(at: digitEnd + 1) == C.space,
              let number = Int(ns.substring(with: NSRange(location: i, length: digitEnd - i)))
        else { return plain() }

        let prefix = digitEnd + 2
        return MarkdownLine(
            indent: indent,
            kind: .ordered(number: number, delimiter: ns.substring(with: NSRange(location: digitEnd, length: 1))),
            prefixLength: prefix,
            content: rest(from: prefix),
            boxRange: nil
        )
    }
}
