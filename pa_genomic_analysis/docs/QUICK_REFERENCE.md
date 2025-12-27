# Quick Reference Guide

## Command Quick Reference

### Check Dependencies

```bash
bash scripts/check_dependencies.sh
```

### Run Complete Pipeline

```bash
bash scripts/pa_analysis_pipeline.sh \
    -i raw_reads/ \
    -o results/ \
    -t 16 \
    -s all
```

### Run Individual Steps

```bash
# Quality control
bash scripts/pa_analysis_pipeline.sh -i raw_reads/ -o results/ -s qc

# MLST typing
bash scripts/pa_analysis_pipeline.sh -i results/assembly -o results/ -s mlst

# SNP detection (requires reference)
bash scripts/pa_analysis_pipeline.sh -i raw_reads/ -o results/ -r ref.fasta -s snp

# Resistance genes
bash scripts/pa_analysis_pipeline.sh -i results/assembly -o results/ -s args

# Virulence factors
bash scripts/pa_analysis_pipeline.sh -i results/assembly -o results/ -s vf

# Comparative genomics
bash scripts/pa_analysis_pipeline.sh -i results/annotation -o results/ -s comparative
```

## Tool-Specific Commands

### FastQC
```bash
fastqc -t 8 -o output_dir/ reads.fastq.gz
```

### FastP
```bash
fastp -i R1.fq.gz -I R2.fq.gz -o R1_trim.fq.gz -O R2_trim.fq.gz --thread 8
```

### SPAdes
```bash
spades.py -1 R1.fq.gz -2 R2.fq.gz -o output/ --threads 16 --careful
```

### Quast
```bash
quast.py contigs.fasta -o quast_results/ --threads 8
```

### Prokka
```bash
prokka --outdir output/ --prefix sample --cpus 16 contigs.fasta
```

### Kraken
```bash
kraken --db $KRAKEN_DB --threads 16 --paired R1.fq R2.fq > kraken.out
kraken-report --db $KRAKEN_DB kraken.out > report.txt
```

### MLST
```bash
mlst --scheme paer contigs.fasta
```

### Snippy
```bash
snippy --outdir output/ --ref reference.fa --R1 R1.fq --R2 R2.fq --cpus 16
snippy-core --ref reference.fa --prefix core sample1/ sample2/ sample3/
```

### ABRicate
```bash
# ResFinder
abricate --db resfinder contigs.fasta > resfinder_results.tsv

# CARD
abricate --db card contigs.fasta > card_results.tsv

# VFDB
abricate --db vfdb contigs.fasta > vfdb_results.tsv

# Summary
abricate --summary *_results.tsv > summary.tsv
```

### Roary
```bash
roary -e -n -v -p 16 -i 95 -cd 99 -f output/ *.gff
```

### Parsnp
```bash
parsnp -d genome_dir/ -o output/ -p 16 -c -v
```

## Common Workflows

### New Sample Analysis

```bash
# 1. Quality control
bash scripts/01_qc_assembly.sh -i raw_reads/ -o results/ -t 16

# 2. Check assembly quality
cat results/assembly/quast_results/report.txt

# 3. Run typing
bash scripts/02_mlst_typing.sh -i results/assembly -o results/ -t 16

# 4. Screen for resistance
bash scripts/04_args_identification.sh -i results/assembly -o results/ -t 16

# 5. Screen for virulence
bash scripts/05_virulence_factors.sh -i results/assembly -o results/ -t 16
```

### Outbreak Investigation

```bash
# 1. Run complete pipeline
bash scripts/pa_analysis_pipeline.sh -i outbreak_samples/ -o outbreak_analysis/ -t 32 -s all

# 2. Perform SNP analysis
bash scripts/03_snp_detection.sh -i outbreak_samples/ -o outbreak_analysis/ -r reference.fa -t 32

# 3. Build phylogenetic tree
# Tree is automatically generated in outbreak_analysis/snp_analysis/core.tree

# 4. Visualize in iTOL
firefox https://itol.embl.de/
# Upload: outbreak_analysis/comparative_genomics/phylogenetics/core_genome.tree
```

### Compare with Database Sequences

```bash
# 1. Download sequences from PathogenWatch
# Visit: https://pathogen.watch/
# Download assemblies and annotations

# 2. Combine with your sequences
cp pathogenwatch/*.gff results/annotation/

# 3. Run comparative analysis
bash scripts/06_comparative_genomics.sh -i results/annotation -o results/ -t 32

# 4. Analyze pan-genome
cat results/comparative_genomics/pangenome/pangenome_summary.txt
```

## File Locations

### Input Files
- Raw reads: `*_R1.fastq.gz`, `*_R2.fastq.gz`
- Reference genome: `*.fasta`

### Output Files
- Assemblies: `results/assembly/*_contigs.fasta`
- Annotations: `results/annotation/*/*.gff`
- MLST: `results/mlst/mlst_results.tsv`
- SNPs: `results/snp_analysis/*/snps.vcf`
- Resistance: `results/antibiotic_resistance/*/`
- Virulence: `results/virulence_factors/*/`
- Pan-genome: `results/comparative_genomics/pangenome/gene_presence_absence.csv`
- Tree: `results/comparative_genomics/phylogenetics/core_genome.tree`

## Troubleshooting Commands

### Check tool versions
```bash
fastqc --version
fastp --version
spades.py --version
prokka --version
```

### Check ABRicate databases
```bash
abricate --list
```

### Check MLST schemes
```bash
mlst --longlist | grep paer
```

### Test tools
```bash
# Test on small dataset
bash scripts/check_dependencies.sh
```

### View logs
```bash
tail -f results/pipeline.log
```

## Environment Management

### Conda
```bash
# Activate
conda activate pa_analysis

# Deactivate
conda deactivate

# Update
conda update --all

# List installed
conda list
```

### Database Updates
```bash
# Update ABRicate
abricate-get_db --db resfinder --force
abricate-get_db --db card --force
abricate-get_db --db vfdb --force

# Update MLST
mlst --longlist  # Auto-updates
```

## Performance Tips

### Optimize Threads
```bash
# Use 80% of available cores
THREADS=$(nproc)
OPTIMAL=$((THREADS * 80 / 100))
bash scripts/pa_analysis_pipeline.sh -i data/ -o results/ -t $OPTIMAL -s all
```

### Reduce Memory Usage
```bash
# For SPAdes on large genomes
# Edit scripts/01_qc_assembly.sh
# Add: --memory 100  # Limit to 100 GB
```

### Parallel Processing
```bash
# Process multiple samples in parallel
for sample in sample1 sample2 sample3; do
    bash scripts/pa_analysis_pipeline.sh -i ${sample}/ -o ${sample}_results/ -t 8 -s all &
done
wait
```

## Useful One-Liners

### Count resistance genes per sample
```bash
for f in results/antibiotic_resistance/resfinder/*_resfinder.tsv; do
    echo "$(basename $f): $(tail -n +2 $f | wc -l) genes"
done
```

### List all MLST types
```bash
cut -f3 results/mlst/mlst_results.tsv | tail -n +2 | sort -u
```

### Extract core genes
```bash
awk -F',' '$4>=99' results/comparative_genomics/pangenome/gene_presence_absence.csv | wc -l
```

### Find carbapenemase genes
```bash
grep -i "VIM\|IMP\|KPC\|NDM\|OXA" results/antibiotic_resistance/resfinder/*.tsv
```

### Count virulence factors
```bash
for f in results/virulence_factors/vfdb/*_vfdb.tsv; do
    echo "$(basename $f .tsv): $(tail -n +2 $f | wc -l) VFs"
done
```

## Export and Reporting

### Generate summary report
```bash
bash examples/example_analysis.sh  # Creates comprehensive report
```

### Export for publication
```bash
# Assembly statistics
cp results/assembly/quast_results/report.pdf manuscript/

# Phylogenetic tree
cp results/comparative_genomics/phylogenetics/core_genome.tree manuscript/

# Resistance matrix
cp results/antibiotic_resistance/resfinder/resfinder_summary.tsv manuscript/
```

### Create supplementary files
```bash
# Gene presence/absence
cp results/comparative_genomics/pangenome/gene_presence_absence.csv supplementary/

# SNP matrix
cp results/snp_analysis/core.tab supplementary/
```

## Help and Documentation

- Main README: `README.md`
- Installation: `docs/INSTALLATION.md`
- Workflow: `docs/WORKFLOW.md`
- Requirements: `docs/REQUIREMENTS.md`
- Example: `examples/example_analysis.sh`

For tool-specific help:
```bash
tool_name --help
```
