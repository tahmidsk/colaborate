# Analysis Methods Summary

## Overview

This document provides a detailed summary of the bioinformatics methods implemented in the Pseudomonas aeruginosa genomic analysis pipeline, corresponding to section 3.13.4 of the research methodology.

---

## 3.13.4.1 Quality Control, Genome Assembly and Annotation

### Raw Sequence Quality Screening (FastQC v0.12.1)

**Purpose:** Preliminary assessment of sequencing data quality

**Method:**
- Evaluates per-base sequence quality scores
- Identifies adapter contamination
- Detects overrepresented sequences
- Assesses GC content distribution
- Identifies sequence duplication levels

**Implementation:**
```bash
fastqc -t 16 -o qc_output/ raw_reads/*.fastq.gz
```

**Reference:** Andrews, S. (2010). FastQC: A quality control tool for high throughput sequence data.

---

### Quality Filtering and Trimming (FastP v0.23.2)

**Purpose:** Remove low-quality bases and adapter sequences

**Method:**
- Automatic adapter detection and removal
- Quality filtering (default Q20)
- Length filtering (default >15 bp)
- Poly-G tail trimming for NextSeq/NovaSeq
- Default mode parameters used as specified

**Implementation:**
```bash
fastp -i R1.fastq.gz -I R2.fastq.gz \
      -o R1_trimmed.fastq.gz -O R2_trimmed.fastq.gz \
      --thread 16
```

**Reference:** Chen, S., et al. (2018). fastp: an ultra-fast all-in-one FASTQ preprocessor. *Bioinformatics*, 34(17), i884-i890.

---

### De Novo Genome Assembly (SPAdes v3.14.1)

**Purpose:** Reconstruct genome sequences from short reads

**Method:**
- De Bruijn graph-based assembly
- Multiple k-mer sizes: 21, 33, 55, 77, 99, 127
- Error correction module enabled
- Careful mode for improved accuracy
- Automatic coverage cutoff determination

**Implementation:**
```bash
spades.py -1 R1_trimmed.fastq.gz -2 R2_trimmed.fastq.gz \
          -o assembly_output/ \
          --threads 16 \
          --careful \
          --cov-cutoff auto
```

**Reference:** Prjibelski, A., et al. (2020). Using SPAdes De Novo Assembler. *Current Protocols in Bioinformatics*, 70(1), e102.

---

### Assembly Quality Assessment (Quast v5.2.0)

**Purpose:** Evaluate assembly quality metrics

**Metrics Evaluated:**
- N50 and L50 values
- Total assembly length
- Number of contigs
- Largest contig size
- GC content
- N's per 100 kbp
- Misassemblies (when reference available)

**Implementation:**
```bash
quast.py contigs.fasta \
         -o quast_results/ \
         --threads 16 \
         --min-contig 500
```

**Reference:** Gurevich, A., et al. (2013). QUAST: quality assessment tool for genome assemblies. *Bioinformatics*, 29(8), 1072-1075.

---

### Genome Annotation (Prokka v1.13.4)

**Purpose:** Predict and annotate genomic features

**Features Annotated:**
- Protein-coding genes (CDS)
- rRNA genes (16S, 23S, 5S)
- tRNA genes
- tmRNA genes
- Signal peptides
- CRISPR arrays

**Databases Used:**
- RefSeq protein database
- Genus-specific (Pseudomonas) database
- Species-specific (P. aeruginosa) annotations

**Implementation:**
```bash
prokka --outdir annotation/ \
       --prefix sample \
       --kingdom Bacteria \
       --genus Pseudomonas \
       --species aeruginosa \
       --cpus 16 \
       contigs.fasta
```

**Outputs:**
- GFF3 format (for Roary)
- GenBank format
- Protein sequences (FASTA)
- Gene sequences (FASTA)

**Reference:** Seemann, T. (2014). Prokka: rapid prokaryotic genome annotation. *Bioinformatics*, 30(14), 2068-2069.

---

### Taxonomic Classification (Kraken v1.1.1)

**Purpose:** Confirm species identity and detect contamination

**Method:**
- k-mer based taxonomic classification
- Exact k-mer matching against database
- Confidence scoring for taxonomic assignments
- Database: Standard Kraken database (bacteria, archaea, viruses)

**Implementation:**
```bash
kraken --db $KRAKEN_DB \
       --threads 16 \
       --paired \
       --fastq-input \
       --gzip-compressed \
       R1_trimmed.fastq.gz R2_trimmed.fastq.gz \
       > kraken_output.txt

kraken-report --db $KRAKEN_DB \
              kraken_output.txt \
              > kraken_report.txt
```

**Reference:** Wood, D. E., & Salzberg, S. L. (2014). Kraken: ultrafast metagenomic sequence classification using exact alignments. *Genome Biology*, 15(3), R46.

---

## 3.13.4.2 MLST, Capsular and Antigen Typing

### Multi-Locus Sequence Typing (MLST)

**Purpose:** Determine sequence type for epidemiological tracking

**Method:**
- Analysis of 7 housekeeping genes:
  1. acsA - acetyl-CoA synthetase
  2. aroE - shikimate dehydrogenase
  3. guaA - GMP synthase
  4. mutL - DNA mismatch repair protein
  5. nuoD - NADH dehydrogenase subunit
  6. ppsA - phosphoenolpyruvate synthase
  7. trpE - anthranilate synthase

**Database:** PubMLST (https://pubmlst.org/paeruginosa/)

**Implementation:**
```bash
mlst --scheme paer contigs.fasta > mlst_results.tsv
```

**Allele Calling:**
- Exact sequence matches to known alleles
- Novel alleles assigned new numbers
- Combination of alleles defines sequence type (ST)

**Reference:** Jolley, K. A., & Maiden, M. C. (2010). BIGSdb: Scalable analysis of bacterial genome variation at the population level. *BMC Bioinformatics*, 11(1), 595.

---

### Serotyping (PAst v1.0)

**Purpose:** Identify O antigen serotype

**Method:**
- BLAST-based search for O antigen-specific genes
- 20 known P. aeruginosa O serotypes (O1-O20)
- Identification based on wzz, wzy, and specific glycosyltransferase genes

**Implementation:**
```bash
past -i contigs.fasta -o serotype_output.txt
```

**Reference:** Zhao, Y., Xie, Z., et al. (2023). PAst: A Pseudomonas aeruginosa Serotyper. *Microbiology Spectrum*, 11(2).

---

## 3.13.4.3 SNP and Indel Detection

### Variant Calling (Snippy v4.3.6)

**Purpose:** Identify single nucleotide polymorphisms and insertion/deletions

**Method:**
- Read alignment to reference genome (BWA-MEM)
- Variant calling with FreeBayes
- Filtering of low-quality variants
- Consensus sequence generation

**Workflow:**
1. Map reads to reference genome
2. Call variants (SNPs and indels)
3. Apply quality filters
4. Annotate variant effects

**Implementation:**
```bash
# Individual sample
snippy --outdir sample_snps/ \
       --ref reference.fasta \
       --R1 R1.fastq.gz \
       --R2 R2.fastq.gz \
       --cpus 16

# Core SNP alignment (multiple samples)
snippy-core --ref reference.fasta \
            --prefix core \
            sample1_snps/ sample2_snps/ sample3_snps/
```

**Outputs:**
- VCF file (variant call format)
- SNP table (tab-delimited)
- Consensus sequences
- Core SNP alignment (for phylogenetics)

**Reference:** Seemann, T. (2015). Snippy: fast bacterial variant calling from NGS reads. https://github.com/tseemann/snippy

---

## 3.13.4.4 ARGs Identification

### Antibiotic Resistance Gene Detection

**Purpose:** Identify acquired antibiotic resistance genes

**Databases and Tools:**

#### 1. ResFinder Database

**Method:**
- BLAST-based screening
- Identity threshold: ≥90%
- Coverage threshold: ≥60%
- Detects acquired resistance genes

**Implementation:**
```bash
abricate --db resfinder \
         --minid 90 \
         --mincov 60 \
         contigs.fasta > resfinder_results.tsv
```

**Reference:** Florensa, A. F., et al. (2022). ResFinder–an open online resource for identification of antimicrobial resistance genes in next-generation sequencing data. *Journal of Antimicrobial Chemotherapy*, 77(11), 3091-3094.

---

#### 2. CARD (Comprehensive Antibiotic Resistance Database)

**Method:**
- BLAST-based screening
- Includes resistance genes and mutations
- Resistance mechanisms categorized by:
  - Antibiotic target alteration
  - Antibiotic inactivation
  - Antibiotic efflux
  - Reduced permeability

**Implementation:**
```bash
abricate --db card \
         --minid 90 \
         --mincov 60 \
         contigs.fasta > card_results.tsv
```

**Alternative (RGI - CARD native tool):**
```bash
rgi main --input_sequence contigs.fasta \
         --output_file rgi_output \
         --input_type contig \
         --alignment_tool BLAST \
         --num_threads 16
```

**Reference:** Alcock, B. P., et al. (2023). CARD 2023: expanded curation, support for machine learning, and resistome prediction at the Comprehensive Antibiotic Resistance Database. *Nucleic Acids Research*, 51(D1), D690-D699.

---

### Antibiotic Classes Covered

- β-lactams (including carbapenems)
- Aminoglycosides
- Fluoroquinolones
- Tetracyclines
- Macrolides
- Sulfonamides
- Trimethoprim
- Chloramphenicol
- Polymyxins
- Rifampicin

---

## 3.13.4.5 Virulence Factor and Pathogenicity

### Virulence Factor Identification (ABRicate v0.8.13, VFDB)

**Purpose:** Identify genes contributing to bacterial pathogenicity

**Database:** VFDB (Virulence Factor Database)

**Method:**
- BLAST-based screening
- Identity threshold: ≥80%
- Coverage threshold: ≥60%

**Implementation:**
```bash
abricate --db vfdb \
         --minid 80 \
         --mincov 60 \
         contigs.fasta > vfdb_results.tsv
```

**Virulence Factor Categories:**

1. **Secretion Systems**
   - Type I, II, III, VI secretion systems
   - Effector proteins

2. **Toxins**
   - Exotoxin A (toxA)
   - Exoenzymes S, T, U, Y

3. **Adhesins**
   - Pili (Type IV)
   - Flagella
   - Alginate

4. **Iron Acquisition**
   - Pyoverdine
   - Pyochelin

5. **Quorum Sensing**
   - Las, Rhl, PQS systems

6. **Biofilm Formation**
   - Pel and Psl operons

**Pathogenicity Assessment:**
- High: >20 virulence factors
- Moderate: 10-20 virulence factors
- Low: <10 virulence factors

**References:**
- Chen, L., et al. (2016). VFDB 2016: hierarchical and refined dataset for big data analysis—10 years on. *Nucleic Acids Research*, 44(D1), D694-D697.
- Seemann, T. (2020). ABRicate: mass screening of contigs for antimicrobial resistance or virulence genes. https://github.com/tseemann/abricate

---

## 3.13.4.6 Comparative Genomic Analysis

### Pan-genome Analysis (Roary v3.13.0)

**Purpose:** Identify core and accessory genomes across multiple isolates

**Method:**
- Input: GFF3 files from Prokka
- BLASTp comparison of all genes
- Identity threshold: 95%
- Core genome definition: genes present in ≥99% of strains
- Accessory genome: remaining genes

**Implementation:**
```bash
roary -e \                    # Create multiFASTA alignment
      -n \                    # Fast core gene alignment
      -v \                    # Verbose
      -p 16 \                 # Threads
      -i 95 \                 # Identity threshold
      -cd 99 \                # Core definition
      -f pangenome_output/ \  # Output directory
      *.gff                   # Prokka GFF files
```

**Outputs:**
- `gene_presence_absence.csv` - Binary matrix of gene distribution
- `summary_statistics.txt` - Pan-genome statistics
- `core_gene_alignment.aln` - Alignment of core genes
- `accessory_binary_genes.fa` - Accessory gene sequences

**Analysis:**
- Core genome size
- Accessory genome size
- Unique genes per isolate
- Pan-genome size
- Gene frequency distribution

**Reference:** Page, A. J., et al. (2015). Roary: rapid large-scale prokaryote pan genome analysis. *Bioinformatics*, 31(22), 3691-3693.

---

### Core Genome Phylogenetics (Parsnp v1.7.4)

**Purpose:** Construct phylogenetic tree based on core genome SNPs

**Method:**
- Alignment of core genome regions
- Maximum likelihood tree construction
- Exclusion of recombinant regions
- FastTree for tree building

**Implementation:**
```bash
parsnp -d genome_directory/ \
       -o output_directory/ \
       -p 16 \                  # Threads
       -c \                      # Force inclusion of all sequences
       -v                        # Verbose
```

**Features:**
- Automatic detection of core genome
- Identification of recombinant regions (excluded from tree)
- Output in Newick format
- Compatible with iTOL for visualization

**Reference:** Rhoads, D. D., et al. (2024). Parsnp 2.0: Scalable Core-Genome Alignment for Massive Microbial Datasets. *bioRxiv*.

---

### Phylogenetic Visualization (iTOL)

**Purpose:** Interactive visualization and annotation of phylogenetic trees

**Method:**
1. Upload Newick tree to iTOL (https://itol.embl.de/)
2. Add metadata annotations:
   - MLST sequence types
   - Geographic locations
   - Serotypes
   - Resistance profiles
   - Virulence profiles
3. Customize display:
   - Color branches by metadata
   - Add heatmaps for gene presence/absence
   - Display bootstrap values
   - Add timeline scales

**Annotation Datasets:**
- Color strips for categorical data
- Heatmaps for numerical data
- Binary data for presence/absence
- Connection lines for transmission links

**Reference:** Letunic, I., & Bork, P. (2021). Interactive Tree Of Life (iTOL) v5: an online tool for phylogenetic tree display and annotation. *Nucleic Acids Research*, 49(W1), W293-W296.

---

### Comparison with PathogenWatch

**Database:** PathogenWatch (https://pathogen.watch/)

**Method:**
1. Upload assemblies to PathogenWatch
2. Retrieve metadata and assemblies:
   - 72 P. aeruginosa sequences from Bangladesh
   - Reference sequences for ST645, ST773, ST2238
3. Download GFF files and assemblies
4. Re-run comparative analysis with combined dataset
5. Identify population structure and transmission patterns

**Analysis:**
- Temporal trends
- Geographic distribution
- Clone distribution
- Resistance patterns
- Transmission networks

---

## Quality Assurance

### Assembly Quality Thresholds

**Good Quality Assembly:**
- N50 > 100 kb
- Total length: 5.5-7.0 Mb
- Number of contigs < 500
- GC content: 65-67%
- Completeness: >95% (if checked with CheckM)

### Taxonomic Confirmation

- Kraken classification: >90% reads assigned to P. aeruginosa
- Contamination: <2% reads from other species

### Gene Calling Quality

- Coding density: 85-90%
- Average gene length: ~900-1000 bp
- rRNA genes: 3-6 copies
- tRNA genes: 50-80 copies

---

## Data Analysis Workflow Summary

```
Raw Reads (FASTQ)
    ↓
[FastQC] → Quality Assessment
    ↓
[FastP] → Quality Filtering
    ↓
[SPAdes] → De Novo Assembly
    ↓
[Quast] → Assembly QC
    ↓
[Prokka] → Annotation (GFF3)
    ↓
[Kraken] → Taxonomic Classification
    ↓
┌───────────┬──────────────┬──────────────┬──────────────┐
↓           ↓              ↓              ↓              ↓
[MLST]    [Snippy]    [ABRicate]   [ABRicate]      [Roary]
  ST       SNPs/Indels  ResFinder    VFDB         Pan-genome
typing                   CARD      Virulence         ↓
  ↓           ↓              ↓              ↓        [Parsnp]
[PAst]    [Core SNPs]  Resistance  Pathogenicity  Phylogeny
Serotype    Tree        Profile      Profile         ↓
    ↓           ↓              ↓              ↓        [iTOL]
    └───────────┴──────────────┴──────────────┴─────────┘
                            ↓
                    Integrated Analysis
                            ↓
                      Final Report
```

---

## Computational Requirements

### Per Sample (Typical P. aeruginosa genome)

- **Storage:** ~10-20 GB
- **RAM:** 32-64 GB
- **CPU Time:** 4-8 hours (16 cores)

### For Complete Pipeline (4 samples)

- **Storage:** 100-200 GB
- **RAM:** 64 GB
- **CPU Time:** 16-24 hours (16 cores)

---

## Summary

This pipeline implements a comprehensive workflow for P. aeruginosa genomic analysis, following best practices in bacterial genomics. All tools and databases are regularly updated and widely used in the scientific community. The workflow enables:

1. High-quality genome assemblies
2. Accurate molecular typing
3. Comprehensive resistance profiling
4. Detailed virulence characterization
5. Population structure analysis
6. Outbreak investigation capabilities

The modular design allows for flexible execution of individual analysis steps or the complete pipeline, making it suitable for various research and clinical applications.
