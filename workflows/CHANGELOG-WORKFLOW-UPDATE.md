# Workflow Update - Flight Search Agent v2

**Datum:** 06.02.2026  
**Version:** 2.0

## 🎯 Übersicht der Änderungen

Dieses Update bringt umfassende Verbesserungen am Flight Search Agent Workflow, insbesondere:
- **Debug-Logging System** (Webhook-gesteuert)
- **Vereinfachte Google Sheets Konfiguration**
- **Neue Webhook-URL**
- **Verbesserte Node-Struktur**

---

## 📋 Detaillierte Änderungen

### 1. **Webhook URL geändert**

**Von:** `http://localhost:5678/webhook/flight-search`  
**Nach:** `http://localhost:5678/webhook-test/flight-search`

**Betroffen:**
- Webhook Node im Workflow
- `test-flight-search.sh`
- `test-debug-flight-search.sh` (neu)

### 2. **Debug-Logging System implementiert** 🐛

**Steuerung:** Per Webhook-Request Parameter `"debug": true`

**Neue Nodes:**
- **Debug Logger Node** (Position: zwischen AI Agent und Parse Agent Response)
- **AI Agent Output Parser** (aktiviert im AI Agent Node)

**Features:**
- Console Logging nur wenn `debug: true` im Request
- Logs zeigen:
  - Validation Input
  - Agent Intermediate Steps (SerpAPI Calls)
  - Raw Agent Response
  - Parsing Status

**Beispiel Debug-Request:**
```json
{
  "debug": true,
  "termin": {
    "datum": "2026-03-15",
    "zeit_von": "09:00",
    "zeit_bis": "17:00"
  },
  "ort": "Berlin"
}
```

**Debug-Logs ansehen:**
```bash
# Docker
docker logs -f n8n-container

# Docker Compose
docker-compose logs -f n8n

# Direktes n8n
tail -f ~/.n8n/logs/n8n.log
```

### 3. **Google Sheets Konfiguration vereinfacht**

**Beide Google Sheets Nodes geändert:**
- "Log to Google Sheets"
- "Log Error to Sheets"

**Alte Konfiguration:**
```json
{
  "credentials": {
    "googleSheetsOAuth2Api": {...}
  },
  "documentId": {
    "mode": "id",
    "value": "YOUR_GOOGLE_SHEET_ID"
  },
  "sheetName": {
    "mode": "name",
    "value": "Sheet1"
  },
  "columns": {
    "mappingMode": "defineBelow",
    "value": {...komplexes Mapping...}
  }
}
```

**Neue Konfiguration:**
```json
{
  "credentials": {
    "googleApi": {
      "id": "google-service-account",
      "name": "Google Service Account"
    }
  },
  "documentId": {
    "mode": "list"
  },
  "sheetName": {
    "mode": "list"
  },
  "columns": {
    "mappingMode": "autoMapInputData"
  },
  "options": {
    "timeout": 3000
  },
  "continueOnFail": true
}
```

**Vorteile:**
- ✅ Service Account statt OAuth2 (keine User-Interaktion)
- ✅ Document Selection via Dropdown
- ✅ Sheet Selection via Dropdown
- ✅ Automatisches Column Mapping
- ✅ Production-Ready

### 4. **Validate Input Node erweitert**

**Neu:**
- Extrahiert `debug` Flag aus Request
- Setzt `_debug` Flag durch gesamten Workflow
- Console Logging bei `DEBUG=true`

**Code-Ergänzung:**
```javascript
// ===== EXTRACT DEBUG FLAG =====
const DEBUG = data.debug === true;

if (DEBUG) {
  console.log('\n🐛 DEBUG MODE ACTIVATED via webhook request\n');
}

// Bei validated.push():
_debug: DEBUG  // Flag durchreichen
```

### 5. **Parse Agent Response Node erweitert**

**Neu:**
- Debug-Logging vor/nach Parsing
- Detaillierte Error-Logs bei Parsing-Fehlern

**Code-Ergänzung:**
```javascript
const DEBUG = originalData._debug || false;

if (DEBUG) {
  console.log('\n🔍 DEBUG: Starting to parse agent response...');
}

// Nach erfolgreichem Parsing:
if (DEBUG) {
  console.log('\n✅ DEBUG: Successfully parsed agent response');
  console.log('Status:', parsedResponse.status);
  console.log('Flights found:', parsedResponse.flights?.length || 0);
}
```

### 6. **AI Agent Output Parser aktiviert**

**Neu im AI Agent Node:**
- `hasOutputParser: true`
- Custom Parser Code für intermediateSteps Logging

**Code:**
```javascript
const validatedData = $('Validate Input').first().json;
const DEBUG = validatedData._debug || false;

if (DEBUG && $json.intermediateSteps) {
  console.log('\n=== 🔍 AGENT INTERMEDIATE STEPS ===\n');
  
  $json.intermediateSteps.forEach((step, i) => {
    console.log(`\n--- Step ${i + 1} ---`);
    console.log('Tool:', step.action?.tool || 'unknown');
    console.log('Tool Input:', JSON.stringify(step.action?.toolInput, null, 2));
    console.log('Observation:', JSON.stringify(step.observation, null, 2));
  });
  
  console.log('\n=== END INTERMEDIATE STEPS ===\n');
}

return $json;
```

---

## 🆕 Neue Komponenten

### 1. **Debug Logger Node**

- **Type:** Code Node
- **Position:** Zwischen "AI Agent" und "Parse Agent Response"
- **Funktion:** Loggt raw Agent Response wenn DEBUG=true

### 2. **test-debug-flight-search.sh**

Neues Script für Debug-Tests:

```bash
# Standard Success-Test
./test-debug-flight-search.sh

# Validation Error Test
./test-debug-flight-search.sh validation_error

# No Flights Test
./test-debug-flight-search.sh no_flights
```

**Features:**
- Interactive Test-Ausführung
- Pretty-printed Request/Response
- Log-Anzeige Hinweise
- Drei vordefinierte Szenarien

---

## 📊 Workflow-Struktur (NEU)

```
Webhook (webhook-test/flight-search)
  ↓
Validate Input (mit debug-Flag Extraktion)
  ↓
Check Validation
  ├─ ERROR → Webhook Response Error
  │         └→ Log Error to Sheets (Service Account, Auto-Mapping)
  └─ VALID → AI Agent
             ├─ [Output Parser: logs intermediateSteps wenn DEBUG]
             ├─ OpenRouter LLM
             └─ SerpAPI Tool
             ↓
             Debug Logger (logs raw response wenn DEBUG)
             ↓
             Parse Agent Response (mit debug logging)
             ↓
             Log to Google Sheets (Service Account, Auto-Mapping)
             ↓
             Webhook Response Success
```

---

## 🧪 Testing

### Standard Tests (ohne Debug):

```bash
./test-flight-search.sh
```

- Führt alle 20 Test-Cases aus
- **KEINE** Console Logs
- Erstellt CSV Ergebnis-Datei

### Debug Tests (mit Debug):

```bash
./test-debug-flight-search.sh
```

- Führt EINEN Test aus
- **VOLLE** Console Logs
- Interaktiv mit Enter-Bestätigung

**In separatem Terminal dann:**
```bash
docker logs -f n8n-container
```

### Erwartete Debug-Ausgabe:

```
🐛 DEBUG MODE ACTIVATED via webhook request

=== 🔍 AGENT INTERMEDIATE STEPS ===

--- Step 1 ---
Tool: serpapi_google_flights
Tool Input: {
  "query": "flights from CGN to Berlin..."
}
Observation: {
  "best_flights": [...]
}

=== END INTERMEDIATE STEPS ===

================================================================================
🔍 DEBUG: RAW AGENT RESPONSE
================================================================================
Timestamp: 2026-02-06T12:00:00.000Z
Request ID: flight_1234567890_abc123
...

🔍 DEBUG: Starting to parse agent response...
✅ DEBUG: Successfully parsed agent response
Status: success
Flights found: 2
```

---

## 🔄 Migration Guide

### Schritt 1: Workflow neu importieren

1. In n8n UI: Alten Workflow deaktivieren/löschen
2. `workflows/flight-search-agent.json` neu importieren
3. **Wichtig:** Credentials neu verbinden:
   - OpenRouter API
   - SerpAPI
   - **Google Service Account** (statt OAuth2!)

### Schritt 2: Google Service Account einrichten

Falls noch nicht vorhanden:

1. Google Cloud Console → IAM & Admin → Service Accounts
2. Create Service Account
3. Download JSON Key
4. In n8n: Credentials → Add → Google Service Account
5. JSON Key hochladen
6. In Google Sheets Nodes: Credentials auswählen

### Schritt 3: Google Sheets konfigurieren

1. "Log to Google Sheets" Node öffnen
2. Document ID: Dropdown → Wähle dein Sheet
3. Sheet Name: Dropdown → Wähle dein Sheet
4. Columns: **Automatisch** (nichts tun!)
5. Wiederhole für "Log Error to Sheets"

### Schritt 4: Test Scripts aktualisieren

```bash
# Scripts sind bereits aktualisiert!
# Nur executable machen:
chmod +x test-debug-flight-search.sh

# Testen:
./test-flight-search.sh
```

---

## ⚠️ Breaking Changes

### 1. **Webhook URL geändert**

Alte URL funktioniert NICHT mehr!

**Alt:** `/webhook/flight-search`  
**Neu:** `/webhook-test/flight-search`

→ Alle externen Integrationen müssen URL anpassen!

### 2. **Google Sheets Credentials**

OAuth2 → Service Account

→ Neue Credentials nötig!

### 3. **Column Mapping**

Manual → Automatic

→ Spalten-Namen werden automatisch aus JSON Keys generiert

---

## 🎁 Benefits

| Feature | Vorher | Nachher |
|---------|--------|---------|
| **Debug-Möglichkeit** | ❌ Keine | ✅ Per Request-Flag |
| **SerpAPI Visibility** | ❌ Black Box | ✅ Full Logging |
| **Agent Steps** | ❌ Unsichtbar | ✅ Nachvollziehbar |
| **Google Sheets Auth** | 🔴 User OAuth | 🟢 Service Account |
| **Sheets Config** | 🔴 Manual IDs | 🟢 Dropdown |
| **Column Mapping** | 🔴 Manuell | 🟢 Automatisch |
| **Production Ready** | 🟡 Teilweise | 🟢 Ja |

---

## 📝 Nächste Schritte

1. ✅ Workflow importieren
2. ✅ Credentials konfigurieren
3. ✅ Debug-Test ausführen:
   ```bash
   ./test-debug-flight-search.sh
   # In anderem Terminal:
   docker logs -f n8n-container
   ```
4. ✅ Standard-Tests ausführen:
   ```bash
   ./test-flight-search.sh
   ```
5. ✅ Google Sheets prüfen (Daten sollten automatisch erscheinen)

---

## 🐛 Troubleshooting

### Problem: "DEBUG MODE ACTIVATED" erscheint nicht

**Lösung:**
- Prüfe ob `"debug": true` im Request ist
- Prüfe n8n Logs: `docker logs n8n-container | grep DEBUG`

### Problem: Google Sheets Mapping zeigt Fehler

**Lösung:**
- Stelle sicher: `mappingMode: "autoMapInputData"`
- Keine manuelle Column Definition nötig!
- Bei erstem Durchlauf werden Spalten automatisch erstellt

### Problem: intermediateSteps sind leer

**Lösung:**
- AI Agent Node → Options → Output Parser aktivieren
- Code korrekt eingefügt?

---

## 📚 Weitere Dokumentation

- `docs/TESTING.md` - Test-Strategie
- `docs/flight-search-agent-setup.md` - Setup Guide
- `workflows/README-FLIGHT-SEARCH.md` - Workflow Details

---

**Version:** 2.0  
**Author:** Cline AI Assistant  
**Datum:** 06.02.2026
