#!/bin/bash
# VEPforT2T - Batch processing script
# Process multiple VCF files in a directory
# Author: Thomas X. Garcia, PhD, HCLD

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

usage() {
    cat << EOF
Usage: $(basename "$0") <input_directory> [options]

Process multiple VCF files with VEPforT2T

Required:
    input_directory       Directory containing .vcf.gz files

Options:
    --output-dir DIR      Output directory (default: same as input)
    --pattern PATTERN     File pattern (default: "*.vcf.gz")
    --threads N           Threads per job (default: 8)
    --parallel N          Number of parallel jobs (default: 4)
    --dry-run             Show what would be processed without running
    --help                Show this help message

Example:
    $(basename "$0") /data/vcf_files/ --parallel 8 --threads 4

EOF
    exit 1
}

# Parse arguments
INPUT_DIR=""
OUTPUT_DIR=""
PATTERN="*.vcf.gz"
THREADS=8
PARALLEL=4
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --pattern)
            PATTERN="$2"
            shift 2
            ;;
        --threads)
            THREADS="$2"
            shift 2
            ;;
        --parallel)
            PARALLEL="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
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
            if [ -z "$INPUT_DIR" ]; then
                INPUT_DIR="$1"
            else
                echo "Error: Multiple input directories specified"
                usage
            fi
            shift
            ;;
    esac
done

# Validate input
if [ -z "$INPUT_DIR" ]; then
    echo "Error: No input directory specified"
    usage
fi

if [ ! -d "$INPUT_DIR" ]; then
    echo "Error: Input directory not found: $INPUT_DIR"
    exit 1
fi

# Set output directory
if [ -z "$OUTPUT_DIR" ]; then
    OUTPUT_DIR="$INPUT_DIR"
fi

# Find VCF files
VCF_FILES=()
while IFS= read -r -d '' file; do
    VCF_FILES+=("$file")
done < <(find "$INPUT_DIR" -maxdepth 1 -name "$PATTERN" -type f -print0 | sort -z)

if [ ${#VCF_FILES[@]} -eq 0 ]; then
    echo "No VCF files found matching pattern: $PATTERN"
    exit 1
fi

echo "Found ${#VCF_FILES[@]} VCF files to process"
echo "Output directory: $OUTPUT_DIR"
echo "Parallel jobs: $PARALLEL"
echo "Threads per job: $THREADS"

if [ "$DRY_RUN" = true ]; then
    echo -e "\nDry run - files that would be processed:"
    printf '%s\n' "${VCF_FILES[@]}"
    exit 0
fi

# Create job file
JOB_FILE=$(mktemp)
for vcf in "${VCF_FILES[@]}"; do
    echo "$SCRIPT_DIR/run_vep_t2t.sh \"$vcf\" --output-dir \"$OUTPUT_DIR\" --threads $THREADS" >> "$JOB_FILE"
done

# Run jobs in parallel
echo -e "\nStarting batch processing..."
echo "Progress will be shown below:"

if command -v parallel &> /dev/null; then
    # Use GNU parallel if available
    parallel -j "$PARALLEL" --progress --joblog "${OUTPUT_DIR}/vep_batch.log" < "$JOB_FILE"
else
    # Fallback to xargs
    cat "$JOB_FILE" | xargs -P "$PARALLEL" -I {} bash -c '{}'
fi

# Clean up
rm -f "$JOB_FILE"

# Summary
echo -e "\nBatch processing complete!"
echo "Check individual log files for details."

# Count successful completions
SUCCESS_COUNT=$(find "$OUTPUT_DIR" -name "*_vep_t2t_only.txt" -newer "$0" | wc -l)
echo "Successfully processed: $SUCCESS_COUNT/${#VCF_FILES[@]} files"