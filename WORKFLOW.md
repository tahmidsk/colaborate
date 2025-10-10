# BLAST Workflow Diagram

## Overview: How BLAST Analysis Works

```
┌─────────────────────────────────────────────────────────────────┐
│                    BLAST Command Line Workflow                   │
└─────────────────────────────────────────────────────────────────┘

Step 1: Input Sequences
┌──────────────────────────────────────┐
│  sequences/                          │
│  ├── chikungunya_1.fasta            │
│  ├── chikungunya_2.fasta            │
│  ├── chikungunya_3.fasta            │
│  ├── chikungunya_4.fasta            │
│  └── zika_1.fasta                   │
└──────────────────────────────────────┘
                ↓
                
Step 2: Create BLAST Database
┌──────────────────────────────────────┐
│  makeblastdb                         │
│  → Combines all sequences            │
│  → Creates searchable database       │
│  → Indexes for fast searching        │
└──────────────────────────────────────┘
                ↓
                
Step 3: BLAST Database Created
┌──────────────────────────────────────┐
│  blast_db/                           │
│  ├── viral_genomes.nhr              │
│  ├── viral_genomes.nin              │
│  └── viral_genomes.nsq              │
└──────────────────────────────────────┘
                ↓
                
Step 4: Run BLAST Queries
┌──────────────────────────────────────┐
│  blastn                              │
│  → Query vs Database                 │
│  → Finds similar regions             │
│  → Calculates statistics             │
└──────────────────────────────────────┘
                ↓
                
Step 5: Results Generated
┌──────────────────────────────────────┐
│  blast_results/                      │
│  ├── chikungunya_1_results.txt      │
│  ├── chikungunya_2_results.txt      │
│  ├── chikungunya_3_results.txt      │
│  ├── chikungunya_4_results.txt      │
│  ├── zika_1_results.txt             │
│  └── chikungunya_vs_zika.txt        │
└──────────────────────────────────────┘
                ↓
                
Step 6: Analyze Results
┌──────────────────────────────────────┐
│  • Check E-values (lower = better)   │
│  • Review % identity                 │
│  • Identify similar regions          │
│  • Compare alignments                │
└──────────────────────────────────────┘
```

## Two Ways to Run BLAST

### Option A: Automated Script (Recommended for Beginners)
```
./run_blast.sh
     ↓
[Automatic execution of all steps]
     ↓
Results in blast_results/
```

### Option B: Manual Commands (For Learning/Customization)
```
Step 1: makeblastdb -in sequences.fasta -dbtype nucl -out mydb
     ↓
Step 2: blastn -query input.fasta -db mydb -out results.txt
     ↓
Step 3: Analyze results.txt
```

## Understanding BLAST Output

### Tabular Output Format (-outfmt 6)
```
Query_ID | Subject_ID | %Identity | Length | Mismatches | Gaps | ...
---------|------------|-----------|--------|------------|------|----
chik_1   | chik_2     | 98.5      | 240    | 4          | 0    | ...
chik_1   | zika_1     | 75.2      | 150    | 37         | 2    | ...
```

### What Each Column Means
```
Query_ID    → Your input sequence
Subject_ID  → Matching sequence in database
%Identity   → How similar (higher = more similar)
E-value     → Statistical significance (lower = better)
Bit Score   → Quality of match (higher = better)
```

## BLAST Parameter Impact

### Sensitivity vs Speed
```
High Sensitivity (Slow)          Default              Fast (Less Sensitive)
├────────────────────────┼────────────────────────┼────────────────────────┤
word_size=7                   word_size=11              word_size=28
evalue=0.0001                 evalue=10                 task=megablast
task=blastn                   task=blastn               
                              
Use for:                      Use for:                  Use for:
• Distantly related           • General purpose         • Very similar sequences
• Finding weak matches        • Unknown similarity      • Same species
• Comprehensive search        • Exploratory             • Quality control
```

## Common Use Cases

### Use Case 1: Compare Two Specific Sequences
```
blastn -query A.fasta -subject B.fasta
                ↓
    Direct comparison results
```

### Use Case 2: Search One vs Many
```
blastn -query one.fasta -db many_database
                ↓
    Find all matches in database
```

### Use Case 3: Compare All vs All
```
Create database from all sequences
    → Query each sequence against database
    → Generate matrix of similarities
```

### Use Case 4: Find Conserved Regions
```
Align multiple sequences of same virus
    → Identify high-similarity regions
    → These are conserved/functional regions
```

## File Organization

```
Your Working Directory
├── Input Files
│   └── sequences/*.fasta         (Your genome sequences)
│
├── Scripts & Documentation
│   ├── run_blast.sh             (Run everything)
│   ├── blast_examples.sh        (Learn commands)
│   ├── README.md                (Full documentation)
│   ├── TUTORIAL.md              (Step-by-step guide)
│   └── BLAST_QUICK_REFERENCE.md (Command reference)
│
├── Generated Files (Created by scripts)
│   ├── blast_db/                (Database files)
│   │   ├── viral_genomes.nhr
│   │   ├── viral_genomes.nin
│   │   └── viral_genomes.nsq
│   │
│   └── blast_results/           (Your results)
│       ├── *_results.txt        (Individual results)
│       ├── *_results.xml        (XML format)
│       └── analysis_summary.txt (Summary)
│
└── .gitignore                   (Excludes generated files)
```

## Quick Decision Tree

```
                    Want to run BLAST?
                            |
        ┌───────────────────┴───────────────────┐
        ↓                                       ↓
    First time?                          Experienced?
        |                                       |
        ↓                                       ↓
    ./run_blast.sh                    Manual commands
    (Automated)                       (Custom analysis)
        |                                       |
        ↓                                       ↓
    Check blast_results/               Adjust parameters
        |                                       |
        ↓                                       ↓
    Read TUTORIAL.md                   Use specific options
    to understand                      for your needs
```

## Understanding E-values

```
E-value Scale (Lower = Better Match)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
0.0        1e-100    1e-10     1e-5    0.01      1       10
├─────────┼─────────┼─────────┼───────┼────────┼───────┼───→
│         │         │         │       │        │       │
Perfect   Excellent Very Good Good    Weak     Poor    Random
Match     Match     Match     Match   Match    Match   Noise

Recommended thresholds:
• Strict filtering: 1e-10
• General use: 1e-5
• Permissive: 0.01
```

## Tips for Success

1. **Start Simple**: Use `./run_blast.sh` first
2. **Check Results**: Look at E-values and % identity
3. **Experiment**: Try different parameters
4. **Compare**: Run reciprocal BLAST for validation
5. **Document**: Keep notes on what parameters work best

## Getting Help

| Need | Look Here |
|------|-----------|
| Quick start | `./run_blast.sh` |
| Step-by-step guide | `TUTORIAL.md` |
| Command reference | `BLAST_QUICK_REFERENCE.md` |
| Example commands | `./blast_examples.sh` |
| Full documentation | `README.md` |
| BLAST help | `blastn -help` |

## Next Steps After First Run

1. ✅ Run `./run_blast.sh` successfully
2. 📊 Open `blast_results/analysis_summary.txt`
3. 🔍 Review individual result files
4. 📈 Compare E-values and % identity
5. 🧪 Try different BLAST parameters
6. 📚 Read TUTORIAL.md for advanced usage
7. 🌐 Try with real genome data from NCBI

Good luck with your BLAST analysis! 🧬🔬
