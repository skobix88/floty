import AppKit
import SwiftUI

/// SwiftUI wrapper around `MarkdownTextView`.
///
/// The text storage holds raw Markdown at all times; styling happens in the
/// content storage delegate, one paragraph at a time.
struct MarkdownEditor: NSViewRepresentable {
    @Binding var text: String
    var theme: EditorTheme = .standard
    var isEditable: Bool = true

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSScrollView {
        // TextKit 2 stack, built by hand so the content storage can be kept and
        // given a delegate.
        let contentStorage = NSTextContentStorage()
        let layoutManager = NSTextLayoutManager()
        let container = NSTextContainer(size: CGSize(width: 0, height: CGFloat.greatestFiniteMagnitude))
        contentStorage.addTextLayoutManager(layoutManager)
        layoutManager.textContainer = container
        contentStorage.delegate = context.coordinator
        context.coordinator.contentStorage = contentStorage

        let textView = MarkdownTextView(frame: .zero, textContainer: container)
        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.smartInsertDeleteEnabled = false
        textView.drawsBackground = false
        textView.insertionPointColor = theme.insertionPoint
        textView.font = theme.font
        textView.textColor = theme.text
        textView.textContainerInset = NSSize(width: 6, height: 10)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [NSView.AutoresizingMask.width]
        container.widthTracksTextView = true
        textView.string = text

        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.documentView = textView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? MarkdownTextView else { return }
        context.coordinator.parent = self
        textView.isEditable = isEditable
        // Only when the model changed underneath us - otherwise every keystroke
        // would reset the caret.
        if textView.string != text {
            let caret = textView.selectedRange()
            textView.string = text
            let clamped = min(caret.location, (text as NSString).length)
            textView.setSelectedRange(NSRange(location: clamped, length: 0))
        }
    }

    @MainActor
    final class Coordinator: NSObject, NSTextViewDelegate, NSTextContentStorageDelegate {
        var parent: MarkdownEditor
        /// Held here because the text view only keeps the container.
        var contentStorage: NSTextContentStorage?

        init(_ parent: MarkdownEditor) { self.parent = parent }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }

        nonisolated func textContentStorage(_ textContentStorage: NSTextContentStorage,
                                            textParagraphWith range: NSRange) -> NSTextParagraph? {
            guard let source = textContentStorage.textStorage?.attributedSubstring(from: range) else { return nil }
            let styled = MarkdownHighlighter.styled(source, theme: .standard)
            // Length preserving by construction; bail out rather than risk a
            // mismatch between what is stored and what is laid out.
            guard styled.length == source.length else { return nil }
            return NSTextParagraph(attributedString: styled)
        }
    }
}
