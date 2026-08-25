# Changelog

Format nach [Keep a Changelog](https://keepachangelog.com/de/1.1.0/),
Versionierung nach [Semantic Versioning](https://semver.org/lang/de/).

## [Unveröffentlicht]

### Hinzugefügt

- Projektdokumentation: Anforderungen, Umsetzungsstand, offene Punkte.
- M1: schwebendes Panel in der Menüleiste, globaler Hotkey ⌃⌥⌘N, eine Notiz als
  Markdown-Datei mit automatischem Speichern, Live-Styling, klickbare
  Checkboxen, Listenfortsetzung und Formatierungs-Shortcuts.

- M2: mehrere Notizen als Tabs mit Anlegen, Umbenennen, Verschieben und
  Löschen in den Papierkorb; Fußleiste mit Vorschau, Kopieren und Löschen;
  Einstellungsfenster für Transparenz, Pin, Ausblendeverhalten, Start bei Login,
  globalen Kurzbefehl, Notiz- und Vault-Ordner; Oberfläche deutsch und englisch.

- `scripts/install.sh`: baut Release und installiert nach `/Applications`.

### Behoben

- Die App startete lautlos ohne Fenster: `@main` auf dem Delegaten verbindet bei
  AppKit ohne NIB-Datei keinen Delegaten. Eigener Einstiegspunkt ergänzt.
- Eine gemerkte Fensterposition auf einem nicht mehr vorhandenen Bildschirm
  machte das Panel unerreichbar. Position wird vor dem Anzeigen geprüft.
- Das Panel öffnete auf einem zweiten Display statt auf dem Bildschirm mit der
  Menüleiste.
- Beim Löschen verschwand das Panel samt Rückfrage, statt zu fragen. Das
  Ausblenden bei Fokusverlust prüft jetzt einen Durchlauf später, ob der Fokus
  wirklich zu einer anderen Anwendung gegangen ist.
- Ein fehlgeschlagenes Löschen blieb unsichtbar; es wird jetzt gemeldet.
- Eine Notiz im Hintergrund zu löschen sprang zum ersten Tab.
- Ein angefangenes Umbenennen blieb hängen, wenn man daneben klickte.
