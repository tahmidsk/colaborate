#!/bin/bash
#
# Viral Genome Analysis Workflow
# Performs variant calling and consensus sequence generation for viral genomes
#
# This script demonstrates the complete workflow for analyzing Chikungunya and Zika virus genomes

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_header() {
    echo ""
    print_message "$BLUE" "=========================================="
    print_message "$BLUE" "$1"
    print_message "$BLUE" "=========================================="
    echo ""
}

# Default directories
DATA_DIR="./data"
RESULTS_DIR="./results"
CHIKV_DIR="${DATA_DIR}/chikungunya"
ZIKV_DIR="${DATA_DIR}/zika"

# Check if Python 3 is available
if ! command -v python3 &> /dev/null; then
    print_message "$RED" "Error: Python 3 is not installed or not in PATH"
    exit 1
fi

# Check if required Python packages are installed
print_header "Checking Dependencies"
python3 -c "import Bio" 2>/dev/null || {
    print_message "$YELLOW" "Warning: Biopython not installed. Installing dependencies..."
    pip install -r requirements.txt
}

# Create directories if they don't exist
mkdir -p "$RESULTS_DIR"
mkdir -p "${RESULTS_DIR}/chikungunya"
mkdir -p "${RESULTS_DIR}/zika"

print_header "Viral Genome Analysis Workflow"

# Process Chikungunya virus genomes
if [ -d "$CHIKV_DIR" ] && [ "$(ls -A $CHIKV_DIR/*.fasta 2>/dev/null)" ]; then
    print_header "Processing Chikungunya Virus Genomes"
    
    # Count FASTA files
    CHIKV_FILES=(${CHIKV_DIR}/*.fasta)
    NUM_CHIKV_FILES=${#CHIKV_FILES[@]}
    print_message "$GREEN" "Found ${NUM_CHIKV_FILES} Chikungunya genome file(s)"
    
    # Check if we have a reference sequence
    if [ -f "${CHIKV_DIR}/reference.fasta" ]; then
        CHIKV_REF="${CHIKV_DIR}/reference.fasta"
        CHIKV_SAMPLES=($(ls ${CHIKV_DIR}/*.fasta | grep -v reference.fasta))
    else
        # Use first file as reference
        CHIKV_REF="${CHIKV_FILES[0]}"
        CHIKV_SAMPLES=("${CHIKV_FILES[@]:1}")
        print_message "$YELLOW" "No reference.fasta found, using ${CHIKV_REF} as reference"
    fi
    
    # Generate consensus sequence for Chikungunya
    print_message "$GREEN" "Generating Chikungunya consensus sequence..."
    python3 consensus_generation.py \
        -i ${CHIKV_DIR}/*.fasta \
        -o ${RESULTS_DIR}/chikungunya/chikv_consensus.fasta \
        --name "CHIKV_consensus" \
        --metrics
    
    # Perform variant calling if we have samples
    if [ ${#CHIKV_SAMPLES[@]} -gt 0 ]; then
        print_message "$GREEN" "Performing variant calling for Chikungunya..."
        python3 variant_calling.py \
            -r "$CHIKV_REF" \
            -s "${CHIKV_SAMPLES[@]}" \
            -o ${RESULTS_DIR}/chikungunya/chikv_variants.vcf \
            --summary
    else
        print_message "$YELLOW" "Not enough samples for variant calling (need at least 2 files)"
    fi
else
    print_message "$YELLOW" "No Chikungunya genome files found in ${CHIKV_DIR}"
    print_message "$YELLOW" "Please place FASTA files in ${CHIKV_DIR}/"
fi

# Process Zika virus genome (S-22)
if [ -d "$ZIKV_DIR" ] && [ "$(ls -A $ZIKV_DIR/*.fasta 2>/dev/null)" ]; then
    print_header "Processing Zika Virus Genome (S-22)"
    
    # Count FASTA files
    ZIKV_FILES=(${ZIKV_DIR}/*.fasta)
    NUM_ZIKV_FILES=${#ZIKV_FILES[@]}
    print_message "$GREEN" "Found ${NUM_ZIKV_FILES} Zika genome file(s)"
    
    # Generate consensus sequence for Zika
    print_message "$GREEN" "Generating Zika virus consensus sequence..."
    python3 consensus_generation.py \
        -i ${ZIKV_DIR}/*.fasta \
        -o ${RESULTS_DIR}/zika/zikv_s22_consensus.fasta \
        --name "ZIKV_S22_consensus" \
        --metrics
    
    # Perform variant calling if we have multiple files
    if [ ${#ZIKV_FILES[@]} -gt 1 ]; then
        # Use first file as reference
        ZIKV_REF="${ZIKV_FILES[0]}"
        ZIKV_SAMPLES=("${ZIKV_FILES[@]:1}")
        
        print_message "$GREEN" "Performing variant calling for Zika virus..."
        python3 variant_calling.py \
            -r "$ZIKV_REF" \
            -s "${ZIKV_SAMPLES[@]}" \
            -o ${RESULTS_DIR}/zika/zikv_variants.vcf \
            --summary
    else
        print_message "$YELLOW" "Only one Zika genome file found, skipping variant calling"
    fi
else
    print_message "$YELLOW" "No Zika genome files found in ${ZIKV_DIR}"
    print_message "$YELLOW" "Please place FASTA files in ${ZIKV_DIR}/"
fi

# Summary
print_header "Analysis Complete"
print_message "$GREEN" "Results saved in: ${RESULTS_DIR}/"
echo ""
print_message "$BLUE" "Generated files:"
[ -f "${RESULTS_DIR}/chikungunya/chikv_consensus.fasta" ] && echo "  - ${RESULTS_DIR}/chikungunya/chikv_consensus.fasta"
[ -f "${RESULTS_DIR}/chikungunya/chikv_variants.vcf" ] && echo "  - ${RESULTS_DIR}/chikungunya/chikv_variants.vcf"
[ -f "${RESULTS_DIR}/zika/zikv_s22_consensus.fasta" ] && echo "  - ${RESULTS_DIR}/zika/zikv_s22_consensus.fasta"
[ -f "${RESULTS_DIR}/zika/zikv_variants.vcf" ] && echo "  - ${RESULTS_DIR}/zika/zikv_variants.vcf"
echo ""

print_message "$GREEN" "✓ Workflow completed successfully!"
