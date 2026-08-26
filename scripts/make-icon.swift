#!/usr/bin/env swift
import AppKit

// Erzeugt den App-Icon-Satz aus Resources/AppIcon.svg.
// Aufruf: swift scripts/make-icon.swift
//
// Die Vorlage ist ein reiner Umriss. macOS erwartet eine gerundete Kachel,
// also wird der Umriss auf einen dunklen Verlauf gesetzt - passend zur festen
// dunklen Farbgebung von Floty.

let root = URL(filePath: FileManager.default.currentDirectoryPath)
let source = root.appending(path: "Resources/AppIcon.svg")
let target = root.appending(path: "Sources/Floty/Resources/Assets.xcassets/AppIcon.appiconset")

guard let glyph = NSImage(contentsOf: source) else {
    print("AppIcon.svg nicht lesbar: \(source.path(percentEncoded: false))")
    exit(1)
}

/// Kachelmaße nach Apples Vorgaben: die gerundete Fläche füllt nicht das ganze
/// Bild, sondern lässt ringsum Luft für den Schatten.
let tileRatio: CGFloat = 0.80
let cornerRatio: CGFloat = 0.2237
let glyphRatio: CGFloat = 0.52

/// Färbt den schwarzen Umriss hell um.
///
/// Das muss auf durchsichtigem Grund geschehen: `sourceAtop` färbt alles, was
/// schon gezeichnet ist. Direkt über der Kachel gäbe das ein volles Quadrat
/// statt eines Umrisses.
func tinted(_ image: NSImage, side: CGFloat) -> NSImage {
    let result = NSImage(size: NSSize(width: side, height: side))
    result.lockFocus()
    let rect = NSRect(x: 0, y: 0, width: side, height: side)
    image.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1)
    NSColor(calibratedWhite: 0.93, alpha: 1).set()
    rect.fill(using: .sourceAtop)
    result.unlockFocus()
    return result
}

func render(size: Int) -> NSBitmapImageRep {
    let side = CGFloat(size)
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                               isPlanar: false, colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: side, height: side)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    let tileSide = side * tileRatio
    let tile = NSRect(x: (side - tileSide) / 2, y: (side - tileSide) / 2,
                      width: tileSide, height: tileSide)
    let shape = NSBezierPath(roundedRect: tile,
                             xRadius: tileSide * cornerRatio,
                             yRadius: tileSide * cornerRatio)

    NSGradient(colors: [
        NSColor(calibratedWhite: 0.26, alpha: 1),
        NSColor(calibratedWhite: 0.13, alpha: 1)
    ])?.draw(in: shape, angle: -90)

    // Feine helle Kante oben, damit die Kachel nicht flach wirkt.
    shape.lineWidth = max(1, side / 256)
    NSColor(calibratedWhite: 1, alpha: 0.10).setStroke()
    shape.stroke()

    let glyphSide = side * glyphRatio
    let glyphRect = NSRect(x: (side - glyphSide) / 2, y: (side - glyphSide) / 2,
                           width: glyphSide, height: glyphSide)
    tinted(glyph, side: glyphSide).draw(in: glyphRect, from: .zero,
                                        operation: .sourceOver, fraction: 1)

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

// Die zehn Größen, die ein macOS-Symbolsatz braucht.
let variants: [(name: String, pixels: Int)] = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32),
    ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256),
    ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024)
]

for variant in variants {
    guard let data = render(size: variant.pixels).representation(using: .png, properties: [:]) else {
        print("konnte \(variant.name) nicht erzeugen"); exit(1)
    }
    try data.write(to: target.appending(path: "\(variant.name).png"))
}
print("\(variants.count) Symbolgrößen geschrieben nach \(target.lastPathComponent)")
