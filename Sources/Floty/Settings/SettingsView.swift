import KeyboardShortcuts
import SwiftUI

/// The settings window.
struct SettingsView: View {
    @Bindable var settings: AppSettings
    let onNotesFolderChanged: (URL) -> Void

    @State private var launchAtLogin = LoginItem.isEnabled
    @State private var loginError: String?

    var body: some View {
        Form {
            Section("Fenster") {
                VStack(alignment: .leading, spacing: 4) {
                    Slider(value: $settings.panelOpacity, in: AppSettings.minimumOpacity...1)
                    HStack {
                        Text("Durchscheinend").font(.caption).foregroundStyle(.secondary)
                        Spacer()
                        Text("Deckend").font(.caption).foregroundStyle(.secondary)
                    }
                }
                Toggle("Immer im Vordergrund", isOn: $settings.isPinned)
                Toggle("Beim Klick außerhalb schließen", isOn: $settings.hidesOnClickOutside)
                    .disabled(settings.isPinned)
                    .help(String(localized: "Gilt nur, solange das Panel nicht festgepinnt ist."))
            }

            Section("Verhalten") {
                Toggle("Start bei Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, enabled in setLaunchAtLogin(enabled) }
                if let loginError {
                    Text(loginError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                LabeledContent("Globaler Kurzbefehl") {
                    KeyboardShortcuts.Recorder(for: .togglePanel)
                }
            }

            Section("Ablage") {
                folderRow(
                    title: String(localized: "Notizordner"),
                    url: settings.notesFolder,
                    placeholder: String(localized: "Nicht gesetzt")
                ) { url in
                    settings.notesFolder = url
                    onNotesFolderChanged(url)
                }
                folderRow(
                    title: String(localized: "Obsidian-Vault"),
                    url: settings.vaultFolder,
                    placeholder: String(localized: "Noch nicht gewählt")
                ) { settings.vaultFolder = $0 }
            }
        }
        .formStyle(.grouped)
        .frame(width: 460)
        .fixedSize(horizontal: false, vertical: true)
    }

    private func folderRow(title: String,
                           url: URL?,
                           placeholder: String,
                           onPick: @escaping (URL) -> Void) -> some View {
        LabeledContent(title) {
            HStack(spacing: 8) {
                Text(url?.path(percentEncoded: false) ?? placeholder)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.head)
                Button("Ändern …") { pickFolder(startingAt: url, then: onPick) }
            }
        }
    }

    private func pickFolder(startingAt url: URL?, then onPick: @escaping (URL) -> Void) {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = url
        guard panel.runModal() == .OK, let chosen = panel.url else { return }
        onPick(chosen)
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        if let error = LoginItem.setEnabled(enabled) {
            // The switch has to bounce back, otherwise it would lie.
            launchAtLogin = LoginItem.isEnabled
            loginError = error.localizedDescription
        } else {
            loginError = nil
        }
    }
}
