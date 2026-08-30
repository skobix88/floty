import Foundation
import Testing
@testable import Floty

@Suite("Zwischenablage – Zeitangabe")
struct ClipboardTimestampTests {

    private let calendar = Calendar(identifier: .gregorian)
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    @Test("Ganz frisch heißt gerade eben")
    func justNow() {
        #expect(ClipboardTimestamp.recency(of: now.addingTimeInterval(-30),
                                           relativeTo: now, calendar: calendar) == .justNow)
    }

    @Test("Später am selben Tag")
    func today() {
        #expect(ClipboardTimestamp.recency(of: now.addingTimeInterval(-3600 * 3),
                                           relativeTo: now, calendar: calendar) == .today)
    }

    @Test("Gestern und älter werden unterschieden")
    func olderDays() {
        #expect(ClipboardTimestamp.recency(of: now.addingTimeInterval(-3600 * 26),
                                           relativeTo: now, calendar: calendar) == .yesterday)
        #expect(ClipboardTimestamp.recency(of: now.addingTimeInterval(-3600 * 24 * 5),
                                           relativeTo: now, calendar: calendar) == .older)
    }

    @Test("Es kommt immer etwas Lesbares heraus")
    func captionNeverEmpty() {
        for offset: TimeInterval in [-10, -3600, -3600 * 26, -3600 * 24 * 40] {
            let caption = ClipboardTimestamp.caption(for: now.addingTimeInterval(offset),
                                                     relativeTo: now, calendar: calendar)
            #expect(!caption.isEmpty)
        }
    }
}

@Suite("Auswahlfenster")
struct PickerPlacementTests {

    private let screen = NSRect(x: 0, y: 0, width: 1920, height: 1050)

    @Test("Das Fenster sitzt waagerecht mittig")
    func centred() {
        let frame = PanelPlacement.pickerFrame(in: screen, size: NSSize(width: 380, height: 460))
        #expect(frame.midX == screen.midX)
    }

    @Test("Es sitzt im oberen Drittel und bleibt vollständig auf dem Bildschirm")
    func nearTheTop() {
        let frame = PanelPlacement.pickerFrame(in: screen, size: NSSize(width: 380, height: 460))
        #expect(frame.maxY < screen.maxY, "unter der Menüleiste")
        #expect(frame.minY > screen.minY, "nicht unten heraushängend")
        #expect(frame.midY > screen.midY, "obere Hälfte")
    }

    @Test("Auch ein hohes Fenster passt noch auf den Bildschirm")
    func tallWindow() {
        let frame = PanelPlacement.pickerFrame(in: screen, size: NSSize(width: 380, height: 800))
        #expect(frame.minY >= screen.minY)
    }
}
