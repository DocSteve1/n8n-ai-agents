# Prompts Directory

Dieser Ordner enthält verschiedene Prompt-Versionen für deine AI Agent Workflows.

## Struktur

```
prompts/
├── entity-extraction/
│   ├── v1.0.txt
│   ├── v1.1.txt
│   └── v2.0.txt
├── classification/
│   └── sentiment-v1.txt
└── summarization/
    └── v1.txt
```

## Verwendung

### Prompt-Versioning

Speichere verschiedene Versionen deiner Prompts, um sie zu vergleichen:

```
entity-extraction-v1.0.txt
entity-extraction-v1.1.txt
entity-extraction-v2.0.txt
```

### Format

Speichere Prompts als `.txt` oder `.md` Dateien mit Metadaten:

```markdown
---
version: 1.0
task: entity-extraction
model: gpt-4o-mini
temperature: 0.3
date: 2026-02-04
---

Task: Extract entities from text
Input: {{text}}
Output format: JSON with keys: persons, organizations, locations
...
```

### Best Practices

1. **Versioniere systematisch**: Nutze semantische Versionierung (v1.0, v1.1, v2.0)
2. **Dokumentiere Änderungen**: Füge Kommentare hinzu warum eine Version besser ist
3. **Teste parallel**: Nutze mehrere Versionen in deinen Workflows zum Vergleich
4. **Speichere Metriken**: Notiere welche Version die besten Ergebnisse liefert
