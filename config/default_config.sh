#!/bin/bash
# VEPforT2T - Default configuration
# Author: Thomas X. Garcia, PhD, HCLD

# VEP installation path
VEP_PATH="${VEP_PATH:-/home/$USER/ensembl-vep}"

# Cache configuration
VEP_CACHE_DIR="${VEP_CACHE_DIR:-$HOME/.vep}"
T2T_SPECIES="homo_sapiens_gca009914755v4"
T2T_ASSEMBLY="T2T-CHM13v2.0"
T2T_CACHE_VERSION="107"

# Reference files
T2T_REFERENCE="${T2T_REFERENCE:-/home/$USER/chm13v2.0.fa}"
T2T_GFF3="${T2T_GFF3:-/home/$USER/T2T-CHM13v2.0/chm13v2.0_RefSeq_Liftoff_v5.2.sorted.gff3.gz}"

# Structural variant reference files
T2T_SV_FILE="${T2T_SV_FILE:-/home/$USER/reference_data/T2T-CHM13v2.0_SVs.vcf.gz}"
GNOMAD_T2T_SV_FILE="${GNOMAD_T2T_SV_FILE:-/home/$USER/reference_data/gnomad_v2.1_sv.sites.T2T.sorted.vcf.gz}"

# BCFtools plugin directory
export BCFTOOLS_PLUGINS="${BCFTOOLS_PLUGINS:-$HOME/reference_data/bcftools_plugins}"

# Default VEP parameters
DEFAULT_BUFFER_SIZE=20000
DEFAULT_THREADS=32
DEFAULT_MAX_SV_SIZE=1000000000

# Logging
LOG_DIR="${LOG_DIR:-$HOME/VEPforT2T/logs}"
mkdir -p "$LOG_DIR"