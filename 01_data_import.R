###############################################################################
# 01_data_import.R
# Section 3.1.3: Data Import and Phyloseq Object Construction
#
# Import QIIME2 artifacts into R and construct a phyloseq object.
#
# Required input files (from QIIME2 pipeline):
#   - feature-table.qza    (ASV feature table)
#   - rooted-tree.qza      (rooted phylogenetic tree)
#   - taxonomy.qza         (taxonomy classifications)
#   - metadata.tsv         (sample metadata)
#
# Output:
#   - phyloseq object saved as "phyloseq_raw.rds"
###############################################################################

# ---- Load Libraries ---------------------------------------------------------
library(qiime2R)
library(phyloseq)

# ---- Set File Paths ---------------------------------------------------------
# Update these paths to match your QIIME2 output directory
qiime2_dir <- "qiime2_output"

feature_table_path <- file.path(qiime2_dir, "feature-table.qza")
rooted_tree_path   <- file.path(qiime2_dir, "rooted-tree.qza")
taxonomy_path      <- file.path(qiime2_dir, "taxonomy.qza")
metadata_path      <- "metadata.tsv"

# ---- Verify Input Files Exist -----------------------------------------------
required_files <- c(feature_table_path, rooted_tree_path,
                    taxonomy_path, metadata_path)

missing <- required_files[!file.exists(required_files)]
if (length(missing) > 0) {
  stop("Missing required input files:\n  ",
       paste(missing, collapse = "\n  "),
       "\nPlease ensure all QIIME2 output files and metadata are in place.")
}

# ---- Import QIIME2 Artifacts and Build Phyloseq Object ----------------------
physeq <- qza_to_phyloseq(
  features = feature_table_path,
  tree     = rooted_tree_path,
  taxonomy = taxonomy_path,
  metadata = metadata_path
)

# ---- Quick Summary -----------------------------------------------------------
cat("Phyloseq object created successfully\n")
cat("Number of ASVs   :", ntaxa(physeq), "\n")
cat("Number of samples:", nsamples(physeq), "\n")
cat("Sample variables :", paste(sample_variables(physeq), collapse = ", "), "\n")
cat("Taxonomic ranks  :", paste(rank_names(physeq), collapse = ", "), "\n")

# ---- Save Raw Phyloseq Object -----------------------------------------------
output_dir <- "results"
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

saveRDS(physeq, file.path(output_dir, "phyloseq_raw.rds"))
cat("Raw phyloseq object saved to:", file.path(output_dir, "phyloseq_raw.rds"), "\n")
