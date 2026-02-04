# n8n AI Agent Development Guide
## Robuste Workflows für Rapid Prototyping mit kleinen LLMs

### Übersicht
Dieser Guide fokussiert sich auf stabile, robuste AI Agent Workflows in n8n mit Schwerpunkt auf:
- Kleine LLMs (OpenAI GPT-4o-mini, lokale Modelle wie Nemotron Nano 9B)
- Robuste Eingangsdaten-Verarbeitung
- Prompt-Testing und Vergleichbarkeit

---

## 1. Robuste Datenverarbeitung - Kernprinzipien

### 1.1 Input Validation Pattern

**Immer am Anfang jedes Workflows:**

```javascript
// In einem "Code" Node als erste Node nach dem Trigger
const input = $input.all();

// Validierung mit klaren Fallbacks
const validatedData = input.map(item => {
  const data = item.json;
  
  return {
    // Pflichtfelder mit Defaults
    text: data.text || data.content || data.message || "",
    id: data.id || `gen_${Date.now()}`,
    timestamp: data.timestamp || new Date().toISOString(),
    
    // Optionale Felder sicher extrahieren
    metadata: {
      source: data.source || "unknown",
      priority: data.priority || "normal",
      ...data.metadata
    },
    
    // Original für Debugging
    _original: data
  };
});

return validatedData;
```

**Warum das wichtig ist:**
- Verhindert Workflow-Abbrüche durch fehlende Felder
- Garantiert konsistente Datenstruktur für LLM-Nodes
- Ermöglicht saubere Fehleranalyse

### 1.2 JSON Schema Validation (für kritische Workflows)

```javascript
// Verwende JSON Schema für strikte Validation
const Ajv = require('ajv');
const ajv = new Ajv();

const schema = {
  type: "object",
  required: ["text", "id"],
  properties: {
    text: { type: "string", minLength: 1 },
    id: { type: "string" },
    metadata: { type: "object" }
  }
};

const validate = ajv.compile(schema);
const input = $input.all();

return input.filter(item => {
  const valid = validate(item.json);
  if (!valid) {
    console.error('Validation error:', validate.errors);
    // Sende invalide Daten an separaten Error-Branch
  }
  return valid;
});
```

---

## 2. LLM-Integration Patterns

### 2.1 Multi-LLM Setup für Vergleichstests

**Workflow-Struktur:**
```
Trigger → Validate Input → Split → [OpenAI] → Merge → Compare
                              ↓    [Local LLM] ↘
                              ↓    [Anthropic] ↗
```

### 2.2 OpenAI Node Konfiguration (für kleine Modelle)

**Empfohlene Settings für gpt-4o-mini:**

```json
{
  "model": "gpt-4o-mini",
  "temperature": 0.3,
  "max_tokens": 500,
  "top_p": 0.9,
  "frequency_penalty": 0.0,
  "presence_penalty": 0.0
}
```

**Warum diese Settings:**
- `temperature: 0.3` → Konsistentere Outputs, gut für Tests
- `max_tokens: 500` → Kosteneffizienz bei Prototyping
- Niedrige Penalties → Weniger Einschränkungen bei kleinen Modellen

### 2.3 Lokale LLM Integration (Nemotron Nano 9B)

**Via HTTP Request Node:**

```javascript
// Nimm an, du nutzt Ollama oder LM Studio
{
  "method": "POST",
  "url": "http://localhost:11434/api/generate",
  "headers": {
    "Content-Type": "application/json"
  },
  "body": {
    "model": "nemotron-nano:9b",
    "prompt": "={{$json.prompt}}",
    "stream": false,
    "options": {
      "temperature": 0.3,
      "top_p": 0.9,
      "num_predict": 500
    }
  }
}
```

**Error Handling für lokale LLMs:**

```javascript
// Nach HTTP Request Node
try {
  const response = $input.first().json;
  
  if (!response || !response.response) {
    return [{
      json: {
        success: false,
        error: "Empty response from local LLM",
        fallback: "LOCAL_LLM_UNAVAILABLE"
      }
    }];
  }
  
  return [{
    json: {
      success: true,
      output: response.response,
      model: "nemotron-nano-9b",
      tokens_used: response.eval_count || 0
    }
  }];
} catch (error) {
  return [{
    json: {
      success: false,
      error: error.message,
      fallback: "LOCAL_LLM_ERROR"
    }
  }];
}
```

---

## 3. Prompt Engineering für kleine Modelle

### 3.1 Strukturierte Prompts

**❌ Schlecht für kleine Modelle:**
```
Analyze this text and extract entities, classify sentiment, and suggest improvements.
```

**✅ Gut für kleine Modelle:**
```
Task: Extract entities from text
Input: {{$json.text}}
Output format: JSON with keys: persons, organizations, locations
Example: {"persons": ["John"], "organizations": ["ACME"], "locations": ["Berlin"]}
Now extract from the input above:
```

**Prinzipien:**
1. **Eine Task pro Prompt** (kein Multitasking)
2. **Explizites Output-Format** (JSON Schema angeben)
3. **Example-driven** (Few-shot wenn möglich)
4. **Kurze, klare Instruktionen**

### 3.2 Prompt-Versioning System

Speichere Prompts als JSON für einfaches Testen:

```json
{
  "version": "v1.2",
  "name": "entity-extraction",
  "prompt_template": "Task: Extract entities\nInput: {{text}}\nOutput: JSON with persons, orgs\nExtract:",
  "settings": {
    "temperature": 0.3,
    "max_tokens": 300
  },
  "test_cases": [
    {
      "input": "John works at ACME in Berlin",
      "expected": {"persons": ["John"], "organizations": ["ACME"], "locations": ["Berlin"]}
    }
  ]
}
```

### 3.3 Prompt Testing Workflow

```javascript
// Test-Node: Vergleiche Output mit Expected
const result = $('LLM_Node').first().json;
const expected = $json.expected;

// Simple Similarity Check
const similarity = calculateSimilarity(result, expected);

return [{
  json: {
    prompt_version: $json.version,
    model: $json.model,
    similarity_score: similarity,
    passed: similarity > 0.8,
    result: result,
    expected: expected,
    timestamp: new Date().toISOString()
  }
}];
```

---

## 4. Error Handling & Robustheit

### 4.1 Drei-Schicht Error Handling

**Schicht 1: Input Validation** (siehe oben)

**Schicht 2: LLM Response Validation**

```javascript
// Nach jedem LLM Node
const response = $input.first().json;

// Check 1: Response vorhanden?
if (!response || !response.output) {
  return [{
    json: {
      status: "error",
      error_type: "empty_response",
      retry: true
    }
  }];
}

// Check 2: Ist Output parseable JSON?
if ($json.expected_format === "json") {
  try {
    const parsed = JSON.parse(response.output);
    return [{ json: { status: "success", data: parsed } }];
  } catch (e) {
    return [{
      json: {
        status: "error",
        error_type: "invalid_json",
        raw_output: response.output,
        retry: true
      }
    }];
  }
}

return [{ json: { status: "success", data: response.output } }];
```

**Schicht 3: Retry Logic mit Exponential Backoff**

```javascript
// Loop Node Settings:
// Max Iterations: 3
// Loop on: status === "error" && retry === true

const attempt = $json.attempt || 1;
const backoff = Math.pow(2, attempt) * 1000; // 2s, 4s, 8s

if (attempt >= 3) {
  return [{
    json: {
      status: "failed",
      final_error: $json.error_type,
      attempts: attempt
    }
  }];
}

// Wait before retry
await new Promise(resolve => setTimeout(resolve, backoff));

return [{
  json: {
    ...($input.first().json),
    attempt: attempt + 1,
    retry: true
  }
}];
```

### 4.2 Fallback Strategy

```javascript
// Fallback Chain: GPT-4o-mini → Local LLM → Simple Rule-based
const primaryFailed = $('OpenAI').first().json.status === "error";
const secondaryFailed = $('LocalLLM').first().json.status === "error";

if (!primaryFailed) {
  return $('OpenAI').first();
} else if (!secondaryFailed) {
  return $('LocalLLM').first();
} else {
  // Fallback auf einfache Regel-basierte Logik
  return [{
    json: {
      status: "fallback",
      output: simpleRuleBasedExtraction($json.input),
      note: "All LLMs failed, used rule-based fallback"
    }
  }];
}
```

---

## 5. Testing & Vergleich Framework

### 5.1 Batch Testing Setup

**Workflow-Struktur:**
```
Load Test Cases → For Each Test → Run All Models → Collect Results → Analyze
```

**Test Case Format:**

```json
{
  "test_id": "test_001",
  "input": "Sample text for testing",
  "expected_output": {"entities": ["Sample"]},
  "models_to_test": ["gpt-4o-mini", "nemotron-nano-9b"],
  "prompt_version": "v1.2"
}
```

### 5.2 Ergebnis-Sammlung

```javascript
// Merge Node nach allen LLM-Branches
const results = $input.all();

const comparison = {
  test_id: $json.test_id,
  timestamp: new Date().toISOString(),
  models: results.map(r => ({
    model: r.json.model,
    output: r.json.output,
    latency_ms: r.json.latency,
    tokens_used: r.json.tokens,
    success: r.json.status === "success",
    similarity_to_expected: calculateSimilarity(r.json.output, $json.expected_output)
  })),
  winner: null // Wird nachher berechnet
};

// Bestimme bestes Modell für diesen Test
comparison.winner = comparison.models.reduce((best, current) => 
  current.similarity_to_expected > best.similarity_to_expected ? current : best
).model;

return [{ json: comparison }];
```

### 5.3 Metriken für Vergleich

```javascript
// Analyse-Node am Ende
const allResults = $input.all();

const metrics = {
  total_tests: allResults.length,
  models: {},
  overall_winner: null
};

// Aggregiere pro Modell
allResults.forEach(result => {
  result.json.models.forEach(modelResult => {
    if (!metrics.models[modelResult.model]) {
      metrics.models[modelResult.model] = {
        wins: 0,
        avg_similarity: 0,
        avg_latency: 0,
        success_rate: 0,
        total_tests: 0
      };
    }
    
    const m = metrics.models[modelResult.model];
    m.total_tests++;
    m.avg_similarity += modelResult.similarity_to_expected;
    m.avg_latency += modelResult.latency_ms;
    m.success_rate += modelResult.success ? 1 : 0;
    
    if (result.json.winner === modelResult.model) {
      m.wins++;
    }
  });
});

// Berechne Durchschnitte
Object.keys(metrics.models).forEach(model => {
  const m = metrics.models[model];
  m.avg_similarity /= m.total_tests;
  m.avg_latency /= m.total_tests;
  m.success_rate = (m.success_rate / m.total_tests) * 100;
});

// Bestimme Overall Winner
metrics.overall_winner = Object.entries(metrics.models)
  .reduce((best, [model, stats]) => 
    stats.avg_similarity > best.stats.avg_similarity ? 
      { model, stats } : best
  , { model: null, stats: { avg_similarity: 0 } })
  .model;

return [{ json: metrics }];
```

---

## 6. Best Practices für Rapid Prototyping

### 6.1 Workflow-Organisation

```
/workflows/
  /core/
    - base-validation.json       # Wiederverwendbare Input-Validation
    - error-handler.json         # Standard Error Handling
  /prototypes/
    - entity-extraction-v1.json
    - entity-extraction-v2.json
  /tests/
    - batch-test-runner.json
    - model-comparison.json
```

### 6.2 Schnelle Iteration

1. **Start klein**: Ein einfacher Task, ein Modell
2. **Validiere zuerst**: Input/Output Validation bevor LLM-Testing
3. **Prompt zuerst**: Optimiere Prompt bevor du Modelle vergleichst
4. **Dann skalieren**: Mehrere Modelle, größere Test-Sets

### 6.3 Debugging Tips

**Füge überall Debug-Outputs hinzu:**

```javascript
// In jedem wichtigen Node
return [{
  json: {
    // Deine normalen Daten
    ...data,
    
    // Debug Info
    _debug: {
      node_name: "Entity Extraction",
      input_received: $input.all().length,
      timestamp: new Date().toISOString(),
      execution_time: Date.now() - startTime
    }
  }
}];
```

**Nutze Set Node für Checkpoints:**
Setze zwischen wichtigen Schritten "Set" Nodes die den State speichern.

---

## 7. Lokale LLM Setup (Nemotron Nano 9B)

### 7.1 Empfohlene Tools

**Option A: Ollama (Empfohlen für Anfänger)**
```bash
# Installation
curl -fsSL https://ollama.com/install.sh | sh

# Nemotron Nano starten (wenn verfügbar)
ollama pull nemotron-nano:9b
ollama run nemotron-nano:9b

# Server läuft auf http://localhost:11434
```

**Option B: LM Studio (GUI)**
- Download von https://lmstudio.ai
- Lade Nemotron Nano Modell herunter
- Starte Local Server

**Option C: llama.cpp (Für Fortgeschrittene)**
```bash
# Build llama.cpp
git clone https://github.com/ggerganov/llama.cpp
cd llama.cpp && make

# Run model (nach Download)
./server -m models/nemotron-nano-9b.gguf -c 2048
```

### 7.2 n8n Konfiguration für lokale LLMs

**HTTP Request Node Settings:**
- Method: POST
- URL: `http://localhost:11434/api/generate` (Ollama)
- Authentication: None
- Timeout: 60000 (60 Sekunden für lokale Modelle)

**Request Body Template:**
```json
{
  "model": "nemotron-nano:9b",
  "prompt": "={{ $json.prompt }}",
  "stream": false,
  "options": {
    "temperature": 0.3,
    "top_p": 0.9,
    "top_k": 40,
    "num_predict": 500,
    "stop": ["</s>", "\n\n"]
  }
}
```

### 7.3 Performance Optimierung

**Für 9B Modelle:**
- Halte Prompts kurz (< 500 tokens input)
- Nutze `num_predict` um Output zu limitieren
- Setze `top_k: 40` für bessere Fokussierung
- Verwende `stop` tokens um unendliche Generation zu vermeiden

---

## 8. Quick Start Checkliste

### Setup (15 Minuten)
- [ ] n8n läuft lokal
- [ ] Ollama installiert mit Nemotron Nano
- [ ] OpenAI API Key in n8n Credentials
- [ ] Test-Daten vorbereitet (5-10 Beispiele)

### Erster Workflow (30 Minuten)
- [ ] Input Validation Node erstellt
- [ ] OpenAI Node konfiguriert (gpt-4o-mini)
- [ ] HTTP Request Node für lokales LLM
- [ ] Error Handling implementiert
- [ ] Test mit einem Beispiel erfolgreich

### Testing Framework (1 Stunde)
- [ ] Batch Test Workflow erstellt
- [ ] Prompt-Versioning implementiert
- [ ] Ergebnis-Sammlung funktioniert
- [ ] Metriken werden berechnet

### Iteration (laufend)
- [ ] Prompt-Varianten testen
- [ ] Modelle vergleichen
- [ ] Best Performer identifiziert
- [ ] In Production Workflow integrieren

---

## 9. Häufige Probleme & Lösungen

### Problem: Lokales LLM antwortet nicht
```javascript
// Timeout & Retry Handling
const timeout = 30000; // 30 Sekunden

try {
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), timeout);
  
  const response = await fetch('http://localhost:11434/api/generate', {
    method: 'POST',
    body: JSON.stringify({...}),
    signal: controller.signal
  });
  
  clearTimeout(timeoutId);
  return response.json();
} catch (error) {
  if (error.name === 'AbortError') {
    // Fallback zu OpenAI
    return await callOpenAI();
  }
  throw error;
}
```

### Problem: Inkonsistente JSON Outputs
```javascript
// JSON Extraction mit Fallback
function extractJSON(text) {
  // Versuch 1: Direktes Parsing
  try {
    return JSON.parse(text);
  } catch (e) {}
  
  // Versuch 2: Extrahiere JSON aus Markdown
  const jsonMatch = text.match(/```json\n(.*?)\n```/s);
  if (jsonMatch) {
    try {
      return JSON.parse(jsonMatch[1]);
    } catch (e) {}
  }
  
  // Versuch 3: Finde JSON-ähnliche Struktur
  const objectMatch = text.match(/\{.*\}/s);
  if (objectMatch) {
    try {
      return JSON.parse(objectMatch[0]);
    } catch (e) {}
  }
  
  // Fallback: Strukturiertes Error Object
  return {
    error: "Could not extract JSON",
    raw_output: text,
    status: "parse_failed"
  };
}
```

### Problem: Zu hohe Kosten bei Tests
```javascript
// Cost Tracking pro Test
const costs = {
  "gpt-4o-mini": 0.00015 / 1000, // $ per token
  "nemotron-nano-9b": 0 // lokal
};

function calculateCost(model, tokens) {
  return (costs[model] || 0) * tokens;
}

// In Ergebnis-Node
const totalCost = results.reduce((sum, r) => 
  sum + calculateCost(r.model, r.tokens_used), 0
);

console.log(`Test cost: $${totalCost.toFixed(4)}`);
```

---

## 10. Nächste Schritte

### Phase 1: Grundlagen (Woche 1)
1. Ersten einfachen Workflow mit Input Validation
2. OpenAI Integration testen
3. Lokales LLM zum Laufen bringen

### Phase 2: Robustheit (Woche 2)
1. Error Handling in allen Workflows
2. Retry Logic implementieren
3. Fallback Strategies testen

### Phase 3: Testing (Woche 3)
1. Batch Test Framework aufbauen
2. Mindestens 3 Prompt-Varianten testen
3. Modelle vergleichen (OpenAI vs. Local)

### Phase 4: Optimierung (Woche 4)
1. Best Prompts identifiziert
2. Performance-Tuning
3. Production-ready Workflow

---

## Ressourcen

### n8n Dokumentation
- https://docs.n8n.io/
- https://docs.n8n.io/code-examples/

### LLM Tools
- Ollama: https://ollama.com
- LM Studio: https://lmstudio.ai
- llama.cpp: https://github.com/ggerganov/llama.cpp

### Prompt Engineering
- Anthropic Prompt Engineering: https://docs.anthropic.com/claude/docs/prompt-engineering
- OpenAI Best Practices: https://platform.openai.com/docs/guides/prompt-engineering

---

**Version:** 1.0  
**Letzte Aktualisierung:** 2026-02-04  
**Für:** Rapid Prototyping mit kleinen LLMs in n8n
