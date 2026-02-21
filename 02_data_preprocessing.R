###############################################################################
# 02_data_preprocessing.R
# Sections 3.2.1 – 3.2.4: Data Quality Assessment and Preprocessing
#
# Steps:
#   1. Initial data assessment (library sizes, taxonomic overview)
#   2. Taxonomic filtering – keep only Kingdom "d__Bacteria"
#   3. Mitochondria and chloroplast removal
#   4. Prevalence-based filtering (taxa in >= 2 samples)
#
# Input:  results/phyloseq_raw.rds
# Output: results/phyloseq_filtered.rds
###############################################################################

# ---- Load Libraries ---------------------------------------------------------
library(phyloseq)
library(ggplot2)

# ---- Load Data --------------------------------------------------------------
physeq <- readRDS("results/phyloseq_raw.rds")

# ---- 3.2.1 Initial Data Assessment -----------------------------------------
cat("=== Initial Data Assessment ===\n")
cat("Total ASVs   :", ntaxa(physeq), "\n")
cat("Total samples:", nsamples(physeq), "\n")

# Library sizes
lib_sizes <- sample_sums(physeq)
cat("\nLibrary sizes:\n")
print(summary(lib_sizes))

# Kingdom-level overview
cat("\nKingdom-level distribution:\n")
print(table(tax_table(physeq)[, "Kingdom"], useNA = "ifany"))

# Family-level overview (potential contaminants)
cat("\nTop 20 Families by total abundance:\n")
fam_sums <- tapply(taxa_sums(physeq), tax_table(physeq)[, "Family"], sum)
print(head(sort(fam_sums, decreasing = TRUE), 20))

# Library size plot
output_dir <- "results/figures"
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

lib_df <- data.frame(
  Sample    = names(lib_sizes),
  LibSize   = as.numeric(lib_sizes)
)

p_lib <- ggplot(lib_df, aes(x = reorder(Sample, LibSize), y = LibSize)) +
  geom_bar(stat = "identity", fill = "steelblue") +
  coord_flip() +
  labs(title = "Library Sizes per Sample",
       x = "Sample", y = "Number of Reads") +
  theme_minimal(base_size = 12)

ggsave(file.path(output_dir, "library_sizes.png"), p_lib,
       width = 8, height = 6, dpi = 300)
ggsave(file.path(output_dir, "library_sizes.pdf"), p_lib,
       width = 8, height = 6)

# ---- 3.2.2 Taxonomic Filtering – Bacteria Only -----------------------------
physeq_bac <- subset_taxa(physeq, Kingdom == "d__Bacteria")
cat("\nAfter bacterial filtering:\n")
cat("  ASVs   :", ntaxa(physeq_bac), "\n")
cat("  Samples:", nsamples(physeq_bac), "\n")

# ---- 3.2.3 Remove Mitochondria and Chloroplast Sequences -------------------
physeq_clean <- subset_taxa(physeq_bac,
                            (is.na(Family) | Family != "Mitochondria") &
                            (is.na(Family) | Family != "Chloroplast"))
cat("\nAfter mitochondria/chloroplast removal:\n")
cat("  ASVs   :", ntaxa(physeq_clean), "\n")
cat("  Samples:", nsamples(physeq_clean), "\n")

# ---- 3.2.4 Prevalence-Based Filtering (>= 2 samples) -----------------------
physeq_filt <- filter_taxa(physeq_clean, function(x) sum(x > 0) >= 2, TRUE)
cat("\nAfter prevalence filtering (>= 2 samples):\n")
cat("  ASVs   :", ntaxa(physeq_filt), "\n")
cat("  Samples:", nsamples(physeq_filt), "\n")

# ---- Save Filtered Phyloseq Object -----------------------------------------
saveRDS(physeq_filt, "results/phyloseq_filtered.rds")
cat("\nFiltered phyloseq object saved to: results/phyloseq_filtered.rds\n")
