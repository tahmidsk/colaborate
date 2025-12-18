#!/bin/bash
# CHIKV Genome Collection Script (Pure Bash/Linux Version)
# 
# This script collects CHIKV genome sequences from NCBI using curl/wget
# and creates a multi-FASTA file for phylogenetic analysis.
# No Python required - uses only standard Linux tools.
#
# Requirements: curl or wget, grep, sed, awk
#
# Usage: ./collect_genomes_linux.sh [OPTIONS]

set -e  # Exit on error

# Default values
MAX_SEQUENCES=200
SEQUENCES_PER_REGION=20
OUTPUT_FILE="all_chikv_genomes.fasta"
EMAIL="your.email@example.com"
RETMAX=500

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Function to display usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Collect CHIKV genome sequences from different continents using pure Linux tools.
No Python required - uses curl/wget, grep, sed, awk.

OPTIONS:
    -m, --max-sequences NUM       Maximum number of sequences to search (default: 200)
    -r, --sequences-per-region N  Number of sequences per region (default: 20)
    -o, --output FILE             Output FASTA file name (default: all_chikv_genomes.fasta)
    -e, --email EMAIL             Your email for NCBI (recommended)
    -h, --help                    Display this help message
    
EXAMPLES:
    # Basic usage with defaults
    $0
    
    # Collect sequences with custom output
    $0 --max-sequences 300 --output my_chikv_genomes.fasta
    
    # With email for NCBI compliance
    $0 --email your.email@example.com
    
    # Full customization
    $0 -m 300 -r 25 -o genomes.fasta -e user@example.com

GEOGRAPHIC REGIONS:
    Asia    - India, Thailand, Indonesia, Singapore, etc.
    Africa  - Kenya, Tanzania, Senegal, Uganda, etc.
    America - Brazil, Colombia, USA, Caribbean, etc.
    Europe  - Italy, France, Spain, Greece, etc.

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
echo "          CHIKV Genome Collection Tool (Pure Linux Version)"
echo "=============================================================================="
echo ""
print_info "No Python required - using curl/wget and standard Linux tools"
echo ""

# Check for required tools
print_info "Checking required tools..."

# Check for curl or wget
if command -v curl &> /dev/null; then
    HTTP_TOOL="curl"
    print_info "Found curl"
elif command -v wget &> /dev/null; then
    HTTP_TOOL="wget"
    print_info "Found wget"
else
    print_error "Neither curl nor wget found. Please install one of them."
    exit 1
fi

# Check for other required tools
REQUIRED_TOOLS="grep sed awk"
for tool in $REQUIRED_TOOLS; do
    if ! command -v "$tool" &> /dev/null; then
        print_error "$tool is not installed. Please install it."
        exit 1
    fi
done
print_info "All required tools found"

# Create temp directory
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

print_info "Using temporary directory: $TEMP_DIR"
echo ""

# Display configuration
print_info "Configuration:"
echo "  Email for NCBI: $EMAIL"
echo "  Max sequences to search: $MAX_SEQUENCES"
echo "  Sequences per region: $SEQUENCES_PER_REGION"
echo "  Output file: $OUTPUT_FILE"
echo ""

# Function to fetch data with curl or wget
fetch_url() {
    local url="$1"
    local output="$2"
    
    if [ "$HTTP_TOOL" = "curl" ]; then
        curl -s -L "$url" -o "$output"
    else
        wget -q "$url" -O "$output"
    fi
}

# Function to search NCBI for CHIKV sequences
search_ncbi() {
    print_step "Searching NCBI for CHIKV genome sequences..."
    
    local search_query="Chikungunya+virus[Organism]+AND+(complete+genome[Title]+OR+complete+sequence[Title])"
    local search_url="https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=nucleotide&term=${search_query}&retmax=${MAX_SEQUENCES}&usehistory=y&retmode=xml&email=${EMAIL}"
    
    local search_result="$TEMP_DIR/search_result.xml"
    fetch_url "$search_url" "$search_result"
    
    # Extract WebEnv and QueryKey for efetch
    WEBENV=$(grep -oP '(?<=<WebEnv>)[^<]+' "$search_result" || echo "")
    QUERYKEY=$(grep -oP '(?<=<QueryKey>)[^<]+' "$search_result" || echo "")
    COUNT=$(grep -oP '(?<=<Count>)[^<]+' "$search_result" || echo "0")
    
    print_info "Found $COUNT sequences in NCBI"
    
    if [ -z "$WEBENV" ] || [ -z "$QUERYKEY" ]; then
        print_error "Failed to get search results from NCBI"
        exit 1
    fi
}

# Function to fetch sequences in batches
fetch_sequences() {
    print_step "Fetching sequences from NCBI (this may take a few minutes)..."
    
    local fetch_url="https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nucleotide&query_key=${QUERYKEY}&WebEnv=${WEBENV}&rettype=fasta&retmode=text&email=${EMAIL}"
    
    local all_sequences="$TEMP_DIR/all_sequences.fasta"
    fetch_url "$fetch_url" "$all_sequences"
    
    # Count sequences
    local seq_count=$(grep -c "^>" "$all_sequences" || echo "0")
    print_info "Downloaded $seq_count sequences"
    
    if [ "$seq_count" -eq 0 ]; then
        print_error "No sequences downloaded"
        exit 1
    fi
    
    echo "$all_sequences"
}

# Function to extract metadata from FASTA header
extract_metadata() {
    local header="$1"
    
    # Extract accession (first field after >)
    local accession=$(echo "$header" | sed 's/^>//' | awk '{print $1}')
    
    # Try to extract country
    local country=$(echo "$header" | grep -oP '(?<=country=")[^"]+' || echo "$header" | grep -oP '(?<=:)[^:,]+(?=,)' || echo "Unknown")
    country=$(echo "$country" | awk -F: '{print $1}' | sed 's/^ *//;s/ *$//')
    
    # Try to extract year
    local year=$(echo "$header" | grep -oP '\b(19|20)\d{2}\b' | head -1 || echo "Unknown")
    
    # Try to extract strain
    local strain=$(echo "$header" | grep -oP '(?<=strain=")[^"]+' || echo "$header" | grep -oP '(?<=isolate=")[^"]+' || echo "Unknown")
    
    echo "$accession|$country|$year|$strain"
}

# Function to categorize by region
categorize_sequences() {
    print_step "Categorizing sequences by geographic region..."
    
    local input_fasta="$1"
    
    # Define region patterns
    declare -A REGION_PATTERNS
    REGION_PATTERNS[Asia]="India|Thailand|Indonesia|Singapore|Philippines|Malaysia|Sri Lanka|Bangladesh|Pakistan|China|Taiwan|Japan|Vietnam|Cambodia|Myanmar"
    REGION_PATTERNS[Africa]="Kenya|Tanzania|Uganda|Congo|Senegal|Gabon|Sudan|Comoros|Seychelles|Madagascar|Reunion|Mayotte|South Africa|Nigeria|Cameroon|Angola|Mozambique"
    REGION_PATTERNS[America]="Brazil|Colombia|Venezuela|Mexico|USA|United States|Puerto Rico|Dominican Republic|Haiti|Martinique|Guadeloupe|Argentina|Ecuador|Bolivia|Paraguay|Peru|Chile|Nicaragua|Honduras|Salvador|Guatemala|Panama|Costa Rica|Caribbean"
    REGION_PATTERNS[Europe]="Italy|France|Spain|Greece|Netherlands|Germany|Switzerland|United Kingdom|Belgium|Austria|Portugal|Sweden|Norway|Denmark|Finland|Poland"
    
    # Create region files
    for region in Asia Africa America Europe; do
        > "$TEMP_DIR/${region}.fasta"
        > "$TEMP_DIR/${region}_count.txt"
    done
    > "$TEMP_DIR/Other.fasta"
    
    # Process each sequence
    local current_header=""
    local current_seq=""
    local count=0
    
    while IFS= read -r line; do
        if [[ "$line" == ">"* ]]; then
            # Save previous sequence
            if [ -n "$current_header" ]; then
                process_sequence "$current_header" "$current_seq"
                count=$((count + 1))
            fi
            current_header="$line"
            current_seq=""
        else
            current_seq="${current_seq}${line}"
        fi
    done < "$input_fasta"
    
    # Process last sequence
    if [ -n "$current_header" ]; then
        process_sequence "$current_header" "$current_seq"
        count=$((count + 1))
    fi
    
    print_info "Categorized $count sequences"
    
    # Print region counts
    for region in Asia Africa America Europe Other; do
        local region_count=$(grep -c "^>" "$TEMP_DIR/${region}.fasta" 2>/dev/null || echo "0")
        printf "  %-10s: %3d sequences\n" "$region" "$region_count"
    done
}

# Function to process individual sequence
process_sequence() {
    local header="$1"
    local sequence="$2"
    
    local metadata=$(extract_metadata "$header")
    local country=$(echo "$metadata" | cut -d'|' -f2)
    
    local found_region="Other"
    
    # Check each region
    for region in Asia Africa America Europe; do
        local pattern="${REGION_PATTERNS[$region]}"
        if echo "$country" | grep -qiE "$pattern"; then
            found_region="$region"
            break
        fi
    done
    
    # Write to region file
    echo "$header" >> "$TEMP_DIR/${found_region}.fasta"
    echo "$sequence" >> "$TEMP_DIR/${found_region}.fasta"
}

# Function to select representative sequences
select_sequences() {
    print_step "Selecting representative sequences from each region..."
    
    local temp_output="$TEMP_DIR/selected.fasta"
    > "$temp_output"
    
    local total_selected=0
    
    for region in Asia Africa America Europe; do
        local region_file="$TEMP_DIR/${region}.fasta"
        local count=$(grep -c "^>" "$region_file" 2>/dev/null || echo "0")
        
        if [ "$count" -gt 0 ]; then
            local to_select=$SEQUENCES_PER_REGION
            if [ "$count" -lt "$to_select" ]; then
                to_select=$count
            fi
            
            # Extract first N sequences
            awk -v n=$to_select 'BEGIN{count=0} /^>/{count++} count<=n' "$region_file" >> "$temp_output"
            
            total_selected=$((total_selected + to_select))
            print_info "Selected $to_select sequences from $region"
        fi
    done
    
    print_info "Total sequences selected: $total_selected"
    echo "$temp_output"
}

# Function to format headers
format_headers() {
    print_step "Formatting sequence headers..."
    
    local input_fasta="$1"
    local output_fasta="$2"
    
    > "$output_fasta"
    
    local count=0
    while IFS= read -r line; do
        if [[ "$line" == ">"* ]]; then
            local metadata=$(extract_metadata "$line")
            local accession=$(echo "$metadata" | cut -d'|' -f1)
            local country=$(echo "$metadata" | cut -d'|' -f2 | tr ' ' '_')
            local year=$(echo "$metadata" | cut -d'|' -f3)
            local strain=$(echo "$metadata" | cut -d'|' -f4 | tr ' ' '_' | tr '/' '_')
            
            # Format: >CHIKV_Strain_Country_Year_Accession
            echo ">CHIKV_${strain}_${country}_${year}_${accession}" >> "$output_fasta"
            count=$((count + 1))
        else
            echo "$line" >> "$output_fasta"
        fi
    done < "$input_fasta"
    
    print_info "Formatted $count sequence headers"
}

# Function to generate summary
generate_summary() {
    print_step "Generating summary report..."
    
    local fasta_file="$1"
    local summary_file="${fasta_file%.fasta}_summary.txt"
    
    cat > "$summary_file" << EOF
================================================================================
CHIKV Genome Sequences Collection Summary (Linux Version)
Generated: $(date '+%Y-%m-%d %H:%M:%S')
================================================================================

Total sequences collected: $(grep -c "^>" "$fasta_file")

Sequences by region:
EOF
    
    # Count by region
    for region in Asia Africa America Europe; do
        local pattern="${REGION_PATTERNS[$region]}"
        local count=$(grep "^>" "$fasta_file" | grep -icE "$pattern" || echo "0")
        printf "  %-15s: %3d sequences\n" "$region" "$count" >> "$summary_file"
    done
    
    cat >> "$summary_file" << EOF

================================================================================
Sequence Headers:
================================================================================

EOF
    
    grep "^>" "$fasta_file" | sed 's/^>//' | nl -w3 -s'. ' >> "$summary_file"
    
    print_info "Summary saved to: $summary_file"
}

# Main execution
main() {
    print_step "Starting CHIKV genome collection..."
    echo ""
    
    # Step 1: Search NCBI
    search_ncbi
    echo ""
    
    # Step 2: Fetch sequences
    ALL_SEQS=$(fetch_sequences)
    echo ""
    
    # Step 3: Categorize by region
    categorize_sequences "$ALL_SEQS"
    echo ""
    
    # Step 4: Select representative sequences
    SELECTED=$(select_sequences)
    echo ""
    
    # Step 5: Format headers
    format_headers "$SELECTED" "$OUTPUT_FILE"
    echo ""
    
    # Step 6: Generate summary
    generate_summary "$OUTPUT_FILE"
    echo ""
    
    print_info "Collection completed successfully!"
    echo ""
    
    # Display output files
    if [ -f "$OUTPUT_FILE" ]; then
        local fasta_size=$(wc -c < "$OUTPUT_FILE" | tr -d ' ')
        local fasta_seqs=$(grep -c "^>" "$OUTPUT_FILE")
        print_info "Output files created:"
        echo "  📄 $OUTPUT_FILE (${fasta_seqs} sequences, ${fasta_size} bytes)"
        
        local summary_file="${OUTPUT_FILE%.fasta}_summary.txt"
        if [ -f "$summary_file" ]; then
            local summary_size=$(wc -c < "$summary_file" | tr -d ' ')
            echo "  📊 $summary_file (${summary_size} bytes)"
        fi
    fi
    
    echo ""
    print_info "Next steps:"
    echo "  1. Review the summary file to verify sequence selection"
    echo "  2. Add your assembled genome to the FASTA file"
    echo "  3. Perform multiple sequence alignment (e.g., with MAFFT or Clustal)"
    echo "  4. Build phylogenetic tree (e.g., with RAxML or IQ-TREE)"
    echo ""
}

# Run main function
main
