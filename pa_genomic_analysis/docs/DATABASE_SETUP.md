# Database Setup Guide

## Required Databases for PA Genomic Analysis Pipeline

This guide provides detailed instructions and code for downloading all databases needed for the Pseudomonas aeruginosa genomic analysis pipeline.

---

## Quick Setup (Automated)

Use the automated setup script:

```bash
cd pa_genomic_analysis
bash scripts/setup_databases.sh
```

The script will guide you through downloading all required databases.

---

## Manual Setup (Step-by-Step)

### 1. Kraken Database (Taxonomic Classification)

**Purpose:** Confirms species identity and detects contamination

**Required for:** Step 1 (Quality Control) - taxonomic classification

#### Option A: MiniKraken2 (~8 GB) - **RECOMMENDED FOR TESTING**

```bash
# Create directory
mkdir -p ~/pa_analysis_databases/kraken
cd ~/pa_analysis_databases/kraken

# Download pre-built database
wget https://genome-idx.s3.amazonaws.com/kraken/minikraken2_v2_8GB_201904.tgz

# Extract
tar -xzf minikraken2_v2_8GB_201904.tgz

# Set environment variable
export KRAKEN_DB="$HOME/pa_analysis_databases/kraken/minikraken2_v2_8GB_201904"
echo 'export KRAKEN_DB="$HOME/pa_analysis_databases/kraken/minikraken2_v2_8GB_201904"' >> ~/.bashrc
```

**Download time:** 15-30 minutes  
**Disk space:** 8 GB

#### Option B: Standard Database (~180 GB) - **MOST COMPREHENSIVE**

```bash
# Create directory
mkdir -p ~/pa_analysis_databases/kraken
cd ~/pa_analysis_databases/kraken

# Build standard database (includes bacteria, archaea, viruses, human)
kraken-build --standard --db standard_db --threads 16

# Set environment variable
export KRAKEN_DB="$HOME/pa_analysis_databases/kraken/standard_db"
echo 'export KRAKEN_DB="$HOME/pa_analysis_databases/kraken/standard_db"' >> ~/.bashrc
```

**Build time:** 6-12 hours  
**Disk space:** 180 GB

#### Option C: Bacteria-Only Database (~30 GB) - **GOOD BALANCE**

```bash
# Create directory
mkdir -p ~/pa_analysis_databases/kraken/bacteria_db
cd ~/pa_analysis_databases/kraken/bacteria_db

# Download taxonomy
kraken-build --download-taxonomy --db .

# Download bacteria library
kraken-build --download-library bacteria --db .

# Build database
kraken-build --build --db . --threads 16

# Set environment variable
export KRAKEN_DB="$HOME/pa_analysis_databases/kraken/bacteria_db"
echo 'export KRAKEN_DB="$HOME/pa_analysis_databases/kraken/bacteria_db"' >> ~/.bashrc
```

**Build time:** 2-4 hours  
**Disk space:** 30 GB

---

### 2. ABRicate Databases (Resistance & Virulence)

**Purpose:** Identifies antibiotic resistance genes and virulence factors

**Required for:** 
- Step 4 (ARGs Identification)
- Step 5 (Virulence Factors)

#### Install All Required Databases

```bash
# Activate conda environment (if using conda)
conda activate pa_analysis

# Download ResFinder database (antibiotic resistance genes)
abricate-get_db --db resfinder --force

# Download CARD database (comprehensive antibiotic resistance)
abricate-get_db --db card --force

# Download VFDB database (virulence factors)
abricate-get_db --db vfdb --force
```

**Download time:** 5-10 minutes  
**Disk space:** ~200 MB total

#### Optional Additional Databases

```bash
# ARG-ANNOT (additional resistance genes)
abricate-get_db --db argannot --force

# NCBI AMRFinder (NCBI curated resistance genes)
abricate-get_db --db ncbi --force

# PlasmidFinder (plasmid identification)
abricate-get_db --db plasmidfinder --force

# EcOH (E. coli serotyping - useful for comparison)
abricate-get_db --db ecoh --force
```

**Download time:** 5 minutes  
**Disk space:** ~150 MB

#### Verify Installation

```bash
# List all installed databases
abricate --list

# Should show:
# DATABASE       SEQUENCES  DBTYPE  DATE
# card           ...        nucl    ...
# resfinder      ...        nucl    ...
# vfdb           ...        nucl    ...
```

---

### 3. MLST Database (Molecular Typing)

**Purpose:** Multi-locus sequence typing for epidemiological tracking

**Required for:** Step 2 (MLST and Serotyping)

#### Setup

```bash
# MLST databases are automatically downloaded on first use
# No manual download needed!

# Verify P. aeruginosa scheme is available
mlst --longlist | grep "paer"

# Expected output:
# paer    Pseudomonas aeruginosa
```

**Download time:** Automatic on first use  
**Disk space:** ~50 MB (auto-downloaded)

---

### 4. Reference Genomes (SNP Analysis)

**Purpose:** Reference for variant calling and SNP detection

**Required for:** Step 3 (SNP and Indel Detection)

#### Download PAO1 Reference Genome

```bash
# Create directory
mkdir -p ~/pa_analysis_databases/references
cd ~/pa_analysis_databases/references

# Download PAO1 reference (most commonly used)
wget -O PAO1_reference.fna.gz \
    "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/006/765/GCF_000006765.1_ASM676v1/GCF_000006765.1_ASM676v1_genomic.fna.gz"

# Extract
gunzip PAO1_reference.fna.gz

# Rename
mv PAO1_reference.fna PAO1_reference.fasta

echo "PAO1 reference: $HOME/pa_analysis_databases/references/PAO1_reference.fasta"
```

**Download time:** 2-5 minutes  
**Disk space:** 6.3 MB

#### Download PA14 Reference Genome (Alternative)

```bash
cd ~/pa_analysis_databases/references

# Download PA14 reference
wget -O PA14_reference.fna.gz \
    "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/014/625/GCF_000014625.1_ASM1462v1/GCF_000014625.1_ASM1462v1_genomic.fna.gz"

# Extract
gunzip PA14_reference.fna.gz

# Rename
mv PA14_reference.fna PA14_reference.fasta

echo "PA14 reference: $HOME/pa_analysis_databases/references/PA14_reference.fasta"
```

**Download time:** 2-5 minutes  
**Disk space:** 6.5 MB

---

## Database Summary Table

| Database | Size | Download Time | Required For | Auto-download |
|----------|------|---------------|--------------|---------------|
| **Kraken Standard** | 180 GB | 6-12 hours | Taxonomy | No |
| **Kraken Mini** | 8 GB | 15-30 min | Taxonomy | No |
| **Kraken Bacteria** | 30 GB | 2-4 hours | Taxonomy | No |
| **ResFinder** | 50 MB | 2 min | Resistance | Via ABRicate |
| **CARD** | 100 MB | 3 min | Resistance | Via ABRicate |
| **VFDB** | 50 MB | 2 min | Virulence | Via ABRicate |
| **MLST** | 50 MB | 1 min | Typing | Yes (first use) |
| **PAO1 Reference** | 6.3 MB | 2 min | SNP calling | No |
| **PA14 Reference** | 6.5 MB | 2 min | SNP calling | No |

---

## Configuration

### Update Pipeline Configuration

Edit `config/pipeline_config.sh`:

```bash
# Edit configuration file
nano config/pipeline_config.sh

# Update these lines:
export KRAKEN_DB="$HOME/pa_analysis_databases/kraken/minikraken2_v2_8GB_201904"
```

### Set Environment Variables

Add to your `~/.bashrc` or `~/.bash_profile`:

```bash
# PA Analysis Databases
export KRAKEN_DB="$HOME/pa_analysis_databases/kraken/minikraken2_v2_8GB_201904"
export REFERENCE_DIR="$HOME/pa_analysis_databases/references"

# Reload
source ~/.bashrc
```

---

## Verification

### Check All Databases

```bash
# 1. Verify Kraken database
ls -lh $KRAKEN_DB

# 2. Verify ABRicate databases
abricate --list

# 3. Verify MLST
mlst --longlist | grep paer

# 4. Verify reference genomes
ls -lh ~/pa_analysis_databases/references/*.fasta
```

### Test with Sample Data

```bash
# Test Kraken
kraken --db $KRAKEN_DB --threads 4 --check

# Test ABRicate
abricate --db resfinder --help

# Test MLST
mlst --help
```

---

## Updating Databases

### Update ABRicate Databases

```bash
# Update all ABRicate databases (recommended monthly)
abricate-get_db --db resfinder --force
abricate-get_db --db card --force
abricate-get_db --db vfdb --force
```

### Update MLST Database

```bash
# MLST auto-updates when you run:
mlst --longlist
```

### Update Kraken Database

Kraken databases should be rebuilt periodically (every 6-12 months):

```bash
# For standard database
cd ~/pa_analysis_databases/kraken
kraken-build --clean --db standard_db
kraken-build --standard --db standard_db --threads 16
```

---

## Troubleshooting

### Kraken Database Issues

**Problem:** "Database not found"
```bash
# Solution: Check KRAKEN_DB variable
echo $KRAKEN_DB

# Verify database files exist
ls $KRAKEN_DB/database.*
```

**Problem:** "Out of memory during build"
```bash
# Solution: Use MiniKraken or add swap space
sudo fallocate -l 32G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

### ABRicate Database Issues

**Problem:** "Database not found"
```bash
# Solution: Reinstall database
abricate --setupdb
abricate-get_db --db resfinder --force
```

**Problem:** "Connection timeout"
```bash
# Solution: Try again or download manually from GitHub
git clone https://github.com/ncbi/AMRFinderPlus.git
```

### MLST Issues

**Problem:** "Scheme paer not found"
```bash
# Solution: Force update
mlst --longlist > /dev/null
```

### Reference Genome Issues

**Problem:** "FTP connection failed"
```bash
# Solution: Use HTTPS instead
wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/006/765/GCF_000006765.1_ASM676v1/GCF_000006765.1_ASM676v1_genomic.fna.gz
```

---

## Disk Space Requirements

### Minimum Configuration (for testing)

- Kraken MiniKraken: 8 GB
- ABRicate databases: 0.2 GB
- MLST database: 0.05 GB
- Reference genomes: 0.02 GB
- **Total: ~8.3 GB**

### Recommended Configuration (for production)

- Kraken Bacteria-only: 30 GB
- ABRicate databases: 0.5 GB
- MLST database: 0.05 GB
- Reference genomes: 0.02 GB
- **Total: ~30.6 GB**

### Full Configuration (most comprehensive)

- Kraken Standard: 180 GB
- ABRicate databases: 0.5 GB
- MLST database: 0.05 GB
- Reference genomes: 0.02 GB
- **Total: ~180.6 GB**

---

## Alternative Sources

### If NCBI FTP is slow

Use Ensembl Bacteria:
```bash
# PAO1 from Ensembl
wget http://ftp.ensemblgenomes.org/pub/bacteria/release-51/fasta/bacteria_0_collection/pseudomonas_aeruginosa_pao1/dna/Pseudomonas_aeruginosa_pao1.ASM676v1.dna.toplevel.fa.gz
```

### If ABRicate download fails

Clone directly from GitHub:
```bash
cd ~/.abricate
git clone https://github.com/tseemann/abricate-db-resfinder.git resfinder
git clone https://github.com/tseemann/abricate-db-card.git card
git clone https://github.com/tseemann/abricate-db-vfdb.git vfdb
```

---

## Complete Setup Commands

### Quick Start (Minimal)

```bash
# 1. Download MiniKraken
mkdir -p ~/pa_analysis_databases/kraken && cd ~/pa_analysis_databases/kraken
wget https://genome-idx.s3.amazonaws.com/kraken/minikraken2_v2_8GB_201904.tgz
tar -xzf minikraken2_v2_8GB_201904.tgz
export KRAKEN_DB="$HOME/pa_analysis_databases/kraken/minikraken2_v2_8GB_201904"

# 2. Setup ABRicate
abricate-get_db --db resfinder --force
abricate-get_db --db card --force
abricate-get_db --db vfdb --force

# 3. Download reference
mkdir -p ~/pa_analysis_databases/references && cd ~/pa_analysis_databases/references
wget -O PAO1.fna.gz "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/006/765/GCF_000006765.1_ASM676v1/GCF_000006765.1_ASM676v1_genomic.fna.gz"
gunzip PAO1.fna.gz && mv PAO1.fna PAO1_reference.fasta

# 4. Set environment
echo 'export KRAKEN_DB="$HOME/pa_analysis_databases/kraken/minikraken2_v2_8GB_201904"' >> ~/.bashrc
source ~/.bashrc

echo "Database setup complete!"
```

**Total time:** ~30 minutes  
**Total space:** ~8.5 GB

---

## Summary

All databases are now documented with:
✓ Download commands
✓ Size and time estimates
✓ Purpose and usage
✓ Configuration instructions
✓ Troubleshooting tips

For automated setup, use: `bash scripts/setup_databases.sh`

For manual setup, follow the commands in each section above.
