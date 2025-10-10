# BLAST Tutorial: Step-by-Step Guide for Beginners

This tutorial will guide you through running BLAST on command line for the Chikungunya and Zika virus genomes in this repository.

## Step 1: Install BLAST+

Choose the installation method for your operating system:

### For Ubuntu/Debian Users
```bash
sudo apt-get update
sudo apt-get install ncbi-blast+
```

### For macOS Users (with Homebrew)
```bash
brew install blast
```

### For Windows Users
Download the installer from:
https://blast.ncbi.nlm.nih.gov/Blast.cgi?PAGE_TYPE=BlastDocs&DOC_TYPE=Download

### Verify Installation
```bash
blastn -version
```
You should see output like: `blastn: 2.x.x+`

## Step 2: Understand the Repository Structure

```
colaborate/
├── sequences/               # Your input genome sequences
│   ├── chikungunya_1.fasta # Chikungunya strain 1
│   ├── chikungunya_2.fasta # Chikungunya strain 2
│   ├── chikungunya_3.fasta # Chikungunya strain 3
│   ├── chikungunya_4.fasta # Chikungunya strain 4
│   └── zika_1.fasta        # Zika virus
├── run_blast.sh            # Automated script (easiest)
├── blast_examples.sh       # Example commands
└── README.md               # Full documentation
```

## Step 3: Run the Automated Analysis (Easiest Method)

Simply run:
```bash
./run_blast.sh
```

This will:
1. ✅ Create a BLAST database
2. ✅ Run BLAST on all sequences
3. ✅ Compare Chikungunya vs Zika
4. ✅ Generate results in `blast_results/` directory

**What you'll get:**
- Individual BLAST results for each sequence
- Comparative analysis between Chikungunya and Zika
- Summary report

## Step 4: Understanding Your Results

After running the script, check the `blast_results/` directory:

```bash
ls blast_results/
```

You'll see files like:
- `chikungunya_1_blast_results.txt` - Tabular results
- `chikungunya_1_blast_results.xml` - XML format results
- `chikungunya_vs_zika.txt` - Comparative analysis
- `analysis_summary.txt` - Summary of all results

### Reading Tabular Results

Open any `.txt` file to see results in this format:
```
Query_ID  Subject_ID  %Identity  Length  Mismatches  Gaps  Q_Start  Q_End  S_Start  S_End  E-value  Bit_Score
```

**Key columns to understand:**
- **%Identity**: How similar the sequences are (higher is better)
- **E-value**: Statistical significance (lower is better)
- **Bit Score**: Quality of alignment (higher is better)

### What's a Good Match?

- **E-value < 1e-10**: Excellent match (very significant)
- **E-value < 1e-5**: Good match (significant)
- **E-value > 0.01**: Weak match (might not be meaningful)

- **% Identity > 95%**: Very similar sequences
- **% Identity 70-95%**: Related sequences
- **% Identity < 70%**: Distantly related

## Step 5: Manual BLAST (Step-by-Step)

If you want to understand what's happening behind the scenes:

### 5.1 Create a BLAST Database
```bash
# Create database directory
mkdir -p blast_db

# Combine sequences
cat sequences/*.fasta > blast_db/all_sequences.fasta

# Create the database
makeblastdb -in blast_db/all_sequences.fasta \
            -dbtype nucl \
            -out blast_db/viral_genomes
```

### 5.2 Run Your First BLAST Query
```bash
# Simple comparison: Chikungunya 1 against all sequences
blastn -query sequences/chikungunya_1.fasta \
       -db blast_db/viral_genomes \
       -out my_first_blast.txt
```

Check the results:
```bash
cat my_first_blast.txt
```

### 5.3 Run BLAST with Tabular Output (Easier to Read)
```bash
blastn -query sequences/chikungunya_1.fasta \
       -db blast_db/viral_genomes \
       -out my_first_blast_table.txt \
       -outfmt 6
```

This creates a neat table that's easier to analyze.

### 5.4 Compare Two Sequences Directly
```bash
# Compare Chikungunya 1 with Zika
blastn -query sequences/chikungunya_1.fasta \
       -subject sequences/zika_1.fasta \
       -out chik_vs_zika.txt
```

## Step 6: Try Different BLAST Options

### Fast BLAST (for very similar sequences)
```bash
blastn -query sequences/chikungunya_1.fasta \
       -db blast_db/viral_genomes \
       -task megablast \
       -out fast_results.txt
```

### Sensitive BLAST (for finding distant matches)
```bash
blastn -query sequences/chikungunya_1.fasta \
       -db blast_db/viral_genomes \
       -task blastn \
       -word_size 7 \
       -evalue 0.01 \
       -out sensitive_results.txt
```

### Limit Results (Top 5 hits only)
```bash
blastn -query sequences/chikungunya_1.fasta \
       -db blast_db/viral_genomes \
       -max_target_seqs 5 \
       -out top5_results.txt \
       -outfmt 6
```

## Step 7: Batch Processing (All Sequences at Once)

Process all sequences in the `sequences/` directory:

```bash
# Create results directory
mkdir -p my_results

# Run BLAST for each sequence
for fasta in sequences/*.fasta; do
    name=$(basename "$fasta" .fasta)
    echo "Processing $name..."
    blastn -query "$fasta" \
           -db blast_db/viral_genomes \
           -out "my_results/${name}_results.txt" \
           -outfmt 6
done

echo "Done! Results are in my_results/"
```

## Step 8: Working with Real Genome Data

Want to use actual genome sequences from NCBI?

### Method 1: Download from NCBI Website
1. Go to https://www.ncbi.nlm.nih.gov/nuccore
2. Search for "Chikungunya virus complete genome"
3. Select a sequence
4. Click "Send to" → "Complete Record" → "File" → "FASTA"
5. Save to the `sequences/` directory

### Method 2: Using Command Line (requires EDirect tools)
```bash
# Install EDirect (Ubuntu/Debian)
sudo apt-get install ncbi-entrez-direct

# Download Chikungunya genome
efetch -db nucleotide -id NC_004162 -format fasta > sequences/chikungunya_ncbi.fasta

# Download Zika genome
efetch -db nucleotide -id NC_012532 -format fasta > sequences/zika_ncbi.fasta
```

## Troubleshooting Common Issues

### Issue 1: "Command not found: blastn"
**Solution**: BLAST is not installed. Go back to Step 1.

### Issue 2: "BLAST Database error"
**Solution**: Make sure you created the database:
```bash
makeblastdb -in blast_db/all_sequences.fasta -dbtype nucl -out blast_db/viral_genomes
```

### Issue 3: Empty Results
**Solution**: Try increasing the E-value:
```bash
blastn -query input.fasta -db database -evalue 10
```

### Issue 4: BLAST is Too Slow
**Solution**: Use multiple CPU cores:
```bash
blastn -query input.fasta -db database -num_threads 4
```

## Next Steps

1. **Analyze Your Results**: Look at the E-values and % identity
2. **Experiment**: Try different BLAST parameters
3. **Compare**: Run reciprocal BLAST (A vs B, then B vs A)
4. **Learn More**: Read the [BLAST manual](https://www.ncbi.nlm.nih.gov/books/NBK279690/)

## Quick Reference

| What You Want to Do | Command |
|---------------------|---------|
| Run automated analysis | `./run_blast.sh` |
| See example commands | `./blast_examples.sh` |
| Create database | `makeblastdb -in seqs.fasta -dbtype nucl -out mydb` |
| Basic BLAST | `blastn -query input.fasta -db mydb` |
| Tabular output | `blastn -query input.fasta -db mydb -outfmt 6` |
| Compare two files | `blastn -query seq1.fasta -subject seq2.fasta` |

## Getting Help

- Run `blastn -help` for all options
- Check `README.md` for detailed documentation
- See `BLAST_QUICK_REFERENCE.md` for command reference

## Resources

- [NCBI BLAST+](https://blast.ncbi.nlm.nih.gov/Blast.cgi)
- [BLAST Book](https://www.ncbi.nlm.nih.gov/books/NBK279690/)
- [BLAST Tutorial](https://www.ncbi.nlm.nih.gov/books/NBK52640/)

Good luck with your BLAST analysis! 🧬
