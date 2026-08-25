import SwiftUI

/// Contents of the floating panel: header, tab strip, editor.
struct PanelView: View {
    let store: NoteStore
    @Bindable var settings: AppSettings
    let onClose: () -> Void

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
            tabStrip
            editor
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
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            Text("Floty")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(white: 0.92))
                .lineLimit(1)

            Spacer(minLength: 8)

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

    // MARK: - Tabs

    private var tabStrip: some View {
        HStack(spacing: 6) {
            if let note = activeNote {
                Text(note.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color(white: 0.95))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(red: 0.20, green: 0.30, blue: 0.48),
                                in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 6)
    }

    // MARK: - Editor

    @ViewBuilder
    private var editor: some View {
        if let note = activeNote {
            MarkdownEditor(text: Binding(
                get: { store.text(for: note.id) },
                set: { store.setText($0, for: note.id) }
            ))
            .padding(.horizontal, 8)
            .padding(.bottom, 10)
        } else {
            VStack {
                Spacer()
                Text("Keine Notiz vorhanden.")
                    .foregroundStyle(Color(white: 0.55))
                Spacer()
            }
        }
    }
}
