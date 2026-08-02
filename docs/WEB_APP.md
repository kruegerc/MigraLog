# MigraLog Web 1.0

MigraLog Web ist eine Progressive Web App für Smartphone und Desktop. Sie ersetzt die native iOS-Testverteilung, wenn die App ohne Apple-Developer-Kosten dauerhaft genutzt werden soll.

## Eigenschaften

- läuft im Browser
- kann auf dem iPhone zum Home-Bildschirm hinzugefügt werden
- speichert Daten lokal im Browser
- funktioniert nach dem ersten Laden offline
- benötigt kein Benutzerkonto
- verwendet kein Backend für Gesundheitsdaten
- bietet CSV-Export
- bietet druckbaren Arztbericht, der als PDF gespeichert werden kann
- bietet JSON-Backup und Import

## Lokale Nutzung zum Entwickeln

Im Ordner `web` einen lokalen Server starten:

```sh
cd web
python3 -m http.server 8080
```

Danach öffnen:

```text
http://localhost:8080
```

Ein direkter Datei-Aufruf per Doppelklick ist für PWA-Funktionen nicht ausreichend, weil Service Worker nur über `http://localhost` oder HTTPS laufen.

## Installation auf dem iPhone

1. Web-Adresse in Safari öffnen.
2. Teilen-Menü öffnen.
3. `Zum Home-Bildschirm` auswählen.
4. Name `MigraLog` bestätigen.
5. App über das neue Icon starten.

## Datenhaltung

Die Daten werden lokal im Browser gespeichert. Es gibt keine automatische Synchronisierung.

Wichtig:

- Wenn Website-Daten in Safari gelöscht werden, können MigraLog-Daten verloren gehen.
- Vor Gerätewechsel oder größeren Änderungen sollte ein Backup gespeichert werden.
- Das Backup enthält Gesundheitsdaten und sollte vertraulich behandelt werden.

## Backup

Unter `Mehr`:

- `Backup-Datei speichern` erzeugt eine JSON-Datei mit allen Einträgen.
- `Backup importieren` ersetzt die lokalen Daten durch eine gespeicherte Backup-Datei.

## Export für Arzttermin

Unter `Export`:

- Zeitraum auswählen.
- `PDF-Bericht` öffnen.
- Im Druckdialog `Als PDF sichern` wählen.
- Alternativ `CSV` für Tabellenprogramme speichern.

## Bekannte Einschränkungen

- Keine Ende-zu-Ende-Verschlüsselung im Browser-Speicher.
- Keine Synchronisierung zwischen Geräten.
- Keine Push-Erinnerungen.
- Kein zentraler Login.
- Der PDF-Bericht wird über den Druckdialog erzeugt.

## Empfehlung für den produktiven Privatgebrauch

Die App sollte über HTTPS bereitgestellt werden, zum Beispiel über GitHub Pages, Netlify, Vercel oder einen eigenen Webserver. Für private Gesundheitsdaten sollte der Link nicht öffentlich beworben werden. Die Daten bleiben zwar lokal auf dem Gerät, aber der App-Code selbst ist über die URL erreichbar.
