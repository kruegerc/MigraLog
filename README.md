# MigraLog

MigraLog ist ein digitales Kopfschmerztagebuch. Das Repository enthält zwei Varianten:

- native iOS-/iPadOS-App mit SwiftUI und SwiftData
- Web-App/PWA für Smartphone und Desktop ohne App-Store-Verteilung

## MigraLog Web 1.0

Die Web-App liegt im Ordner `web` und ist für den dauerhaften privaten Einsatz ohne Apple-Developer-Kosten vorgesehen.

Nach aktivierter GitHub-Pages-Bereitstellung ist sie hier erreichbar:

```text
https://kruegerc.github.io/MigraLog/
```

- läuft im Browser
- kann auf dem iPhone zum Home-Bildschirm hinzugefügt werden
- speichert Daten lokal im Browser
- funktioniert nach dem ersten Laden offline
- bietet Tagebuch, Verlauf, Statistik, Export und Backup
- benötigt kein Benutzerkonto und kein Backend für Gesundheitsdaten

Dokumentation: [MigraLog Web 1.0](docs/WEB_APP.md)

## Native iOS-Version

Die native App ist als iPhone-/iPad-App vorbereitet und kann lokal über Xcode installiert werden.

### MVP-Umfang

- lokale Speicherung mit SwiftData
- Kopfschmerzepisode anlegen, anzeigen, bearbeiten und löschen
- daumenfreundliche Schnellerfassung mit den Bereichen `Basis` und `Details`
- farbige Intensitätsauswahl von 0 bis 10
- Schmerzart mit Auswahl für `Einseitig links` und `Einseitig rechts`
- Datum, Beginn, optionales Ende, Lokalisation, Symptome, Auslöser, Medikamente, Wirkung und Notizen
- chronologische Übersicht
- Verlauf nach Monat und Tag gruppiert
- Statistik mit Zeitraumfilter für `Alle`, `7 Tage`, `30 Tage`, `90 Tage`, `Dieses Jahr` und `Eigener Zeitraum`
- einfache Kennzahlen zu Anzahl, Kopfschmerztagen, durchschnittlicher Intensität und Dauer
- häufigste Symptome, Auslöser und Schmerzarten im gewählten Zeitraum
- PDF-Bericht für Arzttermine mit auswählbarem Zeitraum
- CSV-Rohdatenexport für Tabellenprogramme mit auswählbarem Zeitraum
- Einstellungsseite mit Datenschutz- und Medizin-Hinweis

### Version 1.0 Patiententest

Für den ersten Test auf einem echten iPhone gelten diese Dokumente:

- [iPhone-Installation](docs/IPHONE_INSTALLATION.md)
- [Patiententest 1.0](docs/PATIENT_TEST_1_0.md)
- [Release-Checkliste 1.0](docs/RELEASE_1_0_CHECKLIST.md)

### Technische Basis

- SwiftUI
- SwiftData
- Universal-App für iPhone und iPad
- Mindestversion: iOS 17.0 / iPadOS 17.0
- Unit-Test-Target und UI-Test-Target

### Build

Projekt in Xcode öffnen:

```sh
open MigraLog.xcodeproj
```

Danach das Scheme `MigraLog` auswählen und auf einem iPhone- oder iPad-Simulator starten.

## Datenschutzmodell

Die erste Version speichert Daten ausschließlich lokal auf dem Gerät. Es gibt kein Benutzerkonto, keine Werbung, keine Analyse-SDKs und keine automatische Weitergabe sensibler Gesundheitsdaten.

PDF- und CSV-Exporte werden nur lokal erzeugt und erst über den Teilen-Dialog beziehungsweise den Browser-Download weitergegeben, wenn der Nutzer dies bewusst auslöst.

MigraLog ersetzt keine medizinische Diagnose oder Behandlung. Bei starken, neuen oder ungewöhnlichen Beschwerden sollte medizinischer Rat eingeholt werden.
