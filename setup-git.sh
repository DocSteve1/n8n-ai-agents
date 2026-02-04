#!/bin/bash

# Git Repository Setup für n8n AI Agents
# Führe dieses Script aus um das Projekt für GitHub vorzubereiten

echo "🚀 Initialisiere Git Repository..."

# Git initialisieren
git init

# Initial Commit
git add .
git commit -m "Initial commit: n8n AI Agents Rapid Prototyping Framework

- MCP Server für Claude Code Integration
- Umfassende Dokumentation
- Workflow Templates
- Test-Daten und Prompt Library
- Best Practices für robuste AI Workflows"

echo "✓ Git Repository initialisiert"
echo ""
echo "📋 Nächste Schritte:"
echo ""
echo "1. Erstelle ein Repository auf GitHub"
echo "2. Füge Remote hinzu:"
echo "   git remote add origin https://github.com/DEIN-USERNAME/n8n-ai-agents.git"
echo ""
echo "3. Push zum Repository:"
echo "   git branch -M main"
echo "   git push -u origin main"
echo ""
echo "Optional - GitHub CLI nutzen:"
echo "   gh repo create n8n-ai-agents --public --source=. --remote=origin"
echo "   git push -u origin main"
