# Collaborate - Viral Genome BLAST Analysis
This is a demo repository for running BLAST on command line for Chikungunya and Zika virus genome sequences.

> **👋 New here?** Start with [START_HERE.md](START_HERE.md) for a guided introduction!

## Overview
This repository contains:
- 4 Chikungunya virus genome sequences
- 1 Zika virus genome sequence
- Automated BLAST analysis script
- Complete documentation for running BLAST on command line

## Prerequisites

### Installing BLAST+

#### Ubuntu/Debian
```bash
sudo apt-get update
sudo apt-get install ncbi-blast+
```

#### macOS (with Homebrew)
```bash
brew install blast
```

#### CentOS/RHEL
```bash
sudo yum install ncbi-blast+
```

#### Manual Installation
Download from the official NCBI BLAST+ website:
https://blast.ncbi.nlm.nih.gov/Blast.cgi?PAGE_TYPE=BlastDocs&DOC_TYPE=Download

### Verifying Installation
```bash
blastn -version
makeblastdb -version
```

## Quick Start

### Option 1: Using the Automated Script
```bash
# Run the automated BLAST analysis
./run_blast.sh
```

This script will:
1. Create a BLAST database from all sequences
2. Run BLAST queries for each sequence
3. Perform comparative analysis (Chikungunya vs Zika)
4. Generate detailed results in the `blast_results/` directory

### Option 2: Manual BLAST Commands

#### Step 1: Create a BLAST Database
```bash
# Create database directory
mkdir -p blast_db

# Combine all sequences
cat sequences/*.fasta > blast_db/all_sequences.fasta

# Create the BLAST database
makeblastdb -in blast_db/all_sequences.fasta \
            -dbtype nucl \
            -out blast_db/viral_genomes \
            -parse_seqids \
            -title "Chikungunya and Zika Virus Genomes"
```

#### Step 2: Run BLAST Queries

**Basic BLAST query (standard output):**
```bash
blastn -query sequences/chikungunya_1.fasta \
       -db blast_db/viral_genomes \
       -out results.txt
```

**Tabular output (easier to parse):**
```bash
blastn -query sequences/chikungunya_1.fasta \
       -db blast_db/viral_genomes \
       -out results_tabular.txt \
       -outfmt 6
```

**Detailed tabular output with custom columns:**
```bash
blastn -query sequences/chikungunya_1.fasta \
       -db blast_db/viral_genomes \
       -out results_detailed.txt \
       -outfmt "6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore"
```

**XML output (for programmatic parsing):**
```bash
blastn -query sequences/chikungunya_1.fasta \
       -db blast_db/viral_genomes \
       -out results.xml \
       -outfmt 5
```

#### Step 3: Compare Two Sequences Directly
```bash
# Compare Chikungunya strain 1 vs Zika
blastn -query sequences/chikungunya_1.fasta \
       -subject sequences/zika_1.fasta \
       -out chik_vs_zika.txt
```

#### Step 4: Batch Processing All Sequences
```bash
# Create results directory
mkdir -p blast_results

# Run BLAST for all sequences
for fasta in sequences/*.fasta; do
    name=$(basename "$fasta" .fasta)
    blastn -query "$fasta" \
           -db blast_db/viral_genomes \
           -out "blast_results/${name}_results.txt" \
           -outfmt 6
done
```

## Understanding BLAST Output Formats

### Output Format Options (-outfmt)
- `0` = Pairwise (default)
- `5` = XML
- `6` = Tabular
- `7` = Tabular with comment lines
- `10` = CSV
- `11` = BLAST archive (ASN.1)

### Tabular Output Columns
When using `-outfmt 6`, the default columns are:
1. `qseqid` - Query sequence ID
2. `sseqid` - Subject sequence ID
3. `pident` - Percentage of identical matches
4. `length` - Alignment length
5. `mismatch` - Number of mismatches
6. `gapopen` - Number of gap openings
7. `qstart` - Start of alignment in query
8. `qend` - End of alignment in query
9. `sstart` - Start of alignment in subject
10. `send` - End of alignment in subject
11. `evalue` - Expect value
12. `bitscore` - Bit score

## Common BLAST Parameters

### Sensitivity and Speed
```bash
# High sensitivity (slow)
blastn -task blastn -word_size 7 -evalue 0.0001

# Default
blastn -task blastn

# Fast, less sensitive (for very similar sequences)
blastn -task blastn-short -word_size 11

# For highly similar sequences (megablast)
blastn -task megablast
```

### Controlling Output
```bash
# Limit number of alignments
blastn -query input.fasta -db database -max_target_seqs 10

# Set e-value threshold
blastn -query input.fasta -db database -evalue 1e-10

# Filter low complexity regions
blastn -query input.fasta -db database -dust yes
```

## Project Structure
```
.
├── README.md                  # This file
├── run_blast.sh              # Automated BLAST analysis script
├── sequences/                # Input genome sequences
│   ├── chikungunya_1.fasta
│   ├── chikungunya_2.fasta
│   ├── chikungunya_3.fasta
│   ├── chikungunya_4.fasta
│   └── zika_1.fasta
├── blast_db/                 # BLAST database (created by script)
└── blast_results/            # Analysis results (created by script)
```

## Using Real Genome Sequences

To use actual genome sequences from NCBI:

### Download from NCBI
```bash
# Install NCBI E-utilities (if not installed)
# Ubuntu/Debian: sudo apt-get install ncbi-entrez-direct
# macOS: brew install edirect

# Download Chikungunya genome
efetch -db nucleotide -id NC_004162 -format fasta > sequences/chikungunya_real.fasta

# Download Zika genome
efetch -db nucleotide -id NC_012532 -format fasta > sequences/zika_real.fasta
```

### Manual Download
1. Visit https://www.ncbi.nlm.nih.gov/nuccore
2. Search for "Chikungunya virus complete genome"
3. Select sequences and download in FASTA format
4. Save to the `sequences/` directory

## Example Use Cases

### 1. Find Similar Regions Between Genomes
```bash
blastn -query sequences/chikungunya_1.fasta \
       -subject sequences/zika_1.fasta \
       -outfmt "6 qseqid sseqid pident length qstart qend sstart send"
```

### 2. Search Against NCBI Database
```bash
# Search against the online NCBI database
blastn -query sequences/chikungunya_1.fasta \
       -db nt \
       -remote \
       -out remote_blast_results.txt
```

### 3. Identify Conserved Regions
```bash
# Align all Chikungunya sequences
cat sequences/chikungunya_*.fasta > all_chikungunya.fasta
blastn -query all_chikungunya.fasta \
       -subject all_chikungunya.fasta \
       -outfmt 6 \
       -out conserved_regions.txt
```

## Troubleshooting

### Error: "BLAST Database error: No alias or index file found"
- Make sure you ran `makeblastdb` successfully
- Check that the database path is correct

### Error: "Sequence contains invalid characters"
- Ensure FASTA files contain only valid nucleotide characters (A, T, G, C, N)
- Check for proper FASTA format (header line starting with `>`)

### Slow Performance
- Use `-num_threads` to parallelize (e.g., `-num_threads 4`)
- Consider using `-task megablast` for highly similar sequences
- Reduce `-max_target_seqs` if you don't need many hits

## Additional Resources
- [BLAST Command Line Manual](https://www.ncbi.nlm.nih.gov/books/NBK279690/)
- [BLAST+ Help](https://www.ncbi.nlm.nih.gov/books/NBK279690/)
- [Understanding BLAST E-values](https://www.ncbi.nlm.nih.gov/BLAST/tutorial/Altschul-1.html)

## License
This is a demo repository for educational purposes.
