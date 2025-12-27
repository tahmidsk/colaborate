# Step-by-Step Workflow Guide

## Complete Workflow for Pseudomonas aeruginosa Genomic Analysis

This document provides detailed step-by-step instructions for each analysis stage.

---

## Table of Contents

1. [Preparation](#1-preparation)
2. [Quality Control & Assembly](#2-quality-control--assembly)
3. [MLST & Serotyping](#3-mlst--serotyping)
4. [SNP Detection](#4-snp-detection)
5. [Resistance Gene Analysis](#5-resistance-gene-analysis)
6. [Virulence Factor Analysis](#6-virulence-factor-analysis)
7. [Comparative Genomics](#7-comparative-genomics)
8. [Results Interpretation](#8-results-interpretation)

---

## 1. Preparation

### 1.1 Environment Setup

```bash
# Clone or navigate to the pipeline directory
cd /path/to/pa_genomic_analysis

# Activate conda environment
conda activate pa_analysis

# Verify all tools are installed
bash scripts/check_dependencies.sh
```

### 1.2 Data Organization

Organize your raw sequencing data:

```
project_directory/
├── raw_reads/
│   ├── PA001_R1.fastq.gz
│   ├── PA001_R2.fastq.gz
│   ├── PA002_R1.fastq.gz
│   ├── PA002_R2.fastq.gz
│   ├── PA003_R1.fastq.gz
│   ├── PA003_R2.fastq.gz
│   └── PA004_R1.fastq.gz
│   └── PA004_R2.fastq.gz
└── reference/
    └── PAO1_reference.fasta  # For SNP analysis
```

### 1.3 Configuration

Edit configuration file if needed:

```bash
nano config/pipeline_config.sh

# Update these variables:
export KRAKEN_DB="/path/to/your/kraken/database"
export DEFAULT_THREADS=16
```

---

## 2. Quality Control & Assembly

### 2.1 Overview

**Purpose:** Assess read quality, filter low-quality reads, assemble genomes, and annotate genes.

**Tools Used:**
- FastQC v0.12.1 - Initial quality assessment
- FastP v0.23.2 - Quality filtering and trimming
- SPAdes v3.14.1 - De novo genome assembly
- Quast v5.2.0 - Assembly quality metrics
- Prokka v1.13.4 - Genome annotation
- Kraken v1.1.1 - Taxonomic classification

### 2.2 Execute Step 1

```bash
bash scripts/pa_analysis_pipeline.sh \
  -i raw_reads/ \
  -o results/ \
  -t 16 \
  -s qc
```

### 2.3 What Happens

**Stage 1.1: Raw Quality Screening**
- FastQC analyzes each FASTQ file
- Generates HTML reports with quality metrics
- Identifies potential issues (adapters, low quality bases)

**Stage 1.2: Quality Filtering**
- FastP removes adapters automatically
- Filters reads below quality threshold
- Trims low-quality ends
- Outputs cleaned FASTQ files

**Stage 1.3: Post-trim QC**
- FastQC re-analyzes trimmed reads
- Confirms improvement in quality

**Stage 1.4: De Novo Assembly**
- SPAdes assembles each sample
- Uses multiple k-mer sizes (21, 33, 55, 77)
- Applies error correction
- Outputs contigs.fasta for each sample

**Stage 1.5: Assembly Quality**
- Quast evaluates assembly quality
- Metrics: N50, L50, total length, # contigs
- Compares all assemblies

**Stage 1.6: Genome Annotation**
- Prokka predicts genes, rRNAs, tRNAs
- Generates GFF3, GenBank, protein FASTA files
- Species-specific annotation for P. aeruginosa

**Stage 1.7: Taxonomic Classification**
- Kraken confirms species identity
- Detects potential contamination

### 2.4 Expected Outputs

```
results/
├── qc/
│   ├── raw/
│   │   ├── PA001_R1_fastqc.html
│   │   └── PA001_R1_fastqc.zip
│   └── trimmed/
│       ├── PA001_fastp.html
│       └── PA001_R1_trimmed_fastqc.html
├── trimmed/
│   ├── PA001_R1_trimmed.fastq.gz
│   └── PA001_R2_trimmed.fastq.gz
├── assembly/
│   ├── PA001/
│   │   └── contigs.fasta
│   ├── PA001_contigs.fasta
│   └── quast_results/
│       └── report.html
├── annotation/
│   └── PA001/
│       ├── PA001.gff
│       ├── PA001.gbk
│       ├── PA001.faa
│       └── PA001.ffn
└── taxonomy/
    └── PA001_kraken_report.txt
```

### 2.5 Quality Checks

Review these metrics:

```bash
# Check FastQC reports
firefox results/qc/raw/PA001_R1_fastqc.html

# Review assembly statistics
cat results/assembly/quast_results/report.txt

# Verify species identification
cat results/taxonomy/PA001_kraken_report.txt
```

**Good Assembly Criteria:**
- N50 > 100 kb
- Total length: 5.5-7.0 Mb (P. aeruginosa genome size)
- # contigs < 500
- GC content: ~65-67%

---

## 3. MLST & Serotyping

### 3.1 Overview

**Purpose:** Determine sequence type and serotype for epidemiological tracking.

**Tools Used:**
- MLST - Multi-locus sequence typing
- PAst v1.0 - P. aeruginosa serotyper

**MLST Genes:** acsA, aroE, guaA, mutL, nuoD, ppsA, trpE

### 3.2 Execute Step 2

```bash
bash scripts/pa_analysis_pipeline.sh \
  -i results/assembly \
  -o results/ \
  -t 16 \
  -s mlst
```

### 3.3 What Happens

**Stage 2.1: MLST Analysis**
- Extracts sequences of 7 housekeeping genes
- Compares against PubMLST database
- Assigns allele numbers for each gene
- Determines sequence type (ST)

**Stage 2.2: Serotyping**
- Identifies O-antigen genes
- Determines serotype (O1-O20)

### 3.4 Expected Outputs

```
results/
├── mlst/
│   ├── mlst_results.tsv
│   └── PA001_mlst_detail.txt
├── serotype/
│   └── PA001_serotype.txt
└── typing_summary.txt
```

### 3.5 Interpretation

**MLST Results:**
```
PA001: ST-645
PA002: ST-773
PA003: ST-2238
PA004: ST-645
```

**Clinical Significance:**
- ST-645: International high-risk clone, often MDR
- ST-773: Emerging clone in Asia
- ST-2238: Associated with chronic infections

**Serotypes:**
- O-antigen type affects immunogenicity
- Important for vaccine development

---

## 4. SNP Detection

### 4.1 Overview

**Purpose:** Identify genetic variations between isolates and reference.

**Tool Used:** Snippy v4.3.6

**Requirements:** Reference genome (e.g., PAO1 or closest match)

### 4.2 Execute Step 3

```bash
bash scripts/pa_analysis_pipeline.sh \
  -i raw_reads/ \
  -o results/ \
  -r reference/PAO1_reference.fasta \
  -t 16 \
  -s snp
```

### 4.3 What Happens

**For Each Sample:**
- Maps reads to reference genome
- Identifies SNPs and indels
- Generates VCF files
- Creates consensus sequences

**Core SNP Analysis:**
- Identifies SNPs present in all samples
- Creates alignment of core SNPs
- Builds phylogenetic tree

### 4.4 Expected Outputs

```
results/snp_analysis/
├── PA001/
│   ├── snps.vcf
│   ├── snps.tab
│   ├── snps.txt
│   └── snps.aligned.fa
├── core.aln
├── core.vcf
├── core.tree
└── snp_summary.txt
```

### 4.5 Interpretation

**SNP Counts:**
- Low SNPs (<50): Closely related, possible outbreak
- Medium SNPs (50-500): Same lineage, different sources
- High SNPs (>500): Diverse isolates

**Phylogenetic Tree:**
- Cluster analysis reveals relationships
- Transmission pathways
- Outbreak investigation

---

## 5. Resistance Gene Analysis

### 5.1 Overview

**Purpose:** Identify antibiotic resistance genes and predict resistance phenotype.

**Databases:**
- ResFinder - Acquired resistance genes
- CARD - Comprehensive resistance mechanisms

### 5.2 Execute Step 4

```bash
bash scripts/pa_analysis_pipeline.sh \
  -i results/assembly \
  -o results/ \
  -t 16 \
  -s args
```

### 5.3 What Happens

- Screens assemblies against ResFinder database
- Screens assemblies against CARD database
- Identifies resistance genes with ≥90% identity, ≥60% coverage
- Categorizes by antibiotic class
- Generates resistance profile

### 5.4 Expected Outputs

```
results/antibiotic_resistance/
├── resfinder/
│   ├── PA001_resfinder.tsv
│   └── resfinder_summary.tsv
├── card/
│   ├── PA001_card.tsv
│   └── card_summary.tsv
├── resistance_profile.txt
└── antibiotic_classes.txt
```

### 5.5 Interpretation

**Key Resistance Genes:**

**Beta-lactams:**
- blaOXA, blaPDC - Cephalosporinases
- blaVIM, blaIMP - Carbapenemases (very concerning)

**Aminoglycosides:**
- aac, aph, ant genes - Aminoglycoside modifying enzymes

**Fluoroquinolones:**
- gyrA, parC mutations
- qnr genes

**Colistin:**
- mcr genes (rare in PA)
- pmr mutations

**Clinical Correlation:**
- Compare with antimicrobial susceptibility testing (AST)
- Guide treatment decisions
- Infection control measures

---

## 6. Virulence Factor Analysis

### 6.1 Overview

**Purpose:** Identify genes contributing to pathogenicity.

**Database:** VFDB (Virulence Factor Database)

**Tool:** ABRicate v0.8.13

### 6.2 Execute Step 5

```bash
bash scripts/pa_analysis_pipeline.sh \
  -i results/assembly \
  -o results/ \
  -t 16 \
  -s vf
```

### 6.3 What Happens

- Screens against VFDB
- Identifies virulence factors with ≥80% identity, ≥60% coverage
- Categorizes virulence factors
- Assesses pathogenic potential

### 6.4 Expected Outputs

```
results/virulence_factors/
├── vfdb/
│   ├── PA001_vfdb.tsv
│   ├── PA001_vf_report.txt
│   └── vfdb_summary.tsv
├── vf_categories.txt
├── pathogenicity_profile.txt
└── virulence_summary.txt
```

### 6.5 Interpretation

**Key Virulence Factors:**

**Type III Secretion System (T3SS):**
- ExoS, ExoT, ExoY, ExoU
- Direct injection into host cells
- Associated with acute infections

**Exotoxin A (toxA):**
- Inhibits protein synthesis
- Major virulence determinant

**Alginate Production:**
- Biofilm formation
- Chronic infections (CF patients)

**Iron Acquisition:**
- Pyoverdine, pyochelin
- Essential for infection

**Quorum Sensing:**
- Las, Rhl, PQS systems
- Coordinate virulence expression

**Pathogenicity Assessment:**
- High (>20 VFs): Highly pathogenic
- Moderate (10-20 VFs): Pathogenic
- Low (<10 VFs): Lower pathogenicity

---

## 7. Comparative Genomics

### 7.1 Overview

**Purpose:** Compare genomes to identify core/accessory genes and phylogenetic relationships.

**Tools:**
- Roary v3.13.0 - Pan-genome analysis
- Parsnp v1.7.4 - Core genome phylogenetics

### 7.2 Execute Step 6

```bash
bash scripts/pa_analysis_pipeline.sh \
  -i results/annotation \
  -o results/ \
  -t 16 \
  -s comparative
```

### 7.3 What Happens

**Pan-genome Analysis (Roary):**
- Compares all annotated genomes
- Identifies orthologs at 95% identity
- Defines core genome (genes in ≥99% strains)
- Defines accessory genome (remaining genes)
- Creates gene presence/absence matrix

**Phylogenetic Analysis (Parsnp):**
- Aligns core genome sequences
- Identifies SNPs in core genome
- Excludes recombinant regions
- Constructs maximum likelihood tree

### 7.4 Expected Outputs

```
results/comparative_genomics/
├── pangenome/
│   ├── gene_presence_absence.csv
│   ├── summary_statistics.txt
│   ├── core_gene_alignment.aln
│   ├── accessory_binary_genes.fa
│   └── pangenome_summary.txt
├── phylogenetics/
│   ├── parsnp.tree
│   ├── core_genome.tree
│   └── README_iTOL.txt
└── comparative_analysis_report.txt
```

### 7.5 Interpretation

**Core Genome:**
- ~5,000-5,500 genes (typical for PA)
- Essential housekeeping genes
- Species definition

**Accessory Genome:**
- Variable between strains
- Pathogenicity islands
- Resistance genes
- Adaptation genes

**Unique Genes:**
- Strain-specific features
- Novel virulence/resistance mechanisms

### 7.6 Visualization with iTOL

```bash
# 1. Open iTOL in browser
firefox https://itol.embl.de/

# 2. Upload tree
# File: results/comparative_genomics/phylogenetics/core_genome.tree

# 3. Add annotations
# - MLST types
# - Resistance profiles
# - Virulence profiles
# - Geographic origin

# 4. Customize display
# - Color branches by ST
# - Add heatmaps for genes
# - Display bootstrap values

# 5. Export
# Save as SVG or PNG
```

---

## 8. Results Interpretation

### 8.1 Integrated Analysis

Combine all results for comprehensive understanding:

**Sample PA001:**
- ST: 645 (high-risk clone)
- Serotype: O11
- SNPs from reference: 1,247
- Resistance genes: 12 (including blaVIM-2)
- Virulence factors: 35 (high pathogenicity)
- Pan-genome: 6,234 genes (5,124 core, 1,110 accessory)

### 8.2 Clinical Implications

**For Infection Control:**
- ST-645 spread: Implement enhanced precautions
- High SNP diversity: Multiple introductions vs. single outbreak
- Carbapenem resistance: Contact precautions required

**For Treatment:**
- Resistance profile guides antibiotic selection
- Multi-drug resistance requires combination therapy
- Consult infectious disease specialist

**For Research:**
- Unique genes: Potential novel mechanisms
- Comparative analysis: Evolution and transmission
- Vaccine targets: Conserved virulence factors

### 8.3 Reporting

Generate comprehensive report including:

1. **Executive Summary**
   - Number of isolates
   - Key findings

2. **Molecular Epidemiology**
   - MLST types
   - Phylogenetic relationships
   - Outbreak assessment

3. **Antimicrobial Resistance**
   - Resistance gene profiles
   - Clinical relevance
   - Treatment implications

4. **Virulence Assessment**
   - Key virulence factors
   - Pathogenic potential
   - Disease associations

5. **Comparative Genomics**
   - Pan-genome structure
   - Unique features
   - Evolutionary insights

### 8.4 Quality Assurance

Before finalizing:

```bash
# Check all samples completed
ls results/assembly/*.fasta | wc -l

# Verify annotation
ls results/annotation/*/*.gff | wc -l

# Review assembly quality
cat results/assembly/quast_results/report.txt

# Confirm all analyses complete
ls results/*/
```

---

## Appendix: Troubleshooting

### Common Issues and Solutions

**Issue 1: Assembly fragmented (>1000 contigs)**
- Cause: Low coverage, contamination
- Solution: Check read depth, filter contamination

**Issue 2: No MLST match**
- Cause: Novel ST, poor assembly
- Solution: Check assembly quality, submit new ST

**Issue 3: Kraken shows contamination**
- Cause: Sample contamination, cross-contamination
- Solution: Re-extract DNA, improve sterile technique

**Issue 4: Low virulence factors detected**
- Cause: Incomplete assembly, environmental strain
- Solution: Verify assembly, check strain background

**Issue 5: Roary fails**
- Cause: Incompatible GFF format, memory
- Solution: Re-annotate with Prokka, increase memory

---

## Conclusion

This workflow provides comprehensive genomic characterization of P. aeruginosa isolates, enabling:
- Outbreak investigation
- Resistance surveillance
- Virulence assessment
- Evolutionary studies
- Clinical decision support

For questions or issues, refer to the main README or contact the bioinformatics team.
