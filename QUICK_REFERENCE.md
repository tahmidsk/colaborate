# Quick Reference Guide

## Installation

```bash
# 1. Clone repository
git clone https://github.com/tahmidsk/colaborate.git
cd colaborate

# 2. Run setup
./setup.sh
```

## Quick Commands

### Complete Workflow (Recommended)
```bash
# Place FASTA files in data/chikungunya/ and data/zika/
# Then run:
./run_analysis.sh
```

### Consensus Generation Only
```bash
# For Chikungunya (4 sequences)
python3 consensus_generation.py \
    -i data/chikungunya/*.fasta \
    -o results/chikv_consensus.fasta \
    --metrics

# For Zika S-22
python3 consensus_generation.py \
    -i data/zika/zikv_s22.fasta \
    -o results/zikv_consensus.fasta \
    --metrics
```

### Variant Calling Only
```bash
# For Chikungunya
python3 variant_calling.py \
    -r data/chikungunya/chikv_1.fasta \
    -s data/chikungunya/chikv_*.fasta \
    -o results/chikv_variants.vcf \
    --summary
```

## File Structure

```
data/
├── chikungunya/
│   ├── chikv_1.fasta
│   ├── chikv_2.fasta
│   ├── chikv_3.fasta
│   └── chikv_4.fasta
└── zika/
    └── zikv_s22.fasta
```

## Output Files

- **Consensus FASTA**: Contains consensus sequence
- **Variants VCF**: Contains detected variants in standard VCF format

## Common Parameters

### Consensus Generation
- `-i`: Input FASTA files
- `-o`: Output file
- `--metrics`: Show quality metrics
- `-m majority`: Use majority voting (default)
- `-t 0.25`: Ambiguity threshold (default)

### Variant Calling
- `-r`: Reference genome
- `-s`: Sample genomes
- `-o`: Output VCF file
- `--summary`: Show variant summary
- `-f 0.25`: Min allele frequency (default)

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Module 'Bio' not found | `pip install biopython` |
| Permission denied | `chmod +x run_analysis.sh` |
| No sequences found | Check file paths and format |
| Script won't run | `python3 script_name.py` |

## Getting Help

```bash
python3 consensus_generation.py --help
python3 variant_calling.py --help
```

## Full Documentation

- `README.md` - Complete overview
- `USAGE_GUIDE.md` - Detailed usage examples
- `DATA_STRUCTURE.txt` - Directory structure
