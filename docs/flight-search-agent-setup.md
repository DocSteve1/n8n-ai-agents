# 🛫 Flight Search Agent - Setup & Konfiguration

## Übersicht

Der **Flight Search Agent** ist ein vollautomatischer n8n Workflow, der über einen Webhook Termindaten empfängt und automatisch passende Tagesflüge sucht. Er nutzt einen AI Agent mit Claude 3.5 Sonnet (über OpenRouter) und SerpAPI Google Flights.

---

## 🎯 Features

✅ **Vollautomatische Flugsuche** von 3 Abflughäfen (CGN, FRA, DUS)  
✅ **Intelligente Zeitfenster-Prüfung** für Geschäftstermine  
✅ **3-Ebenen Error Handling** (Input, Agent Response, Global)  
✅ **Google Sheets Logging** aller Anfragen und Ergebnisse  
✅ **Native n8n Nodes** - keine HTTP Request Nodes!  
✅ **Strukturierte JSON Responses** für einfache Integration  

---

## 📋 Voraussetzungen

### 1. n8n Installation
- **Version:** n8n v1.0 oder höher
- **Self-Hosted** oder **n8n Cloud**

### 2. Benötigte Credentials

#### A) OpenRouter API
1. Account erstellen auf [openrouter.ai](https://openrouter.ai)
2. API Key generieren
3. In n8n unter **Credentials** → **OpenRouter API** eintragen
   - Name: `OpenRouter API`
   - API Key: `sk-or-v1-...`

#### B) SerpAPI
1. Account erstellen auf [serpapi.com](https://serpapi.com)
2. API Key kopieren (gratis: 100 Suchen/Monat)
3. In n8n unter **Credentials** → **SerpAPI** eintragen
   - Name: `SerpAPI`
   - API Key: `your-serpapi-key`

#### C) Google Sheets (optional, für Logging)
1. Google Cloud Project erstellen
2. Google Sheets API aktivieren
3. OAuth2 Credentials erstellen
4. In n8n unter **Credentials** → **Google Sheets OAuth2 API** verbinden

### 3. Google Sheet vorbereiten (optional)

Erstelle ein neues Google Sheet mit folgenden Spalten:

| Timestamp | Request_ID | Termin_Datum | Termin_Von | Termin_Bis | Zielort | Status | Anzahl_Fluege | Beste_Option | Agent_Log | Error_Details |
|-----------|------------|--------------|------------|------------|---------|--------|---------------|--------------|-----------|---------------|

**Sheet ID kopieren** aus der URL:
```
https://docs.google.com/spreadsheets/d/YOUR_SHEET_ID/edit
                                        ^^^^^^^^^^^^^^^^
```

---

## 🚀 Installation

### Schritt 1: Workflow importieren

1. In n8n öffnen
2. Menü → **Import from File**
3. Datei wählen: `workflows/flight-search-agent.json`
4. Importieren bestätigen

### Schritt 2: Credentials konfigurieren

Öffne folgende Nodes und verbinde die Credentials:

#### **OpenRouter LLM Node**
- Node öffnen
- Unter **Credential** → **OpenRouter API** auswählen
- Speichern

#### **SerpAPI Google Flights Node**
- Node öffnen
- Unter **Credential** → **SerpAPI** auswählen
- Speichern

#### **Google Sheets Nodes** (2x)
- Node "Log to Google Sheets" öffnen
- Unter **Credential** → **Google Sheets OAuth2 API** auswählen
- **Document ID** eintragen: `YOUR_GOOGLE_SHEET_ID`
- **Sheet Name** prüfen: `Sheet1` (oder deinen Namen)
- Speichern
- Wiederholen für "Log Error to Sheets"

### Schritt 3: Workflow aktivieren

1. Rechts oben: **Activate** Schalter auf **ON**
2. **Webhook URL** wird generiert
3. URL kopieren (z.B. `http://localhost:5678/webhook/flight-search`)

---

## 📡 API Nutzung

### Webhook Endpoint

```
POST http://localhost:5678/webhook/flight-search
Content-Type: application/json
```

### Request Body Format

```json
{
  "termin": {
    "datum": "2026-03-15",
    "zeit_von": "09:00",
    "zeit_bis": "17:00"
  },
  "ort": "Berlin"
}
```

### Feld-Beschreibungen

| Feld | Typ | Pflicht | Format | Beschreibung |
|------|-----|---------|--------|--------------|
| `termin.datum` | String | ✅ | `YYYY-MM-DD` | Termin-Datum (muss in Zukunft liegen) |
| `termin.zeit_von` | String | ✅ | `HH:MM` | Termin-Beginn |
| `termin.zeit_bis` | String | ✅ | `HH:MM` | Termin-Ende (muss nach zeit_von liegen) |
| `ort` | String | ✅ | Text | Zielstadt |

---

## ✅ Response Formate

### Erfolg: Flüge gefunden

```json
{
  "request_id": "flight_1738779600_abc123",
  "status": "success",
  "termin": {
    "datum": "2026-03-15",
    "zeit_von": "09:00",
    "zeit_bis": "17:00"
  },
  "zielort": "Berlin",
  "ergebnis": {
    "anzahl_fluege": 2,
    "fluege": [
      {
        "outbound": {
          "from": "CGN",
          "to": "BER",
          "departure_time": "06:30",
          "arrival_time": "07:45",
          "airline": "Lufthansa",
          "flight_number": "LH2134",
          "duration": "75",
          "stops": 0
        },
        "return": {
          "from": "BER",
          "to": "CGN",
          "departure_time": "18:30",
          "arrival_time": "19:50",
          "airline": "Lufthansa",
          "flight_number": "LH2139",
          "duration": "80",
          "stops": 0
        },
        "total_price_eur": 189,
        "total_duration_minutes": 795
      }
    ]
  },
  "search_summary": {
    "searched_airports": ["CGN", "FRA", "DUS"],
    "destination": "Berlin",
    "date": "2026-03-15",
    "results_found": 2,
    "search_timestamp": "2026-02-05T19:00:00.000Z"
  },
  "timestamp": "2026-02-05T19:00:00.000Z"
}
```

### Erfolg: Keine Flüge gefunden

```json
{
  "request_id": "flight_1738779600_xyz789",
  "status": "no_flights",
  "termin": { ... },
  "zielort": "Reykjavik",
  "ergebnis": {
    "anzahl_fluege": 0,
    "fluege": []
  },
  "search_summary": {
    "searched_airports": ["CGN", "FRA", "DUS"],
    "destination": "Reykjavik",
    "results_found": 0
  },
  "timestamp": "2026-02-05T19:00:00.000Z"
}
```

### Fehler: Validierung fehlgeschlagen

**HTTP Status:** `400 Bad Request`

```json
{
  "status": "error",
  "error_type": "validation_error",
  "message": "Eingabe-Validierung fehlgeschlagen",
  "errors": [
    "Pflichtfeld fehlt: termin.datum",
    "Ungültiges Zeitformat für termin.zeit_von. Erwartet: HH:MM"
  ],
  "timestamp": "2026-02-05T19:00:00.000Z"
}
```

### Fehler: Agent/Parsing Error

**HTTP Status:** `200 OK` (da technisch erfolgreich, aber fachlich Fehler)

```json
{
  "request_id": "flight_1738779600_abc123",
  "status": "error",
  "error_type": "parsing_error",
  "message": "Failed to parse agent response: ...",
  "ergebnis": {
    "anzahl_fluege": 0,
    "fluege": []
  },
  "timestamp": "2026-02-05T19:00:00.000Z"
}
```

---

## 🧪 Test-Beispiele

### Test 1: Erfolgreiche Suche (Berlin)

```bash
curl -X POST http://localhost:5678/webhook/flight-search \
  -H "Content-Type: application/json" \
  -d '{
    "termin": {
      "datum": "2026-03-15",
      "zeit_von": "09:00",
      "zeit_bis": "17:00"
    },
    "ort": "Berlin"
  }'
```

### Test 2: Erfolgreiche Suche (München)

```bash
curl -X POST http://localhost:5678/webhook/flight-search \
  -H "Content-Type: application/json" \
  -d '{
    "termin": {
      "datum": "2026-04-20",
      "zeit_von": "10:00",
      "zeit_bis": "16:00"
    },
    "ort": "München"
  }'
```

### Test 3: Validierungs-Fehler (fehlendes Datum)

```bash
curl -X POST http://localhost:5678/webhook/flight-search \
  -H "Content-Type: application/json" \
  -d '{
    "termin": {
      "zeit_von": "09:00",
      "zeit_bis": "17:00"
    },
    "ort": "Hamburg"
  }'
```

**Erwartete Response:** `400 Bad Request` mit Fehlermeldung

### Test 4: Validierungs-Fehler (ungültiges Zeitformat)

```bash
curl -X POST http://localhost:5678/webhook/flight-search \
  -H "Content-Type: application/json" \
  -d '{
    "termin": {
      "datum": "2026-03-15",
      "zeit_von": "9:00",
      "zeit_bis": "25:00"
    },
    "ort": "Frankfurt"
  }'
```

**Erwartete Response:** `400 Bad Request` mit Validierungs-Fehlern

---

## 🛡️ Error Handling

Der Workflow hat **3 Ebenen** vom Error Handling:

### Ebene 1: Input Validation
- Prüft alle Pflichtfelder
- Validiert Datum-/Zeitformate
- Prüft logische Bedingungen (Zeit-Ende nach Zeit-Start)
- **Bei Fehler:** Sofortige 400-Response, kein API-Aufruf

### Ebene 2: Agent Response Validation
- Parst AI Agent JSON-Response
- Validiert Struktur und Pflichtfelder
- Prüft Flugdaten-Vollständigkeit
- **Bei Fehler:** Status "error" in Response

### Ebene 3: Global Error Handler
- Fängt unerwartete Runtime-Fehler
- Loggt alle Fehler in Google Sheets
- Verhindert 500-Errors

---

## 📊 Google Sheets Logging

Alle Requests werden automatisch geloggt:

### Log-Einträge bei Erfolg
- ✅ Timestamp
- ✅ Request ID
- ✅ Termin-Daten
- ✅ Zielort
- ✅ Status
- ✅ Anzahl gefundener Flüge
- ✅ Beste Flugoption (JSON)
- ✅ Agent Response (gekürzt)

### Log-Einträge bei Fehler
- ❌ Timestamp
- ❌ Error Details
- ❌ Received Data
- ❌ Fehlertyp

---

## ⚙️ Konfiguration & Tuning

### AI Agent Prompt anpassen

Im Node **"AI Agent - Flight Search"** → **Text** Feld:

```javascript
// Weitere Abflughäfen hinzufügen:
"Suche Flüge von diesen Abflughäfen: CGN, FRA, DUS, STR, HAM"

// Nur Direktflüge:
"Nur Direktflüge - KEINE Umstiege akzeptiert"

// Mehr Ergebnisse:
"Return top 5 flights" // statt Standard 3
```

### LLM-Temperatur ändern

Im Node **"OpenRouter LLM"** → **Options** → **Temperature**:

- `0.1` = Sehr deterministisch, konsistent
- `0.3` = **Standard**, gute Balance
- `0.7` = Mehr Kreativität, weniger Konsistenz

### Max Tokens anpassen

Im Node **"OpenRouter LLM"** → **Options** → **Max Tokens**:

- Standard: `3000`
- Bei kurzen Responses: `1500`
- Bei komplexen Suchen: `4000`

---

## 🐛 Troubleshooting

### Problem: "Credential not found"
**Lösung:** 
1. Prüfe, ob alle 3 Credentials konfiguriert sind
2. Speichere Workflow nach Credential-Änderungen
3. Re-aktiviere Workflow

### Problem: "SerpAPI quota exceeded"
**Lösung:**
1. SerpAPI Account prüfen (gratis: 100 Suchen/Monat)
2. Upgrade auf bezahlten Plan
3. Oder: API Key rotieren (neuen Gratis-Account)

### Problem: "Agent returns no valid JSON"
**Lösung:**
1. Prüfe "Parse Agent Response" Node Logs
2. Erhöhe Max Tokens auf 4000
3. Passe System Message an für strengere JSON-Only Ausgabe

### Problem: "Google Sheets permission denied"
**Lösung:**
1. OAuth2 erneut verbinden
2. Sheet-Freigabe prüfen (Edit-Rechte für Service Account)
3. Sheet ID korrekt kopiert?

### Problem: "Keine Flüge gefunden" (obwohl verfügbar)
**Lösung:**
1. SerpAPI direkt testen: [serpapi.com/playground](https://serpapi.com/playground)
2. Prüfe ob Zielort IATA-Code bekannt ist
3. Zeitfenster eventuell zu eng (z.B. Termin 8-9 Uhr → unmöglich)

---

## 📈 Performance & Kosten

### Durchschnittliche Laufzeit
- **Input Validation:** < 100ms
- **AI Agent + SerpAPI:** 5-15 Sekunden (je nach Suchkomplexität)
- **Google Sheets Log:** < 500ms
- **Gesamt:** ~6-16 Sekunden

### API Kosten (pro Request)

| Service | Kosten | Details |
|---------|--------|---------|
| **OpenRouter** | ~$0.003 - $0.015 | Claude 3.5 Sonnet (Input+Output Token) |
| **SerpAPI** | ~$0.05 | Google Flights Search (oder gratis in Quota) |
| **Google Sheets** | $0 | Gratis (API Quotas sehr hoch) |
| **n8n** | $0 | Self-Hosted gratis, Cloud je nach Plan |
| **GESAMT** | ~$0.05 - $0.07 | Pro Flugsuche |

### Optimierungen
- **Caching:** Identische Suchen innerhalb 1h aus Cache beantworten
- **Batch Processing:** Mehrere Termine in einem Request
- **Kleineres LLM:** `anthropic/claude-3-haiku` (~10x günstiger, etwas weniger akkurat)

---

## 🔒 Sicherheit

### Empfohlene Maßnahmen

1. **IP Whitelisting** im Webhook Node aktivieren
2. **API Key Authentication** hinzufügen (custom Header)
3. **Rate Limiting** implementieren (max. 10 Requests/Minute)
4. **Google Sheet:** Nur dem Service Account Zugriff geben, nicht öffentlich

### Beispiel: API Key Auth hinzufügen

Nach "Webhook" Node einen **"IF"** Node einfügen:

```javascript
// Condition
{{ $('Webhook').item.json.headers['x-api-key'] }} equals YOUR_SECRET_KEY

// Bei Fehler: 401 Unauthorized Response
```

---

## 📚 Weiterführende Links

- [n8n Dokumentation](https://docs.n8n.io)
- [OpenRouter Models](https://openrouter.ai/models)
- [SerpAPI Google Flights Docs](https://serpapi.com/google-flights-api)
- [n8n AI Agent Node](https://docs.n8n.io/integrations/builtin/cluster-nodes/root-nodes/n8n-nodes-langchain.agent/)

---

## 🤝 Support

Bei Problemen oder Fragen:

1. **n8n Community Forum:** [community.n8n.io](https://community.n8n.io)
2. **GitHub Issues:** Öffne ein Issue im Projekt-Repository
3. **Workflow Logs prüfen:** n8n Execution History für detaillierte Error Messages

---

## 📝 Changelog

### Version 1.0 (2026-02-05)
- ✅ Initial Release
- ✅ 3-Ebenen Error Handling
- ✅ Google Sheets Logging
- ✅ Native nodes (OpenRouter, SerpAPI, Google Sheets)
- ✅ Vollständige Input Validation
- ✅ Strukturierte JSON Responses

---

**Viel Erfolg mit dem Flight Search Agent! 🚀**
