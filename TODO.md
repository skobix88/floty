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

- **Tabs per Ziehen umsortieren.** Zurzeit geht das über das `…`-Menü mit
  „Nach links" und „Nach rechts". Ziehen wäre die gewohntere Geste, ist in
  SwiftUI aber deutlich aufwendiger — lohnt erst, wenn viele Tabs zusammenkommen.
- **Start bei Login prüfen.** `SMAppService` verweigert die Registrierung bei nur
  ad-hoc signierten Apps unter Umständen. Der Schalter springt dann zurück und
  zeigt die Meldung an; ob das im echten Release-Bündel funktioniert, ist erst
  mit Developer ID zu beurteilen.

- **Anheften von Dauereinträgen** im Zwischenablage-Verlauf. Meistgenutzte
  Funktion echter Zwischenablage-Programme, bewusst aus der ersten Fassung
  herausgehalten: sie zieht eine zweite Liste mit eigener Sortierung nach sich.
- **Automatisches Einfügen** nach der Auswahl. Bräuchte die Berechtigung
  „Bedienungshilfen" — Tastatursteuerung für alle Programme. Zu großes
  Zugeständnis für eine App, die sonst ohne Sonderrechte auskommt.

## Zu klären

- Wann aus `1.0.0-rc.1` die 1.0.0 wird — dafür sollten die Bedienwege, die in
  `STAND.md` noch als „nur kompiliert" stehen, einmal im Alltag gelaufen sein.
- Die Namensnennung für das Icon (CC Attribution, Zlatko Najdenovski) muss
  zusätzlich zur README auch in der fertigen App auftauchen — spätestens im
  „Über Floty“-Fenster, das es noch nicht gibt.

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
