#!/bin/bash

# ============================================
# AUTOMATED TEST SCRIPT - Flight Search Agent
# ============================================
# 
# Dieses Script führt alle Test-Cases aus test-data/flight-search-test-cases.json
# automatisch gegen den produktiven n8n Workflow aus.
#
# Voraussetzungen:
# - n8n läuft auf http://localhost:5678
# - Workflow "AI Flight Search Agent" ist aktiviert
# - jq ist installiert (für JSON parsing)
#
# Usage: ./test-flight-search.sh
# ============================================

# Konfiguration
N8N_URL="http://localhost:5678/webhook/flight-search"
TEST_FILE="test-data/flight-search-test-cases.json"
RESULTS_DIR="results"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
RESULTS_FILE="${RESULTS_DIR}/test-results_${TIMESTAMP}.csv"

# Farben für Output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================
# Funktionen
# ============================================

print_header() {
    echo ""
    echo "=========================================="
    echo "  FLIGHT SEARCH AGENT - AUTOMATED TESTS  "
    echo "=========================================="
    echo ""
}

check_dependencies() {
    echo -e "${BLUE}[INFO]${NC} Prüfe Abhängigkeiten..."
    
    # Prüfe jq
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}[ERROR]${NC} jq ist nicht installiert!"
        echo "Installation: sudo apt-get install jq"
        exit 1
    fi
    
    # Prüfe curl
    if ! command -v curl &> /dev/null; then
        echo -e "${RED}[ERROR]${NC} curl ist nicht installiert!"
        exit 1
    fi
    
    # Prüfe ob Test-File existiert
    if [ ! -f "$TEST_FILE" ]; then
        echo -e "${RED}[ERROR]${NC} Test-File nicht gefunden: $TEST_FILE"
        exit 1
    fi
    
    echo -e "${GREEN}[OK]${NC} Alle Abhängigkeiten vorhanden"
}

check_n8n() {
    echo -e "${BLUE}[INFO]${NC} Prüfe n8n Verbindung..."
    
    # Teste ob n8n erreichbar ist
    if ! curl -s -o /dev/null -w "%{http_code}" "http://localhost:5678" | grep -q "200\|302"; then
        echo -e "${RED}[ERROR]${NC} n8n ist nicht erreichbar auf http://localhost:5678"
        echo "Bitte starte n8n zuerst!"
        exit 1
    fi
    
    echo -e "${GREEN}[OK]${NC} n8n läuft"
}

create_results_dir() {
    if [ ! -d "$RESULTS_DIR" ]; then
        mkdir -p "$RESULTS_DIR"
        echo -e "${BLUE}[INFO]${NC} Ergebnisordner erstellt: $RESULTS_DIR"
    fi
}

init_csv() {
    # CSV Header erstellen
    echo "Test_ID,Test_Name,Category,Status,HTTP_Status,Expected_Status,Response_Time_ms,Flights_Found,Has_Errors,Error_Messages,Timestamp" > "$RESULTS_FILE"
    echo -e "${BLUE}[INFO]${NC} CSV-Datei erstellt: $RESULTS_FILE"
}

run_test() {
    local test_id=$1
    local test_name=$2
    local category=$3
    local input=$4
    local expected_status=$5
    local expected_http=$6
    
    echo -e "${YELLOW}[TEST]${NC} $test_id: $test_name"
    
    # Start Time
    local start_time=$(date +%s%N)
    
    # API Call ausführen
    local response=$(curl -s -w "\n%{http_code}" -X POST "$N8N_URL" \
        -H "Content-Type: application/json" \
        -d "$input" 2>&1)
    
    # End Time
    local end_time=$(date +%s%N)
    local response_time=$(( (end_time - start_time) / 1000000 )) # Convert to ms
    
    # HTTP Status extrahieren (letzte Zeile)
    local http_status=$(echo "$response" | tail -n1)
    
    # Response Body extrahieren (alles außer letzte Zeile)
    local body=$(echo "$response" | sed '$d')
    
    # Parse Response
    local status=$(echo "$body" | jq -r '.status // "unknown"' 2>/dev/null)
    local flights_count=$(echo "$body" | jq -r '.ergebnis.anzahl_fluege // .flights // 0' 2>/dev/null)
    local has_errors=$(echo "$body" | jq -r 'if .errors then "yes" else "no" end' 2>/dev/null)
    local error_messages=$(echo "$body" | jq -r '.errors // [] | join("; ")' 2>/dev/null | sed 's/,/;/g')
    
    # Validierung
    local test_status="PASS"
    local status_match="✓"
    local http_match="✓"
    
    # Prüfe Status
    if [ "$status" != "$expected_status" ]; then
        test_status="FAIL"
        status_match="✗"
    fi
    
    # Prüfe HTTP Status
    if [ "$http_status" != "$expected_http" ]; then
        test_status="FAIL"
        http_match="✗"
    fi
    
    # Output
    if [ "$test_status" = "PASS" ]; then
        echo -e "  ${GREEN}✓ PASS${NC} - HTTP: $http_status $http_match, Status: $status $status_match, Time: ${response_time}ms"
    else
        echo -e "  ${RED}✗ FAIL${NC} - HTTP: $http_status $http_match (expected: $expected_http), Status: $status $status_match (expected: $expected_status)"
    fi
    
    # CSV Zeile schreiben
    local csv_line="$test_id,\"$test_name\",$category,$test_status,$http_status,$expected_status,$response_time,$flights_count,$has_errors,\"$error_messages\",$(date -Iseconds)"
    echo "$csv_line" >> "$RESULTS_FILE"
    
    # Statistik aktualisieren
    if [ "$test_status" = "PASS" ]; then
        ((TESTS_PASSED++))
    else
        ((TESTS_FAILED++))
    fi
    
    # Kurze Pause zwischen Tests
    sleep 0.5
}

run_all_tests() {
    echo ""
    echo -e "${BLUE}[INFO]${NC} Starte Tests..."
    echo ""
    
    # Statistik-Variablen
    TESTS_PASSED=0
    TESTS_FAILED=0
    
    # Test-Cases aus JSON lesen und durchlaufen
    local test_count=$(jq '.test_cases | length' "$TEST_FILE")
    
    for i in $(seq 0 $((test_count - 1))); do
        local test=$(jq ".test_cases[$i]" "$TEST_FILE")
        
        local test_id=$(echo "$test" | jq -r '.test_id')
        local test_name=$(echo "$test" | jq -r '.name')
        local category=$(echo "$test" | jq -r '.category')
        local input=$(echo "$test" | jq -c '.input')
        local expected_status=$(echo "$test" | jq -r '.expected_result.status')
        local expected_http=$(echo "$test" | jq -r '.expected_result.http_status')
        
        run_test "$test_id" "$test_name" "$category" "$input" "$expected_status" "$expected_http"
    done
}

print_summary() {
    echo ""
    echo "=========================================="
    echo "  TEST SUMMARY"
    echo "=========================================="
    echo ""
    
    local total_tests=$((TESTS_PASSED + TESTS_FAILED))
    local pass_rate=0
    
    if [ $total_tests -gt 0 ]; then
        pass_rate=$(echo "scale=1; $TESTS_PASSED * 100 / $total_tests" | bc)
    fi
    
    echo -e "Total Tests:    ${BLUE}$total_tests${NC}"
    echo -e "Passed:         ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Failed:         ${RED}$TESTS_FAILED${NC}"
    echo -e "Pass Rate:      ${YELLOW}${pass_rate}%${NC}"
    echo ""
    echo -e "Results saved:  ${BLUE}$RESULTS_FILE${NC}"
    echo ""
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}🎉 Alle Tests bestanden!${NC}"
    else
        echo -e "${RED}⚠️  Einige Tests sind fehlgeschlagen!${NC}"
    fi
    
    echo ""
}

# ============================================
# MAIN
# ============================================

main() {
    print_header
    check_dependencies
    check_n8n
    create_results_dir
    init_csv
    run_all_tests
    print_summary
}

# Script ausführen
main

exit 0
