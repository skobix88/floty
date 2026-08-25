import Foundation

/// What pressing Return should do inside a list.
enum ListContinuation {

    /// A text replacement the editor should perform instead of inserting a
    /// plain newline.
    struct Edit: Equatable {
        var range: NSRange
        var replacement: String
    }

    /// Returns nil when the line is not a list item - the editor then inserts a
    /// newline as usual.
    ///
    /// Two behaviours:
    /// - list item with content: continue it (`3. x` -> `4. `)
    /// - empty list item: drop the marker, which ends the list. Without this
    ///   the only way out of a list would be deleting the marker by hand.
    static func onReturn(in text: String, selection: NSRange) -> Edit? {
        let ns = text as NSString
        guard selection.location <= ns.length else { return nil }

        let lineRange = ns.lineRange(for: NSRange(location: selection.location, length: 0))
        // lineRange includes the trailing newline; the marker never does.
        let contentEnd = min(lineRange.upperBound, ns.length)
        let lineText = ns.substring(with: NSRange(location: lineRange.location,
                                                  length: contentEnd - lineRange.location))
            .trimmingCharacters(in: CharacterSet.newlines)
        let line = MarkdownLine.parse(lineText)

        guard let prefix = line.continuationPrefix else { return nil }

        if line.isEmptyItem {
            // Replace the whole marker with nothing, leaving an empty line.
            return Edit(range: NSRange(location: lineRange.location, length: line.prefixLength),
                        replacement: "")
        }

        // Only continue when the caret sits at or past the end of the line;
        // splitting a line in the middle should not duplicate the marker.
        let caretIsAtLineEnd = selection.upperBound >= lineRange.location + (lineText as NSString).length
        guard caretIsAtLineEnd else { return nil }

        return Edit(range: selection, replacement: "\n" + prefix)
    }
}
