import CryptoKit
import Foundation

/// One thing that passed through the clipboard.
///
/// Text carries its content here - it is small and belongs in the index. Images
/// only carry their measurements; the pixels live in their own file, because a
/// single screenshot outweighs the entire text history.
struct ClipboardEntry: Identifiable, Codable, Equatable, Sendable {

    enum Kind: String, Codable, Sendable {
        case text
        case image
    }

    let id: UUID
    var kind: Kind
    var name: String
    var date: Date
    var byteSize: Int
    /// Recognises a repeat of something already in the list.
    var fingerprint: String
    var text: String?
    var pixelWidth: Int?
    var pixelHeight: Int?

    init(id: UUID = UUID(),
         kind: Kind,
         name: String,
         date: Date = .now,
         byteSize: Int,
         fingerprint: String,
         text: String? = nil,
         pixelWidth: Int? = nil,
         pixelHeight: Int? = nil) {
        self.id = id
        self.kind = kind
        self.name = name
        self.date = date
        self.byteSize = byteSize
        self.fingerprint = fingerprint
        self.text = text
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
    }

    // MARK: - Building

    static let nameLimit = 50

    static func text(_ content: String, date: Date = .now) -> ClipboardEntry {
        ClipboardEntry(kind: .text,
                       name: name(for: content),
                       date: date,
                       byteSize: content.utf8.count,
                       fingerprint: fingerprint(for: Data(content.utf8)),
                       text: content)
    }

    static func image(data: Data, width: Int, height: Int, date: Date = .now) -> ClipboardEntry {
        ClipboardEntry(kind: .image,
                       name: name(forImageWidth: width, height: height),
                       date: date,
                       byteSize: data.count,
                       fingerprint: fingerprint(for: data),
                       pixelWidth: width,
                       pixelHeight: height)
    }

    /// The first line that carries something, shortened. Whitespace is collapsed
    /// so a copied code block does not turn the list into a ragged mess.
    static func name(for content: String) -> String {
        let firstLine = content
            .split(whereSeparator: \.isNewline)
            .first { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .map(String.init) ?? ""

        let collapsed = firstLine
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")

        guard !collapsed.isEmpty else { return String(localized: "Leerer Text") }
        guard collapsed.count > nameLimit else { return collapsed }
        return collapsed.prefix(nameLimit - 1).trimmingCharacters(in: .whitespaces) + "\u{2026}"
    }

    static func name(forImageWidth width: Int, height: Int) -> String {
        // Als Zeichenkette eingesetzt, sonst formatiert die Lokalisierung
        // Pixelmaße mit Tausenderpunkt: "Bild 1.920 × 1.080".
        let across = String(width), down = String(height)
        return String(localized: "Bild \(across) × \(down)")
    }

    private static func fingerprint(for data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}
