#!/bin/bash

################################################################################
# Step 3: SNP and Indel Detection
# 
# This script performs:
# - Single nucleotide polymorphism (SNP) detection using Snippy v4.3.6
# - Indel detection
# - Core SNP alignment generation
################################################################################

set -euo pipefail

# Parse arguments
INPUT_DIR=""
OUTPUT_DIR=""
REFERENCE=""
THREADS=8

while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--input) INPUT_DIR="$2"; shift 2 ;;
        -o|--output) OUTPUT_DIR="$2"; shift 2 ;;
        -r|--reference) REFERENCE="$2"; shift 2 ;;
        -t|--threads) THREADS="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# Validate reference genome
if [[ -z "$REFERENCE" ]]; then
    echo "Error: Reference genome is required for SNP detection"
    echo "Usage: $0 -i INPUT_DIR -o OUTPUT_DIR -r REFERENCE -t THREADS"
    exit 1
fi

if [[ ! -f "$REFERENCE" ]]; then
    echo "Error: Reference genome file not found: $REFERENCE"
    exit 1
fi

# Create output directory
SNP_DIR="${OUTPUT_DIR}/snp_analysis"
mkdir -p "$SNP_DIR"

echo "Step 3.1: SNP and Indel Detection with Snippy"
echo "============================================="
echo "Reference genome: $REFERENCE"

# Find all trimmed read pairs
R1_FILES=($(find "$INPUT_DIR" -name "*_R1*.fastq*" -o -name "*_1.fastq*"))

if [[ ${#R1_FILES[@]} -eq 0 ]]; then
    echo "Error: No FASTQ files found in $INPUT_DIR"
    exit 1
fi

echo "Found ${#R1_FILES[@]} samples to analyze"

# Array to store sample directories for core SNP analysis
SAMPLE_DIRS=()

# Run Snippy on each sample
for R1 in "${R1_FILES[@]}"; do
    # Determine R2 filename
    R2="${R1/_R1/_R2}"
    R2="${R2/_1./_2.}"
    
    if [[ ! -f "$R2" ]]; then
        echo "Warning: Could not find paired file for $R1, skipping..."
        continue
    fi
    
    # Get sample name
    SAMPLE=$(basename "$R1" | sed 's/_R1.*//' | sed 's/_1.*//')
    
    echo ""
    echo "Processing sample: $SAMPLE"
    echo "------------------------"
    
    SAMPLE_DIR="${SNP_DIR}/${SAMPLE}"
    SAMPLE_DIRS+=("$SAMPLE_DIR")
    
    # Run Snippy
    snippy \
        --outdir "$SAMPLE_DIR" \
        --ref "$REFERENCE" \
        --R1 "$R1" \
        --R2 "$R2" \
        --cpus "$THREADS" \
        --force
    
    # Display summary
    if [[ -f "${SAMPLE_DIR}/snps.txt" ]]; then
        echo "SNPs found: $(wc -l < ${SAMPLE_DIR}/snps.txt)"
    fi
    
    # Create summary report
    cat > "${SAMPLE_DIR}/summary.txt" << EOF
Sample: $SAMPLE
Reference: $(basename $REFERENCE)
Analysis Date: $(date)

Results:
--------
$(cat ${SAMPLE_DIR}/snps.txt 2>/dev/null | head -20)

For complete results, see:
  - VCF file: ${SAMPLE_DIR}/snps.vcf
  - GFF file: ${SAMPLE_DIR}/snps.gff
  - Tab file: ${SAMPLE_DIR}/snps.tab
  - Aligned fasta: ${SAMPLE_DIR}/snps.aligned.fa
EOF

done

echo ""
echo "Step 3.2: Core SNP Analysis with Snippy-core"
echo "==========================================="

if [[ ${#SAMPLE_DIRS[@]} -gt 1 ]]; then
    echo "Generating core SNP alignment from ${#SAMPLE_DIRS[@]} samples..."
    
    # Run snippy-core
    snippy-core \
        --ref "$REFERENCE" \
        --prefix core \
        "${SAMPLE_DIRS[@]}"
    
    # Move core files to SNP directory
    mv core.* "$SNP_DIR/"
    
    echo ""
    echo "Core SNP statistics:"
    if [[ -f "${SNP_DIR}/core.txt" ]]; then
        echo "  Total core SNPs: $(wc -l < ${SNP_DIR}/core.txt)"
    fi
    
    # Generate core SNP tree if possible
    if command -v FastTree &> /dev/null && [[ -f "${SNP_DIR}/core.aln" ]]; then
        echo ""
        echo "Building phylogenetic tree from core SNPs..."
        FastTree -nt -gtr "${SNP_DIR}/core.aln" > "${SNP_DIR}/core.tree"
        echo "Tree saved to: ${SNP_DIR}/core.tree"
    fi
else
    echo "Note: Need at least 2 samples for core SNP analysis"
fi

echo ""
echo "Step 3.3: Generating SNP summary report"
echo "======================================="

# Create comprehensive summary
cat > "${SNP_DIR}/snp_summary.txt" << EOF
SNP and Indel Detection Summary
================================
Generated: $(date)
Reference Genome: $(basename $REFERENCE)

Sample Statistics:
------------------
EOF

for SAMPLE_DIR in "${SAMPLE_DIRS[@]}"; do
    SAMPLE=$(basename "$SAMPLE_DIR")
    
    if [[ -f "${SAMPLE_DIR}/snps.txt" ]]; then
        SNP_COUNT=$(grep -c "snp" "${SAMPLE_DIR}/snps.txt" 2>/dev/null || echo "0")
        INDEL_COUNT=$(grep -c "del\|ins" "${SAMPLE_DIR}/snps.txt" 2>/dev/null || echo "0")
        
        cat >> "${SNP_DIR}/snp_summary.txt" << EOF

Sample: $SAMPLE
  SNPs: $SNP_COUNT
  Indels: $INDEL_COUNT
  Total variants: $(wc -l < ${SAMPLE_DIR}/snps.txt)
EOF
    fi
done

if [[ -f "${SNP_DIR}/core.txt" ]]; then
    cat >> "${SNP_DIR}/snp_summary.txt" << EOF

Core SNP Analysis:
------------------
  Total core SNPs: $(wc -l < ${SNP_DIR}/core.txt)
  Alignment file: core.aln
  Tree file: core.tree (if generated)
EOF
fi

echo ""
echo "Step 3 completed successfully!"
echo "Results:"
echo "  - Individual SNP results: ${SNP_DIR}/<sample>/"
echo "  - Core SNP analysis: ${SNP_DIR}/core.*"
echo "  - Summary: ${SNP_DIR}/snp_summary.txt"
