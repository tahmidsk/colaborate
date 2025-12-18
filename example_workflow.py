#!/usr/bin/env python3
"""
Example script demonstrating how to merge CHIKV genome sequences
This script shows the basic workflow without requiring NCBI access
"""

import os
import random
from datetime import datetime


def create_example_sequence(strain, country, year, accession, length=11825):
    """Create an example CHIKV genome sequence."""
    # Generate a dummy sequence of specified length
    # Using a realistic nucleotide distribution
    nucleotides = ['A', 'T', 'G', 'C']
    # CHIKV genome has roughly 29% A, 24% T, 24% G, 23% C
    weights = [29, 24, 24, 23]
    sequence = ''.join(random.choices(nucleotides, weights=weights, k=length))
    return sequence


def format_fasta_header(strain, country, year, accession):
    """Format a FASTA header in the standard format."""
    return f">CHIKV_{strain}_{country}_{year}_{accession}"


def write_fasta_sequence(f, header, sequence, line_length=80):
    """Write a sequence in FASTA format with line wrapping."""
    f.write(header + "\n")
    for i in range(0, len(sequence), line_length):
        f.write(sequence[i:i+line_length] + "\n")


def create_example_dataset():
    """Create an example multi-FASTA file with sequences from different regions."""
    
    # Example sequences from different continents
    sequences = [
        # Asia
        ("Ross", "India", "2006", "KJ451624"),
        ("DRDE-06", "India", "2006", "EF210157"),
        ("IND-GWL", "India", "2010", "JF950540"),
        ("Thai-Asian", "Thailand", "1995", "AF986862"),
        ("MY002IMR", "Malaysia", "2008", "FJ807897"),
        
        # Africa
        ("S27-African", "Senegal", "1983", "AF490259"),
        ("37997", "Tanzania", "1953", "AF369024"),
        ("KE12_796", "Kenya", "2004", "KJ679578"),
        ("IbH-35", "Nigeria", "1964", "EF452493"),
        ("CAR", "Central_African_Republic", "1978", "KU681082"),
        
        # America
        ("BrazilID", "Brazil", "2014", "KP164568"),
        ("CO-145", "Colombia", "2014", "KJ451625"),
        ("VE-198", "Venezuela", "2014", "KP851997"),
        ("Caribbean", "Caribbean", "2013", "KJ451626"),
        ("DR-10", "Dominican_Republic", "2014", "KP851998"),
        
        # Europe
        ("ITA07", "Italy", "2007", "EU244823"),
        ("FRA-RE", "France", "2005", "DQ443544"),
        ("ESP", "Spain", "2015", "KT327394"),
        ("GRC", "Greece", "2017", "MG846229"),
        ("NLD", "Netherlands", "2010", "JX088705"),
    ]
    
    output_file = "example_chikv_genomes.fasta"
    
    print("=" * 80)
    print("Creating Example CHIKV Genome Dataset")
    print("=" * 80)
    print()
    print(f"Generating {len(sequences)} example sequences...")
    print()
    
    with open(output_file, 'w') as f:
        for i, (strain, country, year, accession) in enumerate(sequences, 1):
            # Generate example sequence
            sequence = create_example_sequence(strain, country, year, accession)
            
            # Format header
            header = format_fasta_header(strain, country, year, accession)
            
            # Write to file
            write_fasta_sequence(f, header, sequence)
            
            print(f"  {i:2d}. {header[1:]}")  # [1:] to remove '>'
    
    print()
    print(f"Created: {output_file}")
    print()
    
    # Create summary
    summary_file = "example_chikv_genomes_summary.txt"
    with open(summary_file, 'w') as f:
        f.write("=" * 80 + "\n")
        f.write("Example CHIKV Genome Sequences Summary\n")
        f.write(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        f.write("=" * 80 + "\n\n")
        
        f.write(f"Total sequences: {len(sequences)}\n\n")
        
        # Count by region
        asia = sum(1 for s in sequences if s[1] in ["India", "Thailand", "Malaysia"])
        africa = sum(1 for s in sequences if s[1] in ["Senegal", "Tanzania", "Kenya", "Nigeria", "Central_African_Republic"])
        america = sum(1 for s in sequences if s[1] in ["Brazil", "Colombia", "Venezuela", "Caribbean", "Dominican_Republic"])
        europe = sum(1 for s in sequences if s[1] in ["Italy", "France", "Spain", "Greece", "Netherlands"])
        
        f.write("Sequences by region:\n")
        f.write(f"  Asia    : {asia:2d} sequences\n")
        f.write(f"  Africa  : {africa:2d} sequences\n")
        f.write(f"  America : {america:2d} sequences\n")
        f.write(f"  Europe  : {europe:2d} sequences\n")
        f.write("\n" + "=" * 80 + "\n")
        f.write("Sequence Details:\n")
        f.write("=" * 80 + "\n\n")
        
        for i, (strain, country, year, accession) in enumerate(sequences, 1):
            header = format_fasta_header(strain, country, year, accession)
            f.write(f"{i}. {header[1:]}\n")  # [1:] to remove '>'
            f.write(f"   Accession: {accession}\n")
            f.write(f"   Country: {country}, Year: {year}\n")
            f.write(f"   Length: 11825 bp (example)\n\n")
    
    print(f"Created: {summary_file}")
    print()
    return output_file, summary_file


def demonstrate_merging():
    """Demonstrate how to merge sequences with an assembled genome."""
    
    print("=" * 80)
    print("Demonstrating Sequence Merging")
    print("=" * 80)
    print()
    
    # Create example assembled genome
    assembled_file = "your_assembled_genome.fasta"
    print(f"Creating example assembled genome: {assembled_file}")
    
    with open(assembled_file, 'w') as f:
        header = ">CHIKV_YourStrain_USA_2024_Assembly"
        sequence = create_example_sequence("YourStrain", "USA", "2024", "Assembly")
        write_fasta_sequence(f, header, sequence)
    
    print(f"  {header[1:]}")
    print()
    
    # Merge with reference genomes
    output_file = "merged_chikv_genomes.fasta"
    print(f"Merging with reference genomes -> {output_file}")
    
    # Read reference sequences
    with open("example_chikv_genomes.fasta", 'r') as ref:
        reference_content = ref.read()
    
    # Read assembled genome
    with open(assembled_file, 'r') as asm:
        assembled_content = asm.read()
    
    # Merge
    with open(output_file, 'w') as merged:
        merged.write(reference_content)
        merged.write(assembled_content)
    
    # Count sequences
    with open(output_file, 'r') as f:
        num_sequences = sum(1 for line in f if line.startswith('>'))
    
    print(f"  Total sequences in merged file: {num_sequences}")
    print()
    
    return output_file


def show_next_steps(merged_file):
    """Show next steps for phylogenetic analysis."""
    
    print("=" * 80)
    print("Next Steps for Phylogenetic Analysis")
    print("=" * 80)
    print()
    print("1. Multiple Sequence Alignment:")
    print(f"   mafft --auto {merged_file} > aligned_genomes.fasta")
    print("   # OR")
    print(f"   clustalo -i {merged_file} -o aligned_genomes.fasta")
    print()
    print("2. Build Phylogenetic Tree:")
    print("   iqtree -s aligned_genomes.fasta -m TEST -bb 1000 -alrt 1000")
    print("   # OR")
    print("   raxmlHPC -s aligned_genomes.fasta -n chikv_tree -m GTRGAMMA -p 12345")
    print()
    print("3. Visualize Tree:")
    print("   - Use FigTree (download from http://tree.bio.ed.ac.uk/)")
    print("   - Use iTOL online (https://itol.embl.de/)")
    print("   - Use R with ggtree package")
    print()
    print("=" * 80)
    print()


def main():
    """Main function."""
    
    print("\n")
    print("=" * 80)
    print("       CHIKV Genome Collection and Merging - Example Workflow")
    print("=" * 80)
    print()
    print("This script demonstrates the workflow for collecting and merging")
    print("CHIKV genome sequences from different continents.")
    print()
    print("NOTE: This creates example data. For real data, use:")
    print("      python3 collect_chikv_genomes.py")
    print("      or")
    print("      ./collect_genomes.sh")
    print()
    
    # Step 1: Create example reference dataset
    print("\n--- Step 1: Create Reference Dataset ---\n")
    example_file, summary_file = create_example_dataset()
    
    # Step 2: Demonstrate merging
    print("\n--- Step 2: Merge with Assembled Genome ---\n")
    merged_file = demonstrate_merging()
    
    # Step 3: Show next steps
    print("\n--- Step 3: Phylogenetic Analysis ---\n")
    show_next_steps(merged_file)
    
    print("=" * 80)
    print("Example workflow completed!")
    print("=" * 80)
    print()
    print("Files created:")
    print(f"  - {example_file} (reference genomes)")
    print(f"  - {summary_file} (summary report)")
    print(f"  - your_assembled_genome.fasta (your genome)")
    print(f"  - {merged_file} (merged dataset)")
    print()
    print("For real data collection, use the main scripts:")
    print("  ./collect_genomes.sh")
    print("  or")
    print("  python3 collect_chikv_genomes.py")
    print()


if __name__ == '__main__':
    main()
