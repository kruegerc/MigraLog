# MigraLog 1.0 auf einem iPhone installieren

Diese Anleitung beschreibt die Installation direkt aus Xcode auf ein echtes iPhone. Sie ist für den ersten Patiententest gedacht, nicht für eine App-Store-Veröffentlichung.

## Voraussetzungen

- Mac mit Xcode
- iPhone mit iOS 17 oder neuer
- USB-Kabel oder eingerichtetes Wireless Debugging
- Apple-ID in Xcode angemeldet
- aktueller Stand des Branches `main`

## Vorbereitung in Xcode

1. `MigraLog.xcodeproj` öffnen.
2. Links oben das Scheme `MigraLog` auswählen.
3. Als Zielgerät das angeschlossene iPhone auswählen.
4. In der Projektansicht `MigraLog` öffnen.
5. Target `MigraLog` auswählen.
6. Bereich `Signing & Capabilities` öffnen.
7. `Automatically manage signing` aktivieren.
8. Unter `Team` den eigenen Apple-Account auswählen.
9. Bundle Identifier prüfen: `com.claudiokrueger.MigraLog`.
10. Version prüfen: `1.0`, Build `1`.

## Installation

1. iPhone entsperren.
2. Falls abgefragt: diesem Computer vertrauen.
3. In Xcode `Run` drücken.
4. Warten, bis MigraLog auf dem iPhone startet.

## Falls Xcode nach einem Passwort fragt

Das ist in der Regel das macOS-Benutzerpasswort oder die Apple-ID-Abfrage für Signing. Xcode benötigt Zugriff auf Zertifikate und Profile.

## Falls das iPhone die App nicht öffnet

Bei persönlichem Apple-Account kann iOS eine Entwicklerfreigabe verlangen:

1. Auf dem iPhone `Einstellungen` öffnen.
2. `Allgemein` öffnen.
3. `VPN & Geräteverwaltung` oder `Geräteverwaltung` öffnen.
4. Dem Entwicklerprofil vertrauen.
5. MigraLog erneut starten.

## Wichtige Hinweise für den Patiententest

- Die Daten bleiben lokal auf dem iPhone.
- Es gibt aktuell keine Cloud-Synchronisierung.
- Beim Löschen der App werden die lokalen Daten entfernt.
- MigraLog ersetzt keine medizinische Diagnose oder Behandlung.
- Für den Test sollten keine echten Notfalldaten erfasst werden.
