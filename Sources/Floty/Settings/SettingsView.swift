import AppKit
import KeyboardShortcuts
import SwiftUI
import UniformTypeIdentifiers

/// The settings window.
struct SettingsView: View {
    @Bindable var settings: AppSettings
    let clipboard: ClipboardWatcher?
    let onNotesFolderChanged: (URL) -> Void

    @State private var launchAtLogin = LoginItem.isEnabled
    @State private var loginError: String?
    @State private var showsClipboardWarning = false
    @State private var showsClearConfirmation = false

    var body: some View {
        Form {
            Section("Darstellung") {
                Picker("Farbton", selection: $settings.tint) {
                    ForEach(PanelTint.allCases) { tint in
                        Text(tint.name).tag(tint)
                    }
                }
                .pickerStyle(.segmented)
            }

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

            clipboardSection

            Section {
                LabeledContent("Version") {
                    Text(AppVersion.display)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 460)
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Zwischenablage

    @ViewBuilder
    private var clipboardSection: some View {
        Section("Zwischenablage") {
            Toggle("Verlauf der Zwischenablage", isOn: $settings.clipboardEnabled)
                .onChange(of: settings.clipboardEnabled) { _, enabled in
                    // Beim ersten Einschalten muss klar sein, was mitgeschrieben wird.
                    if enabled && !settings.clipboardWarningSeen {
                        showsClipboardWarning = true
                        settings.clipboardWarningSeen = true
                    }
                }
            Text("Floty merkt sich, was du kopierst, und legt es lokal ab. Als verborgen markierte Inhalte aus Passwortmanagern werden nie aufgenommen.")
                .font(.caption)
                .foregroundStyle(.secondary)

            if settings.clipboardEnabled {
                LabeledContent("Kurzbefehl") {
                    KeyboardShortcuts.Recorder(for: .toggleClipboard)
                }
                Toggle("Aufzeichnung pausieren", isOn: $settings.clipboardPaused)
                Stepper("Einträge: \(settings.clipboardMaxCount)",
                        value: $settings.clipboardMaxCount, in: 10...200, step: 10)
                Stepper("Platz höchstens: \(settings.clipboardMaxMegabytes) MB",
                        value: $settings.clipboardMaxMegabytes, in: 20...2000, step: 20)
                if let clipboard {
                    LabeledContent("Belegt") {
                        Text(ByteCountFormatStyle().format(Int64(clipboard.occupiedBytes())))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                excludedAppsRow
                Button("Verlauf leeren …", role: .destructive) { showsClearConfirmation = true }
            }
        }
        .alert(String(localized: "Der Verlauf zeichnet mit, was du kopierst."),
               isPresented: $showsClipboardWarning) {
            Button(String(localized: "Verstanden"), role: .cancel) {}
        } message: {
            Text(String(localized: "Kopierter Text und kopierte Bilder werden unverschlüsselt in deinem Benutzerordner abgelegt. Passwortmanager kennzeichnen ihre Inhalte, die nimmt Floty nicht auf — ein Passwort aus einer E-Mail trägt diese Kennzeichnung aber nicht."))
        }
        .confirmationDialog(String(localized: "Den gesamten Verlauf löschen?"),
                            isPresented: $showsClearConfirmation) {
            Button(String(localized: "Verlauf leeren"), role: .destructive) { clipboard?.clear() }
            Button(String(localized: "Abbrechen"), role: .cancel) {}
        } message: {
            Text(String(localized: "Alle Einträge und die dazugehörigen Bilddateien werden entfernt."))
        }
    }

    private var excludedAppsRow: some View {
        LabeledContent("Nicht aufzeichnen aus") {
            VStack(alignment: .trailing, spacing: 4) {
                ForEach(settings.clipboardExcludedApps, id: \.self) { identifier in
                    HStack(spacing: 6) {
                        Text(identifier)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button {
                            settings.clipboardExcludedApps.removeAll { $0 == identifier }
                        } label: {
                            Image(systemName: "minus.circle")
                        }
                        .buttonStyle(.plain)
                    }
                }
                Button("Programm hinzufügen …") { pickApp() }
            }
        }
    }

    private func pickApp() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(filePath: "/Applications")
        guard panel.runModal() == .OK,
              let url = panel.url,
              let identifier = Bundle(url: url)?.bundleIdentifier,
              !settings.clipboardExcludedApps.contains(identifier) else { return }
        settings.clipboardExcludedApps.append(identifier)
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
