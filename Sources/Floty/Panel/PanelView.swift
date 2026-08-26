import AppKit
import SwiftUI

/// Contents of the floating panel: header, tabs, editor or preview, footer.
struct PanelView: View {
    let store: NoteStore
    @Bindable var settings: AppSettings
    let onClose: () -> Void

    @State private var showsPreview = false
    @State private var noteToDelete: NoteFile?
    @State private var errorMessage: String?
    @State private var handedOver: NoteFile?

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
                onDelete: { noteToDelete = $0 },
                onHandOverToObsidian: handOver
            )
            content
            FooterView(
                showsPreview: $showsPreview,
                canAct: activeNote != nil,
                onCopy: copyNote,
                onExport: exportNote,
                onDelete: { noteToDelete = activeNote }
            )
        }
        .background {
            // Der Farbton deckt voll; durchsichtig wird die ganze Fläche.
            //
            // Vorher lag der Farbton als Platte mit der Deckkraft des Reglers
            // über dem Weichzeichner. Dessen Grau schien dann durch und wusch
            // den Ton aus - je durchscheinender, desto grauer. Jetzt steuert
            // der Regler Weichzeichner und Farbton gemeinsam: der Farbton
            // bleibt bei jeder Stufe genau der eingestellte.
            ZStack {
                VisualEffectBackground()
                settings.tint.base
            }
            .opacity(settings.panelOpacity)
            .ignoresSafeArea()
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .preferredColorScheme(.dark)
        .alert(
            String(localized: "Das hat nicht geklappt."),
            isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
        ) {
            Button(String(localized: "Verstanden"), role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .confirmationDialog(
            String(localized: "An Obsidian übergeben – Tab schließen?"),
            isPresented: Binding(get: { handedOver != nil }, set: { if !$0 { handedOver = nil } }),
            presenting: handedOver
        ) { note in
            Button(String(localized: "Tab schließen")) { delete(note) }
            Button(String(localized: "Behalten"), role: .cancel) { handedOver = nil }
        } message: { _ in
            Text(String(localized: "Die Notiz liegt jetzt im Vault. Der Gedanke ist weitergereicht."))
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

            Toggle(isOn: $settings.isPinned) {
                Image(systemName: settings.isPinned ? "pin.fill" : "pin")
            }
            .toggleStyle(.button)
            .buttonStyle(.plain)
            .foregroundStyle(settings.isPinned ? ControlStyle.active : ControlStyle.idle)
            .help(settings.isPinned
                  ? String(localized: "Loslösen – Panel blendet sich beim Klick außerhalb aus")
                  : String(localized: "Festpinnen – Panel bleibt über allen Fenstern"))

            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
            }
            .buttonStyle(.plain)
            .foregroundStyle(ControlStyle.idle)
            .help(String(localized: "Schließen"))
        }
        .font(ControlStyle.icon(ControlStyle.headerSize))
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

    private func exportNote() {
        guard let note = activeNote else { return }
        do {
            try NoteExport.save(text: store.text(for: note.id), named: note.name)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func handOver(_ note: NoteFile) {
        store.save(note.id)
        do {
            try ObsidianBridge.handOver(text: store.text(for: note.id),
                                        named: note.name,
                                        to: settings.vaultFolder)
            handedOver = note
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func delete(_ note: NoteFile) {
        noteToDelete = nil
        handedOver = nil
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
