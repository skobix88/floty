# Changelog

Format nach [Keep a Changelog](https://keepachangelog.com/de/1.1.0/),
Versionierung nach [Semantic Versioning](https://semver.org/lang/de/).

## [1.0.0-rc.1] – 2026-08-26

Erste vollständige Fassung, als Vorabversion zum Ausprobieren.

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

- M3: Übergabe an Obsidian, Export als `.md`, Teilen über das Share Sheet und
  ein App-Icon, das mit `scripts/make-icon.swift` aus der SVG-Vorlage erzeugt wird.

### Geändert

- Die Bedien-Symbole sind kleiner und blasser, damit der Text führt.
- Die Einstellungen sitzen im Menüleisten-Menü; das Zahnrad im Panel ist
  entfallen. ⌘, öffnet sie weiterhin.
- Zusätzlich zum Neutralgrau gibt es Mitternachtsblau `#171E30`, umschaltbar in
  den Einstellungen. Die Version steht dort jetzt ebenfalls.
- Der Farbton färbt jetzt die ganze Fläche statt nur die Registerkarten: er
  liegt volldeckend unter dem Regler, statt mit dessen Deckkraft über dem
  Weichzeichner zu liegen.
- Der Transparenzregler reicht deutlich weiter ins Durchscheinende
  (Untergrenze von 0,45 auf 0,08).

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
- Der gewählte Obsidian-Vault las sich als „noch nicht gewählt" zurück: die
  Lesezeichen wurden mit `.withSecurityScope` erzeugt, was ohne Sandbox nicht
  wieder auflösbar ist. Zusätzlich waren die Ordner berechnete Eigenschaften und
  damit für `@Observable` unsichtbar.
- Das Menüleisten-Symbol war ein Systemsymbol statt Flotys eigenem Zeichen.

- MIT-Lizenz und `scripts/release.sh`: baut, prüft, packt ein `.dmg` und legt
  auf ausdrückliche Anweisung Git-Tag und GitHub Release an.
