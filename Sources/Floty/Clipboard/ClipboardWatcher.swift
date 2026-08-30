import AppKit
import Observation

/// Watches the clipboard and keeps the history.
///
/// macOS offers no notification when the clipboard changes - there is only
/// `NSPasteboard.changeCount`, which has to be asked. The timer therefore runs
/// only while the feature is switched on and not paused; switched off, Floty has
/// no background loop at all.
@MainActor
@Observable
final class ClipboardWatcher {

    static let interval: TimeInterval = 0.4

    private(set) var history: ClipboardHistory
    private(set) var isRunning = false

    var limits: ClipboardHistory.Limits
    var excludedApps: Set<String>

    @ObservationIgnored private let store: ClipboardStore
    @ObservationIgnored private var timer: Timer?
    /// The last state we have already dealt with. Also how Floty skips its own
    /// writes: after putting an entry back on the clipboard it moves this
    /// forward, so the entry does not bounce to the top again on the next tick.
    @ObservationIgnored private var lastChangeCount: Int

    init(store: ClipboardStore,
         limits: ClipboardHistory.Limits = .standard,
         excludedApps: Set<String> = []) {
        self.store = store
        self.limits = limits
        self.excludedApps = excludedApps
        self.history = ClipboardHistory(entries: store.loadEntries())
        self.lastChangeCount = NSPasteboard.general.changeCount
    }

    // MARK: - Running

    func start() {
        guard timer == nil else { return }
        // Was lay on the clipboard before switching on is not ours to take.
        lastChangeCount = NSPasteboard.general.changeCount
        let timer = Timer.scheduledTimer(withTimeInterval: Self.interval, repeats: true) { _ in
            Task { @MainActor [weak self] in self?.poll() }
        }
        timer.tolerance = Self.interval / 2  // schont den Akku
        self.timer = timer
        isRunning = true
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    // MARK: - Reading

    private func poll() {
        let pasteboard = NSPasteboard.general
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount

        let types = pasteboard.types?.map(\.rawValue) ?? []
        let source = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        guard PasteboardPolicy.shouldRecord(types: types,
                                            source: source,
                                            excludedApps: excludedApps) else { return }

        // Text wins when both are present: it is what people look for.
        if let text = pasteboard.string(forType: .string),
           !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            record(ClipboardEntry.text(text), imageData: nil)
            return
        }

        if let png = imageData(from: pasteboard), let size = Self.pixelSize(of: png) {
            record(ClipboardEntry.image(data: png, width: size.width, height: size.height),
                   imageData: png)
        }
    }

    private func imageData(from pasteboard: NSPasteboard) -> Data? {
        if let png = pasteboard.data(forType: .png) { return png }
        guard let tiff = pasteboard.data(forType: .tiff),
              let rep = NSBitmapImageRep(data: tiff) else { return nil }
        return rep.representation(using: .png, properties: [:])
    }

    private static func pixelSize(of png: Data) -> (width: Int, height: Int)? {
        guard let rep = NSBitmapImageRep(data: png) else { return nil }
        return (rep.pixelsWide, rep.pixelsHigh)
    }

    private func record(_ entry: ClipboardEntry, imageData: Data?) {
        let change = history.insert(entry, limits: limits)
        guard change.accepted else { return }
        if let imageData {
            try? store.writeImage(imageData, for: entry.id)
        }
        store.deleteFiles(for: change.dropped)
        persist()
    }

    // MARK: - Using

    /// Puts an entry back on the clipboard. Deliberately no automatic paste -
    /// that would need the Accessibility permission.
    func copyToPasteboard(_ entry: ClipboardEntry) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        switch entry.kind {
        case .text:
            pasteboard.setString(entry.text ?? "", forType: .string)
        case .image:
            if let data = try? Data(contentsOf: store.imageURL(for: entry.id)) {
                pasteboard.setData(data, forType: .png)
            }
        }
        // Our own write must not come back in as a new entry.
        lastChangeCount = pasteboard.changeCount
    }

    func thumbnailURL(for entry: ClipboardEntry) -> URL? {
        guard entry.kind == .image else { return nil }
        let url = store.thumbnailURL(for: entry.id)
        return FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) ? url : nil
    }

    func remove(_ id: ClipboardEntry.ID) {
        guard let removed = history.remove(id) else { return }
        store.deleteFiles(for: [removed])
        persist()
    }

    func clear() {
        store.clear(history.removeAll())
    }

    func occupiedBytes() -> Int { store.occupiedBytes() }

    /// Applies changed limits right away, so lowering the count in the settings
    /// does not wait for the next copy.
    func applyLimits(_ newLimits: ClipboardHistory.Limits) {
        limits = newLimits
        let dropped = history.prune(newLimits)
        guard !dropped.isEmpty else { return }
        store.deleteFiles(for: dropped)
        persist()
    }

    private func persist() {
        try? store.save(history.entries)
    }
}
