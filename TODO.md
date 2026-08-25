# Floty — Offene Punkte

## Nach 1.0 eingeplant

- **Automatisch leeren nach X Tagen** (Nie / 1 / 7 / 30 Tage, wie in
  [Screenshot](docs/einstellungen.png)). Ein Tab, der lange nicht bearbeitet
  wurde, leert sich selbst. Braucht ein Sicherheitsnetz: Papierkorb statt
  Löschen, plus Hinweis vor dem ersten Mal — sonst verstößt es gegen feste
  Regel 1 in `CLAUDE.md`.
- **Volltextsuche über alle Tabs.** Nicht dringend; lohnt erst, wenn sich viele
  Notizen ansammeln.
- **Hell-/Dunkelmodus folgt System.** 1.0 hat eine feste dunkle, neutrale Optik.
- **Developer ID + Notarisierung** (99 $/Jahr). Dann Installation per
  Doppelklick ohne Gatekeeper-Warnung, auch für Fremde.
- **Automatische Updates über Sparkle.** Setzt Notarisierung voraus.

## Zu klären

- GitHub-Kontoname und Repository-Name — spätestens zu M4.
- Lizenz für das öffentliche Repository. Übliche Wahl wäre MIT (jeder darf
  alles, Haftung ausgeschlossen). Muss vor der Veröffentlichung feststehen —
  ohne Lizenz gilt volles Urheberrecht, niemand darf den Code benutzen.
- App-Icon: die SVG-Vorlage aus Abschnitt 10 der Anforderungen liegt bisher nur
  als Weblink vor und muss in einen Icon-Satz überführt werden.
- Läuft der zweite Mac auf macOS 26? Wenn nein, ist die Mindestversion neu zu
  entscheiden (14 Sonoma kostet uns nichts).

## Aus dem Betrieb

- **M1 von Hand nachstellen.** Bildschirmfotos aus der Sitzung heraus scheitern
  an der fehlenden Berechtigung „Bildschirmaufnahme" für das Terminal. Zu prüfen:
  Aussehen des gezeichneten Kästchens und dessen Abstände, Hotkey aus einer
  Vollbild-App, Ausblenden bei Klick außerhalb, Pin, Transparenzstufen, Klick auf
  das Kästchen, Verschieben und Größe über einen Neustart hinweg.
  Abhilfe für künftige Sitzungen: Systemeinstellungen → Datenschutz & Sicherheit
  → Bildschirmaufnahme → Terminal erlauben.
- **Menüleisten-Symbol ist schwer zu finden.** Auf dem Entwicklungsrechner stehen
  rund 30 Einträge in der Leiste; macOS setzt Flotys Symbol deshalb an die
  äußerste linke Position der Symbolgruppe (x≈247), direkt neben den App-Menüs.
  Es ist da und anklickbar, fällt aber kaum auf, und eine App mit breiten Menüs
  kann es verdecken. Kein Fehler in Floty — die Platzierung entscheidet macOS.
  Zu überlegen: im Einstellungsfenster erwähnen, dass der Hotkey der
  zuverlässigere Weg ist.
