# START HERE - BLAST Guide Navigation

Welcome! This repository contains everything you need to run BLAST on command line for Chikungunya and Zika virus genomes.

## 🚀 Quick Start (3 Steps)

1. **Install BLAST+**
   ```bash
   # Ubuntu/Debian
   sudo apt-get install ncbi-blast+
   
   # macOS
   brew install blast
   ```

2. **Run the Analysis**
   ```bash
   ./run_blast.sh
   ```

3. **Check Results**
   ```bash
   ls blast_results/
   ```

That's it! Results will be in the `blast_results/` directory.

---

## 📚 Documentation Guide

### Choose Your Path:

**Never used BLAST before?**
→ Start with [TUTORIAL.md](TUTORIAL.md) - Complete beginner guide

**Want to understand the workflow?**
→ Read [WORKFLOW.md](WORKFLOW.md) - Visual diagrams and decision trees

**Need specific commands?**
→ Check [BLAST_QUICK_REFERENCE.md](BLAST_QUICK_REFERENCE.md) - Quick command reference

**Want comprehensive documentation?**
→ See [README.md](README.md) - Full documentation with all details

**Want to see examples?**
→ Run `./blast_examples.sh` - Shows 15+ example commands

---

## 📂 What's in This Repository?

### 🧬 Sequence Files (in `sequences/`)
- `chikungunya_1.fasta` - Chikungunya virus strain 1
- `chikungunya_2.fasta` - Chikungunya virus strain 2
- `chikungunya_3.fasta` - Chikungunya virus strain 3
- `chikungunya_4.fasta` - Chikungunya virus strain 4
- `zika_1.fasta` - Zika virus strain 1

### 📜 Scripts
- `run_blast.sh` - **Main script** - Automated BLAST analysis
- `blast_examples.sh` - Shows example commands (educational)

### 📖 Documentation (Choose What You Need)

| File | Best For | Length |
|------|----------|--------|
| **START_HERE.md** | First-time users | This file! |
| **TUTORIAL.md** | Step-by-step learning | Beginner-friendly |
| **WORKFLOW.md** | Understanding the process | Visual guide |
| **BLAST_QUICK_REFERENCE.md** | Quick lookups | Concise reference |
| **README.md** | Complete information | Comprehensive |

---

## 🎯 Common Use Cases

### Use Case 1: "I just want to run BLAST quickly"
```bash
./run_blast.sh
```

### Use Case 2: "I want to learn how BLAST works"
Read in this order:
1. [TUTORIAL.md](TUTORIAL.md) - Learn the basics
2. [WORKFLOW.md](WORKFLOW.md) - Understand the workflow
3. Try manual commands from the tutorial

### Use Case 3: "I need a specific command"
1. Check [BLAST_QUICK_REFERENCE.md](BLAST_QUICK_REFERENCE.md)
2. Run `./blast_examples.sh` for examples
3. Run `blastn -help` for all options

### Use Case 4: "I want to compare two specific sequences"
```bash
blastn -query sequences/chikungunya_1.fasta \
       -subject sequences/zika_1.fasta
```

### Use Case 5: "I want to use my own genome sequences"
1. Download your sequences in FASTA format
2. Place them in the `sequences/` directory
3. Run `./run_blast.sh`

---

## 📋 Checklist for Success

- [ ] Install BLAST+ (`blastn -version` to verify)
- [ ] Clone/download this repository
- [ ] Run `./run_blast.sh`
- [ ] Check `blast_results/` directory
- [ ] Open `blast_results/analysis_summary.txt`
- [ ] Review individual result files
- [ ] Read [TUTORIAL.md](TUTORIAL.md) to understand results
- [ ] Experiment with different parameters

---

## 🔍 Understanding Your Results

After running BLAST, look for these key metrics in your results:

### E-value (Expect Value)
- **Lower is better**
- `< 1e-10` = Excellent match
- `< 1e-5` = Good match
- `> 0.01` = Weak match

### % Identity
- **Higher is better**
- `> 95%` = Very similar
- `70-95%` = Related
- `< 70%` = Distantly related

### Bit Score
- **Higher is better**
- Indicates quality of alignment

---

## ⚡ Quick Command Reference

```bash
# See all example commands
./blast_examples.sh

# Run complete analysis
./run_blast.sh

# Compare two sequences directly
blastn -query seq1.fasta -subject seq2.fasta

# Create a database
makeblastdb -in sequences.fasta -dbtype nucl -out mydb

# Search against database
blastn -query input.fasta -db mydb -outfmt 6

# Get help
blastn -help
```

---

## 🛠️ Troubleshooting

### "Command not found: blastn"
→ BLAST is not installed. See installation instructions above.

### "No such file or directory"
→ Make sure you're in the repository directory: `cd /path/to/colaborate`

### "Permission denied"
→ Make scripts executable: `chmod +x run_blast.sh blast_examples.sh`

### Empty results
→ Try adjusting parameters: `blastn -query input.fasta -db mydb -evalue 10`

### Need more help?
→ Read [TUTORIAL.md](TUTORIAL.md) troubleshooting section

---

## 📚 Learning Path

### Level 1: Beginner
1. ✅ Run `./run_blast.sh`
2. ✅ Read [TUTORIAL.md](TUTORIAL.md)
3. ✅ Check your results

### Level 2: Intermediate
1. ✅ Understand [WORKFLOW.md](WORKFLOW.md)
2. ✅ Try manual commands
3. ✅ Experiment with parameters

### Level 3: Advanced
1. ✅ Read [README.md](README.md) completely
2. ✅ Use custom parameters
3. ✅ Work with real NCBI data

---

## 🌐 External Resources

- [NCBI BLAST+](https://blast.ncbi.nlm.nih.gov/Blast.cgi)
- [BLAST Manual](https://www.ncbi.nlm.nih.gov/books/NBK279690/)
- [Download BLAST](https://blast.ncbi.nlm.nih.gov/Blast.cgi?PAGE_TYPE=BlastDocs&DOC_TYPE=Download)

---

## 💡 Tips

1. **Start simple**: Use the automated script first
2. **Understand results**: E-value and % identity are key
3. **Experiment**: Try different parameters
4. **Document**: Keep notes on what works
5. **Ask for help**: Check documentation or online resources

---

## 📞 Need Help?

1. **For BLAST basics**: Read [TUTORIAL.md](TUTORIAL.md)
2. **For command syntax**: Check [BLAST_QUICK_REFERENCE.md](BLAST_QUICK_REFERENCE.md)
3. **For understanding workflow**: See [WORKFLOW.md](WORKFLOW.md)
4. **For complete info**: Read [README.md](README.md)
5. **For BLAST help**: Run `blastn -help`

---

## ✅ What You'll Learn

By using this repository, you'll learn to:
- Install and set up BLAST+
- Create BLAST databases
- Run BLAST queries from command line
- Interpret BLAST results
- Compare viral genome sequences
- Adjust parameters for different analyses

---

## 🎓 Ready to Start?

**New to BLAST?**
→ Read [TUTORIAL.md](TUTORIAL.md)

**Just want to run it?**
→ Execute `./run_blast.sh`

**Want to see examples?**
→ Run `./blast_examples.sh`

**Need a quick reference?**
→ Open [BLAST_QUICK_REFERENCE.md](BLAST_QUICK_REFERENCE.md)

---

**Happy BLASTing! 🧬🔬**
