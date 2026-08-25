# Floty – Projektkontext

Kleine macOS-App: schwebender Markdown-Schmierzettel in der Menüleiste, Tabs,
iCloud-Ordner, Obsidian-Übergabe. Swift/SwiftUI+AppKit, Ziel macOS 26,
eine Person, ein Target.

**Sprache:** UI de+en (String Catalog) · Code englisch · Doku und Commits deutsch.

---

## Zuerst lesen

`ANFORDERUNGEN.md` (Soll) · `STAND.md` (Ist, Prüfung, Warum, Meilensteine) ·
`TODO.md` (Offenes)

## Doku wird mitgepflegt

Eine Aufgabe ist erst fertig, wenn die betroffene Datei nachgezogen ist — ohne
Nachfrage. Funktion → ANFORDERUNGEN + STAND · Entwurfsentscheidung samt
verworfener Ansätze → STAND · Beobachtung aus dem Betrieb → TODO · neue feste
Regel oder Architektur → diese Datei. Veraltetes berichtigen, nicht anhäufen.

## Bauen und Prüfen

```bash
xcodegen generate
xcodebuild -project Floty.xcodeproj -scheme Floty -configuration Debug build
xcodebuild test -project Floty.xcodeproj -scheme Floty
```

Nach jeder neuen Quelldatei `xcodegen generate` — sonst wird sie nicht gebaut.
Geändert wird `project.yml`; die erzeugte `.xcodeproj` ist nicht im Git.

## Versionsverwaltung

Zweig `main`. Ein Commit je abgeschlossener Sache, Doku im selben Commit wie der
Code. Commit-Nachricht beantwortet das Warum, nicht das Was.

## Architektur

```
Sources/Floty/{App,Panel,Editor,Markdown,Storage,Integrations,Settings,Resources}
Tests/FlotyTests · scripts/release.sh · project.yml
```

- Kein App Sandbox (kein App Store), Hardened Runtime an, vorerst ad-hoc signiert.
- `LSUIElement` — kein Dock-Symbol. Das Panel ist ein nonactivating `NSPanel`:
  ungepinnt blendet es bei `resignKey` aus, gepinnt steht es auf `.floating`.
- Notizen: eine `.md` je Tab in einem vom Nutzer gewählten Ordner (Standard
  iCloud Drive). Sync macht macOS. Schreiben nur über `NSFileCoordinator`,
  atomar und entprellt.
- Tab-Reihenfolge und aktiver Tab in `UserDefaults` — der Notizordner bleibt
  frei von Fremddateien und damit Obsidian-tauglich.
- Einzige Abhängigkeit: `KeyboardShortcuts`. Login-Start über
  `SMAppService.mainApp`. Bewusst kein Markdown-Framework.

## Feste Regeln – nicht ohne Rückfrage ändern

1. Notizdateien werden nie ohne ausdrückliche Nutzeraktion gelöscht oder
   geleert. Löschen heißt Papierkorb, nicht `unlink`.
2. Standard-Markdown, verlustfrei: was in der Datei steht, steht im Editor.
   Checkboxen sind `- [ ]` / `- [x]`, nie Unicode-Zeichen.
3. Floty geht nie ins Netz und meldet nichts nach außen.
4. Notizordner, Vault-Ordner, Fensterposition, Größe, Transparenz und Hotkey
   überleben jede Aktualisierung.
5. Feste dunkle, neutrale Farbgebung. Kein Hell-Modus ohne Absprache.
6. Jede Prüfung ist eine dauerhafte Datei in `Tests/FlotyTests/`, nie ein
   Wegwerfprogramm in `/tmp` oder im Chat. Tests schreiben nie in den echten
   Notizordner: `NoteStore` verweigert ihn, wenn `FLOTY_TESTING=1` gesetzt ist.

## Arbeitsweise

- Prüfen statt behaupten — Verhalten in der laufenden App nachstellen.
- Beim Berichten unterscheiden: automatisiert nachgewiesen / angesehen / nur
  kompiliert. Bekannte Lücken unaufgefordert benennen.
- Begründungen gehören in Code und Doku, nicht in den Chatverlauf.
- Xcode-Fehlermeldungen wörtlich durchreichen. Ursache beheben, nicht Symptom.
