import SwiftUI
import Testing
@testable import Floty

@Suite("Farbton")
struct PanelTintTests {

    @Test("Beide Farbtöne sind wählbar und lassen sich merken")
    func roundTrip() {
        for tint in PanelTint.allCases {
            #expect(PanelTint(rawValue: tint.rawValue) == tint)
        }
    }

    @Test("Ein unbekannter gespeicherter Wert fällt auf Neutralgrau zurück")
    func fallback() {
        #expect(PanelTint(rawValue: "regenbogen") == nil)
    }

    @Test("Mitternachtsblau ist #171E30")
    func midnightColour() {
        let components = NSColor(PanelTint.midnight.base).usingColorSpace(.sRGB)
        #expect(Int(((components?.redComponent ?? 0) * 255).rounded()) == 23)
        #expect(Int(((components?.greenComponent ?? 0) * 255).rounded()) == 30)
        #expect(Int(((components?.blueComponent ?? 0) * 255).rounded()) == 48)
    }

    @Test("Beide Farbfamilien bleiben dunkel")
    func staysDark() {
        for tint in PanelTint.allCases {
            let colour = NSColor(tint.base).usingColorSpace(.sRGB)
            let brightness = (colour?.brightnessComponent ?? 1)
            #expect(brightness < 0.25, "\(tint.rawValue) war \(brightness)")
        }
    }
}
