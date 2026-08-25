import Foundation
import Testing
@testable import Floty

@Suite("Fensterplatzierung")
struct PanelPlacementTests {

    private let screen = NSRect(x: 0, y: 0, width: 1920, height: 1050)
    private let secondScreen = NSRect(x: 1920, y: 0, width: 1920, height: 1080)

    private var fallback: NSRect { PanelPlacement.defaultFrame(in: screen) }

    @Test("Standardposition sitzt oben rechts im nutzbaren Bereich")
    func defaultFrame() {
        let frame = PanelPlacement.defaultFrame(in: screen)
        #expect(frame.maxX == screen.maxX - PanelPlacement.inset)
        #expect(frame.maxY == screen.maxY - PanelPlacement.inset)
        #expect(frame.size == PanelPlacement.defaultSize)
    }

    @Test("Ohne gespeicherte Position gilt der Standard")
    func noStoredFrame() {
        #expect(PanelPlacement.resolve(stored: nil, screens: [screen], fallback: fallback) == fallback)
    }

    @Test("Eine sichtbare gespeicherte Position bleibt erhalten")
    func keepsVisibleFrame() {
        let stored = NSRect(x: 200, y: 200, width: 380, height: 460)
        #expect(PanelPlacement.resolve(stored: stored, screens: [screen], fallback: fallback) == stored)
    }

    @Test("Position auf dem zweiten Bildschirm bleibt erhalten, solange es ihn gibt")
    func keepsSecondScreen() {
        let stored = NSRect(x: 2187, y: 544, width: 380, height: 460)
        #expect(PanelPlacement.resolve(stored: stored,
                                       screens: [screen, secondScreen],
                                       fallback: fallback) == stored)
    }

    @Test("Nach Abziehen des zweiten Bildschirms kommt das Panel zurück")
    func recoversFromRemovedScreen() {
        let stored = NSRect(x: 2187, y: 544, width: 380, height: 460)
        #expect(PanelPlacement.resolve(stored: stored, screens: [screen], fallback: fallback) == fallback)
    }

    @Test("Ein nur knapp überlappendes Fenster gilt als unerreichbar")
    func barelyOverlapping() {
        let stored = NSRect(x: screen.maxX - 30, y: 100, width: 380, height: 460)
        #expect(PanelPlacement.resolve(stored: stored, screens: [screen], fallback: fallback) == fallback)
    }

    @Test("Eine leere gespeicherte Position wird verworfen")
    func emptyFrame() {
        #expect(PanelPlacement.resolve(stored: .zero, screens: [screen], fallback: fallback) == fallback)
    }
}
