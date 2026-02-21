###############################################################################
# 03_relative_abundance.R
# Section 3.3: Relative Abundance Transformation
#
# Transform raw counts to relative abundances (percentages).
#
# Input:  results/phyloseq_filtered.rds
# Output: results/phyloseq_relabund.rds
###############################################################################

# ---- Load Libraries ---------------------------------------------------------
library(phyloseq)

# ---- Load Filtered Data -----------------------------------------------------
physeq_filt <- readRDS("results/phyloseq_filtered.rds")

# ---- Relative Abundance Transformation -------------------------------------
# Divide each ASV count by the sample total and multiply by 100
physeq_rel <- transform_sample_counts(physeq_filt, function(x) (x / sum(x)) * 100)

# Verify transformation
cat("=== Relative Abundance Transformation ===\n")
cat("Sample sums after transformation (should all be 100):\n")
print(round(sample_sums(physeq_rel), 2))

# ---- Save -------------------------------------------------------------------
saveRDS(physeq_rel, "results/phyloseq_relabund.rds")
cat("\nRelative abundance phyloseq saved to: results/phyloseq_relabund.rds\n")
