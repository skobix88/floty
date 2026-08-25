import Foundation

/// Checking and unchecking task boxes.
///
/// The file always holds standard Markdown `- [ ]` / `- [x]`; the box the user
/// sees is drawn, never stored. See CLAUDE.md rule 2.
enum TaskToggle {

    /// Toggles the task on the line containing `location`.
    /// Returns nil when that line has no task box.
    static func edit(in text: String, at location: Int) -> ListContinuation.Edit? {
        let ns = text as NSString
        guard location <= ns.length else { return nil }
        let lineRange = ns.lineRange(for: NSRange(location: location, length: 0))
        let lineText = ns.substring(with: lineRange).trimmingCharacters(in: CharacterSet.newlines)
        let line = MarkdownLine.parse(lineText)
        guard case .task(_, let done) = line.kind, let box = line.boxRange else { return nil }

        return ListContinuation.Edit(
            range: NSRange(location: lineRange.location + box.location, length: box.length),
            replacement: done ? "[ ]" : "[x]"
        )
    }

    /// The text a checked task strikes through: everything after the marker.
    static func struckThroughRange(of line: MarkdownLine, lineStart: Int, lineLength: Int) -> NSRange? {
        guard case .task(_, true) = line.kind, line.prefixLength < lineLength else { return nil }
        return NSRange(location: lineStart + line.prefixLength, length: lineLength - line.prefixLength)
    }
}
