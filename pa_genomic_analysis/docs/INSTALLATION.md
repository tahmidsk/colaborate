# Installation Guide

Complete installation instructions for the Pseudomonas aeruginosa Genomic Analysis Pipeline.

## Table of Contents

1. [System Requirements](#system-requirements)
2. [Installation Methods](#installation-methods)
3. [Database Setup](#database-setup)
4. [Verification](#verification)
5. [Troubleshooting](#troubleshooting)

---

## System Requirements

### Hardware

**Minimum:**
- CPU: 8 cores
- RAM: 32 GB
- Storage: 500 GB

**Recommended:**
- CPU: 16+ cores
- RAM: 64+ GB
- Storage: 1+ TB (especially for Kraken database)

### Operating System

- Linux (Ubuntu 20.04+, CentOS 7+, or similar)
- macOS 10.14+ (with some limitations)
- Windows WSL2 (Ubuntu)

### Prerequisites

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install basic dependencies
sudo apt install -y \
    build-essential \
    git \
    wget \
    curl \
    unzip \
    python3 \
    python3-pip \
    default-jre \
    cmake \
    zlib1g-dev \
    libbz2-dev \
    liblzma-dev \
    libncurses5-dev
```

---

## Installation Methods

### Method 1: Conda/Mamba (Recommended)

**Step 1: Install Conda/Mamba**

```bash
# Install Mambaforge (faster than Conda)
wget https://github.com/conda-forge/miniforge/releases/latest/download/Mambaforge-Linux-x86_64.sh
bash Mambaforge-Linux-x86_64.sh
# Follow prompts, restart terminal
```

**Step 2: Create Environment**

```bash
# Create environment
mamba create -n pa_analysis python=3.9 -y

# Activate environment
conda activate pa_analysis
```

**Step 3: Install Core Tools**

```bash
# Add bioconda channel
conda config --add channels defaults
conda config --add channels bioconda
conda config --add channels conda-forge
conda config --set channel_priority strict

# Install all tools
mamba install -y \
    fastqc=0.12.1 \
    fastp=0.23.2 \
    spades=3.14.1 \
    quast=5.2.0 \
    prokka=1.14.6 \
    kraken=1.1.1 \
    mlst=2.23.0 \
    snippy=4.6.0 \
    abricate=1.0.1 \
    roary=3.13.0 \
    parsnp=1.7.4 \
    fasttree=2.1.11
```

**Step 4: Install PAst (P. aeruginosa serotyper)**

```bash
# Clone PAst repository
cd ~/tools
git clone https://github.com/zhaoqianyue/PAst.git
cd PAst

# Install dependencies
pip install biopython

# Add to PATH
echo 'export PATH="$HOME/tools/PAst:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Test
./past -h
```

**Step 5: Update ABRicate Databases**

```bash
# Setup ABRicate databases
abricate-get_db --db resfinder --force
abricate-get_db --db card --force
abricate-get_db --db vfdb --force
abricate-get_db --db ecoh --force

# List installed databases
abricate --list
```

---

### Method 2: Manual Installation

**Step 1: Install Each Tool**

**FastQC:**
```bash
cd ~/tools
wget https://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v0.12.1.zip
unzip fastqc_v0.12.1.zip
chmod +x FastQC/fastqc
sudo ln -s $PWD/FastQC/fastqc /usr/local/bin/fastqc
```

**FastP:**
```bash
cd ~/tools
wget http://opengene.org/fastp/fastp
chmod +x fastp
sudo mv fastp /usr/local/bin/
```

**SPAdes:**
```bash
cd ~/tools
wget http://cab.spbu.ru/files/release3.14.1/SPAdes-3.14.1-Linux.tar.gz
tar -xzf SPAdes-3.14.1-Linux.tar.gz
sudo ln -s $PWD/SPAdes-3.14.1-Linux/bin/* /usr/local/bin/
```

**QUAST:**
```bash
cd ~/tools
wget https://github.com/ablab/quast/releases/download/quast_5.2.0/quast-5.2.0.tar.gz
tar -xzf quast-5.2.0.tar.gz
cd quast-5.2.0
sudo ./setup.py install
```

**Prokka:**
```bash
sudo apt install -y prokka
# Or install from source
cd ~/tools
git clone https://github.com/tseemann/prokka.git
sudo ln -s $PWD/prokka/bin/prokka /usr/local/bin/
prokka --setupdb
```

**Kraken:**
```bash
cd ~/tools
wget https://github.com/DerrickWood/kraken/archive/v1.1.1.tar.gz
tar -xzf v1.1.1.tar.gz
cd kraken-1.1.1
./install_kraken.sh /usr/local/bin
```

**MLST:**
```bash
cd ~/tools
git clone https://github.com/tseemann/mlst.git
sudo ln -s $PWD/mlst/bin/mlst /usr/local/bin/
# Install dependencies
cpan -i Bio::Perl
```

**Snippy:**
```bash
cd ~/tools
git clone https://github.com/tseemann/snippy.git
sudo ln -s $PWD/snippy/bin/* /usr/local/bin/
```

**ABRicate:**
```bash
cd ~/tools
git clone https://github.com/tseemann/abricate.git
sudo ln -s $PWD/abricate/bin/abricate /usr/local/bin/
abricate --setupdb
```

**Roary:**
```bash
sudo apt install -y roary
# Or via cpan
sudo cpan Bio::Roary
```

**Parsnp:**
```bash
cd ~/tools
wget https://github.com/marbl/parsnp/releases/download/v1.7.4/parsnp-Linux64-v1.7.4.tar.gz
tar -xzf parsnp-Linux64-v1.7.4.tar.gz
sudo ln -s $PWD/Parsnp-Linux64-v1.7.4/parsnp /usr/local/bin/
```

---

### Method 3: Docker

**Step 1: Install Docker**

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
# Logout and login
```

**Step 2: Create Dockerfile**

```bash
cat > Dockerfile << 'EOF'
FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    wget curl git python3 python3-pip \
    build-essential cmake zlib1g-dev \
    default-jre perl

# Install Conda
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    bash Miniconda3-latest-Linux-x86_64.sh -b -p /opt/conda && \
    rm Miniconda3-latest-Linux-x86_64.sh

ENV PATH="/opt/conda/bin:$PATH"

# Install tools
RUN conda install -c bioconda -c conda-forge \
    fastqc fastp spades quast prokka kraken \
    mlst snippy abricate roary parsnp

# Setup ABRicate databases
RUN abricate-get_db --db resfinder --force && \
    abricate-get_db --db card --force && \
    abricate-get_db --db vfdb --force

WORKDIR /analysis

CMD ["/bin/bash"]
EOF

# Build Docker image
docker build -t pa_analysis:latest .
```

**Step 3: Run Container**

```bash
# Run analysis in Docker
docker run -it \
    -v /path/to/data:/data \
    -v /path/to/results:/results \
    pa_analysis:latest \
    bash
```

---

## Database Setup

### Kraken Database

**Option 1: Standard Database (~180 GB)**

```bash
# Create database directory
mkdir -p ~/databases/kraken
cd ~/databases/kraken

# Download and build (takes several hours)
kraken-build --standard --db standard_db --threads 16

# Set environment variable
echo 'export KRAKEN_DB="$HOME/databases/kraken/standard_db"' >> ~/.bashrc
source ~/.bashrc
```

**Option 2: MiniKraken Database (~8 GB, faster)**

```bash
# Download pre-built MiniKraken
cd ~/databases/kraken
wget https://genome-idx.s3.amazonaws.com/kraken/minikraken2_v2_8GB_201904.tgz
tar -xzf minikraken2_v2_8GB_201904.tgz

# Set environment variable
echo 'export KRAKEN_DB="$HOME/databases/kraken/minikraken2_v2_8GB_201904"' >> ~/.bashrc
source ~/.bashrc
```

**Option 3: Bacteria-only Database (~30 GB)**

```bash
cd ~/databases/kraken
mkdir bacteria_db
cd bacteria_db

# Build bacteria-only database
kraken-build --download-taxonomy --db .
kraken-build --download-library bacteria --db .
kraken-build --build --db . --threads 16

# Set environment variable
echo 'export KRAKEN_DB="$HOME/databases/kraken/bacteria_db"' >> ~/.bashrc
source ~/.bashrc
```

### MLST Database

```bash
# MLST databases are auto-downloaded
# Verify P. aeruginosa scheme exists
mlst --longlist | grep "paer"
# Should show: paer (Pseudomonas aeruginosa)
```

### ABRicate Databases

```bash
# Update all databases
abricate-get_db --db resfinder --force
abricate-get_db --db card --force
abricate-get_db --db vfdb --force
abricate-get_db --db argannot --force
abricate-get_db --db ncbi --force
abricate-get_db --db plasmidfinder --force

# Verify installation
abricate --list
```

### Reference Genomes

```bash
# Download P. aeruginosa reference genomes
mkdir -p ~/references/pseudomonas

# PAO1 reference
cd ~/references/pseudomonas
wget ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/006/765/GCF_000006765.1_ASM676v1/GCF_000006765.1_ASM676v1_genomic.fna.gz
gunzip GCF_000006765.1_ASM676v1_genomic.fna.gz
mv GCF_000006765.1_ASM676v1_genomic.fna PAO1_reference.fasta

# PA14 reference
wget ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/014/625/GCF_000014625.1_ASM1462v1/GCF_000014625.1_ASM1462v1_genomic.fna.gz
gunzip GCF_000014625.1_ASM1462v1_genomic.fna.gz
mv GCF_000014625.1_ASM1462v1_genomic.fna PA14_reference.fasta
```

---

## Verification

### Test Individual Tools

```bash
# Activate environment
conda activate pa_analysis

# Test each tool
fastqc --version    # Should show v0.12.1
fastp --version     # Should show 0.23.2
spades.py --version # Should show 3.14.1
quast.py --version  # Should show 5.2.0
prokka --version    # Should show 1.13+
kraken --version    # Should show 1.1.1
mlst --version      # Should show 2.23+
snippy --version    # Should show 4.3+
abricate --version  # Should show 0.8+
roary --version     # Should show 3.13+
parsnp --version    # Should show 1.7+
```

### Test Pipeline

```bash
# Download test data
mkdir -p ~/test_pa_pipeline
cd ~/test_pa_pipeline

# Download small test dataset (optional)
# Or use your own small dataset

# Run pipeline on test data
bash /path/to/pa_genomic_analysis/scripts/pa_analysis_pipeline.sh \
    -i test_reads/ \
    -o test_results/ \
    -t 4 \
    -s qc

# Check output
ls test_results/
```

### Verification Checklist

- [ ] All tools installed and accessible
- [ ] Tool versions match requirements
- [ ] Kraken database configured
- [ ] ABRicate databases updated
- [ ] Reference genomes downloaded
- [ ] Test run completed successfully
- [ ] Configuration file updated

---

## Troubleshooting

### Common Issues

**Issue 1: Command not found**

```bash
# Check if tool is in PATH
which fastqc

# If not found, ensure conda environment is activated
conda activate pa_analysis

# Or add to PATH manually
export PATH="/path/to/tool/bin:$PATH"
```

**Issue 2: Kraken database error**

```bash
# Verify KRAKEN_DB is set
echo $KRAKEN_DB

# Check database files exist
ls $KRAKEN_DB

# Test database
kraken --db $KRAKEN_DB --threads 1 --check
```

**Issue 3: Perl module missing**

```bash
# Install missing Perl modules
cpan -i Bio::Perl
cpan -i Module::Name
```

**Issue 4: Python package missing**

```bash
# Install Python packages
pip install biopython numpy pandas
```

**Issue 5: Memory errors**

```bash
# Reduce thread count
-t 4  # Instead of -t 16

# Increase system swap space
sudo fallocate -l 32G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

**Issue 6: Disk space**

```bash
# Check disk space
df -h

# Clean conda cache
conda clean --all

# Remove unnecessary files
rm -rf tmp/ *.tmp
```

### Getting Help

**Check tool documentation:**
```bash
tool_name --help
tool_name --man
```

**Check logs:**
```bash
cat results/pipeline.log
tail -f results/pipeline.log
```

**Community support:**
- Bioconda: https://bioconda.github.io/
- Biostars: https://www.biostars.org/
- SeqAnswers: http://seqanswers.com/

---

## Post-Installation

### Configure Pipeline

```bash
# Edit configuration
nano /path/to/pa_genomic_analysis/config/pipeline_config.sh

# Update paths
export KRAKEN_DB="/your/path/to/kraken/database"
export DEFAULT_THREADS=16
```

### Set Up Aliases (Optional)

```bash
# Add to ~/.bashrc
cat >> ~/.bashrc << 'EOF'

# PA Analysis Pipeline
alias pa_pipeline='bash /path/to/pa_genomic_analysis/scripts/pa_analysis_pipeline.sh'
alias pa_env='conda activate pa_analysis'

EOF

source ~/.bashrc
```

### Test Complete Pipeline

```bash
# Run all steps on test data
pa_pipeline -i test_reads/ -o test_results/ -t 8 -s all
```

---

## Next Steps

1. **Read the workflow guide:** `docs/WORKFLOW.md`
2. **Review example analysis:** `examples/example_analysis.sh`
3. **Prepare your data:** Organize FASTQ files
4. **Run the pipeline:** Start with QC step
5. **Interpret results:** Use interpretation guide

---

## Updates and Maintenance

### Keep Tools Updated

```bash
# Update conda packages
conda activate pa_analysis
conda update --all

# Update ABRicate databases
abricate-get_db --db resfinder --force
abricate-get_db --db card --force
abricate-get_db --db vfdb --force

# Update MLST database
mlst --longlist  # This auto-updates
```

### Check for Pipeline Updates

```bash
cd /path/to/pa_genomic_analysis
git pull origin main
```

---

## Support

For installation issues:
1. Check this guide
2. Review tool documentation
3. Search Biostars/SeqAnswers
4. Open GitHub issue

---

Installation complete! Proceed to the workflow guide to start your analysis.
