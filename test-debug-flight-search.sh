#!/bin/bash

# ============================================
# DEBUG TEST SCRIPT - Flight Search Agent
# ============================================
# 
# Führt EINEN einzelnen Test mit aktiviertem DEBUG-Modus aus.
# Debug-Logs erscheinen in der n8n Console/Docker Logs.
#
# Voraussetzungen:
# - n8n läuft auf http://localhost:5678
# - Workflow "AI Flight Search Agent" ist aktiviert
# - jq ist installiert (für JSON pretty-print)
#
# Usage: 
#   ./test-debug-flight-search.sh
#   
# Dann in separatem Terminal:
#   docker logs -f n8n-container
#   # oder bei direktem n8n:
#   tail -f ~/.n8n/logs/n8n.log
# ============================================

# Konfiguration
WEBHOOK_URL="http://localhost:5678/webhook-test/flight-search"

# Farben für Output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ============================================
# Test Data
# ============================================

# Wähle Test-Szenario
TEST_SCENARIO=${1:-"success"}

case $TEST_SCENARIO in
    success)
        TEST_NAME="Erfolgreiche Flugsuche - Berlin (DEBUG)"
        TEST_DATA='{
            "debug": true,
            "termin": {
                "datum": "2026-03-15",
                "zeit_von": "09:00",
                "zeit_bis": "17:00"
            },
            "ort": "Berlin"
        }'
        ;;
    
    validation_error)
        TEST_NAME="Validierungsfehler - Fehlendes Datum (DEBUG)"
        TEST_DATA='{
            "debug": true,
            "termin": {
                "zeit_von": "09:00",
                "zeit_bis": "17:00"
            },
            "ort": "Berlin"
        }'
        ;;
    
    no_flights)
        TEST_NAME="Keine Flüge - Enges Zeitfenster (DEBUG)"
        TEST_DATA='{
            "debug": true,
            "termin": {
                "datum": "2026-03-20",
                "zeit_von": "07:00",
                "zeit_bis": "08:00"
            },
            "ort": "Stuttgart"
        }'
        ;;
    
    *)
        echo -e "${RED}[ERROR]${NC} Unbekanntes Test-Szenario: $TEST_SCENARIO"
        echo ""
        echo "Verfügbare Szenarien:"
        echo "  success           - Erfolgreiche Flugsuche"
        echo "  validation_error  - Validierungsfehler"
        echo "  no_flights        - Keine Flüge gefunden"
        echo ""
        echo "Usage: ./test-debug-flight-search.sh [scenario]"
        exit 1
        ;;
esac

# ============================================
# Funktionen
# ============================================

print_header() {
    clear
    echo ""
    echo "=========================================="
    echo "  🐛 DEBUG TEST - Flight Search Agent"
    echo "=========================================="
    echo ""
}

check_dependencies() {
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}[ERROR]${NC} jq ist nicht installiert!"
        echo "Installation: sudo apt-get install jq"
        exit 1
    fi
    
    if ! command -v curl &> /dev/null; then
        echo -e "${RED}[ERROR]${NC} curl ist nicht installiert!"
        exit 1
    fi
}

check_n8n() {
    echo -e "${BLUE}[INFO]${NC} Prüfe n8n Verbindung..."
    
    if ! curl -s -o /dev/null -w "%{http_code}" "http://localhost:5678" | grep -q "200\|302"; then
        echo -e "${RED}[ERROR]${NC} n8n ist nicht erreichbar auf http://localhost:5678"
        echo "Bitte starte n8n zuerst!"
        exit 1
    fi
    
    echo -e "${GREEN}[OK]${NC} n8n läuft"
    echo ""
}

run_debug_test() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}[TEST]${NC} $TEST_NAME"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    echo -e "${BLUE}[REQUEST]${NC}"
    echo "$TEST_DATA" | jq .
    echo ""
    
    echo -e "${BLUE}[INFO]${NC} Sende Request mit DEBUG=true..."
    echo -e "${BLUE}[INFO]${NC} URL: $WEBHOOK_URL"
    echo ""
    
    # Start Time
    local start_time=$(date +%s%N)
    
    # API Call mit Timeout
    local response=$(curl -s -w "\n%{http_code}" -X POST "$WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -d "$TEST_DATA" \
        --max-time 60 \
        2>&1)
    
    # End Time
    local end_time=$(date +%s%N)
    local response_time=$(( (end_time - start_time) / 1000000 ))
    
    # HTTP Status Code (letzte Zeile)
    local http_status=$(echo "$response" | tail -n1)
    
    # Response Body (alles außer letzte Zeile)
    local body=$(echo "$response" | sed '$d')
    
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}[RESPONSE]${NC} HTTP $http_status (${response_time}ms)"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # Pretty-print Response
    if echo "$body" | jq . >/dev/null 2>&1; then
        echo "$body" | jq .
    else
        echo "$body"
    fi
    
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

show_log_hint() {
    echo -e "${YELLOW}[HINWEIS]${NC} Debug-Logs anzeigen:"
    echo ""
    echo -e "  ${CYAN}# Docker:${NC}"
    echo -e "  docker logs -f n8n-container"
    echo ""
    echo -e "  ${CYAN}# Docker Compose:${NC}"
    echo -e "  docker-compose logs -f n8n"
    echo ""
    echo -e "  ${CYAN}# Direktes n8n:${NC}"
    echo -e "  tail -f ~/.n8n/logs/n8n.log"
    echo ""
    echo -e "${YELLOW}[DEBUG OUTPUT ERWARTEN:]${NC}"
    echo -e "  🐛 DEBUG MODE ACTIVATED via webhook request"
    echo -e "  === 🔍 AGENT INTERMEDIATE STEPS ==="
    echo -e "  --- Step 1 ---"
    echo -e "  Tool: serpapi_google_flights"
    echo -e "  ..."
    echo -e "  ================================================================================
  🔍 DEBUG: RAW AGENT RESPONSE"
    echo -e "  ..."
    echo ""
}

# ============================================
# MAIN
# ============================================

main() {
    print_header
    check_dependencies
    check_n8n
    
    echo -e "${GREEN}╔═══════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  DEBUG MODUS IST AKTIVIERT (debug: true)  ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════╝${NC}"
    echo ""
    
    show_log_hint
    
    echo -e "${YELLOW}Drücke ENTER um den Test zu starten...${NC}"
    read
    
    run_debug_test
    
    echo -e "${GREEN}✅ Test abgeschlossen!${NC}"
    echo ""
    echo -e "${YELLOW}[INFO]${NC} Prüfe jetzt die n8n Logs für detaillierte Debug-Ausgaben!"
    echo ""
}

# Script ausführen
main

exit 0
