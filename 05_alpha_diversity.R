###############################################################################
# 05_alpha_diversity.R
# Section 3.5: Alpha Diversity Analysis
#
# Indices calculated:
#   Observed, Chao1, Shannon, Simpson, InvSimpson  (via phyloseq)
#   Faith's PD  (via picante)
#
# Statistical comparison: Wilcoxon rank-sum test (Gut vs Derm)
# Visualization: violin + box + jitter plots
#
# Input:  results/phyloseq_filtered.rds
# Output: results/alpha_diversity.csv, figures
###############################################################################

# ---- Load Libraries ---------------------------------------------------------
library(phyloseq)
library(picante)
library(ggplot2)
library(ggpubr)
library(dplyr)
library(tidyr)

# ---- Load Data (raw counts, not relative abundance) -------------------------
physeq <- readRDS("results/phyloseq_filtered.rds")

output_dir <- "results/figures"
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

# ---- Calculate Standard Alpha Diversity Indices -----------------------------
alpha_div <- estimate_richness(physeq,
                               measures = c("Observed", "Chao1", "Shannon",
                                            "Simpson", "InvSimpson"))

# ---- Calculate Faith's Phylogenetic Diversity -------------------------------
# pd() requires samples as rows, taxa as columns
if (taxa_are_rows(physeq)) {
  otu_mat <- as.data.frame(t(as(otu_table(physeq), "matrix")))
} else {
  otu_mat <- as.data.frame(as(otu_table(physeq), "matrix"))
}

tree <- phy_tree(physeq)
faith_pd <- pd(otu_mat, tree, include.root = TRUE)

# ---- Combine Into Single Data Frame -----------------------------------------
alpha_div$Sample <- rownames(alpha_div)
alpha_div$PD     <- faith_pd$PD[match(alpha_div$Sample, rownames(faith_pd))]

# Add sample metadata (Group column)
meta <- data.frame(sample_data(physeq))
meta$Sample <- rownames(meta)
alpha_div <- merge(alpha_div, meta[, c("Sample", "Group")], by = "Sample")

cat("=== Alpha Diversity Summary ===\n")
print(head(alpha_div))

write.csv(alpha_div, "results/alpha_diversity.csv", row.names = FALSE)

# ---- Visualization: Violin + Box + Jitter -----------------------------------
metrics <- c("Observed", "Chao1", "Shannon", "Simpson", "InvSimpson", "PD")

alpha_long <- alpha_div %>%
  pivot_longer(cols = all_of(metrics), names_to = "Metric", values_to = "Value")

comparisons <- list(c("Gut", "Derm"))

p_alpha <- ggplot(alpha_long, aes(x = Group, y = Value, fill = Group)) +
  geom_violin(alpha = 0.5, trim = FALSE) +
  geom_boxplot(width = 0.2, outlier.shape = NA) +
  geom_jitter(width = 0.1, size = 1.5, alpha = 0.7) +
  stat_compare_means(method = "wilcox.test", comparisons = comparisons,
                     label = "p.format") +
  facet_wrap(~ Metric, scales = "free_y", ncol = 3) +
  labs(title = "Alpha Diversity: Gut vs Derm",
       x = NULL, y = "Diversity Value") +
  theme_bw(base_size = 12) +
  theme(legend.position = "bottom",
        panel.grid.minor = element_blank())

ggsave(file.path(output_dir, "alpha_diversity.png"), p_alpha,
       width = 12, height = 8, dpi = 300)
ggsave(file.path(output_dir, "alpha_diversity.pdf"), p_alpha,
       width = 12, height = 8)

cat("Alpha diversity analysis complete.\n")
