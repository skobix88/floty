import SwiftUI

/// The row of icons along the bottom of the panel.
struct FooterView: View {
    @Binding var showsPreview: Bool
    let canAct: Bool
    let onCopy: () -> Void
    let onDelete: () -> Void

    @State private var copied = false

    var body: some View {
        HStack(spacing: 16) {
            Button { showsPreview.toggle() } label: {
                Image(systemName: showsPreview ? "eye.fill" : "eye")
            }
            .help(showsPreview
                  ? String(localized: "Zurück zum Bearbeiten")
                  : String(localized: "Vorschau"))

            Button(action: copy) {
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
            }
            .help(String(localized: "Notiz kopieren"))

            Spacer()

            Button(action: onDelete) {
                Image(systemName: "trash")
            }
            .help(String(localized: "Notiz in den Papierkorb legen"))
        }
        .buttonStyle(.plain)
        .imageScale(.large)
        .foregroundStyle(Color(white: 0.62))
        .disabled(!canAct)
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 12)
    }

    private func copy() {
        onCopy()
        copied = true
        Task {
            try? await Task.sleep(for: .seconds(1.2))
            copied = false
        }
    }
}
