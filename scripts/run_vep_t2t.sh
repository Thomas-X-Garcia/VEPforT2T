#!/bin/bash
# VEPforT2T - Main execution script
# Runs Ensembl VEP on T2T-CHM13v2.0 reference genome
# Author: Thomas X. Garcia, PhD, HCLD
# Version: 1.0.0

set -euo pipefail

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")/config"

# Default configuration
source "$CONFIG_DIR/default_config.sh"

# Function to display usage
usage() {
    cat << EOF
Usage: $(basename "$0") <input.vcf.gz> [options]

Run Ensembl VEP on T2T-CHM13v2.0 reference genome

Required:
    input.vcf.gz          Input VCF file (must be bgzip compressed)

Options:
    --output-dir DIR      Output directory (default: same as input)
    --threads N           Number of threads (default: 32)
    --buffer-size N       VEP buffer size (default: 20000)
    --vep-options "OPTS"  Additional VEP options
    --no-sv               Skip StructuralVariantOverlap plugin
    --help                Show this help message

Examples:
    # Basic usage
    $(basename "$0") sample.vcf.gz

    # Custom output directory
    $(basename "$0") sample.vcf.gz --output-dir /results/

    # With additional VEP options
    $(basename "$0") sample.vcf.gz --vep-options "--sift b --polyphen b"

EOF
    exit 1
}

# Parse command line arguments
INPUT_VCF=""
OUTPUT_DIR=""
THREADS=32
BUFFER_SIZE=20000
VEP_EXTRA_OPTIONS=""
USE_SV_PLUGIN=true

while [[ $# -gt 0 ]]; do
    case $1 in
        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --threads)
            THREADS="$2"
            shift 2
            ;;
        --buffer-size)
            BUFFER_SIZE="$2"
            shift 2
            ;;
        --vep-options)
            VEP_EXTRA_OPTIONS="$2"
            shift 2
            ;;
        --no-sv)
            USE_SV_PLUGIN=false
            shift
            ;;
        --help|-h)
            usage
            ;;
        -*)
            echo "Error: Unknown option $1"
            usage
            ;;
        *)
            if [ -z "$INPUT_VCF" ]; then
                INPUT_VCF="$1"
            else
                echo "Error: Multiple input files specified"
                usage
            fi
            shift
            ;;
    esac
done

# Validate input
if [ -z "$INPUT_VCF" ]; then
    echo "Error: No input VCF file specified"
    usage
fi

if [ ! -f "$INPUT_VCF" ]; then
    echo "Error: Input file not found: $INPUT_VCF"
    exit 1
fi

# Set output directory if not specified
if [ -z "$OUTPUT_DIR" ]; then
    OUTPUT_DIR=$(dirname "$INPUT_VCF")
fi

# Create output directory if needed
mkdir -p "$OUTPUT_DIR"

# Set output file name
OUTPUT_PREFIX="$OUTPUT_DIR/$(basename "$INPUT_VCF" .vcf.gz)"
OUTPUT_FILE="${OUTPUT_PREFIX}_vep_t2t_only.txt"
LOG_FILE="${OUTPUT_PREFIX}_vep_t2t.log"

# Activate conda environment
echo "Activating VEP environment..."
source ~/miniconda3/etc/profile.d/conda.sh
conda activate vep

# Check for required files
echo "Checking required files..."
check_required_files() {
    local missing=0
    
    if [ ! -f "$T2T_REFERENCE" ]; then
        echo "ERROR: T2T reference not found: $T2T_REFERENCE"
        missing=1
    fi
    
    if [ ! -f "$T2T_GFF3" ]; then
        echo "ERROR: T2T GFF3 not found: $T2T_GFF3"
        missing=1
    fi
    
    if [ ! -d "$VEP_CACHE_DIR/$T2T_SPECIES/$T2T_CACHE_VERSION" ]; then
        echo "ERROR: T2T cache not found: $VEP_CACHE_DIR/$T2T_SPECIES/$T2T_CACHE_VERSION"
        echo "Please run the installation script first."
        missing=1
    fi
    
    return $missing
}

if ! check_required_files; then
    exit 1
fi

# Check for SV reference file
SV_PLUGIN_OPTIONS=""
if [ "$USE_SV_PLUGIN" = true ]; then
    if [ -f "$T2T_SV_FILE" ]; then
        echo "Using T2T-specific SV file: $T2T_SV_FILE"
        SV_PLUGIN_OPTIONS="--plugin StructuralVariantOverlap,file=$T2T_SV_FILE,percentage=80,cols=AF:AC:AN,same_type=1,label=T2T_SV"
    elif [ -f "$GNOMAD_T2T_SV_FILE" ]; then
        echo "Using lifted gnomAD SV file: $GNOMAD_T2T_SV_FILE"
        SV_PLUGIN_OPTIONS="--plugin StructuralVariantOverlap,file=$GNOMAD_T2T_SV_FILE,percentage=80,cols=AF:AC:AN,same_type=1,label=gnomAD_SV"
    else
        echo "WARNING: No T2T-compatible SV reference file found."
        echo "StructuralVariantOverlap plugin will be disabled."
        echo "See documentation for setup instructions."
        USE_SV_PLUGIN=false
    fi
fi

# Display configuration
echo "==========================================="
echo "VEPforT2T - Configuration"
echo "==========================================="
echo "Input VCF: $INPUT_VCF"
echo "Output file: $OUTPUT_FILE"
echo "Log file: $LOG_FILE"
echo "Reference: $T2T_REFERENCE"
echo "GFF3: $T2T_GFF3"
echo "Cache: $VEP_CACHE_DIR/$T2T_SPECIES/$T2T_CACHE_VERSION"
echo "Threads: $THREADS"
echo "Buffer size: $BUFFER_SIZE"
echo "SV plugin: $([ "$USE_SV_PLUGIN" = true ] && echo "Enabled" || echo "Disabled")"
echo "==========================================="

# Run VEP
echo "Running VEP (this may take a while)..."
echo "Start time: $(date)"

{
    perl "$VEP_PATH/vep" \
        --input_file "$INPUT_VCF" \
        --output_file "$OUTPUT_FILE" \
        --fasta "$T2T_REFERENCE" \
        --gff "$T2T_GFF3" \
        --format vcf \
        --offline \
        --tab \
        --buffer_size "$BUFFER_SIZE" \
        --overlaps \
        --check_existing \
        --verbose \
        --max_sv_size 1000000000 \
        --biotype \
        --canonical \
        --force_overwrite \
        --symbol \
        --fork "$THREADS" \
        --dir_cache "$VEP_CACHE_DIR" \
        --cache_version "$T2T_CACHE_VERSION" \
        --species "$T2T_SPECIES" \
        --assembly "$T2T_ASSEMBLY" \
        $SV_PLUGIN_OPTIONS \
        $VEP_EXTRA_OPTIONS
} 2>&1 | tee "$LOG_FILE"

# Check if VEP completed successfully
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo "==========================================="
    echo "VEP completed successfully!"
    echo "End time: $(date)"
    echo "Output file: $OUTPUT_FILE"
    echo "Log file: $LOG_FILE"
    
    # Generate summary statistics
    echo ""
    echo "Summary statistics:"
    echo -n "Total variants processed: "
    grep -v "^#" "$OUTPUT_FILE" | wc -l
    
    echo -n "Variants with T2T-specific genes (ENSG05220*): "
    grep -v "^#" "$OUTPUT_FILE" | grep -c "ENSG05220" || echo "0"
    
    echo "==========================================="
else
    echo "ERROR: VEP failed. Check the log file: $LOG_FILE"
    exit 1
fi