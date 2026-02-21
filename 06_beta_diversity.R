###############################################################################
# 06_beta_diversity.R
# Section 3.6: Beta Diversity Analysis
#
# Steps:
#   1. Bray-Curtis dissimilarity matrix
#   2. PCoA ordination
#   3. PERMANOVA (adonis2, 999 permutations)
#   4. PCoA plot with 95% confidence ellipses and PERMANOVA results
#
# Input:  results/phyloseq_filtered.rds
# Output: results/figures/beta_diversity_pcoa.{png,pdf}
###############################################################################

# ---- Load Libraries ---------------------------------------------------------
library(phyloseq)
library(vegan)
library(ggplot2)

# ---- Load Data --------------------------------------------------------------
physeq <- readRDS("results/phyloseq_filtered.rds")

output_dir <- "results/figures"
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

# ---- Bray-Curtis Dissimilarity & PCoA ---------------------------------------
bray_dist <- phyloseq::distance(physeq, method = "bray")
pcoa_res  <- ordinate(physeq, method = "PCoA", distance = bray_dist)

# ---- PERMANOVA --------------------------------------------------------------
meta <- data.frame(sample_data(physeq))
perm_res <- adonis2(bray_dist ~ Group, data = meta, permutations = 999)

cat("=== PERMANOVA Results ===\n")
print(perm_res)

r2_val <- round(perm_res$R2[1], 4)
p_val  <- perm_res$`Pr(>F)`[1]

# ---- PCoA Plot with Ellipses and PERMANOVA Annotation -----------------------
pcoa_df <- data.frame(pcoa_res$vectors[, 1:2])
colnames(pcoa_df) <- c("Axis1", "Axis2")
pcoa_df$Sample <- rownames(pcoa_df)
pcoa_df$Group  <- meta$Group[match(pcoa_df$Sample, rownames(meta))]

eig_vals <- pcoa_res$values$Eigenvalues
var_explained <- round(100 * eig_vals / sum(eig_vals), 1)

annotation_label <- paste0("PERMANOVA: R² = ", r2_val,
                           ", p = ", p_val)

p_pcoa <- ggplot(pcoa_df, aes(x = Axis1, y = Axis2,
                               color = Group, shape = Group)) +
  geom_point(size = 3, alpha = 0.8) +
  stat_ellipse(level = 0.95, linetype = "dashed") +
  labs(title = "PCoA – Bray-Curtis Dissimilarity",
       x = paste0("PCoA Axis 1 (", var_explained[1], "%)"),
       y = paste0("PCoA Axis 2 (", var_explained[2], "%)")) +
  annotate("text", x = Inf, y = -Inf, label = annotation_label,
           hjust = 1.1, vjust = -0.5, size = 3.5) +
  theme_bw(base_size = 14) +
  theme(panel.grid.minor = element_blank(),
        legend.position = "bottom")

ggsave(file.path(output_dir, "beta_diversity_pcoa.png"), p_pcoa,
       width = 8, height = 7, dpi = 600)
ggsave(file.path(output_dir, "beta_diversity_pcoa.pdf"), p_pcoa,
       width = 8, height = 7)

cat("Beta diversity analysis complete.\n")
