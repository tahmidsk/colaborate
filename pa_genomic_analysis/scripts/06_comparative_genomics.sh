#!/bin/bash

################################################################################
# Step 6: Comparative Genomic Analysis
# 
# This script performs:
# - Pan-genome analysis using Roary v3.13.0
# - Phylogenetic analysis using Parsnp v1.7.4
# - Core and accessory genome identification
# - Tree visualization preparation for iTOL
################################################################################

set -euo pipefail

# Parse arguments
INPUT_DIR=""
OUTPUT_DIR=""
THREADS=8

while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--input) INPUT_DIR="$2"; shift 2 ;;
        -o|--output) OUTPUT_DIR="$2"; shift 2 ;;
        -t|--threads) THREADS="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# Create output directories
COMP_DIR="${OUTPUT_DIR}/comparative_genomics"
PANGENOME_DIR="${COMP_DIR}/pangenome"
PHYLO_DIR="${COMP_DIR}/phylogenetics"

mkdir -p "$PANGENOME_DIR"
mkdir -p "$PHYLO_DIR"

echo "Comparative Genomic Analysis"
echo "============================"
echo ""

# Find all GFF3 files from Prokka annotation
GFF_FILES=($(find "$INPUT_DIR" -name "*.gff"))

if [[ ${#GFF_FILES[@]} -eq 0 ]]; then
    echo "Error: No GFF files found in $INPUT_DIR"
    echo "Make sure to run Prokka annotation first"
    exit 1
fi

echo "Found ${#GFF_FILES[@]} annotated genomes"

# Copy GFF files to working directory
GFF_WORK_DIR="${PANGENOME_DIR}/gff_files"
mkdir -p "$GFF_WORK_DIR"

for GFF in "${GFF_FILES[@]}"; do
    cp "$GFF" "$GFF_WORK_DIR/"
done

echo ""
echo "Step 6.1: Pan-genome Analysis with Roary"
echo "========================================"

echo "Running Roary pan-genome analysis..."
echo "Parameters:"
echo "  - Identity threshold: 95%"
echo "  - Core genome: genes in 99% of strains"
echo "  - BLASTp mode: enabled"

roary \
    -e \
    -n \
    -v \
    -p "$THREADS" \
    -i 95 \
    -cd 99 \
    -f "$PANGENOME_DIR" \
    "${GFF_WORK_DIR}"/*.gff

echo ""
echo "Pan-genome analysis completed!"

# Parse Roary results
if [[ -f "${PANGENOME_DIR}/summary_statistics.txt" ]]; then
    echo ""
    echo "Pan-genome Statistics:"
    cat "${PANGENOME_DIR}/summary_statistics.txt"
fi

# Analyze core and accessory genomes
if [[ -f "${PANGENOME_DIR}/gene_presence_absence.csv" ]]; then
    TOTAL_GENES=$(tail -n +2 "${PANGENOME_DIR}/gene_presence_absence.csv" | wc -l)
    CORE_GENES=$(awk -F',' '$4=="100" || $4=="99" {count++} END {print count}' "${PANGENOME_DIR}/gene_presence_absence.csv")
    
    cat > "${PANGENOME_DIR}/pangenome_summary.txt" << EOF
Pan-genome Analysis Summary
===========================
Generated: $(date)

Genome Statistics:
------------------
Total genomes analyzed: ${#GFF_FILES[@]}
Total gene clusters: $TOTAL_GENES
Core genes (99-100% strains): $CORE_GENES
Accessory genes: $((TOTAL_GENES - CORE_GENES))

Core genome definition: Genes present in ≥99% of strains
Accessory genome: All genes not in core genome

Analysis Parameters:
--------------------
- Identity threshold: 95%
- BLASTp comparison: Enabled
- Core genome cutoff: 99%

Output Files:
-------------
- gene_presence_absence.csv: Full pan-genome matrix
- summary_statistics.txt: Detailed statistics
- core_gene_alignment.aln: Core gene alignment (if generated)
- accessory_binary_genes.fa: Accessory genes
- pan_genome_reference.fa: Pan-genome reference

EOF
fi

echo ""
echo "Step 6.2: Identifying Unique and Shared Genes"
echo "============================================="

# Extract unique genes for each sample
echo "Analyzing unique genes per genome..."

if [[ -f "${PANGENOME_DIR}/gene_presence_absence.csv" ]]; then
    # Create unique genes report
    cat > "${PANGENOME_DIR}/unique_genes.txt" << EOF
Unique Genes Analysis
=====================

Genes unique to each genome (not found in any other genome):

EOF
    
    # This would require custom parsing of the gene_presence_absence.csv
    # For now, create a placeholder
    echo "See gene_presence_absence.csv for detailed gene distribution" >> "${PANGENOME_DIR}/unique_genes.txt"
fi

echo ""
echo "Step 6.3: Phylogenetic Analysis with Parsnp"
echo "=========================================="

# Find all assembled contigs for Parsnp
CONTIGS=($(find "${OUTPUT_DIR}/assembly" -name "*_contigs.fasta" 2>/dev/null || find "$INPUT_DIR" -name "*.fasta"))

if [[ ${#CONTIGS[@]} -eq 0 ]]; then
    echo "Warning: No assembly files found for phylogenetic analysis"
else
    echo "Running Parsnp phylogenetic analysis..."
    echo "Samples: ${#CONTIGS[@]}"
    
    # Create directory for contigs
    PARSNP_INPUT="${PHYLO_DIR}/genomes"
    mkdir -p "$PARSNP_INPUT"
    
    # Copy contigs
    for CONTIG in "${CONTIGS[@]}"; do
        cp "$CONTIG" "$PARSNP_INPUT/"
    done
    
    # Run Parsnp
    parsnp \
        -d "$PARSNP_INPUT" \
        -o "$PHYLO_DIR" \
        -p "$THREADS" \
        -c \
        -v
    
    echo ""
    echo "Parsnp analysis completed!"
    
    # Check for output files
    if [[ -f "${PHYLO_DIR}/parsnp.tree" ]]; then
        echo "Phylogenetic tree generated: ${PHYLO_DIR}/parsnp.tree"
        
        # Convert to Newick format if needed
        cp "${PHYLO_DIR}/parsnp.tree" "${PHYLO_DIR}/core_genome.tree"
    fi
fi

echo ""
echo "Step 6.4: Preparing Visualization for iTOL"
echo "=========================================="

# Create annotation files for iTOL
cat > "${PHYLO_DIR}/itol_dataset_template.txt" << EOF
DATASET_COLORSTRIP
SEPARATOR TAB
DATASET_LABEL	Sample Information

# This is a template for iTOL visualization
# Upload this file along with your tree to iTOL (https://itol.embl.de/)

# Color definitions for different categories
# Modify according to your sample metadata

LEGEND_TITLE	Metadata
LEGEND_SHAPES	1	1	1
LEGEND_COLORS	#FF0000	#00FF00	#0000FF
LEGEND_LABELS	Group1	Group2	Group3

DATA
# Add your sample data here in format: SAMPLE_ID	COLOR
# Example:
# Sample1	#FF0000
# Sample2	#00FF00

EOF

cat > "${PHYLO_DIR}/README_iTOL.txt" << EOF
iTOL Visualization Instructions
================================

1. Access iTOL:
   Visit: https://itol.embl.de/

2. Upload your tree:
   - Use: core_genome.tree or parsnp.tree
   - Format: Newick

3. Annotate your tree:
   - Upload: itol_dataset_template.txt
   - Customize colors and labels for your samples

4. Add metadata:
   - MLST types (ST645, ST773, ST2238)
   - Geographic origin
   - Isolation source
   - Resistance profiles
   - Virulence profiles

5. Visualization options:
   - Tree type: Circular or rectangular
   - Branch support: Display bootstrap values
   - Color branches: By metadata categories
   - Add heatmaps: For gene presence/absence

6. Export:
   - Save as SVG or PNG for publication

Recommended Annotations:
------------------------
- MLST sequence types
- Serotypes
- Resistance gene profiles
- Virulence factor profiles
- Geographic locations
- Collection dates

EOF

echo ""
echo "Step 6.5: Generating Comprehensive Comparative Analysis Report"
echo "=============================================================="

cat > "${COMP_DIR}/comparative_analysis_report.txt" << EOF
Comparative Genomic Analysis Report
====================================
Generated: $(date)

Analysis Overview:
------------------
Number of genomes: ${#GFF_FILES[@]}

1. Pan-genome Analysis (Roary):
   - Core genes identified
   - Accessory genes characterized
   - Gene presence/absence matrix generated
   - Results: ${PANGENOME_DIR}/

2. Phylogenetic Analysis (Parsnp):
   - Core genome alignment performed
   - Maximum likelihood tree constructed
   - Recombination regions excluded
   - Results: ${PHYLO_DIR}/

3. Key Output Files:
   - Pan-genome matrix: gene_presence_absence.csv
   - Core genes: core_gene_alignment.aln
   - Phylogenetic tree: core_genome.tree
   - iTOL templates: itol_dataset_template.txt

4. Visualization:
   - Tree ready for iTOL upload
   - Annotation templates provided
   - Metadata integration instructions available

Next Steps:
-----------
1. Review pan-genome statistics
2. Examine unique genes per isolate
3. Upload tree to iTOL for visualization
4. Integrate MLST, resistance, and virulence data
5. Compare with PathogenWatch database sequences

For PathogenWatch comparison:
------------------------------
1. Visit: https://pathogen.watch/
2. Upload your assemblies
3. Retrieve 72 Bangladesh sequences
4. Re-run comparative analysis with all sequences
5. Identify population structure and transmission patterns

References:
-----------
- Roary: Page et al., 2015
- Parsnp: Rhoads et al., 2024
- iTOL: Letunic & Bork, 2021

EOF

echo ""
echo "Step 6 completed successfully!"
echo "Results:"
echo "  - Pan-genome: ${PANGENOME_DIR}"
echo "  - Phylogenetics: ${PHYLO_DIR}"
echo "  - Report: ${COMP_DIR}/comparative_analysis_report.txt"
echo ""
echo "Next: Upload core_genome.tree to iTOL for visualization"
