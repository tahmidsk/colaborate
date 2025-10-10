#!/bin/bash
# Additional BLAST Examples and Use Cases
# This script demonstrates various BLAST command line options

echo "BLAST Command Line Examples"
echo "==========================="
echo ""

# Check if BLAST is installed
if ! command -v blastn &> /dev/null; then
    echo "ERROR: BLAST+ is not installed!"
    echo "Run the main run_blast.sh script to see installation instructions."
    exit 1
fi

SEQUENCE_DIR="sequences"
RESULTS_DIR="blast_results"
DB_DIR="blast_db"

mkdir -p "$RESULTS_DIR"

echo "Example 1: Basic BLAST with Standard Output"
echo "--------------------------------------------"
echo "Command:"
echo "blastn -query sequences/chikungunya_1.fasta -subject sequences/zika_1.fasta"
echo ""

echo "Example 2: Tabular Output (Easy to Parse)"
echo "-----------------------------------------"
echo "Command:"
echo "blastn -query sequences/chikungunya_1.fasta -subject sequences/zika_1.fasta -outfmt 6"
echo ""

echo "Example 3: Custom Tabular Output with Selected Columns"
echo "------------------------------------------------------"
echo "Command:"
echo 'blastn -query input.fasta -db database -outfmt "6 qseqid sseqid pident evalue bitscore"'
echo ""

echo "Example 4: XML Output for Programmatic Parsing"
echo "----------------------------------------------"
echo "Command:"
echo "blastn -query sequences/chikungunya_1.fasta -db blast_db/viral_genomes -outfmt 5 -out results.xml"
echo ""

echo "Example 5: High Sensitivity BLAST"
echo "---------------------------------"
echo "Command:"
echo "blastn -query input.fasta -db database -task blastn -word_size 7 -evalue 0.0001"
echo ""

echo "Example 6: Fast BLAST for Similar Sequences (Megablast)"
echo "-------------------------------------------------------"
echo "Command:"
echo "blastn -query input.fasta -db database -task megablast"
echo ""

echo "Example 7: Remote BLAST Against NCBI Database"
echo "---------------------------------------------"
echo "Command:"
echo "blastn -query sequences/chikungunya_1.fasta -db nt -remote -out ncbi_results.txt"
echo "Note: This requires internet connection and may take longer"
echo ""

echo "Example 8: BLAST with Multiple Threads (Parallel Processing)"
echo "-----------------------------------------------------------"
echo "Command:"
echo "blastn -query input.fasta -db database -num_threads 4"
echo ""

echo "Example 9: Filtering by E-value"
echo "-------------------------------"
echo "Command:"
echo "blastn -query input.fasta -db database -evalue 1e-10"
echo ""

echo "Example 10: Limiting Number of Hits"
echo "-----------------------------------"
echo "Command:"
echo "blastn -query input.fasta -db database -max_target_seqs 5"
echo ""

echo "Example 11: BLAST All Sequences in a Directory"
echo "----------------------------------------------"
echo "Command:"
echo 'for fasta in sequences/*.fasta; do'
echo '    blastn -query "$fasta" -db blast_db/viral_genomes -outfmt 6 -out "results_$(basename $fasta .fasta).txt"'
echo 'done'
echo ""

echo "Example 12: Creating a BLAST Database"
echo "-------------------------------------"
echo "Command:"
echo "makeblastdb -in sequences.fasta -dbtype nucl -out my_database -parse_seqids"
echo ""

echo "Example 13: Viewing BLAST Database Info"
echo "---------------------------------------"
echo "Command:"
echo "blastdbcmd -db blast_db/viral_genomes -info"
echo ""

echo "Example 14: Extracting a Sequence from BLAST Database"
echo "-----------------------------------------------------"
echo "Command:"
echo 'blastdbcmd -db blast_db/viral_genomes -entry "chikungunya_strain_1"'
echo ""

echo "Example 15: Reciprocal BLAST (Find Best Bidirectional Hits)"
echo "-----------------------------------------------------------"
echo "Command:"
echo "# First direction"
echo "blastn -query seq_A.fasta -subject seq_B.fasta -outfmt 6 -out A_vs_B.txt"
echo "# Second direction"
echo "blastn -query seq_B.fasta -subject seq_A.fasta -outfmt 6 -out B_vs_A.txt"
echo ""

echo ""
echo "Output Format Specifiers for -outfmt 6 or 7:"
echo "============================================="
echo "qseqid    - Query sequence ID"
echo "sseqid    - Subject sequence ID"
echo "pident    - Percentage of identical matches"
echo "length    - Alignment length"
echo "mismatch  - Number of mismatches"
echo "gapopen   - Number of gap openings"
echo "qstart    - Start of alignment in query"
echo "qend      - End of alignment in query"
echo "sstart    - Start of alignment in subject"
echo "send      - End of alignment in subject"
echo "evalue    - Expect value (E-value)"
echo "bitscore  - Bit score"
echo "qlen      - Query sequence length"
echo "slen      - Subject sequence length"
echo "qcovs     - Query coverage per subject"
echo ""

echo ""
echo "BLAST Task Types:"
echo "================="
echo "megablast       - Traditional megablast (fast, for highly similar sequences)"
echo "dc-megablast    - Discontiguous megablast"
echo "blastn          - Traditional BLASTN (slower, more sensitive)"
echo "blastn-short    - BLASTN optimized for short sequences"
echo ""

echo ""
echo "Common E-value Thresholds:"
echo "========================="
echo "1e-10 or lower  - Very high confidence (strict)"
echo "1e-5            - High confidence (default for many tools)"
echo "1e-3            - Moderate confidence"
echo "0.01 - 0.1      - Low confidence"
echo "10              - Very low confidence (permissive, default for blastn)"
echo ""

echo ""
echo "For more information:"
echo "===================="
echo "Run: blastn -help"
echo "Run: makeblastdb -help"
echo "Visit: https://www.ncbi.nlm.nih.gov/books/NBK279690/"
