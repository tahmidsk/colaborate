#!/bin/bash

################################################################################
# Step 1: Quality Control and Genome Assembly
# 
# This script performs:
# - Quality screening with FastQC v0.12.1
# - Quality filtering and trimming with FastP v0.23.2
# - De novo assembly with SPAdes v3.14.1
# - Quality assessment with Quast v5.2.0
# - Genome annotation with Prokka v1.13.4
# - Taxonomic classification with Kraken v1.1.1
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
QC_DIR="${OUTPUT_DIR}/qc"
TRIMMED_DIR="${OUTPUT_DIR}/trimmed"
ASSEMBLY_DIR="${OUTPUT_DIR}/assembly"
ANNOTATION_DIR="${OUTPUT_DIR}/annotation"
TAXONOMY_DIR="${OUTPUT_DIR}/taxonomy"

mkdir -p "$QC_DIR"/{raw,trimmed}
mkdir -p "$TRIMMED_DIR"
mkdir -p "$ASSEMBLY_DIR"
mkdir -p "$ANNOTATION_DIR"
mkdir -p "$TAXONOMY_DIR"

echo "Step 1.1: Raw sequence quality screening with FastQC"
echo "=================================================="

# Find all FASTQ files in input directory
FASTQ_FILES=($(find "$INPUT_DIR" -name "*.fastq" -o -name "*.fq" -o -name "*.fastq.gz" -o -name "*.fq.gz"))

if [[ ${#FASTQ_FILES[@]} -eq 0 ]]; then
    echo "Error: No FASTQ files found in $INPUT_DIR"
    exit 1
fi

# Run FastQC on raw reads
echo "Running FastQC on ${#FASTQ_FILES[@]} files..."
fastqc -t "$THREADS" -o "${QC_DIR}/raw" "${FASTQ_FILES[@]}"

echo ""
echo "Step 1.2: Quality filtering and trimming with FastP"
echo "=================================================="

# Process paired-end reads with FastP
for R1 in $(find "$INPUT_DIR" -name "*_R1*.fastq*" -o -name "*_1.fastq*"); do
    # Determine R2 filename
    R2="${R1/_R1/_R2}"
    R2="${R2/_1./_2.}"
    
    if [[ ! -f "$R2" ]]; then
        echo "Warning: Could not find paired file for $R1, skipping..."
        continue
    fi
    
    # Get sample name
    SAMPLE=$(basename "$R1" | sed 's/_R1.*//' | sed 's/_1.*//')
    
    echo "Processing sample: $SAMPLE"
    
    # Run FastP with default parameters
    fastp \
        -i "$R1" \
        -I "$R2" \
        -o "${TRIMMED_DIR}/${SAMPLE}_R1_trimmed.fastq.gz" \
        -O "${TRIMMED_DIR}/${SAMPLE}_R2_trimmed.fastq.gz" \
        -h "${QC_DIR}/trimmed/${SAMPLE}_fastp.html" \
        -j "${QC_DIR}/trimmed/${SAMPLE}_fastp.json" \
        --thread "$THREADS"
done

echo ""
echo "Step 1.3: Quality control of trimmed sequences with FastQC"
echo "========================================================"

# Run FastQC on trimmed reads
TRIMMED_FILES=($(find "$TRIMMED_DIR" -name "*.fastq.gz"))
fastqc -t "$THREADS" -o "${QC_DIR}/trimmed" "${TRIMMED_FILES[@]}"

echo ""
echo "Step 1.4: De novo genome assembly with SPAdes"
echo "============================================="

# Assemble each sample with SPAdes
for R1 in $(find "$TRIMMED_DIR" -name "*_R1_trimmed.fastq.gz"); do
    R2="${R1/_R1_/_R2_}"
    SAMPLE=$(basename "$R1" | sed 's/_R1_trimmed.fastq.gz//')
    
    echo "Assembling sample: $SAMPLE"
    
    spades.py \
        -1 "$R1" \
        -2 "$R2" \
        -o "${ASSEMBLY_DIR}/${SAMPLE}" \
        --threads "$THREADS" \
        --careful \
        --cov-cutoff auto
    
    # Copy final assembly
    cp "${ASSEMBLY_DIR}/${SAMPLE}/contigs.fasta" \
       "${ASSEMBLY_DIR}/${SAMPLE}_contigs.fasta"
done

echo ""
echo "Step 1.5: Assembly quality assessment with Quast"
echo "==============================================="

# Collect all assembled contigs
CONTIGS=($(find "$ASSEMBLY_DIR" -name "*_contigs.fasta"))

# Run Quast
quast.py \
    "${CONTIGS[@]}" \
    -o "${ASSEMBLY_DIR}/quast_results" \
    --threads "$THREADS" \
    --min-contig 500

echo ""
echo "Step 1.6: Genome annotation with Prokka"
echo "======================================="

# Annotate each assembly
for CONTIG in "${CONTIGS[@]}"; do
    SAMPLE=$(basename "$CONTIG" | sed 's/_contigs.fasta//')
    
    echo "Annotating sample: $SAMPLE"
    
    prokka \
        --outdir "${ANNOTATION_DIR}/${SAMPLE}" \
        --prefix "$SAMPLE" \
        --kingdom Bacteria \
        --genus Pseudomonas \
        --species aeruginosa \
        --cpus "$THREADS" \
        --force \
        "$CONTIG"
done

echo ""
echo "Step 1.7: Taxonomic classification with Kraken"
echo "=============================================="

# Check if Kraken database is available
if [[ -z "${KRAKEN_DB:-}" ]]; then
    echo "Warning: KRAKEN_DB not set, skipping taxonomic classification"
else
    for R1 in $(find "$TRIMMED_DIR" -name "*_R1_trimmed.fastq.gz"); do
        R2="${R1/_R1_/_R2_}"
        SAMPLE=$(basename "$R1" | sed 's/_R1_trimmed.fastq.gz//')
        
        echo "Classifying sample: $SAMPLE"
        
        kraken \
            --db "$KRAKEN_DB" \
            --threads "$THREADS" \
            --paired \
            --fastq-input \
            --gzip-compressed \
            --output "${TAXONOMY_DIR}/${SAMPLE}_kraken.out" \
            --preload \
            "$R1" "$R2"
        
        # Generate report
        kraken-report \
            --db "$KRAKEN_DB" \
            "${TAXONOMY_DIR}/${SAMPLE}_kraken.out" \
            > "${TAXONOMY_DIR}/${SAMPLE}_kraken_report.txt"
    done
fi

echo ""
echo "Step 1 completed successfully!"
echo "Results:"
echo "  - Raw QC: ${QC_DIR}/raw"
echo "  - Trimmed QC: ${QC_DIR}/trimmed"
echo "  - Assemblies: ${ASSEMBLY_DIR}"
echo "  - Annotations: ${ANNOTATION_DIR}"
echo "  - Taxonomy: ${TAXONOMY_DIR}"
