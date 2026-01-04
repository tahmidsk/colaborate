# 16S rRNA Microbiome Analysis Pipeline

## Overview

This R script provides a comprehensive implementation of a 16S rRNA gene sequencing analysis pipeline for comparing gut and dermal microbiome communities. The pipeline follows best practices for microbiome data analysis and includes quality control, preprocessing, taxonomic analysis, diversity metrics, and differential abundance testing.

## Table of Contents

1. [Requirements](#requirements)
2. [Installation](#installation)
3. [Pipeline Overview](#pipeline-overview)
4. [Usage](#usage)
5. [Analysis Sections](#analysis-sections)
6. [Output](#output)
7. [Interpretation Guide](#interpretation-guide)

## Requirements

### Software
- R version 4.5.0 or higher
- FastQC v0.12.0 (for quality control)
- QIIME2 v2024.10 (for sequence processing)
- SILVA-138-99-nb-classifier (for taxonomic classification)

### R Packages
```r
# Core packages
install.packages(c("dplyr", "ggplot2", "tidyr", "scales"))

# Bioconductor packages
if (!require("BiocManager", quietly = TRUE))
    install.packages("BiocManager")

BiocManager::install(c("phyloseq", "DESeq2"))

# Additional packages
install.packages(c("ggpubr", "vegan", "picante", "effsize"))

# QIIME2R (from GitHub)
if (!require("devtools")) install.packages("devtools")
devtools::install_github("jbisanz/qiime2R")
```

### Package Versions (as specified in methods)
- phyloseq v1.52.0
- ggplot2 v3.5.2
- dplyr v1.1.4
- ggpubr v0.6.1
- tidyr v1.3.0
- scales v1.2.1
- qiime2R v0.99.6
- DESeq2 v1.42.0
- vegan v2.7-4
- picante (latest)
- effsize v0.8.1

## Installation

1. Clone or download this repository
2. Install required R packages (see above)
3. Ensure FastQC and QIIME2 are installed and accessible
4. Download SILVA-138-99-nb-classifier.qza from QIIME2 database

## Pipeline Overview

The pipeline consists of the following major sections:

```
Raw FASTQ files
    ↓
3.1 Quality Assessment & QIIME2 Processing
    ├── FastQC quality control
    ├── DADA2 filtering & denoising
    ├── Taxonomic classification
    └── Phylogenetic tree construction
    ↓
3.2 Data Preprocessing
    ├── Quality assessment
    ├── Taxonomic filtering (Bacteria only)
    ├── Remove contaminants (mitochondria/chloroplast)
    └── Prevalence-based filtering
    ↓
3.3 Relative Abundance Transformation
    ↓
3.4 Taxonomic Composition Analysis
    ├── Phylum-level analysis
    ├── Family-level analysis (top 15)
    ├── Genus-level analysis (top 15/25)
    └── Statistical comparisons
    ↓
3.5 Alpha Diversity Analysis
    ├── 6 diversity indices
    └── Statistical testing
    ↓
3.6 Beta Diversity Analysis
    ├── Bray-Curtis dissimilarity
    ├── PCoA ordination
    └── PERMANOVA
    ↓
3.7 Differential Abundance Analysis
    └── DESeq2 (Gut vs Derm)
```

## Usage

### Quick Start: Complete Analysis

```r
# Load the pipeline
source("16S_microbiome_analysis_pipeline.R")

# Run complete analysis
results <- run_complete_microbiome_analysis(
  qiime_dir = "path/to/qiime2/output",      # Directory with .qza files
  metadata_file = "path/to/metadata.tsv",    # Sample metadata
  output_dir = "results",                    # Output directory
  group_var = "SampleType",                  # Grouping variable name
  group1 = "Gut",                           # First group name
  group2 = "Derm"                           # Second group name (reference)
)
```

### Step-by-Step Execution

#### 1. Quality Control (External to R)

```bash
# Run FastQC on raw sequences
fastqc raw_sequences/*.fastq.gz -o fastqc_output -t 4
```

#### 2. QIIME2 Processing (External to R)

```bash
# Import sequences
qiime tools import \
  --type 'SampleData[PairedEndSequencesWithQuality]' \
  --input-path raw_sequences/ \
  --output-path demux-paired-end.qza \
  --input-format CasavaOneEightSingleLanePerSampleDirFmt

# DADA2 denoising (trim first 15bp, truncate at 240bp)
qiime dada2 denoise-paired \
  --i-demultiplexed-seqs demux-paired-end.qza \
  --p-trim-left-f 15 \
  --p-trim-left-r 15 \
  --p-trunc-len-f 240 \
  --p-trunc-len-r 240 \
  --o-table table.qza \
  --o-representative-sequences rep-seqs.qza \
  --o-denoising-stats denoising-stats.qza

# Taxonomic classification
qiime feature-classifier classify-sklearn \
  --i-classifier silva-138-99-nb-classifier.qza \
  --i-reads rep-seqs.qza \
  --o-classification taxonomy.qza

# Build phylogenetic tree
qiime phylogeny align-to-tree-mafft-fasttree \
  --i-sequences rep-seqs.qza \
  --o-alignment aligned-rep-seqs.qza \
  --o-masked-alignment masked-aligned-rep-seqs.qza \
  --o-tree unrooted-tree.qza \
  --o-rooted-tree rooted-tree.qza
```

#### 3. R Analysis

```r
# Load pipeline
source("16S_microbiome_analysis_pipeline.R")

# Import QIIME2 data
qiime_artifacts <- list(
  table = "table.qza",
  sequences = "rep-seqs.qza",
  taxonomy = "taxonomy.qza",
  tree = "rooted-tree.qza"
)

ps <- import_qiime2_to_phyloseq(qiime_artifacts, "metadata.tsv")

# Quality assessment
assess_phyloseq_quality(ps)

# Preprocessing
ps <- filter_bacteria_only(ps)
ps <- remove_organellar_sequences(ps)
ps <- prevalence_based_filtering(ps, min_samples = 2)

# Transform to relative abundance
ps_rel <- transform_to_relative_abundance(ps)

# Taxonomic composition
phylum_results <- analyze_phylum_level(ps_rel, "SampleType")
family_results <- analyze_family_level(ps_rel, "SampleType", top_n = 15)
genus_comp <- analyze_genus_level_composition(ps_rel, "SampleType", top_n = 15)
genus_stats <- analyze_genus_level_statistics(ps_rel, "SampleType", 
                                              "Gut", "Derm", top_n = 25)

# Diversity analyses
alpha_results <- analyze_alpha_diversity(ps, "SampleType", "Gut", "Derm")
beta_results <- analyze_beta_diversity(ps, "SampleType", "Gut", "Derm")

# Differential abundance
ps_deseq <- preprocess_for_deseq2(ps, "Genus", min_reads = 10)
deseq_results <- perform_deseq2_analysis(ps_deseq, "SampleType", "Derm", "Gut")
deseq_plots <- visualize_deseq2_results(deseq_results, 0.05, 1, "Gut", "Derm")
```

## Analysis Sections

### Section 3.1: Raw Data Quality Assessment and QIIME2 Pipeline

**Purpose**: Assess raw sequence quality and process through QIIME2 pipeline

**Key Steps**:
- **FastQC Analysis**: Evaluates per-base quality scores, GC content, adapter contamination
- **DADA2 Processing**: 
  - Trims first 15 bp from 5' end (removes low-quality bases and primers)
  - Truncates at 240 bp (maintains quality while preserving length)
  - Denoises, dereplicates, and removes chimeras
  - Generates Amplicon Sequence Variants (ASVs)
- **Taxonomic Classification**: Uses SILVA-138-99 database
- **Phylogenetic Tree**: Constructs rooted phylogenetic tree

**What it does**: Converts raw sequencing reads into a clean dataset of ASVs with taxonomic classifications and phylogenetic relationships.

### Section 3.2: Data Quality Assessment and Preprocessing

**Purpose**: Clean and filter the phyloseq object

**Key Steps**:
1. **Initial Assessment**: Examine library sizes, taxonomic composition
2. **Bacterial Filtering**: Keep only Kingdom "d__Bacteria"
3. **Contaminant Removal**: Remove mitochondrial and chloroplast sequences
4. **Prevalence Filtering**: Remove ASVs present in <2 samples

**What it does**: Removes non-bacterial and contaminating sequences, filters out rare ASVs that may be sequencing artifacts.

**Why it matters**: Ensures downstream analysis focuses on true bacterial community members.

### Section 3.3: Relative Abundance Transformation

**Purpose**: Normalize for sequencing depth differences

**Method**: Divides each ASV count by total sample reads × 100

**What it does**: Converts absolute counts to percentages, enabling fair comparisons between samples with different read depths.

### Section 3.4: Taxonomic Composition Analysis

**Purpose**: Describe community composition at multiple taxonomic levels

**Analyses**:
1. **Phylum Level**: All phyla, stacked bar plots by group
2. **Family Level**: Top 15 families, stacked bar plots
3. **Genus Level**: 
   - Composition: Top 15 genera, stacked bar plots
   - Statistics: Top 25 genera, statistical testing

**Statistical Methods**:
- **Wilcoxon rank-sum test**: Non-parametric test for group differences
- **Cliff's Delta effect size**: Quantifies magnitude of differences
  - |δ| < 0.147: negligible
  - 0.147 ≤ |δ| < 0.33: small
  - 0.33 ≤ |δ| < 0.474: medium
  - |δ| ≥ 0.474: large
- **Benjamini-Hochberg FDR correction**: Controls false discovery rate

**What it does**: Identifies which taxa are present and whether their abundances differ significantly between groups.

### Section 3.5: Alpha Diversity Analysis

**Purpose**: Measure within-sample microbial diversity

**Indices Calculated**:
1. **Observed**: Direct ASV count
2. **Chao1**: Estimates total richness (including unobserved species)
3. **Shannon**: Accounts for richness and evenness
4. **Simpson**: Measures dominance/evenness
5. **Inverse Simpson**: Reciprocal of Simpson index
6. **Faith's PD**: Phylogenetic diversity (sum of branch lengths)

**Statistical Test**: Wilcoxon rank-sum test comparing groups

**What it does**: Determines if one sample group has higher diversity than another.

**Interpretation**: Higher values generally indicate more diverse communities, though interpretation depends on the specific index.

### Section 3.6: Beta Diversity Analysis

**Purpose**: Measure between-sample community differences

**Methods**:
- **Bray-Curtis Dissimilarity**: Quantifies compositional differences
- **PCoA**: Principal Coordinates Analysis for visualization
- **PERMANOVA**: Tests if groups have significantly different compositions
  - 999 permutations
  - Reports R² (effect size) and p-value

**What it does**: Determines if gut and dermal communities are compositionally distinct.

**Interpretation**: 
- Samples that cluster together have similar communities
- Significant PERMANOVA indicates groups differ in composition
- R² indicates proportion of variance explained by group

### Section 3.7: Differential Abundance Analysis

**Purpose**: Identify specific genera that differ in abundance between groups

**Method**: DESeq2 negative binomial generalized linear model
- Originally developed for RNA-seq, validated for microbiome data
- Accounts for compositional nature and overdispersion
- Uses empirical Bayes shrinkage estimators
- Wald test for significance
- Benjamini-Hochberg FDR correction

**Preprocessing**:
- Agglomerate at genus level
- Filter genera with <10 total reads

**Interpretation**:
- **log2 Fold Change (log2FC)**: 
  - Positive: higher in comparison group (Gut)
  - Negative: higher in reference group (Derm)
  - |log2FC| ≥ 1: at least 2-fold change (biologically significant)
- **Adjusted p-value (padj)**: FDR-corrected significance
  - padj < 0.05: statistically significant

**What it does**: Identifies which specific genera are significantly enriched in gut vs. dermal samples.

## Output

The pipeline generates:

### Data Objects
- `phyloseq_raw`: Filtered phyloseq object with counts
- `phyloseq_rel`: Relative abundance phyloseq object
- Multiple result lists containing statistics and plots

### Visualizations
1. **Taxonomic Composition**: Stacked bar plots (phylum, family, genus)
2. **Genus Statistics**: Box plots with p-values
3. **Alpha Diversity**: Violin plots with box plots for 6 indices
4. **Beta Diversity**: PCoA plot with confidence ellipses and PERMANOVA results
5. **Differential Abundance**: 
   - Volcano plot (log2FC vs. significance)
   - Horizontal bar plot of significant genera

### Statistical Tables
- Taxonomic summaries (mean, median, SD, min, max)
- Alpha diversity statistics
- PERMANOVA results
- DESeq2 differential abundance results

## Interpretation Guide

### Reading Statistical Outputs

#### Significance Levels
- `***`: p < 0.001 (highly significant)
- `**`: p < 0.01 (very significant)
- `*`: p < 0.05 (significant)
- `NS`: not significant (p ≥ 0.05)

#### Effect Sizes

**Cliff's Delta (δ)**:
- Measures probability that a random value from group 1 exceeds a random value from group 2
- Range: -1 to +1
- Positive: group 1 > group 2
- Negative: group 1 < group 2

**DESeq2 log2 Fold Change**:
- log2FC = 1: 2-fold increase
- log2FC = 2: 4-fold increase
- log2FC = -1: 2-fold decrease
- |log2FC| ≥ 1 generally considered biologically meaningful

### Common Questions

**Q: What does a significant PERMANOVA result mean?**
A: The overall community composition differs significantly between groups. This doesn't tell you which specific taxa differ.

**Q: When should I use alpha vs. beta diversity?**
A: Alpha diversity measures diversity within samples (how diverse is each sample?). Beta diversity measures differences between samples (how different are the communities?).

**Q: Why use both Wilcoxon tests and DESeq2?**
A: Wilcoxon tests work on relative abundances and are simple to interpret. DESeq2 works on counts, better handles compositionality and overdispersion, and is more powerful for detecting differential abundance.

**Q: What if no taxa are significant in DESeq2?**
A: This could mean: (1) groups truly don't differ at genus level, (2) sample size is too small, (3) variability is too high, or (4) differences exist at other taxonomic levels.

## Troubleshooting

### Common Issues

**Error: Cannot find QIIME2 artifacts**
- Ensure .qza files exist and paths are correct
- Check that QIIME2 processing completed successfully

**Error: Package not found**
- Install missing packages (see Requirements)
- Check Bioconductor packages are installed via BiocManager

**Warning: DESeq2 size factor estimation issues**
- Common with sparse microbiome data
- Pipeline uses geometric means approach to handle zeros
- If persistent, try increasing min_reads filter threshold

**Error: Phylogenetic tree missing**
- Faith's PD requires phylogenetic tree
- Ensure rooted-tree.qza was generated in QIIME2
- Check tree imported correctly

### Memory Issues

For large datasets:
```r
# Increase memory limit (Windows)
memory.limit(size = 16000)

# Process fewer samples at a time
# Or filter more stringently (higher min_reads, higher min_samples)
```

## Citation

If you use this pipeline, please cite:

**QIIME2**: Bolyen et al. (2019) Nature Biotechnology
**phyloseq**: McMurdie & Holmes (2013) PLoS ONE
**DESeq2**: Love et al. (2014) Genome Biology
**vegan**: Oksanen et al. (2022)
**Other tools**: See references in methods section

## License

This pipeline is provided as-is for research and educational purposes.

## Contact

For questions or issues with this pipeline, please open an issue in the repository.

---

## Appendix: Metadata File Format

The `metadata.tsv` file should be tab-separated with:
- First column: Sample IDs (matching those in QIIME2 data)
- Additional columns: Sample variables (e.g., SampleType, Subject, TimePoint)

Example:
```
SampleID	SampleType	Subject	Site
Sample1	Gut	Fish1	Intestine
Sample2	Gut	Fish2	Intestine
Sample3	Derm	Fish1	Skin
Sample4	Derm	Fish2	Skin
```

## Appendix: Expected Runtime

On a typical workstation:
- FastQC: ~5-10 minutes (11 samples)
- QIIME2 processing: ~1-2 hours
- R analysis: ~5-15 minutes

Runtime varies with:
- Number of samples
- Sequencing depth
- Number of ASVs
- Computer specifications
