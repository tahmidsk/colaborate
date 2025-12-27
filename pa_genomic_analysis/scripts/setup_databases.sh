#!/bin/bash

################################################################################
# Database Setup Script for PA Genomic Analysis Pipeline
# 
# This script downloads and sets up all required databases for the
# Pseudomonas aeruginosa genomic analysis pipeline
#
# Usage: bash setup_databases.sh
################################################################################

set -euo pipefail

echo "=========================================="
echo "PA Genomic Analysis Pipeline"
echo "Database Setup Script"
echo "=========================================="
echo ""

# Create database directory structure
BASE_DIR="${HOME}/pa_analysis_databases"
KRAKEN_DIR="${BASE_DIR}/kraken"
REFERENCE_DIR="${BASE_DIR}/references"

mkdir -p "$KRAKEN_DIR"
mkdir -p "$REFERENCE_DIR"

echo "Database directory: $BASE_DIR"
echo ""

# Function to print section headers
print_header() {
    echo ""
    echo "=========================================="
    echo "$1"
    echo "=========================================="
    echo ""
}

# ============================================================================
# 1. KRAKEN DATABASE (for taxonomic classification)
# ============================================================================

print_header "1. Setting up Kraken Database"

echo "Kraken database options:"
echo "  1) Standard database (~180 GB, most comprehensive)"
echo "  2) MiniKraken database (~8 GB, faster, recommended for testing)"
echo "  3) Bacteria-only database (~30 GB, good balance)"
echo ""
read -p "Choose option (1/2/3): " KRAKEN_CHOICE

case $KRAKEN_CHOICE in
    1)
        echo "Building Standard Kraken database (this will take several hours)..."
        cd "$KRAKEN_DIR"
        kraken-build --standard --db standard_db --threads 16
        KRAKEN_DB_PATH="${KRAKEN_DIR}/standard_db"
        ;;
    2)
        echo "Downloading MiniKraken2 database..."
        cd "$KRAKEN_DIR"
        wget https://genome-idx.s3.amazonaws.com/kraken/minikraken2_v2_8GB_201904.tgz
        tar -xzf minikraken2_v2_8GB_201904.tgz
        rm minikraken2_v2_8GB_201904.tgz
        KRAKEN_DB_PATH="${KRAKEN_DIR}/minikraken2_v2_8GB_201904"
        ;;
    3)
        echo "Building Bacteria-only Kraken database..."
        cd "$KRAKEN_DIR"
        mkdir -p bacteria_db
        cd bacteria_db
        kraken-build --download-taxonomy --db .
        kraken-build --download-library bacteria --db .
        kraken-build --build --db . --threads 16
        KRAKEN_DB_PATH="${KRAKEN_DIR}/bacteria_db"
        ;;
    *)
        echo "Invalid choice. Skipping Kraken database setup."
        KRAKEN_DB_PATH=""
        ;;
esac

if [ ! -z "$KRAKEN_DB_PATH" ]; then
    echo ""
    echo "Kraken database installed at: $KRAKEN_DB_PATH"
    echo "Setting KRAKEN_DB environment variable..."
    echo "export KRAKEN_DB=\"$KRAKEN_DB_PATH\"" >> ~/.bashrc
    export KRAKEN_DB="$KRAKEN_DB_PATH"
    echo "Done!"
fi

# ============================================================================
# 2. ABRICATE DATABASES (for resistance and virulence screening)
# ============================================================================

print_header "2. Setting up ABRicate Databases"

echo "Installing ABRicate databases..."
echo ""

# Check if abricate is installed
if ! command -v abricate &> /dev/null; then
    echo "Error: ABRicate not found. Please install it first."
    echo "Install with: conda install -c bioconda abricate"
    exit 1
fi

# Update ABRicate databases
echo "Downloading ResFinder database (antibiotic resistance)..."
abricate-get_db --db resfinder --force

echo "Downloading CARD database (comprehensive antibiotic resistance)..."
abricate-get_db --db card --force

echo "Downloading VFDB database (virulence factors)..."
abricate-get_db --db vfdb --force

echo "Downloading optional databases..."
abricate-get_db --db argannot --force
abricate-get_db --db ncbi --force
abricate-get_db --db plasmidfinder --force

echo ""
echo "Verifying ABRicate databases..."
abricate --list

echo ""
echo "ABRicate databases installed successfully!"

# ============================================================================
# 3. MLST DATABASE (auto-downloaded on first use)
# ============================================================================

print_header "3. MLST Database"

echo "MLST databases are automatically downloaded on first use."
echo "Verifying P. aeruginosa scheme availability..."

if command -v mlst &> /dev/null; then
    echo ""
    mlst --longlist | grep "paer" || echo "Note: Run 'mlst --longlist' to initialize database"
    echo ""
    echo "MLST is configured and will auto-download P. aeruginosa scheme on first use."
else
    echo "Warning: MLST not installed. Install with: conda install -c bioconda mlst"
fi

# ============================================================================
# 4. REFERENCE GENOMES (for SNP analysis)
# ============================================================================

print_header "4. Downloading Reference Genomes"

echo "Downloading P. aeruginosa reference genomes..."
cd "$REFERENCE_DIR"

# PAO1 reference genome
echo ""
echo "Downloading PAO1 reference genome..."
if [ ! -f "PAO1_reference.fasta" ]; then
    wget -O PAO1_reference.fna.gz \
        "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/006/765/GCF_000006765.1_ASM676v1/GCF_000006765.1_ASM676v1_genomic.fna.gz"
    gunzip PAO1_reference.fna.gz
    mv PAO1_reference.fna PAO1_reference.fasta
    echo "PAO1 reference downloaded: ${REFERENCE_DIR}/PAO1_reference.fasta"
else
    echo "PAO1 reference already exists."
fi

# PA14 reference genome
echo ""
echo "Downloading PA14 reference genome..."
if [ ! -f "PA14_reference.fasta" ]; then
    wget -O PA14_reference.fna.gz \
        "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/014/625/GCF_000014625.1_ASM1462v1/GCF_000014625.1_ASM1462v1_genomic.fna.gz"
    gunzip PA14_reference.fna.gz
    mv PA14_reference.fna PA14_reference.fasta
    echo "PA14 reference downloaded: ${REFERENCE_DIR}/PA14_reference.fasta"
else
    echo "PA14 reference already exists."
fi

echo ""
echo "Reference genomes installed successfully!"

# ============================================================================
# SUMMARY
# ============================================================================

print_header "Database Setup Complete!"

cat << EOF
Database Summary:
=================

1. Kraken Database (Taxonomic Classification):
   Location: ${KRAKEN_DB_PATH:-Not installed}
   Environment variable: KRAKEN_DB

2. ABRicate Databases (Resistance & Virulence):
   - ResFinder: Antibiotic resistance genes
   - CARD: Comprehensive antibiotic resistance
   - VFDB: Virulence factors
   - ARG-ANNOT: Additional resistance genes
   - NCBI: NCBI curated resistance genes
   - PlasmidFinder: Plasmid identification

3. MLST Database (Molecular Typing):
   Auto-downloads P. aeruginosa scheme on first use

4. Reference Genomes (SNP Analysis):
   - PAO1: ${REFERENCE_DIR}/PAO1_reference.fasta
   - PA14: ${REFERENCE_DIR}/PA14_reference.fasta

Configuration:
==============

Add this to your pipeline configuration or environment:

export KRAKEN_DB="${KRAKEN_DB_PATH:-/path/to/kraken/db}"
export REFERENCE_DIR="${REFERENCE_DIR}"

To make permanent, add to ~/.bashrc:
echo 'export KRAKEN_DB="${KRAKEN_DB_PATH:-/path/to/kraken/db}"' >> ~/.bashrc
echo 'export REFERENCE_DIR="${REFERENCE_DIR}"' >> ~/.bashrc
source ~/.bashrc

Disk Space Used:
================
$(du -sh "$BASE_DIR" 2>/dev/null || echo "Unable to calculate")

Next Steps:
===========
1. Update config/pipeline_config.sh with database paths
2. Run dependency checker: bash scripts/check_dependencies.sh
3. Test with sample data
4. Run full pipeline

For more information, see docs/INSTALLATION.md

EOF

echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
