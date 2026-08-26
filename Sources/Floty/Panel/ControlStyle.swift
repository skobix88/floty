import SwiftUI

/// Size and tone of the small control icons in the panel.
///
/// The reference is the app Floty is modelled on: its icons sit back and let
/// the text lead. A single place for it, so nudging the look does not mean
/// touching five files.
enum ControlStyle {
    /// Roughly a quarter smaller than SwiftUI's `.imageScale(.large)`.
    static let headerSize: CGFloat = 12.5
    static let footerSize: CGFloat = 13
    static let tabSize: CGFloat = 12

    /// Dim enough to step back, bright enough to read on the darkest backdrop.
    static let idle = Color(white: 0.46)
    /// Only the pinned state earns attention.
    static let active = Color(white: 0.88)

    static func icon(_ size: CGFloat) -> Font { .system(size: size, weight: .medium) }
}
