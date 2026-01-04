################################################################################
# 16S rRNA Microbiome Analysis Pipeline
# Complete implementation of quality assessment, preprocessing, and statistical
# analysis for gut vs dermal microbiome communities
################################################################################

# =============================================================================
# SECTION 3.1: Raw Data Quality Assessment and QIIME2 Pipeline Processing
# =============================================================================

# -----------------------------------------------------------------------------
# 3.1.1: Initial Quality Control with FastQC
# -----------------------------------------------------------------------------
# This section uses FastQC to assess raw sequencing data quality
# FastQC evaluates: per-base quality scores, sequence length distribution,
# GC content, and adapter contamination

run_fastqc_quality_control <- function(input_dir, output_dir) {
  # Purpose: Run FastQC on raw sequencing files to assess quality metrics
  # Parameters:
  #   input_dir: Directory containing raw FASTQ files
  #   output_dir: Directory to save FastQC reports
  
  cat("=== Running FastQC Quality Control ===\n")
  
  # Create output directory if it doesn't exist
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }
  
  # Get list of FASTQ files
  fastq_files <- list.files(input_dir, pattern = "\\.fastq\\.gz$|\\.fq\\.gz$", 
                           full.names = TRUE)
  
  cat(sprintf("Found %d FASTQ files to process\n", length(fastq_files)))
  
  # Run FastQC on each file
  # Note: This requires FastQC v0.12.0 to be installed
  fastqc_cmd <- sprintf("fastqc %s -o %s -t 4", 
                       paste(fastq_files, collapse = " "), 
                       output_dir)
  
  cat("Command:", fastqc_cmd, "\n")
  cat("Note: Ensure FastQC v0.12.0 is installed and in PATH\n")
  
  # Uncomment to run:
  # system(fastqc_cmd)
  
  return(output_dir)
}

# -----------------------------------------------------------------------------
# 3.1.2: QIIME2 Processing Pipeline
# -----------------------------------------------------------------------------
# This section processes raw sequences through QIIME2 pipeline v2024.10
# Steps: Import -> DADA2 (trim, filter, denoise) -> Taxonomy -> Phylogeny

qiime2_processing_pipeline <- function(input_dir, output_dir, metadata_file) {
  # Purpose: Complete QIIME2 processing of raw sequences
  # Pipeline steps:
  #   1. Import raw sequences
  #   2. DADA2: Quality trimming (first 15 bp), truncation (at 240 bp),
  #      denoising, dereplication, chimera removal
  #   3. Taxonomic classification using SILVA-138-99-nb-classifier
  #   4. Phylogenetic tree construction
  
  cat("=== QIIME2 Processing Pipeline ===\n")
  
  # Create output directory
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }
  
  # Step 1: Import sequences
  cat("\n1. Importing sequences...\n")
  import_cmd <- sprintf(
    "qiime tools import \\
    --type 'SampleData[PairedEndSequencesWithQuality]' \\
    --input-path %s \\
    --output-path %s/demux-paired-end.qza \\
    --input-format CasavaOneEightSingleLanePerSampleDirFmt",
    input_dir, output_dir
  )
  cat(import_cmd, "\n")
  
  # Step 2: DADA2 quality filtering and denoising
  # Trim first 15 bp from 5' end to remove low-quality bases and primers
  # Truncate at 240 bp to maintain high quality while preserving length
  cat("\n2. Running DADA2 for quality filtering and denoising...\n")
  dada2_cmd <- sprintf(
    "qiime dada2 denoise-paired \\
    --i-demultiplexed-seqs %s/demux-paired-end.qza \\
    --p-trim-left-f 15 \\
    --p-trim-left-r 15 \\
    --p-trunc-len-f 240 \\
    --p-trunc-len-r 240 \\
    --o-table %s/table.qza \\
    --o-representative-sequences %s/rep-seqs.qza \\
    --o-denoising-stats %s/denoising-stats.qza",
    output_dir, output_dir, output_dir, output_dir
  )
  cat(dada2_cmd, "\n")
  
  # Step 3: Taxonomic classification using SILVA database
  cat("\n3. Performing taxonomic classification...\n")
  taxonomy_cmd <- sprintf(
    "qiime feature-classifier classify-sklearn \\
    --i-classifier silva-138-99-nb-classifier.qza \\
    --i-reads %s/rep-seqs.qza \\
    --o-classification %s/taxonomy.qza",
    output_dir, output_dir
  )
  cat(taxonomy_cmd, "\n")
  
  # Step 4: Build phylogenetic tree
  cat("\n4. Building phylogenetic tree...\n")
  phylogeny_cmd <- sprintf(
    "qiime phylogeny align-to-tree-mafft-fasttree \\
    --i-sequences %s/rep-seqs.qza \\
    --o-alignment %s/aligned-rep-seqs.qza \\
    --o-masked-alignment %s/masked-aligned-rep-seqs.qza \\
    --o-tree %s/unrooted-tree.qza \\
    --o-rooted-tree %s/rooted-tree.qza",
    output_dir, output_dir, output_dir, output_dir, output_dir
  )
  cat(phylogeny_cmd, "\n")
  
  cat("\nNote: Uncomment system() calls to execute commands\n")
  cat("Required: QIIME2 v2024.10 and SILVA-138-99-nb-classifier.qza\n")
  
  # Return paths to output artifacts
  return(list(
    table = file.path(output_dir, "table.qza"),
    sequences = file.path(output_dir, "rep-seqs.qza"),
    taxonomy = file.path(output_dir, "taxonomy.qza"),
    tree = file.path(output_dir, "rooted-tree.qza")
  ))
}

# -----------------------------------------------------------------------------
# 3.1.3: Data Import and Phyloseq Object Construction
# -----------------------------------------------------------------------------
# Import QIIME2 artifacts into R and construct phyloseq object

import_qiime2_to_phyloseq <- function(qiime_artifacts, metadata_file) {
  # Purpose: Import QIIME2 outputs and create phyloseq object
  # Uses qiime2R package to import artifacts and metadata
  # Creates integrated phyloseq object containing ASV table, taxonomy,
  # phylogenetic tree, and sample metadata
  
  library(qiime2R)
  library(phyloseq)
  
  cat("=== Importing QIIME2 Data to Phyloseq ===\n")
  
  # Import QIIME2 artifacts using qza_to_phyloseq function
  # This function integrates all components into a single phyloseq object
  cat("Importing QIIME2 artifacts...\n")
  
  ps <- qza_to_phyloseq(
    features = qiime_artifacts$table,
    tree = qiime_artifacts$tree,
    taxonomy = qiime_artifacts$taxonomy,
    metadata = metadata_file
  )
  
  cat(sprintf("Phyloseq object created successfully\n"))
  cat(sprintf("  Samples: %d\n", nsamples(ps)))
  cat(sprintf("  ASVs: %d\n", ntaxa(ps)))
  cat(sprintf("  Sample variables: %s\n", 
              paste(sample_variables(ps), collapse = ", ")))
  
  return(ps)
}

# =============================================================================
# SECTION 3.2: Data Quality Assessment and Preprocessing
# =============================================================================

# -----------------------------------------------------------------------------
# 3.2.1: Initial Data Assessment of Phyloseq Dataset
# -----------------------------------------------------------------------------

assess_phyloseq_quality <- function(ps) {
  # Purpose: Comprehensive quality assessment of phyloseq object
  # Evaluates: library sizes, taxonomic composition, potential contaminants
  
  library(phyloseq)
  library(ggplot2)
  
  cat("=== Initial Phyloseq Data Assessment ===\n")
  
  # Basic statistics
  cat(sprintf("\nDataset Overview:\n"))
  cat(sprintf("  Total ASVs: %d\n", ntaxa(ps)))
  cat(sprintf("  Total Samples: %d\n", nsamples(ps)))
  
  # Library sizes (sequencing depth per sample)
  lib_sizes <- sample_sums(ps)
  cat(sprintf("\nLibrary Sizes:\n"))
  cat(sprintf("  Mean: %.0f\n", mean(lib_sizes)))
  cat(sprintf("  Median: %.0f\n", median(lib_sizes)))
  cat(sprintf("  Min: %.0f\n", min(lib_sizes)))
  cat(sprintf("  Max: %.0f\n", max(lib_sizes)))
  
  # Visualize library sizes
  lib_size_df <- data.frame(
    Sample = sample_names(ps),
    LibrarySize = lib_sizes
  )
  
  p_lib <- ggplot(lib_size_df, aes(x = reorder(Sample, LibrarySize), 
                                   y = LibrarySize)) +
    geom_bar(stat = "identity", fill = "steelblue") +
    labs(title = "Library Sizes per Sample",
         x = "Sample", y = "Number of Reads") +
    theme_minimal(base_size = 10) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
  
  print(p_lib)
  
  # Kingdom-level taxonomic composition
  cat("\nKingdom-level Classification:\n")
  kingdom_table <- table(tax_table(ps)[, "Kingdom"], useNA = "ifany")
  print(kingdom_table)
  
  # Family-level assessment for potential contaminants
  cat("\nFamily-level Composition (top 10):\n")
  family_sums <- tapply(taxa_sums(ps), tax_table(ps)[, "Family"], sum, 
                       na.rm = TRUE)
  top_families <- sort(family_sums, decreasing = TRUE)[1:10]
  print(top_families)
  
  return(list(
    ntaxa = ntaxa(ps),
    nsamples = nsamples(ps),
    lib_sizes = lib_sizes,
    kingdom_table = kingdom_table
  ))
}

# -----------------------------------------------------------------------------
# 3.2.2: Taxonomic Filtering (Bacteria Only)
# -----------------------------------------------------------------------------

filter_bacteria_only <- function(ps) {
  # Purpose: Retain only bacterial sequences
  # Removes: Eukaryotic, Archaeal, and unclassified sequences
  # Focuses analysis on bacterial communities only
  
  library(phyloseq)
  
  cat("=== Filtering for Bacteria Only ===\n")
  cat(sprintf("ASVs before filtering: %d\n", ntaxa(ps)))
  
  # Keep only sequences classified as Kingdom "d__Bacteria"
  ps_bacteria <- subset_taxa(ps, Kingdom == "d__Bacteria")
  
  cat(sprintf("ASVs after filtering: %d\n", ntaxa(ps_bacteria)))
  cat(sprintf("Removed: %d non-bacterial ASVs\n", 
              ntaxa(ps) - ntaxa(ps_bacteria)))
  
  return(ps_bacteria)
}

# -----------------------------------------------------------------------------
# 3.2.3: Mitochondria and Chloroplast Sequence Removal
# -----------------------------------------------------------------------------

remove_organellar_sequences <- function(ps) {
  # Purpose: Remove host organellar DNA contamination
  # Removes: Mitochondrial and Chloroplast sequences
  # These sequences are common contaminants from host tissue
  # Uses logical operators to preserve taxa with missing Family classifications
  
  library(phyloseq)
  
  cat("=== Removing Mitochondria and Chloroplast Sequences ===\n")
  cat(sprintf("ASVs before filtering: %d\n", ntaxa(ps)))
  
  # Remove Mitochondria and Chloroplast
  # Keep taxa where Family is NOT Mitochondria or Chloroplast
  # OR where Family is NA (preserve unclassified at Family level)
  ps_clean <- subset_taxa(ps, 
                         (Family != "Mitochondria" | is.na(Family)) & 
                         (Family != "Chloroplast" | is.na(Family)))
  
  cat(sprintf("ASVs after filtering: %d\n", ntaxa(ps_clean)))
  cat(sprintf("Removed: %d organellar sequences\n", 
              ntaxa(ps) - ntaxa(ps_clean)))
  
  return(ps_clean)
}

# -----------------------------------------------------------------------------
# 3.2.4: Prevalence-Based Filtering
# -----------------------------------------------------------------------------

prevalence_based_filtering <- function(ps, min_samples = 2) {
  # Purpose: Remove rare taxa that may be sequencing artifacts
  # Criterion: Taxa must be observed in at least 'min_samples' samples
  # Rationale: Rare taxa in only 1 sample are often sequencing errors
  # or cross-contamination
  
  library(phyloseq)
  
  cat("=== Prevalence-Based Filtering ===\n")
  cat(sprintf("ASVs before filtering: %d\n", ntaxa(ps)))
  cat(sprintf("Minimum samples threshold: %d\n", min_samples))
  
  # Filter taxa: keep if present in >= min_samples
  ps_filtered <- filter_taxa(ps, function(x) sum(x > 0) >= min_samples, 
                            prune = TRUE)
  
  cat(sprintf("ASVs after filtering: %d\n", ntaxa(ps_filtered)))
  cat(sprintf("Removed: %d rare ASVs\n", ntaxa(ps) - ntaxa(ps_filtered)))
  
  return(ps_filtered)
}

# =============================================================================
# SECTION 3.3: Relative Abundance Transformation
# =============================================================================

transform_to_relative_abundance <- function(ps) {
  # Purpose: Normalize counts to relative abundances (percentages)
  # Rationale: Accounts for varying sequencing depths across samples
  # Method: Divide each ASV count by total sample reads, multiply by 100
  # Enables meaningful cross-sample comparisons
  
  library(phyloseq)
  
  cat("=== Transforming to Relative Abundance ===\n")
  
  # Transform counts to relative abundance (percentage)
  ps_rel <- transform_sample_counts(ps, function(x) x / sum(x) * 100)
  
  cat("Transformation complete: counts converted to percentages\n")
  cat(sprintf("Sample sums now equal 100 (e.g., sample 1: %.2f)\n", 
              sum(otu_table(ps_rel)[, 1])))
  
  return(ps_rel)
}

# =============================================================================
# SECTION 3.4: Taxonomic Composition Analysis
# =============================================================================

# -----------------------------------------------------------------------------
# 3.4.1: Hierarchical Taxonomic Analysis Setup
# -----------------------------------------------------------------------------

agglomerate_taxa <- function(ps, rank) {
  # Purpose: Combine ASVs at specified taxonomic level
  # Reduces complexity while maintaining biological meaning
  # Parameters:
  #   ps: phyloseq object
  #   rank: taxonomic rank (e.g., "Phylum", "Family", "Genus")
  
  library(phyloseq)
  
  cat(sprintf("Agglomerating taxa at %s level...\n", rank))
  
  ps_agg <- tax_glom(ps, taxrank = rank, NArm = FALSE)
  
  cat(sprintf("  ASVs before: %d\n", ntaxa(ps)))
  cat(sprintf("  Taxa after: %d\n", ntaxa(ps_agg)))
  
  return(ps_agg)
}

# -----------------------------------------------------------------------------
# 3.4.2: Phylum-Level Analysis
# -----------------------------------------------------------------------------

analyze_phylum_level <- function(ps_rel, group_var = "SampleType") {
  # Purpose: Analyze and visualize phylum-level composition
  # Includes all bacterial phyla detected
  # Creates stacked bar plots grouped by experimental condition
  
  library(phyloseq)
  library(ggplot2)
  library(dplyr)
  
  cat("=== Phylum-Level Analysis ===\n")
  
  # Agglomerate at Phylum level
  ps_phylum <- agglomerate_taxa(ps_rel, "Phylum")
  
  # Convert to data frame for plotting
  phylum_df <- psmelt(ps_phylum)
  
  cat(sprintf("Total phyla detected: %d\n", 
              length(unique(phylum_df$Phylum))))
  
  # Create stacked bar plot
  p_phylum <- ggplot(phylum_df, aes(x = Sample, y = Abundance, 
                                    fill = Phylum)) +
    geom_bar(stat = "identity", position = "fill") +
    facet_wrap(as.formula(paste("~", group_var)), scales = "free_x") +
    labs(title = "Phylum-Level Composition",
         x = "Sample", y = "Relative Abundance (%)") +
    scale_y_continuous(labels = scales::percent) +
    theme_minimal(base_size = 12) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1),
          legend.position = "right")
  
  print(p_phylum)
  
  # Summary statistics
  phylum_summary <- phylum_df %>%
    group_by(across(all_of(group_var)), Phylum) %>%
    summarise(
      n = n(),
      mean_abundance = mean(Abundance),
      sd_abundance = sd(Abundance),
      .groups = "drop"
    )
  
  return(list(
    plot = p_phylum,
    data = phylum_df,
    summary = phylum_summary
  ))
}

# -----------------------------------------------------------------------------
# 3.4.3: Family-Level Analysis
# -----------------------------------------------------------------------------

analyze_family_level <- function(ps_rel, group_var = "SampleType", 
                                top_n = 15) {
  # Purpose: Analyze top 15 most abundant families
  # Rationale: Family level shows high diversity; focus on most abundant
  # Creates stacked bar plots for visualization
  
  library(phyloseq)
  library(ggplot2)
  library(dplyr)
  
  cat("=== Family-Level Analysis ===\n")
  
  # Agglomerate at Family level
  ps_family <- agglomerate_taxa(ps_rel, "Family")
  
  # Identify top families by total abundance
  family_sums <- taxa_sums(ps_family)
  top_families <- names(sort(family_sums, decreasing = TRUE)[1:top_n])
  
  # Prune to top families
  ps_family_top <- prune_taxa(top_families, ps_family)
  
  cat(sprintf("Analyzing top %d families (of %d total)\n", 
              top_n, ntaxa(ps_family)))
  
  # Convert to data frame
  family_df <- psmelt(ps_family_top)
  
  # Create stacked bar plot
  p_family <- ggplot(family_df, aes(x = Sample, y = Abundance, 
                                   fill = Family)) +
    geom_bar(stat = "identity", position = "fill") +
    facet_wrap(as.formula(paste("~", group_var)), scales = "free_x") +
    labs(title = paste("Top", top_n, "Family-Level Composition"),
         x = "Sample", y = "Relative Abundance (%)") +
    scale_y_continuous(labels = scales::percent) +
    theme_minimal(base_size = 12) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1),
          legend.position = "right")
  
  print(p_family)
  
  # Summary statistics
  family_summary <- family_df %>%
    group_by(across(all_of(group_var)), Family) %>%
    summarise(
      n = n(),
      mean_abundance = mean(Abundance),
      median_abundance = median(Abundance),
      sd_abundance = sd(Abundance),
      min_abundance = min(Abundance),
      max_abundance = max(Abundance),
      .groups = "drop"
    )
  
  return(list(
    plot = p_family,
    data = family_df,
    summary = family_summary
  ))
}

# -----------------------------------------------------------------------------
# 3.4.4: Genus-Level Analysis
# -----------------------------------------------------------------------------

analyze_genus_level_composition <- function(ps_rel, group_var = "SampleType", 
                                           top_n = 15) {
  # Purpose: Compositional analysis of top 15 genera
  # Creates stacked bar plots for overall community composition
  
  library(phyloseq)
  library(ggplot2)
  library(dplyr)
  
  cat("=== Genus-Level Compositional Analysis ===\n")
  
  # Agglomerate at Genus level
  ps_genus <- agglomerate_taxa(ps_rel, "Genus")
  
  # Identify top genera
  genus_sums <- taxa_sums(ps_genus)
  top_genera <- names(sort(genus_sums, decreasing = TRUE)[1:top_n])
  
  # Prune to top genera
  ps_genus_top <- prune_taxa(top_genera, ps_genus)
  
  cat(sprintf("Analyzing top %d genera (of %d total)\n", 
              top_n, ntaxa(ps_genus)))
  
  # Convert to data frame
  genus_df <- psmelt(ps_genus_top)
  
  # Create stacked bar plot
  p_genus <- ggplot(genus_df, aes(x = Sample, y = Abundance, fill = Genus)) +
    geom_bar(stat = "identity", position = "fill") +
    facet_wrap(as.formula(paste("~", group_var)), scales = "free_x") +
    labs(title = paste("Top", top_n, "Genus-Level Composition"),
         x = "Sample", y = "Relative Abundance (%)") +
    scale_y_continuous(labels = scales::percent) +
    theme_minimal(base_size = 12) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1),
          legend.position = "right")
  
  print(p_genus)
  
  return(list(
    plot = p_genus,
    data = genus_df
  ))
}

# -----------------------------------------------------------------------------
# 3.4.4.1: Statistical Analysis of Genus-Level Comparisons
# -----------------------------------------------------------------------------

analyze_genus_level_statistics <- function(ps_rel, 
                                          group_var = "SampleType",
                                          group1 = "Gut", 
                                          group2 = "Derm",
                                          top_n = 25) {
  # Purpose: Statistical comparison of top 25 genera between groups
  # Methods: 
  #   - Wilcoxon rank-sum test (non-parametric)
  #   - Cliff's Delta effect size
  #   - Benjamini-Hochberg FDR correction
  # Interpretation thresholds for Cliff's Delta:
  #   |δ| < 0.147 → negligible
  #   0.147 ≤ |δ| < 0.33 → small
  #   0.33 ≤ |δ| < 0.474 → medium
  #   |δ| ≥ 0.474 → large
  
  library(phyloseq)
  library(ggplot2)
  library(dplyr)
  library(ggpubr)
  library(effsize)
  
  cat("=== Genus-Level Statistical Analysis ===\n")
  cat(sprintf("Comparing: %s vs %s\n", group1, group2))
  
  # Agglomerate at Genus level
  ps_genus <- agglomerate_taxa(ps_rel, "Genus")
  
  # Identify top genera
  genus_sums <- taxa_sums(ps_genus)
  top_genera <- names(sort(genus_sums, decreasing = TRUE)[1:top_n])
  
  # Prune to top genera
  ps_genus_top <- prune_taxa(top_genera, ps_genus)
  
  cat(sprintf("Analyzing top %d genera for statistical comparison\n", top_n))
  
  # Convert to data frame
  genus_df <- psmelt(ps_genus_top)
  
  # Filter for the two groups being compared
  genus_df_filtered <- genus_df %>%
    filter(get(group_var) %in% c(group1, group2))
  
  # Perform statistical tests for each genus
  stat_results <- data.frame()
  
  for (genus in unique(genus_df_filtered$Genus)) {
    genus_data <- genus_df_filtered %>% filter(Genus == genus)
    
    group1_vals <- genus_data %>% 
      filter(get(group_var) == group1) %>% 
      pull(Abundance)
    
    group2_vals <- genus_data %>% 
      filter(get(group_var) == group2) %>% 
      pull(Abundance)
    
    # Wilcoxon rank-sum test
    wilcox_result <- wilcox.test(group1_vals, group2_vals)
    
    # Cliff's Delta effect size
    cliff_result <- cliff.delta(group1_vals, group2_vals)
    
    # Effect size interpretation
    abs_delta <- abs(cliff_result$estimate)
    if (abs_delta < 0.147) {
      magnitude <- "negligible"
    } else if (abs_delta < 0.33) {
      magnitude <- "small"
    } else if (abs_delta < 0.474) {
      magnitude <- "medium"
    } else {
      magnitude <- "large"
    }
    
    stat_results <- rbind(stat_results, data.frame(
      Genus = genus,
      p_value = wilcox_result$p.value,
      cliff_delta = cliff_result$estimate,
      effect_magnitude = magnitude,
      mean_group1 = mean(group1_vals),
      mean_group2 = mean(group2_vals)
    ))
  }
  
  # Apply Benjamini-Hochberg FDR correction
  stat_results$p_adj <- p.adjust(stat_results$p_value, method = "BH")
  
  # Add significance labels
  stat_results$significance <- ifelse(stat_results$p_adj < 0.001, "***",
                                     ifelse(stat_results$p_adj < 0.01, "**",
                                     ifelse(stat_results$p_adj < 0.05, "*", 
                                            "NS")))
  
  # Sort by p-value
  stat_results <- stat_results %>% arrange(p_value)
  
  cat(sprintf("\nStatistical Results:\n"))
  cat(sprintf("  Total genera tested: %d\n", nrow(stat_results)))
  cat(sprintf("  Significant (p < 0.05): %d\n", 
              sum(stat_results$p_adj < 0.05)))
  
  # Create box plots with statistics
  plots_list <- list()
  
  for (i in 1:min(12, nrow(stat_results))) {  # Plot top 12 most significant
    genus <- stat_results$Genus[i]
    genus_data <- genus_df_filtered %>% filter(Genus == genus)
    
    p <- ggplot(genus_data, aes_string(x = group_var, y = "Abundance")) +
      geom_boxplot(aes_string(fill = group_var), alpha = 0.7) +
      geom_jitter(width = 0.2, size = 2, alpha = 0.6) +
      stat_compare_means(method = "wilcox.test", 
                        label = "p.format",
                        label.y.npc = 0.95) +
      labs(title = genus,
           y = "Relative Abundance (%)",
           x = "") +
      theme_bw(base_size = 10) +
      theme(legend.position = "none")
    
    plots_list[[genus]] <- p
  }
  
  # Combine plots
  if (length(plots_list) > 0) {
    combined_plot <- ggpubr::ggarrange(plotlist = plots_list, 
                                      ncol = 3, nrow = 4)
    print(combined_plot)
  }
  
  return(list(
    statistics = stat_results,
    plots = plots_list,
    data = genus_df_filtered
  ))
}

# -----------------------------------------------------------------------------
# 3.4.5: Summary Calculations
# -----------------------------------------------------------------------------

calculate_taxonomic_summaries <- function(ps_rel, group_var = "SampleType",
                                         rank = "Genus") {
  # Purpose: Calculate descriptive statistics for taxonomic groups
  # Statistics: n, mean, median, sd, min, max relative abundance
  
  library(phyloseq)
  library(dplyr)
  
  cat(sprintf("=== Calculating %s-Level Summaries ===\n", rank))
  
  # Agglomerate at specified rank
  ps_agg <- agglomerate_taxa(ps_rel, rank)
  
  # Convert to data frame
  tax_df <- psmelt(ps_agg)
  
  # Calculate summary statistics
  summaries <- tax_df %>%
    group_by(across(all_of(c(group_var, rank)))) %>%
    summarise(
      n = n(),
      mean_abundance = mean(Abundance),
      median_abundance = median(Abundance),
      sd_abundance = sd(Abundance),
      min_abundance = min(Abundance),
      max_abundance = max(Abundance),
      .groups = "drop"
    ) %>%
    arrange(desc(mean_abundance))
  
  cat(sprintf("Summary statistics calculated for %d taxa\n", 
              length(unique(summaries[[rank]]))))
  
  return(summaries)
}

# =============================================================================
# SECTION 3.5: Alpha Diversity Analysis
# =============================================================================

analyze_alpha_diversity <- function(ps, group_var = "SampleType",
                                   group1 = "Gut", group2 = "Derm") {
  # Purpose: Comprehensive alpha diversity analysis
  # Calculates 6 indices:
  #   1. Observed species (ASV count)
  #   2. Chao1 (richness estimator)
  #   3. Shannon (richness + evenness)
  #   4. Simpson (dominance/evenness)
  #   5. Inverse Simpson
  #   6. Faith's Phylogenetic Diversity (PD)
  # Statistical comparison: Wilcoxon rank-sum test
  
  library(phyloseq)
  library(ggplot2)
  library(ggpubr)
  library(picante)
  library(dplyr)
  
  cat("=== Alpha Diversity Analysis ===\n")
  
  # Calculate standard diversity indices
  alpha_div <- estimate_richness(ps, measures = c("Observed", "Chao1", 
                                                   "Shannon", "Simpson", 
                                                   "InvSimpson"))
  
  # Calculate Faith's Phylogenetic Diversity
  # Extract OTU table and tree
  otu_mat <- as.matrix(otu_table(ps))
  if (!taxa_are_rows(ps)) {
    otu_mat <- t(otu_mat)
  }
  tree <- phy_tree(ps)
  
  # Calculate PD
  pd_result <- pd(t(otu_mat), tree, include.root = FALSE)
  alpha_div$PD <- pd_result$PD
  
  # Add sample metadata
  alpha_div$Sample <- rownames(alpha_div)
  alpha_div[[group_var]] <- sample_data(ps)[[group_var]]
  
  cat(sprintf("Calculated %d diversity indices for %d samples\n",
              ncol(alpha_div) - 2, nrow(alpha_div)))
  
  # Statistical comparisons
  diversity_metrics <- c("Observed", "Chao1", "Shannon", "Simpson", 
                        "InvSimpson", "PD")
  
  stat_results <- data.frame()
  
  for (metric in diversity_metrics) {
    group1_vals <- alpha_div %>% 
      filter(get(group_var) == group1) %>% 
      pull(metric)
    
    group2_vals <- alpha_div %>% 
      filter(get(group_var) == group2) %>% 
      pull(metric)
    
    wilcox_result <- wilcox.test(group1_vals, group2_vals)
    
    stat_results <- rbind(stat_results, data.frame(
      Metric = metric,
      p_value = wilcox_result$p.value,
      mean_group1 = mean(group1_vals, na.rm = TRUE),
      mean_group2 = mean(group2_vals, na.rm = TRUE)
    ))
  }
  
  cat("\nStatistical Results (Wilcoxon test):\n")
  print(stat_results)
  
  # Visualization: Violin plots with boxplots
  plots_list <- list()
  
  for (metric in diversity_metrics) {
    p <- ggplot(alpha_div, aes_string(x = group_var, y = metric)) +
      geom_violin(aes_string(fill = group_var), alpha = 0.7) +
      geom_boxplot(width = 0.1, outlier.shape = NA) +
      geom_jitter(width = 0.1, size = 2, alpha = 0.6) +
      stat_compare_means(method = "wilcox.test",
                        label = "p.format") +
      labs(title = metric,
           y = metric,
           x = "") +
      theme_minimal(base_size = 12) +
      theme(legend.position = "none")
    
    plots_list[[metric]] <- p
  }
  
  # Combine plots
  combined_plot <- ggpubr::ggarrange(plotlist = plots_list, 
                                    ncol = 3, nrow = 2)
  print(combined_plot)
  
  return(list(
    diversity_data = alpha_div,
    statistics = stat_results,
    plots = plots_list
  ))
}

# =============================================================================
# SECTION 3.6: Beta Diversity Analysis
# =============================================================================

analyze_beta_diversity <- function(ps, group_var = "SampleType",
                                  group1 = "Gut", group2 = "Derm") {
  # Purpose: Analyze between-sample community dissimilarity
  # Methods:
  #   - Bray-Curtis dissimilarity
  #   - Principal Coordinates Analysis (PCoA)
  #   - PERMANOVA (permutational ANOVA, 999 permutations)
  # Visualizes: PCoA with 95% confidence ellipses
  
  library(phyloseq)
  library(ggplot2)
  library(vegan)
  
  cat("=== Beta Diversity Analysis ===\n")
  
  # Calculate Bray-Curtis dissimilarity
  bc_dist <- distance(ps, method = "bray")
  
  # Perform PCoA ordination
  pcoa_result <- ordinate(ps, method = "PCoA", distance = bc_dist)
  
  # Extract variance explained
  eig <- pcoa_result$values$Eigenvalues
  var_exp <- eig / sum(eig) * 100
  
  cat(sprintf("PCoA variance explained:\n"))
  cat(sprintf("  Axis 1: %.2f%%\n", var_exp[1]))
  cat(sprintf("  Axis 2: %.2f%%\n", var_exp[2]))
  
  # PERMANOVA test
  metadata <- data.frame(sample_data(ps))
  permanova_result <- adonis2(bc_dist ~ metadata[[group_var]], 
                             permutations = 999)
  
  cat("\nPERMANOVA Results:\n")
  print(permanova_result)
  
  r_squared <- permanova_result$R2[1]
  p_value <- permanova_result$`Pr(>F)`[1]
  
  # Create PCoA plot with confidence ellipses
  p_pcoa <- plot_ordination(ps, pcoa_result, color = group_var) +
    geom_point(size = 4, alpha = 0.8) +
    stat_ellipse(level = 0.95, linetype = 2) +
    labs(title = "PCoA - Bray-Curtis Dissimilarity",
         subtitle = sprintf("PERMANOVA: R² = %.3f, p = %.3f", 
                           r_squared, p_value),
         x = sprintf("PC1 (%.2f%%)", var_exp[1]),
         y = sprintf("PC2 (%.2f%%)", var_exp[2])) +
    theme_minimal(base_size = 14) +
    theme(legend.position = "right")
  
  print(p_pcoa)
  
  return(list(
    pcoa_result = pcoa_result,
    permanova = permanova_result,
    plot = p_pcoa,
    distance = bc_dist
  ))
}

# =============================================================================
# SECTION 3.7: Differential Abundance Analysis with DESeq2
# =============================================================================

# -----------------------------------------------------------------------------
# 3.7.1: Data Preprocessing for Differential Analysis
# -----------------------------------------------------------------------------

preprocess_for_deseq2 <- function(ps, rank = "Genus", min_reads = 10) {
  # Purpose: Prepare data for DESeq2 analysis
  # Steps:
  #   1. Agglomerate at specified taxonomic rank (Genus)
  #   2. Filter low-abundance taxa (< min_reads total)
  # Rationale: Reduces noise from rare, potentially erroneous taxa
  
  library(phyloseq)
  
  cat("=== Preprocessing for DESeq2 Analysis ===\n")
  cat(sprintf("Taxa before agglomeration: %d\n", ntaxa(ps)))
  
  # Agglomerate at genus level
  ps_genus <- tax_glom(ps, taxrank = rank, NArm = FALSE)
  cat(sprintf("Genera after agglomeration: %d\n", ntaxa(ps_genus)))
  
  # Filter low-abundance genera
  ps_filtered <- filter_taxa(ps_genus, 
                             function(x) sum(x) >= min_reads, 
                             prune = TRUE)
  
  cat(sprintf("Genera after filtering (>= %d reads): %d\n", 
              min_reads, ntaxa(ps_filtered)))
  
  return(ps_filtered)
}

# -----------------------------------------------------------------------------
# 3.7.2: DESeq2 Analysis Framework
# -----------------------------------------------------------------------------

perform_deseq2_analysis <- function(ps, group_var = "SampleType",
                                   reference_group = "Derm",
                                   comparison_group = "Gut") {
  # Purpose: Differential abundance analysis using DESeq2
  # Model: Negative binomial GLM with empirical Bayes shrinkage
  # Features:
  #   - Accounts for compositional nature of microbiome data
  #   - Handles overdispersion
  #   - Benjamini-Hochberg FDR correction
  # Significance: FDR < 0.05
  
  library(phyloseq)
  library(DESeq2)
  library(dplyr)
  
  cat("=== DESeq2 Differential Abundance Analysis ===\n")
  cat(sprintf("Reference group: %s\n", reference_group))
  cat(sprintf("Comparison group: %s\n", comparison_group))
  
  # Convert phyloseq to DESeq2 object
  # Set reference level
  sample_data(ps)[[group_var]] <- factor(
    sample_data(ps)[[group_var]],
    levels = c(reference_group, comparison_group)
  )
  
  # Create DESeq2 object
  dds <- phyloseq_to_deseq2(ps, as.formula(paste("~", group_var)))
  
  # Calculate geometric means for normalization
  # (handling zeros in microbiome data)
  gm_mean <- function(x, na.rm = TRUE) {
    exp(sum(log(x[x > 0]), na.rm = na.rm) / length(x))
  }
  
  geoMeans <- apply(counts(dds), 1, gm_mean)
  dds <- estimateSizeFactors(dds, geoMeans = geoMeans)
  
  # Run DESeq2 analysis
  cat("Running DESeq2 analysis...\n")
  dds <- DESeq(dds, test = "Wald", fitType = "local")
  
  # Extract results
  res <- results(dds, 
                contrast = c(group_var, comparison_group, reference_group),
                pAdjustMethod = "BH")
  
  # Convert to data frame and add taxonomy
  res_df <- as.data.frame(res)
  res_df$ASV <- rownames(res_df)
  
  # Add taxonomy information
  tax <- as.data.frame(tax_table(ps))
  res_df <- merge(res_df, tax, by.x = "ASV", by.y = "row.names", all.x = TRUE)
  
  # Sort by adjusted p-value
  res_df <- res_df %>% arrange(padj)
  
  # Summary
  cat("\nDESeq2 Results Summary:\n")
  cat(sprintf("  Total genera tested: %d\n", nrow(res_df)))
  cat(sprintf("  Significant (FDR < 0.05): %d\n", 
              sum(res_df$padj < 0.05, na.rm = TRUE)))
  cat(sprintf("  Enriched in %s (log2FC > 0): %d\n", 
              comparison_group,
              sum(res_df$padj < 0.05 & res_df$log2FoldChange > 0, 
                  na.rm = TRUE)))
  cat(sprintf("  Enriched in %s (log2FC < 0): %d\n", 
              reference_group,
              sum(res_df$padj < 0.05 & res_df$log2FoldChange < 0, 
                  na.rm = TRUE)))
  
  return(list(
    deseq_object = dds,
    results = res_df
  ))
}

# -----------------------------------------------------------------------------
# 3.7.3: Effect Size Quantification, Interpretation and Visualization
# -----------------------------------------------------------------------------

visualize_deseq2_results <- function(deseq_results, 
                                    fdr_threshold = 0.05,
                                    fc_threshold = 1,
                                    comparison_group = "Gut",
                                    reference_group = "Derm") {
  # Purpose: Visualize differential abundance results
  # Plots:
  #   1. Volcano plot: log2FC vs -log10(padj)
  #   2. Horizontal bar plot: significant genera by effect size
  # Interpretation:
  #   - Positive log2FC: higher in comparison group (Gut)
  #   - Negative log2FC: higher in reference group (Derm)
  #   - |log2FC| ≥ 1: at least 2-fold change (biologically significant)
  
  library(ggplot2)
  library(dplyr)
  
  cat("=== Visualizing DESeq2 Results ===\n")
  
  res_df <- deseq_results$results
  
  # Add significance category
  res_df <- res_df %>%
    mutate(
      Significance = case_when(
        is.na(padj) ~ "Not tested",
        padj >= fdr_threshold ~ "Not significant",
        padj < fdr_threshold & abs(log2FoldChange) < fc_threshold ~ 
          "Significant (FC < 2)",
        padj < fdr_threshold & log2FoldChange >= fc_threshold ~ 
          paste("Up in", comparison_group),
        padj < fdr_threshold & log2FoldChange <= -fc_threshold ~ 
          paste("Up in", reference_group),
        TRUE ~ "Other"
      )
    )
  
  # Volcano plot
  p_volcano <- ggplot(res_df, aes(x = log2FoldChange, 
                                  y = -log10(padj),
                                  color = Significance)) +
    geom_point(alpha = 0.6, size = 3) +
    geom_vline(xintercept = c(-fc_threshold, fc_threshold), 
              linetype = "dashed", color = "gray50") +
    geom_hline(yintercept = -log10(fdr_threshold), 
              linetype = "dashed", color = "gray50") +
    scale_color_manual(values = c(
      "Not significant" = "gray70",
      "Significant (FC < 2)" = "gray40",
      paste("Up in", comparison_group) = "red",
      paste("Up in", reference_group) = "blue",
      "Not tested" = "gray90"
    )) +
    labs(title = "Differential Abundance - Volcano Plot",
         subtitle = sprintf("%s vs %s", comparison_group, reference_group),
         x = expression(log[2]~"Fold Change"),
         y = expression(-log[10]~"adjusted p-value")) +
    theme_bw(base_size = 14) +
    theme(legend.position = "right")
  
  print(p_volcano)
  
  # Bar plot of significant genera
  sig_genera <- res_df %>%
    filter(padj < fdr_threshold & abs(log2FoldChange) >= fc_threshold) %>%
    arrange(log2FoldChange) %>%
    mutate(Genus = factor(Genus, levels = Genus))
  
  if (nrow(sig_genera) > 0) {
    p_bar <- ggplot(sig_genera, aes(x = log2FoldChange, y = Genus,
                                    fill = log2FoldChange > 0)) +
      geom_bar(stat = "identity") +
      scale_fill_manual(values = c("TRUE" = "red", "FALSE" = "blue"),
                       labels = c("TRUE" = comparison_group, 
                                 "FALSE" = reference_group),
                       name = "Enriched in") +
      geom_vline(xintercept = 0, linetype = "solid", color = "black") +
      labs(title = "Differentially Abundant Genera",
           subtitle = sprintf("FDR < %.2f, |log2FC| ≥ %d", 
                            fdr_threshold, fc_threshold),
           x = expression(log[2]~"Fold Change"),
           y = "") +
      theme_bw(base_size = 12)
    
    print(p_bar)
  } else {
    cat("No genera meet significance thresholds for bar plot\n")
    p_bar <- NULL
  }
  
  return(list(
    volcano_plot = p_volcano,
    bar_plot = p_bar,
    significant_taxa = sig_genera
  ))
}

# =============================================================================
# SECTION 3.8: Computational Environment Documentation
# =============================================================================

document_computational_environment <- function() {
  # Purpose: Document R version and package versions
  # Ensures reproducibility of analysis
  
  cat("=== Computational Environment ===\n\n")
  
  # R version
  cat("R version:\n")
  print(R.version.string)
  cat("\n")
  
  # Package versions
  packages <- c("phyloseq", "ggplot2", "dplyr", "ggpubr", "tidyr", 
               "scales", "qiime2R", "DESeq2", "vegan", "picante", "effsize")
  
  cat("Package versions:\n")
  for (pkg in packages) {
    if (requireNamespace(pkg, quietly = TRUE)) {
      version <- packageVersion(pkg)
      cat(sprintf("  %s: %s\n", pkg, version))
    } else {
      cat(sprintf("  %s: NOT INSTALLED\n", pkg))
    }
  }
  
  cat("\n")
  
  # Session info
  cat("Full session info:\n")
  print(sessionInfo())
}

# =============================================================================
# MAIN ANALYSIS WORKFLOW
# =============================================================================

run_complete_microbiome_analysis <- function(qiime_dir, 
                                            metadata_file,
                                            output_dir = "results",
                                            group_var = "SampleType",
                                            group1 = "Gut",
                                            group2 = "Derm") {
  # Purpose: Execute complete 16S microbiome analysis pipeline
  # This function runs all analysis sections in order
  
  cat("\n")
  cat("################################################################################\n")
  cat("# COMPLETE 16S rRNA MICROBIOME ANALYSIS PIPELINE\n")
  cat("################################################################################\n\n")
  
  # Create output directory
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }
  
  # Set working directory for plots
  original_wd <- getwd()
  setwd(output_dir)
  
  # Document environment
  document_computational_environment()
  
  # Load required libraries
  library(phyloseq)
  library(ggplot2)
  library(dplyr)
  
  cat("\n=== SECTION 3.1.3: Data Import ===\n")
  # Import QIIME2 data
  # Note: Assumes QIIME2 artifacts already exist
  qiime_artifacts <- list(
    table = file.path(qiime_dir, "table.qza"),
    sequences = file.path(qiime_dir, "rep-seqs.qza"),
    taxonomy = file.path(qiime_dir, "taxonomy.qza"),
    tree = file.path(qiime_dir, "rooted-tree.qza")
  )
  
  ps <- import_qiime2_to_phyloseq(qiime_artifacts, metadata_file)
  
  cat("\n=== SECTION 3.2: Data Quality Assessment and Preprocessing ===\n")
  # Quality assessment
  assess_phyloseq_quality(ps)
  
  # Taxonomic filtering
  ps <- filter_bacteria_only(ps)
  ps <- remove_organellar_sequences(ps)
  ps <- prevalence_based_filtering(ps, min_samples = 2)
  
  cat("\n=== SECTION 3.3: Relative Abundance Transformation ===\n")
  ps_rel <- transform_to_relative_abundance(ps)
  
  cat("\n=== SECTION 3.4: Taxonomic Composition Analysis ===\n")
  # Phylum level
  phylum_results <- analyze_phylum_level(ps_rel, group_var)
  
  # Family level
  family_results <- analyze_family_level(ps_rel, group_var, top_n = 15)
  
  # Genus level - composition
  genus_comp <- analyze_genus_level_composition(ps_rel, group_var, top_n = 15)
  
  # Genus level - statistics
  genus_stats <- analyze_genus_level_statistics(ps_rel, group_var, 
                                               group1, group2, top_n = 25)
  
  # Summary calculations
  genus_summary <- calculate_taxonomic_summaries(ps_rel, group_var, "Genus")
  
  cat("\n=== SECTION 3.5: Alpha Diversity Analysis ===\n")
  alpha_results <- analyze_alpha_diversity(ps, group_var, group1, group2)
  
  cat("\n=== SECTION 3.6: Beta Diversity Analysis ===\n")
  beta_results <- analyze_beta_diversity(ps, group_var, group1, group2)
  
  cat("\n=== SECTION 3.7: Differential Abundance Analysis ===\n")
  # Preprocess for DESeq2
  ps_deseq <- preprocess_for_deseq2(ps, rank = "Genus", min_reads = 10)
  
  # Run DESeq2
  deseq_results <- perform_deseq2_analysis(ps_deseq, group_var, 
                                          reference_group = group2,
                                          comparison_group = group1)
  
  # Visualize DESeq2 results
  deseq_plots <- visualize_deseq2_results(deseq_results, 
                                         fdr_threshold = 0.05,
                                         fc_threshold = 1,
                                         comparison_group = group1,
                                         reference_group = group2)
  
  # Reset working directory
  setwd(original_wd)
  
  cat("\n")
  cat("################################################################################\n")
  cat("# ANALYSIS COMPLETE\n")
  cat("################################################################################\n\n")
  cat(sprintf("Results saved to: %s\n", output_dir))
  
  # Return all results
  return(list(
    phyloseq_raw = ps,
    phyloseq_rel = ps_rel,
    phylum_results = phylum_results,
    family_results = family_results,
    genus_composition = genus_comp,
    genus_statistics = genus_stats,
    genus_summary = genus_summary,
    alpha_diversity = alpha_results,
    beta_diversity = beta_results,
    deseq2_results = deseq_results,
    deseq2_plots = deseq_plots
  ))
}

# =============================================================================
# EXAMPLE USAGE
# =============================================================================

# Uncomment and modify paths to run the complete analysis:
#
# results <- run_complete_microbiome_analysis(
#   qiime_dir = "path/to/qiime2/output",
#   metadata_file = "path/to/metadata.tsv",
#   output_dir = "results",
#   group_var = "SampleType",
#   group1 = "Gut",
#   group2 = "Derm"
# )

# For step-by-step execution, see individual functions above
# Each function is documented with its purpose and parameters

cat("\n16S Microbiome Analysis Pipeline loaded successfully!\n")
cat("Use run_complete_microbiome_analysis() to execute the full pipeline\n")
cat("Or call individual functions for specific analyses\n\n")
