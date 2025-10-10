# Examples for Chikungunya and Zika Virus Analysis

## Example 1: Complete Analysis of 4 Chikungunya Genomes and 1 Zika Genome

### Step 1: Setup
```bash
git clone https://github.com/tahmidsk/colaborate.git
cd colaborate
./setup.sh
```

### Step 2: Organize Your Data

Place your FASTA files:
- `data/chikungunya/chikv_1.fasta` (Chikungunya genome 1)
- `data/chikungunya/chikv_2.fasta` (Chikungunya genome 2)
- `data/chikungunya/chikv_3.fasta` (Chikungunya genome 3)
- `data/chikungunya/chikv_4.fasta` (Chikungunya genome 4)
- `data/zika/zikv_s22.fasta` (Zika S-22 genome)

### Step 3: Run Automated Analysis
```bash
./run_analysis.sh
```

### Expected Output:
```
==========================================
Processing Chikungunya Virus Genomes
==========================================

Found 4 Chikungunya genome file(s)
Generating Chikungunya consensus sequence...
  - CHIKV_strain_1 (length: 11805 bp)
  - CHIKV_strain_2 (length: 11805 bp)
  - CHIKV_strain_3 (length: 11805 bp)
  - CHIKV_strain_4 (length: 11805 bp)

=== Consensus Sequence Generated ===
Length: 11805 bp
Ambiguous bases (N): 23 (0.19%)

Performing variant calling for Chikungunya...
Total variants called: 42

==========================================
Processing Zika Virus Genome (S-22)
==========================================

Found 1 Zika genome file(s)
Generating Zika virus consensus sequence...
  - ZIKV_S22 (length: 10807 bp)

=== Consensus Sequence Generated ===
Length: 10807 bp
Ambiguous bases (N): 0 (0.00%)

✓ Workflow completed successfully!
```

### Step 4: Check Results
```bash
ls -lh results/chikungunya/
# chikv_consensus.fasta  - Consensus sequence
# chikv_variants.vcf     - Variant calls

ls -lh results/zika/
# zikv_s22_consensus.fasta - Consensus sequence
```

---

## Example 2: Manual Consensus Generation for Chikungunya

Generate consensus with default parameters:
```bash
python3 consensus_generation.py \
    -i data/chikungunya/chikv_1.fasta \
       data/chikungunya/chikv_2.fasta \
       data/chikungunya/chikv_3.fasta \
       data/chikungunya/chikv_4.fasta \
    -o results/chikv_consensus.fasta \
    --name "CHIKV_consensus_manual" \
    --metrics
```

Generate high-quality consensus (require 3+ sequences, 60% agreement):
```bash
python3 consensus_generation.py \
    -i data/chikungunya/*.fasta \
    -o results/chikv_high_quality_consensus.fasta \
    --name "CHIKV_HQ_consensus" \
    -m majority \
    -c 3 \
    -t 0.6 \
    --metrics
```

---

## Example 3: Manual Variant Calling for Chikungunya

Basic variant calling (use first sequence as reference):
```bash
python3 variant_calling.py \
    -r data/chikungunya/chikv_1.fasta \
    -s data/chikungunya/chikv_2.fasta \
       data/chikungunya/chikv_3.fasta \
       data/chikungunya/chikv_4.fasta \
    -o results/chikv_variants.vcf \
    --summary
```

Call only high-frequency variants (>50%):
```bash
python3 variant_calling.py \
    -r data/chikungunya/chikv_1.fasta \
    -s data/chikungunya/chikv_*.fasta \
    -o results/chikv_high_freq_variants.vcf \
    -f 0.5 \
    --summary
```

Call even rare variants (>10%):
```bash
python3 variant_calling.py \
    -r data/chikungunya/chikv_1.fasta \
    -s data/chikungunya/chikv_*.fasta \
    -o results/chikv_all_variants.vcf \
    -f 0.1 \
    --summary
```

---

## Example 4: Zika S-22 Consensus Generation

Since you have only one Zika genome (S-22), consensus generation will simply output the sequence:

```bash
python3 consensus_generation.py \
    -i data/zika/zikv_s22.fasta \
    -o results/zikv_s22_consensus.fasta \
    --name "ZIKV_S22" \
    --metrics
```

If you later obtain additional Zika sequences, you can generate a consensus from all of them:
```bash
python3 consensus_generation.py \
    -i data/zika/*.fasta \
    -o results/zikv_multi_consensus.fasta \
    --name "ZIKV_consensus" \
    --metrics
```

---

## Example 5: Comparing Chikungunya to Zika (Cross-Species Comparison)

If you want to identify differences between the two virus types:

```bash
python3 variant_calling.py \
    -r data/chikungunya/chikv_1.fasta \
    -s data/zika/zikv_s22.fasta \
    -o results/chikv_vs_zikv_differences.vcf \
    -f 0.1 \
    --summary
```

Note: This is primarily for research purposes as these are different virus species with significant genomic differences.

---

## Example 6: Working with Your Own File Names

If your files have different names, adjust the commands accordingly:

```bash
# If your files are named: CHIKV_isolate1.fa, CHIKV_isolate2.fa, etc.
python3 consensus_generation.py \
    -i data/chikungunya/CHIKV_isolate1.fa \
       data/chikungunya/CHIKV_isolate2.fa \
       data/chikungunya/CHIKV_isolate3.fa \
       data/chikungunya/CHIKV_isolate4.fa \
    -o results/consensus.fasta \
    --metrics

# Or use wildcard pattern
python3 consensus_generation.py \
    -i data/chikungunya/CHIKV_*.fa \
    -o results/consensus.fasta \
    --metrics
```

---

## Understanding Your Results

### Consensus Sequence (FASTA)
The consensus sequence represents the most common nucleotide at each position across all input sequences.

Example:
```
>CHIKV_consensus Consensus sequence from 4 sequences using majority method
ATGGCTAAACGAGTGCTTATCGACGATGCTAAACGAGTGCTTATCGACGATGCTAGCTAGCTAGC
TAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCT
...
```

### Variant Calls (VCF)
The VCF file contains all positions where at least one sample differs from the reference.

Example:
```
#CHROM                  POS  REF  ALT  INFO
CHIKV_strain_1         157   C    G    AF=0.3333;AC=1;DP=3
CHIKV_strain_1         2450  A    T    AF=0.6667;AC=2;DP=3
```

Interpretation:
- Position 157: 1 out of 3 samples has G instead of C (33.3% frequency)
- Position 2450: 2 out of 3 samples have T instead of A (66.7% frequency)

---

## Tips for Best Results

1. **Quality Control**: Ensure your FASTA files are properly formatted
2. **File Naming**: Use consistent, descriptive names for your files
3. **Reference Selection**: Use the highest quality genome as reference
4. **Parameter Tuning**: Adjust thresholds based on your data quality
5. **Result Validation**: Always review the output metrics

---

## Common Use Cases

### Use Case 1: Epidemiological Study
You have 4 Chikungunya samples from different patients/locations.
→ Generate consensus to identify the dominant strain
→ Call variants to understand genetic diversity

### Use Case 2: Reference Sequence Creation
You have multiple sequences of the same virus.
→ Generate high-quality consensus (high threshold)
→ Use as reference for future studies

### Use Case 3: Mutation Detection
You have sequences from different time points.
→ Use earliest sample as reference
→ Call variants to track mutations over time

---

## Next Steps

After running the analysis:

1. **Visualize Results**: Use genome browsers to visualize variants
2. **Functional Analysis**: Annotate variants to genes/proteins
3. **Phylogenetic Analysis**: Use consensus sequences for phylogenetic trees
4. **Publication**: VCF files are publication-ready standard format

For more details, see:
- `README.md` - Complete documentation
- `USAGE_GUIDE.md` - Detailed usage guide
- `QUICK_REFERENCE.md` - Quick command reference
