# MigraLog MVP-Spezifikation

## Ziel

MigraLog hilft Betroffenen, Kopfschmerz- und Migraeneepisoden schnell zu dokumentieren und fuer Arztgespraeche nachvollziehbar auszuwerten.

## Zielgruppe

Menschen, die wiederkehrende Kopfschmerzen oder Migraene beobachten und Verlauf, Ausloeser, Symptome und Medikamentenwirkung lokal dokumentieren wollen.

## Plattform

- iPhone und iPad
- iOS/iPadOS 17 oder neuer
- keine Server-Komponente im MVP

## Kerndaten

Ein Eintrag enthaelt:

- eindeutige ID
- Beginn
- optionales Ende
- Schmerzintensitaet von 0 bis 10
- Schmerzarten
- Lokalisationen
- Begleitsymptome
- moegliche Ausloeser
- Medikamente
- Medikamentenwirkung
- Notiz
- Erstell- und Aenderungszeitpunkt

## MVP-Funktionen

1. Eintrag erfassen
2. Eintrag speichern
3. Eintraege chronologisch anzeigen
4. Eintrag im Detail anzeigen
5. Eintrag bearbeiten
6. Eintrag loeschen
7. Basisstatistiken anzeigen
8. Datenschutz- und Medizin-Hinweis anzeigen

## Nicht im MVP

- iCloud-Synchronisierung
- Benutzerkonto
- HealthKit
- Watch-App
- Widgets
- Push-Erinnerungen
- PDF-/CSV-Export
- App-Sperre per Face ID oder Touch ID

## Datenschutzannahmen

- Alle Daten bleiben lokal.
- Daten werden nur durch bewusste Nutzeraktion weitergegeben.
- Keine Analyse- oder Tracking-SDKs.
- Keine medizinische Diagnosefunktion.
