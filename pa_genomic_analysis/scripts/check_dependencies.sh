#!/bin/bash

################################################################################
# Dependency Checker for PA Genomic Analysis Pipeline
# 
# This script verifies that all required tools are installed and accessible
################################################################################

echo "=========================================="
echo "PA Genomic Analysis Pipeline"
echo "Dependency Checker"
echo "=========================================="
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
TOTAL=0
INSTALLED=0
MISSING=0

# Function to check tool
check_tool() {
    local tool=$1
    local expected_version=$2
    local optional=$3
    
    TOTAL=$((TOTAL + 1))
    
    if command -v "$tool" &> /dev/null; then
        version=$($tool --version 2>&1 | head -1 || echo "unknown")
        echo -e "${GREEN}✓${NC} $tool - FOUND"
        if [ ! -z "$expected_version" ]; then
            echo "    Version: $version"
        fi
        INSTALLED=$((INSTALLED + 1))
        return 0
    else
        if [ "$optional" = "optional" ]; then
            echo -e "${YELLOW}○${NC} $tool - NOT FOUND (optional)"
        else
            echo -e "${RED}✗${NC} $tool - NOT FOUND (required)"
            MISSING=$((MISSING + 1))
        fi
        return 1
    fi
}

echo "Checking Core Analysis Tools:"
echo "------------------------------"
check_tool "fastqc" "0.12.1"
check_tool "fastp" "0.23.2"
check_tool "spades.py" "3.14.1"
check_tool "quast.py" "5.2.0"
check_tool "prokka" "1.13.4+"
check_tool "kraken" "1.1.1"

echo ""
echo "Checking Typing Tools:"
echo "----------------------"
check_tool "mlst" "2.23+"
check_tool "past" "1.0" "optional"

echo ""
echo "Checking Variant Analysis Tools:"
echo "---------------------------------"
check_tool "snippy" "4.3.6+"
check_tool "snippy-core" "4.3.6+"
check_tool "FastTree" "" "optional"

echo ""
echo "Checking Resistance & Virulence Tools:"
echo "---------------------------------------"
check_tool "abricate" "0.8.13+"
check_tool "rgi" "" "optional"

echo ""
echo "Checking Comparative Genomics Tools:"
echo "-------------------------------------"
check_tool "roary" "3.13.0"
check_tool "parsnp" "1.7.4"

echo ""
echo "Checking System Tools:"
echo "----------------------"
check_tool "java"
check_tool "perl"
check_tool "python3"
check_tool "git"

echo ""
echo "=========================================="
echo "Summary"
echo "=========================================="
echo "Total tools checked: $TOTAL"
echo -e "Installed: ${GREEN}$INSTALLED${NC}"
echo -e "Missing: ${RED}$MISSING${NC}"

echo ""

# Check databases
echo "Checking Databases:"
echo "-------------------"

# Kraken database
if [ ! -z "${KRAKEN_DB:-}" ] && [ -d "$KRAKEN_DB" ]; then
    echo -e "${GREEN}✓${NC} Kraken database: $KRAKEN_DB"
else
    echo -e "${YELLOW}○${NC} Kraken database: Not configured (set KRAKEN_DB environment variable)"
fi

# ABRicate databases
if command -v abricate &> /dev/null; then
    echo ""
    echo "ABRicate databases:"
    abricate --list 2>/dev/null || echo "  Could not list databases"
fi

echo ""
echo "=========================================="

if [ $MISSING -eq 0 ]; then
    echo -e "${GREEN}✓ All required tools are installed!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Configure Kraken database (if not already done)"
    echo "2. Setup ABRicate databases: abricate-get_db --db resfinder --force"
    echo "3. Read the documentation: docs/WORKFLOW.md"
    echo "4. Run the example: examples/example_analysis.sh"
    exit 0
else
    echo -e "${RED}✗ Some required tools are missing${NC}"
    echo ""
    echo "Installation instructions:"
    echo "1. See docs/INSTALLATION.md for detailed instructions"
    echo "2. Quick install with Conda:"
    echo "   conda create -n pa_analysis python=3.9"
    echo "   conda activate pa_analysis"
    echo "   conda install -c bioconda fastqc fastp spades quast prokka kraken mlst snippy abricate roary parsnp"
    exit 1
fi
