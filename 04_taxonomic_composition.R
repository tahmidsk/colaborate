###############################################################################
# 04_taxonomic_composition.R
# Sections 3.4.1 – 3.4.6: Taxonomic Composition Analysis
#
# Steps:
#   1. Phylum-level composition (stacked bar plot)
#   2. Family-level composition (top 15, stacked bar plot)
#   3. Genus-level composition (top 15, stacked bar plot)
#   4. Genus-level statistical comparison (top 25, Wilcoxon + Cliff's Delta)
#   5. Summary statistics table
#
# Input:  results/phyloseq_relabund.rds
# Output: figures and summary tables in results/
###############################################################################

# ---- Load Libraries ---------------------------------------------------------
library(phyloseq)
library(ggplot2)
library(dplyr)
library(tidyr)
library(ggpubr)
library(effsize)
library(scales)

# ---- Load Data --------------------------------------------------------------
physeq_rel <- readRDS("results/phyloseq_relabund.rds")

output_dir <- "results/figures"
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

# ---- Helper: Save Plot in PNG and PDF ---------------------------------------
save_plot <- function(plot, filename, width = 10, height = 7) {
  ggsave(file.path(output_dir, paste0(filename, ".png")), plot,
         width = width, height = height, dpi = 300)
  ggsave(file.path(output_dir, paste0(filename, ".pdf")), plot,
         width = width, height = height)
}

###############################################################################
# 3.4.2  Phylum-Level Analysis
###############################################################################
physeq_phylum <- tax_glom(physeq_rel, taxrank = "Phylum")
phylum_df     <- psmelt(physeq_phylum)

p_phylum <- ggplot(phylum_df, aes(x = Sample, y = Abundance, fill = Phylum)) +
  geom_bar(stat = "identity", position = "fill") +
  facet_wrap(~ Group, scales = "free_x") +
  scale_y_continuous(labels = percent_format()) +
  labs(title = "Phylum-Level Relative Abundance",
       x = "Sample", y = "Relative Abundance (%)") +
  theme_minimal(base_size = 12) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

save_plot(p_phylum, "phylum_composition")

###############################################################################
# 3.4.3  Family-Level Analysis (Top 15)
###############################################################################
physeq_family <- tax_glom(physeq_rel, taxrank = "Family")
top15_family  <- names(sort(taxa_sums(physeq_family), decreasing = TRUE))[1:15]
physeq_fam15  <- prune_taxa(top15_family, physeq_family)
family_df     <- psmelt(physeq_fam15)

p_family <- ggplot(family_df, aes(x = Sample, y = Abundance, fill = Family)) +
  geom_bar(stat = "identity", position = "fill") +
  facet_wrap(~ Group, scales = "free_x") +
  scale_y_continuous(labels = percent_format()) +
  labs(title = "Top 15 Families – Relative Abundance",
       x = "Sample", y = "Relative Abundance (%)") +
  theme_minimal(base_size = 12) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

save_plot(p_family, "family_composition_top15")

###############################################################################
# 3.4.4  Genus-Level Compositional Analysis (Top 15)
###############################################################################
physeq_genus <- tax_glom(physeq_rel, taxrank = "Genus")
top15_genus  <- names(sort(taxa_sums(physeq_genus), decreasing = TRUE))[1:15]
physeq_gen15 <- prune_taxa(top15_genus, physeq_genus)
genus_df     <- psmelt(physeq_gen15)

p_genus <- ggplot(genus_df, aes(x = Sample, y = Abundance, fill = Genus)) +
  geom_bar(stat = "identity", position = "fill") +
  facet_wrap(~ Group, scales = "free_x") +
  scale_y_continuous(labels = percent_format()) +
  labs(title = "Top 15 Genera – Relative Abundance",
       x = "Sample", y = "Relative Abundance (%)") +
  theme_minimal(base_size = 12) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

save_plot(p_genus, "genus_composition_top15")

###############################################################################
# 3.4.4  Genus-Level Statistical Comparison (Top 25)
###############################################################################
top25_genus  <- names(sort(taxa_sums(physeq_genus), decreasing = TRUE))[1:25]
physeq_gen25 <- prune_taxa(top25_genus, physeq_genus)
genus25_df   <- psmelt(physeq_gen25)

# ---- 3.4.4.1 Statistical Analysis ------------------------------------------
# Wilcoxon rank-sum test + Cliff's Delta for each genus

genera_list <- unique(genus25_df$Genus)

stat_results <- do.call(rbind, lapply(genera_list, function(g) {
  sub <- genus25_df[genus25_df$Genus == g, ]
  gut  <- sub$Abundance[sub$Group == "Gut"]
  derm <- sub$Abundance[sub$Group == "Derm"]

  # Wilcoxon rank-sum test
  wt <- wilcox.test(gut, derm, exact = FALSE)

  # Cliff's Delta effect size
  cd <- cliff.delta(gut, derm)

  data.frame(
    Genus       = g,
    p_value     = wt$p.value,
    cliff_delta = cd$estimate,
    effect_size = as.character(cd$magnitude),
    stringsAsFactors = FALSE
  )
}))

# Benjamini-Hochberg correction
stat_results$p_adjusted <- p.adjust(stat_results$p_value, method = "BH")

# Significance notation
stat_results$significance <- ifelse(stat_results$p_adjusted < 0.001, "***",
                             ifelse(stat_results$p_adjusted < 0.01,  "**",
                             ifelse(stat_results$p_adjusted < 0.05,  "*", "NS")))

cat("=== Genus-Level Statistical Comparisons (Top 25) ===\n")
print(stat_results)

write.csv(stat_results, "results/genus_statistical_comparisons.csv",
          row.names = FALSE)

# ---- Box Plots with Statistical Annotation ----------------------------------
genus_plots <- lapply(genera_list, function(g) {
  sub <- genus25_df[genus25_df$Genus == g, ]
  ggplot(sub, aes(x = Group, y = Abundance, fill = Group)) +
    geom_boxplot(outlier.shape = NA, alpha = 0.7) +
    geom_jitter(width = 0.2, size = 1.5, alpha = 0.8) +
    stat_compare_means(method = "wilcox.test", label = "p.format",
                       label.x.npc = "center") +
    labs(title = g, x = NULL, y = "Relative Abundance (%)") +
    theme_bw(base_size = 10) +
    theme(legend.position = "none",
          panel.grid.minor = element_blank())
})

# Combine into multi-panel figure
library(gridExtra)
p_genus_stat <- marrangeGrob(genus_plots, nrow = 5, ncol = 5, top = NULL)

ggsave(file.path(output_dir, "genus_statistical_boxplots.png"),
       p_genus_stat, width = 20, height = 20, dpi = 300)
ggsave(file.path(output_dir, "genus_statistical_boxplots.pdf"),
       p_genus_stat, width = 20, height = 20)

###############################################################################
# 3.4.5  Summary Calculations
###############################################################################
summary_stats <- genus25_df %>%
  group_by(Group, Genus) %>%
  summarise(
    n      = n(),
    mean   = mean(Abundance),
    median = median(Abundance),
    sd     = sd(Abundance),
    min    = min(Abundance),
    max    = max(Abundance),
    .groups = "drop"
  )

cat("\n=== Summary Statistics (Top 25 Genera) ===\n")
print(as.data.frame(summary_stats))

write.csv(summary_stats, "results/genus_summary_statistics.csv",
          row.names = FALSE)

cat("\nTaxonomic composition analysis complete.\n")
