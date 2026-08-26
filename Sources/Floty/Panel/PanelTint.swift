import SwiftUI

/// The panel's colour family.
///
/// CLAUDE.md rule 5 used to say "fixed dark, neutral colouring". That has been
/// agreed away: neutral grey turned out to feel flat, so there is a second,
/// blue-leaning family. Both stay dark - a light mode is still not on the table.
enum PanelTint: String, CaseIterable, Identifiable, Sendable {
    case neutral
    case midnight

    var id: String { rawValue }

    var name: String {
        switch self {
        case .neutral: String(localized: "Neutralgrau")
        case .midnight: String(localized: "Mitternachtsblau")
        }
    }

    /// The plate the opacity slider fades over the blurred backdrop.
    var base: Color {
        switch self {
        case .neutral: Color(white: 0.12)
        case .midnight: Color(red: 0.090, green: 0.118, blue: 0.188)  // #171E30
        }
    }

    /// Tab that is not in front.
    var chipIdle: Color {
        switch self {
        case .neutral: Color(white: 0.20)
        case .midnight: Color(red: 0.122, green: 0.153, blue: 0.251)
        }
    }

    /// Tab in front.
    var chipActive: Color {
        switch self {
        case .neutral: Color(red: 0.20, green: 0.30, blue: 0.48)
        case .midnight: Color(red: 0.184, green: 0.263, blue: 0.451)
        }
    }

    /// Behind the text field while renaming a tab.
    var field: Color {
        switch self {
        case .neutral: Color(white: 0.22)
        case .midnight: Color(red: 0.137, green: 0.173, blue: 0.282)
        }
    }
}
