import Foundation
import Testing
@testable import Floty

@Suite("Version")
struct AppVersionTests {

    @Test("Ohne Vorabkennzeichnung bleibt die Nummer schlicht")
    func release() {
        #expect(AppVersion.semantic(marketing: "1.2.3", preRelease: nil) == "1.2.3")
        #expect(AppVersion.semantic(marketing: "1.2.3", preRelease: "") == "1.2.3")
    }

    @Test("Mit Vorabkennzeichnung wird sie angehängt")
    func preRelease() {
        #expect(AppVersion.semantic(marketing: "1.0.0", preRelease: "rc.1") == "1.0.0-rc.1")
    }

    @Test("Das Bündel trägt eine rein numerische Marketing-Nummer")
    func bundleVersionIsNumeric() {
        // Sonst stolpert die Notarisierung später darüber.
        let parts = AppVersion.marketing.split(separator: ".")
        #expect(parts.count >= 2)
        #expect(parts.allSatisfy { $0.allSatisfy(\.isNumber) }, "war: \(AppVersion.marketing)")
    }

    @Test("Die Anzeige nennt Namen, Version und Build")
    func display() {
        #expect(AppVersion.display.hasPrefix("Floty "))
        #expect(AppVersion.display.contains(AppVersion.semantic))
    }
}
