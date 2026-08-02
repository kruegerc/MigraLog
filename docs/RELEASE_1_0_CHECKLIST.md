# Release-Checkliste MigraLog 1.0

## Stand

- Version: `1.0`
- Build: `1`
- Bundle Identifier: `com.claudiokrueger.MigraLog`
- Mindestversion: iOS 17 / iPadOS 17
- Zielgerät für den ersten Patiententest: iPhone 16
- Speicherung: lokal auf dem Gerät
- Ziel: erster realer Patiententest

## Projektprüfung für iPhone 16

- iPhone ist als Zielgerätefamilie aktiviert.
- `TARGETED_DEVICE_FAMILY = 1,2` ist gesetzt.
- `SUPPORTED_PLATFORMS = iphoneos iphonesimulator` ist gesetzt.
- `IPHONEOS_DEPLOYMENT_TARGET = 17.0` ist gesetzt.
- Es gibt keine Gerätegeneration, die iPhone 16 ausschließt.
- Es gibt keine Hardware-Abhängigkeit, die auf dem iPhone 16 fehlen würde.

## Vor Installation auf dem iPhone 16

- `main` ist lokal aktuell.
- Xcode öffnet `MigraLog.xcodeproj` ohne Projektfehler.
- Scheme `MigraLog` ist ausgewählt.
- Angeschlossenes iPhone 16 ist als Zielgerät sichtbar.
- `Automatically manage signing` ist aktiv.
- Apple-Team ist im Target `MigraLog` ausgewählt.
- iPhone 16 ist entsperrt und vertraut dem Mac.

## Technischer Smoke Test auf dem iPhone 16

- App startet.
- Neuer Eintrag kann gespeichert werden.
- App wird beendet und neu geöffnet.
- Gespeicherter Eintrag ist weiterhin sichtbar.
- Eintrag kann bearbeitet werden.
- Verlauf öffnet.
- Statistik öffnet.
- PDF-Export wird erzeugt.
- Teilen-Dialog öffnet.
- App kann ohne Datenverlust erneut gestartet werden.

## Fachlicher Smoke Test

- Eintrag mit hoher Intensität erfassen.
- Eintrag mit `Einseitig links` erfassen.
- Eintrag mit `Einseitig rechts` erfassen.
- Eintrag mit `Rizatriptan 10 mg` erfassen.
- Eintrag mit mehreren Symptomen und Auslösern erfassen.
- Eintrag mit eigenem Zeitraum in Statistik und Export prüfen.

## Bekannte Einschränkungen von 1.0

- Keine Cloud-Synchronisierung.
- Keine App-Sperre.
- Keine Erinnerungen.
- Kein App-Store- oder TestFlight-Prozess.
- App-Icon ist noch nicht final gestaltet.

## Freigabeentscheidung

Version 1.0 kann für den Patiententest genutzt werden, wenn der technische Smoke Test auf dem iPhone 16 erfolgreich ist.

Ein Git-Tag `v1.0.0` sollte erst gesetzt werden, nachdem die Installation und der technische Smoke Test auf dem iPhone 16 erfolgreich waren.
