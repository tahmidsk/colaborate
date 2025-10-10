# BLAST Quick Reference Guide

## Quick Start Commands

### 1. Run the Complete Analysis
```bash
./run_blast.sh
```

### 2. View Command Examples
```bash
./blast_examples.sh
```

## Most Common BLAST Commands

### Compare Two Sequences
```bash
blastn -query sequences/chikungunya_1.fasta -subject sequences/zika_1.fasta
```

### Search Against a Database
```bash
blastn -query sequences/chikungunya_1.fasta -db blast_db/viral_genomes -outfmt 6
```

### Create a Database
```bash
makeblastdb -in sequences.fasta -dbtype nucl -out my_database
```

## Output Format Quick Reference

### Format 6 - Tabular (Most Common)
```bash
-outfmt 6
```
Columns: qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore

### Format 7 - Tabular with Comments
```bash
-outfmt 7
```

### Format 5 - XML
```bash
-outfmt 5
```

### Custom Columns
```bash
-outfmt "6 qseqid sseqid pident length evalue bitscore"
```

## Important Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `-evalue` | E-value threshold | `-evalue 1e-10` |
| `-max_target_seqs` | Maximum hits to return | `-max_target_seqs 5` |
| `-num_threads` | Parallel processing | `-num_threads 4` |
| `-task` | BLAST algorithm | `-task blastn` or `-task megablast` |
| `-word_size` | Word size for matching | `-word_size 11` |
| `-dust` | Filter low complexity | `-dust yes` |

## Task Types

- `megablast` - Fast, for highly similar sequences (>95% identity)
- `blastn` - Default, more sensitive
- `blastn-short` - For short queries (<30 nucleotides)

## E-value Guide

- `1e-10` or lower - Very high confidence
- `1e-5` - High confidence
- `1e-3` - Moderate confidence
- `10` - Default for blastn (permissive)

## Sequence Files

### Chikungunya Genomes
- `sequences/chikungunya_1.fasta`
- `sequences/chikungunya_2.fasta`
- `sequences/chikungunya_3.fasta`
- `sequences/chikungunya_4.fasta`

### Zika Genome
- `sequences/zika_1.fasta`

## Output Locations

- `blast_db/` - BLAST database files
- `blast_results/` - Analysis results

## Troubleshooting

**BLAST not found?**
Install with: `sudo apt-get install ncbi-blast+` (Ubuntu/Debian)

**Empty results?**
Try adjusting `-evalue` to a higher value (e.g., `-evalue 10`)

**Slow performance?**
Use `-num_threads` to parallelize or `-task megablast` for similar sequences

## Getting Help

```bash
blastn -help
makeblastdb -help
```

## Online Resources

- [BLAST Manual](https://www.ncbi.nlm.nih.gov/books/NBK279690/)
- [BLAST Downloads](https://blast.ncbi.nlm.nih.gov/Blast.cgi?PAGE_TYPE=BlastDocs&DOC_TYPE=Download)
