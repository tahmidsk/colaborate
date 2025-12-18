# CHIKV Genome Collection Tool

A comprehensive solution for collecting Chikungunya virus (CHIKV) genome sequences from multiple continents for phylogenetic analysis.

## Overview

This tool automates the process of:
1. Searching NCBI for CHIKV complete genome sequences
2. Filtering sequences by geographic location (Asia, Africa, America, Europe)
3. Selecting representative sequences from each region
4. Creating a multi-FASTA file with properly formatted headers
5. Generating a summary report with sequence metadata

## Features

- 🌍 **Multi-continental coverage**: Collects sequences from Asia, Africa, America, and Europe
- 🔍 **Smart filtering**: Automatically categorizes sequences by geographic region
- 📝 **Standardized headers**: Formats sequence names as `Strain_Country_Year_Accession`
- 📊 **Summary reports**: Generates detailed metadata for all collected sequences
- ⚡ **Easy to use**: Both Python script and bash wrapper available

## Requirements

- Python 3.6 or higher
- Biopython library
- Internet connection to access NCBI databases

## Installation

### 1. Install Python dependencies

```bash
pip install biopython
```

Or if using the bash script, it will automatically install dependencies:

```bash
./collect_genomes.sh
```

### 2. Configure NCBI email (recommended)

Edit `collect_chikv_genomes.py` and set your email:

```python
Entrez.email = "your.email@example.com"
```

Or pass it as a command-line argument (see Usage below).

## Usage

### Quick Start (Bash Script)

The easiest way to collect genomes is using the bash wrapper:

```bash
# Basic usage with defaults (20 sequences per region)
./collect_genomes.sh

# With custom settings
./collect_genomes.sh --max-sequences 300 --sequences-per-region 25 --output my_genomes.fasta

# With NCBI email for compliance
./collect_genomes.sh --email your.email@example.com
```

### Advanced Usage (Python Script)

For more control, use the Python script directly:

```bash
# Basic usage
python3 collect_chikv_genomes.py

# Custom settings
python3 collect_chikv_genomes.py \
    --max-sequences 200 \
    --sequences-per-region 20 \
    --output all_chikv_genomes.fasta \
    --email your.email@example.com

# View help
python3 collect_chikv_genomes.py --help
```

## Command-Line Options

### Bash Script Options

| Option | Short | Description | Default |
|--------|-------|-------------|---------|
| `--max-sequences` | `-m` | Maximum sequences to search | 200 |
| `--sequences-per-region` | `-r` | Sequences per region | 20 |
| `--output` | `-o` | Output FASTA filename | all_chikv_genomes.fasta |
| `--email` | `-e` | Your email for NCBI | (none) |
| `--help` | `-h` | Show help message | - |

### Python Script Options

```
--max-sequences N         Maximum number of sequences to search for
--sequences-per-region N  Number of sequences to select per region
--output FILE            Output FASTA file name
--email ADDRESS          Your email address for NCBI Entrez
```

## Output Files

### 1. Multi-FASTA File (`all_chikv_genomes.fasta`)

Contains genome sequences with formatted headers:

```
>CHIKV_Strain_Country_Year_Accession
ATGACTGATCGATCGATCG...
>CHIKV_Ross_India_2006_KJ451624
ATGACTGATCGATCGATCG...
```

### 2. Summary Report (`all_chikv_genomes_summary.txt`)

Detailed information about collected sequences:

```
================================================================================
CHIKV Genome Sequences Collection Summary
Generated: 2024-12-18 10:30:45
================================================================================

Total sequences collected: 80

Sequences by region:
  Asia           : 20 sequences
  Africa         : 20 sequences
  America        : 20 sequences
  Europe         : 15 sequences
  Other          :  5 sequences

================================================================================
Sequence Details:
================================================================================

1. CHIKV_Ross_India_2006_KJ451624
   Accession: KJ451624
   Description: Chikungunya virus isolate Ross, complete genome...
   Length: 11825 bp
   Country: India, Year: 2006
   ...
```

## Workflow for Phylogenetic Analysis

### Step 1: Collect Reference Genomes

```bash
./collect_genomes.sh --sequences-per-region 20 --output reference_genomes.fasta
```

### Step 2: Add Your Assembled Genome

Add your assembled/consensus genome to the FASTA file:

```bash
cat your_assembled_genome.fasta >> reference_genomes.fasta
```

Or manually edit the file to add:

```
>CHIKV_YourStrain_YourCountry_2024_Local
ATGACTGATCGATCGATCG...
```

### Step 3: Perform Multiple Sequence Alignment

Using MAFFT:

```bash
mafft --auto reference_genomes.fasta > aligned_genomes.fasta
```

Using Clustal Omega:

```bash
clustalo -i reference_genomes.fasta -o aligned_genomes.fasta --auto
```

### Step 4: Build Phylogenetic Tree

Using IQ-TREE:

```bash
iqtree -s aligned_genomes.fasta -m TEST -bb 1000 -alrt 1000
```

Using RAxML:

```bash
raxmlHPC -s aligned_genomes.fasta -n chikv_tree -m GTRGAMMA -p 12345 -# 100
```

### Step 5: Visualize the Tree

Use tools like:
- FigTree (GUI)
- iTOL (online)
- ggtree (R package)
- Dendroscope (GUI)

## Examples

### Example 1: Basic Collection

```bash
./collect_genomes.sh
```

This will:
- Search for up to 200 CHIKV genomes in NCBI
- Select 20 sequences from each continent
- Create `all_chikv_genomes.fasta` with ~80 sequences
- Generate `all_chikv_genomes_summary.txt` with metadata

### Example 2: Larger Dataset

```bash
./collect_genomes.sh --max-sequences 500 --sequences-per-region 50
```

This creates a larger dataset with ~200 sequences total.

### Example 3: Custom Output with Email

```bash
python3 collect_chikv_genomes.py \
    --max-sequences 300 \
    --sequences-per-region 30 \
    --output my_chikv_dataset.fasta \
    --email researcher@university.edu
```

### Example 4: Adding Your Genome

```bash
# Collect reference genomes
./collect_genomes.sh -o reference.fasta

# Create your genome entry
echo ">CHIKV_MyStrain_USA_2024_Assembly" > my_genome.fasta
cat your_consensus_sequence.txt >> my_genome.fasta

# Combine
cat reference.fasta my_genome.fasta > complete_dataset.fasta
```

## Geographic Regions Covered

### Asia (16 countries)
India, Thailand, Indonesia, Singapore, Philippines, Malaysia, Sri Lanka, Maldives, Bangladesh, Pakistan, China, Taiwan, Japan, Vietnam, Cambodia, Myanmar

### Africa (18 countries)
Kenya, Tanzania, Uganda, Congo, Senegal, Gabon, Central African Republic, Sudan, Comoros, Seychelles, Madagascar, Reunion, Mayotte, South Africa, Nigeria, Cameroon, Angola, Mozambique

### America (24 countries/territories)
Brazil, Colombia, Caribbean, Venezuela, Mexico, USA, Puerto Rico, Dominican Republic, Haiti, Martinique, Guadeloupe, Argentina, Ecuador, Bolivia, Paraguay, Peru, Chile, Nicaragua, Honduras, El Salvador, Guatemala, Panama, Costa Rica

### Europe (16 countries)
Italy, France, Spain, Greece, Netherlands, Germany, Switzerland, United Kingdom, Belgium, Austria, Portugal, Sweden, Norway, Denmark, Finland, Poland

## Tips and Best Practices

1. **NCBI Compliance**: Always provide your email using the `--email` option for NCBI tracking

2. **Sequence Selection**: Start with 20-25 sequences per region for a balanced dataset

3. **Quality Check**: Review the summary file to ensure geographic diversity

4. **Recommended Total**: 50-100 sequences is optimal for phylogenetic analysis
   - Too few (<30): May miss important lineages
   - Too many (>200): Computationally expensive, may include redundancy

5. **Header Format**: Keep headers consistent - the tool formats them as:
   ```
   >CHIKV_StrainName_Country_Year_AccessionNumber
   ```

6. **Before Alignment**: Check sequence lengths in the summary file
   - Complete genomes should be ~11,000-12,000 bp
   - Remove any partial sequences if needed

7. **Merging with Your Data**: Ensure your assembled genome follows the same header format

## Troubleshooting

### Issue: "Biopython not found"

**Solution**: Install Biopython:
```bash
pip install biopython
# or
python3 -m pip install biopython --user
```

### Issue: "No sequences found"

**Solution**: 
- Check your internet connection
- NCBI might be temporarily unavailable - try again later
- Increase `--max-sequences` value

### Issue: "Rate limit exceeded"

**Solution**:
- Provide your email with `--email` option
- The script includes automatic delays between requests
- If problem persists, wait a few hours before retrying

### Issue: "Python command not found"

**Solution**: Ensure Python 3 is installed:
```bash
# Check Python installation
python3 --version

# If not installed, install it:
# Ubuntu/Debian
sudo apt-get install python3 python3-pip

# macOS
brew install python3

# Windows
# Download from python.org
```

## Data Source

All sequence data is retrieved from NCBI Nucleotide database using the Entrez E-utilities API.

**Citation**: When using this data, please cite the original sequence submissions and NCBI:
- Individual sequences: See GenBank accession numbers in the summary file
- NCBI: https://www.ncbi.nlm.nih.gov/

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests to improve:
- Geographic coverage (add more countries)
- Sequence filtering logic
- Output formats
- Documentation

## License

This tool is provided for educational and research purposes. Please ensure compliance with NCBI's usage policies and cite original data sources appropriately.

## Support

For issues or questions:
1. Check the Troubleshooting section above
2. Review the summary file for details about collected sequences
3. Ensure all requirements are installed
4. Check NCBI status if connection issues persist

## Version History

- **v1.0** (2024-12-18): Initial release
  - Multi-continental genome collection
  - Automated sequence categorization
  - Summary report generation
  - Bash wrapper for easy usage

---

**Happy Phylogenetic Analysis! 🧬🌍**
