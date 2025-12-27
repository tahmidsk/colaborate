#!/bin/bash

################################################################################
# Step 2: MLST and Serotyping
# 
# This script performs:
# - Multi-Locus Sequence Typing (MLST) using PubMLST
#   Based on 7 housekeeping genes: acsA, aroE, guaA, mutL, nuoD, ppsA, trpE
# - O antigen serotyping using PAst (Pseudomonas aeruginosa serotyper) v1.0
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
MLST_DIR="${OUTPUT_DIR}/mlst"
SEROTYPE_DIR="${OUTPUT_DIR}/serotype"

mkdir -p "$MLST_DIR"
mkdir -p "$SEROTYPE_DIR"

echo "Step 2.1: Multi-Locus Sequence Typing (MLST)"
echo "============================================"

# Find all assembled contigs
CONTIGS=($(find "$INPUT_DIR" -name "*_contigs.fasta" -o -name "*.fasta"))

if [[ ${#CONTIGS[@]} -eq 0 ]]; then
    echo "Error: No assembly files found in $INPUT_DIR"
    exit 1
fi

echo "Found ${#CONTIGS[@]} genomes to analyze"

# Run MLST on each assembly
echo "Running MLST analysis..."
mlst --scheme paer "${CONTIGS[@]}" > "${MLST_DIR}/mlst_results.tsv"

# Generate detailed report for each sample
echo ""
echo "MLST Results:"
echo "============="
cat "${MLST_DIR}/mlst_results.tsv"

# Parse MLST results and create individual reports
while IFS=$'\t' read -r file scheme st gene1 gene2 gene3 gene4 gene5 gene6 gene7; do
    if [[ "$file" == "FILE" ]]; then
        continue
    fi
    
    SAMPLE=$(basename "$file" | sed 's/_contigs.fasta//' | sed 's/.fasta//')
    
    cat > "${MLST_DIR}/${SAMPLE}_mlst_detail.txt" << EOF
Sample: $SAMPLE
Scheme: $scheme
Sequence Type (ST): $st

Housekeeping Genes:
  acsA:  $gene1
  aroE:  $gene2
  guaA:  $gene3
  mutL:  $gene4
  nuoD:  $gene5
  ppsA:  $gene6
  trpE:  $gene7
EOF

    echo "  $SAMPLE: ST-$st"
done < "${MLST_DIR}/mlst_results.tsv"

echo ""
echo "Step 2.2: O antigen serotyping with PAst"
echo "========================================"

# Check if PAst is available
if command -v past &> /dev/null; then
    echo "Running PAst serotyping..."
    
    for CONTIG in "${CONTIGS[@]}"; do
        SAMPLE=$(basename "$CONTIG" | sed 's/_contigs.fasta//' | sed 's/.fasta//')
        
        echo "Serotyping sample: $SAMPLE"
        
        # Run PAst
        past \
            -i "$CONTIG" \
            -o "${SEROTYPE_DIR}/${SAMPLE}_serotype.txt"
        
        # Display result
        if [[ -f "${SEROTYPE_DIR}/${SAMPLE}_serotype.txt" ]]; then
            echo "  Result: $(cat ${SEROTYPE_DIR}/${SAMPLE}_serotype.txt)"
        fi
    done
else
    echo "Warning: PAst not found, performing BLAST-based serotyping..."
    
    # Alternative: Use ABRicate with custom O-antigen database if available
    if command -v abricate &> /dev/null; then
        for CONTIG in "${CONTIGS[@]}"; do
            SAMPLE=$(basename "$CONTIG" | sed 's/_contigs.fasta//' | sed 's/.fasta//')
            
            echo "Serotyping sample: $SAMPLE (using ABRicate)"
            
            abricate \
                --db ecoh \
                --quiet \
                "$CONTIG" \
                > "${SEROTYPE_DIR}/${SAMPLE}_serotype.tsv"
        done
    else
        echo "Note: Install PAst for proper O-antigen serotyping"
        echo "  Git: https://github.com/zhaoqianyue/PAst"
        
        # Create placeholder files
        for CONTIG in "${CONTIGS[@]}"; do
            SAMPLE=$(basename "$CONTIG" | sed 's/_contigs.fasta//' | sed 's/.fasta//')
            echo "Serotype determination requires PAst installation" > "${SEROTYPE_DIR}/${SAMPLE}_serotype.txt"
        done
    fi
fi

echo ""
echo "Step 2.3: Generating summary report"
echo "==================================="

# Create comprehensive summary
cat > "${OUTPUT_DIR}/typing_summary.txt" << EOF
Pseudomonas aeruginosa MLST and Serotyping Summary
==================================================
Generated: $(date)

MLST Results:
-------------
$(cat ${MLST_DIR}/mlst_results.tsv)

Serotype Results:
-----------------
EOF

for SAMPLE_DIR in "${SEROTYPE_DIR}"/*_serotype.txt; do
    if [[ -f "$SAMPLE_DIR" ]]; then
        SAMPLE=$(basename "$SAMPLE_DIR" | sed 's/_serotype.txt//')
        echo "Sample $SAMPLE:" >> "${OUTPUT_DIR}/typing_summary.txt"
        cat "$SAMPLE_DIR" >> "${OUTPUT_DIR}/typing_summary.txt"
        echo "" >> "${OUTPUT_DIR}/typing_summary.txt"
    fi
done

echo ""
echo "Step 2 completed successfully!"
echo "Results:"
echo "  - MLST: ${MLST_DIR}"
echo "  - Serotypes: ${SEROTYPE_DIR}"
echo "  - Summary: ${OUTPUT_DIR}/typing_summary.txt"
