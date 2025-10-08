# Phylogenetic Analysis Pipeline for Chikungunya Virus Whole Genome Data

This document provides a comprehensive step-by-step pipeline for conducting phylogenetic analysis of Chikungunya virus (CHIKV) whole genome sequences.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Data Acquisition](#data-acquisition)
3. [Quality Control](#quality-control)
4. [Genome Assembly](#genome-assembly)
5. [Multiple Sequence Alignment](#multiple-sequence-alignment)
6. [Phylogenetic Tree Construction](#phylogenetic-tree-construction)
7. [Tree Visualization and Analysis](#tree-visualization-and-analysis)
8. [Software and Tools](#software-and-tools)

---

## Prerequisites

### Required Software
- **FastQC** (v0.11.9+): Quality control of sequencing data
- **Trimmomatic** (v0.39+): Read trimming and filtering
- **SPAdes** or **MEGAHIT**: Genome assembly
- **BWA** or **Bowtie2**: Read mapping
- **SAMtools**: BAM file manipulation
- **MAFFT** (v7.450+): Multiple sequence alignment
- **IQ-TREE** (v2.0+): Phylogenetic tree construction
- **RAxML-NG**: Alternative phylogenetic inference
- **FigTree** or **iTOL**: Tree visualization
- **BEAST2** (optional): Bayesian phylogenetic analysis

### Required Skills
- Basic command-line proficiency
- Understanding of molecular evolution concepts
- Familiarity with phylogenetic methods

---

## Data Acquisition

### Step 1: Obtain Raw Sequencing Data

#### Option A: Download from Public Databases
```bash
# From NCBI SRA (Sequence Read Archive)
# Install SRA Toolkit first
prefetch SRR1234567
fastq-dump --split-files SRR1234567

# From NCBI GenBank (for reference genomes)
# Use NCBI Datasets CLI or manual download
datasets download virus genome taxon chikungunya --filename chikv_genomes.zip
unzip chikv_genomes.zip
```

#### Option B: Your Own Sequencing Data
- Illumina paired-end reads (FASTQ format)
- Nanopore long reads (FASTQ/FASTA format)
- Expected genome size: ~11.8 kb (single-stranded RNA)

### Step 2: Download Reference Genome
```bash
# Download CHIKV reference genome (e.g., AF369024.2)
# From NCBI Nucleotide database
# Save as: chikv_reference.fasta
```

---

## Quality Control

### Step 3: Assess Read Quality

```bash
# Run FastQC on raw reads
fastqc raw_reads_R1.fastq.gz raw_reads_R2.fastq.gz -o fastqc_results/

# Review HTML reports for:
# - Per base sequence quality
# - Adapter content
# - GC content
# - Sequence duplication levels
```

### Step 4: Trim and Filter Reads

```bash
# Using Trimmomatic for paired-end reads
trimmomatic PE -phred33 \
    raw_reads_R1.fastq.gz raw_reads_R2.fastq.gz \
    trimmed_R1_paired.fastq.gz trimmed_R1_unpaired.fastq.gz \
    trimmed_R2_paired.fastq.gz trimmed_R2_unpaired.fastq.gz \
    ILLUMINACLIP:adapters.fa:2:30:10 \
    LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36

# Re-run FastQC on trimmed reads
fastqc trimmed_R1_paired.fastq.gz trimmed_R2_paired.fastq.gz -o fastqc_trimmed/
```

---

## Genome Assembly

### Step 5: De Novo Assembly (if starting from reads)

#### Option A: Using SPAdes
```bash
# For RNA virus assembly
spades.py --rnaviral \
    -1 trimmed_R1_paired.fastq.gz \
    -2 trimmed_R2_paired.fastq.gz \
    -o spades_assembly/ \
    -t 8 -m 16

# Extract assembled contigs
cp spades_assembly/contigs.fasta chikv_assembled.fasta
```

#### Option B: Reference-Based Assembly
```bash
# Index reference genome
bwa index chikv_reference.fasta

# Map reads to reference
bwa mem -t 8 chikv_reference.fasta \
    trimmed_R1_paired.fastq.gz \
    trimmed_R2_paired.fastq.gz | \
    samtools view -bS - | \
    samtools sort -o mapped_reads.bam

# Index BAM file
samtools index mapped_reads.bam

# Generate consensus sequence
samtools mpileup -uf chikv_reference.fasta mapped_reads.bam | \
    bcftools call -c | \
    vcfutils.pl vcf2fq > consensus.fq

# Convert fastq to fasta
seqtk seq -A consensus.fq > chikv_consensus.fasta
```

### Step 6: Assembly Quality Check

```bash
# Check assembly statistics
# Install QUAST
quast.py chikv_assembled.fasta -r chikv_reference.fasta -o quast_results/

# Expected metrics:
# - Genome length: ~11.8 kb
# - Number of contigs: ideally 1
# - Coverage depth: >100x recommended
```

---

## Multiple Sequence Alignment

### Step 7: Collect Multiple Genome Sequences

```bash
# Combine your assembled genome with reference sequences
# Create a multi-FASTA file: all_chikv_genomes.fasta
# Include:
# - Your assembled/consensus genome(s)
# - Reference genomes from different CHIKV lineages
# - Genomes from different geographic locations/time points
# Recommended: 20-100 sequences for robust phylogeny

# Format sequence headers (important!)
# Use descriptive names: >Strain_Country_Year
# Example: >CHIKV_India_2006
```

### Step 8: Perform Multiple Sequence Alignment

```bash
# Using MAFFT (recommended for viral genomes)
mafft --auto --thread 8 all_chikv_genomes.fasta > aligned_genomes.fasta

# Alternative: Using MUSCLE
muscle -in all_chikv_genomes.fasta -out aligned_genomes.fasta

# Alternative: Using Clustal Omega
clustalo -i all_chikv_genomes.fasta -o aligned_genomes.fasta --threads=8
```

### Step 9: Refine and Trim Alignment

```bash
# Remove poorly aligned regions using trimAl
trimal -in aligned_genomes.fasta \
    -out aligned_trimmed.fasta \
    -automated1

# Or manually inspect and edit in alignment viewer
# Recommended: AliView, MEGA, or Jalview
```

---

## Phylogenetic Tree Construction

### Step 10: Choose Substitution Model

```bash
# Use ModelTest-NG or IQ-TREE to select best model
# Using IQ-TREE's built-in model selection
iqtree -s aligned_trimmed.fasta -m MFP -bb 1000 -nt AUTO

# Common models for CHIKV:
# - GTR+G+I (General Time Reversible with gamma and invariant sites)
# - HKY+G (Hasegawa-Kishino-Yano with gamma)
```

### Step 11: Maximum Likelihood Phylogenetic Analysis

#### Option A: Using IQ-TREE (Recommended)
```bash
# Run IQ-TREE with ultrafast bootstrap
iqtree -s aligned_trimmed.fasta \
    -m GTR+G+I \
    -bb 1000 \
    -alrt 1000 \
    -nt AUTO \
    -pre chikv_tree

# Output files:
# - chikv_tree.treefile: Best ML tree in Newick format
# - chikv_tree.iqtree: Full analysis report
# - chikv_tree.log: Log file
```

#### Option B: Using RAxML-NG
```bash
# Run RAxML-NG
raxml-ng --all \
    --msa aligned_trimmed.fasta \
    --model GTR+G+I \
    --prefix chikv_raxml \
    --threads auto \
    --bs-trees 1000

# Output: chikv_raxml.raxml.bestTree
```

### Step 12: Bayesian Phylogenetic Analysis (Optional)

```bash
# Using BEAST2 for time-calibrated phylogeny
# 1. Prepare XML configuration file using BEAUti
#    - Import aligned sequences
#    - Specify molecular clock model
#    - Set MCMC parameters (chain length: 10M-100M)
#    - Add sampling dates if temporal data available

# 2. Run BEAST2
beast -beagle_SSE chikv_beast.xml

# 3. Check convergence with Tracer
#    - Ensure ESS values > 200
#    - Check trace plots for stationarity

# 4. Summarize trees with TreeAnnotator
treeannotator -burnin 10 chikv_beast.trees chikv_mcc.tree
```

---

## Tree Visualization and Analysis

### Step 13: Visualize Phylogenetic Tree

#### Using FigTree (Desktop Application)
```bash
# Open chikv_tree.treefile in FigTree
# Customize:
# - Display bootstrap values (node labels)
# - Color branches by lineage/geography
# - Scale tree by genetic distance or time
# - Export as PDF/PNG for publication
```

#### Using iTOL (Interactive Tree of Life - Web-based)
```bash
# 1. Upload tree file to https://itol.embl.de/
# 2. Annotate with metadata:
#    - Geographic origin (colored strips)
#    - Temporal data (timeline)
#    - Lineage classification (colored branches)
# 3. Export high-resolution figure
```

#### Using R (ggtree package)
```r
# Install packages
install.packages("BiocManager")
BiocManager::install("ggtree")

# Load packages
library(ggtree)
library(treeio)

# Read tree
tree <- read.tree("chikv_tree.treefile")

# Plot basic tree
ggtree(tree) + 
  geom_tiplab(size=3) + 
  geom_nodelab(aes(label=label), size=2) +
  theme_tree2()

# Save plot
ggsave("chikv_phylogeny.pdf", width=10, height=8)
```

### Step 14: Interpret Phylogenetic Results

#### Key Analyses:
1. **Lineage Identification**
   - CHIKV has three major lineages: West African, East/Central/South African (ECSA), and Asian
   - Identify which lineage(s) your sequences belong to
   - Look for lineage-specific clades

2. **Geographic Clustering**
   - Do sequences from the same region cluster together?
   - Identify potential transmission pathways

3. **Temporal Patterns**
   - If dates available, assess evolutionary rates
   - Identify emergence and spread patterns

4. **Bootstrap Support**
   - Values ≥70% indicate moderate support
   - Values ≥95% indicate strong support
   - Low support suggests uncertainty in relationships

5. **Genetic Distance**
   - Calculate pairwise distances
   - Identify closely related sequences (potential outbreaks)
   - Compare divergence between lineages

### Step 15: Additional Analyses (Optional)

```bash
# 1. Root the tree with an outgroup
#    Use a related alphavirus (e.g., O'nyong-nyong virus)

# 2. Calculate genetic distances
#    Using MEGA or R packages (ape, phangorn)

# 3. Test for recombination
#    Use RDP4, GARD, or PHI test

# 4. Selection pressure analysis
#    Use PAML, HyPhy, or datamonkey web server

# 5. Population dynamics
#    Bayesian skyline plot in BEAST2
```

---

## Software and Tools

### Installation Guide

#### Conda Installation (Recommended)
```bash
# Create conda environment
conda create -n chikv_phylo python=3.8
conda activate chikv_phylo

# Install bioinformatics tools
conda install -c bioconda fastqc trimmomatic spades bwa samtools bcftools
conda install -c bioconda mafft muscle trimal
conda install -c bioconda iqtree raxml-ng
conda install -c bioconda blast quast seqtk
```

#### Manual Installation
- **FastQC**: https://www.bioinformatics.babraham.ac.uk/projects/fastqc/
- **Trimmomatic**: http://www.usadellab.org/cms/?page=trimmomatic
- **SPAdes**: https://github.com/ablab/spades
- **BWA**: https://github.com/lh3/bwa
- **MAFFT**: https://mafft.cbrc.jp/alignment/software/
- **IQ-TREE**: http://www.iqtree.org/
- **FigTree**: http://tree.bio.ed.ac.uk/software/figtree/
- **BEAST2**: https://www.beast2.org/

---

## Expected Timeline

- Data acquisition and QC: 1-2 days
- Genome assembly: 0.5-1 day
- Multiple sequence alignment: 1-2 hours
- Phylogenetic analysis: 2-24 hours (depends on dataset size and method)
- Visualization and interpretation: 1-2 days

**Total**: Approximately 5-7 days for complete analysis

---

## Best Practices and Tips

1. **Always use quality-controlled data** - Poor quality reads lead to incorrect assemblies
2. **Include appropriate reference sequences** - Representative samples from all known lineages
3. **Document your workflow** - Keep track of software versions and parameters
4. **Validate results** - Cross-check with multiple methods when possible
5. **Consider biological context** - Phylogenies should make epidemiological sense
6. **Check for contamination** - BLAST assembled sequences against nt database
7. **Use adequate bootstrap replicates** - Minimum 1000 for publication
8. **Report branch support values** - Essential for interpreting tree reliability

---

## Common Issues and Troubleshooting

### Low Coverage Assembly
- Increase sequencing depth
- Adjust assembly parameters
- Try reference-guided assembly

### Poor Alignment Quality
- Check for sequence contamination
- Ensure sequences are from same gene/region
- Remove partial or low-quality sequences

### Low Bootstrap Support
- Insufficient phylogenetic signal
- Try different models or methods
- Increase sequence length
- Add more informative sequences

### Long Computation Time
- Reduce number of sequences
- Use faster methods (e.g., FastTree for initial analysis)
- Increase computational resources
- Use parallel processing options

---

## References and Resources

### Key Papers
1. Staples JE, et al. (2009). "Chikungunya fever: an epidemiological review of a re-emerging infectious disease." *Clinical Infectious Diseases*, 49(6), 942-948.
2. Volk SM, et al. (2010). "Genome-scale phylogenetic analyses of chikungunya virus reveal independent emergences of recent epidemics and various evolutionary rates." *Journal of Virology*, 84(13), 6497-6504.
3. Minh BQ, et al. (2020). "IQ-TREE 2: New models and efficient methods for phylogenetic inference in the genomic era." *Molecular Biology and Evolution*, 37(5), 1530-1534.

### Online Resources
- **NCBI Virus**: https://www.ncbi.nlm.nih.gov/labs/virus/
- **ViPR (Virus Pathogen Resource)**: https://www.viprbrc.org/
- **Nextstrain CHIKV**: https://nextstrain.org/chikungunya
- **IQ-TREE Tutorial**: http://www.iqtree.org/doc/
- **BEAST2 Tutorials**: https://www.beast2.org/tutorials/

### Databases
- **GenBank**: NCBI's genetic sequence database
- **GISAID**: Global database for influenza and coronavirus (expanding to other viruses)
- **ViralZone**: Viral genome and protein database

---

## Citation

If you use this pipeline, please cite the relevant software tools and databases used in your analysis. Each tool has its own citation requirements.

---

## Contact and Support

For questions or issues with this pipeline, please refer to the documentation of individual tools or contact bioinformatics support forums such as:
- **Biostars**: https://www.biostars.org/
- **SEQanswers**: http://seqanswers.com/
- **BioInfoToolkit**: https://bioinformaticsworkbook.org/

---

*Last Updated: 2024*
*Pipeline Version: 1.0*
