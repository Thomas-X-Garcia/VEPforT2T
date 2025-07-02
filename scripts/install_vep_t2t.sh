#!/bin/bash
# VEPforT2T - Installation script
# Installs and configures Ensembl VEP for T2T-CHM13v2.0
# Author: Thomas X. Garcia, PhD, HCLD

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")/config"
LOG_FILE="$HOME/VEPforT2T/logs/installation_$(date +%Y%m%d_%H%M%S).log"

# Create log directory
mkdir -p "$(dirname "$LOG_FILE")"

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log "Starting VEPforT2T installation..."

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check for conda
    if ! command -v conda &> /dev/null; then
        log "ERROR: Conda not found. Please install Miniconda or Anaconda first."
        log "Visit: https://docs.conda.io/en/latest/miniconda.html"
        exit 1
    fi
    
    # Check for wget
    if ! command -v wget &> /dev/null; then
        log "ERROR: wget not found. Please install wget."
        exit 1
    fi
    
    # Check disk space (need at least 50GB)
    available_space=$(df -BG "$HOME" | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ "$available_space" -lt 50 ]; then
        log "WARNING: Less than 50GB free space available. Installation may fail."
        read -p "Continue anyway? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    log "Prerequisites check completed."
}

# Install VEP and dependencies
install_vep() {
    log "Installing VEP and dependencies..."
    
    # Create conda environment
    if conda env list | grep -q "^vep "; then
        log "VEP environment already exists."
        read -p "Update existing environment? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            conda env remove -n vep -y
        else
            log "Using existing VEP environment."
            return
        fi
    fi
    
    log "Creating VEP conda environment..."
    conda create -n vep python=3.9 -y
    
    # Activate environment and install dependencies
    source ~/miniconda3/etc/profile.d/conda.sh
    conda activate vep
    
    log "Installing Perl dependencies..."
    conda install -c bioconda -c conda-forge \
        perl-bio-db-hts \
        perl-dbi \
        perl-json \
        perl-set-intervaltree \
        perl-perlio-gzip \
        perl-dbd-mysql \
        htslib \
        samtools \
        bcftools \
        tabix \
        -y
    
    # Download and install VEP
    log "Downloading VEP..."
    cd "$HOME"
    if [ ! -d "ensembl-vep" ]; then
        wget https://github.com/Ensembl/ensembl-vep/archive/release/114.1.tar.gz
        tar -xzf 114.1.tar.gz
        mv ensembl-vep-114.1 ensembl-vep
        rm 114.1.tar.gz
    fi
    
    cd ensembl-vep
    log "Installing VEP..."
    perl INSTALL.pl --AUTO a --NO_UPDATE
    
    # Install plugins
    log "Installing VEP plugins..."
    cd $HOME/.vep/Plugins
    wget https://raw.githubusercontent.com/Ensembl/VEP_plugins/release/114/StructuralVariantOverlap.pm
    
    log "VEP installation completed."
}

# Download T2T cache
download_t2t_cache() {
    log "Downloading T2T-CHM13v2.0 cache..."
    
    CACHE_DIR="$HOME/.vep/homo_sapiens_gca009914755v4"
    
    if [ -d "$CACHE_DIR/107_T2T-CHM13v2.0" ]; then
        log "T2T cache already exists."
        read -p "Re-download cache? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return
        fi
        rm -rf "$CACHE_DIR"
    fi
    
    mkdir -p "$HOME/.vep"
    cd "$HOME/.vep"
    
    log "Note: T2T cache download is large (~15-20GB) and may take time."
    log "Downloading from AWS S3..."
    
    # Download T2T cache (URL to be updated with actual location)
    # For now, provide instructions
    cat << EOF | tee -a "$LOG_FILE"
    
Manual cache download required:
1. Download the T2T cache from the T2T consortium or Ensembl
2. Extract to: $HOME/.vep/homo_sapiens_gca009914755v4/

The cache directory structure should be:
$HOME/.vep/homo_sapiens_gca009914755v4/107_T2T-CHM13v2.0/
├── 1/
├── 2/
├── ...
├── X/
├── Y/
├── MT/
├── info.txt
└── chr_synonyms.txt

EOF
    
    log "T2T cache setup instructions provided."
}

# Download reference files
download_reference_files() {
    log "Setting up reference files..."
    
    mkdir -p "$HOME/T2T-CHM13v2.0"
    mkdir -p "$HOME/reference_data"
    
    # T2T reference genome
    if [ ! -f "$HOME/chm13v2.0.fa" ]; then
        log "Downloading T2T-CHM13v2.0 reference genome..."
        cd "$HOME"
        wget https://s3-us-west-2.amazonaws.com/human-pangenomics/T2T/CHM13/assemblies/analysis_set/chm13v2.0.fa.gz
        gunzip chm13v2.0.fa.gz
        samtools faidx chm13v2.0.fa
    else
        log "T2T reference genome already exists."
    fi
    
    # RefSeq GFF3
    if [ ! -f "$HOME/T2T-CHM13v2.0/chm13v2.0_RefSeq_Liftoff_v5.2.sorted.gff3.gz" ]; then
        log "Downloading RefSeq GFF3 annotations..."
        cd "$HOME/T2T-CHM13v2.0"
        # Download GFF3 (URL to be updated with actual location)
        log "Please download the RefSeq GFF3 file manually from the T2T consortium."
    else
        log "RefSeq GFF3 already exists."
    fi
    
    log "Reference files setup completed."
}

# Setup BCFtools liftover plugin
setup_bcftools_liftover() {
    log "Setting up BCFtools liftover plugin..."
    
    source ~/miniconda3/etc/profile.d/conda.sh
    conda activate vep
    
    cd "$HOME/reference_data"
    
    # Check if plugin already exists
    if [ -f "$HOME/reference_data/bcftools_plugins/liftover.so" ]; then
        log "BCFtools liftover plugin already installed."
        return
    fi
    
    # Clone score repository
    if [ ! -d "score" ]; then
        log "Cloning liftover plugin repository..."
        git clone https://github.com/freeseek/score.git
    fi
    
    # Download and compile BCFtools
    if [ ! -d "bcftools-1.21" ]; then
        log "Downloading BCFtools source..."
        wget https://github.com/samtools/bcftools/releases/download/1.21/bcftools-1.21.tar.bz2
        tar -xjf bcftools-1.21.tar.bz2
    fi
    
    cd bcftools-1.21
    
    # Copy plugin files
    cp ../score/*.c plugins/
    cp ../score/*.h plugins/
    
    # Remove problematic plugin
    rm -f plugins/pgs.c
    
    # Configure and compile
    log "Compiling BCFtools with liftover plugin..."
    ./configure --prefix=$CONDA_PREFIX --disable-bz2 --disable-lzma
    make
    
    # Setup plugins
    mkdir -p "$HOME/reference_data/bcftools_plugins"
    cp plugins/*.so "$HOME/reference_data/bcftools_plugins/"
    
    log "BCFtools liftover plugin installed."
}

# Create lifted gnomAD SV file
create_lifted_sv_file() {
    log "Setting up lifted gnomAD SV file..."
    
    cd "$HOME/reference_data"
    
    # Check if already exists
    if [ -f "gnomad_v2.1_sv.sites.T2T.sorted.vcf.gz" ]; then
        log "Lifted gnomAD SV file already exists."
        return
    fi
    
    # Download required files
    log "Downloading required files for liftover..."
    
    # Chain file
    if [ ! -f "hg38-chm13v2.over.chain.gz" ]; then
        wget https://hgwdev.gi.ucsc.edu/~markd/t2t/CHM13-fixed-chains/hg38-chm13v2.over.chain.gz
    fi
    
    # GRCh38 reference
    if [ ! -f "hg38.fa" ]; then
        log "Downloading GRCh38 reference..."
        wget https://hgdownload.soe.ucsc.edu/goldenPath/hg38/bigZips/hg38.fa.gz
        gunzip hg38.fa.gz
    fi
    
    # gnomAD SV
    if [ ! -f "gnomad_v2.1_sv.sites.vcf.gz" ]; then
        log "Downloading gnomAD SV data..."
        wget https://storage.googleapis.com/gcp-public-data--gnomad/papers/2019-sv/gnomad_v2.1_sv.sites.vcf.gz
        wget https://storage.googleapis.com/gcp-public-data--gnomad/papers/2019-sv/gnomad_v2.1_sv.sites.vcf.gz.tbi
    fi
    
    # Perform liftover
    log "Performing liftover to T2T coordinates..."
    export BCFTOOLS_PLUGINS="$HOME/reference_data/bcftools_plugins"
    
    bcftools +liftover gnomad_v2.1_sv.sites.vcf.gz -Oz -o gnomad_v2.1_sv.sites.T2T.vcf.gz -- \
        -s hg38.fa \
        -f "$HOME/chm13v2.0.fa" \
        -c hg38-chm13v2.over.chain.gz
    
    # Sort and index
    log "Sorting and indexing lifted file..."
    bcftools sort gnomad_v2.1_sv.sites.T2T.vcf.gz -Oz -o gnomad_v2.1_sv.sites.T2T.sorted.vcf.gz
    tabix -p vcf gnomad_v2.1_sv.sites.T2T.sorted.vcf.gz
    
    # Clean up
    rm gnomad_v2.1_sv.sites.T2T.vcf.gz
    
    log "Lifted gnomAD SV file created successfully."
}

# Main installation
main() {
    log "==========================================="
    log "VEPforT2T Installation"
    log "==========================================="
    
    check_prerequisites
    install_vep
    download_t2t_cache
    download_reference_files
    setup_bcftools_liftover
    create_lifted_sv_file
    
    # Create test data
    log "Creating test data..."
    mkdir -p "$HOME/VEPforT2T/examples"
    
    # Verify installation
    log "Verifying installation..."
    source ~/miniconda3/etc/profile.d/conda.sh
    conda activate vep
    
    if perl "$HOME/ensembl-vep/vep" --help &> /dev/null; then
        log "VEP installation verified."
    else
        log "ERROR: VEP installation verification failed."
        exit 1
    fi
    
    log "==========================================="
    log "Installation completed successfully!"
    log "==========================================="
    log ""
    log "Next steps:"
    log "1. Activate the VEP environment: conda activate vep"
    log "2. Run VEP on your T2T VCF files:"
    log "   bash $SCRIPT_DIR/run_vep_t2t.sh your_file.vcf.gz"
    log ""
    log "Installation log: $LOG_FILE"
}

# Run main installation
main "$@"