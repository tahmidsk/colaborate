#!/bin/bash

################################################################################
# Quick Command List - PA Genomic Analysis Pipeline Setup
# 
# Copy and paste these commands sequentially into your Linux terminal
# Each command has a comment explaining its function
################################################################################

# ============================================================================
# PART 1: SYSTEM DEPENDENCIES
# ============================================================================

# Update system packages
sudo apt update && sudo apt upgrade -y

# Install basic dependencies
sudo apt install -y build-essential git wget curl unzip python3 python3-pip default-jre cmake zlib1g-dev libbz2-dev liblzma-dev libncurses5-dev

# ============================================================================
# PART 2: INSTALL CONDA/MAMBA
# ============================================================================

# Download Mambaforge
cd ~
wget https://github.com/conda-forge/miniforge/releases/latest/download/Mambaforge-Linux-x86_64.sh

# Install Mambaforge
bash Mambaforge-Linux-x86_64.sh -b -p $HOME/mambaforge

# Initialize conda
~/mambaforge/bin/conda init bash

# Reload shell
source ~/.bashrc

# ============================================================================
# PART 3: CREATE ANALYSIS ENVIRONMENT
# ============================================================================

# Create conda environment
conda create -n pa_analysis python=3.9 -y

# Activate environment
conda activate pa_analysis

# Configure conda channels
conda config --add channels defaults
conda config --add channels bioconda
conda config --add channels conda-forge
conda config --set channel_priority strict

# ============================================================================
# PART 4: INSTALL BIOINFORMATICS TOOLS
# ============================================================================

# Install all tools (FastQC, FastP, SPAdes, Quast, Prokka, Kraken, MLST, Snippy, ABRicate, Roary, Parsnp)
mamba install -y fastqc=0.12.1 fastp=0.23.2 spades=3.14.1 quast=5.2.0 prokka kraken mlst snippy abricate roary parsnp fasttree

# ============================================================================
# PART 5: DATABASE SETUP
# ============================================================================

# Create database directories
mkdir -p ~/pa_analysis_databases/kraken ~/pa_analysis_databases/references

# Download MiniKraken2 database (~8 GB)
cd ~/pa_analysis_databases/kraken
wget https://genome-idx.s3.amazonaws.com/kraken/minikraken2_v2_8GB_201904.tgz

# Extract database
tar -xzf minikraken2_v2_8GB_201904.tgz

# Remove archive
rm minikraken2_v2_8GB_201904.tgz

# Set environment variable
echo 'export KRAKEN_DB="$HOME/pa_analysis_databases/kraken/minikraken2_v2_8GB_201904"' >> ~/.bashrc
source ~/.bashrc

# Install ABRicate databases (ResFinder, CARD, VFDB)
abricate-get_db --db resfinder --force
abricate-get_db --db card --force
abricate-get_db --db vfdb --force

# Verify ABRicate databases
abricate --list

# Download PAO1 reference genome
cd ~/pa_analysis_databases/references
wget -O PAO1_reference.fna.gz "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/006/765/GCF_000006765.1_ASM676v1/GCF_000006765.1_ASM676v1_genomic.fna.gz"
gunzip PAO1_reference.fna.gz
mv PAO1_reference.fna PAO1_reference.fasta

# ============================================================================
# PART 6: CLONE PIPELINE
# ============================================================================

# Navigate to home directory
cd ~

# Clone repository
git clone https://github.com/tahmidsk/colaborate.git

# Navigate to pipeline directory
cd colaborate/pa_genomic_analysis

# Make scripts executable
chmod +x scripts/*.sh

# ============================================================================
# PART 7: VERIFICATION
# ============================================================================

# Check tool versions
fastqc --version          # Should show v0.12.1
fastp --version           # Should show 0.23.2
spades.py --version       # Should show 3.14.1
quast.py --version        # Should show 5.2.0
prokka --version          # Should show 1.13+
kraken --version          # Should show 1.1.1
mlst --version            # Should show 2.23+
snippy --version          # Should show 4.3+
abricate --version        # Should show 0.8+
roary --version           # Should show 3.13+
parsnp --version          # Should show 1.7+

# Run comprehensive dependency checker
bash scripts/check_dependencies.sh

# ============================================================================
# PART 8: CONFIGURE (MANUAL EDIT NEEDED)
# ============================================================================

# Edit configuration file
nano config/pipeline_config.sh
# Update KRAKEN_DB path if different from default
# Press Ctrl+X, then Y, then Enter to save

# ============================================================================
# PART 9: RUN PIPELINE
# ============================================================================

# Prepare your data directory (replace with your actual data location)
mkdir -p ~/my_pa_study/raw_reads
# Copy your FASTQ files here

# Run complete pipeline on your data
# Adjust paths and thread count (-t) as needed
bash scripts/pa_analysis_pipeline.sh \
    -i ~/my_pa_study/raw_reads \
    -o ~/my_pa_study/results \
    -t 16 \
    -s all

# ============================================================================
# ALTERNATIVE: RUN INDIVIDUAL STEPS
# ============================================================================

# Quality control only
bash scripts/pa_analysis_pipeline.sh -i ~/my_pa_study/raw_reads -o ~/my_pa_study/results -t 16 -s qc

# MLST typing only
bash scripts/pa_analysis_pipeline.sh -i ~/my_pa_study/results/assembly -o ~/my_pa_study/results -t 16 -s mlst

# SNP detection (requires reference genome)
bash scripts/pa_analysis_pipeline.sh -i ~/my_pa_study/raw_reads -o ~/my_pa_study/results -r ~/pa_analysis_databases/references/PAO1_reference.fasta -t 16 -s snp

# Resistance genes only
bash scripts/pa_analysis_pipeline.sh -i ~/my_pa_study/results/assembly -o ~/my_pa_study/results -t 16 -s args

# Virulence factors only
bash scripts/pa_analysis_pipeline.sh -i ~/my_pa_study/results/assembly -o ~/my_pa_study/results -t 16 -s vf

# Comparative genomics only
bash scripts/pa_analysis_pipeline.sh -i ~/my_pa_study/results/annotation -o ~/my_pa_study/results -t 16 -s comparative

# ============================================================================
# END OF SETUP
# ============================================================================

echo "Setup complete! Pipeline is ready to use."
echo "Activate environment with: conda activate pa_analysis"
echo "See documentation: cat README.md"
