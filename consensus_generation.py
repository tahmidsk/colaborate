#!/usr/bin/env python3
"""
Consensus Sequence Generation Script for Viral Genome Sequences
Generates consensus sequences from multiple aligned genome sequences
"""

import sys
import os
from collections import Counter
from Bio import SeqIO
from Bio.Seq import Seq
from Bio.SeqRecord import SeqRecord
import argparse


def read_fasta_sequences(fasta_file):
    """Read sequences from a FASTA file"""
    sequences = []
    try:
        for record in SeqIO.parse(fasta_file, "fasta"):
            sequences.append({
                'id': record.id,
                'description': record.description,
                'seq': str(record.seq)
            })
        return sequences
    except Exception as e:
        print(f"Error reading FASTA file {fasta_file}: {e}")
        sys.exit(1)


def generate_consensus(sequences, method='majority', min_coverage=1, ambiguous_threshold=0.25):
    """
    Generate consensus sequence from multiple sequences
    
    Args:
        sequences: List of sequence dictionaries
        method: 'majority' (most common base) or 'reference' (use first as reference)
        min_coverage: Minimum number of sequences required at a position
        ambiguous_threshold: If no base has frequency above this, call as 'N'
    
    Returns:
        Consensus sequence string
    """
    if not sequences:
        return ""
    
    # Find maximum length
    max_len = max(len(seq['seq']) for seq in sequences)
    consensus = []
    
    for pos in range(max_len):
        bases = []
        
        # Collect bases at this position from all sequences
        for seq_data in sequences:
            seq = seq_data['seq']
            if pos < len(seq):
                base = seq[pos].upper()
                # Include only valid bases
                if base in 'ACGT':
                    bases.append(base)
        
        # Determine consensus base
        if len(bases) >= min_coverage:
            if method == 'majority':
                # Count bases and select most common
                base_counts = Counter(bases)
                most_common = base_counts.most_common(1)[0]
                most_common_base = most_common[0]
                most_common_freq = most_common[1] / len(bases)
                
                # Call base if above threshold, otherwise N
                if most_common_freq >= ambiguous_threshold:
                    consensus.append(most_common_base)
                else:
                    consensus.append('N')
            else:
                # Use reference (first sequence) method
                if pos < len(sequences[0]['seq']):
                    base = sequences[0]['seq'][pos].upper()
                    consensus.append(base if base in 'ACGT' else 'N')
                else:
                    consensus.append('N')
        else:
            # Insufficient coverage
            consensus.append('N')
    
    return ''.join(consensus)


def calculate_quality_metrics(sequences, consensus_seq):
    """Calculate quality metrics for consensus sequence"""
    metrics = {
        'num_sequences': len(sequences),
        'consensus_length': len(consensus_seq),
        'n_count': consensus_seq.count('N'),
        'coverage_per_position': []
    }
    
    # Calculate coverage at each position
    for pos in range(len(consensus_seq)):
        coverage = 0
        for seq_data in sequences:
            seq = seq_data['seq']
            if pos < len(seq) and seq[pos].upper() in 'ACGT':
                coverage += 1
        metrics['coverage_per_position'].append(coverage)
    
    if metrics['coverage_per_position']:
        metrics['mean_coverage'] = sum(metrics['coverage_per_position']) / len(metrics['coverage_per_position'])
        metrics['min_coverage'] = min(metrics['coverage_per_position'])
        metrics['max_coverage'] = max(metrics['coverage_per_position'])
    
    return metrics


def main():
    parser = argparse.ArgumentParser(
        description='Generate consensus sequence from multiple viral genome sequences',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Generate consensus from 4 Chikungunya sequences
  python consensus_generation.py -i chikv1.fasta chikv2.fasta chikv3.fasta chikv4.fasta -o chikv_consensus.fasta
  
  # Generate consensus with custom method and threshold
  python consensus_generation.py -i *.fasta -o consensus.fasta -m majority -t 0.3 -c 2
  
  # Generate consensus with quality metrics
  python consensus_generation.py -i *.fasta -o consensus.fasta --metrics
        """
    )
    
    parser.add_argument('-i', '--input', nargs='+', required=True,
                        help='Input FASTA files (can specify multiple files)')
    parser.add_argument('-o', '--output', required=True,
                        help='Output consensus FASTA file')
    parser.add_argument('-m', '--method', choices=['majority', 'reference'], default='majority',
                        help='Consensus method: majority (most common base) or reference (use first sequence)')
    parser.add_argument('-c', '--min-coverage', type=int, default=1,
                        help='Minimum sequence coverage at a position (default: 1)')
    parser.add_argument('-t', '--threshold', type=float, default=0.25,
                        help='Minimum frequency for majority base, otherwise call N (default: 0.25)')
    parser.add_argument('--name', default='consensus',
                        help='Name for consensus sequence (default: consensus)')
    parser.add_argument('--metrics', action='store_true',
                        help='Print quality metrics')
    
    args = parser.parse_args()
    
    # Read all input sequences
    print(f"Reading sequences from {len(args.input)} file(s)...")
    all_sequences = []
    
    for fasta_file in args.input:
        if not os.path.exists(fasta_file):
            print(f"Warning: File {fasta_file} not found, skipping...")
            continue
            
        sequences = read_fasta_sequences(fasta_file)
        for seq_data in sequences:
            all_sequences.append(seq_data)
            print(f"  - {seq_data['id']} (length: {len(seq_data['seq'])} bp)")
    
    if not all_sequences:
        print("Error: No sequences found in input files")
        sys.exit(1)
    
    print(f"\nTotal sequences: {len(all_sequences)}")
    
    # Generate consensus
    print(f"Generating consensus sequence using '{args.method}' method...")
    consensus_seq = generate_consensus(
        all_sequences, 
        method=args.method,
        min_coverage=args.min_coverage,
        ambiguous_threshold=args.threshold
    )
    
    # Calculate metrics
    metrics = calculate_quality_metrics(all_sequences, consensus_seq)
    
    # Create consensus record
    consensus_record = SeqRecord(
        Seq(consensus_seq),
        id=args.name,
        description=f"Consensus sequence from {len(all_sequences)} sequences using {args.method} method"
    )
    
    # Write consensus to file
    print(f"Writing consensus sequence to {args.output}...")
    SeqIO.write(consensus_record, args.output, "fasta")
    
    # Print metrics
    print(f"\n=== Consensus Sequence Generated ===")
    print(f"Length: {metrics['consensus_length']} bp")
    print(f"Ambiguous bases (N): {metrics['n_count']} ({metrics['n_count']/metrics['consensus_length']*100:.2f}%)")
    
    if args.metrics:
        print(f"\n=== Quality Metrics ===")
        print(f"Number of input sequences: {metrics['num_sequences']}")
        print(f"Mean coverage per position: {metrics.get('mean_coverage', 0):.2f}x")
        print(f"Min coverage: {metrics.get('min_coverage', 0)}x")
        print(f"Max coverage: {metrics.get('max_coverage', 0)}x")
    
    print(f"\n✓ Consensus generation complete!")


if __name__ == "__main__":
    main()
