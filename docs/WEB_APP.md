# MigraLog Web 1.0

MigraLog Web ist eine Progressive Web App für Smartphone und Desktop. Sie ersetzt die native iOS-Testverteilung, wenn die App ohne Apple-Developer-Kosten dauerhaft genutzt werden soll.

## Öffentliche Web-Adresse

Nach aktivierter GitHub-Pages-Bereitstellung ist die App hier erreichbar:

```text
https://kruegerc.github.io/MigraLog/
```

Die Veröffentlichung erfolgt automatisch aus dem Ordner `web`, sobald Änderungen auf `main` landen.

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

## Installation auf dem iPhone

1. In Safari diese Adresse öffnen:

```text
https://kruegerc.github.io/MigraLog/
```

2. Teilen-Menü öffnen.
3. `Zum Home-Bildschirm` auswählen.
4. Name `MigraLog` bestätigen.
5. App über das neue Icon starten.

## Nutzung durch eine zweite Person

Die App kann per Link weitergegeben werden. Jede Person speichert ihre Einträge lokal auf dem eigenen Gerät.

Wichtig:

- Deine Einträge und die Einträge deiner Frau werden nicht miteinander synchronisiert.
- Es gibt kein zentrales Benutzerkonto.
- Die Gesundheitsdaten werden nicht an GitHub übertragen.
- GitHub liefert nur die statischen App-Dateien aus.

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

## GitHub Pages aktivieren

Falls GitHub Pages im Repository noch nicht aktiv ist:

1. Repository auf GitHub öffnen.
2. `Settings` öffnen.
3. `Pages` öffnen.
4. Unter `Build and deployment` die Quelle `GitHub Actions` auswählen.
5. Änderungen speichern.
6. Danach den Workflow `Deploy MigraLog Web` ausführen oder auf `main` mergen.

## Empfehlung für den produktiven Privatgebrauch

Für private Nutzung reicht GitHub Pages technisch aus. Der Link sollte nicht öffentlich beworben werden. Die Daten bleiben lokal auf dem Gerät, aber der App-Code selbst ist über die URL erreichbar.
