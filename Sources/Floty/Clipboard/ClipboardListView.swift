import AppKit
import SwiftUI

/// The picker: search field on top, list below, keyboard first.
struct ClipboardListView: View {
    let watcher: ClipboardWatcher
    @Bindable var settings: AppSettings
    let onChoose: (ClipboardEntry) -> Void
    let onClose: () -> Void

    @State private var query = ""
    @State private var selection: ClipboardEntry.ID?
    @FocusState private var searchFocused: Bool

    private var visible: [ClipboardEntry] { watcher.history.filtered(by: query) }

    var body: some View {
        VStack(spacing: 0) {
            search
            Divider().opacity(0.25)
            if visible.isEmpty {
                empty
            } else {
                list
            }
        }
        .background {
            ZStack {
                VisualEffectBackground()
                settings.tint.base
            }
            .opacity(settings.panelOpacity)
            .ignoresSafeArea()
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .preferredColorScheme(.dark)
        .onAppear {
            searchFocused = true
            selection = visible.first?.id
        }
    }

    // MARK: - Search

    private var search: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(ControlStyle.idle)
            TextField(String(localized: "Suchen"), text: $query)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .focused($searchFocused)
                .onChange(of: query) { _, _ in selection = visible.first?.id }
                .onKeyPress(.upArrow) { move(-1); return .handled }
                .onKeyPress(.downArrow) { move(1); return .handled }
                .onKeyPress(.return) { chooseSelected(); return .handled }
                .onKeyPress(.escape) { onClose(); return .handled }
                .onKeyPress(keys: [.delete, .deleteForward], phases: .down) { press in
                    guard press.modifiers.contains(.command) else { return .ignored }
                    deleteSelected()
                    return .handled
                }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private var empty: some View {
        VStack {
            Spacer()
            Text(query.isEmpty
                 ? String(localized: "Noch nichts kopiert.")
                 : String(localized: "Nichts gefunden."))
                .font(.system(size: 13))
                .foregroundStyle(ControlStyle.idle)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - List

    private var list: some View {
        ScrollViewReader { scroll in
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(visible) { entry in
                        row(entry)
                            .id(entry.id)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
            }
            .onChange(of: selection) { _, new in
                guard let new else { return }
                withAnimation(.easeOut(duration: 0.12)) { scroll.scrollTo(new, anchor: .center) }
            }
        }
    }

    private func row(_ entry: ClipboardEntry) -> some View {
        let isSelected = entry.id == selection
        return HStack(spacing: 10) {
            preview(entry)
            Text(entry.name)
                .font(.system(size: 13))
                .foregroundStyle(Color(white: isSelected ? 0.97 : 0.86))
                .lineLimit(1)
            Spacer(minLength: 8)
            Text(ClipboardTimestamp.caption(for: entry.date))
                .font(.system(size: 11))
                .foregroundStyle(ControlStyle.idle)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(isSelected ? settings.tint.chipActive : .clear,
                    in: RoundedRectangle(cornerRadius: 7, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture { onChoose(entry) }
        .onHover { if $0 { selection = entry.id } }
        .contextMenu {
            Button(String(localized: "Löschen"), role: .destructive) { watcher.remove(entry.id) }
        }
    }

    @ViewBuilder
    private func preview(_ entry: ClipboardEntry) -> some View {
        if let url = watcher.thumbnailURL(for: entry), let image = NSImage(contentsOf: url) {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 26, height: 20)
                .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
        } else {
            Image(systemName: entry.kind == .image ? "photo" : "text.alignleft")
                .font(.system(size: 11))
                .foregroundStyle(ControlStyle.idle)
                .frame(width: 26, height: 20)
        }
    }

    // MARK: - Keyboard

    private func move(_ offset: Int) {
        let items = visible
        guard !items.isEmpty else { return }
        let current = items.firstIndex { $0.id == selection } ?? 0
        let next = min(max(current + offset, 0), items.count - 1)
        selection = items[next].id
    }

    private func chooseSelected() {
        guard let entry = visible.first(where: { $0.id == selection }) ?? visible.first else { return }
        onChoose(entry)
    }

    private func deleteSelected() {
        guard let id = selection else { return }
        let items = visible
        let index = items.firstIndex { $0.id == id }
        watcher.remove(id)
        let remaining = watcher.history.filtered(by: query)
        selection = remaining.isEmpty ? nil : remaining[min(index ?? 0, remaining.count - 1)].id
    }
}
