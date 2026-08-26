import SwiftUI

/// The row of notes. One chip per note, plus adding and managing.
struct TabBarView: View {
    let store: NoteStore
    @Bindable var settings: AppSettings
    let activeNote: NoteFile?
    let onSelect: (NoteFile) -> Void
    let onDelete: (NoteFile) -> Void
    let onHandOverToObsidian: (NoteFile) -> Void

    @State private var renamingID: NoteFile.ID?
    @State private var draftName = ""
    @FocusState private var nameFieldFocused: Bool

    var body: some View {
        HStack(spacing: 6) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(store.notes) { note in
                        chip(for: note)
                    }
                }
                .padding(.vertical, 1)
            }

            Button(action: addNote) {
                Image(systemName: "plus")
            }
            .buttonStyle(.plain)
            .foregroundStyle(ControlStyle.idle)
            .help(String(localized: "Neue Notiz"))

            Menu {
                menuItems
            } label: {
                Image(systemName: "ellipsis")
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .foregroundStyle(ControlStyle.idle)
            .disabled(activeNote == nil)
        }
        .font(ControlStyle.icon(ControlStyle.tabSize))
        .padding(.horizontal, 14)
        .padding(.bottom, 6)
    }

    // MARK: - Chip

    @ViewBuilder
    private func chip(for note: NoteFile) -> some View {
        let isActive = note.id == activeNote?.id

        if renamingID == note.id {
            TextField("", text: $draftName)
                .textFieldStyle(.plain)
                .font(.system(size: 13, weight: .medium))
                .focused($nameFieldFocused)
                .frame(width: max(70, CGFloat(draftName.count) * 8 + 20))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(settings.tint.field, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                .onSubmit(commitRename)
                .onExitCommand { renamingID = nil }
                .onAppear { nameFieldFocused = true }
                // Clicking somewhere else has to end the rename too, otherwise
                // the chip stays a text field and the tab looks broken.
                .onChange(of: nameFieldFocused) { wasFocused, isFocused in
                    if wasFocused && !isFocused { commitRename() }
                }
        } else {
            Text(note.name)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color(white: isActive ? 0.95 : 0.70))
                .lineLimit(1)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    isActive ? settings.tint.chipActive : settings.tint.chipIdle,
                    in: RoundedRectangle(cornerRadius: 7, style: .continuous)
                )
                .contentShape(Rectangle())
                .onTapGesture(count: 2) { beginRename(note) }
                .onTapGesture { onSelect(note) }
                .contextMenu {
                    Button(String(localized: "Umbenennen")) { beginRename(note) }
                    Button(String(localized: "Löschen"), role: .destructive) { onDelete(note) }
                }
        }
    }

    @ViewBuilder
    private var menuItems: some View {
        if let note = activeNote {
            Button(String(localized: "Umbenennen")) { beginRename(note) }
            Divider()
            Button(String(localized: "An Obsidian übergeben")) { onHandOverToObsidian(note) }
            ShareLink(item: note.url) {
                Text(String(localized: "Teilen …"))
            }
            Divider()
            Button(String(localized: "Nach links")) { move(note, by: -1) }
                .disabled(store.notes.first?.id == note.id)
            Button(String(localized: "Nach rechts")) { move(note, by: 1) }
                .disabled(store.notes.last?.id == note.id)
            Divider()
            Button(String(localized: "Löschen"), role: .destructive) { onDelete(note) }
        }
    }

    // MARK: - Actions

    private func addNote() {
        let note = try? store.addNote(named: uniqueName())
        settings.noteOrder = store.preferredOrder
        if let note {
            onSelect(note)
            beginRename(note)
        }
    }

    /// "Notiz", "Notiz 2", "Notiz 3" - never collides, never asks first.
    private func uniqueName() -> String {
        let base = String(localized: "Notiz")
        let taken = Set(store.notes.map(\.name))
        guard taken.contains(base) else { return base }
        var index = 2
        while taken.contains("\(base) \(index)") { index += 1 }
        return "\(base) \(index)"
    }

    private func beginRename(_ note: NoteFile) {
        draftName = note.name
        renamingID = note.id
    }

    private func commitRename() {
        defer { renamingID = nil }
        guard let id = renamingID,
              let renamed = try? store.rename(id, to: draftName) else { return }
        settings.noteOrder = store.preferredOrder
        settings.activeNoteName = renamed.name
    }

    private func move(_ note: NoteFile, by offset: Int) {
        store.move(note.id, by: offset)
        settings.noteOrder = store.preferredOrder
    }
}
