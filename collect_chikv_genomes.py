#!/usr/bin/env python3
"""
CHIKV Genome Sequence Collection Script

This script collects Chikungunya virus (CHIKV) genome sequences from NCBI
and creates a multi-FASTA file with sequences from different continents.

Usage:
    python collect_chikv_genomes.py [--max-sequences N] [--output FILE]

Requirements:
    - biopython
    - requests (installed with biopython)
"""

import argparse
import sys
from datetime import datetime
from typing import List, Dict, Tuple
import time

try:
    from Bio import Entrez, SeqIO
    from Bio.SeqRecord import SeqRecord
except ImportError:
    print("Error: Biopython is required. Install it with: pip install biopython")
    sys.exit(1)


# Configure your email for NCBI Entrez (required by NCBI)
# This will be set properly in the __init__ method
Entrez.email = None


class CHIKVGenomeCollector:
    """Collects CHIKV genome sequences from different geographic regions."""
    
    # Geographic regions mapped to countries
    REGIONS = {
        'Asia': ['India', 'Thailand', 'Indonesia', 'Singapore', 'Philippines', 
                 'Malaysia', 'Sri Lanka', 'Maldives', 'Bangladesh', 'Pakistan',
                 'China', 'Taiwan', 'Japan', 'Vietnam', 'Cambodia', 'Myanmar'],
        'Africa': ['Kenya', 'Tanzania', 'Uganda', 'Congo', 'Senegal', 'Gabon',
                   'Central African Republic', 'Sudan', 'Comoros', 'Seychelles',
                   'Madagascar', 'Reunion', 'Mayotte', 'South Africa', 'Nigeria',
                   'Cameroon', 'Angola', 'Mozambique'],
        'America': ['Brazil', 'Colombia', 'Caribbean', 'Venezuela', 'Mexico',
                    'USA', 'United States', 'Puerto Rico', 'Dominican Republic',
                    'Haiti', 'Martinique', 'Guadeloupe', 'Argentina', 'Ecuador',
                    'Bolivia', 'Paraguay', 'Peru', 'Chile', 'Nicaragua', 'Honduras',
                    'El Salvador', 'Guatemala', 'Panama', 'Costa Rica'],
        'Europe': ['Italy', 'France', 'Spain', 'Greece', 'Netherlands', 'Germany',
                   'Switzerland', 'United Kingdom', 'Belgium', 'Austria', 'Portugal',
                   'Sweden', 'Norway', 'Denmark', 'Finland', 'Poland']
    }
    
    def __init__(self, email: str = None):
        """Initialize the collector with optional email for NCBI."""
        if email:
            Entrez.email = email
        
        # Validate that email is set
        if not Entrez.email or Entrez.email == "your.email@example.com":
            print("Warning: No valid email provided for NCBI.")
            print("NCBI requires an email address for API usage.")
            print("Please provide one using --email option or set it in the script.")
            print("Using placeholder email may result in API restrictions.")
    
    def search_chikv_genomes(self, max_results: int = 200) -> List[str]:
        """
        Search for CHIKV complete genome sequences in NCBI.
        
        Args:
            max_results: Maximum number of sequences to retrieve
            
        Returns:
            List of GenBank IDs
        """
        print(f"Searching NCBI for CHIKV genome sequences...")
        
        # Search query for complete genomes
        search_query = (
            '("Chikungunya virus"[Organism]) AND '
            '(complete genome[Title] OR complete sequence[Title]) AND '
            '8000:15000[Sequence Length]'
        )
        
        try:
            with Entrez.esearch(
                db="nucleotide",
                term=search_query,
                retmax=max_results,
                sort="relevance"
            ) as handle:
                record = Entrez.read(handle)
            
            id_list = record["IdList"]
            print(f"Found {len(id_list)} sequences")
            return id_list
            
        except Exception as e:
            print(f"Error searching NCBI: {e}")
            return []
    
    def fetch_sequence_details(self, id_list: List[str]) -> List[SeqRecord]:
        """
        Fetch detailed sequence records from NCBI.
        
        Args:
            id_list: List of GenBank IDs
            
        Returns:
            List of SeqRecord objects
        """
        print(f"Fetching {len(id_list)} sequences from NCBI...")
        sequences = []
        
        # Fetch in batches to avoid overwhelming the server
        batch_size = 20
        for i in range(0, len(id_list), batch_size):
            batch = id_list[i:i+batch_size]
            print(f"  Fetching batch {i//batch_size + 1}/{(len(id_list)-1)//batch_size + 1}...")
            
            try:
                with Entrez.efetch(
                    db="nucleotide",
                    id=batch,
                    rettype="gb",
                    retmode="text"
                ) as handle:
                    records = list(SeqIO.parse(handle, "genbank"))
                sequences.extend(records)
                
                # Be nice to NCBI servers
                time.sleep(0.5)
                
            except Exception as e:
                print(f"  Error fetching batch: {e}")
                continue
        
        print(f"Successfully fetched {len(sequences)} sequences")
        return sequences
    
    def extract_metadata(self, record: SeqRecord) -> Tuple[str, str, str]:
        """
        Extract strain, country, and year from sequence record.
        
        Args:
            record: SeqRecord object
            
        Returns:
            Tuple of (strain, country, year)
        """
        strain = "Unknown"
        country = "Unknown"
        year = "Unknown"
        
        # Extract from features
        for feature in record.features:
            if feature.type == "source":
                qualifiers = feature.qualifiers
                
                # Get strain
                if "strain" in qualifiers:
                    strain = qualifiers["strain"][0]
                elif "isolate" in qualifiers:
                    strain = qualifiers["isolate"][0]
                
                # Get country
                if "country" in qualifiers:
                    country_info = qualifiers["country"][0]
                    # Country format is often "Country: Region"
                    country = country_info.split(":")[0].strip()
                
                # Get collection date
                if "collection_date" in qualifiers:
                    date_str = qualifiers["collection_date"][0]
                    # Extract year from various date formats
                    for part in date_str.split('-'):
                        if len(part) == 4 and part.isdigit():
                            year = part
                            break
        
        # Clean strain name (remove special characters)
        strain = strain.replace(" ", "_").replace("/", "_").replace(":", "_")
        country = country.replace(" ", "_")
        
        return strain, country, year
    
    def categorize_by_region(self, sequences: List[SeqRecord]) -> Dict[str, List[SeqRecord]]:
        """
        Categorize sequences by geographic region.
        
        Args:
            sequences: List of SeqRecord objects
            
        Returns:
            Dictionary mapping region names to lists of sequences
        """
        categorized = {region: [] for region in self.REGIONS.keys()}
        categorized['Other'] = []
        
        for record in sequences:
            strain, country, year = self.extract_metadata(record)
            
            # Find which region this country belongs to
            found_region = False
            for region, countries in self.REGIONS.items():
                if any(c.lower() in country.lower() for c in countries):
                    categorized[region].append(record)
                    found_region = True
                    break
            
            if not found_region:
                categorized['Other'].append(record)
        
        return categorized
    
    def format_sequence_header(self, record: SeqRecord) -> str:
        """
        Format sequence header in the format: Strain_Country_Year
        
        Args:
            record: SeqRecord object
            
        Returns:
            Formatted header string
        """
        strain, country, year = self.extract_metadata(record)
        
        # Create descriptive header
        header = f"CHIKV_{strain}_{country}_{year}"
        
        # Add GenBank accession for reference
        accession = record.id
        header += f"_{accession}"
        
        return header
    
    def select_representative_sequences(self, 
                                       categorized: Dict[str, List[SeqRecord]], 
                                       sequences_per_region: int = 20) -> List[SeqRecord]:
        """
        Select representative sequences from each region.
        
        Args:
            categorized: Dictionary of sequences by region
            sequences_per_region: Number of sequences to select per region
            
        Returns:
            List of selected SeqRecord objects
        """
        selected = []
        
        print("\nSelecting representative sequences:")
        for region, sequences in categorized.items():
            if not sequences:
                print(f"  {region}: 0 sequences (skipped)")
                continue
            
            # Take up to sequences_per_region from each region
            n_select = min(len(sequences), sequences_per_region)
            selected.extend(sequences[:n_select])
            print(f"  {region}: {len(sequences)} available, {n_select} selected")
        
        return selected
    
    def write_multifasta(self, sequences: List[SeqRecord], output_file: str):
        """
        Write sequences to a multi-FASTA file with formatted headers.
        
        Args:
            sequences: List of SeqRecord objects
            output_file: Output file path
        """
        print(f"\nWriting {len(sequences)} sequences to {output_file}...")
        
        with open(output_file, 'w') as f:
            for record in sequences:
                header = self.format_sequence_header(record)
                f.write(f">{header}\n")
                
                # Write sequence in lines of 80 characters
                sequence = str(record.seq)
                for i in range(0, len(sequence), 80):
                    f.write(sequence[i:i+80] + "\n")
        
        print(f"Successfully wrote multi-FASTA file: {output_file}")
    
    def generate_summary(self, sequences: List[SeqRecord], output_file: str):
        """
        Generate a summary report of collected sequences.
        
        Args:
            sequences: List of SeqRecord objects
            output_file: Output file path
        """
        summary_file = output_file.replace('.fasta', '_summary.txt')
        
        print(f"\nGenerating summary report: {summary_file}")
        
        with open(summary_file, 'w') as f:
            f.write("=" * 80 + "\n")
            f.write("CHIKV Genome Sequences Collection Summary\n")
            f.write(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write("=" * 80 + "\n\n")
            
            f.write(f"Total sequences collected: {len(sequences)}\n\n")
            
            # Categorize for summary
            categorized = self.categorize_by_region(sequences)
            
            f.write("Sequences by region:\n")
            for region in ['Asia', 'Africa', 'America', 'Europe', 'Other']:
                count = len(categorized[region])
                f.write(f"  {region:15s}: {count:3d} sequences\n")
            
            f.write("\n" + "=" * 80 + "\n")
            f.write("Sequence Details:\n")
            f.write("=" * 80 + "\n\n")
            
            for i, record in enumerate(sequences, 1):
                strain, country, year = self.extract_metadata(record)
                header = self.format_sequence_header(record)
                length = len(record.seq)
                
                f.write(f"{i}. {header}\n")
                f.write(f"   Accession: {record.id}\n")
                description = record.description if len(record.description) <= 80 else record.description[:80] + "..."
                f.write(f"   Description: {description}\n")
                f.write(f"   Length: {length} bp\n")
                f.write(f"   Country: {country}, Year: {year}\n\n")
        
        print(f"Summary report saved: {summary_file}")


def main():
    """Main function to run the genome collection pipeline."""
    parser = argparse.ArgumentParser(
        description='Collect CHIKV genome sequences from different continents',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Collect default set of sequences (20 per region)
  python collect_chikv_genomes.py
  
  # Collect more sequences with custom output
  python collect_chikv_genomes.py --max-sequences 200 --output my_genomes.fasta
  
  # Set custom email for NCBI
  python collect_chikv_genomes.py --email your.email@example.com
        """
    )
    
    parser.add_argument(
        '--max-sequences',
        type=int,
        default=200,
        help='Maximum number of sequences to search for (default: 200)'
    )
    
    parser.add_argument(
        '--sequences-per-region',
        type=int,
        default=20,
        help='Number of sequences to select per region (default: 20)'
    )
    
    parser.add_argument(
        '--output',
        type=str,
        default='all_chikv_genomes.fasta',
        help='Output FASTA file name (default: all_chikv_genomes.fasta)'
    )
    
    parser.add_argument(
        '--email',
        type=str,
        help='Your email address for NCBI Entrez (recommended)'
    )
    
    args = parser.parse_args()
    
    print("=" * 80)
    print("CHIKV Genome Sequence Collection Tool")
    print("=" * 80)
    print()
    
    # Initialize collector
    collector = CHIKVGenomeCollector(email=args.email)
    
    # Step 1: Search for sequences
    id_list = collector.search_chikv_genomes(max_results=args.max_sequences)
    
    if not id_list:
        print("No sequences found. Exiting.")
        return 1
    
    # Step 2: Fetch sequence details
    sequences = collector.fetch_sequence_details(id_list)
    
    if not sequences:
        print("Failed to fetch sequences. Exiting.")
        return 1
    
    # Step 3: Categorize by region
    categorized = collector.categorize_by_region(sequences)
    
    # Step 4: Select representative sequences
    selected = collector.select_representative_sequences(
        categorized, 
        sequences_per_region=args.sequences_per_region
    )
    
    print(f"\nTotal sequences selected: {len(selected)}")
    
    # Step 5: Write multi-FASTA file
    collector.write_multifasta(selected, args.output)
    
    # Step 6: Generate summary report
    collector.generate_summary(selected, args.output)
    
    print("\n" + "=" * 80)
    print("Collection completed successfully!")
    print("=" * 80)
    print(f"\nOutput files:")
    print(f"  - FASTA file: {args.output}")
    print(f"  - Summary: {args.output.replace('.fasta', '_summary.txt')}")
    print("\nNext steps:")
    print("  1. Review the summary file to check sequence selection")
    print("  2. Use the FASTA file for multiple sequence alignment")
    print("  3. Perform phylogenetic analysis with your assembled genome")
    
    return 0


if __name__ == '__main__':
    sys.exit(main())
