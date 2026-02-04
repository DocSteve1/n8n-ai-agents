# n8n AI Agents - Rapid Prototyping Framework

Ein komplettes Setup für schnelles Prototyping von AI Agent Workflows in n8n mit Fokus auf robuste Datenverarbeitung und Multi-LLM-Testing.

## 🎯 Features

- **Robuste Workflows**: Best Practices für stabile Eingangsdaten-Verarbeitung
- **Multi-LLM Support**: OpenAI, lokale Modelle (Nemotron Nano 9B, etc.)
- **Claude Code Integration**: MCP Server für intelligente Workflow-Entwicklung
- **Testing Framework**: Systematischer Vergleich verschiedener Prompts & Modelle
- **Production-Ready Patterns**: Error Handling, Validation, Retry Logic

## 📁 Projekt-Struktur

```
n8n-ai-agents/
├── docs/
│   └── n8n-agent-guide.md          # Umfassende Dokumentation
├── mcp-server/                      # Claude Code MCP Server
│   ├── server.js                    # Server Implementation
│   ├── data/                        # Best Practices & Templates
│   └── README.md
├── workflows/                       # n8n Workflow JSONs
│   └── entity-extraction-comparison.json
├── prompts/                         # Prompt-Versionen
├── test-data/                       # Test Cases
│   └── sample-tests.json
├── results/                         # Test-Ergebnisse
├── QUICKSTART.md                    # 15-Minuten Start Guide
└── README.md                        # Diese Datei
```

## 🚀 Quick Start

### Voraussetzungen

- Node.js 18+
- n8n installiert (via npm)
- Optional: Claude Code CLI
- Optional: Ollama für lokale LLMs

### Installation (5 Minuten)

1. **MCP Server Setup**
```bash
cd mcp-server
npm install
```

2. **Lokales LLM (optional aber empfohlen)**
```bash
curl -fsSL https://ollama.com/install.sh | sh
ollama pull nemotron-nano:9b
ollama serve
```

3. **Claude Code konfigurieren** (optional)

Editiere `~/.config/claude-code/config.json`:
```json
{
  "mcpServers": {
    "n8n-ai-agents": {
      "command": "node",
      "args": ["/absoluter/pfad/zu/n8n-ai-agents/mcp-server/server.js"]
    }
  }
}
```

### Erste Schritte

**Siehe [QUICKSTART.md](QUICKSTART.md) für detaillierte Anleitung!**

## 📖 Dokumentation

### Kern-Dokumentation
- **[n8n Agent Guide](docs/n8n-agent-guide.md)** - Vollständige Anleitung für robuste Workflows
- **[Quick Start](QUICKSTART.md)** - 15-Minuten Einstieg
- **[MCP Server README](mcp-server/README.md)** - Claude Code Integration

### Wichtige Konzepte

#### 1. Robuste Datenverarbeitung
```javascript
// Immer Input validieren
const validated = {
  text: data.text || data.content || "",
  id: data.id || `gen_${Date.now()}`,
  timestamp: data.timestamp || new Date().toISOString()
};
```

#### 2. Drei-Schicht Error Handling
1. **Input Validation** - Fange schlechte Daten früh ab
2. **LLM Response Validation** - Verifiziere Outputs
3. **Retry Logic** - Exponential Backoff für transiente Fehler

#### 3. Multi-LLM Testing
- Parallele Ausführung mehrerer Modelle
- Automatischer Vergleich der Ergebnisse
- Similarity-Scoring
- Performance-Metriken

## 🛠️ Use Cases

### 1. Entity Extraction
```bash
# Mit Claude Code
claude-code
> Erstelle einen robusten Entity Extraction Workflow
```

Oder importiere: `workflows/entity-extraction-comparison.json`

### 2. Prompt Testing
```bash
> Teste 3 Prompt-Varianten für Entity Extraction mit Test-Daten
```

### 3. Model Comparison
```bash
> Vergleiche GPT-4o-mini vs Nemotron Nano für Sentiment Analysis
```

## 🎨 Workflows

### Verfügbare Templates

1. **entity-extraction-comparison.json**
   - Vergleicht OpenAI & lokales LLM
   - Robuste Validation
   - Similarity-Scoring

2. **llm-comparison** (via MCP)
   - Multi-Model Testing
   - Parallele Ausführung
   - Ergebnis-Aggregation

3. **batch-testing** (via MCP)
   - Test-Case Loader
   - Metriken-Berechnung
   - Automatische Analyse

4. **robust-pipeline** (via MCP)
   - Full Error Handling
   - Fallback Chain
   - Production-ready

## 🧪 Testing

### Test-Daten laden
```javascript
// In n8n Code Node
const fs = require('fs');
const tests = JSON.parse(
  fs.readFileSync('./test-data/sample-tests.json')
);
```

### Batch Testing
1. Lade Test Cases
2. Führe auf allen Modellen aus
3. Sammle Metriken
4. Analysiere Ergebnisse

### Metriken
- **Similarity Score** - Übereinstimmung mit Expected Output
- **Success Rate** - % erfolgreicher Durchläufe
- **Latency** - Durchschnittliche Response-Zeit
- **Cost** - Token-Kosten pro Test

## 📊 Best Practices

### Für kleine Modelle (<10B)

✅ **Do:**
- Kurze, explizite Prompts
- One Task per Prompt
- Provide Output Format Examples
- Temperature 0.3-0.4
- JSON Output mit Schema

❌ **Don't:**
- Lange, komplexe Prompts
- Multiple Tasks in einem Call
- Vage Instruktionen
- Hohe Temperature
- Freeform Text Output

### Error Handling Pattern
```javascript
try {
  const result = await callLLM();
  return validateAndParse(result);
} catch (error) {
  if (shouldRetry(error)) {
    return retryWithBackoff();
  } else {
    return fallbackStrategy();
  }
}
```

## 🔧 Claude Code Integration

Der MCP Server bietet:

### Tools
- `get_n8n_best_practices` - Best Practices abrufen
- `generate_workflow_template` - Templates generieren
- `validate_workflow_json` - Workflows validieren
- `get_prompt_template` - Optimierte Prompts
- `analyze_test_results` - Ergebnis-Analyse

### Beispiel-Nutzung
```bash
claude-code
> Erstelle einen Workflow für Sentiment Analysis der:
  - Robuste Input Validation hat
  - 3 Modelle parallel testet
  - Ergebnisse vergleicht und best performer identifiziert
```

Claude Code nutzt automatisch den MCP Server für:
- Best Practices
- Template-Generierung
- Validierung
- Optimierte Prompts

## 🎯 Workflow-Entwicklung

### Iterativer Prozess

1. **Start Simple**
   - Ein Task
   - Ein Modell
   - Minimale Validation

2. **Add Robustness**
   - Input Validation
   - Error Handling
   - Output Validation

3. **Scale Testing**
   - Mehrere Modelle
   - Batch Tests
   - Metriken sammeln

4. **Optimize**
   - Best Prompts identifizieren
   - Best Model wählen
   - Performance tunen

### Mit Claude Code
```bash
# Phase 1: Prototyp
> Erstelle einfachen Entity Extraction Workflow

# Phase 2: Robustheit
> Füge Error Handling und Validation hinzu

# Phase 3: Testing
> Erweitere für Batch Testing mit 10 Test Cases

# Phase 4: Optimierung
> Analysiere Ergebnisse und optimiere Prompts
```

## 📈 Performance-Tipps

### OpenAI (gpt-4o-mini)
- Temperature: 0.3
- Max Tokens: 300-500
- Batch ähnliche Requests
- Cache bei wiederholten Inputs

### Lokale LLMs (9B)
- Kurze Prompts (<500 tokens)
- Explizite Stop Tokens
- `num_predict` limitieren
- GPU Memory beachten

## 🤝 Contributing

Ergänzungen willkommen:
- Neue Workflow Templates
- Best Practice Patterns
- Prompt-Varianten
- Test Cases

## 📚 Ressourcen

### Dokumentation
- [n8n Docs](https://docs.n8n.io/)
- [Anthropic Prompt Engineering](https://docs.anthropic.com/claude/docs/prompt-engineering)
- [OpenAI Best Practices](https://platform.openai.com/docs/guides/prompt-engineering)

### Tools
- [Ollama](https://ollama.com) - Lokale LLMs
- [LM Studio](https://lmstudio.ai) - LLM GUI
- [Claude Code](https://claude.ai) - AI Coding Assistant

## 📝 Lizenz

MIT

## 🆘 Support

Bei Problemen:
1. Prüfe [QUICKSTART.md](QUICKSTART.md)
2. Lies [n8n-agent-guide.md](docs/n8n-agent-guide.md)
3. Checke n8n Logs
4. Verifiziere MCP Server läuft
5. Teste Ollama Endpoint

---

**Happy Prototyping! 🚀**

Erstellt für schnelles Experimentieren mit AI Agents in n8n.
