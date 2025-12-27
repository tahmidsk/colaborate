#!/bin/bash

################################################################################
# Step 5: Virulence Factor Identification
# 
# This script performs:
# - Virulence factor detection using ABRicate v0.8.13
# - VFDB (Virulence Factor Database) analysis
# - Pathogenicity assessment
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
VF_DIR="${OUTPUT_DIR}/virulence_factors"
VFDB_DIR="${VF_DIR}/vfdb"

mkdir -p "$VFDB_DIR"

echo "Step 5.1: Virulence Factor Detection with ABRicate"
echo "=================================================="

# Find all assembled contigs
CONTIGS=($(find "$INPUT_DIR" -name "*_contigs.fasta" -o -name "*.fasta"))

if [[ ${#CONTIGS[@]} -eq 0 ]]; then
    echo "Error: No assembly files found in $INPUT_DIR"
    exit 1
fi

echo "Found ${#CONTIGS[@]} genomes to analyze"

# Run ABRicate with VFDB database
echo ""
echo "Running ABRicate with VFDB (Virulence Factor Database)..."

for CONTIG in "${CONTIGS[@]}"; do
    SAMPLE=$(basename "$CONTIG" | sed 's/_contigs.fasta//' | sed 's/.fasta//')
    
    echo "Analyzing sample: $SAMPLE"
    
    abricate \
        --db vfdb \
        --threads "$THREADS" \
        --minid 80 \
        --mincov 60 \
        "$CONTIG" \
        > "${VFDB_DIR}/${SAMPLE}_vfdb.tsv"
    
    # Count detected virulence factors
    VF_COUNT=$(tail -n +2 "${VFDB_DIR}/${SAMPLE}_vfdb.tsv" | wc -l)
    echo "  Virulence factors found: $VF_COUNT"
    
    # Create individual report
    cat > "${VFDB_DIR}/${SAMPLE}_vf_report.txt" << EOF
Virulence Factor Analysis Report
=================================
Sample: $SAMPLE
Analysis Date: $(date)

Total Virulence Factors: $VF_COUNT

Detected Virulence Factors:
---------------------------
EOF
    
    if [[ $VF_COUNT -gt 0 ]]; then
        tail -n +2 "${VFDB_DIR}/${SAMPLE}_vfdb.tsv" | \
            awk -F'\t' '{print "- " $6 " (" $5 ") - " $9}' \
            >> "${VFDB_DIR}/${SAMPLE}_vf_report.txt"
    else
        echo "No virulence factors detected with current thresholds" \
            >> "${VFDB_DIR}/${SAMPLE}_vf_report.txt"
    fi
done

# Create summary for VFDB
echo ""
echo "Creating VFDB summary..."
abricate --summary "${VFDB_DIR}"/*_vfdb.tsv > "${VFDB_DIR}/vfdb_summary.tsv"

echo ""
echo "Step 5.2: Categorizing Virulence Factors"
echo "========================================"

# Common P. aeruginosa virulence factor categories
cat > "${VF_DIR}/vf_categories.txt" << EOF
Pseudomonas aeruginosa Virulence Factor Categories
===================================================

Major Virulence Factor Categories:
-----------------------------------

1. Secretion Systems:
   - Type I Secretion System
   - Type II Secretion System (Xcp system)
   - Type III Secretion System (T3SS)
   - Type VI Secretion System (T6SS)

2. Toxins:
   - Exotoxin A (toxA)
   - Exoenzyme S (exoS)
   - Exoenzyme T (exoT)
   - Exoenzyme U (exoU)
   - Exoenzyme Y (exoY)

3. Adhesins:
   - Pili (pilA)
   - Flagella (fliC, fleQ)
   - Alginate biosynthesis

4. Iron Acquisition:
   - Pyoverdine
   - Pyochelin

5. Quorum Sensing:
   - Las system (lasI, lasR)
   - Rhl system (rhlI, rhlR)
   - PQS system

6. Biofilm Formation:
   - Pel operon
   - Psl operon

Samples Analysis:
-----------------
EOF

for SAMPLE_TSV in "${VFDB_DIR}"/*_vfdb.tsv; do
    SAMPLE=$(basename "$SAMPLE_TSV" | sed 's/_vfdb.tsv//')
    
    echo "" >> "${VF_DIR}/vf_categories.txt"
    echo "Sample: $SAMPLE" >> "${VF_DIR}/vf_categories.txt"
    
    if [[ -f "$SAMPLE_TSV" ]]; then
        # Extract and categorize virulence factors
        tail -n +2 "$SAMPLE_TSV" | cut -f5,6 | sort -u | sed 's/^/  /' >> "${VF_DIR}/vf_categories.txt"
    fi
done

echo ""
echo "Step 5.3: Pathogenicity Assessment"
echo "=================================="

# Create pathogenicity profile
cat > "${VF_DIR}/pathogenicity_profile.txt" << EOF
Pathogenicity Assessment Report
================================
Generated: $(date)

This report summarizes the pathogenic potential of analyzed isolates
based on detected virulence factors.

EOF

for CONTIG in "${CONTIGS[@]}"; do
    SAMPLE=$(basename "$CONTIG" | sed 's/_contigs.fasta//' | sed 's/.fasta//')
    
    VF_COUNT=$(tail -n +2 "${VFDB_DIR}/${SAMPLE}_vfdb.tsv" 2>/dev/null | wc -l || echo "0")
    
    # Assess pathogenicity level based on VF count
    if [[ $VF_COUNT -gt 20 ]]; then
        PATHOGENICITY="High"
    elif [[ $VF_COUNT -gt 10 ]]; then
        PATHOGENICITY="Moderate"
    elif [[ $VF_COUNT -gt 0 ]]; then
        PATHOGENICITY="Low"
    else
        PATHOGENICITY="Minimal"
    fi
    
    cat >> "${VF_DIR}/pathogenicity_profile.txt" << EOF

Sample: $SAMPLE
---------------
Virulence Factors Detected: $VF_COUNT
Pathogenic Potential: $PATHOGENICITY

Key Virulence Factors:
EOF
    
    # List top virulence factors
    if [[ -f "${VFDB_DIR}/${SAMPLE}_vfdb.tsv" ]]; then
        tail -n +2 "${VFDB_DIR}/${SAMPLE}_vfdb.tsv" | \
            awk -F'\t' '{print "  - " $6 " (" $10 "% coverage)"}' | \
            head -15 >> "${VF_DIR}/pathogenicity_profile.txt"
    fi
    
    echo "" >> "${VF_DIR}/pathogenicity_profile.txt"
done

echo ""
echo "Step 5.4: Generating comprehensive summary"
echo "========================================="

# Create comprehensive virulence summary
cat > "${VF_DIR}/virulence_summary.txt" << EOF
Comprehensive Virulence Factor Analysis
========================================
Generated: $(date)

Analysis Overview:
------------------
Total samples analyzed: ${#CONTIGS[@]}
Database: VFDB (Virulence Factor Database)
Tool: ABRicate v0.8.13
Identity threshold: 80%
Coverage threshold: 60%

Summary Matrix:
---------------
$(cat ${VFDB_DIR}/vfdb_summary.tsv)

Individual Sample Details:
--------------------------
EOF

for SAMPLE_TSV in "${VFDB_DIR}"/*_vfdb.tsv; do
    SAMPLE=$(basename "$SAMPLE_TSV" | sed 's/_vfdb.tsv//')
    VF_COUNT=$(tail -n +2 "$SAMPLE_TSV" | wc -l)
    
    cat >> "${VF_DIR}/virulence_summary.txt" << EOF

Sample: $SAMPLE
  Total VFs: $VF_COUNT
  Detailed report: ${SAMPLE}_vf_report.txt
EOF
done

echo ""
echo "Step 5 completed successfully!"
echo "Results:"
echo "  - VFDB results: ${VFDB_DIR}"
echo "  - VF categories: ${VF_DIR}/vf_categories.txt"
echo "  - Pathogenicity profile: ${VF_DIR}/pathogenicity_profile.txt"
echo "  - Summary: ${VF_DIR}/virulence_summary.txt"
