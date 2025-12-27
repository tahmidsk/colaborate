#!/bin/bash

################################################################################
# Pseudomonas aeruginosa Genomic Analysis Pipeline
# 
# This script performs comprehensive genomic analysis of P. aeruginosa isolates
# following the workflow described in section 3.13.4
#
# Author: Generated for colaborate project
# Date: 2025-12-27
################################################################################

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Source configuration
CONFIG_FILE="${PROJECT_DIR}/config/pipeline_config.sh"
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
else
    echo "Error: Configuration file not found: $CONFIG_FILE"
    exit 1
fi

# Function to display usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Pseudomonas aeruginosa Genomic Analysis Pipeline

OPTIONS:
    -i, --input DIR         Input directory containing raw sequencing reads (FASTQ)
    -o, --output DIR        Output directory for results
    -r, --reference FILE    Reference genome for SNP analysis (optional)
    -t, --threads NUM       Number of threads to use (default: 8)
    -s, --step STEP         Run specific step only (qc, assembly, mlst, snp, args, vf, comparative)
    -h, --help              Display this help message

STEPS:
    qc          Quality control and genome assembly
    mlst        MLST and serotyping
    snp         SNP and indel detection
    args        Antibiotic resistance genes identification
    vf          Virulence factor identification
    comparative Comparative genomic analysis
    all         Run all steps (default)

EXAMPLE:
    $0 -i raw_reads/ -o results/ -t 16 -s all
    $0 -i raw_reads/ -o results/ -r reference.fasta -s snp

EOF
    exit 1
}

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${OUTPUT_DIR}/pipeline.log"
}

# Function to check required tools
check_dependencies() {
    log "Checking dependencies..."
    
    local tools=("fastqc" "fastp" "spades.py" "quast.py" "prokka" "mlst" "snippy" "abricate" "roary")
    local missing=()
    
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing+=("$tool")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log "ERROR: Missing required tools: ${missing[*]}"
        log "Please install missing tools before running the pipeline"
        return 1
    fi
    
    log "All dependencies found"
    return 0
}

# Parse command line arguments
INPUT_DIR=""
OUTPUT_DIR=""
REFERENCE=""
THREADS=8
STEP="all"

while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--input)
            INPUT_DIR="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -r|--reference)
            REFERENCE="$2"
            shift 2
            ;;
        -t|--threads)
            THREADS="$2"
            shift 2
            ;;
        -s|--step)
            STEP="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Validate arguments
if [[ -z "$INPUT_DIR" || -z "$OUTPUT_DIR" ]]; then
    echo "Error: Input and output directories are required"
    usage
fi

if [[ ! -d "$INPUT_DIR" ]]; then
    echo "Error: Input directory does not exist: $INPUT_DIR"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Initialize log file
log "===== Pseudomonas aeruginosa Genomic Analysis Pipeline ====="
log "Input directory: $INPUT_DIR"
log "Output directory: $OUTPUT_DIR"
log "Threads: $THREADS"
log "Step: $STEP"

# Check dependencies
if ! check_dependencies; then
    exit 1
fi

# Execute pipeline steps
case $STEP in
    qc|all)
        log "Starting Step 1: Quality Control and Genome Assembly"
        bash "${SCRIPT_DIR}/01_qc_assembly.sh" \
            -i "$INPUT_DIR" \
            -o "$OUTPUT_DIR" \
            -t "$THREADS"
        log "Step 1 completed"
        ;&
    mlst)
        if [[ "$STEP" == "mlst" ]]; then
            log "Starting Step 2: MLST and Serotyping"
            bash "${SCRIPT_DIR}/02_mlst_typing.sh" \
                -i "${OUTPUT_DIR}/assembly" \
                -o "$OUTPUT_DIR" \
                -t "$THREADS"
            log "Step 2 completed"
        fi
        if [[ "$STEP" == "all" ]]; then
            log "Starting Step 2: MLST and Serotyping"
            bash "${SCRIPT_DIR}/02_mlst_typing.sh" \
                -i "${OUTPUT_DIR}/assembly" \
                -o "$OUTPUT_DIR" \
                -t "$THREADS"
            log "Step 2 completed"
        fi
        ;&
    snp)
        if [[ "$STEP" == "snp" ]]; then
            log "Starting Step 3: SNP and Indel Detection"
            bash "${SCRIPT_DIR}/03_snp_detection.sh" \
                -i "$INPUT_DIR" \
                -o "$OUTPUT_DIR" \
                -r "$REFERENCE" \
                -t "$THREADS"
            log "Step 3 completed"
        fi
        if [[ "$STEP" == "all" && -n "$REFERENCE" ]]; then
            log "Starting Step 3: SNP and Indel Detection"
            bash "${SCRIPT_DIR}/03_snp_detection.sh" \
                -i "$INPUT_DIR" \
                -o "$OUTPUT_DIR" \
                -r "$REFERENCE" \
                -t "$THREADS"
            log "Step 3 completed"
        fi
        ;&
    args)
        if [[ "$STEP" == "args" ]]; then
            log "Starting Step 4: Antibiotic Resistance Genes Identification"
            bash "${SCRIPT_DIR}/04_args_identification.sh" \
                -i "${OUTPUT_DIR}/assembly" \
                -o "$OUTPUT_DIR" \
                -t "$THREADS"
            log "Step 4 completed"
        fi
        if [[ "$STEP" == "all" ]]; then
            log "Starting Step 4: Antibiotic Resistance Genes Identification"
            bash "${SCRIPT_DIR}/04_args_identification.sh" \
                -i "${OUTPUT_DIR}/assembly" \
                -o "$OUTPUT_DIR" \
                -t "$THREADS"
            log "Step 4 completed"
        fi
        ;&
    vf)
        if [[ "$STEP" == "vf" ]]; then
            log "Starting Step 5: Virulence Factor Identification"
            bash "${SCRIPT_DIR}/05_virulence_factors.sh" \
                -i "${OUTPUT_DIR}/assembly" \
                -o "$OUTPUT_DIR" \
                -t "$THREADS"
            log "Step 5 completed"
        fi
        if [[ "$STEP" == "all" ]]; then
            log "Starting Step 5: Virulence Factor Identification"
            bash "${SCRIPT_DIR}/05_virulence_factors.sh" \
                -i "${OUTPUT_DIR}/assembly" \
                -o "$OUTPUT_DIR" \
                -t "$THREADS"
            log "Step 5 completed"
        fi
        ;&
    comparative)
        if [[ "$STEP" == "comparative" ]]; then
            log "Starting Step 6: Comparative Genomic Analysis"
            bash "${SCRIPT_DIR}/06_comparative_genomics.sh" \
                -i "${OUTPUT_DIR}/annotation" \
                -o "$OUTPUT_DIR" \
                -t "$THREADS"
            log "Step 6 completed"
        fi
        if [[ "$STEP" == "all" ]]; then
            log "Starting Step 6: Comparative Genomic Analysis"
            bash "${SCRIPT_DIR}/06_comparative_genomics.sh" \
                -i "${OUTPUT_DIR}/annotation" \
                -o "$OUTPUT_DIR" \
                -t "$THREADS"
            log "Step 6 completed"
        fi
        ;;
    *)
        echo "Error: Invalid step: $STEP"
        usage
        ;;
esac

log "===== Pipeline completed successfully ====="
log "Results are available in: $OUTPUT_DIR"
