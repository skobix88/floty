import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    /// Shows and hides the panel from anywhere. Default matches the mockup: ^⌥⌘N.
    static let togglePanel = Self("togglePanel", default: .init(.n, modifiers: [.control, .option, .command]))
}
