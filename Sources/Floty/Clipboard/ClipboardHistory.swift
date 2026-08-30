import Foundation

/// The list itself: order, repeats, limits, searching. No files, no clipboard,
/// no user interface - so all of it can be checked without a running app.
struct ClipboardHistory: Equatable {

    /// Two ceilings, whichever is reached first. A count alone is not enough
    /// once images are recorded: fifty screenshots are several hundred megabyte,
    /// and nobody expects a scratchpad to take that much room.
    struct Limits: Equatable, Sendable {
        var maxCount: Int
        var maxTotalBytes: Int
        /// Anything larger is not taken in at all.
        var maxItemBytes: Int

        static let standard = Limits(maxCount: 50,
                                     maxTotalBytes: 200 * 1024 * 1024,
                                     maxItemBytes: 20 * 1024 * 1024)
    }

    /// Newest first.
    private(set) var entries: [ClipboardEntry] = []

    init(entries: [ClipboardEntry] = []) {
        self.entries = entries.sorted { $0.date > $1.date }
    }

    /// What the caller has to clean up afterwards.
    struct Change: Equatable {
        var accepted: Bool
        /// Entries that fell out - their image files have to go with them.
        var dropped: [ClipboardEntry] = []
    }

    @discardableResult
    mutating func insert(_ entry: ClipboardEntry, limits: Limits = .standard) -> Change {
        guard entry.byteSize <= limits.maxItemBytes else {
            return Change(accepted: false)
        }

        var dropped: [ClipboardEntry] = []

        // A repeat moves up instead of doubling. The older copy goes, so its
        // image file has to go too.
        if let index = entries.firstIndex(where: { $0.fingerprint == entry.fingerprint }) {
            dropped.append(entries.remove(at: index))
        }

        entries.insert(entry, at: 0)
        dropped.append(contentsOf: prune(limits))
        return Change(accepted: true, dropped: dropped)
    }

    mutating func remove(_ id: ClipboardEntry.ID) -> ClipboardEntry? {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return nil }
        return entries.remove(at: index)
    }

    mutating func removeAll() -> [ClipboardEntry] {
        defer { entries = [] }
        return entries
    }

    /// Cuts by count first, then by total size - counting from the newest.
    @discardableResult
    mutating func prune(_ limits: Limits = .standard) -> [ClipboardEntry] {
        var dropped: [ClipboardEntry] = []

        if entries.count > limits.maxCount {
            dropped.append(contentsOf: entries[limits.maxCount...])
            entries.removeSubrange(limits.maxCount...)
        }

        var total = 0
        var cutoff: Int?
        for (index, entry) in entries.enumerated() {
            total += entry.byteSize
            if total > limits.maxTotalBytes {
                cutoff = index
                break
            }
        }
        if let cutoff {
            dropped.append(contentsOf: entries[cutoff...])
            entries.removeSubrange(cutoff...)
        }

        return dropped
    }

    /// Searches name and text, ignoring case and accents.
    func filtered(by query: String) -> [ClipboardEntry] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return entries }
        return entries.filter { entry in
            let haystack = entry.name + " " + (entry.text ?? "")
            return haystack.range(of: trimmed, options: [.caseInsensitive, .diacriticInsensitive]) != nil
        }
    }

    var totalBytes: Int { entries.reduce(0) { $0 + $1.byteSize } }
}
