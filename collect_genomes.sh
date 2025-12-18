#!/bin/bash
# CHIKV Genome Collection Script
# 
# This script automates the collection of CHIKV genome sequences from NCBI
# and creates a multi-FASTA file for phylogenetic analysis.
#
# Usage: ./collect_genomes.sh [OPTIONS]

set -e  # Exit on error

# Default values
MAX_SEQUENCES=200
SEQUENCES_PER_REGION=20
OUTPUT_FILE="all_chikv_genomes.fasta"
EMAIL=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to display usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Collect CHIKV genome sequences from different continents for phylogenetic analysis.

OPTIONS:
    -m, --max-sequences NUM       Maximum number of sequences to search (default: 200)
    -r, --sequences-per-region N  Number of sequences per region (default: 20)
    -o, --output FILE             Output FASTA file name (default: all_chikv_genomes.fasta)
    -e, --email EMAIL             Your email for NCBI (recommended)
    -h, --help                    Display this help message
    
EXAMPLES:
    # Basic usage with defaults
    $0
    
    # Collect more sequences with custom output
    $0 --max-sequences 300 --output my_chikv_genomes.fasta
    
    # With email for NCBI compliance
    $0 --email your.email@example.com
    
    # Full customization
    $0 -m 300 -r 25 -o genomes.fasta -e user@example.com

EOF
    exit 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -m|--max-sequences)
            MAX_SEQUENCES="$2"
            shift 2
            ;;
        -r|--sequences-per-region)
            SEQUENCES_PER_REGION="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -e|--email)
            EMAIL="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            print_error "Unknown option: $1"
            usage
            ;;
    esac
done

# Print banner
echo "=============================================================================="
echo "                  CHIKV Genome Collection Tool"
echo "=============================================================================="
echo ""

# Check if Python is installed
print_info "Checking Python installation..."
if ! command -v python3 &> /dev/null; then
    print_error "Python 3 is not installed. Please install Python 3.6 or higher."
    exit 1
fi
print_info "Python 3 found: $(python3 --version)"

# Check if biopython is installed
print_info "Checking for Biopython..."
if ! python3 -c "import Bio" 2>/dev/null; then
    print_warning "Biopython is not installed."
    print_info "Installing Biopython..."
    
    # Try to install biopython
    if python3 -m pip install biopython --user; then
        print_info "Biopython installed successfully!"
    else
        print_error "Failed to install Biopython."
        print_error "Please install it manually with: pip install biopython"
        exit 1
    fi
else
    print_info "Biopython is already installed."
fi

# Build python command
PYTHON_CMD="python3 collect_chikv_genomes.py --max-sequences $MAX_SEQUENCES --sequences-per-region $SEQUENCES_PER_REGION --output $OUTPUT_FILE"

if [ -n "$EMAIL" ]; then
    PYTHON_CMD="$PYTHON_CMD --email $EMAIL"
fi

# Display configuration
echo ""
print_info "Configuration:"
echo "  Max sequences to search: $MAX_SEQUENCES"
echo "  Sequences per region: $SEQUENCES_PER_REGION"
echo "  Output file: $OUTPUT_FILE"
if [ -n "$EMAIL" ]; then
    echo "  Email for NCBI: $EMAIL"
else
    print_warning "No email provided. Consider using --email for NCBI compliance."
fi
echo ""

# Run the Python script
print_info "Starting genome collection..."
echo ""

if eval "$PYTHON_CMD"; then
    echo ""
    print_info "Collection completed successfully!"
    echo ""
    
    # Display output files
    if [ -f "$OUTPUT_FILE" ]; then
        FASTA_SIZE=$(wc -c < "$OUTPUT_FILE" | tr -d ' ')
        FASTA_SEQS=$(grep -c "^>" "$OUTPUT_FILE" || true)
        print_info "Output files created:"
        echo "  📄 $OUTPUT_FILE (${FASTA_SEQS} sequences, ${FASTA_SIZE} bytes)"
        
        SUMMARY_FILE="${OUTPUT_FILE%.fasta}_summary.txt"
        if [ -f "$SUMMARY_FILE" ]; then
            SUMMARY_SIZE=$(wc -c < "$SUMMARY_FILE" | tr -d ' ')
            echo "  📊 $SUMMARY_FILE (${SUMMARY_SIZE} bytes)"
        fi
    fi
    
    echo ""
    print_info "Next steps:"
    echo "  1. Review the summary file to verify sequence selection"
    echo "  2. Add your assembled genome to the FASTA file"
    echo "  3. Perform multiple sequence alignment (e.g., with MAFFT or Clustal)"
    echo "  4. Build phylogenetic tree (e.g., with RAxML or IQ-TREE)"
    echo ""
else
    echo ""
    print_error "Collection failed. Please check the error messages above."
    exit 1
fi
