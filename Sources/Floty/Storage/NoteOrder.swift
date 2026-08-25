import Foundation

/// The order the tabs appear in.
///
/// Kept as note names rather than identifiers: identifiers only live as long as
/// the app runs, but the order has to survive a restart - and it must also make
/// sense for a file that appeared through iCloud while Floty was closed.
enum NoteOrder {

    /// Notes named in `preferred` come first, in that order. Anything else is
    /// appended in natural file name order, so a note synced from another Mac
    /// lands predictably at the end instead of somewhere in the middle.
    static func arrange(_ notes: [NoteFile], preferring preferred: [String]) -> [NoteFile] {
        var remaining = notes
        var result: [NoteFile] = []

        for name in preferred {
            guard let index = remaining.firstIndex(where: { $0.name == name }) else { continue }
            result.append(remaining.remove(at: index))
        }

        result.append(contentsOf: remaining.sorted {
            $0.name.localizedStandardCompare($1.name) == .orderedAscending
        })
        return result
    }

    /// Moves one note by `offset` positions, clamped to the ends.
    static func moving(_ names: [String], name: String, by offset: Int) -> [String] {
        guard let from = names.firstIndex(of: name) else { return names }
        let to = min(max(from + offset, 0), names.count - 1)
        guard to != from else { return names }
        var result = names
        result.remove(at: from)
        result.insert(name, at: to)
        return result
    }
}
