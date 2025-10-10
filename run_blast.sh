#!/bin/bash
# BLAST Command Line Script for Chikungunya and Zika Virus Genomes
# This script demonstrates how to run BLAST on viral genome sequences

echo "================================================"
echo "BLAST Analysis for Viral Genomes"
echo "4 Chikungunya and 1 Zika virus sequences"
echo "================================================"
echo ""

# Set directories
SEQUENCE_DIR="sequences"
RESULTS_DIR="blast_results"
DB_DIR="blast_db"

# Create necessary directories
mkdir -p "$RESULTS_DIR"
mkdir -p "$DB_DIR"

# Check if BLAST is installed
if ! command -v blastn &> /dev/null; then
    echo "ERROR: BLAST+ is not installed!"
    echo "Please install BLAST+ using one of the following methods:"
    echo ""
    echo "Ubuntu/Debian:"
    echo "  sudo apt-get update"
    echo "  sudo apt-get install ncbi-blast+"
    echo ""
    echo "macOS (with Homebrew):"
    echo "  brew install blast"
    echo ""
    echo "Or download from: https://blast.ncbi.nlm.nih.gov/Blast.cgi?PAGE_TYPE=BlastDocs&DOC_TYPE=Download"
    exit 1
fi

echo "Step 1: Combining all sequences into a single file..."
cat "$SEQUENCE_DIR"/*.fasta > "$DB_DIR/all_sequences.fasta"
echo "✓ Combined sequences file created: $DB_DIR/all_sequences.fasta"
echo ""

echo "Step 2: Creating BLAST database..."
makeblastdb -in "$DB_DIR/all_sequences.fasta" \
            -dbtype nucl \
            -out "$DB_DIR/viral_genomes" \
            -parse_seqids \
            -title "Chikungunya and Zika Virus Genomes"
echo "✓ BLAST database created"
echo ""

echo "Step 3: Running BLAST queries..."
echo ""

# Function to run BLAST and format output
run_blast() {
    local query_file=$1
    local query_name=$(basename "$query_file" .fasta)
    local output_file="$RESULTS_DIR/${query_name}_blast_results.txt"
    local output_xml="$RESULTS_DIR/${query_name}_blast_results.xml"
    
    echo "Running BLAST for: $query_name"
    
    # Standard tabular output
    blastn -query "$query_file" \
           -db "$DB_DIR/viral_genomes" \
           -out "$output_file" \
           -outfmt "6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore" \
           -max_target_seqs 10
    
    # XML output for detailed analysis
    blastn -query "$query_file" \
           -db "$DB_DIR/viral_genomes" \
           -out "$output_xml" \
           -outfmt 5 \
           -max_target_seqs 10
    
    echo "  ✓ Results saved to: $output_file"
    echo "  ✓ XML results saved to: $output_xml"
    echo ""
}

# Run BLAST for each sequence
for fasta_file in "$SEQUENCE_DIR"/*.fasta; do
    run_blast "$fasta_file"
done

echo "Step 4: Running comparative analysis - Chikungunya vs Zika..."
# Compare all Chikungunya sequences against Zika
cat "$SEQUENCE_DIR"/chikungunya_*.fasta > "$RESULTS_DIR/all_chikungunya.fasta"

blastn -query "$RESULTS_DIR/all_chikungunya.fasta" \
       -subject "$SEQUENCE_DIR/zika_1.fasta" \
       -out "$RESULTS_DIR/chikungunya_vs_zika.txt" \
       -outfmt "7 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore"

echo "✓ Comparative analysis complete: $RESULTS_DIR/chikungunya_vs_zika.txt"
echo ""

echo "Step 5: Generating summary report..."
cat > "$RESULTS_DIR/analysis_summary.txt" << EOF
BLAST Analysis Summary
=====================
Date: $(date)

Input Files:
- 4 Chikungunya genome sequences
- 1 Zika genome sequence

Database:
- Location: $DB_DIR/viral_genomes
- Type: Nucleotide

Output Files Generated:
$(ls -1 "$RESULTS_DIR"/*.txt "$RESULTS_DIR"/*.xml 2>/dev/null | sed 's/^/- /')

Next Steps:
1. Review individual BLAST results in blast_results/
2. Analyze the comparative analysis (chikungunya_vs_zika.txt)
3. Consider using blastn with different parameters:
   - Adjust e-value threshold with -evalue
   - Modify word size with -word_size
   - Change output format with -outfmt

For more information, run: blastn -help
EOF

cat "$RESULTS_DIR/analysis_summary.txt"
echo ""
echo "================================================"
echo "BLAST Analysis Complete!"
echo "Results are available in: $RESULTS_DIR/"
echo "================================================"
