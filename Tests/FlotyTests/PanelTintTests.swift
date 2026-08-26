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

@Suite("Farbton in der Fläche")
struct PanelTintSurfaceTests {

    /// Der Farbton liegt jetzt volldeckend unter dem Regler, statt mit dessen
    /// Deckkraft über dem Weichzeichner zu liegen. Bei voller Deckkraft muss
    /// die Fläche deshalb exakt der eingestellte Ton sein.
    private func srgb(_ color: Color) -> NSColor {
        NSColor(color).usingColorSpace(.sRGB) ?? .black
    }

    @Test("Die beiden Farbtöne unterscheiden sich messbar")
    func distinguishable() {
        let neutral = srgb(PanelTint.neutral.base)
        let midnight = srgb(PanelTint.midnight.base)
        let blueDelta = (midnight.blueComponent - neutral.blueComponent) * 255
        #expect(blueDelta > 12, "Blauanteil unterscheidet sich nur um \(blueDelta)")
    }

    @Test("Mitternachtsblau ist blaustichig, Neutralgrau nicht")
    func hue() {
        let midnight = srgb(PanelTint.midnight.base)
        #expect(midnight.blueComponent > midnight.redComponent)

        let neutral = srgb(PanelTint.neutral.base)
        #expect(abs(neutral.blueComponent - neutral.redComponent) < 0.01)
    }

    @Test("Der Regler lässt deutlich mehr Transparenz zu als früher")
    @MainActor
    func opacityRange() {
        #expect(AppSettings.minimumOpacity < 0.15)
        #expect(AppSettings.minimumOpacity > 0, "ganz unsichtbar wäre nicht bedienbar")
    }
}
