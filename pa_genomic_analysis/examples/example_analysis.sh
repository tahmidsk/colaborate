#!/bin/bash

################################################################################
# Example Analysis Script
# 
# This script demonstrates a complete analysis of P. aeruginosa isolates
# using the genomic analysis pipeline
################################################################################

# This is an example - modify paths and parameters for your analysis

# Configuration
PROJECT_NAME="PA_Clinical_Study_2025"
INPUT_DIR="raw_sequencing_data"
OUTPUT_DIR="results_${PROJECT_NAME}"
REFERENCE_GENOME="references/PAO1_reference.fasta"
THREADS=16

# Pipeline script location
PIPELINE="/path/to/pa_genomic_analysis/scripts/pa_analysis_pipeline.sh"

echo "=========================================="
echo "Pseudomonas aeruginosa Genomic Analysis"
echo "Project: ${PROJECT_NAME}"
echo "=========================================="
echo ""

# Activate conda environment
echo "Activating analysis environment..."
conda activate pa_analysis
echo ""

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Step 1: Quality Control and Assembly
echo "=========================================="
echo "Step 1: Quality Control and Assembly"
echo "=========================================="
bash "$PIPELINE" \
    -i "$INPUT_DIR" \
    -o "$OUTPUT_DIR" \
    -t "$THREADS" \
    -s qc

echo ""
echo "Step 1 completed. Review QC reports:"
echo "  firefox ${OUTPUT_DIR}/qc/trimmed/*.html"
echo ""
read -p "Press Enter to continue to Step 2..."

# Step 2: MLST and Serotyping
echo ""
echo "=========================================="
echo "Step 2: MLST and Serotyping"
echo "=========================================="
bash "$PIPELINE" \
    -i "${OUTPUT_DIR}/assembly" \
    -o "$OUTPUT_DIR" \
    -t "$THREADS" \
    -s mlst

echo ""
echo "Step 2 completed. Review typing results:"
cat "${OUTPUT_DIR}/typing_summary.txt"
echo ""
read -p "Press Enter to continue to Step 3..."

# Step 3: SNP Detection
echo ""
echo "=========================================="
echo "Step 3: SNP and Indel Detection"
echo "=========================================="

if [ -f "$REFERENCE_GENOME" ]; then
    bash "$PIPELINE" \
        -i "$INPUT_DIR" \
        -o "$OUTPUT_DIR" \
        -r "$REFERENCE_GENOME" \
        -t "$THREADS" \
        -s snp
    
    echo ""
    echo "Step 3 completed. SNP analysis results:"
    cat "${OUTPUT_DIR}/snp_analysis/snp_summary.txt"
else
    echo "Warning: Reference genome not found: $REFERENCE_GENOME"
    echo "Skipping SNP analysis"
fi

echo ""
read -p "Press Enter to continue to Step 4..."

# Step 4: Antibiotic Resistance Genes
echo ""
echo "=========================================="
echo "Step 4: Antibiotic Resistance Genes"
echo "=========================================="
bash "$PIPELINE" \
    -i "${OUTPUT_DIR}/assembly" \
    -o "$OUTPUT_DIR" \
    -t "$THREADS" \
    -s args

echo ""
echo "Step 4 completed. Resistance profile:"
head -50 "${OUTPUT_DIR}/antibiotic_resistance/resistance_profile.txt"
echo ""
read -p "Press Enter to continue to Step 5..."

# Step 5: Virulence Factors
echo ""
echo "=========================================="
echo "Step 5: Virulence Factor Identification"
echo "=========================================="
bash "$PIPELINE" \
    -i "${OUTPUT_DIR}/assembly" \
    -o "$OUTPUT_DIR" \
    -t "$THREADS" \
    -s vf

echo ""
echo "Step 5 completed. Virulence summary:"
head -50 "${OUTPUT_DIR}/virulence_factors/virulence_summary.txt"
echo ""
read -p "Press Enter to continue to Step 6..."

# Step 6: Comparative Genomics
echo ""
echo "=========================================="
echo "Step 6: Comparative Genomic Analysis"
echo "=========================================="
bash "$PIPELINE" \
    -i "${OUTPUT_DIR}/annotation" \
    -o "$OUTPUT_DIR" \
    -t "$THREADS" \
    -s comparative

echo ""
echo "Step 6 completed. Comparative analysis:"
cat "${OUTPUT_DIR}/comparative_genomics/comparative_analysis_report.txt"
echo ""

# Generate Final Report
echo ""
echo "=========================================="
echo "Generating Final Report"
echo "=========================================="

REPORT_FILE="${OUTPUT_DIR}/FINAL_REPORT_${PROJECT_NAME}.txt"

cat > "$REPORT_FILE" << EOF
================================================================================
Pseudomonas aeruginosa Genomic Analysis Report
================================================================================
Project: ${PROJECT_NAME}
Date: $(date)
Analysis Pipeline: PA Genomic Analysis v1.0

================================================================================
1. SAMPLE INFORMATION
================================================================================

Input Directory: ${INPUT_DIR}
Number of Samples: $(ls ${INPUT_DIR}/*_R1*.fastq* 2>/dev/null | wc -l)

Sample List:
$(ls ${INPUT_DIR}/*_R1*.fastq* 2>/dev/null | xargs -n 1 basename | sed 's/_R1.*//' | nl)

================================================================================
2. QUALITY CONTROL AND ASSEMBLY
================================================================================

Assembly Statistics:
$(cat ${OUTPUT_DIR}/assembly/quast_results/report.txt 2>/dev/null || echo "See quast_results/report.html")

================================================================================
3. MOLECULAR TYPING
================================================================================

MLST Results:
$(cat ${OUTPUT_DIR}/mlst/mlst_results.tsv 2>/dev/null)

Serotype Results:
$(cat ${OUTPUT_DIR}/typing_summary.txt 2>/dev/null | grep -A 20 "Serotype Results")

================================================================================
4. SNP ANALYSIS
================================================================================

$(cat ${OUTPUT_DIR}/snp_analysis/snp_summary.txt 2>/dev/null || echo "SNP analysis not performed")

================================================================================
5. ANTIBIOTIC RESISTANCE
================================================================================

$(head -100 ${OUTPUT_DIR}/antibiotic_resistance/resistance_profile.txt 2>/dev/null)

Key Findings:
- Carbapenemase genes: $(grep -i "IMP\|VIM\|KPC\|NDM\|OXA" ${OUTPUT_DIR}/antibiotic_resistance/resfinder/*_resfinder.tsv 2>/dev/null | wc -l) detected
- Aminoglycoside resistance: $(grep -i "aac\|aph\|ant" ${OUTPUT_DIR}/antibiotic_resistance/resfinder/*_resfinder.tsv 2>/dev/null | wc -l) genes
- Fluoroquinolone resistance: $(grep -i "qnr\|aac(6')-Ib-cr" ${OUTPUT_DIR}/antibiotic_resistance/resfinder/*_resfinder.tsv 2>/dev/null | wc -l) genes

================================================================================
6. VIRULENCE FACTORS
================================================================================

$(head -100 ${OUTPUT_DIR}/virulence_factors/virulence_summary.txt 2>/dev/null)

Key Virulence Factors:
- Type III Secretion System: $(grep -i "exo[STUY]\|psc" ${OUTPUT_DIR}/virulence_factors/vfdb/*_vfdb.tsv 2>/dev/null | wc -l) genes
- Exotoxin A: $(grep -i "toxA" ${OUTPUT_DIR}/virulence_factors/vfdb/*_vfdb.tsv 2>/dev/null | wc -l) detected
- Alginate production: $(grep -i "alg" ${OUTPUT_DIR}/virulence_factors/vfdb/*_vfdb.tsv 2>/dev/null | wc -l) genes

================================================================================
7. COMPARATIVE GENOMICS
================================================================================

$(cat ${OUTPUT_DIR}/comparative_genomics/pangenome/pangenome_summary.txt 2>/dev/null)

================================================================================
8. SUMMARY AND CONCLUSIONS
================================================================================

1. Molecular Epidemiology:
   - MLST types identified: $(cut -f3 ${OUTPUT_DIR}/mlst/mlst_results.tsv | tail -n +2 | sort -u | tr '\n' ',' | sed 's/,$//')
   - Phylogenetic relationships: See ${OUTPUT_DIR}/comparative_genomics/phylogenetics/core_genome.tree

2. Clinical Significance:
   - High-risk clones detected: $(grep -E "ST-?(645|773|235|111|175|654)" ${OUTPUT_DIR}/mlst/mlst_results.tsv | wc -l)
   - Multi-drug resistance: $(grep -c "." ${OUTPUT_DIR}/antibiotic_resistance/resfinder/*_resfinder.tsv | awk -F: '{s+=$2} END {printf "%.1f genes/isolate\n", s/NR}')
   - Pathogenicity: High (based on virulence factor profile)

3. Recommendations:
   - Implement infection control measures for high-risk clones
   - Consider combination therapy for MDR isolates
   - Monitor for emergence of new resistance mechanisms
   - Conduct follow-up surveillance

4. Files for Further Analysis:
   - Phylogenetic tree: ${OUTPUT_DIR}/comparative_genomics/phylogenetics/core_genome.tree
   - Pan-genome matrix: ${OUTPUT_DIR}/comparative_genomics/pangenome/gene_presence_absence.csv
   - Resistance profiles: ${OUTPUT_DIR}/antibiotic_resistance/
   - Virulence profiles: ${OUTPUT_DIR}/virulence_factors/

================================================================================
9. REFERENCES
================================================================================

- FastQC: Andrews, 2010
- FastP: Chen et al., 2018
- SPAdes: Prjibelski et al., 2020
- Quast: Gurevich et al., 2013
- Prokka: Seemann, 2014
- Kraken: Wood & Salzberg, 2014
- MLST: Jolley & Maiden, 2010
- PAst: Zhao et al., 2023
- Snippy: Seemann, 2015
- ResFinder: Florensa et al., 2022
- CARD: Alcock et al., 2023
- ABRicate: Seemann, 2020
- VFDB: Chen et al., 2016
- Roary: Page et al., 2015
- Parsnp: Rhoads et al., 2024
- iTOL: Letunic & Bork, 2021

================================================================================
END OF REPORT
================================================================================
EOF

echo ""
echo "=========================================="
echo "Analysis Complete!"
echo "=========================================="
echo ""
echo "Results directory: ${OUTPUT_DIR}"
echo "Final report: ${REPORT_FILE}"
echo ""
echo "Next steps:"
echo "1. Review the final report: cat ${REPORT_FILE}"
echo "2. Visualize phylogenetic tree in iTOL"
echo "3. Compare with PathogenWatch database"
echo "4. Generate publication figures"
echo ""
echo "To view the report:"
echo "  cat ${REPORT_FILE}"
echo ""
echo "To visualize the tree:"
echo "  Upload ${OUTPUT_DIR}/comparative_genomics/phylogenetics/core_genome.tree to https://itol.embl.de/"
echo ""
