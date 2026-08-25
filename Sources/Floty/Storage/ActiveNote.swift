import Foundation

/// Which tab is in front after one was deleted.
enum ActiveNote {

    /// Deleting a tab in the background must not move the user somewhere else -
    /// that is the annoying part of most tabbed interfaces. Only when the tab
    /// the user was actually looking at disappears does the neighbour take
    /// over: the one that slid into its place, or the last one if it was the
    /// rightmost.
    static func afterDeletion(of deleted: String,
                              at index: Int,
                              remaining: [String],
                              current: String?) -> String? {
        if let current, current != deleted, remaining.contains(current) {
            return current
        }
        guard !remaining.isEmpty else { return nil }
        return remaining[min(max(index, 0), remaining.count - 1)]
    }
}
