import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    /// Shows and hides the panel from anywhere. Default matches the mockup: ^⌥⌘N.
    static let togglePanel = Self("togglePanel", default: .init(.n, modifiers: [.control, .option, .command]))

    /// Opens the clipboard history: ^⌥⌘C.
    ///
    /// The obvious choice would have been ^⌥⌘V, matching the panel's ^⌥⌘N. It
    /// was tried and dropped: Raycast ships its own clipboard history on that
    /// combination, and both windows opened on top of each other. C for
    /// clipboard is free and just as easy to remember. Changeable in settings.
    static let toggleClipboard = Self("toggleClipboard", default: .init(.c, modifiers: [.control, .option, .command]))
}
