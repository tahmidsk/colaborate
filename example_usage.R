################################################################################
# Example Script: Running the 16S Microbiome Analysis Pipeline
# 
# This script demonstrates how to use the 16S microbiome analysis pipeline
# Follow the steps below to analyze your data
################################################################################

# =============================================================================
# STEP 1: Install Required Packages (run once)
# =============================================================================

# Uncomment and run if packages not yet installed:

# install.packages(c("dplyr", "ggplot2", "tidyr", "scales", "ggpubr", 
#                    "vegan", "effsize"))
# 
# if (!require("BiocManager", quietly = TRUE))
#     install.packages("BiocManager")
# 
# BiocManager::install(c("phyloseq", "DESeq2", "picante"))
# 
# if (!require("devtools")) install.packages("devtools")
# devtools::install_github("jbisanz/qiime2R")

# =============================================================================
# STEP 2: Load the Pipeline
# =============================================================================

# Set working directory to where the pipeline script is located
# setwd("/path/to/pipeline/directory")

# Load the pipeline functions
source("16S_microbiome_analysis_pipeline.R")

# =============================================================================
# STEP 3: Verify Required Packages
# =============================================================================

cat("\nChecking required packages...\n")
required_packages <- c("phyloseq", "ggplot2", "dplyr", "ggpubr", "tidyr", 
                      "scales", "qiime2R", "DESeq2", "vegan", "picante", 
                      "effsize")

missing_packages <- c()
for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    missing_packages <- c(missing_packages, pkg)
    cat(sprintf("  ✗ %s: NOT INSTALLED\n", pkg))
  } else {
    cat(sprintf("  ✓ %s: installed\n", pkg))
  }
}

if (length(missing_packages) > 0) {
  cat("\nPlease install missing packages before proceeding.\n")
  stop("Missing required packages")
} else {
  cat("\nAll required packages are installed!\n")
}

# =============================================================================
# STEP 4: Run Complete Analysis (Easiest Approach)
# =============================================================================

# This runs the entire pipeline in one command
# Adjust paths to match your data location

cat("\n=== RUNNING COMPLETE ANALYSIS ===\n")

# Example with placeholder paths - UPDATE THESE TO YOUR ACTUAL PATHS
results <- run_complete_microbiome_analysis(
  qiime_dir = "qiime2_output",              # Directory containing .qza files
  metadata_file = "example_metadata.tsv",    # Your metadata file
  output_dir = "results",                    # Where to save results
  group_var = "SampleType",                  # Column name for grouping
  group1 = "Gut",                           # First group name
  group2 = "Derm"                           # Second group name (reference)
)

# =============================================================================
# STEP 5: Examine Results
# =============================================================================

cat("\n=== EXAMINING RESULTS ===\n")

# The 'results' object contains all analysis outputs:
# - results$phyloseq_raw: Original filtered data
# - results$phyloseq_rel: Relative abundance data
# - results$phylum_results: Phylum-level analysis
# - results$family_results: Family-level analysis
# - results$genus_composition: Genus composition
# - results$genus_statistics: Genus statistical tests
# - results$alpha_diversity: Alpha diversity results
# - results$beta_diversity: Beta diversity results
# - results$deseq2_results: DESeq2 differential abundance

# Example: View significant genera from DESeq2
cat("\nTop 10 Differentially Abundant Genera:\n")
sig_genera <- results$deseq2_results$results %>%
  filter(padj < 0.05) %>%
  arrange(padj) %>%
  head(10)

print(sig_genera[, c("Genus", "log2FoldChange", "padj")])

# Example: View alpha diversity statistics
cat("\nAlpha Diversity Comparison:\n")
print(results$alpha_diversity$statistics)

# Example: View beta diversity PERMANOVA results
cat("\nBeta Diversity PERMANOVA:\n")
print(results$beta_diversity$permanova)

# =============================================================================
# ALTERNATIVE: Step-by-Step Analysis (More Control)
# =============================================================================

# If you prefer to run each step individually with more control:

# # 1. Import data
# qiime_artifacts <- list(
#   table = "qiime2_output/table.qza",
#   sequences = "qiime2_output/rep-seqs.qza",
#   taxonomy = "qiime2_output/taxonomy.qza",
#   tree = "qiime2_output/rooted-tree.qza"
# )
# 
# ps <- import_qiime2_to_phyloseq(qiime_artifacts, "example_metadata.tsv")
# 
# # 2. Quality assessment
# qa_results <- assess_phyloseq_quality(ps)
# 
# # 3. Preprocessing
# ps <- filter_bacteria_only(ps)
# ps <- remove_organellar_sequences(ps)
# ps <- prevalence_based_filtering(ps, min_samples = 2)
# 
# # 4. Transform to relative abundance
# ps_rel <- transform_to_relative_abundance(ps)
# 
# # 5. Taxonomic composition analysis
# phylum_results <- analyze_phylum_level(ps_rel, "SampleType")
# family_results <- analyze_family_level(ps_rel, "SampleType", top_n = 15)
# genus_comp <- analyze_genus_level_composition(ps_rel, "SampleType", top_n = 15)
# genus_stats <- analyze_genus_level_statistics(ps_rel, "SampleType", 
#                                               "Gut", "Derm", top_n = 25)
# 
# # 6. Alpha diversity
# alpha_results <- analyze_alpha_diversity(ps, "SampleType", "Gut", "Derm")
# 
# # 7. Beta diversity
# beta_results <- analyze_beta_diversity(ps, "SampleType", "Gut", "Derm")
# 
# # 8. Differential abundance
# ps_deseq <- preprocess_for_deseq2(ps, "Genus", min_reads = 10)
# deseq_results <- perform_deseq2_analysis(ps_deseq, "SampleType", "Derm", "Gut")
# deseq_plots <- visualize_deseq2_results(deseq_results, 0.05, 1, "Gut", "Derm")

# =============================================================================
# STEP 6: Save Results
# =============================================================================

# Save workspace for future reference
# save.image("microbiome_analysis_workspace.RData")

# Export key results to files
# write.csv(results$deseq2_results$results, 
#           "results/deseq2_results.csv", row.names = FALSE)
# 
# write.csv(results$alpha_diversity$diversity_data, 
#           "results/alpha_diversity.csv", row.names = FALSE)
# 
# write.csv(results$genus_statistics$statistics, 
#           "results/genus_statistics.csv", row.names = FALSE)

# =============================================================================
# STEP 7: Export High-Resolution Plots
# =============================================================================

# Save plots as publication-quality figures
# 
# # Save phylum composition plot
# ggsave("results/phylum_composition.png", 
#        results$phylum_results$plot, 
#        width = 12, height = 8, dpi = 300)
# 
# ggsave("results/phylum_composition.pdf", 
#        results$phylum_results$plot, 
#        width = 12, height = 8)
# 
# # Save beta diversity PCoA
# ggsave("results/beta_diversity_pcoa.png", 
#        results$beta_diversity$plot, 
#        width = 10, height = 8, dpi = 300)
# 
# ggsave("results/beta_diversity_pcoa.pdf", 
#        results$beta_diversity$plot, 
#        width = 10, height = 8)
# 
# # Save DESeq2 volcano plot
# ggsave("results/deseq2_volcano.png", 
#        results$deseq2_plots$volcano_plot, 
#        width = 10, height = 8, dpi = 600)
# 
# ggsave("results/deseq2_volcano.pdf", 
#        results$deseq2_plots$volcano_plot, 
#        width = 10, height = 8)

# =============================================================================
# STEP 8: Document Your Analysis
# =============================================================================

# Document computational environment
document_computational_environment()

# Save session info to file
# sink("results/session_info.txt")
# sessionInfo()
# sink()

cat("\n=== ANALYSIS COMPLETE ===\n")
cat("Check the 'results' directory for all outputs\n")
cat("Plots have been displayed in your R graphics device\n")
cat("Results object is available in your workspace\n\n")

# =============================================================================
# ADDITIONAL EXAMPLES
# =============================================================================

# Example: Subset data for specific analysis
# ps_gut_only <- subset_samples(ps, SampleType == "Gut")
# ps_derm_only <- subset_samples(ps, SampleType == "Derm")

# Example: Export phyloseq object
# saveRDS(results$phyloseq_rel, "results/phyloseq_relative_abundance.rds")

# Example: Re-run analysis with different parameters
# genus_stats_stringent <- analyze_genus_level_statistics(
#   ps_rel, "SampleType", "Gut", "Derm", top_n = 50
# )

# Example: Custom plot
# library(ggplot2)
# custom_plot <- ggplot(results$alpha_diversity$diversity_data, 
#                      aes(x = SampleType, y = Shannon, fill = SampleType)) +
#   geom_violin(alpha = 0.6) +
#   geom_boxplot(width = 0.2) +
#   geom_jitter(width = 0.1, alpha = 0.5) +
#   theme_minimal() +
#   labs(title = "Shannon Diversity: Gut vs Derm",
#        y = "Shannon Index")
# print(custom_plot)

cat("\nFor more information, see README_MICROBIOME_PIPELINE.md\n")
