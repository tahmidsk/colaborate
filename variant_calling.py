#!/usr/bin/env python3
"""
Variant Calling Script for Viral Genome Sequences
Performs variant calling by comparing aligned sequences to a reference genome
"""

import sys
import os
from collections import defaultdict
from Bio import SeqIO, AlignIO
from Bio.Align import MultipleSeqAlignment
from Bio.Seq import Seq
from Bio.SeqRecord import SeqRecord
import argparse


def read_fasta_sequences(fasta_file):
    """Read sequences from a FASTA file"""
    sequences = {}
    try:
        for record in SeqIO.parse(fasta_file, "fasta"):
            sequences[record.id] = str(record.seq)
        return sequences
    except Exception as e:
        print(f"Error reading FASTA file {fasta_file}: {e}")
        sys.exit(1)


def call_variants(reference_seq, sample_seqs, min_frequency=0.25):
    """
    Call variants by comparing sample sequences to reference
    
    Args:
        reference_seq: Reference sequence string
        sample_seqs: Dictionary of sample_id -> sequence string
        min_frequency: Minimum allele frequency to call a variant
    
    Returns:
        List of variant calls
    """
    variants = []
    ref_len = len(reference_seq)
    
    # Check each position
    for pos in range(ref_len):
        ref_base = reference_seq[pos]
        alt_bases = defaultdict(int)
        total_samples = 0
        
        # Count alternative bases at this position
        for sample_id, seq in sample_seqs.items():
            if pos < len(seq):
                base = seq[pos]
                if base != '-' and base != 'N':  # Skip gaps and N's
                    total_samples += 1
                    if base != ref_base:
                        alt_bases[base] += 1
        
        # Call variants if frequency threshold is met
        if total_samples > 0:
            for alt_base, count in alt_bases.items():
                frequency = count / total_samples
                if frequency >= min_frequency:
                    variant = {
                        'position': pos + 1,  # 1-based position
                        'ref': ref_base,
                        'alt': alt_base,
                        'frequency': frequency,
                        'count': count,
                        'total': total_samples
                    }
                    variants.append(variant)
    
    return variants


def write_vcf(variants, reference_id, output_file, sample_names):
    """Write variants in VCF format"""
    with open(output_file, 'w') as f:
        # Write VCF header
        f.write("##fileformat=VCFv4.2\n")
        f.write("##source=ViralVariantCaller\n")
        f.write(f"##reference={reference_id}\n")
        f.write("##INFO=<ID=AF,Number=A,Type=Float,Description=\"Allele Frequency\">\n")
        f.write("##INFO=<ID=DP,Number=1,Type=Integer,Description=\"Total Depth\">\n")
        f.write("##INFO=<ID=AC,Number=A,Type=Integer,Description=\"Allele Count\">\n")
        
        # Column headers
        sample_names_str = "\t".join(sample_names) if sample_names else ""
        if sample_names_str:
            f.write(f"#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\t{sample_names_str}\n")
        else:
            f.write("#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\n")
        
        # Write variants
        for var in variants:
            info = f"AF={var['frequency']:.4f};AC={var['count']};DP={var['total']}"
            f.write(f"{reference_id}\t{var['position']}\t.\t{var['ref']}\t{var['alt']}\t.\tPASS\t{info}\n")


def main():
    parser = argparse.ArgumentParser(
        description='Call variants from aligned viral genome sequences',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Call variants with default settings
  python variant_calling.py -r reference.fasta -s sample1.fasta sample2.fasta -o variants.vcf
  
  # Call variants with custom frequency threshold
  python variant_calling.py -r reference.fasta -s *.fasta -o variants.vcf -f 0.3
        """
    )
    
    parser.add_argument('-r', '--reference', required=True,
                        help='Reference genome FASTA file')
    parser.add_argument('-s', '--samples', nargs='+', required=True,
                        help='Sample genome FASTA files')
    parser.add_argument('-o', '--output', required=True,
                        help='Output VCF file')
    parser.add_argument('-f', '--min-frequency', type=float, default=0.25,
                        help='Minimum allele frequency to call variant (default: 0.25)')
    parser.add_argument('--summary', action='store_true',
                        help='Print summary of variants to stdout')
    
    args = parser.parse_args()
    
    # Read reference sequence
    print(f"Reading reference sequence from {args.reference}...")
    ref_sequences = read_fasta_sequences(args.reference)
    
    if len(ref_sequences) != 1:
        print(f"Error: Reference file should contain exactly one sequence, found {len(ref_sequences)}")
        sys.exit(1)
    
    reference_id = list(ref_sequences.keys())[0]
    reference_seq = ref_sequences[reference_id]
    print(f"Reference: {reference_id} (length: {len(reference_seq)} bp)")
    
    # Read sample sequences
    print(f"\nReading {len(args.samples)} sample file(s)...")
    sample_seqs = {}
    sample_names = []
    
    for sample_file in args.samples:
        seqs = read_fasta_sequences(sample_file)
        for seq_id, seq in seqs.items():
            sample_seqs[seq_id] = seq
            sample_names.append(seq_id)
            print(f"  - {seq_id} (length: {len(seq)} bp)")
    
    # Call variants
    print(f"\nCalling variants (min frequency: {args.min_frequency})...")
    variants = call_variants(reference_seq, sample_seqs, args.min_frequency)
    
    # Write VCF output
    print(f"Writing {len(variants)} variants to {args.output}...")
    write_vcf(variants, reference_id, args.output, sample_names)
    
    # Print summary if requested
    if args.summary:
        print("\n=== Variant Summary ===")
        print(f"Total variants called: {len(variants)}")
        if variants:
            print("\nVariant details:")
            print(f"{'Position':<10} {'Ref':<5} {'Alt':<5} {'Frequency':<12} {'Count/Total'}")
            print("-" * 50)
            for var in variants:
                print(f"{var['position']:<10} {var['ref']:<5} {var['alt']:<5} "
                      f"{var['frequency']:<12.4f} {var['count']}/{var['total']}")
    
    print(f"\n✓ Variant calling complete!")


if __name__ == "__main__":
    main()
