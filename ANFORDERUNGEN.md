# Floty — Anforderungen

**Untertitel:** *your floating notes* · **Kurzform:** Floty — quick thoughts

## 0. Grundidee

Floty ist eine leichte, kleine und unaufdringliche macOS-Anwendung, mit der sich
schnell Gedanken, Textideen, Notizen und kurze Textschnipsel festhalten lassen.

Sie soll sich bewusst nicht wie eine klassische Notiz-App anfühlen, sondern wie
ein **digitaler Schmierzettel**, der jederzeit schnell erreichbar ist.

> Floty soll nicht im Weg sein. Es soll einfach da sein, wenn ein Gedanke schnell
> aufgeschrieben werden muss.

Design-Referenz: [Panel](docs/panel.png) und [Einstellungen](docs/einstellungen.png).

Zielplattform: **macOS 26** und neuer, Apple Silicon und Intel. Beide Macs des
Nutzers liegen darüber, die Untergrenze bleibt also.

---

## 1. Fenster und Bedienung

- Ein einzelnes schwebendes Panel, frei verschiebbar, per Ziehen in der Größe
  veränderbar. Position und Größe überleben Neustarts.
- Leicht transparent, Transparenz stufenlos einstellbar von durchscheinend bis
  deckend. Die Untergrenze ist so gesetzt, dass Text lesbar bleibt.
- Dunkle Farbgebung, zwei Familien zur Wahl: Neutralgrau und Mitternachtsblau
  `#171E30`. Kein Hell-Modus.
- **Pin-Knopf** oben rechts löst den Widerspruch zwischen „immer im Vordergrund"
  und „beim Klick außerhalb schließen":
  - *ungepinnt* — das Panel blendet sich aus, sobald woanders hingeklickt wird
  - *gepinnt* — das Panel bleibt über allen anderen Anwendungen sichtbar
- Beim Tippen bleibt die darunterliegende Anwendung aktiv (nonactivating Panel).
- Kein Dock-Symbol, kein Eintrag in Cmd-Tab.

## 2. Menüleiste und Startverhalten

Floty lebt in der macOS-Menüleiste.

- Klick auf das Menüleisten-Icon blendet das Panel ein und aus.
- Einstellbarer globaler Hotkey für dieselbe Aktion (Vorgabe wie im Screenshot: ⌃⌥⌘N).
- Einstellungen über das Menüleisten-Icon erreichbar, zusätzlich per ⌘,.
  Bewusst kein Knopf im Panel — der Zettel soll nichts zeigen, was man einmal
  im Jahr braucht.
- Optionaler Start bei macOS-Login.

## 3. Schreiben und Formatierung

Der Editor zeigt **Markdown mit Live-Styling**: die Marker bleiben als blasser
Text im Dokument stehen, werden aber gleichzeitig angewendet — `**fett**`
erscheint fett, die Sternchen bleiben sichtbar. Damit ist die Datei exakt das,
was auf dem Bildschirm steht; es gibt keine verlustbehaftete Umwandlung.

Quick Formatting per Shortcut auf der Auswahl:

| Format | Shortcut | Markdown |
|---|---|---|
| Fett | ⌘B | `**Text**` |
| Kursiv | ⌘I | `*Text*` |
| Durchgestrichen | ⌘⇧X | `~~Text~~` |
| Checkbox | ⌘⇧L | `- [ ] ` |

Durchstreichen muss auch unabhängig von Checkboxen möglich sein.

## 4. Aufzählungen und Checklisten

- **Nummerierte Listen:** Enter nach `1. Erster Punkt` erzeugt `2. `.
  Enter auf einer leeren Listenzeile beendet die Liste, statt sie fortzusetzen.
- **Checkboxen:** Enter nach `- [ ] Aufgabe` erzeugt eine neue `- [ ] `-Zeile.
- **Darstellung:** `- [ ]` und `- [x]` werden als anklickbares ☐ / ☑ gezeichnet.
  Das ist die einzige Ausnahme von der Regel „Marker bleiben sichtbar" — ein
  Kästchen muss klickbar sein.
- Ist eine Checkbox aktiviert, wird der Text dahinter automatisch durchgestrichen
  dargestellt. Diese Durchstreichung ist reine Darstellung und steht nicht als
  `~~` in der Datei.
- **In der Datei** steht immer Standard-Markdown `- [ ]` / `- [x]`, nie Unicode-
  Zeichen. Nur so erkennt Obsidian echte Aufgaben und GitHub rendert sie.

## 5. Tabs

Eine Floty-Instanz enthält mehrere Notizen als Tabs. Ein Tab entspricht genau
einer `.md`-Datei; der Tabname ist der Dateiname.

- Neue Notiz per `+` hinzufügen — sie heißt „Notiz", „Notiz 2" und so weiter
  und lässt sich sofort umbenennen
- Tab umbenennen per Doppelklick auf den Reiter (benennt die Datei mit um)
- Tab nach links oder rechts verschieben
- Tab löschen — nach Rückfrage in den Papierkorb, nie endgültig
- Zwischen Notizen wechseln

Reihenfolge und zuletzt aktiver Tab werden gerätelokal gemerkt, nicht im
Notizordner abgelegt.

## 6. Speichern, Export, Teilen

- **Speichern** geschieht automatisch: entprellt nach der letzten Taste und beim
  Ausblenden des Panels. Kein Speichern-Knopf.
- **Ablageort:** ein vom Nutzer gewählter Ordner, vorgeschlagen wird ein Ordner
  in iCloud Drive. Die Dateien sind im Finder sichtbar und mit jedem beliebigen
  Editor lesbar.
- **Kopieren:** gesamter Notiztext in die Zwischenablage.
- **Vorschau:** Umschalten zwischen Editor und gerenderter Markdown-Ansicht.
  In der Vorschau verschwinden die Marker; sie ist nicht bearbeitbar.
- **Export** als `.md` an einen beliebigen Ort.
- **Teilen** über das macOS Share Sheet.

## 7. Synchronisation

Die Notizen liegen in einem iCloud-Drive-Ordner; die Synchronisation übernimmt
macOS. Floty selbst synchronisiert nicht und geht nie ins Netz.

Damit ist Floty auf mehreren eigenen Macs nutzbar. Legt iCloud Drive bei einem
Konflikt eine zweite Datei an, taucht sie in Floty als zusätzlicher Tab auf.

## 8. Obsidian

Ziel: **Floty zum schnellen Erfassen → Obsidian zur dauerhaften Ablage.**

„An Obsidian übergeben" schreibt die Notiz als `.md` in einen in den
Einstellungen festgelegten Vault-Ordner und ruft anschließend `obsidian://open`
auf. Danach wird angeboten, den Tab zu schließen — der Gedanke ist
weitergereicht und hier erledigt.

## 9. Einstellungen

**Darstellung:** Farbton (Neutralgrau / Mitternachtsblau)
**Fenster:** Transparenz (stufenlos) · immer im Vordergrund · beim Klick
außerhalb schließen (nur wirksam, solange nicht festgepinnt)
**Verhalten:** Start bei Login · globaler Kurzbefehl
**Ablage:** Notizordner · Obsidian-Vault-Ordner
**Sprache:** folgt der Systemsprache (Deutsch und Englisch)
**Version:** wird unten im Einstellungsfenster angezeigt

Die Fenstergröße wird nicht eingestellt, sondern gezogen — und gemerkt. Ist die
gemerkte Position auf keinem vorhandenen Bildschirm mehr erreichbar, öffnet
Floty wieder an seinem Standardplatz.

## 10. Icon

Ein Klemmbrett-Umriss auf dunkler, gerundeter Kachel — passend zur festen
dunklen Farbgebung. Quelle: `Resources/AppIcon.svg` von Zlatko Najdenovski,
Lizenz CC Attribution; die Namensnennung ist Pflicht. Der Symbolsatz wird mit
`scripts/make-icon.swift` erzeugt, damit er aus der Quelle reproduzierbar bleibt.

## 11. Veröffentlichung, Versionierung, Verteilung

- Öffentliches GitHub-Repository mit Quellcode, README, Dokumentation der
  wichtigsten Funktionen und Release-Historie.
- Fertige App-Versionen als `.dmg` über GitHub Releases.
- **Semantic Versioning** `MAJOR.MINOR.PATCH`, Vorabversionen als
  `1.0.0-beta.1` / `1.0.0-rc.1`.
- Release-Ablauf: entwickeln → Version setzen → CHANGELOG → Git-Tag →
  GitHub Release → `.dmg` anhängen.
- **Signierung:** zunächst ad-hoc, ohne bezahlten Developer-Account. Auf einem
  zweiten eigenen Mac einmal pro Version über Rechtsklick → Öffnen freigeben.
  Der Release-Ablauf ist so gebaut, dass Developer ID und Notarisierung später
  ohne Umbau ergänzt werden können.

---

## Design-Ziel

Floty soll sich anfühlen wie: klein, schnell, leicht, unaufdringlich,
minimalistisch, immer verfügbar — und ausdrücklich nicht wie ein überladenes
Notizprogramm.

---

## Nicht in 1.0

Siehe [TODO.md](TODO.md): automatisches Leeren nach X Tagen, Volltextsuche über
alle Tabs, Hell-/Dunkelmodus, Developer ID + Notarisierung, automatische Updates.
