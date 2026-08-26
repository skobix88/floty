import AppKit
import SwiftUI

/// The blurred window backdrop.
///
/// `.underWindowBackground` rather than `.hudWindow`: the latter renders a
/// fairly light grey that pulls any tint towards neutral. The text is never
/// faded with it - only the backdrop - so "translucent" stays readable.
struct VisualEffectBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .underWindowBackground
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
