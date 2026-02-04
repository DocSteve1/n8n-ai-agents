# Quick Start Guide - n8n AI Agents

Schnelleinstieg in 15 Minuten!

## Schritt 1: MCP Server Setup (5 Minuten)

### Installation

```bash
cd n8n-ai-agents/mcp-server
npm install
```

### Test den Server

```bash
npm start
```

Du solltest sehen: `n8n AI Agents MCP Server running on stdio`

Drücke `Ctrl+C` um zu stoppen.

### Claude Code Konfiguration

Füge den Server zu deiner Claude Code Config hinzu:

**Linux:** `~/.config/claude-code/config.json`
**macOS:** `~/Library/Application Support/Claude Code/config.json`

```json
{
  "mcpServers": {
    "n8n-ai-agents": {
      "command": "node",
      "args": ["/ABSOLUTER/PFAD/ZU/n8n-ai-agents/mcp-server/server.js"]
    }
  }
}
```

**Wichtig:** Ersetze den Pfad mit deinem tatsächlichen absoluten Pfad!

Finde deinen Pfad mit:
```bash
cd n8n-ai-agents/mcp-server
pwd
```

## Schritt 2: Lokales LLM Setup (5 Minuten)

### Option A: Ollama (Empfohlen)

```bash
# Installation
curl -fsSL https://ollama.com/install.sh | sh

# Nemotron Nano herunterladen und starten
ollama pull nemotron-nano:9b
ollama serve
```

Test ob es läuft:
```bash
curl http://localhost:11434/api/generate -d '{
  "model": "nemotron-nano:9b",
  "prompt": "Hello",
  "stream": false
}'
```

### Option B: Alternatives Modell

Falls Nemotron Nano nicht verfügbar:
```bash
# Alternatives kleines Modell
ollama pull gemma2:9b
# oder
ollama pull llama3.2:3b
```

## Schritt 3: n8n Workflow erstellen (5 Minuten)

### Workflow in n8n importieren

1. Öffne n8n: `http://localhost:5678`
2. Klicke auf "+" → "Import from File" oder "Import from URL"
3. Nutze einen der Templates aus `/workflows/`

### Oder: Manuell mit Claude Code erstellen

```bash
cd n8n-ai-agents
claude-code
```

Dann im Chat:
```
Erstelle mir einen n8n Workflow für Entity Extraction der:
- OpenAI GPT-4o-mini nutzt
- Lokales LLM als Fallback hat
- Robuste Input/Output Validation hat
- Test-Daten aus test-data/sample-tests.json nutzt
```

Claude Code wird automatisch:
1. Den MCP Server nutzen für Best Practices
2. Ein Template generieren
3. Anpassen an deine Anforderungen
4. Als JSON in `/workflows/` speichern

## Schritt 4: Erster Test

### API Keys setzen

In n8n:
1. Gehe zu **Settings** → **Credentials**
2. Füge **OpenAI API** Credential hinzu
3. Trage deinen API Key ein

### Workflow testen

1. Importiere `workflows/entity-extraction-example.json`
2. Öffne den Workflow
3. Klicke auf **"Execute Workflow"**
4. Prüfe die Ergebnisse

### Mit Test-Daten

Wenn du den Batch-Test Workflow verwendest:
1. Passe den "Load Test Cases" Node an
2. Lade `test-data/sample-tests.json`
3. Führe aus und vergleiche Ergebnisse

## Nächste Schritte

### Experimentiere mit Prompts

```bash
claude-code
```

```
Gib mir 3 verschiedene Prompt-Varianten für Entity Extraction
mit einem 9B Modell. Teste sie mit den Beispieldaten.
```

### Vergleiche Modelle

Nutze den `llm-comparison` Template:
```
Erstelle einen Workflow der OpenAI, lokales LLM und 
Anthropic Claude parallel testet und Ergebnisse vergleicht.
```

### Optimiere für Robustheit

```
Analysiere meinen Workflow in workflows/my-workflow.json
und schlage Verbesserungen vor für Robustheit.
```

## Troubleshooting

### MCP Server nicht gefunden

```bash
# Prüfe Config
cat ~/.config/claude-code/config.json

# Teste Server manuell
cd n8n-ai-agents/mcp-server
node server.js
```

### Lokales LLM antwortet nicht

```bash
# Prüfe ob Ollama läuft
curl http://localhost:11434/api/tags

# Neu starten
ollama serve
```

### n8n findet Credentials nicht

1. Gehe zu **Settings** → **Credentials**
2. Erstelle neue Credential
3. Wähle den Credential-Typ im Node aus

## Tipps für Rapid Prototyping

### 1. Start klein
Beginne mit einem einfachen Task (z.B. nur Entity Extraction)

### 2. Validiere zuerst
Füge Input/Output Validation hinzu bevor du LLMs testest

### 3. Iteriere schnell
```bash
# In Claude Code
"Ändere den Prompt zu: [deine Änderung]"
"Teste mit test-data/sample-tests.json"
"Vergleiche mit vorheriger Version"
```

### 4. Dokumentiere Ergebnisse
Speichere Testergebnisse in `/results/`:
```json
{
  "test_run": "2026-02-04_15-30",
  "prompt_version": "v1.2",
  "model": "gpt-4o-mini",
  "results": [...]
}
```

## Hilfreiche Commands

```bash
# Claude Code starten
claude-code

# n8n starten (falls nicht läuft)
n8n start

# Ollama Model Liste
ollama list

# Neue Test-Daten hinzufügen
echo '{"id": "test_011", "text": "...", "expected": {...}}' >> test-data/sample-tests.json
```

## Ressourcen

- **Dokumentation:** `docs/n8n-agent-guide.md`
- **MCP Server README:** `mcp-server/README.md`
- **Test-Daten:** `test-data/sample-tests.json`
- **Beispiel Workflows:** `workflows/`

## Support

Bei Problemen:
1. Prüfe die Logs in n8n
2. Teste MCP Server manuell
3. Verifiziere Ollama läuft
4. Prüfe API Keys in n8n

**Viel Erfolg beim Prototyping! 🚀**
