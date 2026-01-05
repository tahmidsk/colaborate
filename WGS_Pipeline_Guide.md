# Whole Genome Sequencing (WGS) Bioinformatics Pipeline - Linux Tutorial

This comprehensive guide provides step-by-step instructions for analyzing bacterial whole genome sequencing data on Linux, based on the methodology used for Pseudomonas aeruginosa genome analysis.

---

## Table of Contents

1. [Prerequisites and Environment Setup](#1-prerequisites-and-environment-setup)
2. [Installing Required Tools](#2-installing-required-tools)
3. [Quality Control of Raw Sequences](#3-quality-control-of-raw-sequences)
4. [Quality Filtering and Trimming](#4-quality-filtering-and-trimming)
5. [De Novo Genome Assembly](#5-de-novo-genome-assembly)
6. [Assembly Quality Assessment](#6-assembly-quality-assessment)
7. [Genome Annotation](#7-genome-annotation)
8. [Taxonomic Classification](#8-taxonomic-classification)
9. [MLST and Serotyping](#9-mlst-and-serotyping)
10. [SNP and Indel Detection](#10-snp-and-indel-detection)
11. [Antibiotic Resistance Gene Identification](#11-antibiotic-resistance-gene-identification)
12. [Virulence Factor Identification](#12-virulence-factor-identification)
13. [Comparative Genomics and Pangenome Analysis](#13-comparative-genomics-and-pangenome-analysis)
14. [Phylogenetic Analysis](#14-phylogenetic-analysis)
15. [Data Visualization](#15-data-visualization)

---

## 1. Prerequisites and Environment Setup

### System Requirements
- Linux operating system (Ubuntu 20.04+ recommended)
- Minimum 16 GB RAM (32 GB recommended for assembly)
- At least 100 GB free disk space
- Internet connection for downloading tools and databases

### Create Project Directory Structure

```bash
# Create main project directory
mkdir -p ~/wgs_analysis

# Create subdirectories for organized workflow
cd ~/wgs_analysis
mkdir -p raw_reads          # Raw FASTQ files from sequencer
mkdir -p quality_control    # FastQC reports
mkdir -p trimmed_reads      # Quality-filtered reads
mkdir -p assembly           # SPades output
mkdir -p assembly_qc        # QUAST reports
mkdir -p annotation         # Prokka output
mkdir -p taxonomy           # Kraken output
mkdir -p mlst               # MLST results
mkdir -p serotype           # Serotyping results
mkdir -p snp_analysis       # Snippy output
mkdir -p amr                # Antibiotic resistance results
mkdir -p virulence          # Virulence factor results
mkdir -p pangenome          # Roary output
mkdir -p phylogeny          # Phylogenetic trees

echo "Directory structure created successfully!"
ls -la
```

**Explanation:** This creates an organized folder structure to keep all analysis outputs separate and easily manageable. Each folder will contain outputs from specific analysis steps.

### Install Conda (Package Manager)

Conda simplifies the installation of bioinformatics tools and manages dependencies.

```bash
# Download Miniconda installer
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh

# Make installer executable and run
chmod +x Miniconda3-latest-Linux-x86_64.sh
./Miniconda3-latest-Linux-x86_64.sh -b -p $HOME/miniconda3

# Initialize conda
source $HOME/miniconda3/bin/activate
conda init bash

# Restart your terminal or source bashrc
source ~/.bashrc

# Add bioconda channels (for bioinformatics tools)
conda config --add channels defaults
conda config --add channels bioconda
conda config --add channels conda-forge
conda config --set channel_priority strict
```

**Explanation:** 
- Conda is a package manager that handles software dependencies
- Bioconda channel contains most bioinformatics tools
- Channel priority ensures consistent package installation

---

## 2. Installing Required Tools

### Create a Dedicated Conda Environment

```bash
# Create a new environment for WGS analysis
conda create -n wgs_env python=3.9 -y

# Activate the environment
conda activate wgs_env
```

**Explanation:** Using a dedicated conda environment prevents conflicts between different software versions and keeps your system clean.

### Install All Required Tools

```bash
# Activate the environment first
conda activate wgs_env

# Install quality control tools
conda install -y fastqc=0.12.1        # Raw sequence quality assessment
conda install -y fastp=0.23.2          # Quality filtering and trimming

# Install assembly tools
conda install -y spades=3.15.5         # De novo genome assembler

# Install assembly quality assessment
conda install -y quast=5.2.0           # Assembly quality metrics

# Install annotation tools
conda install -y prokka=1.14.6         # Prokaryotic genome annotation

# Install taxonomic classification
conda install -y kraken2=2.1.2         # Taxonomic classification
conda install -y bracken=2.8           # Abundance estimation

# Install MLST tools
conda install -y mlst=2.23.0           # Multi-locus sequence typing

# Install SNP analysis
conda install -y snippy=4.6.0          # SNP/indel detection

# Install AMR and virulence tools
conda install -y abricate=1.0.1        # Screening for resistance and virulence genes

# Install pangenome analysis tools
conda install -y roary=3.13.0          # Pangenome analysis

# Install phylogenetic tools
conda install -y parsnp=1.7.4          # Core genome alignment and phylogeny

# Install additional utilities
conda install -y samtools=1.17         # SAM/BAM file handling
conda install -y bcftools=1.17         # VCF file handling
conda install -y bwa=0.7.17            # Read alignment
```

**Explanation:** Each tool serves a specific purpose in the pipeline:
- **FastQC**: Generates quality reports for raw sequencing reads
- **FastP**: Filters and trims low-quality bases and adapters
- **SPades**: Assembles short reads into contigs/scaffolds
- **QUAST**: Evaluates assembly quality metrics
- **Prokka**: Annotates genes, proteins, and features
- **Kraken2**: Assigns taxonomic labels to sequences
- **MLST**: Identifies sequence type based on housekeeping genes
- **Snippy**: Identifies SNPs and indels against a reference
- **ABRicate**: Screens for resistance and virulence genes
- **Roary**: Performs pangenome analysis
- **Parsnp**: Generates core genome alignments for phylogeny

### Verify Installation

```bash
# Check if all tools are installed correctly
fastqc --version
fastp --version
spades.py --version
quast --version
prokka --version
kraken2 --version
mlst --version
snippy --version
abricate --version
roary --version
parsnp --version

echo "All tools installed successfully!"
```

---

## 3. Quality Control of Raw Sequences

### Prepare Your Input Files

First, place your raw FASTQ files in the `raw_reads` directory:

```bash
cd ~/wgs_analysis/raw_reads

# If you have files elsewhere, copy them here
# cp /path/to/your/sample_R1.fastq.gz .
# cp /path/to/your/sample_R2.fastq.gz .

# List your input files
ls -lh *.fastq.gz
```

**Note:** Illumina paired-end reads typically come as two files:
- `*_R1.fastq.gz` (forward reads)
- `*_R2.fastq.gz` (reverse reads)

### Run FastQC on Raw Reads

```bash
cd ~/wgs_analysis

# Activate environment
conda activate wgs_env

# Run FastQC on all raw FASTQ files
# -o specifies output directory
# -t specifies number of threads (adjust based on your CPU)

fastqc raw_reads/*.fastq.gz \
    -o quality_control/ \
    -t 4

echo "FastQC analysis complete!"
ls -la quality_control/
```

**Explanation:**
- **FastQC** analyzes raw reads and generates HTML reports
- Reports include per-base sequence quality, GC content, adapter content, etc.
- `-t 4` uses 4 threads for parallel processing (adjust based on your CPU cores)

### Interpreting FastQC Results

```bash
# Open the HTML report in a browser
# If using a graphical desktop:
firefox quality_control/*_fastqc.html &

# Or generate a summary text file
cd quality_control
for file in *_fastqc.zip; do
    unzip -q "$file"
done

# Extract summary results
for dir in *_fastqc; do
    echo "=== $dir ===" >> ../fastqc_summary.txt
    cat "$dir/summary.txt" >> ../fastqc_summary.txt
    echo "" >> ../fastqc_summary.txt
done

cat ../fastqc_summary.txt
```

**Key Quality Metrics to Check:**
| Metric | Good | Acceptable | Poor |
|--------|------|------------|------|
| Per base sequence quality | Green (Q>28) | Yellow (Q20-28) | Red (Q<20) |
| Per sequence quality scores | Peak at Q>30 | Peak at Q20-30 | Peak at Q<20 |
| Adapter content | <5% | 5-20% | >20% |
| Sequence duplication | <20% | 20-50% | >50% |

---

## 4. Quality Filtering and Trimming

### Run FastP for Quality Trimming

```bash
cd ~/wgs_analysis

# Define sample name (modify for each sample)
SAMPLE="PA-CU-1"

# Run FastP for quality filtering and trimming
fastp \
    --in1 raw_reads/${SAMPLE}_R1.fastq.gz \
    --in2 raw_reads/${SAMPLE}_R2.fastq.gz \
    --out1 trimmed_reads/${SAMPLE}_R1_trimmed.fastq.gz \
    --out2 trimmed_reads/${SAMPLE}_R2_trimmed.fastq.gz \
    --html trimmed_reads/${SAMPLE}_fastp.html \
    --json trimmed_reads/${SAMPLE}_fastp.json \
    --thread 4 \
    --qualified_quality_phred 20 \
    --unqualified_percent_limit 40 \
    --length_required 50 \
    --detect_adapter_for_pe \
    --correction \
    --cut_front \
    --cut_tail \
    --cut_window_size 4 \
    --cut_mean_quality 20

echo "FastP trimming complete for $SAMPLE"
```

**Explanation of FastP Parameters:**
- `--qualified_quality_phred 20`: Minimum quality score of 20 (99% accuracy)
- `--unqualified_percent_limit 40`: Allow up to 40% bases below quality threshold
- `--length_required 50`: Discard reads shorter than 50 bp after trimming
- `--detect_adapter_for_pe`: Auto-detect adapters for paired-end reads
- `--correction`: Enable base correction in overlapping regions
- `--cut_front/--cut_tail`: Trim low quality bases from 5' and 3' ends
- `--cut_window_size 4`: Window size for quality trimming
- `--cut_mean_quality 20`: Mean quality threshold for sliding window

### Process Multiple Samples with a Loop

```bash
cd ~/wgs_analysis

# Create a file listing all sample names
# One sample name per line (without _R1.fastq.gz suffix)
cat > samples.txt << 'EOF'
PA-CU-1
PA-CU-2
PA-CU-3
PA-CU-5
EOF

# Process all samples
while read SAMPLE; do
    echo "Processing $SAMPLE..."
    
    fastp \
        --in1 raw_reads/${SAMPLE}_R1.fastq.gz \
        --in2 raw_reads/${SAMPLE}_R2.fastq.gz \
        --out1 trimmed_reads/${SAMPLE}_R1_trimmed.fastq.gz \
        --out2 trimmed_reads/${SAMPLE}_R2_trimmed.fastq.gz \
        --html trimmed_reads/${SAMPLE}_fastp.html \
        --json trimmed_reads/${SAMPLE}_fastp.json \
        --thread 4
    
    echo "$SAMPLE completed!"
done < samples.txt

echo "All samples processed!"
```

### Verify Trimmed Read Quality

```bash
# Run FastQC on trimmed reads to verify improvement
fastqc trimmed_reads/*_trimmed.fastq.gz \
    -o quality_control/ \
    -t 4

echo "Post-trimming QC complete!"
```

---

## 5. De Novo Genome Assembly

### Run SPades Assembler

```bash
cd ~/wgs_analysis

# Define sample name
SAMPLE="PA-CU-1"

# Run SPades de novo assembly
# --careful: Reduces mismatches and short indels
# --cov-cutoff auto: Automatic coverage cutoff
spades.py \
    -1 trimmed_reads/${SAMPLE}_R1_trimmed.fastq.gz \
    -2 trimmed_reads/${SAMPLE}_R2_trimmed.fastq.gz \
    -o assembly/${SAMPLE} \
    --threads 8 \
    --memory 32 \
    --careful \
    --cov-cutoff auto

echo "Assembly complete for $SAMPLE"
```

**Explanation of SPades Parameters:**
- `-1` and `-2`: Paired-end input files
- `-o`: Output directory
- `--threads`: Number of CPU threads to use
- `--memory`: Maximum RAM in GB
- `--careful`: Runs additional mismatch correction
- `--cov-cutoff auto`: Automatically removes low-coverage contigs

### Assemble Multiple Samples

```bash
cd ~/wgs_analysis

# Loop through all samples
while read SAMPLE; do
    echo "Assembling $SAMPLE..."
    
    spades.py \
        -1 trimmed_reads/${SAMPLE}_R1_trimmed.fastq.gz \
        -2 trimmed_reads/${SAMPLE}_R2_trimmed.fastq.gz \
        -o assembly/${SAMPLE} \
        --threads 8 \
        --memory 32 \
        --careful \
        --cov-cutoff auto
    
    echo "$SAMPLE assembly completed!"
done < samples.txt
```

### Key Output Files

```bash
# List main output files
ls -la assembly/${SAMPLE}/

# Main assembly files:
# - contigs.fasta: All assembled contigs
# - scaffolds.fasta: Scaffolds (contigs joined by gaps)
# - assembly_graph.fastg: Assembly graph
```

**Key Assembly Output Files:**
| File | Description |
|------|-------------|
| `contigs.fasta` | Primary assembly output - use this for most analyses |
| `scaffolds.fasta` | Contigs linked by gaps (N's) |
| `spades.log` | Detailed log file for troubleshooting |

---

## 6. Assembly Quality Assessment

### Run QUAST for Assembly Metrics

```bash
cd ~/wgs_analysis

SAMPLE="PA-CU-1"

# Download P. aeruginosa reference genome (optional, for comparison)
# Using PAO1 reference as example
wget -P assembly_qc/ \
    https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/006/765/GCF_000006765.1_ASM676v1/GCF_000006765.1_ASM676v1_genomic.fna.gz

gunzip assembly_qc/GCF_000006765.1_ASM676v1_genomic.fna.gz

# Run QUAST without reference (basic mode)
quast.py \
    assembly/${SAMPLE}/contigs.fasta \
    -o assembly_qc/${SAMPLE} \
    --threads 4

# OR run QUAST with reference genome (more detailed)
quast.py \
    assembly/${SAMPLE}/contigs.fasta \
    -r assembly_qc/GCF_000006765.1_ASM676v1_genomic.fna \
    -o assembly_qc/${SAMPLE}_with_ref \
    --threads 4

echo "QUAST analysis complete!"
```

**Explanation:**
- QUAST calculates assembly statistics (N50, total length, # contigs)
- Reference comparison shows alignment statistics and misassemblies
- Reports are generated in HTML, PDF, and text formats

### Compare Multiple Assemblies

```bash
cd ~/wgs_analysis

# Run QUAST on all assemblies together
quast.py \
    assembly/PA-CU-1/contigs.fasta \
    assembly/PA-CU-2/contigs.fasta \
    assembly/PA-CU-3/contigs.fasta \
    assembly/PA-CU-5/contigs.fasta \
    -o assembly_qc/comparison \
    --labels "PA-CU-1,PA-CU-2,PA-CU-3,PA-CU-5" \
    --threads 4

# View summary report
cat assembly_qc/comparison/report.txt
```

### Key Quality Metrics

```bash
# View the summary statistics
cat assembly_qc/${SAMPLE}/report.txt
```

**Important Assembly Metrics:**
| Metric | Typical for Good Bacterial Assembly |
|--------|-------------------------------------|
| Total length | Close to expected genome size (~6.3 Mb for P. aeruginosa) |
| Number of contigs | < 200 (ideally < 100) |
| N50 | > 50,000 bp (higher is better) |
| L50 | < 30 (fewer contigs needed for 50% genome) |
| GC content | ~66% for P. aeruginosa |
| Largest contig | > 200,000 bp |

---

## 7. Genome Annotation

### Run Prokka for Genome Annotation

```bash
cd ~/wgs_analysis

SAMPLE="PA-CU-1"

# Run Prokka annotation
prokka \
    assembly/${SAMPLE}/contigs.fasta \
    --outdir annotation/${SAMPLE} \
    --prefix ${SAMPLE} \
    --genus Pseudomonas \
    --species aeruginosa \
    --strain ${SAMPLE} \
    --kingdom Bacteria \
    --gcode 11 \
    --cpus 8 \
    --force

echo "Prokka annotation complete for $SAMPLE"
```

**Explanation of Prokka Parameters:**
- `--genus/--species`: Taxonomic classification for better annotation
- `--strain`: Sample identifier
- `--kingdom Bacteria`: Specifies bacterial genetic code
- `--gcode 11`: Bacterial/archaeal genetic code table
- `--cpus`: Number of parallel threads
- `--force`: Overwrite existing output

### Annotate All Samples

```bash
cd ~/wgs_analysis

while read SAMPLE; do
    echo "Annotating $SAMPLE..."
    
    prokka \
        assembly/${SAMPLE}/contigs.fasta \
        --outdir annotation/${SAMPLE} \
        --prefix ${SAMPLE} \
        --genus Pseudomonas \
        --species aeruginosa \
        --strain ${SAMPLE} \
        --kingdom Bacteria \
        --gcode 11 \
        --cpus 8 \
        --force
    
    echo "$SAMPLE annotation completed!"
done < samples.txt
```

### Key Output Files

```bash
ls -la annotation/${SAMPLE}/
```

**Prokka Output Files:**
| File Extension | Description |
|----------------|-------------|
| `.gff` | General Feature Format with annotations (needed for Roary) |
| `.gbk` | GenBank format file |
| `.fna` | Nucleotide FASTA file of contigs |
| `.faa` | Protein FASTA file |
| `.ffn` | Nucleotide FASTA of CDS |
| `.tsv` | Tab-separated feature table |
| `.txt` | Summary statistics |

### View Annotation Summary

```bash
# View annotation statistics
cat annotation/${SAMPLE}/${SAMPLE}.txt

# Count different feature types
grep -c "CDS" annotation/${SAMPLE}/${SAMPLE}.gff
grep -c "tRNA" annotation/${SAMPLE}/${SAMPLE}.gff
grep -c "rRNA" annotation/${SAMPLE}/${SAMPLE}.gff
```

---

## 8. Taxonomic Classification

### Set Up Kraken2 Database

```bash
cd ~/wgs_analysis

# Create database directory
mkdir -p taxonomy/kraken2_db

# Download pre-built standard database (smaller version for testing)
# For full analysis, use the standard or PlusPFP database
kraken2-build --download-taxonomy --db taxonomy/kraken2_db

# Download a smaller database (MiniKraken) for quick testing
# wget https://genome-idx.s3.amazonaws.com/kraken/k2_standard_08gb_20230605.tar.gz
# tar -xzf k2_standard_08gb_20230605.tar.gz -C taxonomy/kraken2_db

# OR use the standard library (requires ~100GB disk space)
# kraken2-build --standard --threads 8 --db taxonomy/kraken2_db
```

### Run Kraken2 for Taxonomic Classification

```bash
cd ~/wgs_analysis

SAMPLE="PA-CU-1"

# Run Kraken2 on assembled contigs
kraken2 \
    --db taxonomy/kraken2_db \
    --threads 8 \
    --output taxonomy/${SAMPLE}_kraken.out \
    --report taxonomy/${SAMPLE}_kraken_report.txt \
    assembly/${SAMPLE}/contigs.fasta

echo "Kraken2 classification complete for $SAMPLE"
```

**Explanation:**
- Kraken2 assigns taxonomic labels to each sequence
- Uses k-mer matching against a database of known genomes
- Output includes per-sequence classification and summary report

### View Classification Results

```bash
# View top classifications
head -20 taxonomy/${SAMPLE}_kraken_report.txt

# Count sequences classified as Pseudomonas aeruginosa
grep "Pseudomonas aeruginosa" taxonomy/${SAMPLE}_kraken_report.txt
```

### Run on All Samples

```bash
while read SAMPLE; do
    echo "Classifying $SAMPLE..."
    
    kraken2 \
        --db taxonomy/kraken2_db \
        --threads 8 \
        --output taxonomy/${SAMPLE}_kraken.out \
        --report taxonomy/${SAMPLE}_kraken_report.txt \
        assembly/${SAMPLE}/contigs.fasta
        
    echo "$SAMPLE classification completed!"
done < samples.txt
```

---

## 9. MLST and Serotyping

### Run MLST Analysis

```bash
cd ~/wgs_analysis

SAMPLE="PA-CU-1"

# Run MLST (uses PubMLST database)
# The tool automatically detects the species scheme
mlst \
    assembly/${SAMPLE}/contigs.fasta \
    > mlst/${SAMPLE}_mlst.txt

# View results
cat mlst/${SAMPLE}_mlst.txt
```

**Explanation:**
- MLST identifies sequence types based on 7 housekeeping genes
- For P. aeruginosa: acsA, aroE, guaA, mutL, nuoD, ppsA, trpE
- Results show allele numbers and final ST (Sequence Type)

### Run MLST on All Samples

```bash
cd ~/wgs_analysis

# Process all samples and create a combined report
echo -e "Sample\tScheme\tST\tacsA\taroE\tguaA\tmutL\tnuoD\tppsA\ttrpE" > mlst/all_mlst_results.txt

while read SAMPLE; do
    mlst assembly/${SAMPLE}/contigs.fasta >> mlst/all_mlst_results.txt
done < samples.txt

# View combined results
cat mlst/all_mlst_results.txt
```

### P. aeruginosa Serotyping with PAst

```bash
cd ~/wgs_analysis

# Download PAst tool for P. aeruginosa serotyping
git clone https://github.com/Sandmanhz/PAst.git

# Run PAst on assembled genome
python PAst/past.py \
    -i assembly/${SAMPLE}/contigs.fasta \
    -o serotype/${SAMPLE}_serotype.txt

# View serotype results
cat serotype/${SAMPLE}_serotype.txt
```

**Note:** PAst identifies O-antigen serotypes specific to P. aeruginosa through BLAST-based analysis.

---

## 10. SNP and Indel Detection

### Run Snippy for SNP Analysis

```bash
cd ~/wgs_analysis

SAMPLE="PA-CU-1"

# Download reference genome if not already done
# Using P. aeruginosa PAO1 as reference
REFERENCE="assembly_qc/GCF_000006765.1_ASM676v1_genomic.fna"

# Run Snippy for single sample
snippy \
    --outdir snp_analysis/${SAMPLE} \
    --ref $REFERENCE \
    --R1 trimmed_reads/${SAMPLE}_R1_trimmed.fastq.gz \
    --R2 trimmed_reads/${SAMPLE}_R2_trimmed.fastq.gz \
    --cpus 8 \
    --ram 16 \
    --mincov 10 \
    --minfrac 0.9

echo "Snippy analysis complete for $SAMPLE"
```

**Explanation of Snippy Parameters:**
- `--ref`: Reference genome for SNP calling
- `--mincov 10`: Minimum read coverage depth (10x)
- `--minfrac 0.9`: Minimum fraction of reads supporting variant (90%)
- `--cpus/--ram`: Computational resources

### Run Snippy on All Samples

```bash
cd ~/wgs_analysis

REFERENCE="assembly_qc/GCF_000006765.1_ASM676v1_genomic.fna"

while read SAMPLE; do
    echo "Running Snippy on $SAMPLE..."
    
    snippy \
        --outdir snp_analysis/${SAMPLE} \
        --ref $REFERENCE \
        --R1 trimmed_reads/${SAMPLE}_R1_trimmed.fastq.gz \
        --R2 trimmed_reads/${SAMPLE}_R2_trimmed.fastq.gz \
        --cpus 8 \
        --ram 16
        
    echo "$SAMPLE SNP analysis completed!"
done < samples.txt
```

### Generate Core SNP Alignment

```bash
# Create core SNP alignment from multiple samples
snippy-core \
    --ref $REFERENCE \
    --prefix snp_analysis/core \
    snp_analysis/PA-CU-1 \
    snp_analysis/PA-CU-2 \
    snp_analysis/PA-CU-3 \
    snp_analysis/PA-CU-5

# View summary
cat snp_analysis/core.txt
```

### View SNP Results

```bash
# View SNP summary
head snp_analysis/${SAMPLE}/snps.tab

# Count total SNPs
wc -l snp_analysis/${SAMPLE}/snps.vcf

# View variant types
grep -v "^#" snp_analysis/${SAMPLE}/snps.vcf | cut -f8 | cut -d';' -f1 | sort | uniq -c
```

---

## 11. Antibiotic Resistance Gene Identification

### Run ABRicate with ResFinder Database

```bash
cd ~/wgs_analysis

SAMPLE="PA-CU-1"

# List available databases
abricate --list

# Run ABRicate with ResFinder database
abricate \
    --db resfinder \
    --minid 80 \
    --mincov 60 \
    assembly/${SAMPLE}/contigs.fasta \
    > amr/${SAMPLE}_resfinder.tab

echo "ResFinder analysis complete for $SAMPLE"
```

**Explanation:**
- `--db resfinder`: Uses ResFinder database for resistance genes
- `--minid 80`: Minimum DNA identity of 80%
- `--mincov 60`: Minimum coverage of 60%

### Run with CARD Database

```bash
# Update CARD database (if needed)
abricate-get_db --db card

# Run ABRicate with CARD database
abricate \
    --db card \
    --minid 80 \
    --mincov 60 \
    assembly/${SAMPLE}/contigs.fasta \
    > amr/${SAMPLE}_card.tab

echo "CARD analysis complete for $SAMPLE"
```

### Process All Samples

```bash
cd ~/wgs_analysis

# ResFinder analysis for all samples
while read SAMPLE; do
    echo "Analyzing $SAMPLE for AMR genes..."
    
    abricate \
        --db resfinder \
        --minid 80 \
        --mincov 60 \
        assembly/${SAMPLE}/contigs.fasta \
        > amr/${SAMPLE}_resfinder.tab
    
    abricate \
        --db card \
        --minid 80 \
        --mincov 60 \
        assembly/${SAMPLE}/contigs.fasta \
        > amr/${SAMPLE}_card.tab
        
done < samples.txt

# Create summary report
abricate --summary amr/*_resfinder.tab > amr/resfinder_summary.tab
abricate --summary amr/*_card.tab > amr/card_summary.tab

echo "AMR analysis complete for all samples!"
```

### View Results

```bash
# View ResFinder results
cat amr/${SAMPLE}_resfinder.tab

# View summary matrix
cat amr/resfinder_summary.tab

# View CARD results
cat amr/${SAMPLE}_card.tab
```

---

## 12. Virulence Factor Identification

### Run ABRicate with VFDB

```bash
cd ~/wgs_analysis

SAMPLE="PA-CU-1"

# Run ABRicate with Virulence Factor Database (VFDB)
abricate \
    --db vfdb \
    --minid 80 \
    --mincov 60 \
    assembly/${SAMPLE}/contigs.fasta \
    > virulence/${SAMPLE}_vfdb.tab

echo "VFDB analysis complete for $SAMPLE"
```

**Explanation:**
- VFDB (Virulence Factor Database) contains known virulence genes
- Identifies genes for toxins, adhesins, secretion systems, etc.

### Process All Samples

```bash
cd ~/wgs_analysis

while read SAMPLE; do
    echo "Analyzing $SAMPLE for virulence factors..."
    
    abricate \
        --db vfdb \
        --minid 80 \
        --mincov 60 \
        assembly/${SAMPLE}/contigs.fasta \
        > virulence/${SAMPLE}_vfdb.tab
        
done < samples.txt

# Create summary matrix
abricate --summary virulence/*_vfdb.tab > virulence/vfdb_summary.tab

echo "Virulence analysis complete!"
```

### View Virulence Results

```bash
# View individual sample results
cat virulence/${SAMPLE}_vfdb.tab

# View summary across all samples
cat virulence/vfdb_summary.tab

# Count virulence factors per sample
for file in virulence/*_vfdb.tab; do
    count=$(wc -l < "$file")
    echo "$file: $((count-1)) virulence factors"
done
```

---

## 13. Comparative Genomics and Pangenome Analysis

### Prepare Input for Roary

```bash
cd ~/wgs_analysis

# Create a directory for GFF files (input for Roary)
mkdir -p pangenome/gff_files

# Copy all GFF3 files from Prokka output
cp annotation/*/PA-CU*.gff pangenome/gff_files/

# Verify files
ls -la pangenome/gff_files/
```

### Download Additional Genomes for Comparison

```bash
cd ~/wgs_analysis/pangenome

# Create a file with accession numbers from PathogenWatch or NCBI
# Example: Download genomes of the same ST types
mkdir -p reference_genomes

# Download genomes using NCBI datasets tool (install if needed)
# conda install -c conda-forge ncbi-datasets-cli

# OR manually download from NCBI and add their GFFs
# For this example, we'll proceed with our 4 isolates
```

### Run Roary Pangenome Analysis

```bash
cd ~/wgs_analysis/pangenome

# Run Roary on all GFF files
# -e creates multiFASTA alignment of core genes
# -n uses fast nucleotide alignment with MAFFT
roary \
    -f roary_output \
    -e -n \
    -v \
    -p 8 \
    -i 95 \
    -cd 99 \
    gff_files/*.gff

echo "Roary analysis complete!"
```

**Explanation of Roary Parameters:**
- `-f roary_output`: Output directory
- `-e -n`: Create core gene alignment using nucleotides
- `-v`: Verbose output
- `-p 8`: Use 8 threads
- `-i 95`: Minimum percentage identity for BLASTp (95%)
- `-cd 99`: Core gene percentage threshold (genes in 99% of strains)

### View Pangenome Results

```bash
# View summary statistics
cat pangenome/roary_output/summary_statistics.txt

# View core genes
head pangenome/roary_output/core_gene_alignment.aln

# View gene presence/absence matrix
head pangenome/roary_output/gene_presence_absence.csv

# Count gene categories
echo "Core genes (in all isolates):"
awk -F',' '$4==4' pangenome/roary_output/gene_presence_absence.csv | wc -l

echo "Accessory genes:"
awk -F',' '$4<4' pangenome/roary_output/gene_presence_absence.csv | wc -l
```

### Visualize Pangenome

```bash
# Generate plots (requires python packages)
python ~/miniconda3/envs/wgs_env/bin/roary_plots.py \
    pangenome/roary_output/accessory_binary_genes.fa.newick \
    pangenome/roary_output/gene_presence_absence.csv

# Move plots to output
mv *.svg pangenome/roary_output/
mv *.png pangenome/roary_output/
```

---

## 14. Phylogenetic Analysis

### Run Parsnp for Core Genome Alignment

```bash
cd ~/wgs_analysis/phylogeny

# Create directory for genome FASTA files
mkdir -p genomes

# Copy assembled genomes (contigs.fasta)
cp ../assembly/*/contigs.fasta genomes/

# Rename files for clarity
cd genomes
for f in contigs.fasta; do
    mv "$f" "$(dirname "$(pwd)")/PA-CU-1.fasta" 2>/dev/null
done
cd ..

# Better approach: copy with proper names
cp ../assembly/PA-CU-1/contigs.fasta genomes/PA-CU-1.fasta
cp ../assembly/PA-CU-2/contigs.fasta genomes/PA-CU-2.fasta
cp ../assembly/PA-CU-3/contigs.fasta genomes/PA-CU-3.fasta
cp ../assembly/PA-CU-5/contigs.fasta genomes/PA-CU-5.fasta

# Download reference genome
cp ../assembly_qc/GCF_000006765.1_ASM676v1_genomic.fna genomes/PAO1_reference.fasta
```

### Run Parsnp

```bash
cd ~/wgs_analysis/phylogeny

# Run Parsnp for core genome alignment
# -c: Use all sequences from each genome
# -x: Enable recombination detection and filtering
parsnp \
    -d genomes/ \
    -r genomes/PAO1_reference.fasta \
    -o parsnp_output \
    -p 8 \
    -c \
    -x

echo "Parsnp analysis complete!"
```

**Explanation of Parsnp Parameters:**
- `-d`: Directory containing genome FASTA files
- `-r`: Reference genome for alignment
- `-p`: Number of threads
- `-c`: Use all input sequences
- `-x`: Enable PhiPack recombination filtering

### View Parsnp Results

```bash
# View output files
ls -la phylogeny/parsnp_output/

# Main output files:
# - parsnp.tree: Newick format phylogenetic tree
# - parsnp.ggr: Gingr format for visualization
# - parsnp.xmfa: Core genome alignment

# View the tree
cat phylogeny/parsnp_output/parsnp.tree
```

### Convert Tree for iTOL Visualization

```bash
# Copy the Newick tree file
cp phylogeny/parsnp_output/parsnp.tree phylogeny/tree_for_itol.newick

# The .newick file can be uploaded directly to iTOL
echo "Tree file ready for iTOL: phylogeny/tree_for_itol.newick"
```

---

## 15. Data Visualization

### Upload Tree to iTOL (Interactive Tree Of Life)

```bash
# iTOL is a web-based tool at: https://itol.embl.de/

# Steps:
# 1. Go to https://itol.embl.de/
# 2. Click "Upload" 
# 3. Upload the file: phylogeny/tree_for_itol.newick
# 4. Annotate and customize the tree visualization

# Prepare annotation files for iTOL
cd ~/wgs_analysis

# Create MLST annotation file for iTOL
echo "TREE_COLORS
SEPARATOR TAB
DATA" > phylogeny/mlst_colors.txt

# Create color annotation based on ST types
# (Customize based on your MLST results)
cat >> phylogeny/mlst_colors.txt << 'EOF'
PA-CU-1	range	#FF0000	ST645
PA-CU-2	range	#00FF00	ST773
PA-CU-3	range	#0000FF	ST2238
PA-CU-5	range	#FFFF00	ST645
EOF

echo "Annotation files created for iTOL visualization"
```

### Create Summary Reports

```bash
cd ~/wgs_analysis

# Create a comprehensive summary report
cat > final_report.txt << 'EOF'
=========================================
WHOLE GENOME SEQUENCING ANALYSIS REPORT
=========================================

Date: $(date)
Samples analyzed: PA-CU-1, PA-CU-2, PA-CU-3, PA-CU-5

EOF

# Add assembly statistics
echo "--- ASSEMBLY STATISTICS ---" >> final_report.txt
cat assembly_qc/comparison/report.txt >> final_report.txt

# Add MLST results
echo "" >> final_report.txt
echo "--- MLST RESULTS ---" >> final_report.txt
cat mlst/all_mlst_results.txt >> final_report.txt

# Add AMR summary
echo "" >> final_report.txt
echo "--- ANTIBIOTIC RESISTANCE GENES ---" >> final_report.txt
cat amr/resfinder_summary.tab >> final_report.txt

# Add virulence summary
echo "" >> final_report.txt
echo "--- VIRULENCE FACTORS ---" >> final_report.txt
cat virulence/vfdb_summary.tab >> final_report.txt

echo "Final report generated: final_report.txt"
```

---

## Quick Reference: Complete Pipeline Script

Save this as `run_wgs_pipeline.sh` for automated analysis:

```bash
#!/bin/bash

# WGS Analysis Pipeline
# Usage: ./run_wgs_pipeline.sh sample_name

set -e  # Exit on error

# Configuration
SAMPLE=$1
THREADS=8
REFERENCE="reference/PAO1.fasta"

# Activate conda environment
source ~/miniconda3/bin/activate wgs_env

echo "=== Starting WGS Pipeline for $SAMPLE ==="

# Step 1: Quality Control
echo "Step 1: Running FastQC..."
fastqc raw_reads/${SAMPLE}_R*.fastq.gz -o quality_control/ -t $THREADS

# Step 2: Quality Trimming
echo "Step 2: Running FastP..."
fastp \
    --in1 raw_reads/${SAMPLE}_R1.fastq.gz \
    --in2 raw_reads/${SAMPLE}_R2.fastq.gz \
    --out1 trimmed_reads/${SAMPLE}_R1_trimmed.fastq.gz \
    --out2 trimmed_reads/${SAMPLE}_R2_trimmed.fastq.gz \
    --html trimmed_reads/${SAMPLE}_fastp.html \
    --json trimmed_reads/${SAMPLE}_fastp.json \
    --thread $THREADS

# Step 3: Genome Assembly
echo "Step 3: Running SPades..."
spades.py \
    -1 trimmed_reads/${SAMPLE}_R1_trimmed.fastq.gz \
    -2 trimmed_reads/${SAMPLE}_R2_trimmed.fastq.gz \
    -o assembly/${SAMPLE} \
    --threads $THREADS \
    --careful

# Step 4: Assembly QC
echo "Step 4: Running QUAST..."
quast.py assembly/${SAMPLE}/contigs.fasta -o assembly_qc/${SAMPLE}

# Step 5: Genome Annotation
echo "Step 5: Running Prokka..."
prokka \
    assembly/${SAMPLE}/contigs.fasta \
    --outdir annotation/${SAMPLE} \
    --prefix ${SAMPLE} \
    --genus Pseudomonas \
    --species aeruginosa \
    --cpus $THREADS \
    --force

# Step 6: MLST
echo "Step 6: Running MLST..."
mlst assembly/${SAMPLE}/contigs.fasta > mlst/${SAMPLE}_mlst.txt

# Step 7: SNP Analysis
echo "Step 7: Running Snippy..."
snippy \
    --outdir snp_analysis/${SAMPLE} \
    --ref $REFERENCE \
    --R1 trimmed_reads/${SAMPLE}_R1_trimmed.fastq.gz \
    --R2 trimmed_reads/${SAMPLE}_R2_trimmed.fastq.gz \
    --cpus $THREADS

# Step 8: AMR Detection
echo "Step 8: Running AMR analysis..."
abricate --db resfinder assembly/${SAMPLE}/contigs.fasta > amr/${SAMPLE}_resfinder.tab
abricate --db card assembly/${SAMPLE}/contigs.fasta > amr/${SAMPLE}_card.tab

# Step 9: Virulence Factors
echo "Step 9: Running virulence factor analysis..."
abricate --db vfdb assembly/${SAMPLE}/contigs.fasta > virulence/${SAMPLE}_vfdb.tab

echo "=== Pipeline Complete for $SAMPLE ==="
```

### Make the Script Executable

```bash
chmod +x run_wgs_pipeline.sh

# Run for a single sample
./run_wgs_pipeline.sh PA-CU-1

# Run for all samples
for sample in PA-CU-1 PA-CU-2 PA-CU-3 PA-CU-5; do
    ./run_wgs_pipeline.sh $sample
done
```

---

## Troubleshooting Common Issues

### Memory Issues During Assembly

```bash
# If SPades runs out of memory, reduce k-mer sizes
spades.py -1 R1.fastq.gz -2 R2.fastq.gz -o output \
    -k 21,33,55 --memory 16 --threads 4
```

### Database Download Issues

```bash
# Update ABRicate databases
abricate-get_db --db resfinder
abricate-get_db --db card
abricate-get_db --db vfdb
```

### Conda Environment Problems

```bash
# If tools conflict, create separate environments
conda create -n assembly_env spades quast
conda create -n annotation_env prokka
conda create -n amr_env abricate
```

---

## References

1. Andrews, S. (2010). FastQC: A Quality Control Tool for High Throughput Sequence Data.
2. Chen, S. et al. (2018). fastp: an ultra-fast all-in-one FASTQ preprocessor. Bioinformatics.
3. Prjibelski, A. et al. (2020). Using SPAdes De Novo Assembler. Current Protocols in Bioinformatics.
4. Seemann, T. (2014). Prokka: rapid prokaryotic genome annotation. Bioinformatics.
5. Page, A.J. et al. (2015). Roary: rapid large-scale prokaryote pan genome analysis. Bioinformatics.
6. Florensa, A.F. et al. (2022). ResFinder – an open online resource for identification of antimicrobial resistance genes.
7. Letunic, I. & Bork, P. (2021). Interactive Tree Of Life (iTOL) v5. Nucleic Acids Research.

---

**Note:** This pipeline was designed for bacterial WGS analysis. Adjust parameters and tools based on your specific organism and research requirements.

For questions or issues, please open an issue in the repository.
