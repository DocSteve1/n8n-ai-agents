# 🧪 Automated Testing - Flight Search Agent

## Übersicht

Dieses Projekt enthält ein vollautomatisches Test-System für den Flight Search Agent Workflow. Alle 20 Test-Cases werden automatisch ausgeführt und die Ergebnisse in einer CSV-Datei gespeichert.

---

## 🚀 Quick Start

### 1. Voraussetzungen

```bash
# n8n muss laufen
n8n start
# Läuft auf: http://localhost:5678

# Workflow "AI Flight Search Agent" muss aktiviert sein
# Webhook URL: http://localhost:5678/webhook/flight-search

# jq muss installiert sein (für JSON parsing)
sudo apt-get install jq
```

### 2. Tests ausführen

```bash
# Im Projekt-Root:
./test-flight-search.sh
```

### 3. Ergebnisse prüfen

```bash
# Neueste Ergebnisse anzeigen
ls -lt results/test-results_*.csv | head -1

# Ergebnis-Datei öffnen
cat results/test-results_YYYYMMDD_HHMMSS.csv
```

---

## 📋 Test-Script Features

### ✅ Automatische Checks

- **Dependency Check** - Prüft ob jq und curl installiert sind
- **n8n Connection Check** - Verifiziert dass n8n läuft
- **Test File Validation** - Stellt sicher dass Test-Cases existieren

### 📊 Test-Execution

- **20 Test-Cases** automatisch ausgeführt
- **Response Time Messung** für jeden Test
- **HTTP Status Validierung** (200, 400, etc.)
- **Business Logic Validierung** (status: success/error/no_flights)
- **Farbcodierter Output** für bessere Lesbarkeit

### 💾 Ergebnis-Speicherung

Alle Testergebnisse werden in CSV-Dateien gespeichert:

```
results/
  test-results_20260205_210230.csv
  test-results_20260205_153045.csv
  test-results_20260204_092015.csv
```

---

## 📈 CSV-Format

```csv
Test_ID,Test_Name,Category,Status,HTTP_Status,Expected_Status,Response_Time_ms,Flights_Found,Has_Errors,Error_Messages,Timestamp
TC001,"Erfolgreiche Flugsuche - Berlin",success,PASS,200,success,5234,2,no,"",2026-02-05T21:02:30+01:00
TC006,"Validierungsfehler - Fehlendes Datum",validation_error,PASS,400,error,123,0,yes,"Pflichtfeld fehlt: termin.datum",2026-02-05T21:02:31+01:00
```

### Spalten-Beschreibung

| Spalte | Beschreibung |
|--------|--------------|
| Test_ID | Eindeutige Test-ID (TC001 - TC020) |
| Test_Name | Beschreibender Name des Tests |
| Category | success / validation_error / no_flights |
| Status | PASS / FAIL |
| HTTP_Status | Tatsächlicher HTTP Status Code |
| Expected_Status | Erwarteter Business Status |
| Response_Time_ms | Antwortzeit in Millisekunden |
| Flights_Found | Anzahl gefundener Flüge |
| Has_Errors | yes/no - ob Validierungsfehler vorliegen |
| Error_Messages | Liste der Fehlermeldungen |
| Timestamp | Zeitpunkt der Ausführung |

---

## 🎯 Test-Categories

### 1. Success Tests (8 Tests)
Testen erfolgreiche Flugsuchen für verschiedene Ziele:
- TC001: Berlin
- TC002: München
- TC003: Hamburg
- TC014: Frankfurt (ganztägig)
- TC015: Wien (Spätnachmittag)
- TC019: Zürich (Schweiz)
- TC020: Wien (Österreich)

### 2. Validation Error Tests (10 Tests)
Testen Input-Validierung:
- TC006: Fehlendes Datum
- TC007: Ungültiges Datumsformat
- TC008: Ungültiges Zeitformat (eine Stelle)
- TC009: Ungültige Zeit (>24h)
- TC010: Zeit-Ende vor Zeit-Start
- TC011: Fehlendes Feld "ort"
- TC012: Leerer Ort
- TC013: Datum in Vergangenheit
- TC016: Mehrere Fehler gleichzeitig
- TC017: Mitternacht als Ende
- TC018: Gleiche Start- und Endzeit

### 3. No Flights Tests (2 Tests)
Testen Szenarien ohne passende Flüge:
- TC004: Sehr enges Zeitfenster (7-8 Uhr)
- TC005: Exotisches Ziel (Reykjavik)

---

## 🔧 Konfiguration

### n8n URL anpassen

Wenn n8n auf einem anderen Server läuft:

```bash
# Datei: test-flight-search.sh
# Zeile 17 ändern:
N8N_URL="http://192.168.1.100:5678/webhook/flight-search"
```

### Timeout anpassen

Für langsame API-Calls:

```bash
# In run_test() Funktion:
curl -s -w "\n%{http_code}" --max-time 30 -X POST "$N8N_URL" \
```

### Pause zwischen Tests

```bash
# In run_test() Funktion, letzte Zeile:
sleep 0.5  # Standard: 0.5 Sekunden
sleep 2    # Längere Pause für Rate-Limit-Schonung
```

---

## 📊 Beispiel-Output

```
==========================================
  FLIGHT SEARCH AGENT - AUTOMATED TESTS  
==========================================

[INFO] Prüfe Abhängigkeiten...
[OK] Alle Abhängigkeiten vorhanden
[INFO] Prüfe n8n Verbindung...
[OK] n8n läuft
[INFO] CSV-Datei erstellt: results/test-results_20260205_210230.csv

[INFO] Starte Tests...

[TEST] TC001: Erfolgreiche Flugsuche - Berlin
  ✓ PASS - HTTP: 200 ✓, Status: success ✓, Time: 5234ms

[TEST] TC002: Erfolgreiche Flugsuche - München
  ✓ PASS - HTTP: 200 ✓, Status: success ✓, Time: 4891ms

[TEST] TC006: Validierungsfehler - Fehlendes Datum
  ✓ PASS - HTTP: 400 ✓, Status: error ✓, Time: 123ms

...

==========================================
  TEST SUMMARY
==========================================

Total Tests:    20
Passed:         18
Failed:         2
Pass Rate:      90.0%

Results saved:  results/test-results_20260205_210230.csv

⚠️  Einige Tests sind fehlgeschlagen!
```

---

## 🐛 Troubleshooting

### Problem: "jq ist nicht installiert"

```bash
# Ubuntu/Debian:
sudo apt-get install jq

# macOS:
brew install jq
```

### Problem: "n8n ist nicht erreichbar"

```bash
# Prüfe ob n8n läuft:
curl http://localhost:5678

# Starte n8n:
n8n start

# Oder mit Docker:
docker ps | grep n8n
```

### Problem: "Test-File nicht gefunden"

```bash
# Stelle sicher, dass du im Projekt-Root bist:
cd /path/to/18-n8n-ai-agents
./test-flight-search.sh
```

### Problem: "Permission denied"

```bash
# Mache Script ausführbar:
chmod +x test-flight-search.sh
```

### Problem: Alle Tests schlagen fehl

1. **Workflow aktiviert?** - Prüfe in n8n UI
2. **Webhook URL korrekt?** - Sollte `/webhook/flight-search` sein
3. **Credentials konfiguriert?** - OpenRouter, SerpAPI, Google Sheets

---

## 📈 CSV-Analyse mit Tools

### LibreOffice Calc / Excel
```
- Öffne CSV-Datei
- Filtere nach Status = FAIL
- Sortiere nach Response_Time_ms
- Erstelle Pivot-Tabelle für Kategorien
```

### Command Line
```bash
# Zeige nur fehlgeschlagene Tests
cat results/test-results_*.csv | grep FAIL

# Zeige durchschnittliche Response Time
awk -F',' 'NR>1 {sum+=$7; count++} END {print sum/count "ms"}' results/test-results_*.csv

# Zähle Tests pro Kategorie
cut -d',' -f3 results/test-results_*.csv | sort | uniq -c
```

### Python Pandas
```python
import pandas as pd

# Lade Ergebnisse
df = pd.read_csv('results/test-results_20260205_210230.csv')

# Statistiken
print(df['Status'].value_counts())
print(df.groupby('Category')['Response_Time_ms'].mean())

# Visualisierung
df.plot(x='Test_ID', y='Response_Time_ms', kind='bar')
```

---

## 🔄 CI/CD Integration

### GitHub Actions Beispiel

```yaml
name: Test Flight Search Agent

on:
  push:
    branches: [ main ]
  schedule:
    - cron: '0 6 * * *'  # Täglich um 6 Uhr

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v2
    
    - name: Install jq
      run: sudo apt-get install -y jq
    
    - name: Start n8n
      run: |
        docker run -d -p 5678:5678 n8nio/n8n
        sleep 30  # Warte bis n8n gestartet ist
    
    - name: Run Tests
      run: ./test-flight-search.sh
    
    - name: Upload Results
      uses: actions/upload-artifact@v2
      with:
        name: test-results
        path: results/*.csv
```

---

## 📝 Best Practices

### 1. Regelmäßiges Testen
```bash
# Cron Job für tägliche Tests um 6 Uhr
0 6 * * * cd /path/to/18-n8n-ai-agents && ./test-flight-search.sh
```

### 2. Test-Daten aktualisieren
```bash
# Passe Datum-Werte in test-data/flight-search-test-cases.json an
# Alle Datum-Werte sollten in der Zukunft liegen!
```

### 3. Rate Limits beachten
```bash
# SerpAPI Gratis: 100 Suchen/Monat
# 20 Tests × 30 Tage = 600 Suchen/Monat → bezahlter Plan nötig
# Oder: Nur Validation-Error Tests täglich (keine API-Calls)
```

### 4. Ergebnisse archivieren
```bash
# Alte Ergebnisse komprimieren
gzip results/test-results_2026*.csv

# Nur letzte 30 Tage behalten
find results/ -name "*.csv" -mtime +30 -delete
```

---

## 🎓 Erweiterte Nutzung

### Einzelnen Test ausführen

```bash
# Extrahiere einen Test aus JSON und führe manuell aus
jq '.test_cases[0]' test-data/flight-search-test-cases.json | \
  jq -c '.input' | \
  curl -X POST http://localhost:5678/webhook/flight-search \
    -H "Content-Type: application/json" \
    -d @-
```

### Nur bestimmte Kategorien testen

Modifiziere `test-flight-search.sh`:

```bash
# In run_all_tests() Funktion:
if [ "$category" != "validation_error" ]; then
    continue  # Überspringe nicht-validation Tests
fi
```

### Performance-Analyse

```bash
# Zeige langsamste Tests
cat results/test-results_*.csv | \
  awk -F',' 'NR>1 {print $7","$2}' | \
  sort -rn | \
  head -5
```

---

## 📚 Weitere Dokumentation

- **Setup Guide:** `docs/flight-search-agent-setup.md`
- **Quick Start:** `workflows/README-FLIGHT-SEARCH.md`
- **Test Cases:** `test-data/flight-search-test-cases.json`
- **Workflow JSON:** `workflows/flight-search-agent.json`

---

**Happy Testing! 🧪**
