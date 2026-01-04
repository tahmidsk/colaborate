# 16S Microbiome Analysis: Methodology Explained

## Overview

This document explains the reasoning behind each step of the 16S rRNA microbiome analysis pipeline, written in accessible language.

---

## Section 3.1: Quality Assessment and Initial Processing

### 3.1.1: Why FastQC?

**What it does**: Examines raw sequencing data quality before processing.

**Why it matters**: 
- Poor quality sequences can lead to incorrect conclusions
- Identifies technical problems (adapter contamination, quality drops)
- Informs decisions about trimming and filtering parameters

**What we check**:
- Per-base quality scores (should be high, typically >30)
- Sequence length distribution (should be consistent)
- GC content (should match expected bacterial range ~50-55%)
- Adapter sequences (should be minimal or absent)

### 3.1.2: QIIME2 and DADA2 Processing

**What it does**: Converts raw sequences into clean biological variants (ASVs).

**Why this approach**:
- **Trimming first 15 bp**: Sequencing quality typically drops at read starts; primers may still be present
- **Truncating at 240 bp**: Balances quality (higher at read start) with length (needed for taxonomic classification)
- **DADA2 algorithm**: Superior to older OTU methods because:
  - Resolves sequences to single-nucleotide resolution
  - Better distinguishes biological variation from sequencing errors
  - Produces reproducible results (not dependent on arbitrary clustering thresholds)

**Process steps**:
1. **Quality filtering**: Removes low-quality sequences
2. **Denoising**: Corrects sequencing errors using error profiles learned from the data
3. **Dereplication**: Combines identical sequences to reduce computational burden
4. **Chimera removal**: Eliminates artificial sequences formed when fragments from different organisms join
5. **ASV generation**: Produces unique biological sequence variants

**Why taxonomic classification with SILVA**:
- SILVA is the gold-standard database for bacterial 16S sequences
- Version 138 is the most recent comprehensive release
- 99% identity clustering balances specificity and computational efficiency

**Why phylogenetic trees**:
- Some diversity metrics (Faith's PD) require evolutionary relationships
- Helps understand community assembly processes
- Reveals whether similar taxa are clustering together

---

## Section 3.2: Data Cleaning and Preprocessing

### 3.2.1: Initial Assessment

**What it does**: Examines the imported phyloseq object characteristics.

**Why it matters**:
- **Library sizes** (read counts per sample) reveal sequencing depth variation
  - Large variation may require normalization or rarefaction
  - Very low samples may need exclusion
- **Taxonomic profiling** identifies potential issues
  - High unclassified sequences suggest database mismatches
  - Unexpected kingdoms indicate contamination
- **Contaminant screening** at Family level catches common issues before detailed analysis

### 3.2.2: Keep Only Bacteria

**What it does**: Filters to Kingdom "d__Bacteria" only.

**Why it matters**:
- The research question focuses on bacterial communities
- Archaeal and eukaryotic sequences would confound bacterial analyses
- Different kingdoms require different analysis approaches
- Unclassified sequences at Kingdom level are likely artifacts

### 3.2.3: Remove Mitochondria and Chloroplasts

**What it does**: Eliminates organellar DNA sequences.

**Why it matters**:
- **Mitochondria and chloroplasts** originated from bacteria (endosymbiotic theory)
- Their 16S genes amplify with bacterial primers
- They represent host (fish) or dietary (plant) contamination, not the microbiome
- Can dominate samples and mask true bacterial community
- Keeping unclassified at Family level preserves true bacteria that lack detailed classification

**When this is especially important**:
- Gut samples (dietary plant material)
- Tissue-associated samples (host cell contamination)
- Any sample with eukaryotic host material

### 3.2.4: Prevalence Filtering

**What it does**: Removes ASVs found in fewer than 2 samples.

**Why it matters**:
- **Sequencing errors** typically appear in single samples
- **Cross-contamination** ("tag jumping") creates rare, spurious detections
- True community members appear consistently across replicate samples
- Conservative threshold (2 samples) balances removing artifacts while retaining real rare taxa

**What we're NOT removing**:
- Low abundance taxa that appear consistently (these may be important!)
- We're only removing taxa that appear sporadically

---

## Section 3.3: Relative Abundance Transformation

**What it does**: Converts counts to percentages within each sample.

**Why it matters**:
- **Sequencing depth varies** between samples (technical variation)
  - Sample A: 50,000 reads
  - Sample B: 25,000 reads
  - Same taxa appear to differ 2-fold due to technical artifact
- **Relative abundances** make samples comparable
  - Both samples sum to 100%
  - Reveals true compositional differences

**Formula**: (ASV count ÷ total sample reads) × 100

**Important note**: This is for visualization and some analyses. Count-based methods (like DESeq2) use raw counts because they model count variation explicitly.

---

## Section 3.4: Taxonomic Composition Analysis

### Why Multiple Taxonomic Levels?

Different levels reveal different information:
- **Phylum**: Broad differences in community architecture
- **Family**: Functional groups (many families share metabolic strategies)
- **Genus**: Specific taxa with known biological roles

### 3.4.2: Phylum-Level Analysis

**Why examine all phyla**:
- Phylum is a high level with relatively few groups (~30 bacterial phyla)
- Shows fundamental community structure differences
- Classic patterns (e.g., Firmicutes/Bacteroidetes ratio in gut)

### 3.4.3: Family-Level Analysis

**Why only top 15**:
- Families are numerous (hundreds possible)
- Top families represent most of the community
- Visualization becomes unreadable with too many categories
- Rare families cluster as "Other" in interpretation

### 3.4.4: Genus-Level Analysis

**Why two approaches**:
1. **Top 15 for composition**: Visualize major community members
2. **Top 25 for statistics**: More comprehensive testing while maintaining statistical power

**Statistical choices explained**:

**Wilcoxon rank-sum test (Mann-Whitney U)**:
- **Why non-parametric**: Microbiome data violates normal distribution assumptions
  - Many zeros (taxa absent from samples)
  - Skewed (few abundant, many rare)
  - Can't transform to normality reliably
- **What it tests**: Whether one group tends to have higher values
- **No assumptions** about data distribution

**Cliff's Delta effect size**:
- **Why not just p-values**: Statistical significance ≠ biological importance
  - Large sample sizes make small differences "significant"
  - Small sample sizes make large differences "non-significant"
- **What it measures**: Probability that random Gut sample > random Derm sample
- **Intuitive interpretation**: 
  - δ = 0.5 means 75% chance Gut > Derm (strong effect)
  - δ = 0 means 50% chance (no effect)

**Benjamini-Hochberg correction**:
- **The multiple testing problem**: Testing 25 genera means ~1 will be "significant" by chance
- **FDR control**: Controls proportion of false discoveries among significant results
- **Less conservative** than Bonferroni, more appropriate for exploratory microbiome work

---

## Section 3.5: Alpha Diversity Analysis

**What it measures**: How diverse is each individual sample?

### Why 6 Different Indices?

Each captures different aspects:

1. **Observed ASVs**: Simple richness count
   - Pro: Easy to interpret
   - Con: Underestimates true richness (some taxa undetected)

2. **Chao1**: Estimates true richness including unobserved taxa
   - Uses information about rare taxa to estimate missing ones
   - More accurate richness estimate

3. **Shannon Index**: Richness + evenness
   - High when many taxa present at similar abundances
   - Weighs rare and common taxa
   - Range: 0 (no diversity) to ~5+ (high diversity for microbiomes)

4. **Simpson Index**: Probability two random sequences are same species
   - Emphasizes dominant taxa
   - Range: 0 (infinite diversity) to 1 (no diversity)

5. **Inverse Simpson**: Reciprocal of Simpson
   - More intuitive (higher = more diverse)
   - Effective number of dominant species

6. **Faith's Phylogenetic Diversity (PD)**: Incorporates evolutionary relationships
   - Two distant taxa increase PD more than two close relatives
   - Captures evolutionary diversity, not just species count

**Why use multiple indices**: Different indices can reveal different patterns; comprehensive assessment is most robust.

---

## Section 3.6: Beta Diversity Analysis

**What it measures**: How different are samples from each other?

### Bray-Curtis Dissimilarity

**Why this metric**:
- Handles microbiome data well (compositional, many zeros)
- Ranges 0 (identical communities) to 1 (completely different)
- Accounts for abundance (not just presence/absence)
- Widely used and well-understood in ecology

**Alternative metrics not used here**:
- Jaccard: Presence/absence only (loses abundance information)
- UniFrac: Requires phylogenetic tree (used in some microbiome studies)
- Euclidean: Poor for compositional data

### Principal Coordinates Analysis (PCoA)

**What it does**: Reduces complex dissimilarity matrix to 2D plot.

**How to interpret**:
- Points close together = similar communities
- Points far apart = different communities
- Axes show directions of maximum variation
- % variance explained indicates how much information retained

**Why PCoA not PCA**:
- PCA: Works on raw data (assumes linear relationships)
- PCoA: Works on distance matrix (no assumptions about data structure)

### PERMANOVA (Permutational ANOVA)

**What it tests**: Are group centroids significantly different?

**How it works**:
1. Calculate distance between group centroids
2. Randomly shuffle group labels 999 times
3. Recalculate distances for each shuffle
4. P-value = proportion of shuffles with larger difference than observed

**Why permutation**:
- No assumptions about data distribution
- Robust to violations of ANOVA assumptions
- Appropriate for distance matrices

**What R² tells you**:
- Proportion of variance explained by group
- R² = 0.3 means 30% of community variation due to Gut vs. Derm
- Remaining 70% due to other factors (individual variation, technical factors, etc.)

**Important**: PERMANOVA tests if groups differ, not if they're homogeneous. Check ordination plot to ensure groups don't just differ in dispersion.

---

## Section 3.7: Differential Abundance Analysis

### Why DESeq2 for Microbiome Data?

**DESeq2 was designed for RNA-seq but works for microbiomes because both share**:
- Count data (not continuous measurements)
- Compositional nature (relative, not absolute abundances)
- Overdispersion (variance > mean)
- Many zeros

### How DESeq2 Works

**Negative binomial model**:
- Models count data more realistically than normal distribution
- Accounts for overdispersion (technical + biological variation)
- Handles zeros naturally

**Empirical Bayes shrinkage**:
- Borrows information across taxa to estimate variance
- Stabilizes estimates for rare taxa
- Improves statistical power

**Size factor normalization**:
- Accounts for varying sequencing depth
- Geometric mean approach handles zeros in microbiome data
- More sophisticated than simple relative abundance

### Preprocessing Choices

**Why agglomerate at genus level**:
- ASV-level is too fine (too many, too rare)
- Genus is meaningful biologically
- Reduces multiple testing burden

**Why filter low-abundance taxa (<10 total reads)**:
- Too few reads make reliable estimation impossible
- Likely to be noise or contamination
- Statistical power is wasted testing them

### Interpreting Results

**Log2 Fold Change**:
- Gut vs. Derm (Derm is reference)
- Positive log2FC: higher in Gut
- Negative log2FC: higher in Derm
- log2FC = 1 means 2-fold difference
- log2FC = 2 means 4-fold difference

**Why |log2FC| ≥ 1 threshold**:
- Statistical significance ≠ biological importance
- 2-fold change is generally considered biologically meaningful
- Smaller changes may be real but less interesting

**Adjusted p-value (padj)**:
- FDR-corrected significance
- padj < 0.05 is standard threshold
- Controls false discovery rate at 5%

### Volcano Plot

**What it shows**:
- X-axis: Effect size (log2 fold change)
- Y-axis: Significance (-log10 adjusted p-value)
- Points in upper corners: significant with large effect
- Points near center: not significant or small effect

---

## Common Questions

### Q: Why not just use a t-test?

Microbiome data violates t-test assumptions:
- Not normally distributed (many zeros, skewed)
- Compositional (if one taxon increases, others must decrease)
- Overdispersed (variance >> mean)

Non-parametric tests and specialized models handle these issues.

### Q: Why both Wilcoxon tests and DESeq2?

They serve different purposes:
- **Wilcoxon**: Simple, works on relative abundances, easy to interpret
- **DESeq2**: More sophisticated, works on counts, better handles compositional effects

Using both provides comprehensive assessment and validates findings.

### Q: How do I decide if results are "biologically meaningful"?

Consider:
1. **Statistical significance** (p < 0.05): Is it likely real?
2. **Effect size** (Cliff's Delta, log2FC): How large is the difference?
3. **Biological plausibility**: Does it make sense given the biology?
4. **Abundance**: Is the taxon abundant enough to matter functionally?
5. **Consistency**: Do multiple related taxa show similar patterns?

### Q: What if no taxa are significantly different?

Possible explanations:
1. Groups truly don't differ at tested taxonomic level
2. Differences exist but sample size too small to detect
3. High inter-individual variation masks group differences
4. Differences exist at other taxonomic levels or metabolic pathways

Consider:
- Testing other taxonomic ranks
- Functional profiling (PICRUSt2, HUMAnN)
- Increasing sample size
- Examining covarying taxa patterns

---

## Best Practices Summary

1. **Always start with quality control**: Bad data → bad conclusions
2. **Filter conservatively**: Remove obvious artifacts, keep potentially real taxa
3. **Use multiple approaches**: No single method is perfect
4. **Consider effect sizes**: Significance alone isn't enough
5. **Visualize extensively**: Plots reveal patterns statistics miss
6. **Think biologically**: Do results make sense given the system?
7. **Report transparently**: Document all parameters and thresholds
8. **Validate key findings**: Follow up significant results with targeted experiments

---

## References

This methodology follows current best practices from:
- QIIME2 documentation and tutorials
- phyloseq documentation
- Microbiome data analysis literature
- Statistical ecology textbooks

For specific citations, see the methods section of your manuscript.
