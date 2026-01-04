# Quick Reference Guide

## Common Tasks and Solutions

### Installation

```r
# Install all packages at once
install.packages(c("dplyr", "ggplot2", "tidyr", "scales", "ggpubr", 
                   "vegan", "effsize"))

if (!require("BiocManager")) install.packages("BiocManager")
BiocManager::install(c("phyloseq", "DESeq2", "picante"))

if (!require("devtools")) install.packages("devtools")
devtools::install_github("jbisanz/qiime2R")
```

### Basic Usage

```r
# Load pipeline
source("16S_microbiome_analysis_pipeline.R")

# Run everything
results <- run_complete_microbiome_analysis(
  qiime_dir = "qiime2_output",
  metadata_file = "metadata.tsv",
  output_dir = "results",
  group_var = "SampleType",
  group1 = "Gut",
  group2 = "Derm"
)
```

### Accessing Results

```r
# View significant genera
sig <- results$deseq2_results$results %>%
  filter(padj < 0.05) %>%
  arrange(padj)
print(sig[, c("Genus", "log2FoldChange", "padj")])

# Alpha diversity stats
print(results$alpha_diversity$statistics)

# Beta diversity PERMANOVA
print(results$beta_diversity$permanova)

# Top abundant phyla
print(head(results$phylum_results$summary))
```

### Exporting Results

```r
# Save plots
ggsave("phylum_plot.png", results$phylum_results$plot, 
       width = 12, height = 8, dpi = 300)

# Save tables
write.csv(results$deseq2_results$results, "deseq2_results.csv")
write.csv(results$alpha_diversity$diversity_data, "alpha_diversity.csv")

# Save workspace
save.image("analysis_workspace.RData")
```

### Custom Analyses

```r
# Analyze only top 10 genera
genus_top10 <- analyze_genus_level_composition(ps_rel, "SampleType", top_n = 10)

# Different alpha diversity groups
alpha_custom <- analyze_alpha_diversity(ps, "Treatment", "Control", "Treatment")

# Subset by condition
ps_subset <- subset_samples(ps, Condition == "Healthy")

# Filter by prevalence threshold
ps_stringent <- prevalence_based_filtering(ps, min_samples = 3)
```

### Troubleshooting

**Package not found**
```r
# Check what's installed
installed.packages()[, "Version"]["phyloseq"]

# Reinstall
BiocManager::install("phyloseq", force = TRUE)
```

**Memory issues**
```r
# Increase memory (Windows)
memory.limit(16000)

# Filter more stringently
ps <- filter_taxa(ps, function(x) sum(x) >= 100, TRUE)
```

**DESeq2 errors**
```r
# More stringent filtering
ps_deseq <- preprocess_for_deseq2(ps, "Genus", min_reads = 50)

# Check sample sizes
table(sample_data(ps)$SampleType)
```

**No significant results**
```r
# Try less stringent thresholds
sig_relaxed <- deseq_results$results %>% filter(padj < 0.1)

# Check at different taxonomic levels
family_results <- analyze_family_level(ps_rel, "SampleType")

# Examine effect sizes even if not significant
all_results <- deseq_results$results %>% arrange(desc(abs(log2FoldChange)))
```

### Modifying Parameters

```r
# Change significance threshold
deseq_plots <- visualize_deseq2_results(
  deseq_results, 
  fdr_threshold = 0.1,  # More lenient
  fc_threshold = 0.5    # Lower fold-change
)

# Analyze more genera
genus_stats <- analyze_genus_level_statistics(
  ps_rel, "SampleType", "Gut", "Derm", 
  top_n = 50  # Increased from 25
)

# Different diversity metrics only
alpha_subset <- estimate_richness(ps, measures = c("Shannon", "Simpson"))
```

### Quality Checks

```r
# Check library sizes
sample_sums(ps)
hist(sample_sums(ps))

# Check rarefaction curves
rarecurve(t(otu_table(ps)), step = 1000)

# Examine taxonomic composition
table(tax_table(ps)[, "Phylum"])

# Count ASVs per sample
apply(otu_table(ps) > 0, 2, sum)
```

### Visualization Customization

```r
# Modify colors
p <- results$phylum_results$plot +
  scale_fill_brewer(palette = "Set3")

# Change theme
p <- p + theme_classic(base_size = 14)

# Adjust labels
p <- p + labs(title = "Custom Title", x = "My X Label")

# Remove legend
p <- p + theme(legend.position = "none")

# Save high-resolution
ggsave("figure.pdf", p, width = 10, height = 8)
ggsave("figure.png", p, width = 10, height = 8, dpi = 600)
```

### Working with Subsets

```r
# Select specific samples
ps_gut <- subset_samples(ps, SampleType == "Gut")
ps_timepoint1 <- subset_samples(ps, Timepoint == 1)

# Select specific taxa
ps_firmicutes <- subset_taxa(ps, Phylum == "Firmicutes")

# Remove specific samples
ps_filtered <- subset_samples(ps, !(SampleID %in% c("Bad1", "Bad2")))

# Merge samples by group
ps_merged <- merge_samples(ps, "SampleType")
```

### Batch Processing Multiple Comparisons

```r
# Compare multiple groups
groups <- c("Gut", "Derm", "Oral")
results_list <- list()

for (i in 1:(length(groups)-1)) {
  for (j in (i+1):length(groups)) {
    comparison_name <- paste(groups[i], "vs", groups[j])
    results_list[[comparison_name]] <- perform_deseq2_analysis(
      ps, "SampleType", groups[j], groups[i]
    )
  }
}
```

### Statistical Power Considerations

```r
# Check sample sizes
table(sample_data(ps)$SampleType)

# Estimate minimum detectable fold-change
# Rule of thumb: need 5+ samples per group for reliable results
# With 5 samples, can detect ~2-fold changes
# With 10 samples, can detect ~1.5-fold changes

# Filter to reduce multiple testing burden
ps_abundant <- filter_taxa(ps, function(x) sum(x) >= 100, TRUE)
```

### Reproducibility

```r
# Set random seed for permutation tests
set.seed(12345)

# Document session
sessionInfo()
sink("session_info.txt")
sessionInfo()
sink()

# Save all parameters
analysis_params <- list(
  date = Sys.Date(),
  r_version = R.version.string,
  min_samples = 2,
  min_reads = 10,
  fdr_threshold = 0.05,
  fc_threshold = 1
)
saveRDS(analysis_params, "analysis_parameters.rds")
```

### Integration with Other Tools

```r
# Export for Cytoscape network analysis
write.table(otu_table(ps), "otu_table.txt", sep = "\t")
write.table(tax_table(ps), "taxonomy.txt", sep = "\t")

# Export for LEfSe analysis
# (Need to format as required by LEfSe)

# Import additional metadata
new_metadata <- read.table("new_metadata.txt", header = TRUE)
sample_data(ps) <- merge(sample_data(ps), new_metadata, by = "SampleID")
```

### Performance Optimization

```r
# Parallel processing for ordination
library(parallel)
cl <- makeCluster(detectCores() - 1)
# Use with vegan functions that support parallel

# Reduce data size before intensive analyses
ps_subset <- filter_taxa(ps, function(x) sum(x > 0) > 2, TRUE)

# Use more efficient distance calculations
dist_fast <- phyloseq::distance(ps, method = "bray", parallel = TRUE)
```

### Common Error Messages

**"Error in FUN(X[[i]], ...) : object not found"**
- Check that phyloseq object exists: `exists("ps")`
- Verify column names: `colnames(sample_data(ps))`

**"Error in validObject(.Object) : invalid class"**
- Phyloseq object corrupted
- Reimport data or reload workspace

**"Error: cannot allocate vector of size"**
- Memory issue
- Close other programs
- Filter data more stringently
- Use smaller subset for testing

**"All counts are zero"**
- Check that taxa weren't over-filtered
- Verify sample subsetting didn't remove all data
- Confirm proper phyloseq orientation

### Quick Data Checks

```r
# Basic phyloseq info
ps
ntaxa(ps)
nsamples(ps)
sample_variables(ps)
rank_names(ps)

# Check for zeros
sum(otu_table(ps) == 0) / length(otu_table(ps))  # Proportion zeros

# Verify metadata
head(sample_data(ps))
table(sample_data(ps)$SampleType)

# Check taxonomy completeness
apply(tax_table(ps), 2, function(x) sum(is.na(x)))
```

---

## Function Quick Reference

| Task | Function | Key Parameters |
|------|----------|----------------|
| Import QIIME2 | `import_qiime2_to_phyloseq()` | artifacts, metadata |
| Filter bacteria | `filter_bacteria_only()` | ps |
| Remove contaminants | `remove_organellar_sequences()` | ps |
| Prevalence filter | `prevalence_based_filtering()` | ps, min_samples |
| Relative abundance | `transform_to_relative_abundance()` | ps |
| Phylum analysis | `analyze_phylum_level()` | ps_rel, group_var |
| Genus statistics | `analyze_genus_level_statistics()` | ps_rel, groups, top_n |
| Alpha diversity | `analyze_alpha_diversity()` | ps, group_var, groups |
| Beta diversity | `analyze_beta_diversity()` | ps, group_var, groups |
| DESeq2 | `perform_deseq2_analysis()` | ps, group_var, groups |
| Visualize DESeq2 | `visualize_deseq2_results()` | results, thresholds |
| Complete pipeline | `run_complete_microbiome_analysis()` | dirs, groups |

---

## File Formats

**metadata.tsv**
```
SampleID    SampleType    Subject
Sample1     Gut          Fish1
Sample2     Derm         Fish2
```

**QIIME2 artifacts needed**
- table.qza (feature table)
- rep-seqs.qza (representative sequences)
- taxonomy.qza (taxonomic classifications)
- rooted-tree.qza (phylogenetic tree)

---

## Getting Help

1. Check error message carefully
2. Review README_MICROBIOME_PIPELINE.md
3. Read METHODOLOGY_EXPLAINED.md for concepts
4. Check function documentation: `?function_name`
5. Examine example_usage.R
6. Validate syntax: `Rscript validate_syntax.R`

---

## Tips

- Start with small dataset to test workflow
- Save frequently: `save.image("checkpoint.RData")`
- Keep raw data separate from processed data
- Document all parameter choices
- Validate key results with multiple methods
- Check assumptions before interpreting statistics
- Consider biological significance, not just statistical
