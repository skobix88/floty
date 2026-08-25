import AppKit

/// Entry point.
///
/// `@main` on the delegate itself is not enough for an AppKit app:
/// `NSApplicationMain` takes the delegate from the main NIB, and Floty has no
/// NIB. Without this the delegate is never connected and nothing ever launches.
@main
enum FlotyMain {
    /// `NSApplication.delegate` is a weak reference - something has to hold it.
    @MainActor static let delegate = AppDelegate()

    @MainActor
    static func main() {
        let app = NSApplication.shared
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }
}
