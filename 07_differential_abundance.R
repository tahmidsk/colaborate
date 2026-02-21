###############################################################################
# 07_differential_abundance.R
# Section 3.7: Differential Abundance Analysis (DESeq2)
#
# Steps:
#   1. Genus-level agglomeration on raw counts
#   2. Remove genera with < 10 total reads
#   3. DESeq2 analysis (Derm = reference, Gut = comparison)
#   4. Volcano plot
#   5. Bar plot of significant genera
#
# Input:  results/phyloseq_filtered.rds
# Output: results/deseq2_results.csv, figures
###############################################################################

# ---- Load Libraries ---------------------------------------------------------
library(phyloseq)
library(DESeq2)
library(ggplot2)
library(dplyr)

# ---- Load Data (raw counts) ------------------------------------------------
physeq <- readRDS("results/phyloseq_filtered.rds")

output_dir <- "results/figures"
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

# ---- 3.7.1 Preprocessing: genus agglomeration + abundance filter -----------
physeq_genus <- tax_glom(physeq, taxrank = "Genus")

# Remove genera with < 10 total reads across all samples
physeq_genus <- prune_taxa(taxa_sums(physeq_genus) >= 10, physeq_genus)

cat("Genera retained after filtering:", ntaxa(physeq_genus), "\n")

# ---- 3.7.2 DESeq2 Analysis -------------------------------------------------
# Set Derm as reference level so positive log2FC = higher in Gut
sample_data(physeq_genus)$Group <- factor(
  sample_data(physeq_genus)$Group, levels = c("Derm", "Gut")
)

# Convert phyloseq to DESeq2 dataset
dds <- phyloseq_to_deseq2(physeq_genus, ~ Group)

# Run DESeq2 (Wald test, default shrinkage)
dds <- DESeq(dds, test = "Wald", fitType = "parametric")

# Extract results with BH correction
res <- results(dds, cooksCutoff = FALSE, alpha = 0.05)
res_df <- as.data.frame(res)

# Add genus names
res_df$Genus <- tax_table(physeq_genus)[rownames(res_df), "Genus"]
res_df <- res_df[order(res_df$padj), ]

cat("\n=== DESeq2 Results Summary ===\n")
cat("Total genera tested:", nrow(res_df), "\n")
cat("Significant (FDR < 0.05):", sum(res_df$padj < 0.05, na.rm = TRUE), "\n")
print(head(res_df, 20))

write.csv(res_df, "results/deseq2_results.csv", row.names = TRUE)

# ---- 3.7.3 Volcano Plot ----------------------------------------------------
res_df$Significant <- ifelse(!is.na(res_df$padj) & res_df$padj < 0.05 &
                             abs(res_df$log2FoldChange) >= 1,
                             "Significant", "Not Significant")

p_volcano <- ggplot(res_df, aes(x = log2FoldChange, y = -log10(padj),
                                 color = Significant)) +
  geom_point(alpha = 0.7, size = 2) +
  scale_color_manual(values = c("Not Significant" = "grey60",
                                 "Significant"     = "red")) +
  geom_vline(xintercept = c(-1, 1), linetype = "dashed", color = "blue") +
  geom_hline(yintercept = -log10(0.05), linetype = "dashed", color = "blue") +
  labs(title = "Volcano Plot – Differential Abundance (Gut vs Derm)",
       x = "log2 Fold Change",
       y = "-log10(adjusted p-value)") +
  theme_bw(base_size = 12) +
  theme(panel.grid.minor = element_blank(),
        legend.position = "bottom")

ggsave(file.path(output_dir, "deseq2_volcano.png"), p_volcano,
       width = 8, height = 6, dpi = 300)
ggsave(file.path(output_dir, "deseq2_volcano.pdf"), p_volcano,
       width = 8, height = 6)

# ---- Bar Plot of Significant Genera -----------------------------------------
sig_df <- res_df %>%
  filter(!is.na(padj), padj < 0.05, abs(log2FoldChange) >= 1) %>%
  arrange(log2FoldChange)

if (nrow(sig_df) > 0) {
  sig_df$Direction <- ifelse(sig_df$log2FoldChange > 0,
                             "Enriched in Gut", "Enriched in Derm")

  p_bar <- ggplot(sig_df, aes(x = reorder(Genus, log2FoldChange),
                               y = log2FoldChange, fill = Direction)) +
    geom_bar(stat = "identity") +
    coord_flip() +
    scale_fill_manual(values = c("Enriched in Gut"  = "steelblue",
                                  "Enriched in Derm" = "coral")) +
    labs(title = "Significantly Differentially Abundant Genera",
         x = "Genus", y = "log2 Fold Change") +
    theme_bw(base_size = 12) +
    theme(panel.grid.minor = element_blank(),
          legend.position = "bottom")

  ggsave(file.path(output_dir, "deseq2_significant_genera.png"), p_bar,
         width = 8, height = max(4, nrow(sig_df) * 0.35), dpi = 300)
  ggsave(file.path(output_dir, "deseq2_significant_genera.pdf"), p_bar,
         width = 8, height = max(4, nrow(sig_df) * 0.35))
} else {
  cat("No genera met the significance and fold-change thresholds.\n")
}

cat("\nDifferential abundance analysis complete.\n")
