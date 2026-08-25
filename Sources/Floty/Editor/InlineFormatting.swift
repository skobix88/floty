import Foundation

/// The quick formatting shortcuts: wrap the selection in Markdown markers, or
/// unwrap it when it is already wrapped.
enum InlineFormatting {

    enum Style: String, CaseIterable {
        case bold = "**"
        case italic = "*"
        case strikethrough = "~~"

        var marker: String { rawValue }
    }

    /// With an empty selection the markers are inserted and the caret is placed
    /// between them, so typing continues inside the formatting.
    struct Edit: Equatable {
        var range: NSRange
        var replacement: String
        /// Where the selection should end up afterwards, absolute.
        var selection: NSRange
    }

    static func apply(_ style: Style, to text: String, selection: NSRange) -> Edit {
        let ns = text as NSString
        let marker = style.marker
        let markerLength = (marker as NSString).length
        let selected = ns.substring(with: selection)

        // Already wrapped inside the selection: `**bold**` -> `bold`
        if selected.hasPrefix(marker), selected.hasSuffix(marker),
           (selected as NSString).length >= markerLength * 2 {
            let inner = (selected as NSString).substring(
                with: NSRange(location: markerLength,
                              length: (selected as NSString).length - markerLength * 2))
            return Edit(range: selection,
                        replacement: inner,
                        selection: NSRange(location: selection.location, length: (inner as NSString).length))
        }

        // Wrapped just outside the selection: `**|bold|**` -> `bold`
        let before = NSRange(location: selection.location - markerLength, length: markerLength)
        let after = NSRange(location: selection.upperBound, length: markerLength)
        if before.location >= 0, after.upperBound <= ns.length,
           ns.substring(with: before) == marker, ns.substring(with: after) == marker {
            let outer = NSRange(location: before.location, length: markerLength * 2 + selection.length)
            return Edit(range: outer,
                        replacement: selected,
                        selection: NSRange(location: before.location, length: selection.length))
        }

        let wrapped = marker + selected + marker
        let caret = selection.location + markerLength
        return Edit(range: selection,
                    replacement: wrapped,
                    selection: selection.length == 0
                        ? NSRange(location: caret, length: 0)
                        : NSRange(location: caret, length: selection.length))
    }

    /// Turns the lines touched by the selection into task items, or removes the
    /// task marker if they all already are ones.
    static func toggleTaskLines(in text: String, selection: NSRange) -> Edit {
        let ns = text as NSString
        let lines = ns.lineRange(for: selection)
        let block = ns.substring(with: lines)
        let hadTrailingNewline = block.hasSuffix("\n")
        let parts = block.components(separatedBy: "\n")
        let bodyCount = hadTrailingNewline ? parts.count - 1 : parts.count
        let body = Array(parts.prefix(bodyCount))

        let allTasks = body.allSatisfy {
            if case .task = MarkdownLine.parse($0).kind { return true }
            return false
        }

        let rewritten = body.map { lineText -> String in
            let line = MarkdownLine.parse(lineText)
            if allTasks, case .task = line.kind {
                return line.indent + line.content
            }
            if case .task = line.kind { return lineText }
            return line.indent + "- [ ] " + (lineText as NSString)
                .substring(from: (line.indent as NSString).length)
        }

        var replacement = rewritten.joined(separator: "\n")
        if hadTrailingNewline { replacement += "\n" }
        return Edit(range: lines,
                    replacement: replacement,
                    selection: NSRange(location: lines.location, length: (replacement as NSString).length))
    }
}
