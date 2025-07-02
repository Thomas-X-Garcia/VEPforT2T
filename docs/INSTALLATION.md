# Detailed Installation Guide for VEPforT2T

This guide provides comprehensive instructions for manually installing and configuring VEPforT2T.

## Table of Contents

1. [System Requirements](#system-requirements)
2. [Installing Dependencies](#installing-dependencies)
3. [Installing Ensembl VEP](#installing-ensembl-vep)
4. [Setting up T2T Cache](#setting-up-t2t-cache)
5. [Installing BCFtools Liftover Plugin](#installing-bcftools-liftover-plugin)
6. [Creating T2T-Compatible SV Reference](#creating-t2t-compatible-sv-reference)
7. [Verification](#verification)
8. [Troubleshooting](#troubleshooting)

## System Requirements

- **Operating System**: Linux (Ubuntu 20.04+ or CentOS 7+)
- **Memory**: Minimum 8GB RAM, 16GB+ recommended
- **Storage**: At least 50GB free disk space
- **Software**: 
  - Miniconda or Anaconda
  - gcc/g++ compiler
  - make
  - wget
  - git

## Installing Dependencies

### 1. Install Miniconda (if not already installed)

```bash
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh
# Follow the prompts and restart your terminal
```

### 2. Create VEP Conda Environment

```bash
conda create -n vep python=3.9
conda activate vep
```

### 3. Install Required Packages

```bash
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
    tabix
```

## Installing Ensembl VEP

### 1. Download VEP

```bash
cd $HOME
wget https://github.com/Ensembl/ensembl-vep/archive/release/114.1.tar.gz
tar -xzf 114.1.tar.gz
mv ensembl-vep-114.1 ensembl-vep
rm 114.1.tar.gz
```

### 2. Install VEP

```bash
cd ensembl-vep
perl INSTALL.pl --AUTO a --NO_UPDATE
```

Note: If you see a warning about DBD::mysql, it's safe to continue for offline use.

### 3. Install Required Plugins

```bash
cd $HOME/.vep/Plugins
wget https://raw.githubusercontent.com/Ensembl/VEP_plugins/release/114/StructuralVariantOverlap.pm
```

## Setting up T2T Cache

The T2T-CHM13v2.0 cache is essential for proper annotation.

### Option 1: Download Pre-built Cache

```bash
cd $HOME/.vep
# Download the T2T cache (replace with actual URL)
wget [T2T_CACHE_URL]/homo_sapiens_gca009914755v4_107.tar.gz
tar -xzf homo_sapiens_gca009914755v4_107.tar.gz
```

### Option 2: Manual Cache Setup

If pre-built cache is not available:

```bash
mkdir -p $HOME/.vep/homo_sapiens_gca009914755v4/107_T2T-CHM13v2.0
# The cache needs to be populated with T2T-specific data
# Contact the T2T consortium for cache files
```

### Cache Directory Structure

The final structure should be:
```
$HOME/.vep/homo_sapiens_gca009914755v4/107_T2T-CHM13v2.0/
├── 1/
│   ├── 1-1000000.gz
│   ├── 1000001-2000000.gz
│   └── ...
├── 2/
├── ...
├── X/
├── Y/
├── MT/
├── info.txt
└── chr_synonyms.txt
```

## Installing BCFtools Liftover Plugin

This plugin is required to create T2T-compatible SV reference files.

### 1. Clone the Plugin Repository

```bash
cd $HOME/reference_data
git clone https://github.com/freeseek/score.git
```

### 2. Download BCFtools Source

```bash
wget https://github.com/samtools/bcftools/releases/download/1.21/bcftools-1.21.tar.bz2
tar -xjf bcftools-1.21.tar.bz2
cd bcftools-1.21
```

### 3. Copy Plugin Files

```bash
cp ../score/*.c plugins/
cp ../score/*.h plugins/
```

### 4. Handle Compilation Issues

```bash
# Remove problematic plugin
rm -f plugins/pgs.c

# Configure without optional compressions
./configure --prefix=$CONDA_PREFIX --disable-bz2 --disable-lzma
```

### 5. Compile and Install

```bash
make
mkdir -p $HOME/reference_data/bcftools_plugins
cp plugins/*.so $HOME/reference_data/bcftools_plugins/
```

### 6. Set Environment Variable

```bash
export BCFTOOLS_PLUGINS=$HOME/reference_data/bcftools_plugins
# Add to .bashrc for persistence
echo 'export BCFTOOLS_PLUGINS=$HOME/reference_data/bcftools_plugins' >> ~/.bashrc
```

## Creating T2T-Compatible SV Reference

### 1. Download Required Files

```bash
cd $HOME/reference_data

# Chain file
wget https://hgwdev.gi.ucsc.edu/~markd/t2t/CHM13-fixed-chains/hg38-chm13v2.over.chain.gz

# GRCh38 reference
wget https://hgdownload.soe.ucsc.edu/goldenPath/hg38/bigZips/hg38.fa.gz
gunzip hg38.fa.gz

# T2T reference (if not already present)
wget https://s3-us-west-2.amazonaws.com/human-pangenomics/T2T/CHM13/assemblies/analysis_set/chm13v2.0.fa.gz
gunzip chm13v2.0.fa.gz
mv chm13v2.0.fa $HOME/

# gnomAD SV data
wget https://storage.googleapis.com/gcp-public-data--gnomad/papers/2019-sv/gnomad_v2.1_sv.sites.vcf.gz
wget https://storage.googleapis.com/gcp-public-data--gnomad/papers/2019-sv/gnomad_v2.1_sv.sites.vcf.gz.tbi
```

### 2. Perform Liftover

```bash
bcftools +liftover gnomad_v2.1_sv.sites.vcf.gz -Oz -o gnomad_v2.1_sv.sites.T2T.vcf.gz -- \
    -s hg38.fa \
    -f $HOME/chm13v2.0.fa \
    -c hg38-chm13v2.over.chain.gz
```

### 3. Sort and Index

```bash
bcftools sort gnomad_v2.1_sv.sites.T2T.vcf.gz -Oz -o gnomad_v2.1_sv.sites.T2T.sorted.vcf.gz
tabix -p vcf gnomad_v2.1_sv.sites.T2T.sorted.vcf.gz
rm gnomad_v2.1_sv.sites.T2T.vcf.gz
```

## Verification

### 1. Test VEP Installation

```bash
conda activate vep
perl $HOME/ensembl-vep/vep --help
```

### 2. Check Cache

```bash
ls $HOME/.vep/homo_sapiens_gca009914755v4/107_T2T-CHM13v2.0/
```

### 3. Verify BCFtools Plugin

```bash
export BCFTOOLS_PLUGINS=$HOME/reference_data/bcftools_plugins
bcftools plugin -l | grep liftover
```

### 4. Test Complete Pipeline

```bash
# Create a test VCF
cat > test.vcf << EOF
##fileformat=VCFv4.2
##contig=<ID=chr1,length=248387328>
#CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO
chr1	10000	.	A	G	100	PASS	.
EOF

bgzip test.vcf
tabix -p vcf test.vcf.gz

# Run VEP
bash $HOME/VEPforT2T/scripts/run_vep_t2t.sh test.vcf.gz
```

## Troubleshooting

### Common Issues and Solutions

1. **Missing perl modules**
   ```bash
   # Install missing module
   conda install -c bioconda perl-module-name
   ```

2. **Cache not found error**
   - Verify cache directory exists
   - Check species name: `homo_sapiens_gca009914755v4`
   - Check version: `107`

3. **BCFtools plugin not found**
   - Ensure BCFTOOLS_PLUGINS is set correctly
   - Verify .so files exist in plugin directory

4. **Liftover failures**
   - Expected: ~2% variants will fail liftover
   - Check chain file is correct version
   - Ensure reference sequences match

### Getting Help

- GitHub Issues: https://github.com/Thomas-X-Garcia/VEPforT2T/issues
- VEP Documentation: https://www.ensembl.org/info/docs/tools/vep/
- T2T Consortium: https://github.com/marbl/CHM13