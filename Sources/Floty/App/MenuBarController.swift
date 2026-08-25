import AppKit

/// The menu bar item Floty lives in. Left click toggles the panel, right click
/// opens the menu - there is no Dock icon to fall back on.
@MainActor
final class MenuBarController {

    private let statusItem: NSStatusItem
    private let onToggle: () -> Void

    init(onToggle: @escaping () -> Void) {
        self.onToggle = onToggle
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "note.text",
                                   accessibilityDescription: String(localized: "Floty"))
            button.image?.isTemplate = true
            button.target = self
            button.action = #selector(buttonClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    @objc private func buttonClicked() {
        guard let event = NSApp.currentEvent else { onToggle(); return }
        if event.type == .rightMouseUp || event.modifierFlags.contains(.control) {
            showMenu()
        } else {
            onToggle()
        }
    }

    private func showMenu() {
        let menu = NSMenu()
        menu.addItem(withTitle: String(localized: "Floty öffnen"),
                     action: #selector(toggleFromMenu), keyEquivalent: "")
            .target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: String(localized: "Floty beenden"),
                     action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        // Detached again straight away, otherwise a left click would open the
        // menu instead of the panel.
        statusItem.menu = nil
    }

    @objc private func toggleFromMenu() { onToggle() }
}
