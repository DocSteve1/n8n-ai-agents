# MCP Server Update - Native Node Support

## ✨ Neue Features

### 1. Native Node Best Practices

Der MCP Server bevorzugt jetzt **native n8n API Nodes** statt generischer HTTP Request Nodes.

**Neue Best Practice Kategorie:** `node-selection`

```bash
# In Claude Code
> Zeige mir Best Practices für Node Selection
```

### 2. Neues Tool: `find_native_node`

Prüft ob ein nativer Node für einen Service existiert.

**Verwendung in Claude Code:**
```
> Hat n8n einen nativen Node für OpenRouter?
> Gibt es einen SerpAPI Node für Google Flights?
> Welcher Node für Anthropic Claude?
```

**Antwort enthält:**
- ✅/❌ Ob nativer Node existiert
- Node-Typ (z.B. `n8n-nodes-openrouter`)
- Features des Nodes
- Vorteile gegenüber HTTP Request
- Alternative Lösungen falls kein Node existiert

### 3. Neue Workflow Templates

**llm-comparison-openrouter** - Nutzt native OpenRouter Node

Vergleicht mehrere Modelle über OpenRouter:
- Claude 3.5 Sonnet
- GPT-4o-mini  
- Llama 3.2 3B

**Vorteile:**
- Modell-Auswahl via Dropdown (keine Code-Änderungen)
- Automatische Authentifizierung
- Sichere Credential-Verwaltung
- Built-in Rate Limiting

## 📚 Unterstützte native Nodes

### AI Models
- **OpenRouter** (`n8n-nodes-openrouter`) - Zugriff auf viele Modelle
- **Anthropic** (`n8n-nodes-base.anthropic`) - Claude Modelle
- **OpenAI** (`n8n-nodes-base.openAi`) - GPT Modelle

### Search APIs
- **SerpAPI** (`n8n-nodes-base.serpApi`) - Google Flights, Search, Shopping, News
- **Google Search Console** (`n8n-nodes-base.googleSearchConsole`)

### Data Services
- **Airtable** (`n8n-nodes-base.airtable`)
- **Google Sheets** (`n8n-nodes-base.googleSheets`)
- **Notion** (`n8n-nodes-base.notion`)

### Communication
- **Slack** (`n8n-nodes-base.slack`)
- **Discord** (`n8n-nodes-base.discord`)

*Und viele mehr - siehe Best Practices!*

## 🔄 Migration

### Vorher: HTTP Request für OpenRouter
```javascript
// HTTP Request Node
{
  "method": "POST",
  "url": "https://openrouter.ai/api/v1/chat/completions",
  "headers": {
    "Authorization": "Bearer YOUR_API_KEY"
  },
  "body": {
    "model": "anthropic/claude-3.5-sonnet",
    "messages": [...]
  }
}
```

**Probleme:**
- Manuelle API Key Verwaltung
- Keine Modell-Dropdown
- Keys im Workflow JSON sichtbar
- Kein Rate Limiting

### Nachher: Native OpenRouter Node
```javascript
// OpenRouter Node
{
  "model": "anthropic/claude-3.5-sonnet",  // Dropdown!
  "prompt": "={{$json.prompt}}",
  "credentials": "openRouterApi"  // Sicher!
}
```

**Vorteile:**
- ✅ Dropdown mit allen Modellen
- ✅ Automatische Authentifizierung  
- ✅ Sichere Credentials
- ✅ Rate Limiting
- ✅ Bessere Error Messages

## 🚀 Verwendung

### In Claude Code

**Workflow erstellen:**
```
> Erstelle einen Workflow der Google Flights über SerpAPI abfragt
```

Claude Code wird automatisch:
1. `find_native_node("serpapi")` aufrufen
2. Erkennen dass `n8n-nodes-base.serpApi` existiert
3. Nativen Node statt HTTP Request verwenden

**Node-Lookup:**
```
> Welchen Node soll ich für Slack Nachrichten nutzen?
> Hat n8n Support für Anthropic Claude?
```

## 📝 Installation

### Update bestehender MCP Server

```bash
cd ~/mcp-servers/n8n-mcp-tools
git pull
npm install  # Falls neue Dependencies
```

### Neuinstallation

```bash
mkdir -p ~/mcp-servers
cd ~/mcp-servers
git clone https://github.com/DEIN-USERNAME/n8n-mcp-tools.git
cd n8n-mcp-tools
npm install
```

Restart VSCode / Claude Code nach dem Update.

## 🎯 Best Practices

### 1. Immer zuerst nach nativem Node suchen

```
> Ich will API X nutzen - gibt es einen nativen Node?
```

### 2. HTTP Request nur als Fallback

Nur verwenden wenn:
- Kein nativer Node existiert
- Custom/Internal API
- Test-Zwecke

### 3. Credentials in n8n verwalten

**Settings > Credentials** in n8n:
- Erstelle Credential für Service
- Nutze in Nodes
- Keine API Keys im Code!

## 🐛 Troubleshooting

**"Node nicht gefunden":**
- Prüfe ob Node installiert ist
- Community Nodes: `npm install n8n-nodes-openrouter`
- Suche in n8n UI Node-Panel

**"Credentials fehlen":**
- Gehe zu Settings > Credentials in n8n
- Erstelle neue Credential für den Service
- Wähle im Node aus

## 📚 Weitere Infos

- [n8n Integrations](https://docs.n8n.io/integrations/)
- [n8n Community Nodes](https://www.npmjs.com/search?q=n8n-nodes)
- [OpenRouter Models](https://openrouter.ai/models)
- [SerpAPI Docs](https://serpapi.com/docs)

---

**Version:** 1.1.0  
**Datum:** 2026-02-04
