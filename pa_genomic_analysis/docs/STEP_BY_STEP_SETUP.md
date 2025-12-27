# Step-by-Step Installation and Setup Guide

## Direct Linux Commands for PA Genomic Analysis Pipeline Setup

This guide provides **sequential, copy-paste ready commands** for setting up the Pseudomonas aeruginosa genomic analysis pipeline. Run these commands in order in your Linux terminal.

---

## Prerequisites Check

```bash
# Check if you have sudo access (needed for some installations)
sudo -v
# Function: Validates that you have administrator privileges
```

---

## Part 1: System Dependencies Installation

### Step 1: Update System Packages

```bash
sudo apt update && sudo apt upgrade -y
# Function: Updates package lists and upgrades existing packages to latest versions
```

### Step 2: Install Basic Build Tools

```bash
sudo apt install -y build-essential git wget curl unzip python3 python3-pip default-jre cmake zlib1g-dev libbz2-dev liblzma-dev libncurses5-dev
# Function: Installs essential development tools, Java runtime, and compression libraries needed by bioinformatics tools
```

---

## Part 2: Conda/Mamba Installation

### Step 3: Download Mambaforge Installer

```bash
cd ~
wget https://github.com/conda-forge/miniforge/releases/latest/download/Mambaforge-Linux-x86_64.sh
# Function: Downloads the Mambaforge installer (faster alternative to Conda)
```

### Step 4: Install Mambaforge

```bash
bash Mambaforge-Linux-x86_64.sh -b -p $HOME/mambaforge
# Function: Installs Mambaforge in silent mode (-b) to ~/mambaforge directory
```

### Step 5: Initialize Conda

```bash
~/mambaforge/bin/conda init bash
# Function: Configures your bash shell to use conda commands
```

### Step 6: Reload Shell Configuration

```bash
source ~/.bashrc
# Function: Reloads bash configuration to activate conda
```

---

## Part 3: Create Analysis Environment

### Step 7: Create Conda Environment

```bash
conda create -n pa_analysis python=3.9 -y
# Function: Creates isolated environment named 'pa_analysis' with Python 3.9
```

### Step 8: Activate Environment

```bash
conda activate pa_analysis
# Function: Activates the pa_analysis environment (all subsequent installations go here)
```

### Step 9: Configure Conda Channels

```bash
conda config --add channels defaults
conda config --add channels bioconda
conda config --add channels conda-forge
conda config --set channel_priority strict
# Function: Adds bioconda and conda-forge channels for bioinformatics software, sets strict priority to avoid conflicts
```

---

## Part 4: Install Bioinformatics Tools

### Step 10: Install Core Analysis Tools

```bash
mamba install -y fastqc=0.12.1 fastp=0.23.2 spades=3.14.1 quast=5.2.0 prokka kraken mlst snippy abricate roary parsnp fasttree
# Function: Installs all required bioinformatics tools for the pipeline (mamba is faster than conda)
```

---

## Part 5: Database Setup

### Step 11: Create Database Directory

```bash
mkdir -p ~/pa_analysis_databases/kraken ~/pa_analysis_databases/references
# Function: Creates directory structure for storing databases
```

### Step 12: Download MiniKraken Database (Recommended for Testing)

```bash
cd ~/pa_analysis_databases/kraken
wget https://genome-idx.s3.amazonaws.com/kraken/minikraken2_v2_8GB_201904.tgz
# Function: Downloads pre-built MiniKraken2 database (~8 GB, for taxonomic classification)
```

### Step 13: Extract MiniKraken Database

```bash
tar -xzf minikraken2_v2_8GB_201904.tgz
# Function: Extracts the compressed Kraken database
```

### Step 14: Clean Up Archive

```bash
rm minikraken2_v2_8GB_201904.tgz
# Function: Removes the compressed file to save disk space
```

### Step 15: Set Kraken Environment Variable

```bash
echo 'export KRAKEN_DB="$HOME/pa_analysis_databases/kraken/minikraken2_v2_8GB_201904"' >> ~/.bashrc
# Function: Adds KRAKEN_DB path to bash configuration for permanent access
```

### Step 16: Load New Environment Variable

```bash
source ~/.bashrc
# Function: Reloads bash configuration to make KRAKEN_DB available immediately
```

### Step 17: Install ResFinder Database

```bash
abricate-get_db --db resfinder --force
# Function: Downloads ResFinder database for antibiotic resistance gene detection
```

### Step 18: Install CARD Database

```bash
abricate-get_db --db card --force
# Function: Downloads CARD (Comprehensive Antibiotic Resistance Database)
```

### Step 19: Install VFDB Database

```bash
abricate-get_db --db vfdb --force
# Function: Downloads Virulence Factor Database for pathogenicity analysis
```

### Step 20: Verify ABRicate Databases

```bash
abricate --list
# Function: Lists all installed ABRicate databases to confirm successful installation
```

### Step 21: Download PAO1 Reference Genome

```bash
cd ~/pa_analysis_databases/references
wget -O PAO1_reference.fna.gz "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/006/765/GCF_000006765.1_ASM676v1/GCF_000006765.1_ASM676v1_genomic.fna.gz"
# Function: Downloads P. aeruginosa PAO1 reference genome for SNP analysis
```

### Step 22: Extract PAO1 Reference

```bash
gunzip PAO1_reference.fna.gz
# Function: Decompresses the reference genome file
```

### Step 23: Rename Reference File

```bash
mv PAO1_reference.fna PAO1_reference.fasta
# Function: Renames to standard .fasta extension
```

---

## Part 6: Clone Pipeline Repository

### Step 24: Navigate to Working Directory

```bash
cd ~
# Function: Changes to home directory
```

### Step 25: Clone Repository

```bash
git clone https://github.com/tahmidsk/colaborate.git
# Function: Downloads the colaborate repository containing the PA analysis pipeline
```

### Step 26: Navigate to Pipeline Directory

```bash
cd colaborate/pa_genomic_analysis
# Function: Changes to the pipeline directory
```

### Step 27: Make Scripts Executable

```bash
chmod +x scripts/*.sh
# Function: Adds execute permissions to all shell scripts
```

---

## Part 7: Configure Pipeline

### Step 28: Edit Pipeline Configuration

```bash
nano config/pipeline_config.sh
# Function: Opens configuration file in text editor for customization
# Modify: Update KRAKEN_DB path and thread counts as needed
# Press Ctrl+X, then Y, then Enter to save and exit
```

**Manual edit needed:** Update this line in the file:
```bash
export KRAKEN_DB="$HOME/pa_analysis_databases/kraken/minikraken2_v2_8GB_201904"
```

---

## Part 8: Verification

### Step 29: Check Tool Versions

```bash
fastqc --version
# Function: Verifies FastQC installation (should show v0.12.1)
```

```bash
fastp --version
# Function: Verifies FastP installation (should show 0.23.2)
```

```bash
spades.py --version
# Function: Verifies SPAdes installation (should show 3.14.1)
```

```bash
quast.py --version
# Function: Verifies Quast installation (should show 5.2.0)
```

```bash
prokka --version
# Function: Verifies Prokka installation (should show 1.13+)
```

```bash
kraken --version
# Function: Verifies Kraken installation (should show 1.1.1)
```

```bash
mlst --version
# Function: Verifies MLST installation
```

```bash
snippy --version
# Function: Verifies Snippy installation (should show 4.3+)
```

```bash
abricate --version
# Function: Verifies ABRicate installation (should show 0.8+)
```

```bash
roary --version
# Function: Verifies Roary installation (should show 3.13+)
```

```bash
parsnp --version
# Function: Verifies Parsnp installation (should show 1.7+)
```

### Step 30: Run Dependency Checker

```bash
bash scripts/check_dependencies.sh
# Function: Comprehensive check of all tools and databases
```

---

## Part 9: Test with Example Data (Optional)

### Step 31: Create Test Directory

```bash
mkdir -p ~/pa_test_data/raw_reads
# Function: Creates directory for test data
```

### Step 32: Download Example Data (if available)

```bash
# Note: Replace with actual test data URLs
# This is a placeholder - you would download your actual FASTQ files here
# Example format:
# wget -O ~/pa_test_data/raw_reads/sample1_R1.fastq.gz "URL_TO_R1_FILE"
# wget -O ~/pa_test_data/raw_reads/sample1_R2.fastq.gz "URL_TO_R2_FILE"
# Function: Downloads example sequencing data for testing
```

### Step 33: Run Quality Control Step (Test)

```bash
bash scripts/pa_analysis_pipeline.sh -i ~/pa_test_data/raw_reads -o ~/pa_test_results -t 4 -s qc
# Function: Tests the pipeline with quality control and assembly step
# -i: input directory with FASTQ files
# -o: output directory for results
# -t: number of CPU threads (adjust based on your system)
# -s: step to run (qc = quality control and assembly)
```

---

## Part 10: Production Use

### Step 34: Prepare Your Data

```bash
# Create directory for your actual sequencing data
mkdir -p ~/my_pa_study/raw_reads
# Function: Creates directory for your project data
# Copy your FASTQ files to this directory
```

### Step 35: Run Complete Pipeline

```bash
bash scripts/pa_analysis_pipeline.sh -i ~/my_pa_study/raw_reads -o ~/my_pa_study/results -t 16 -s all
# Function: Runs the complete genomic analysis pipeline on your data
# -i: input directory with your FASTQ files
# -o: output directory (will be created)
# -t: number of threads (use 80% of available CPUs)
# -s all: runs all 6 analysis steps sequentially
```

---

## Summary of What Was Installed

After completing these steps, you will have:

✓ **System tools**: Build tools, git, wget, curl, Java  
✓ **Conda environment**: Isolated Python 3.9 environment named 'pa_analysis'  
✓ **Bioinformatics tools**: FastQC, FastP, SPAdes, Quast, Prokka, Kraken, MLST, Snippy, ABRicate, Roary, Parsnp  
✓ **Databases**:
  - Kraken MiniKraken2 (~8 GB) for taxonomic classification
  - ResFinder for antibiotic resistance genes
  - CARD for comprehensive resistance analysis
  - VFDB for virulence factors
  - MLST (auto-downloads P. aeruginosa scheme)
  - PAO1 reference genome for SNP analysis  
✓ **Pipeline**: Complete PA genomic analysis scripts and documentation

---

## Disk Space Used

- System tools: ~500 MB
- Conda + Tools: ~3 GB
- MiniKraken database: ~8 GB
- ABRicate databases: ~200 MB
- Reference genomes: ~10 MB
- **Total: ~12 GB**

---

## Next Steps

1. Review documentation: `cat README.md`
2. See workflow guide: `cat docs/WORKFLOW.md`
3. Organize your FASTQ files in the input directory
4. Run the pipeline on your data (Step 35)
5. Check results in the output directory

---

## Troubleshooting

**If conda command not found after Step 6:**
```bash
export PATH="$HOME/mambaforge/bin:$PATH"
source ~/.bashrc
# Function: Manually adds conda to PATH if initialization failed
```

**If mamba command not found:**
```bash
conda install mamba -y
# Function: Installs mamba in base environment if not available
```

**If out of disk space:**
```bash
df -h
# Function: Check disk space usage
# Consider using Kraken bacteria-only database (~30 GB) or standard (~180 GB) instead
```

**If tool installation fails:**
```bash
conda install -c bioconda TOOL_NAME
# Function: Install individual tool if batch installation fails
# Replace TOOL_NAME with specific tool (e.g., fastqc, spades, etc.)
```

---

## Alternative: Standard Kraken Database (More Comprehensive)

If you need the full Kraken database instead of MiniKraken, replace Steps 12-14 with:

```bash
cd ~/pa_analysis_databases/kraken
kraken-build --download-taxonomy --db standard_db
# Function: Downloads NCBI taxonomy (~4 GB)
```

```bash
kraken-build --download-library bacteria --db standard_db
# Function: Downloads bacterial genomes (~50 GB)
```

```bash
kraken-build --download-library archaea --db standard_db
# Function: Downloads archaeal genomes (~3 GB)
```

```bash
kraken-build --download-library viral --db standard_db
# Function: Downloads viral genomes (~2 GB)
```

```bash
kraken-build --build --db standard_db --threads 16
# Function: Builds Kraken database index (~180 GB total, takes 6-12 hours)
```

```bash
echo 'export KRAKEN_DB="$HOME/pa_analysis_databases/kraken/standard_db"' >> ~/.bashrc
source ~/.bashrc
# Function: Updates environment variable to point to standard database
```

---

## Time Estimates

- Steps 1-11: ~20 minutes
- Step 12-16 (MiniKraken): ~30 minutes
- Steps 17-23: ~10 minutes
- Steps 24-30: ~5 minutes
- **Total setup time: ~65 minutes** (with MiniKraken)

With Standard Kraken database: **6-12 hours total**

---

## Important Notes

1. **Always activate the conda environment** before running the pipeline:
   ```bash
   conda activate pa_analysis
   ```

2. **Required input format**: Paired-end FASTQ files named:
   - `*_R1*.fastq.gz` or `*_1.fastq.gz` (forward reads)
   - `*_R2*.fastq.gz` or `*_2.fastq.gz` (reverse reads)

3. **Memory requirements**: Minimum 32 GB RAM, recommended 64 GB

4. **Thread selection**: Use ~80% of available CPU cores for optimal performance

5. **MLST database**: Auto-downloads on first use, no manual setup needed

---

End of step-by-step installation guide.
