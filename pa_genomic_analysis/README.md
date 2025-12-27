# Pseudomonas aeruginosa Genomic Analysis Pipeline

A comprehensive bioinformatics pipeline for genomic analysis of *Pseudomonas aeruginosa* isolates, implementing state-of-the-art tools for quality control, assembly, annotation, and comparative genomics.

## Overview

This pipeline implements the complete workflow described in section 3.13.4 of the research methodology, covering:

1. **Quality Control and Genome Assembly** - FastQC, FastP, SPAdes, Quast, Prokka, Kraken
2. **MLST and Serotyping** - PubMLST, PAst
3. **SNP and Indel Detection** - Snippy
4. **Antibiotic Resistance Gene Identification** - ResFinder, CARD
5. **Virulence Factor Analysis** - ABRicate, VFDB
6. **Comparative Genomics** - Roary, Parsnp, iTOL

## Requirements

### Software Dependencies

Install the following bioinformatics tools before running the pipeline:

#### Core Tools
- **FastQC** v0.12.1 - Quality control for sequencing data
- **FastP** v0.23.2 - Read filtering and trimming
- **SPAdes** v3.14.1 - Genome assembly
- **Quast** v5.2.0 - Assembly quality assessment
- **Prokka** v1.13.4 - Genome annotation
- **Kraken** v1.1.1 - Taxonomic classification

#### Typing Tools
- **MLST** - Multi-locus sequence typing
- **PAst** v1.0 - P. aeruginosa serotyper

#### Analysis Tools
- **Snippy** v4.3.6 - SNP detection
- **ABRicate** v0.8.13 - Gene database screening
- **Roary** v3.13.0 - Pan-genome analysis
- **Parsnp** v1.7.4 - Core genome phylogenetics
- **FastTree** - Phylogenetic tree construction (optional)

### Installation

#### Using Conda (Recommended)

```bash
# Create conda environment
conda create -n pa_analysis python=3.9

# Activate environment
conda activate pa_analysis

# Install tools
conda install -c bioconda fastqc fastp spades quast prokka kraken mlst snippy abricate roary parsnp

# Install PAst separately
git clone https://github.com/zhaoqianyue/PAst.git
cd PAst
# Follow installation instructions
```

#### Using Docker

```bash
# Pull pre-built container (example)
docker pull staphb/spades
docker pull staphb/prokka
# ... etc for each tool
```

### Database Setup

**Automated Setup (Recommended):**

```bash
# Run the automated database setup script
bash scripts/setup_databases.sh
```

**Manual Setup:**

```bash
# Download and setup ABRicate databases
abricate-get_db --db resfinder --force
abricate-get_db --db card --force
abricate-get_db --db vfdb --force

# Download Kraken database (choose one option)
# Option 1: MiniKraken (~8 GB, fastest)
wget https://genome-idx.s3.amazonaws.com/kraken/minikraken2_v2_8GB_201904.tgz
tar -xzf minikraken2_v2_8GB_201904.tgz

# Option 2: Standard Kraken (~180 GB, most comprehensive)
kraken-build --standard --db /path/to/kraken/database

# Update configuration
export KRAKEN_DB="/path/to/kraken/database"
```

**For detailed database setup instructions and all download codes, see:**
- **[Database Setup Guide](docs/DATABASE_SETUP.md)** - Complete database download instructions

## Quick Start

### 1. Prepare Your Data

Organize your raw sequencing reads in a directory:

```
raw_reads/
├── sample1_R1.fastq.gz
├── sample1_R2.fastq.gz
├── sample2_R1.fastq.gz
└── sample2_R2.fastq.gz
```

### 2. Run Complete Pipeline

```bash
bash scripts/pa_analysis_pipeline.sh \
  -i raw_reads/ \
  -o results/ \
  -t 16 \
  -s all
```

### 3. Run Individual Steps

```bash
# Step 1: Quality control and assembly
bash scripts/pa_analysis_pipeline.sh -i raw_reads/ -o results/ -s qc

# Step 2: MLST and serotyping
bash scripts/pa_analysis_pipeline.sh -i raw_reads/ -o results/ -s mlst

# Step 3: SNP detection (requires reference genome)
bash scripts/pa_analysis_pipeline.sh -i raw_reads/ -o results/ -r reference.fasta -s snp

# Step 4: Antibiotic resistance genes
bash scripts/pa_analysis_pipeline.sh -i raw_reads/ -o results/ -s args

# Step 5: Virulence factors
bash scripts/pa_analysis_pipeline.sh -i raw_reads/ -o results/ -s vf

# Step 6: Comparative genomics
bash scripts/pa_analysis_pipeline.sh -i raw_reads/ -o results/ -s comparative
```

## Pipeline Steps

### Step 1: Quality Control and Genome Assembly

**Input:** Raw FASTQ files (paired-end)

**Process:**
1. Quality screening with FastQC
2. Adapter trimming and quality filtering with FastP
3. De novo assembly with SPAdes
4. Assembly quality assessment with Quast
5. Genome annotation with Prokka
6. Taxonomic confirmation with Kraken

**Output:**
- `qc/` - Quality control reports
- `assembly/` - Assembled contigs
- `annotation/` - Annotated genomes (GFF3, GenBank, FASTA)

### Step 2: MLST and Serotyping

**Input:** Assembled contigs

**Process:**
1. MLST typing based on 7 housekeeping genes (acsA, aroE, guaA, mutL, nuoD, ppsA, trpE)
2. O antigen serotyping with PAst

**Output:**
- `mlst/` - Sequence types and allele profiles
- `serotype/` - Serotype predictions

### Step 3: SNP and Indel Detection

**Input:** Raw reads + reference genome

**Process:**
1. Variant calling with Snippy
2. Core SNP alignment
3. Phylogenetic tree construction

**Output:**
- `snp_analysis/` - VCF files, SNP tables, core alignment
- `snp_analysis/core.tree` - Phylogenetic tree

### Step 4: Antibiotic Resistance Genes

**Input:** Assembled contigs

**Process:**
1. Screen against ResFinder database
2. Screen against CARD database
3. Resistance profile generation

**Output:**
- `antibiotic_resistance/` - ARG predictions and profiles
- `antibiotic_resistance/resistance_profile.txt` - Summary report

### Step 5: Virulence Factor Identification

**Input:** Assembled contigs

**Process:**
1. Screen against VFDB using ABRicate
2. Pathogenicity assessment
3. Categorization of virulence factors

**Output:**
- `virulence_factors/` - VF predictions and pathogenicity profiles

### Step 6: Comparative Genomics

**Input:** Annotated genomes (GFF3 files)

**Process:**
1. Pan-genome analysis with Roary (95% identity, 99% core definition)
2. Core genome phylogeny with Parsnp
3. Gene presence/absence matrix
4. iTOL visualization preparation

**Output:**
- `comparative_genomics/pangenome/` - Pan-genome results
- `comparative_genomics/phylogenetics/` - Trees and alignments
- iTOL annotation files

## Output Structure

```
results/
├── pipeline.log
├── qc/
│   ├── raw/          # FastQC reports for raw reads
│   └── trimmed/      # FastQC and FastP reports
├── trimmed/          # Trimmed FASTQ files
├── assembly/         # Assembled contigs and Quast results
├── annotation/       # Prokka annotations (GFF3, GenBank, etc.)
├── taxonomy/         # Kraken classification results
├── mlst/            # MLST results
├── serotype/        # Serotype predictions
├── snp_analysis/    # SNP calling and core genome
├── antibiotic_resistance/
│   ├── resfinder/
│   ├── card/
│   └── resistance_profile.txt
├── virulence_factors/
│   ├── vfdb/
│   └── pathogenicity_profile.txt
└── comparative_genomics/
    ├── pangenome/
    └── phylogenetics/
```

## Usage Examples

### Example 1: Analyze Clinical Isolates

```bash
# Analyze 4 P. aeruginosa clinical isolates
bash scripts/pa_analysis_pipeline.sh \
  -i clinical_samples/ \
  -o pa_clinical_analysis/ \
  -t 32 \
  -s all
```

### Example 2: SNP Analysis with Reference

```bash
# Perform SNP analysis against PAO1 reference
bash scripts/pa_analysis_pipeline.sh \
  -i isolates/ \
  -o snp_results/ \
  -r PAO1_reference.fasta \
  -t 16 \
  -s snp
```

### Example 3: Quick Resistance Screening

```bash
# Screen assemblies for resistance genes only
bash scripts/pa_analysis_pipeline.sh \
  -i assemblies/ \
  -o resistance_screen/ \
  -t 8 \
  -s args
```

## Comparative Analysis with PathogenWatch

For comparison with published sequences:

1. **Upload your sequences to PathogenWatch:**
   - Visit: https://pathogen.watch/
   - Upload your assembled genomes
   - Download metadata and assemblies

2. **Retrieve reference sequences:**
   ```bash
   # Download 72 Bangladesh sequences from PathogenWatch
   # Download ST645, ST773, ST2238 reference sequences
   ```

3. **Run comparative analysis:**
   ```bash
   # Combine your sequences with downloaded references
   # Re-run Step 6 (comparative genomics)
   ```

4. **Visualize in iTOL:**
   - Upload `core_genome.tree` to iTOL
   - Add metadata annotations
   - Color by MLST type, location, resistance profile

## Interpretation Guidelines

### MLST Results
- **ST645, ST773, ST2238**: High-risk clones
- Novel STs: Potential emerging lineages

### Resistance Genes
- **High concern**: bla genes (carbapenemases), mcr (colistin)
- **Clinical relevance**: Match resistance genes with phenotype

### Virulence Factors
- **Type III secretion system**: Key pathogenicity determinant
- **Exotoxins**: toxA, exoS, exoU, exoT
- **Biofilm genes**: pel, psl operons

### Pan-genome
- **Core genes**: Essential for P. aeruginosa biology
- **Accessory genes**: Adaptation, pathogenicity islands
- **Unique genes**: Sample-specific features

## Troubleshooting

### Common Issues

**Issue:** Tool not found
```bash
# Solution: Check installation
which fastqc
conda list

# Reinstall if needed
conda install -c bioconda fastqc
```

**Issue:** Kraken database not found
```bash
# Solution: Set KRAKEN_DB in config/pipeline_config.sh
export KRAKEN_DB=/path/to/kraken/db
```

**Issue:** Out of memory
```bash
# Solution: Reduce threads or increase memory
# Adjust SPADES parameters for lower memory usage
```

**Issue:** No SNPs detected
```bash
# Check: Are you using the correct reference?
# Ensure reference is closely related to your isolates
```

## Citations

When using this pipeline, please cite:

- **FastQC**: Andrews, S. (2010). FastQC: A quality control tool for high throughput sequence data.
- **FastP**: Chen, S., et al. (2018). fastp: an ultra-fast all-in-one FASTQ preprocessor. Bioinformatics, 34(17), i884-i890.
- **SPAdes**: Prjibelski, A., et al. (2020). Using SPAdes De Novo Assembler. Current Protocols in Bioinformatics, 70(1), e102.
- **Quast**: Gurevich, A., et al. (2013). QUAST: quality assessment tool for genome assemblies. Bioinformatics, 29(8), 1072-1075.
- **Prokka**: Seemann, T. (2014). Prokka: rapid prokaryotic genome annotation. Bioinformatics, 30(14), 2068-2069.
- **Kraken**: Wood, D. E., & Salzberg, S. L. (2014). Kraken: ultrafast metagenomic sequence classification. Genome biology, 15(3), 1-12.
- **MLST**: Jolley, K. A., & Maiden, M. C. (2010). BIGSdb: Scalable analysis of bacterial genome variation at the population level. BMC bioinformatics, 11(1), 1-11.
- **PAst**: Zhao, Y., et al. (2023). PAst: A Pseudomonas aeruginosa Serotyper.
- **Snippy**: Seemann, T. (2015). Snippy: fast bacterial variant calling from NGS reads.
- **ResFinder**: Florensa, A. F., et al. (2022). ResFinder–an open online resource for identification of antimicrobial resistance genes. Microbial genomics, 8(7).
- **CARD**: Alcock, B. P., et al. (2023). CARD 2023: expanded curation, support for machine learning, and resistome prediction at the Comprehensive Antibiotic Resistance Database. Nucleic Acids Research, 51(D1), D690-D699.
- **ABRicate**: Seemann, T. (2020). ABRicate: mass screening of contigs for antimicrobial resistance or virulence genes.
- **VFDB**: Chen, L., et al. (2016). VFDB 2016: hierarchical and refined dataset for big data analysis. Nucleic acids research, 44(D1), D694-D697.
- **Roary**: Page, A. J., et al. (2015). Roary: rapid large-scale prokaryote pan genome analysis. Bioinformatics, 31(22), 3691-3693.
- **Parsnp**: Rhoads, D. D., et al. (2024). Parsnp 2.0: Scalable Core-Genome Alignment for Massive Microbial Datasets.
- **iTOL**: Letunic, I., & Bork, P. (2021). Interactive Tree Of Life (iTOL) v5: an online tool for phylogenetic tree display and annotation. Nucleic acids research, 49(W1), W293-W296.

## Support

For issues or questions:
- **Database Setup**: See [Database Setup Guide](docs/DATABASE_SETUP.md) for all database download codes
- Check the documentation in `docs/`
- Review example outputs in `examples/`
- Open an issue on GitHub

## Documentation

- [README](README.md) - Overview and quick start
- [Installation Guide](docs/INSTALLATION.md) - Software installation
- **[Database Setup](docs/DATABASE_SETUP.md) - Database download codes and setup**
- [Workflow Guide](docs/WORKFLOW.md) - Step-by-step analysis
- [Methods](docs/METHODS.md) - Scientific methodology
- [Requirements](docs/REQUIREMENTS.md) - Dependencies
- [Quick Reference](docs/QUICK_REFERENCE.md) - Command reference

## License

This pipeline is provided as-is for research and educational purposes.

## Authors

Generated for the colaborate project - 2025
