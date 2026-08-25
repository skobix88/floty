import AppKit
import SwiftUI

/// Contents of the floating panel: header, tabs, editor or preview, footer.
struct PanelView: View {
    let store: NoteStore
    @Bindable var settings: AppSettings
    let onClose: () -> Void
    let onOpenSettings: () -> Void

    @State private var showsPreview = false
    @State private var noteToDelete: NoteFile?
    @State private var errorMessage: String?

    private var activeNote: NoteFile? {
        if let name = settings.activeNoteName,
           let match = store.notes.first(where: { $0.name == name }) {
            return match
        }
        return store.notes.first
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            TabBarView(
                store: store,
                settings: settings,
                activeNote: activeNote,
                onSelect: { settings.activeNoteName = $0.name },
                onDelete: { noteToDelete = $0 }
            )
            content
            FooterView(
                showsPreview: $showsPreview,
                canAct: activeNote != nil,
                onCopy: copyNote,
                onDelete: { noteToDelete = activeNote }
            )
        }
        .background {
            ZStack {
                VisualEffectBackground()
                Color(white: 0.12).opacity(settings.panelOpacity)
            }
            .ignoresSafeArea()
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .preferredColorScheme(.dark)
        .alert(
            String(localized: "Die Notiz ließ sich nicht in den Papierkorb legen."),
            isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
        ) {
            Button(String(localized: "Abbrechen"), role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .confirmationDialog(
            String(localized: "Notiz in den Papierkorb legen?"),
            isPresented: Binding(get: { noteToDelete != nil }, set: { if !$0 { noteToDelete = nil } }),
            presenting: noteToDelete
        ) { note in
            Button(String(localized: "In den Papierkorb"), role: .destructive) { delete(note) }
            Button(String(localized: "Abbrechen"), role: .cancel) { noteToDelete = nil }
        } message: { note in
            Text(String(localized: "\u{201E}\(note.name)\u{201C} landet im Papierkorb und lässt sich von dort zurückholen."))
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            Text("Floty")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(white: 0.92))

            Spacer(minLength: 8)

            Button(action: onOpenSettings) {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color(white: 0.62))
            .help(String(localized: "Einstellungen"))

            Toggle(isOn: $settings.isPinned) {
                Image(systemName: settings.isPinned ? "pin.fill" : "pin")
            }
            .toggleStyle(.button)
            .buttonStyle(.plain)
            .foregroundStyle(Color(white: settings.isPinned ? 0.95 : 0.62))
            .help(settings.isPinned
                  ? String(localized: "Loslösen – Panel blendet sich beim Klick außerhalb aus")
                  : String(localized: "Festpinnen – Panel bleibt über allen Fenstern"))

            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color(white: 0.62))
            .help(String(localized: "Schließen"))
        }
        .imageScale(.large)
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if let note = activeNote {
            Group {
                if showsPreview {
                    PreviewView(markdown: store.text(for: note.id))
                } else {
                    MarkdownEditor(text: Binding(
                        get: { store.text(for: note.id) },
                        set: { store.setText($0, for: note.id) }
                    ))
                }
            }
            .padding(.horizontal, 8)
            .id(note.id)
        } else {
            VStack {
                Spacer()
                Text("Keine Notiz vorhanden.")
                    .foregroundStyle(Color(white: 0.55))
                Spacer()
            }
        }
    }

    // MARK: - Actions

    private func copyNote() {
        guard let note = activeNote else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(store.text(for: note.id), forType: .string)
    }

    private func delete(_ note: NoteFile) {
        noteToDelete = nil
        let index = store.notes.firstIndex(where: { $0.id == note.id }) ?? 0
        do {
            try store.moveToTrash(note.id)
        } catch {
            // Never swallow this: a delete that quietly does nothing is worse
            // than one that fails loudly.
            errorMessage = error.localizedDescription
            return
        }
        settings.noteOrder = store.preferredOrder
        settings.activeNoteName = ActiveNote.afterDeletion(
            of: note.name,
            at: index,
            remaining: store.notes.map(\.name),
            current: settings.activeNoteName
        )
    }
}
