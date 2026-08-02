# MigraLog

MigraLog ist ein digitales Kopfschmerztagebuch für iPhone und iPad.

## MVP-Umfang

- lokale Speicherung mit SwiftData
- Kopfschmerzepisode anlegen, anzeigen, bearbeiten und löschen
- daumenfreundliche Schnellerfassung mit den Bereichen `Basis` und `Details`
- farbige Intensitätsauswahl von 0 bis 10
- Schmerzart mit Auswahl für `Einseitig links` und `Einseitig rechts`
- Datum, Beginn, optionales Ende, Lokalisation, Symptome, Auslöser, Medikamente, Wirkung und Notizen
- chronologische Übersicht
- einfache Kennzahlen zu Anzahl, durchschnittlicher Intensität und Dauer
- PDF-Bericht für Arzttermine
- CSV-Rohdatenexport für Tabellenprogramme
- Einstellungsseite mit Datenschutz- und Medizin-Hinweis

## Technische Basis

- SwiftUI
- SwiftData
- Universal-App für iPhone und iPad
- Mindestversion: iOS 17.0 / iPadOS 17.0
- Unit-Test-Target und UI-Test-Target

## Build

Projekt in Xcode öffnen:

```sh
open MigraLog.xcodeproj
```

Danach das Scheme `MigraLog` auswählen und auf einem iPhone- oder iPad-Simulator starten.

## Datenschutzmodell

Die erste Version speichert Daten ausschließlich lokal auf dem Gerät. Es gibt kein Benutzerkonto, keine Werbung, keine Analyse-SDKs und keine automatische Weitergabe sensibler Gesundheitsdaten.

PDF- und CSV-Exporte werden nur lokal erzeugt und erst über den Teilen-Dialog weitergegeben, wenn der Nutzer dies bewusst auslöst.

MigraLog ersetzt keine medizinische Diagnose oder Behandlung. Bei starken, neuen oder ungewöhnlichen Beschwerden sollte medizinischer Rat eingeholt werden.
