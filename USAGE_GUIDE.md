# Usage Guide for Viral Genome Analysis

## Quick Start Guide

### For Chikungunya Virus (4 genome sequences)

1. **Prepare your data:**
   - Create directory: `mkdir -p data/chikungunya`
   - Place your 4 Chikungunya genome FASTA files in `data/chikungunya/`
   - Name them something like: `chikv_1.fasta`, `chikv_2.fasta`, `chikv_3.fasta`, `chikv_4.fasta`
   - Optionally add a `reference.fasta` file

2. **Generate consensus sequence:**
   ```bash
   python3 consensus_generation.py \
       -i data/chikungunya/*.fasta \
       -o results/chikungunya_consensus.fasta \
       --name "CHIKV_consensus" \
       --metrics
   ```

3. **Call variants:**
   ```bash
   # If you have a reference.fasta:
   python3 variant_calling.py \
       -r data/chikungunya/reference.fasta \
       -s data/chikungunya/chikv_*.fasta \
       -o results/chikungunya_variants.vcf \
       --summary
   
   # Or use first file as reference:
   python3 variant_calling.py \
       -r data/chikungunya/chikv_1.fasta \
       -s data/chikungunya/chikv_2.fasta \
          data/chikungunya/chikv_3.fasta \
          data/chikungunya/chikv_4.fasta \
       -o results/chikungunya_variants.vcf \
       --summary
   ```

### For Zika Virus S-22 (single genome sequence)

1. **Prepare your data:**
   - Create directory: `mkdir -p data/zika`
   - Place your S-22 Zika genome FASTA file in `data/zika/`
   - Name it: `zikv_s22.fasta`

2. **Generate consensus sequence:**
   ```bash
   python3 consensus_generation.py \
       -i data/zika/zikv_s22.fasta \
       -o results/zikv_s22_consensus.fasta \
       --name "ZIKV_S22_consensus" \
       --metrics
   ```

   Note: Variant calling requires at least 2 sequences, so if you only have S-22, consensus generation is the primary analysis.

### Automated Workflow (Both Viruses)

The easiest way to process both Chikungunya and Zika genomes:

```bash
# 1. Set up directories
mkdir -p data/chikungunya data/zika

# 2. Place your FASTA files:
#    - 4 Chikungunya files in data/chikungunya/
#    - 1 Zika S-22 file in data/zika/

# 3. Run the automated workflow
./run_analysis.sh
```

This will process everything and save results in `results/chikungunya/` and `results/zika/`

## Advanced Options

### Consensus Generation Parameters

**Method Selection:**
- `majority`: Select most common base at each position (recommended)
- `reference`: Use first sequence as template

**Coverage Threshold:**
- `-c 2`: Require at least 2 sequences at a position
- `-c 3`: Require at least 3 sequences (more stringent)

**Ambiguity Threshold:**
- `-t 0.25`: Call 'N' if no base has >25% frequency
- `-t 0.5`: Call 'N' if no base has >50% frequency (more stringent)

**Example - High Quality Consensus:**
```bash
python3 consensus_generation.py \
    -i data/chikungunya/*.fasta \
    -o results/high_quality_consensus.fasta \
    -m majority \
    -c 3 \
    -t 0.5 \
    --metrics
```

### Variant Calling Parameters

**Allele Frequency Threshold:**
- `-f 0.25`: Call variants present in >25% of samples (default)
- `-f 0.5`: Only call variants present in >50% of samples
- `-f 0.1`: Call even rare variants (>10%)

**Example - High Frequency Variants Only:**
```bash
python3 variant_calling.py \
    -r reference.fasta \
    -s sample*.fasta \
    -o high_freq_variants.vcf \
    -f 0.5 \
    --summary
```

## Understanding the Output

### Consensus Sequence Output

Example output from consensus generation:
```
=== Consensus Sequence Generated ===
Length: 11805 bp
Ambiguous bases (N): 23 (0.19%)

=== Quality Metrics ===
Number of input sequences: 4
Mean coverage per position: 4.00x
Min coverage: 4x
Max coverage: 4x
```

- **Length**: Total length of consensus sequence
- **Ambiguous bases (N)**: Positions where no clear consensus could be determined
- **Mean coverage**: Average number of sequences covering each position
- **Min/Max coverage**: Coverage range across the genome

### Variant Call Output (VCF)

Example VCF line:
```
reference_sequence  89  .  C  G  .  PASS  AF=0.3333;AC=1;DP=3
```

Interpretation:
- **Position 89**: Variant location in the reference genome
- **REF: C**: Reference base is Cytosine
- **ALT: G**: Alternative base is Guanine (the variant)
- **AF=0.3333**: Allele frequency - 33.33% of samples have this variant
- **AC=1**: Allele count - 1 out of 3 samples has this variant
- **DP=3**: Depth - 3 total sequences at this position

## Expected File Structure

```
colaborate/
├── consensus_generation.py      # Consensus sequence tool
├── variant_calling.py           # Variant calling tool
├── run_analysis.sh             # Automated workflow
├── requirements.txt            # Python dependencies
├── README.md                   # Main documentation
├── USAGE_GUIDE.md             # This file
├── example.fasta              # Example FASTA file
│
├── data/                      # Your input data
│   ├── chikungunya/
│   │   ├── chikv_1.fasta
│   │   ├── chikv_2.fasta
│   │   ├── chikv_3.fasta
│   │   ├── chikv_4.fasta
│   │   └── reference.fasta (optional)
│   └── zika/
│       └── zikv_s22.fasta
│
└── results/                   # Output files
    ├── chikungunya/
    │   ├── chikv_consensus.fasta
    │   └── chikv_variants.vcf
    └── zika/
        └── zikv_s22_consensus.fasta
```

## Common Scenarios

### Scenario 1: I have 4 Chikungunya sequences and need consensus
```bash
python3 consensus_generation.py \
    -i data/chikungunya/*.fasta \
    -o results/chikv_consensus.fasta \
    --metrics
```

### Scenario 2: I want to identify variants in my 4 Chikungunya sequences
```bash
# Use first sequence as reference
python3 variant_calling.py \
    -r data/chikungunya/chikv_1.fasta \
    -s data/chikungunya/chikv_2.fasta \
       data/chikungunya/chikv_3.fasta \
       data/chikungunya/chikv_4.fasta \
    -o results/chikv_variants.vcf \
    --summary
```

### Scenario 3: I need high-quality consensus (strict parameters)
```bash
python3 consensus_generation.py \
    -i data/chikungunya/*.fasta \
    -o results/strict_consensus.fasta \
    -m majority \
    -c 3 \
    -t 0.6 \
    --metrics
```

### Scenario 4: I want to find only common variants (>50% frequency)
```bash
python3 variant_calling.py \
    -r reference.fasta \
    -s sample*.fasta \
    -o common_variants.vcf \
    -f 0.5 \
    --summary
```

## Troubleshooting

### "No sequences found"
- Check that your FASTA files are in the correct directory
- Verify FASTA format: sequences should start with `>` followed by ID

### "Module not found: Bio"
- Install dependencies: `pip install -r requirements.txt`
- Or: `pip install biopython`

### "Permission denied" on run_analysis.sh
- Make executable: `chmod +x run_analysis.sh`

### Sequences have different lengths
- This is OK! The tools handle variable-length sequences
- Shorter sequences are treated as having gaps at the end

## Tips for Best Results

1. **Quality Input**: Ensure your FASTA files are properly formatted
2. **Reference Selection**: Use a high-quality reference genome when available
3. **Coverage**: More sequences generally produce better consensus
4. **Thresholds**: Adjust based on your data quality and research needs
5. **Validate**: Always check the quality metrics in the output

## Getting Help

If you encounter issues:
1. Check the error message - it usually indicates the problem
2. Verify your file paths are correct
3. Ensure dependencies are installed
4. Review this guide for examples
5. Open an issue on GitHub with details about your problem
