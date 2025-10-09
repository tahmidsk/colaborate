# collaborate
This is a demo repo to collaborate (study purpose)

## How to Run Kraken 2 for Quality Control (QC)

Kraken 2 is a taxonomic classification system used for assigning taxonomic labels to DNA sequences. It's commonly used in quality control workflows to identify contamination or verify sample composition in metagenomic studies.

### Prerequisites

- Linux or macOS operating system
- At least 8 GB RAM (more recommended for larger databases)
- Sufficient disk space for databases (varies by database size)

### Installation

#### Option 1: Using Conda (Recommended)
```bash
# Install via conda
conda install -c bioconda kraken2

# Or create a dedicated environment
conda create -n kraken2 -c bioconda kraken2
conda activate kraken2
```

#### Option 2: From Source
```bash
# Clone the repository
git clone https://github.com/DerrickWood/kraken2.git
cd kraken2

# Install
./install_kraken2.sh /path/to/installation/directory

# Add to PATH
export PATH="/path/to/installation/directory:$PATH"
```

### Database Setup

Kraken 2 requires a reference database to classify sequences. You can download pre-built databases or build your own.

#### Download Pre-built Databases

```bash
# Create a directory for databases
mkdir -p kraken2_db

# Download a standard database (requires ~100 GB disk space)
kraken2-build --standard --db kraken2_db/standard

# Or download a smaller database for testing
kraken2-build --download-taxonomy --db kraken2_db/minikraken
kraken2-build --download-library bacteria --db kraken2_db/minikraken
kraken2-build --build --db kraken2_db/minikraken
```

#### Alternative: Download MiniKraken Database
```bash
# Download pre-built MiniKraken database (8GB, faster for testing)
wget ftp://ftp.ccb.jhu.edu/pub/data/kraken2_dbs/old/minikraken2_v2_8GB_201904.tgz
tar -xvzf minikraken2_v2_8GB_201904.tgz
```

### Running Kraken 2 for QC

#### Basic Usage

For single-end reads:
```bash
kraken2 --db kraken2_db/standard \
        --threads 4 \
        --report sample_report.txt \
        --output sample_output.txt \
        input_reads.fastq
```

For paired-end reads:
```bash
kraken2 --db kraken2_db/standard \
        --threads 4 \
        --paired \
        --report sample_report.txt \
        --output sample_output.txt \
        read1.fastq read2.fastq
```

#### Parameters Explained

- `--db`: Path to Kraken 2 database directory
- `--threads`: Number of CPU threads to use
- `--report`: Output file with taxonomy report
- `--output`: Output file with per-read classifications
- `--paired`: Use for paired-end reads
- `--gzip-compressed`: If input files are gzip-compressed
- `--fastq-input`: Specify FASTQ input (default)
- `--confidence`: Confidence score threshold (0-1, default 0)

#### Quality Control Workflow

1. **Run Kraken 2 on your samples:**
```bash
# For each sample
kraken2 --db kraken2_db/standard \
        --threads 8 \
        --report sample1_kraken_report.txt \
        --output sample1_kraken_output.txt \
        --paired \
        sample1_R1.fastq.gz sample1_R2.fastq.gz
```

2. **Check for contamination:**
```bash
# View the top hits in the report
head -20 sample1_kraken_report.txt

# Look for unexpected organisms or high percentage of classified reads
# from non-target species
```

3. **Generate summary statistics:**
```bash
# Count classified vs unclassified reads
grep -c "^C" sample1_kraken_output.txt  # Classified
grep -c "^U" sample1_kraken_output.txt  # Unclassified
```

### Interpreting Results

#### Kraken Report Format

The report file contains columns:
1. **Percentage of reads**: Covered by this taxon
2. **Number of reads**: Covered by this taxon
3. **Number of reads**: Assigned directly to this taxon
4. **Taxonomic rank**: (U)nclassified, (D)omain, (K)ingdom, (P)hylum, (C)lass, (O)rder, (F)amily, (G)enus, (S)pecies
5. **Taxon ID**: NCBI taxonomy ID
6. **Scientific name**: Name of the taxon

Example:
```
 45.23  1000000    500000  U       0       unclassified
 54.77  1210000         0  R       1       root
 50.00  1100000      1000  D       2       Bacteria
 30.00   660000     10000  P       1239      Firmicutes
 25.00   550000     50000  C       91061       Bacilli
```

#### QC Checklist

- [ ] **Contamination check**: Look for unexpected organisms
- [ ] **Classification rate**: At least 50-80% of reads should be classified for well-characterized samples
- [ ] **Dominant taxa**: Verify expected species/genera are present at expected proportions
- [ ] **Human contamination**: Check for human DNA if not expected
- [ ] **Environmental contaminants**: Look for common lab contaminants (e.g., *Ralstonia*, *Delftia*)

### Visualization

Use **Krona** for interactive visualization:

```bash
# Install Krona
conda install -c bioconda krona

# Convert Kraken report to Krona format
ktImportTaxonomy -q 2 -t 3 sample1_kraken_output.txt -o sample1_krona.html

# Open in browser
firefox sample1_krona.html
```

Or use **Pavian** (R-based interactive tool):
```R
# In R
install.packages("pavian")
library(pavian)
pavian::runApp(port=5000)
# Upload your Kraken reports through the web interface
```

### Filtering Contamination

If contamination is detected, filter reads:

```bash
# Extract reads classified to a specific taxon (e.g., bacteria - taxID 2)
extract_kraken_reads.py -k sample1_kraken_output.txt \
                        -s sample1_R1.fastq.gz \
                        -s2 sample1_R2.fastq.gz \
                        -o sample1_bacteria_R1.fastq \
                        -o2 sample1_bacteria_R2.fastq \
                        -t 2 \
                        --include-children
```

### Advanced Options

#### Confidence Score Filtering
Use `--confidence` to require a minimum confidence score (reduces false positives):
```bash
kraken2 --db kraken2_db/standard \
        --confidence 0.5 \
        --report sample_report.txt \
        --output sample_output.txt \
        input_reads.fastq
```

#### Memory Mapping
For faster repeated runs:
```bash
kraken2 --db kraken2_db/standard \
        --memory-mapping \
        --report sample_report.txt \
        --output sample_output.txt \
        input_reads.fastq
```

### Troubleshooting

**Issue**: Out of memory error
- **Solution**: Use a smaller database (e.g., MiniKraken) or increase system RAM

**Issue**: Low classification rate
- **Solution**: Check if database matches your sample type; build custom database if needed

**Issue**: Slow performance
- **Solution**: Increase `--threads` parameter; use `--memory-mapping` option

### Additional Resources

- [Kraken 2 GitHub Repository](https://github.com/DerrickWood/kraken2)
- [Kraken 2 Manual](https://github.com/DerrickWood/kraken2/wiki)
- [Kraken 2 Paper](https://genomebiology.biomedcentral.com/articles/10.1186/s13059-019-1891-0)
- [Krona Visualization Tool](https://github.com/marbl/Krona/wiki)
- [Pavian Visualization](https://github.com/fbreitwieser/pavian)

### Quick Reference Commands

```bash
# Basic run (single-end)
kraken2 --db DB_PATH --threads 8 --report report.txt --output output.txt reads.fastq

# Paired-end with gzipped files
kraken2 --db DB_PATH --threads 8 --paired --gzip-compressed \
        --report report.txt --output output.txt R1.fastq.gz R2.fastq.gz

# With confidence threshold
kraken2 --db DB_PATH --confidence 0.5 --report report.txt reads.fastq

# View classification summary
head -20 report.txt

# Count classified reads
grep -c "^C" output.txt
```
