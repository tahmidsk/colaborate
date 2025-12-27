#!/bin/bash

################################################################################
# Pipeline Configuration File
# 
# Set environment variables and paths for the PA genomic analysis pipeline
################################################################################

# Pipeline version
export PIPELINE_VERSION="1.0.0"

# Tool versions (for reference and validation)
export FASTQC_VERSION="0.12.1"
export FASTP_VERSION="0.23.2"
export SPADES_VERSION="3.14.1"
export QUAST_VERSION="5.2.0"
export PROKKA_VERSION="1.13.4"
export KRAKEN_VERSION="1.1.1"
export SNIPPY_VERSION="4.3.6"
export ABRICATE_VERSION="0.8.13"
export ROARY_VERSION="3.13.0"
export PARSNP_VERSION="1.7.4"

# Database paths
# Modify these paths according to your system configuration

# Kraken database path (required for taxonomic classification)
export KRAKEN_DB="${KRAKEN_DB:-/path/to/kraken/database}"

# ABRicate databases (usually auto-installed with abricate)
export ABRICATE_DATADIR="${ABRICATE_DATADIR:-}"

# Analysis parameters
export DEFAULT_THREADS=8
export MIN_CONTIG_LENGTH=500
export MLST_SCHEME="paer"  # P. aeruginosa scheme

# Quality filtering thresholds
export MIN_READ_LENGTH=50
export MIN_QUALITY=20

# Assembly parameters
export SPADES_KMERS="21,33,55,77"
export SPADES_MODE="--careful"

# Gene prediction parameters
export PROKKA_KINGDOM="Bacteria"
export PROKKA_GENUS="Pseudomonas"
export PROKKA_SPECIES="aeruginosa"

# Comparative analysis parameters
export ROARY_IDENTITY=95
export ROARY_CORE_DEFINITION=99  # Genes in 99% of strains

# Resistance gene detection thresholds
export ARG_MIN_IDENTITY=90
export ARG_MIN_COVERAGE=60

# Virulence factor detection thresholds
export VF_MIN_IDENTITY=80
export VF_MIN_COVERAGE=60

# Output directories structure
export QC_DIRNAME="qc"
export ASSEMBLY_DIRNAME="assembly"
export ANNOTATION_DIRNAME="annotation"
export MLST_DIRNAME="mlst"
export SNP_DIRNAME="snp_analysis"
export ARG_DIRNAME="antibiotic_resistance"
export VF_DIRNAME="virulence_factors"
export COMPARATIVE_DIRNAME="comparative_genomics"

# Logging
export LOG_LEVEL="INFO"
export LOG_FILE="pipeline.log"

# Color codes for output
export COLOR_RED='\033[0;31m'
export COLOR_GREEN='\033[0;32m'
export COLOR_YELLOW='\033[1;33m'
export COLOR_BLUE='\033[0;34m'
export COLOR_NC='\033[0m'  # No Color

# Function definitions for common tasks
log_info() {
    echo -e "${COLOR_BLUE}[INFO]${COLOR_NC} $1"
}

log_success() {
    echo -e "${COLOR_GREEN}[SUCCESS]${COLOR_NC} $1"
}

log_warning() {
    echo -e "${COLOR_YELLOW}[WARNING]${COLOR_NC} $1"
}

log_error() {
    echo -e "${COLOR_RED}[ERROR]${COLOR_NC} $1"
}

# Check if required tools are installed
check_tool() {
    local tool=$1
    local version_flag=${2:-"--version"}
    
    if command -v "$tool" &> /dev/null; then
        log_success "$tool is installed"
        return 0
    else
        log_error "$tool is not installed"
        return 1
    fi
}

# Export functions
export -f log_info
export -f log_success
export -f log_warning
export -f log_error
export -f check_tool
