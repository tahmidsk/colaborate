# collaborate
This is a demo repo to collaborate (study purpose)

## CHIKV Genome Collection Tools

This repository includes tools for collecting and merging Chikungunya virus (CHIKV) genome sequences from multiple continents for phylogenetic analysis.

### Quick Start

```bash
# Install dependencies
pip install -r requirements.txt

# Run the collection tool
./collect_genomes.sh

# Or use Python directly
python3 collect_chikv_genomes.py --help

# Try the example workflow (no internet required)
python3 example_workflow.py
```

### Documentation

See [CHIKV_GENOME_COLLECTION.md](CHIKV_GENOME_COLLECTION.md) for comprehensive documentation including:
- Installation instructions
- Usage examples
- Command-line options
- Workflow for phylogenetic analysis
- Troubleshooting guide

### Files

- `collect_chikv_genomes.py` - Main Python script for collecting genomes from NCBI
- `collect_genomes.sh` - Bash wrapper for easy execution
- `example_workflow.py` - Example script demonstrating the workflow
- `requirements.txt` - Python dependencies
- `CHIKV_GENOME_COLLECTION.md` - Comprehensive documentation

### Features

- 🌍 Collects sequences from Asia, Africa, America, and Europe
- 🔍 Smart geographic filtering and categorization
- 📝 Standardized sequence headers (Strain_Country_Year format)
- 📊 Generates detailed summary reports
- ⚡ Easy-to-use with both CLI and GUI options
