# Requirements for PA Genomic Analysis Pipeline

## Software Dependencies

### Core Analysis Tools

| Tool | Version | Purpose | Installation |
|------|---------|---------|--------------|
| FastQC | 0.12.1 | Quality control | `conda install -c bioconda fastqc=0.12.1` |
| FastP | 0.23.2 | Read trimming | `conda install -c bioconda fastp=0.23.2` |
| SPAdes | 3.14.1 | Genome assembly | `conda install -c bioconda spades=3.14.1` |
| Quast | 5.2.0 | Assembly QC | `conda install -c bioconda quast=5.2.0` |
| Prokka | 1.13.4+ | Annotation | `conda install -c bioconda prokka` |
| Kraken | 1.1.1 | Taxonomy | `conda install -c bioconda kraken` |

### Typing Tools

| Tool | Version | Purpose | Installation |
|------|---------|---------|--------------|
| MLST | 2.23+ | MLST typing | `conda install -c bioconda mlst` |
| PAst | 1.0 | Serotyping | Manual (from GitHub) |

### Variant Analysis

| Tool | Version | Purpose | Installation |
|------|---------|---------|--------------|
| Snippy | 4.3.6+ | SNP calling | `conda install -c bioconda snippy` |
| FastTree | 2.1.11 | Tree building | `conda install -c bioconda fasttree` |

### Resistance & Virulence

| Tool | Version | Purpose | Installation |
|------|---------|---------|--------------|
| ABRicate | 0.8.13+ | Gene screening | `conda install -c bioconda abricate` |

### Comparative Genomics

| Tool | Version | Purpose | Installation |
|------|---------|---------|--------------|
| Roary | 3.13.0 | Pan-genome | `conda install -c bioconda roary` |
| Parsnp | 1.7.4 | Phylogenetics | `conda install -c bioconda parsnp` |

## Databases

### Required Databases

| Database | Size | Purpose | Source |
|----------|------|---------|--------|
| Kraken Standard | ~180 GB | Taxonomy | `kraken-build --standard` |
| Kraken MiniKraken | ~8 GB | Taxonomy (alt) | Pre-built download |
| ResFinder | ~50 MB | Resistance | `abricate-get_db --db resfinder` |
| CARD | ~100 MB | Resistance | `abricate-get_db --db card` |
| VFDB | ~50 MB | Virulence | `abricate-get_db --db vfdb` |
| PubMLST | Auto | MLST | Auto-downloaded by mlst |

### Optional Databases

| Database | Size | Purpose | Source |
|----------|------|---------|--------|
| NCBI AMRFinder | ~100 MB | Resistance | `abricate-get_db --db ncbi` |
| ARG-ANNOT | ~50 MB | Resistance | `abricate-get_db --db argannot` |
| PlasmidFinder | ~20 MB | Plasmids | `abricate-get_db --db plasmidfinder` |

## System Requirements

### Minimum Configuration

- **CPU:** 8 cores
- **RAM:** 32 GB
- **Storage:** 500 GB
- **OS:** Linux (Ubuntu 20.04+)

### Recommended Configuration

- **CPU:** 16+ cores
- **RAM:** 64+ GB
- **Storage:** 1+ TB
- **OS:** Linux (Ubuntu 22.04)

## Python Packages

```
biopython>=1.79
numpy>=1.21.0
pandas>=1.3.0
matplotlib>=3.4.0
seaborn>=0.11.0
```

Install with:
```bash
pip install biopython numpy pandas matplotlib seaborn
```

## Perl Modules

```
Bio::Perl
Bio::Roary
```

Install with:
```bash
cpan -i Bio::Perl
cpan -i Bio::Roary
```

## Java Runtime

- **Version:** Java 8 or higher
- **Purpose:** Required by Quast and some other tools

```bash
sudo apt install default-jre
java -version  # Verify
```

## Quick Installation (Conda)

```bash
# Create environment
conda create -n pa_analysis python=3.9

# Activate
conda activate pa_analysis

# Install all tools
conda install -c bioconda -c conda-forge \
    fastqc=0.12.1 \
    fastp=0.23.2 \
    spades=3.14.1 \
    quast=5.2.0 \
    prokka \
    kraken \
    mlst \
    snippy \
    abricate \
    roary \
    parsnp \
    fasttree

# Setup databases
abricate-get_db --db resfinder --force
abricate-get_db --db card --force
abricate-get_db --db vfdb --force
```

## Verification

Test all tools are installed:

```bash
fastqc --version
fastp --version
spades.py --version
quast.py --version
prokka --version
kraken --version
mlst --version
snippy --version
abricate --version
roary --version
parsnp --version
```

All commands should return version numbers without errors.
