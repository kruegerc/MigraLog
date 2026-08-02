# MigraLog

MigraLog ist ein digitales Kopfschmerztagebuch fuer iPhone und iPad.

## MVP-Umfang

- lokale Speicherung mit SwiftData
- Kopfschmerzepisode anlegen, anzeigen, bearbeiten und loeschen
- Datum, Beginn, optionales Ende, Intensitaet, Schmerzart, Lokalisation, Symptome, Ausloeser, Medikamente, Wirkung und Notizen
- chronologische Uebersicht
- einfache Kennzahlen zu Anzahl, durchschnittlicher Intensitaet und Dauer
- Einstellungsseite mit Datenschutz- und Medizin-Hinweis

## Technische Basis

- SwiftUI
- SwiftData
- Universal-App fuer iPhone und iPad
- Mindestversion: iOS 17.0 / iPadOS 17.0
- Unit-Test-Target und UI-Test-Target

## Build

Projekt in Xcode oeffnen:

```sh
open MigraLog.xcodeproj
```

Danach das Scheme `MigraLog` auswaehlen und auf einem iPhone- oder iPad-Simulator starten.

## Datenschutzmodell

Die erste Version speichert Daten ausschliesslich lokal auf dem Geraet. Es gibt kein Benutzerkonto, keine Werbung, keine Analyse-SDKs und keine automatische Weitergabe sensibler Gesundheitsdaten.

MigraLog ersetzt keine medizinische Diagnose oder Behandlung. Bei starken, neuen oder ungewoehnlichen Beschwerden sollte medizinischer Rat eingeholt werden.
