# CHIKV Genome Collection - Pure Linux Commands

Complete guide for collecting CHIKV genome sequences using **only Linux tools** (no Python required).

## 📋 Requirements

**Required:**
- `curl` or `wget` (for downloading)
- `grep` (for filtering)
- `sed` (for text processing)
- `awk` (for data extraction)

**Optional (for alignment & phylogeny):**
- `mafft` or `clustalo` (for alignment)
- `iqtree` or `raxml` (for phylogenetic trees)

## 🚀 Quick Start

### Option 1: Automated Script

```bash
# Run the automated Linux script
./collect_genomes_linux.sh

# With custom settings
./collect_genomes_linux.sh --max-sequences 200 --sequences-per-region 20 --output genomes.fasta --email your@email.com
```

### Option 2: Manual Step-by-Step

```bash
# Run the manual demonstration
./manual_collection_linux.sh
```

### Option 3: Individual Commands (Copy & Paste)

See the "Manual Commands" section below.

## 📝 Manual Commands Guide

### Step 1: Search for CHIKV Sequences

```bash
# Set your email (required by NCBI)
EMAIL="your.email@example.com"

# Search NCBI for CHIKV complete genomes
curl -s "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=nucleotide&term=Chikungunya+virus[Organism]+AND+complete+genome[Title]&retmax=100&usehistory=y&retmode=xml&email=${EMAIL}" > search.xml

# Extract search results
WEBENV=$(grep -oP '(?<=<WebEnv>)[^<]+' search.xml)
QUERYKEY=$(grep -oP '(?<=<QueryKey>)[^<]+' search.xml)
COUNT=$(grep -oP '(?<=<Count>)[^<]+' search.xml)

echo "Found $COUNT sequences"
```

### Step 2: Download Sequences

```bash
# Download all sequences in FASTA format
curl -s "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nucleotide&query_key=${QUERYKEY}&WebEnv=${WEBENV}&rettype=fasta&retmode=text&email=${EMAIL}" > all_chikv.fasta

# Count sequences
grep -c "^>" all_chikv.fasta
```

### Step 3: Filter by Geographic Region

#### Filter by Asia

```bash
grep -A 1000 "^>" all_chikv.fasta | \
  awk '/^>/ && /(India|Thailand|Indonesia|Singapore|Malaysia)/ {found=1} 
       /^>/ && !/(India|Thailand|Indonesia|Singapore|Malaysia)/ {found=0} 
       found' > asia.fasta
```

#### Filter by Africa

```bash
awk '/^>/ && /(Kenya|Tanzania|Senegal|Uganda|Madagascar)/ {found=1} 
     /^>/ && !/(Kenya|Tanzania|Senegal|Uganda|Madagascar)/ {found=0} 
     found' all_chikv.fasta > africa.fasta
```

#### Filter by America

```bash
awk '/^>/ && /(Brazil|Colombia|USA|Caribbean|Venezuela)/ {found=1} 
     /^>/ && !/(Brazil|Colombia|USA|Caribbean|Venezuela)/ {found=0} 
     found' all_chikv.fasta > america.fasta
```

#### Filter by Europe

```bash
awk '/^>/ && /(Italy|France|Spain|Greece|Netherlands)/ {found=1} 
     /^>/ && !/(Italy|France|Spain|Greece|Netherlands)/ {found=0} 
     found' all_chikv.fasta > europe.fasta
```

### Step 4: Select Representative Sequences

```bash
# Select first 20 sequences from each region
for region in asia africa america europe; do
  awk 'BEGIN{count=0} /^>/{count++} count<=20' ${region}.fasta >> selected.fasta
done

# Count total selected
grep -c "^>" selected.fasta
```

### Step 5: Format Headers

```bash
# Format headers as: >CHIKV_Country_Year_Accession
while IFS= read -r line; do
  if [[ "$line" == ">"* ]]; then
    # Extract accession
    ACC=$(echo "$line" | sed 's/^>//' | awk '{print $1}')
    
    # Extract country (basic extraction)
    COUNTRY=$(echo "$line" | grep -oP '(?<=:)[^:,]+' | head -1 | tr ' ' '_')
    
    # Extract year
    YEAR=$(echo "$line" | grep -oP '\b(19|20)\d{2}\b' | head -1)
    
    # Format header
    echo ">CHIKV_${COUNTRY:-Unknown}_${YEAR:-Unknown}_${ACC}"
  else
    echo "$line"
  fi
done < selected.fasta > formatted.fasta
```

### Step 6: Merge with Your Assembled Genome

```bash
# Add your assembled genome
cat your_assembled_genome.fasta >> formatted.fasta

# Or manually add with proper header
echo ">CHIKV_YourStrain_YourCountry_2024_Assembly" >> formatted.fasta
cat your_consensus_sequence.txt >> formatted.fasta
```

## 📊 Data Analysis Commands

### Count Sequences

```bash
# Count total sequences
grep -c "^>" genomes.fasta

# Count by region
grep "^>" genomes.fasta | grep -ic "India"
grep "^>" genomes.fasta | grep -ic "Kenya"
grep "^>" genomes.fasta | grep -ic "Brazil"
grep "^>" genomes.fasta | grep -ic "Italy"
```

### List Sequence Headers

```bash
# List all headers
grep "^>" genomes.fasta

# List with line numbers
grep "^>" genomes.fasta | nl

# Extract accessions only
grep "^>" genomes.fasta | sed 's/^>//' | awk '{print $1}'
```

### Calculate Sequence Lengths

```bash
# Calculate length of each sequence
awk '/^>/ {if (seq) print name, length(seq); name=$0; seq=""} 
     !/^>/ {seq=seq$0} 
     END {if (seq) print name, length(seq)}' genomes.fasta
```

### Extract Specific Sequences

```bash
# Extract sequences from India
awk '/^>.*India/ {found=1} /^>/ && !/India/ {found=0} found' genomes.fasta

# Extract first 10 sequences
awk 'BEGIN{count=0} /^>/{count++} count<=10' genomes.fasta

# Extract sequence by accession
awk '/^>.*KJ451624/ {found=1} /^>/ && !/KJ451624/ {found=0} found' genomes.fasta
```

## 🧬 Phylogenetic Analysis Workflow

### 1. Multiple Sequence Alignment

#### Using MAFFT

```bash
# Install MAFFT (if needed)
sudo apt-get install mafft  # Ubuntu/Debian
# or
brew install mafft  # macOS

# Align sequences
mafft --auto formatted.fasta > aligned.fasta

# Or with more options
mafft --maxiterate 1000 --globalpair formatted.fasta > aligned.fasta
```

#### Using Clustal Omega

```bash
# Install Clustal Omega (if needed)
sudo apt-get install clustalo  # Ubuntu/Debian

# Align sequences
clustalo -i formatted.fasta -o aligned.fasta --auto
```

### 2. Build Phylogenetic Tree

#### Using IQ-TREE

```bash
# Install IQ-TREE
sudo apt-get install iqtree  # Ubuntu/Debian

# Build tree with bootstrap
iqtree -s aligned.fasta -m TEST -bb 1000 -alrt 1000

# Output files:
# - aligned.fasta.treefile (main tree)
# - aligned.fasta.iqtree (analysis report)
```

#### Using RAxML

```bash
# Install RAxML
sudo apt-get install raxml  # Ubuntu/Debian

# Build tree
raxmlHPC -s aligned.fasta -n chikv_tree -m GTRGAMMA -p 12345 -# 100

# Output: RAxML_bestTree.chikv_tree
```

### 3. Visualize Tree

```bash
# View tree in terminal (simple)
cat aligned.fasta.treefile

# Or use online tools:
# - Upload to iTOL: https://itol.embl.de/
# - Upload to FigTree (download first)

# Convert tree format if needed
# Newick to Nexus
cat aligned.fasta.treefile | sed 's/$/;/' > tree.nex
```

## 🔧 Useful One-Liners

### Quality Control

```bash
# Check for sequences shorter than 10000 bp
awk '/^>/ {name=$0} !/^>/ {seq[name]=seq[name]$0} END {for (n in seq) if (length(seq[n])<10000) print n, length(seq[n])}' genomes.fasta

# Remove duplicate sequences
awk '/^>/ {if (seq && !seen[seq]++) print name RS seq; name=$0; seq=""} !/^>/ {seq=seq$0} END {if (seq && !seen[seq]++) print name RS seq}' genomes.fasta

# Check for ambiguous bases
grep -v "^>" genomes.fasta | grep -o "[^ATGC]" | sort | uniq -c
```

### Format Conversion

```bash
# FASTA to single line per sequence
awk '/^>/ {if (seq) print seq; print; seq=""} !/^>/ {seq=seq$0} END {print seq}' genomes.fasta

# Split multi-FASTA into individual files
awk '/^>/ {file=sprintf("seq_%03d.fasta", ++count)} {print > file}' genomes.fasta

# Reverse complement (requires bioawk or custom script)
# Install: sudo apt-get install bioawk
bioawk -c fastx '{print ">"$name; print revcomp($seq)}' genomes.fasta
```

### Statistics

```bash
# Calculate GC content
awk '!/^>/ {gc+=gsub(/[GCgc]/,""); at+=gsub(/[ATat]/,""); total+=length($0)} END {print "GC%:", (gc/(gc+at))*100}' genomes.fasta

# Average sequence length
awk '/^>/ {if (seq) {sum+=length(seq); count++} seq=""} !/^>/ {seq=seq$0} END {if (seq) {sum+=length(seq); count++} print "Average:", sum/count}' genomes.fasta

# Sequence length distribution
awk '/^>/ {name=$0} !/^>/ {seq[name]=seq[name]$0} END {for (n in seq) print length(seq[n])}' genomes.fasta | sort -n | uniq -c
```

## 📦 Complete Example Script

Here's a complete example combining all steps:

```bash
#!/bin/bash
# Complete CHIKV collection workflow

EMAIL="your.email@example.com"
OUTPUT="chikv_dataset.fasta"

# 1. Search and download
echo "Searching NCBI..."
curl -s "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=nucleotide&term=Chikungunya+virus[Organism]+AND+complete+genome[Title]&retmax=100&usehistory=y&retmode=xml&email=${EMAIL}" > search.xml

WEBENV=$(grep -oP '(?<=<WebEnv>)[^<]+' search.xml)
QUERYKEY=$(grep -oP '(?<=<QueryKey>)[^<]+' search.xml)

echo "Downloading sequences..."
curl -s "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nucleotide&query_key=${QUERYKEY}&WebEnv=${WEBENV}&rettype=fasta&retmode=text&email=${EMAIL}" > all.fasta

# 2. Filter by regions and select
echo "Filtering by region..."
for region in "India|Thailand|Indonesia" "Kenya|Tanzania|Senegal" "Brazil|Colombia|USA" "Italy|France|Spain"; do
  awk -v pat="$region" '/^>/ && $0 ~ pat {found=1} /^>/ && $0 !~ pat {found=0} found' all.fasta | awk 'BEGIN{c=0} /^>/{c++} c<=5' >> "$OUTPUT"
done

# 3. Count and report
TOTAL=$(grep -c "^>" "$OUTPUT")
echo "Collected $TOTAL sequences"
echo "Saved to: $OUTPUT"

# 4. Next steps
echo ""
echo "Next steps:"
echo "  mafft --auto $OUTPUT > aligned.fasta"
echo "  iqtree -s aligned.fasta -m TEST -bb 1000"
```

## 🆘 Troubleshooting

### Issue: curl/wget not found

```bash
# Install curl
sudo apt-get install curl  # Ubuntu/Debian
brew install curl  # macOS

# Or use wget
sudo apt-get install wget
```

### Issue: NCBI rate limiting

```bash
# Add delays between requests
sleep 1

# Use smaller batches
# Split downloads into multiple smaller requests
```

### Issue: Special characters in headers

```bash
# Clean headers
sed 's/[^A-Za-z0-9_>-]/_/g' input.fasta > cleaned.fasta
```

### Issue: Sequences too long/short

```bash
# Filter by length (keep 10000-13000 bp)
awk '/^>/ {name=$0} !/^>/ {seq[name]=seq[name]$0} END {for (n in seq) {l=length(seq[n]); if (l>=10000 && l<=13000) print n RS seq[n]}}' input.fasta
```

## 📚 Additional Resources

- **NCBI E-utilities**: https://www.ncbi.nlm.nih.gov/books/NBK25500/
- **MAFFT Manual**: https://mafft.cbrc.jp/alignment/software/
- **IQ-TREE Docs**: http://www.iqtree.org/doc/
- **AWK Tutorial**: https://www.gnu.org/software/gawk/manual/

## 💡 Tips

1. **Always provide email**: NCBI requires an email for API usage tracking
2. **Be patient**: Large downloads may take several minutes
3. **Verify sequences**: Check sequence length and quality before analysis
4. **Backup data**: Keep copies of downloaded sequences
5. **Document**: Note which sequences you selected and why

---

**No Python required! All commands work on any Linux system with standard tools.**
