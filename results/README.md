# Results Directory

Dieser Ordner speichert die Ergebnisse deiner Test-Runs und Experimente.

## Struktur

```
results/
├── 2026-02-04_entity-extraction-test.json
├── 2026-02-05_model-comparison.json
└── experiments/
    └── prompt-variants-test.json
```

## Format

### Test Results Format

```json
{
  "test_run": "2026-02-04_15-30",
  "task": "entity-extraction",
  "prompt_version": "v1.2",
  "models_tested": ["gpt-4o-mini", "nemotron-nano-9b"],
  "test_cases": 10,
  "results": [
    {
      "test_id": "test_001",
      "model": "gpt-4o-mini",
      "similarity_score": 0.95,
      "latency_ms": 1250,
      "success": true
    }
  ],
  "summary": {
    "best_model": "gpt-4o-mini",
    "avg_similarity": 0.92,
    "total_cost": 0.015
  }
}
```

## Naming Convention

**Format:** `YYYY-MM-DD_task-name_optional-description.json`

Beispiele:
- `2026-02-04_entity-extraction-baseline.json`
- `2026-02-05_sentiment-analysis-model-comparison.json`
- `2026-02-06_prompt-optimization-round-1.json`

## Best Practices

1. **Timestamp**: Nutze ISO-Datum im Dateinamen
2. **Beschreibend**: Beschreibe was getestet wurde
3. **Versioniere**: Referenziere Prompt-Versionen
4. **Dokumentiere**: Füge Summary und Learnings hinzu

## Export aus n8n

In deinem n8n Workflow kannst du Ergebnisse so speichern:

```javascript
// In einem "Write Binary File" Node
const results = $input.all()[0].json;
const filename = `results/${new Date().toISOString().split('T')[0]}_${results.task}.json`;

return [{
  json: {},
  binary: {
    data: {
      data: Buffer.from(JSON.stringify(results, null, 2)).toString('base64'),
      mimeType: 'application/json',
      fileName: filename
    }
  }
}];
```
