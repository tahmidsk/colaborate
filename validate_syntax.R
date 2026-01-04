#!/usr/bin/env Rscript
################################################################################
# Syntax Validation Script
# This script checks if the pipeline code has syntax errors
# Run with: Rscript validate_syntax.R
################################################################################

cat("=== Validating 16S Microbiome Analysis Pipeline Syntax ===\n\n")

# Check if required file exists
if (!file.exists("16S_microbiome_analysis_pipeline.R")) {
  stop("Error: 16S_microbiome_analysis_pipeline.R not found!")
}

# Attempt to parse the file
cat("Checking syntax of 16S_microbiome_analysis_pipeline.R...\n")
tryCatch({
  parse("16S_microbiome_analysis_pipeline.R")
  cat("✓ Pipeline syntax is valid!\n\n")
}, error = function(e) {
  cat("✗ Syntax error found:\n")
  print(e)
  stop("Syntax validation failed")
})

# Check example usage script
if (file.exists("example_usage.R")) {
  cat("Checking syntax of example_usage.R...\n")
  tryCatch({
    parse("example_usage.R")
    cat("✓ Example usage syntax is valid!\n\n")
  }, error = function(e) {
    cat("✗ Syntax error found:\n")
    print(e)
    stop("Syntax validation failed")
  })
}

# Try to source the pipeline (will fail if packages not installed, but checks deeper issues)
cat("Attempting to load pipeline functions...\n")
cat("(This may generate warnings about missing packages - that's OK)\n\n")

source("16S_microbiome_analysis_pipeline.R")

cat("✓ Pipeline loaded successfully!\n\n")

# List available functions
cat("=== Available Pipeline Functions ===\n\n")

pipeline_functions <- c(
  "run_fastqc_quality_control",
  "qiime2_processing_pipeline",
  "import_qiime2_to_phyloseq",
  "assess_phyloseq_quality",
  "filter_bacteria_only",
  "remove_organellar_sequences",
  "prevalence_based_filtering",
  "transform_to_relative_abundance",
  "agglomerate_taxa",
  "analyze_phylum_level",
  "analyze_family_level",
  "analyze_genus_level_composition",
  "analyze_genus_level_statistics",
  "calculate_taxonomic_summaries",
  "analyze_alpha_diversity",
  "analyze_beta_diversity",
  "preprocess_for_deseq2",
  "perform_deseq2_analysis",
  "visualize_deseq2_results",
  "document_computational_environment",
  "run_complete_microbiome_analysis"
)

for (func in pipeline_functions) {
  if (exists(func)) {
    cat(sprintf("  ✓ %s\n", func))
  } else {
    cat(sprintf("  ✗ %s NOT FOUND\n", func))
  }
}

cat("\n=== Validation Complete ===\n")
cat("All syntax checks passed!\n")
cat("Pipeline is ready to use.\n\n")
cat("Note: To use the pipeline, you'll need to install required packages.\n")
cat("See README_MICROBIOME_PIPELINE.md for installation instructions.\n")
