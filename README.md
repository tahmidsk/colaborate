# collaborate
This is a demo repo to collaborate (study purpose)

## CHIKV Genome Collection Tools

This repository includes tools for collecting and merging Chikungunya virus (CHIKV) genome sequences from multiple continents for phylogenetic analysis.

### Quick Start

#### Option 1: Pure Linux Commands (No Python!) 🐧

```bash
# Automated Linux script (uses only curl/wget, grep, sed, awk)
./collect_genomes_linux.sh

# Manual step-by-step demo
./manual_collection_linux.sh

# See full guide
cat LINUX_COMMANDS_GUIDE.md
```

#### Option 2: Python Scripts 🐍

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

- **[LINUX_COMMANDS_GUIDE.md](LINUX_COMMANDS_GUIDE.md)** - **Pure Linux commands** (no Python!)
- [CHIKV_GENOME_COLLECTION.md](CHIKV_GENOME_COLLECTION.md) - Python-based comprehensive documentation
- [QUICK_START.txt](QUICK_START.txt) - Quick reference for Python version

See documentation for:
- Installation instructions
- Usage examples
- Command-line options
- Workflow for phylogenetic analysis
- Troubleshooting guide

### Files

**Linux/Bash only (no Python):**
- `collect_genomes_linux.sh` - Automated Linux script (curl/wget + standard tools)
- `manual_collection_linux.sh` - Manual step-by-step demonstration
- `LINUX_COMMANDS_GUIDE.md` - Complete guide with commands

**Python-based:**
- `collect_chikv_genomes.py` - Main Python script for collecting genomes from NCBI
- `collect_genomes.sh` - Bash wrapper for Python script
- `example_workflow.py` - Example script demonstrating the workflow
- `requirements.txt` - Python dependencies
- `CHIKV_GENOME_COLLECTION.md` - Comprehensive documentation

### Features

- 🐧 **Pure Linux option** - Works without Python, uses only curl/wget/grep/sed/awk
- 🐍 **Python option** - Full-featured with Biopython
- 🌍 Collects sequences from Asia, Africa, America, and Europe
- 🔍 Smart geographic filtering and categorization
- 📝 Standardized sequence headers (Strain_Country_Year format)
- 📊 Generates detailed summary reports
- ⚡ Easy-to-use with both CLI options
