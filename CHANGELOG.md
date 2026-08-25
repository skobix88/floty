# Changelog

Format nach [Keep a Changelog](https://keepachangelog.com/de/1.1.0/),
Versionierung nach [Semantic Versioning](https://semver.org/lang/de/).

## [Unveröffentlicht]

### Hinzugefügt

- Projektdokumentation: Anforderungen, Umsetzungsstand, offene Punkte.
- M1: schwebendes Panel in der Menüleiste, globaler Hotkey ⌃⌥⌘N, eine Notiz als
  Markdown-Datei mit automatischem Speichern, Live-Styling, klickbare
  Checkboxen, Listenfortsetzung und Formatierungs-Shortcuts.

### Behoben

- Die App startete lautlos ohne Fenster: `@main` auf dem Delegaten verbindet bei
  AppKit ohne NIB-Datei keinen Delegaten. Eigener Einstiegspunkt ergänzt.
- Eine gemerkte Fensterposition auf einem nicht mehr vorhandenen Bildschirm
  machte das Panel unerreichbar. Position wird vor dem Anzeigen geprüft.
