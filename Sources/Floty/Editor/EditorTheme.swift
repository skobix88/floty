import AppKit

/// Fixed dark, neutral colouring - see CLAUDE.md rule 5.
struct EditorTheme: Sendable {
    var baseSize: CGFloat = 14

    var text = NSColor(white: 0.90, alpha: 1)
    /// Markdown markers stay readable but step back.
    var marker = NSColor(white: 0.42, alpha: 1)
    /// Text of a finished task.
    var done = NSColor(white: 0.45, alpha: 1)
    var box = NSColor(white: 0.72, alpha: 1)
    var code = NSColor(red: 0.70, green: 0.80, blue: 0.92, alpha: 1)
    var heading = NSColor(white: 0.97, alpha: 1)
    var insertionPoint = NSColor(red: 0.45, green: 0.62, blue: 0.90, alpha: 1)

    var font: NSFont { .systemFont(ofSize: baseSize) }
    var monospacedFont: NSFont { .monospacedSystemFont(ofSize: baseSize - 1, weight: .regular) }

    func headingFont(level: Int) -> NSFont {
        let bump: CGFloat = switch level {
        case 1: 6
        case 2: 4
        case 3: 2
        default: 1
        }
        return .systemFont(ofSize: baseSize + bump, weight: .semibold)
    }

    static let standard = EditorTheme()
}
