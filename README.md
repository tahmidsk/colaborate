# Viral Genome Analysis Pipeline

This repository provides tools for variant calling and consensus sequence generation for viral genome sequences, specifically designed for Chikungunya and Zika virus genomes.

## Features

- **Variant Calling**: Identify genetic variants by comparing multiple genome sequences to a reference
- **Consensus Generation**: Generate consensus sequences from multiple aligned genome sequences
- **VCF Output**: Standard VCF format for variant calls
- **Quality Metrics**: Calculate coverage and quality statistics
- **Automated Workflow**: Shell script for end-to-end analysis

## Requirements

- Python 3.6 or higher
- Biopython
- NumPy
- pysam (optional, for advanced BAM file processing)

## Installation

1. Clone this repository:
```bash
git clone https://github.com/tahmidsk/colaborate.git
cd colaborate
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

Or install manually:
```bash
pip install biopython numpy pysam
```

## Data Structure

Organize your genome sequence files as follows:

```
./data/
├── chikungunya/
│   ├── chikv_1.fasta
│   ├── chikv_2.fasta
│   ├── chikv_3.fasta
│   ├── chikv_4.fasta
│   └── reference.fasta (optional)
└── zika/
    └── zikv_s22.fasta
```

## Usage

### Quick Start: Automated Workflow

Run the complete analysis pipeline with one command:

```bash
./run_analysis.sh
```

This will:
1. Process all Chikungunya genome sequences (4 sequences)
2. Process Zika virus S-22 genome sequence
3. Generate consensus sequences for both viruses
4. Perform variant calling
5. Save results in the `./results/` directory

### Individual Tools

#### 1. Consensus Sequence Generation

Generate a consensus sequence from multiple genome sequences:

```bash
python3 consensus_generation.py \
    -i data/chikungunya/*.fasta \
    -o results/chikv_consensus.fasta \
    --name "CHIKV_consensus" \
    --metrics
```

**Options:**
- `-i, --input`: Input FASTA files (can specify multiple)
- `-o, --output`: Output consensus FASTA file
- `-m, --method`: Consensus method (`majority` or `reference`)
- `-c, --min-coverage`: Minimum coverage at a position (default: 1)
- `-t, --threshold`: Minimum frequency for majority base (default: 0.25)
- `--name`: Name for consensus sequence
- `--metrics`: Print quality metrics

**Example for Chikungunya (4 sequences):**
```bash
python3 consensus_generation.py \
    -i data/chikungunya/chikv_1.fasta \
       data/chikungunya/chikv_2.fasta \
       data/chikungunya/chikv_3.fasta \
       data/chikungunya/chikv_4.fasta \
    -o results/chikv_consensus.fasta \
    --name "Chikungunya_consensus" \
    --metrics
```

**Example for Zika S-22:**
```bash
python3 consensus_generation.py \
    -i data/zika/zikv_s22.fasta \
    -o results/zikv_s22_consensus.fasta \
    --name "ZIKV_S22_consensus" \
    --metrics
```

#### 2. Variant Calling

Identify variants by comparing sample sequences to a reference:

```bash
python3 variant_calling.py \
    -r data/chikungunya/reference.fasta \
    -s data/chikungunya/chikv_1.fasta \
       data/chikungunya/chikv_2.fasta \
       data/chikungunya/chikv_3.fasta \
       data/chikungunya/chikv_4.fasta \
    -o results/chikv_variants.vcf \
    --summary
```

**Options:**
- `-r, --reference`: Reference genome FASTA file
- `-s, --samples`: Sample genome FASTA files (can specify multiple)
- `-o, --output`: Output VCF file
- `-f, --min-frequency`: Minimum allele frequency (default: 0.25)
- `--summary`: Print summary of variants

## Output Files

### Consensus Sequences
- FASTA format files containing the generated consensus sequences
- Located in `results/chikungunya/` and `results/zika/`

### Variant Calls (VCF)
- Standard VCF v4.2 format
- Contains position, reference allele, alternative allele, frequency, and counts
- Example:
  ```
  #CHROM  POS  ID  REF  ALT  QUAL  FILTER  INFO
  ref_seq 100  .   A    G    .     PASS    AF=0.7500;AC=3;DP=4
  ref_seq 250  .   C    T    .     PASS    AF=0.5000;AC=2;DP=4
  ```

## Understanding the Analysis

### Variant Calling
The variant calling tool compares multiple genome sequences to a reference and identifies positions where the sequences differ. Key metrics include:
- **Position**: Location of the variant in the genome
- **REF**: Reference base
- **ALT**: Alternative base
- **AF (Allele Frequency)**: Proportion of sequences with the alternative base
- **AC (Allele Count)**: Number of sequences with the alternative base
- **DP (Depth)**: Total number of sequences covering this position

### Consensus Generation
The consensus generation tool creates a single representative sequence from multiple genomes:
- **Majority method**: Selects the most common base at each position
- **Reference method**: Uses the first sequence as a guide
- **Ambiguous positions**: Marked as 'N' when no clear consensus exists

## Example Workflow for Your Data

Based on your description of having 4 Chikungunya virus genome sequences and 1 Zika virus (S-22) genome sequence:

### Step 1: Prepare Data
```bash
mkdir -p data/chikungunya data/zika
# Place your sequences:
# - 4 Chikungunya sequences in data/chikungunya/
# - S-22 Zika sequence in data/zika/
```

### Step 2: Run Analysis
```bash
./run_analysis.sh
```

### Step 3: Check Results
```bash
ls -la results/chikungunya/
ls -la results/zika/
```

## Troubleshooting

**Issue**: "No module named 'Bio'"
**Solution**: Install Biopython: `pip install biopython`

**Issue**: "No sequences found in input files"
**Solution**: Ensure your FASTA files are properly formatted and in the correct directory

**Issue**: "Permission denied" when running run_analysis.sh
**Solution**: Make the script executable: `chmod +x run_analysis.sh`

## Advanced Usage

### Custom Allele Frequency Threshold
Call only high-frequency variants (>50%):
```bash
python3 variant_calling.py -r ref.fasta -s sample*.fasta -o variants.vcf -f 0.5
```

### High-Quality Consensus
Require minimum 3x coverage and 30% threshold:
```bash
python3 consensus_generation.py -i *.fasta -o consensus.fasta -c 3 -t 0.3
```

## Output Example

When running the automated workflow, you'll see output like:

```
==========================================
Processing Chikungunya Virus Genomes
==========================================

Found 4 Chikungunya genome file(s)
Generating Chikungunya consensus sequence...
  - chikv_1 (length: 11805 bp)
  - chikv_2 (length: 11805 bp)
  - chikv_3 (length: 11805 bp)
  - chikv_4 (length: 11805 bp)

=== Consensus Sequence Generated ===
Length: 11805 bp
Ambiguous bases (N): 23 (0.19%)

Performing variant calling for Chikungunya...
Total variants called: 42
```

## Contributing

This is a study-purpose repository for collaboration. Feel free to:
- Report issues
- Suggest improvements
- Submit pull requests

## License

This project is for educational and research purposes.

## Contact

For questions or issues, please open an issue on GitHub.
