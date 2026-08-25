import AppKit

/// The text view itself: quick formatting, list continuation, clickable boxes.
///
/// Everything it does goes through `shouldChangeText`/`didChangeText`, so undo
/// and the delegate notifications behave like any other edit.
final class MarkdownTextView: NSTextView {

    override var acceptsFirstResponder: Bool { true }

    // MARK: - Return inside lists

    override func insertNewline(_ sender: Any?) {
        guard let edit = ListContinuation.onReturn(in: string, selection: selectedRange()) else {
            super.insertNewline(sender)
            return
        }
        perform(edit, caretAtEndOfReplacement: true)
    }

    // MARK: - Quick formatting

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard window?.firstResponder === self,
              let key = event.charactersIgnoringModifiers?.lowercased()
        else { return super.performKeyEquivalent(with: event) }

        switch event.modifierFlags.intersection(.deviceIndependentFlagsMask) {
        case [.command]:
            switch key {
            case "b": apply(.bold); return true
            case "i": apply(.italic); return true
            default: break
            }
        case [.command, .shift]:
            switch key {
            case "x": apply(.strikethrough); return true
            case "l": toggleTaskLines(); return true
            default: break
            }
        default:
            break
        }
        return super.performKeyEquivalent(with: event)
    }

    private func apply(_ style: InlineFormatting.Style) {
        let edit = InlineFormatting.apply(style, to: string, selection: selectedRange())
        guard shouldChangeText(in: edit.range, replacementString: edit.replacement) else { return }
        textStorage?.replaceCharacters(in: edit.range, with: edit.replacement)
        didChangeText()
        setSelectedRange(edit.selection)
    }

    private func toggleTaskLines() {
        let edit = InlineFormatting.toggleTaskLines(in: string, selection: selectedRange())
        guard shouldChangeText(in: edit.range, replacementString: edit.replacement) else { return }
        textStorage?.replaceCharacters(in: edit.range, with: edit.replacement)
        didChangeText()
        setSelectedRange(NSRange(location: min(edit.selection.upperBound, (string as NSString).length), length: 0))
    }

    // MARK: - Clicking a task box

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        let index = characterIndexForInsertion(at: point)
        if toggleTask(at: index) { return }
        super.mouseDown(with: event)
    }

    /// Only a click on the marker itself toggles - clicking the task text has
    /// to keep placing the caret.
    private func toggleTask(at index: Int) -> Bool {
        let ns = string as NSString
        guard index <= ns.length else { return false }
        let lineRange = ns.lineRange(for: NSRange(location: index, length: 0))
        let lineText = ns.substring(with: lineRange).trimmingCharacters(in: CharacterSet.newlines)
        let line = MarkdownLine.parse(lineText)
        guard case .task = line.kind,
              index - lineRange.location < line.prefixLength,
              let edit = TaskToggle.edit(in: string, at: index)
        else { return false }

        let caret = selectedRange()
        perform(edit, caretAtEndOfReplacement: false)
        setSelectedRange(caret)
        return true
    }

    // MARK: - Helper

    private func perform(_ edit: ListContinuation.Edit, caretAtEndOfReplacement: Bool) {
        guard shouldChangeText(in: edit.range, replacementString: edit.replacement) else { return }
        textStorage?.replaceCharacters(in: edit.range, with: edit.replacement)
        didChangeText()
        if caretAtEndOfReplacement {
            let caret = edit.range.location + (edit.replacement as NSString).length
            setSelectedRange(NSRange(location: caret, length: 0))
        }
    }
}
