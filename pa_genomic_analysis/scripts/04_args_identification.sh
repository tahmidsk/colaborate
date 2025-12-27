#!/bin/bash

################################################################################
# Step 4: Antibiotic Resistance Genes (ARGs) Identification
# 
# This script performs:
# - ARG detection using ResFinder database
# - ARG detection using CARD (Comprehensive Antibiotic Resistance Database)
# - Resistance profile generation
################################################################################

set -euo pipefail

# Parse arguments
INPUT_DIR=""
OUTPUT_DIR=""
THREADS=8

while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--input) INPUT_DIR="$2"; shift 2 ;;
        -o|--output) OUTPUT_DIR="$2"; shift 2 ;;
        -t|--threads) THREADS="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# Create output directories
ARG_DIR="${OUTPUT_DIR}/antibiotic_resistance"
RESFINDER_DIR="${ARG_DIR}/resfinder"
CARD_DIR="${ARG_DIR}/card"

mkdir -p "$RESFINDER_DIR"
mkdir -p "$CARD_DIR"

echo "Step 4.1: ARG Detection with ResFinder Database"
echo "==============================================="

# Find all assembled contigs
CONTIGS=($(find "$INPUT_DIR" -name "*_contigs.fasta" -o -name "*.fasta"))

if [[ ${#CONTIGS[@]} -eq 0 ]]; then
    echo "Error: No assembly files found in $INPUT_DIR"
    exit 1
fi

echo "Found ${#CONTIGS[@]} genomes to analyze"

# Run ABRicate with ResFinder database
echo ""
echo "Running ABRicate with ResFinder database..."

for CONTIG in "${CONTIGS[@]}"; do
    SAMPLE=$(basename "$CONTIG" | sed 's/_contigs.fasta//' | sed 's/.fasta//')
    
    echo "Analyzing sample: $SAMPLE (ResFinder)"
    
    abricate \
        --db resfinder \
        --threads "$THREADS" \
        --minid 90 \
        --mincov 60 \
        "$CONTIG" \
        > "${RESFINDER_DIR}/${SAMPLE}_resfinder.tsv"
    
    # Count detected genes
    GENE_COUNT=$(tail -n +2 "${RESFINDER_DIR}/${SAMPLE}_resfinder.tsv" | wc -l)
    echo "  Resistance genes found: $GENE_COUNT"
done

# Create summary for ResFinder
echo ""
echo "Creating ResFinder summary..."
abricate --summary "${RESFINDER_DIR}"/*_resfinder.tsv > "${RESFINDER_DIR}/resfinder_summary.tsv"

echo ""
echo "Step 4.2: ARG Detection with CARD Database"
echo "=========================================="

echo "Running ABRicate with CARD database..."

for CONTIG in "${CONTIGS[@]}"; do
    SAMPLE=$(basename "$CONTIG" | sed 's/_contigs.fasta//' | sed 's/.fasta//')
    
    echo "Analyzing sample: $SAMPLE (CARD)"
    
    abricate \
        --db card \
        --threads "$THREADS" \
        --minid 90 \
        --mincov 60 \
        "$CONTIG" \
        > "${CARD_DIR}/${SAMPLE}_card.tsv"
    
    # Count detected genes
    GENE_COUNT=$(tail -n +2 "${CARD_DIR}/${SAMPLE}_card.tsv" | wc -l)
    echo "  Resistance genes found: $GENE_COUNT"
done

# Create summary for CARD
echo ""
echo "Creating CARD summary..."
abricate --summary "${CARD_DIR}"/*_card.tsv > "${CARD_DIR}/card_summary.tsv"

echo ""
echo "Step 4.3: Alternative - RGI (CARD native tool) if available"
echo "==========================================================="

if command -v rgi &> /dev/null; then
    RGI_DIR="${ARG_DIR}/rgi"
    mkdir -p "$RGI_DIR"
    
    echo "Running RGI (Resistance Gene Identifier)..."
    
    for CONTIG in "${CONTIGS[@]}"; do
        SAMPLE=$(basename "$CONTIG" | sed 's/_contigs.fasta//' | sed 's/.fasta//')
        
        echo "Analyzing sample: $SAMPLE (RGI)"
        
        rgi main \
            --input_sequence "$CONTIG" \
            --output_file "${RGI_DIR}/${SAMPLE}_rgi" \
            --input_type contig \
            --alignment_tool BLAST \
            --num_threads "$THREADS" \
            --clean
    done
else
    echo "Note: RGI not installed, using ABRicate only"
    echo "  For enhanced CARD analysis, install RGI: pip install rgi"
fi

echo ""
echo "Step 4.4: Generating comprehensive resistance profile"
echo "===================================================="

# Create comprehensive report
cat > "${ARG_DIR}/resistance_profile.txt" << EOF
Antibiotic Resistance Gene Analysis Summary
============================================
Generated: $(date)

Analysis Methods:
-----------------
1. ResFinder Database (via ABRicate)
2. CARD Database (via ABRicate)

ResFinder Results Summary:
--------------------------
$(cat ${RESFINDER_DIR}/resfinder_summary.tsv)

CARD Results Summary:
---------------------
$(cat ${CARD_DIR}/card_summary.tsv)

Detailed Results by Sample:
---------------------------
EOF

for CONTIG in "${CONTIGS[@]}"; do
    SAMPLE=$(basename "$CONTIG" | sed 's/_contigs.fasta//' | sed 's/.fasta//')
    
    cat >> "${ARG_DIR}/resistance_profile.txt" << EOF

Sample: $SAMPLE
===============

ResFinder Genes:
$(tail -n +2 ${RESFINDER_DIR}/${SAMPLE}_resfinder.tsv | cut -f5,6,9,10 | sort -u)

CARD Genes:
$(tail -n +2 ${CARD_DIR}/${SAMPLE}_card.tsv | cut -f5,6,9,10 | sort -u)

---
EOF
done

# Generate antibiotic class summary
echo ""
echo "Generating antibiotic class distribution..."

cat > "${ARG_DIR}/antibiotic_classes.txt" << EOF
Antibiotic Resistance Classes Detected
======================================

EOF

for SAMPLE_TSV in "${RESFINDER_DIR}"/*_resfinder.tsv; do
    SAMPLE=$(basename "$SAMPLE_TSV" | sed 's/_resfinder.tsv//')
    
    echo "Sample: $SAMPLE" >> "${ARG_DIR}/antibiotic_classes.txt"
    
    if [[ -f "$SAMPLE_TSV" ]]; then
        tail -n +2 "$SAMPLE_TSV" | cut -f9 | sort -u | sed 's/^/  - /' >> "${ARG_DIR}/antibiotic_classes.txt"
    fi
    
    echo "" >> "${ARG_DIR}/antibiotic_classes.txt"
done

echo ""
echo "Step 4 completed successfully!"
echo "Results:"
echo "  - ResFinder results: ${RESFINDER_DIR}"
echo "  - CARD results: ${CARD_DIR}"
echo "  - Resistance profile: ${ARG_DIR}/resistance_profile.txt"
echo "  - Antibiotic classes: ${ARG_DIR}/antibiotic_classes.txt"
