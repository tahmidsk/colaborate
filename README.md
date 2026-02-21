# collaborate

## 16S rRNA Microbiome Analysis Pipeline (Gut vs Derm)

## Overview

This repository contains a complete R analysis pipeline for 16S rRNA gene
sequencing data, implementing all steps described in Chapter 3 (Materials and
Methods). The pipeline processes QIIME2 output through phyloseq and produces
publication-ready figures and statistical results.

## Prerequisites

### R Packages

Install the required packages before running the pipeline:

```r
# CRAN packages
install.packages(c("ggplot2", "dplyr", "tidyr", "scales",
                   "ggpubr", "effsize", "gridExtra", "vegan"))

# Bioconductor packages
if (!requireNamespace("BiocManager", quietly = TRUE))
  install.packages("BiocManager")
BiocManager::install(c("phyloseq", "DESeq2"))

# Additional packages
install.packages("picante")
# qiime2R (from GitHub)
# install.packages("remotes")
# remotes::install_github("jbisanz/qiime2R")
```

### Input Files

Place the following QIIME2 output files in a `qiime2_output/` directory and a
sample metadata file in the project root:

| File | Description |
|------|-------------|
| `qiime2_output/feature-table.qza` | ASV feature table |
| `qiime2_output/rooted-tree.qza` | Rooted phylogenetic tree |
| `qiime2_output/taxonomy.qza` | Taxonomy classifications (SILVA 138) |
| `metadata.tsv` | Sample metadata with a `Group` column (`Gut` / `Derm`) |

## Pipeline Scripts

Run the scripts **in order**. Each script reads the output of the previous one.

| Script | Section | Description |
|--------|---------|-------------|
| `01_data_import.R` | 3.1.3 | Import QIIME2 artifacts → phyloseq object |
| `02_data_preprocessing.R` | 3.2 | Quality assessment, taxonomic/prevalence filtering |
| `03_relative_abundance.R` | 3.3 | Transform counts to relative abundances (%) |
| `04_taxonomic_composition.R` | 3.4 | Phylum/Family/Genus composition & statistics |
| `05_alpha_diversity.R` | 3.5 | Alpha diversity (6 indices) & Wilcoxon tests |
| `06_beta_diversity.R` | 3.6 | PCoA, Bray-Curtis, PERMANOVA |
| `07_differential_abundance.R` | 3.7 | DESeq2 differential abundance analysis |

### Quick Start

```bash
Rscript 01_data_import.R
Rscript 02_data_preprocessing.R
Rscript 03_relative_abundance.R
Rscript 04_taxonomic_composition.R
Rscript 05_alpha_diversity.R
Rscript 06_beta_diversity.R
Rscript 07_differential_abundance.R
```

## Outputs

All results are written to the `results/` directory:

- `results/phyloseq_raw.rds` — raw phyloseq object
- `results/phyloseq_filtered.rds` — filtered phyloseq object
- `results/phyloseq_relabund.rds` — relative abundance phyloseq
- `results/alpha_diversity.csv` — alpha diversity values per sample
- `results/genus_statistical_comparisons.csv` — Wilcoxon + Cliff's Delta
- `results/genus_summary_statistics.csv` — descriptive statistics
- `results/deseq2_results.csv` — DESeq2 results table
- `results/figures/` — all plots in PNG (300–600 DPI) and PDF formats
