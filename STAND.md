# Floty — Umsetzungsstand

Was gebaut ist, wie es geprüft wurde, und warum es so entschieden wurde.

**Stand: 25.08.2026 — M1 und M2 gebaut, 62 Prüfungen laufen durch.**

---

## Umsetzung je Meilenstein

### M1 — Es schreibt sich · gebaut

| Baustein | Datei | Stand |
|---|---|---|
| Menüleisten-Icon, Links-Klick schaltet um, Rechts-Klick öffnet Menü | `App/MenuBarController.swift` | Eintrag in der laufenden App nachgewiesen (Fensterrahmen in der Menüleiste), Klickwege nur kompiliert |
| Globaler Hotkey ⌃⌥⌘N | `App/HotKeys.swift` | vom Nutzer im Betrieb bestätigt |
| Nonactivating Panel, verschiebbar, größenveränderbar, Position gemerkt | `Panel/FlotyPanel.swift`, `Panel/PanelController.swift` | in der laufenden App bestätigt (sichtbar, richtige Größe, richtige Ebene) |
| Pin-Knopf und Ausblenden bei Klick außerhalb | `Panel/PanelController.swift`, `Panel/PanelView.swift` | Pin vom Nutzer im Betrieb bestätigt, Ausblenden bei Klick außerhalb nur kompiliert |
| Transparenz (Blur + dunkle Platte darüber) | `Panel/VisualEffectBackground.swift` | gebaut, nur kompiliert |
| Notizordner, Standard iCloud Drive | `Storage/FolderAccess.swift` | gebaut, automatisiert geprüft |
| Fensterplatzierung gegen verschwundene Bildschirme | `Panel/PanelPlacement.swift` | automatisiert geprüft |
| Autosave als `.md`, entprellt, atomar, `NSFileCoordinator` | `Storage/NoteStore.swift` | automatisiert geprüft |
| Live-Styling fett/kursiv/durchgestrichen/Code/Überschrift | `Editor/MarkdownHighlighter.swift` | automatisiert geprüft |
| Checkboxen: gezeichnetes Kästchen, Klick schaltet um, Durchstreichung | `Editor/MarkdownHighlighter.swift`, `Editor/TaskToggle.swift` | automatisiert geprüft und vom Nutzer im Betrieb bestätigt |
| Listenfortsetzung bei Enter | `Editor/ListContinuation.swift` | automatisiert geprüft und vom Nutzer im Betrieb bestätigt |
| Formatierungs-Shortcuts ⌘B / ⌘I / ⌘⇧X / ⌘⇧L | `Editor/InlineFormatting.swift` | Logik automatisiert geprüft, Tastenweg nur kompiliert |

**Offen aus M1:** noch nichts von Hand nachgestellt — siehe „Was noch nicht
belegt ist" weiter unten.

### M2 — Es ist bedienbar · gebaut

| Baustein | Datei | Stand |
|---|---|---|
| Tabs anlegen, wechseln, umbenennen (Doppelklick), löschen | `Panel/TabBarView.swift` | gebaut, nur kompiliert |
| Tab-Reihenfolge nach links/rechts, überlebt Neustarts | `Storage/NoteOrder.swift` | automatisiert geprüft |
| Fußleiste: Vorschau, Kopieren, Papierkorb mit Rückfrage | `Panel/FooterView.swift` | gebaut, nur kompiliert |
| Vorschau ohne Marker | `Markdown/PreviewRenderer.swift` | automatisiert geprüft |
| Einstellungsfenster: Transparenz, Pin, Klick-außerhalb, Login-Start, Hotkey, Notizordner, Vault | `Settings/SettingsView.swift` | gebaut, nur kompiliert |
| Start bei Login über `SMAppService` | `Settings/LoginItem.swift` | gebaut, nur kompiliert |
| Ordnerwechsel im laufenden Betrieb | `Panel/PanelController.swift` | gebaut, nur kompiliert |
| Oberfläche deutsch und englisch | `Resources/Localizable.xcstrings` | im gebauten Bündel nachgewiesen (`de.lproj`, `en.lproj`) |

**Installation:** `scripts/install.sh` baut Release und legt die App nach
`/Applications`. Vorgezogen aus M4, weil eine App im Build-Ordner sich nicht über
„Programme" starten lässt — nach dem ersten Beenden war Floty sonst weg.

### M3 — Es geht raus · offen

Export als `.md`, Share Sheet, Obsidian-Übergabe, App-Icon.

### M4 — Es wird verteilt · offen

GitHub-Repo, README, `scripts/release.sh`, `.dmg`, Semantic Versioning → 1.0.0.

---

## Entwurfsentscheidungen und ihr Warum

### Nativ Swift statt Tauri oder Electron

Genau die Funktionen, die Floty ausmachen — nonactivating Panel,
Menüleisten-Icon, Share Sheet, globaler Hotkey, iCloud-Ordner — sind nativ ohne
Fremdbibliotheken erreichbar und in jedem Web-Rahmenwerk mühsam nachzubauen.
Dazu kommt die Größenordnung: rund 5–10 MB statt 150 MB, was zum erklärten Ziel
„klein, schnell, leicht" gehört.

*Verworfen:* Tauri (Reibung bei genau den nativen Funktionen), Electron
(widerspricht dem Kerngedanken).

### Live-Styling statt WYSIWYG oder reinem Rohtext

Die Datei ist exakt das, was im Editor steht. Kein Umwandlungsschritt zwischen
Rich Text und Markdown, damit auch keine kaputten Listen oder verlorenen
Formate — die klassische Fehlerquelle solcher Editoren.

*Verworfen:* reiner Rohtext mit Vorschau-Umschalter, weil die automatische
Durchstreichung erledigter Aufgaben (ausdrückliche Anforderung) im Editor
sichtbar sein muss. Voll-WYSIWYG, weil der Aufwand für einen Schmierzettel
nicht zu rechtfertigen ist.

### Checkboxen als `- [ ]` in der Datei, ☐ in der Anzeige

Die ursprüngliche Konzeptnotiz sah Unicode-Zeichen `☐`/`☑` direkt in der Datei
vor. Damit wären es für Obsidian bloße Textzeichen — keine Tasks, keine
Task-Abfragen, kein Abhaken drüben, und GitHub würde nichts rendern. Da die
Obsidian-Brücke ein Kernziel ist, gewinnt Standard-Markdown. Die gewünschte
Optik bleibt trotzdem erhalten, weil das Kästchen gezeichnet statt gespeichert
wird.

### Frei wählbarer Ordner statt iCloud-Container oder CloudKit

Ein Ordner, den macOS ohnehin synchronisiert, kostet kein Entitlement und damit
keinen bezahlten Developer-Account. Die Dateien bleiben im Finder sichtbar,
„Export" ist damit praktisch schon passiert, und der Ordner ließe sich sogar
direkt in einen Obsidian-Vault legen.

*Kompromiss, bewusst eingegangen:* iCloud Drive löst Konflikte durch Anlegen
einer zweiten Datei statt durch Zusammenführen. Floty zeigt eine neu
aufgetauchte Datei einfach als weiteren Tab. Für einen Schmierzettel, der auf
einem Mac zur Zeit bearbeitet wird, ist das ausreichend.

*Verworfen:* eigener iCloud-Dokumentcontainer und SwiftData+CloudKit — beide
erfordern den bezahlten Account, und CloudKit hätte Export, Obsidian-Übergabe
und Finder-Sichtbarkeit zu eigenständigen Baustellen gemacht.

### Datei in den Vault schreiben statt `obsidian://new`

Der URL-Weg müsste den gesamten Notiztext in eine URL packen — das bricht bei
längeren Notizen und Sonderzeichen. Das Schreiben der Datei funktioniert
außerdem, wenn Obsidian gerade nicht läuft, und lässt den Ablageort wählen.

### Pin-Knopf statt fester Entscheidung

Konzept („immer im Vordergrund") und Screenshot („beim Klick außerhalb
schließen") widersprachen sich. Der Pin-Knopf aus Screenshot 1 ist die
Auflösung: beide Verhaltensweisen, umschaltbar mit einem Klick.

### Kein App Sandbox

Floty ist nicht für den App Store gedacht. Ohne Sandbox entfallen Sonderwege bei
Ordnerzugriff und globalem Hotkey. Der Security-Scoped Bookmark für den
Notizordner wird trotzdem gespeichert, damit ein späterer Sandbox-Umzug nicht am
Datenzugriff scheitert. Hardened Runtime bleibt eingeschaltet, damit für die
Notarisierung später nur noch das Zertifikat fehlt — wirksam wird es allerdings
erst mit einem echten Zertifikat, siehe unten.

### Kästchen zeichnen, ohne die Datei zu verändern

Das Kernproblem: die Datei muss `- [ ] ` enthalten, der Editor soll ☐ zeigen.
Gelöst über den `NSTextContentStorage`-Delegaten von TextKit 2, der pro Absatz
eine eigene Darstellung liefern darf. Der Trick ist, dass die Ersetzung
**gleich lang** ist: aus den sechs Zeichen `- [ ] ` werden die sechs Zeichen
`  ☐   `. Damit stimmen Cursorpositionen, Auswahlbereiche und Klick-Trefferpunkte
weiterhin mit dem Rohtext überein — es gibt keine Abbildung zwischen zwei
Koordinatensystemen, die auseinanderlaufen könnte. Ein Test wacht darüber
(`Die Länge bleibt gleich`), und der Delegat verwirft eine Darstellung mit
abweichender Länge, statt sie zu benutzen.

*Verworfen:* `NSTextAttachment` — hätte ein Ersatzzeichen in den Textspeicher
gebracht und damit die Datei verfälscht. *Verworfen:* Marker sichtbar lassen und
nur einfärben — wäre einfacher gewesen, hätte aber die zugesagte Optik nicht
geliefert.

### `@main` auf dem Delegaten startet eine AppKit-App nicht

Der erste Startversuch ergab einen laufenden Prozess ohne jedes Fenster und ohne
jede Ausgabe. Ursache: `@main` auf einer `NSApplicationDelegate`-Klasse ruft
`NSApplicationMain` auf, und das holt sich den Delegaten aus der Haupt-NIB-Datei.
Floty hat keine NIB, also wurde der Delegat nie verbunden und
`applicationDidFinishLaunching` nie ausgeführt — lautlos, ohne Fehlermeldung.

Behoben mit einem eigenen Einstiegspunkt in `App/Main.swift`, der `NSApp.delegate`
selbst setzt. Wichtig dabei: `NSApplication.delegate` ist eine schwache Referenz,
der Delegat muss also anderswo festgehalten werden. Zusätzlich steht jetzt
`NSPrincipalClass` in der `Info.plist`.

### Eine gemerkte Fensterposition darf nicht unerreichbar machen

Beim Nachstellen landete das Panel wiederholt auf dem zweiten Bildschirm und war
damit praktisch verschwunden. `Panel/PanelPlacement.swift` prüft deshalb vor dem
Anzeigen, ob ein brauchbares Stück des gemerkten Rahmens (mindestens 160×90 pt)
auf einem vorhandenen Bildschirm liegt; sonst greift die Standardposition. Neu
geöffnet wird außerdem auf dem Bildschirm, auf dem der Mauszeiger steht, nicht
auf dem, den AppKit gerade „main" nennt. `isRestorable` ist aus, damit macOS'
eigene Fensterwiederherstellung nicht dagegen arbeitet.

Reine Geometrie, ohne AppKit-Zustand — deshalb vollständig automatisiert geprüft,
einschließlich des Falls „zweiter Bildschirm abgezogen".

### Ein Scanner für Inline-Marker, zwei Verwendungen

Editor und Vorschau müssen sich darüber einig sein, was als Hervorhebung zählt —
sonst sieht die Vorschau anders aus als das, was man geschrieben hat.
`Markdown/MarkdownSpans.swift` findet die Bereiche, der Editor blendet die Marker
blass ein, die Vorschau wirft sie weg. Der Highlighter benutzt seit M2 denselben
Scanner statt einer eigenen Kopie der Ausdrücke.

Die Vorschau ist bewusst die einzige Stelle, an der Text *nicht* eins zu eins mit
der Datei ist. Das ist ungefährlich, weil sie nicht bearbeitbar ist.

### Tab-Reihenfolge über Namen, nicht über Kennungen

Kennungen leben nur so lange wie der Programmlauf; die Reihenfolge muss einen
Neustart überstehen. Sie wird deshalb als Liste von Notiznamen in `UserDefaults`
gehalten. Eine Notiz, die über iCloud dazukommt, während Floty zu war, steht in
dieser Liste nicht — sie landet darum berechenbar am Ende statt irgendwo in der
Mitte. Der Notizordner bleibt frei von Floty-eigenen Dateien und damit
Obsidian-tauglich.

### Das Panel öffnet auf dem Bildschirm mit der Menüleiste

Zuerst probiert und wieder verworfen: der Bildschirm, auf dem der Mauszeiger
steht. Das klingt freundlicher, hängt aber davon ab, wo der Zeiger zufällig
liegt — im Betrieb erschien das Panel dadurch auf einem zweiten Display, auf das
der Nutzer nicht schaut. `NSScreen.main` taugt ebenfalls nicht, das bedeutet
„hat das Tastaturfenster". Genommen wird `NSScreen.screens[0]`, der Bildschirm
mit der Menüleiste — dort, wo eine Menüleisten-App hingehört.

### Ad-hoc-Signierung schaltet Hardened Runtime ab

`ENABLE_HARDENED_RUNTIME: YES` steht in `project.yml`, Xcode meldet beim Bauen
aber „Disabling hardened runtime with ad-hoc codesigning". Das ist erwartet:
Hardened Runtime braucht ein echtes Zertifikat. Die Einstellung bleibt trotzdem
stehen, damit sie mit dem Developer-ID-Zertifikat sofort greift, ohne dass
jemand daran denken muss.

### XcodeGen statt gepflegter `.xcodeproj`

Die Projektstruktur liegt als lesbare YAML vor. Damit lassen sich Ziele,
Dateien, Entitlements und Build-Einstellungen zuverlässig ändern, ohne in
Apples Projektformat zu operieren, und die erzeugte `.xcodeproj` bleibt aus dem
Git heraus. Xcode wird ganz normal benutzt.

*Verworfen:* Tuist — für ein Ziel-Target ohne Gegenwert.

### macOS 26 als Untergrenze

Auf Wunsch des Nutzers. Erlaubt die neuesten SwiftUI-Bausteine ohne
Rückfallpfade. **Konsequenz:** der zweite Mac muss ebenfalls auf macOS 26
laufen, sonst ist die Untergrenze neu zu entscheiden.

---

## Prüfung

**62 Prüfungen in 9 Gruppen, alle grün** (`xcodebuild test`, Swift Testing).
Das Testschema setzt `FLOTY_TESTING=1`; `NoteStore` nimmt dann nur noch Ordner
unterhalb des Temp-Verzeichnisses an, und der `AppDelegate` überspringt beim
Start seine gesamte Einrichtung — sonst würde der Test-Host den echten
Notizordner öffnen.

| Gruppe | Deckt ab |
|---|---|
| Zeilen-Parser | Aufzählung, nummerierte Liste, Einrückung, offene/erledigte Aufgabe, großes `X`, unvollständige Marker, leere Listenelemente |
| Enter in Listen | Fortsetzen, Hochzählen, Liste beenden, Cursor mitten in der Zeile, zweite Zeile |
| Checkboxen umschalten | Hin und zurück, richtige Zeile bei mehreren, Durchstreichbereich |
| Schnellformatierung | Einfassen, leere Auswahl, Marker innerhalb und außerhalb der Auswahl entfernen, Zeilen zu Aufgaben und zurück, gemischte Auswahl |
| Hervorhebung | **Längengleichheit** der Darstellung, gezeichnetes Kästchen, Durchstreichung nur bei erledigt, echte Schriftschnitte, Marker bleiben sichtbar, unvollständige Marker, Überschrift |
| Fensterplatzierung | Standardposition, fehlende gemerkte Position, sichtbare Position bleibt, zweiter Bildschirm bleibt, abgezogener Bildschirm holt zurück, knappe Überlappung, leerer Rahmen |
| Tab-Reihenfolge | gemerkte Reihenfolge gewinnt, Unbekanntes hinten, verschwundene Namen stören nicht, natürliche Sortierung, Verschieben, Anschläge |
| Vorschau | Marker verschwinden, Formatierung bleibt, Überschriften, Aufgaben mit Durchstreichung, Aufzählungen, mehrere Zeilen, Formatierung in Aufgaben, unvollständige Marker, leerer Text |
| Notizablage | Testordner-Sperre, Schreiben/Wiedereinlesen, unveränderte Datei bleibt unangetastet, Umbenennen, Namenskonflikte, Schrägstriche im Namen, Papierkorb statt Löschen, Fremddatei wird Tab, Nicht-Markdown wird ignoriert |

### Was noch nicht belegt ist

Die App läuft ohne Dock-Symbol als Hintergrundprozess, hat die vorgelegte Notiz
geöffnet, ohne sie zu verändern (Prüfsumme und Zeitstempel unverändert), und das
Panel steht mit der erwarteten Größe an der erwarteten Stelle — über die
Fensterliste des Fenster-Servers nachgewiesen, nicht behauptet. Der
Menüleisten-Eintrag wird angelegt und meldet Bild, Breite und Sichtbarkeit.

**Nicht nachgestellt** sind alle Dinge, die sich nur am Bildschirm zeigen —
Bildschirmfotos scheiterten an der fehlenden Berechtigung „Bildschirmaufnahme"
für das Terminal:

1. Wie das gezeichnete Kästchen und die Abstände tatsächlich aussehen
2. Hotkey aus einer Vollbild-App heraus, ohne die darunterliegende App zu deaktivieren
3. Ausblenden bei Klick außerhalb
4. Transparenzstufen und Lesbarkeit
5. Wie gut das Menüleisten-Symbol bei sehr voller Leiste auffindbar ist — es
   wird nachweislich gesetzt (x≈247, 32×30 pt), die Platzierung entscheidet aber
   macOS, siehe TODO
6. Alle Bedienelemente aus M2: Tabs anlegen, umbenennen, verschieben, löschen,
   Fußleiste, Einstellungsfenster, Login-Start und Ordnerwechsel. Der Aufbau des
   Panels stürzt nicht ab, aber Menüs und Rückfragen zeigen sich erst beim
   Anklicken.
