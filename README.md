# Colaborate

This is a demo repo to collaborate (study purpose)

## 16S rRNA Microbiome Analysis Pipeline

This repository contains a comprehensive R pipeline for analyzing 16S rRNA gene sequencing data from gut and dermal microbiome communities.

### Key Features

- **Quality Control**: FastQC assessment and QIIME2 processing with DADA2
- **Data Preprocessing**: Taxonomic filtering, contaminant removal, prevalence filtering
- **Taxonomic Analysis**: Composition analysis at phylum, family, and genus levels
- **Diversity Analysis**: Alpha diversity (6 indices) and beta diversity (PCoA, PERMANOVA)
- **Statistical Testing**: Non-parametric tests with effect size calculations
- **Differential Abundance**: DESeq2 analysis for comparing groups

### Files

- **`16S_microbiome_analysis_pipeline.R`**: Complete analysis pipeline with all functions
- **`README_MICROBIOME_PIPELINE.md`**: Comprehensive documentation and user guide
- **`example_usage.R`**: Example script showing how to run the pipeline
- **`example_metadata.tsv`**: Sample metadata file format

### Quick Start

```r
# Load the pipeline
source("16S_microbiome_analysis_pipeline.R")

# Run complete analysis
results <- run_complete_microbiome_analysis(
  qiime_dir = "path/to/qiime2/output",
  metadata_file = "example_metadata.tsv",
  output_dir = "results",
  group_var = "SampleType",
  group1 = "Gut",
  group2 = "Derm"
)
```

### Documentation

See **`README_MICROBIOME_PIPELINE.md`** for:
- Detailed installation instructions
- Complete pipeline overview
- Step-by-step usage guide
- Interpretation guidelines
- Troubleshooting tips

### Requirements

- R ≥ 4.5.0
- QIIME2 v2024.10
- FastQC v0.12.0
- Required R packages: phyloseq, ggplot2, dplyr, DESeq2, vegan, and more (see documentation)
