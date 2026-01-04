# Pipeline Structure and Function Reference

## File Organization

```
colaborate/
│
├── 🔬 CORE PIPELINE
│   └── 16S_microbiome_analysis_pipeline.R (45KB, 1,400+ lines)
│       • 21 functions implementing complete methodology
│       • Sections 3.1 through 3.8 fully implemented
│
├── 💻 USAGE & EXAMPLES  
│   ├── example_usage.R (9.4KB)
│   │   • Complete working examples
│   │   • Both automated and step-by-step approaches
│   │
│   ├── example_metadata.tsv (708B)
│   │   • Sample metadata format (11 samples)
│   │
│   └── validate_syntax.R (2.7KB)
│       • Validates R code syntax
│
└── 📚 DOCUMENTATION (60KB total)
    ├── README.md (1.8KB)
    │   • Repository overview
    │   • Quick start guide
    │
    ├── README_MICROBIOME_PIPELINE.md (15KB)
    │   • Comprehensive user guide
    │   • Installation, usage, interpretation
    │
    ├── METHODOLOGY_EXPLAINED.md (15KB)
    │   • Detailed method explanations
    │   • Statistical reasoning
    │
    ├── QUICK_REFERENCE.md (9.1KB)
    │   • Common tasks and solutions
    │   • Function reference table
    │
    └── COMPLETE_SUMMARY.md (16KB)
        • Overview of entire pipeline
        • Learning path and use cases
```

---

## Function Hierarchy

### 📊 SECTION 3.1: Quality Control & QIIME2 Processing

```
run_fastqc_quality_control()
├── Purpose: FastQC quality assessment of raw reads
├── Input: Directory of FASTQ files
└── Output: FastQC HTML reports

qiime2_processing_pipeline()
├── Purpose: Complete QIIME2 workflow (DADA2, taxonomy, phylogeny)
├── Steps: Import → DADA2 → Classify → Build tree
└── Output: 4 .qza artifacts (table, sequences, taxonomy, tree)

import_qiime2_to_phyloseq()
├── Purpose: Import QIIME2 artifacts into R phyloseq object
├── Input: 4 .qza files + metadata.tsv
└── Output: phyloseq object (integrated data structure)
```

### 🧹 SECTION 3.2: Data Preprocessing

```
assess_phyloseq_quality()
├── Purpose: Initial quality assessment
├── Analyzes: Library sizes, kingdom composition, families
└── Output: Statistics and visualization

filter_bacteria_only()
├── Purpose: Keep only bacterial sequences
├── Filters: Kingdom == "d__Bacteria"
└── Removes: Archaea, Eukaryotes, Unclassified

remove_organellar_sequences()
├── Purpose: Remove host contamination
├── Filters: Family != "Mitochondria" & != "Chloroplast"
└── Preserves: Taxa with NA at Family level

prevalence_based_filtering()
├── Purpose: Remove rare, potentially artifactual ASVs
├── Threshold: Present in ≥ 2 samples (default)
└── Rationale: Removes sequencing errors and contamination
```

### 🔄 SECTION 3.3: Normalization

```
transform_to_relative_abundance()
├── Purpose: Normalize for sequencing depth
├── Method: (ASV count / total reads) × 100
└── Output: phyloseq object with relative abundances (%)
```

### 🏷️ SECTION 3.4: Taxonomic Composition

```
agglomerate_taxa()
├── Purpose: Combine ASVs at specified taxonomic rank
├── Input: phyloseq object, rank name
└── Output: phyloseq object with taxa combined

analyze_phylum_level()
├── Purpose: Phylum-level composition analysis
├── Includes: ALL phyla detected
├── Visualization: Stacked bar plots by group
└── Statistics: Summary table (mean, SD per group)

analyze_family_level()
├── Purpose: Family-level composition analysis
├── Includes: Top 15 families (by total abundance)
├── Visualization: Stacked bar plots by group
└── Statistics: Summary table with descriptives

analyze_genus_level_composition()
├── Purpose: Genus-level composition visualization
├── Includes: Top 15 genera
├── Visualization: Stacked bar plots by group
└── Use: Overall community structure

analyze_genus_level_statistics()
├── Purpose: Statistical comparison of genera between groups
├── Includes: Top 25 genera
├── Tests: Wilcoxon rank-sum (non-parametric)
├── Effect size: Cliff's Delta with magnitude
│   • |δ| < 0.147: negligible
│   • 0.147 ≤ |δ| < 0.33: small
│   • 0.33 ≤ |δ| < 0.474: medium
│   • |δ| ≥ 0.474: large
├── Correction: Benjamini-Hochberg FDR
└── Visualization: Box plots with p-values

calculate_taxonomic_summaries()
├── Purpose: Descriptive statistics for taxonomic groups
├── Statistics: n, mean, median, SD, min, max
└── Output: Summary table by group and taxon
```

### 📈 SECTION 3.5: Alpha Diversity

```
analyze_alpha_diversity()
├── Purpose: Within-sample diversity analysis
├── Indices:
│   1. Observed ASVs (richness)
│   2. Chao1 (estimated richness)
│   3. Shannon (richness + evenness)
│   4. Simpson (dominance)
│   5. Inverse Simpson (effective diversity)
│   6. Faith's Phylogenetic Diversity (evolutionary diversity)
├── Statistical test: Wilcoxon rank-sum
├── Visualization: Violin plots + box plots + points
└── Output: Diversity table + statistics + plots
```

### 🌐 SECTION 3.6: Beta Diversity

```
analyze_beta_diversity()
├── Purpose: Between-sample community differences
├── Dissimilarity: Bray-Curtis
├── Ordination: Principal Coordinates Analysis (PCoA)
├── Statistical test: PERMANOVA (999 permutations)
│   • Tests: Are group centroids different?
│   • Reports: R² (effect size), p-value
├── Visualization: PCoA with 95% confidence ellipses
└── Output: Ordination object + PERMANOVA + plot
```

### 🔬 SECTION 3.7: Differential Abundance

```
preprocess_for_deseq2()
├── Purpose: Prepare data for DESeq2
├── Steps:
│   1. Agglomerate at genus level
│   2. Filter low-abundance taxa (< 10 total reads)
└── Output: Filtered phyloseq object

perform_deseq2_analysis()
├── Purpose: Identify differentially abundant genera
├── Model: Negative binomial GLM
├── Features:
│   • Handles overdispersion
│   • Compositional adjustment
│   • Empirical Bayes shrinkage
├── Test: Wald test
├── Correction: Benjamini-Hochberg FDR
├── Significance: FDR < 0.05
└── Output: Results table with log2FC, p-values, taxonomy

visualize_deseq2_results()
├── Purpose: Visualize differential abundance results
├── Plots:
│   1. Volcano plot (log2FC vs -log10(padj))
│   2. Horizontal bar plot (significant genera)
├── Interpretation:
│   • log2FC > 0: higher in comparison group
│   • log2FC < 0: higher in reference group
│   • |log2FC| ≥ 1: at least 2-fold change
└── Output: 2 publication-quality plots
```

### 📝 SECTION 3.8: Documentation

```
document_computational_environment()
├── Purpose: Record software versions for reproducibility
├── Records:
│   • R version
│   • Package versions
│   • Session info
└── Output: Printed summary + session info object
```

### 🚀 COMPLETE WORKFLOW

```
run_complete_microbiome_analysis()
├── Purpose: Execute entire pipeline with one function call
├── Runs sequentially:
│   1. Import QIIME2 data
│   2. Quality assessment
│   3. Preprocessing (bacteria, no contaminants, prevalence filter)
│   4. Relative abundance transformation
│   5. Taxonomic composition (phylum, family, genus)
│   6. Genus statistics (top 25, Wilcoxon + Cliff's Delta)
│   7. Alpha diversity (6 indices)
│   8. Beta diversity (PCoA + PERMANOVA)
│   9. DESeq2 differential abundance
│   10. Result visualization
│   11. Environment documentation
├── Parameters:
│   • qiime_dir: Path to QIIME2 output
│   • metadata_file: Sample metadata
│   • output_dir: Results directory
│   • group_var: Grouping variable name
│   • group1, group2: Group names to compare
└── Output: List containing all results
```

---

## Data Flow Diagram

```
QIIME2 Artifacts (.qza)
    ↓
┌─────────────────────────────────────────┐
│ import_qiime2_to_phyloseq()             │
│ Creates integrated phyloseq object      │
└─────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────┐
│ Quality Assessment & Preprocessing      │
│ • assess_phyloseq_quality()             │
│ • filter_bacteria_only()                │
│ • remove_organellar_sequences()         │
│ • prevalence_based_filtering()          │
└─────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────┐
│ transform_to_relative_abundance()       │
│ Normalize for sequencing depth          │
└─────────────────────────────────────────┘
    ↓
    ├─────────────────────────────────────┐
    │                                     │
    ↓                                     ↓
┌──────────────────┐              ┌──────────────────┐
│ Count Data (ps)  │              │ Relative (ps_rel)│
│ For DESeq2       │              │ For composition  │
└──────────────────┘              └──────────────────┘
    ↓                                     ↓
    │                      ┌──────────────┴──────────────┐
    │                      ↓                             ↓
    │              ┌──────────────┐            ┌──────────────┐
    │              │ Taxonomic    │            │ Diversity    │
    │              │ Composition  │            │ Analyses     │
    │              └──────────────┘            └──────────────┘
    │                      ↓                             ↓
    │              • analyze_phylum_level()      • analyze_alpha_diversity()
    │              • analyze_family_level()      • analyze_beta_diversity()
    │              • analyze_genus_level_*()
    │              • calculate_taxonomic_summaries()
    ↓
┌─────────────────────────────────────────┐
│ Differential Abundance                  │
│ • preprocess_for_deseq2()               │
│ • perform_deseq2_analysis()             │
│ • visualize_deseq2_results()            │
└─────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────┐
│ Results                                 │
│ • Statistical tables                    │
│ • Publication-quality plots             │
│ • Documented environment                │
└─────────────────────────────────────────┘
```

---

## Statistical Methods Summary

| Analysis | Test/Method | Purpose | Output |
|----------|-------------|---------|--------|
| Taxonomic Comparison | Wilcoxon rank-sum | Non-parametric group comparison | p-value |
| Effect Size | Cliff's Delta | Magnitude of difference | δ (-1 to 1) |
| Alpha Diversity | Wilcoxon rank-sum | Compare diversity indices | p-value |
| Beta Diversity | PERMANOVA | Test community differences | R², p-value |
| Differential Abundance | DESeq2 | Identify differential taxa | log2FC, FDR |
| Multiple Testing | Benjamini-Hochberg | Control false discovery rate | Adjusted p |

---

## Output Summary

### Tables Generated
1. Taxonomic composition summaries (phylum, family, genus)
2. Genus statistical comparison results
3. Alpha diversity values per sample
4. Alpha diversity group comparisons
5. PERMANOVA results
6. DESeq2 differential abundance results

### Plots Generated (~15-20 total)
1. Library size bar chart
2. Phylum stacked bar plot
3. Family stacked bar plot
4. Genus stacked bar plot
5. Genus statistical box plots (up to 12)
6. Alpha diversity violin plots (6 indices)
7. Beta diversity PCoA plot
8. DESeq2 volcano plot
9. DESeq2 bar plot of significant taxa

### File Exports
- High-resolution PNG (300-600 DPI)
- PDF (vector graphics)
- CSV tables
- R workspace (.RData)

---

## Dependencies

### External Software
- FastQC v0.12.0
- QIIME2 v2024.10
- SILVA-138-99-nb-classifier

### R Packages (11 total)
**Core:**
- phyloseq (1.52.0) - Microbiome data management
- ggplot2 (3.5.2) - Visualization
- dplyr (1.1.4) - Data manipulation

**Statistical:**
- DESeq2 (1.42.0) - Differential abundance
- vegan (2.7-4) - Community ecology
- effsize (0.8.1) - Effect sizes

**Additional:**
- ggpubr (0.6.1) - Statistical plotting
- tidyr (1.3.0) - Data reshaping
- scales (1.2.1) - Plot formatting
- qiime2R (0.99.6) - QIIME2 import
- picante - Phylogenetic diversity

---

## Code Metrics

- **Total lines**: ~1,400
- **Functions**: 21
- **Comments**: Extensive (every function, most code blocks)
- **Documentation**: 60KB across 4 files
- **Examples**: Complete working examples included
- **Validation**: Syntax checker included

---

## Quality Assurance

✅ **All methodology sections implemented**  
✅ **Statistical methods appropriate for data type**  
✅ **Effect sizes calculated (not just p-values)**  
✅ **Multiple testing correction applied**  
✅ **Publication-quality visualizations**  
✅ **Reproducibility ensured (version documentation)**  
✅ **Comprehensive documentation**  
✅ **Working examples provided**  
✅ **Syntax validation available**  
✅ **Modular, maintainable code**  

---

## Learning Path

**Beginner** → README.md  
**User** → README_MICROBIOME_PIPELINE.md + example_usage.R  
**Understanding** → METHODOLOGY_EXPLAINED.md  
**Reference** → QUICK_REFERENCE.md  
**Overview** → COMPLETE_SUMMARY.md  
**Code** → 16S_microbiome_analysis_pipeline.R  

---

*This pipeline represents a complete, production-ready implementation of best-practice 16S microbiome analysis methods.*
