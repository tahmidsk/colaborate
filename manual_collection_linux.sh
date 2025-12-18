#!/bin/bash
# Simple Manual CHIKV Genome Collection (Pure Linux Commands)
# This script shows the manual steps using only curl/wget
# No Python required!

set -e

echo "=============================================================================="
echo "    Manual CHIKV Genome Collection - Pure Linux Commands"
echo "=============================================================================="
echo ""
echo "This script demonstrates how to collect CHIKV genomes using only Linux tools"
echo ""

# Configuration
EMAIL="your.email@example.com"
OUTPUT_FILE="chikv_genomes_manual.fasta"
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

echo "Using temporary directory: $TEMP_DIR"
echo ""

# Check for HTTP tool
if command -v curl &> /dev/null; then
    HTTP_TOOL="curl -s"
    echo "[✓] Found curl"
elif command -v wget &> /dev/null; then
    HTTP_TOOL="wget -q -O -"
    echo "[✓] Found wget"
else
    echo "[✗] Neither curl nor wget found!"
    exit 1
fi

echo ""
echo "=============================================================================="
echo "Step 1: Search for CHIKV sequences in NCBI"
echo "=============================================================================="
echo ""

# Build search URL
SEARCH_TERM="Chikungunya+virus[Organism]+AND+complete+genome[Title]"
SEARCH_URL="https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=nucleotide&term=${SEARCH_TERM}&retmax=100&usehistory=y&retmode=xml&email=${EMAIL}"

echo "Searching NCBI..."
echo "URL: $SEARCH_URL"
echo ""

# Execute search
$HTTP_TOOL "$SEARCH_URL" > "$TEMP_DIR/search.xml"

# Extract results
WEBENV=$(grep -oP '(?<=<WebEnv>)[^<]+' "$TEMP_DIR/search.xml" || echo "")
QUERYKEY=$(grep -oP '(?<=<QueryKey>)[^<]+' "$TEMP_DIR/search.xml" || echo "")
COUNT=$(grep -oP '(?<=<Count>)[^<]+' "$TEMP_DIR/search.xml" || echo "0")

echo "Found: $COUNT sequences"
echo "WebEnv: ${WEBENV:0:20}..."
echo "QueryKey: $QUERYKEY"
echo ""

if [ -z "$WEBENV" ]; then
    echo "[✗] Search failed!"
    exit 1
fi

echo "=============================================================================="
echo "Step 2: Download sequences in FASTA format"
echo "=============================================================================="
echo ""

# Build fetch URL
FETCH_URL="https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nucleotide&query_key=${QUERYKEY}&WebEnv=${WEBENV}&rettype=fasta&retmode=text&email=${EMAIL}"

echo "Downloading sequences..."
echo ""

# Download sequences
$HTTP_TOOL "$FETCH_URL" > "$TEMP_DIR/raw_sequences.fasta"

# Count downloaded sequences
SEQ_COUNT=$(grep -c "^>" "$TEMP_DIR/raw_sequences.fasta" || echo "0")
echo "Downloaded: $SEQ_COUNT sequences"
echo ""

echo "=============================================================================="
echo "Step 3: Filter sequences by region"
echo "=============================================================================="
echo ""

# Example: Extract sequences from specific countries
echo "Filtering sequences by geographic region..."
echo ""

# Create empty output
> "$OUTPUT_FILE"

# Define regions
declare -A REGIONS
REGIONS[Asia]="India|Thailand|Indonesia|Singapore|Malaysia"
REGIONS[Africa]="Kenya|Tanzania|Senegal|Uganda|Madagascar"
REGIONS[America]="Brazil|Colombia|USA|Caribbean|Venezuela"
REGIONS[Europe]="Italy|France|Spain|Greece|Netherlands"

# Extract sequences by region
for REGION in Asia Africa America Europe; do
    PATTERN="${REGIONS[$REGION]}"
    
    # Use awk to extract matching sequences
    awk -v pattern="$PATTERN" '
        BEGIN {IGNORECASE=1; in_match=0}
        /^>/ {
            if ($0 ~ pattern) {
                in_match=1
                print
            } else {
                in_match=0
            }
            next
        }
        in_match {print}
    ' "$TEMP_DIR/raw_sequences.fasta" > "$TEMP_DIR/${REGION}.fasta"
    
    COUNT=$(grep -c "^>" "$TEMP_DIR/${REGION}.fasta" 2>/dev/null || echo "0")
    echo "  $REGION: $COUNT sequences"
done

echo ""

echo "=============================================================================="
echo "Step 4: Select representative sequences (5 per region)"
echo "=============================================================================="
echo ""

# Select first 5 from each region
for REGION in Asia Africa America Europe; do
    if [ -f "$TEMP_DIR/${REGION}.fasta" ]; then
        # Extract first 5 sequences
        awk 'BEGIN{count=0} /^>/{count++} count<=5' "$TEMP_DIR/${REGION}.fasta" >> "$OUTPUT_FILE"
        
        SELECTED=$(grep -c "^>" "$OUTPUT_FILE" || echo "0")
    fi
done

TOTAL=$(grep -c "^>" "$OUTPUT_FILE" || echo "0")
echo "Selected total: $TOTAL sequences"
echo ""

echo "=============================================================================="
echo "Step 5: Format headers (optional)"
echo "=============================================================================="
echo ""

# Create formatted version
FORMATTED_FILE="${OUTPUT_FILE%.fasta}_formatted.fasta"
> "$FORMATTED_FILE"

# Format each header
while IFS= read -r line; do
    if [[ "$line" == ">"* ]]; then
        # Extract accession (first field)
        ACCESSION=$(echo "$line" | sed 's/^>//' | awk '{print $1}')
        
        # Try to extract country
        COUNTRY=$(echo "$line" | grep -oP '(?<=:)[^:,]+' | head -1 | tr ' ' '_' || echo "Unknown")
        
        # Try to extract year
        YEAR=$(echo "$line" | grep -oP '\b(19|20)\d{2}\b' | head -1 || echo "Unknown")
        
        # Format: >CHIKV_Country_Year_Accession
        echo ">CHIKV_${COUNTRY}_${YEAR}_${ACCESSION}"
    else
        echo "$line"
    fi
done < "$OUTPUT_FILE" > "$FORMATTED_FILE"

echo "Formatted headers in: $FORMATTED_FILE"
echo ""

echo "=============================================================================="
echo "Step 6: Generate summary"
echo "=============================================================================="
echo ""

SUMMARY_FILE="${OUTPUT_FILE%.fasta}_summary.txt"

cat > "$SUMMARY_FILE" << EOF
================================================================================
CHIKV Genome Collection Summary (Manual Linux Method)
Generated: $(date)
================================================================================

Total sequences: $TOTAL

Files created:
  - $OUTPUT_FILE (raw headers)
  - $FORMATTED_FILE (formatted headers)

Sequence list:
EOF

grep "^>" "$FORMATTED_FILE" | sed 's/^>//' | nl -w3 -s'. ' >> "$SUMMARY_FILE"

echo "Summary saved to: $SUMMARY_FILE"
echo ""

echo "=============================================================================="
echo "✓ Collection Complete!"
echo "=============================================================================="
echo ""
echo "Output files:"
echo "  • $OUTPUT_FILE"
echo "  • $FORMATTED_FILE"
echo "  • $SUMMARY_FILE"
echo ""
echo "Next steps:"
echo "  1. Review sequences: less $FORMATTED_FILE"
echo "  2. Add your genome: cat your_genome.fasta >> $FORMATTED_FILE"
echo "  3. Align sequences: mafft $FORMATTED_FILE > aligned.fasta"
echo "  4. Build tree: iqtree -s aligned.fasta"
echo ""

echo "=============================================================================="
echo "Manual Commands Reference"
echo "=============================================================================="
echo ""
echo "You can also run these commands manually:"
echo ""
echo "# Search NCBI"
echo "curl \"$SEARCH_URL\" > search.xml"
echo ""
echo "# Download sequences"
echo "curl \"$FETCH_URL\" > sequences.fasta"
echo ""
echo "# Count sequences"
echo "grep -c '^>' sequences.fasta"
echo ""
echo "# Filter by country (example: India)"
echo "awk '/^>/ && /India/ {found=1} /^>/ && !/India/ {found=0} found' sequences.fasta"
echo ""
echo "# Extract first 10 sequences"
echo "awk 'BEGIN{count=0} /^>/{count++} count<=10' sequences.fasta"
echo ""
echo "=============================================================================="
