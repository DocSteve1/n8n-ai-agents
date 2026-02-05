Erstelle einen n8n AI Agent Workflow für automatische Flugsuche.

BEISPIEL USER-INPUT (via Webhook):
{
  "termin": {
    "datum": "2026-03-15",
    "zeit_von": "09:00",
    "zeit_bis": "17:00"
  },
  "ort": "Berlin"
}

ANFORDERUNGEN:

1. WEBHOOK TRIGGER
   - Empfängt JSON mit Termin + Ort
   - Validierung: Alle Felder vorhanden?

2. AI AGENT NODE
   Konfiguration:
   - Model: OpenRouter (native node!) - Modell: anthropic/claude-3.5-sonnet
   - Tool: SerpAPI Google Flights (native node!)
   
   Agent-Aufgabe:
   - Parse User-Input
   - Suche Tagesflüge von CGN/FRA/DUS zum Zielort
   - Hinflug vor Termin-Start, Rückflug nach Termin-Ende (gleicher Tag)
   - Finde beste Tagesverbindung
   - Antworte strukturiert: Status + Flüge

3. GOOGLE SHEETS OUTPUT
   Native n8n Google Sheets Node
   Spalten:
   | Timestamp | Termin | Ort | Status | Flüge | Agent-Log |

STATUS-LOGIK:
- "success": Passende Tagesflüge gefunden
- "no_flights": Keine passenden Flüge
- "error": Technischer Fehler

NATIVE NODES VERWENDEN:
✅ n8n-nodes-openrouter (für LLM)
✅ n8n-nodes-base.serpApi (für Google Flights)
✅ n8n-nodes-base.googleSheets (für Logging)
✅ n8n-nodes-base.aiAgent (AI Agent Node)
❌ KEINE HTTP Request Nodes!

WORKFLOW-STRUKTUR:
Webhook → Input Validation → AI Agent (mit SerpAPI Tool) → Parse Agent Response → Google Sheets → Response

Implementiere robusten Error Handling auf allen Ebenen.
Nutze Best Practices für Input Validation und Agent Configuration.
Erstelle einen optimierten System Prompt für den AI Agent basierend auf den Anforderungen.