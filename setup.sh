#!/bin/bash
#
# Setup script for Viral Genome Analysis Pipeline
# This script sets up the environment and verifies all dependencies

set -e

echo "================================================"
echo "Viral Genome Analysis Pipeline - Setup"
echo "================================================"
echo ""

# Check Python version
echo "Checking Python installation..."
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
    echo "✓ Python 3 found: $PYTHON_VERSION"
else
    echo "✗ Python 3 is not installed"
    echo "Please install Python 3.6 or higher"
    exit 1
fi

# Check pip
echo ""
echo "Checking pip installation..."
if command -v pip3 &> /dev/null || command -v pip &> /dev/null; then
    echo "✓ pip found"
else
    echo "✗ pip is not installed"
    echo "Please install pip"
    exit 1
fi

# Install dependencies
echo ""
echo "Installing Python dependencies..."
pip3 install -r requirements.txt || pip install -r requirements.txt
echo "✓ Dependencies installed"

# Create directory structure
echo ""
echo "Creating directory structure..."
mkdir -p data/chikungunya
mkdir -p data/zika
mkdir -p results/chikungunya
mkdir -p results/zika
echo "✓ Directories created"

# Make scripts executable
echo ""
echo "Setting file permissions..."
chmod +x run_analysis.sh
chmod +x setup.sh
echo "✓ Permissions set"

# Verify scripts
echo ""
echo "Verifying scripts..."
python3 -c "from Bio import SeqIO; print('✓ Biopython is working')"
python3 consensus_generation.py --help > /dev/null 2>&1 && echo "✓ consensus_generation.py is working"
python3 variant_calling.py --help > /dev/null 2>&1 && echo "✓ variant_calling.py is working"

echo ""
echo "================================================"
echo "Setup Complete!"
echo "================================================"
echo ""
echo "Next steps:"
echo "1. Place your genome FASTA files in:"
echo "   - data/chikungunya/  (for Chikungunya genomes)"
echo "   - data/zika/         (for Zika genome)"
echo ""
echo "2. Run the analysis:"
echo "   ./run_analysis.sh"
echo ""
echo "3. Check results in:"
echo "   - results/chikungunya/"
echo "   - results/zika/"
echo ""
echo "For detailed usage, see USAGE_GUIDE.md"
echo ""
