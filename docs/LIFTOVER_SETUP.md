# BCFtools Liftover Setup Guide

This guide provides detailed instructions for setting up BCFtools with the liftover plugin to create T2T-compatible reference files.

## Overview

The BCFtools liftover plugin is essential for converting genomic coordinates from GRCh38 to T2T-CHM13v2.0. This is particularly important for structural variant reference files like gnomAD SV.

## Prerequisites

- Conda environment with BCFtools installed
- GCC compiler
- ~10GB free disk space for reference files

## Step-by-Step Installation

### 1. Activate VEP Environment

```bash
conda activate vep
```

### 2. Install BCFtools (if not already installed)

```bash
conda install -c bioconda bcftools
```

Verify installation:
```bash
bcftools --version
# Should show version 1.20 or higher
```

### 3. Clone the Liftover Plugin Repository

```bash
cd ~/reference_data
git clone https://github.com/freeseek/score.git
```

### 4. Download BCFtools Source Code

The plugin must be compiled with BCFtools source. Ensure the version matches your installed BCFtools:

```bash
# Check your BCFtools version
bcftools --version

# Download matching version (example for 1.21)
wget https://github.com/samtools/bcftools/releases/download/1.21/bcftools-1.21.tar.bz2
tar -xjf bcftools-1.21.tar.bz2
cd bcftools-1.21
```

### 5. Copy Plugin Files

```bash
# Copy all plugin source files
cp ~/reference_data/score/*.c plugins/
cp ~/reference_data/score/*.h plugins/
```

### 6. Configure Build Environment

Some plugins require additional libraries that may not be available. Configure without them:

```bash
./configure --prefix=$CONDA_PREFIX --disable-bz2 --disable-lzma
```

### 7. Handle Compilation Issues

If compilation fails due to the pgs plugin:

```bash
# Remove the problematic plugin
rm -f plugins/pgs.c
```

### 8. Compile BCFtools

```bash
make
```

### 9. Install Plugins

```bash
# Create plugin directory
mkdir -p ~/reference_data/bcftools_plugins

# Copy compiled plugins
cp plugins/*.so ~/reference_data/bcftools_plugins/

# Verify liftover plugin was created
ls ~/reference_data/bcftools_plugins/liftover.so
```

### 10. Set Environment Variable

```bash
# Set for current session
export BCFTOOLS_PLUGINS=~/reference_data/bcftools_plugins

# Add to .bashrc for persistence
echo 'export BCFTOOLS_PLUGINS=~/reference_data/bcftools_plugins' >> ~/.bashrc
```

### 11. Verify Installation

```bash
# List available plugins
bcftools plugin -l

# Should include 'liftover' in the list
```

## Using the Liftover Plugin

### Required Files

1. **Chain file**: Maps coordinates between assemblies
2. **Source reference**: GRCh38/hg38 FASTA
3. **Target reference**: T2T-CHM13v2.0 FASTA
4. **Input VCF**: File to convert

### Download Required Files

```bash
cd ~/reference_data

# Chain file (GRCh38 to T2T)
wget https://hgwdev.gi.ucsc.edu/~markd/t2t/CHM13-fixed-chains/hg38-chm13v2.over.chain.gz

# GRCh38 reference
wget https://hgdownload.soe.ucsc.edu/goldenPath/hg38/bigZips/hg38.fa.gz
gunzip hg38.fa.gz

# T2T reference (if not already available)
wget https://s3-us-west-2.amazonaws.com/human-pangenomics/T2T/CHM13/assemblies/analysis_set/chm13v2.0.fa.gz
gunzip chm13v2.0.fa.gz
```

### Basic Liftover Command

```bash
bcftools +liftover input.vcf.gz -Oz -o output.vcf.gz -- \
    -s source_ref.fa \
    -f target_ref.fa \
    -c chain_file.chain.gz
```

### Example: Lifting gnomAD SV to T2T

```bash
# Download gnomAD SV
wget https://storage.googleapis.com/gcp-public-data--gnomad/papers/2019-sv/gnomad_v2.1_sv.sites.vcf.gz
wget https://storage.googleapis.com/gcp-public-data--gnomad/papers/2019-sv/gnomad_v2.1_sv.sites.vcf.gz.tbi

# Perform liftover
bcftools +liftover gnomad_v2.1_sv.sites.vcf.gz -Oz -o gnomad_v2.1_sv.sites.T2T.vcf.gz -- \
    -s hg38.fa \
    -f ~/chm13v2.0.fa \
    -c hg38-chm13v2.over.chain.gz

# Sort the output (required for indexing)
bcftools sort gnomad_v2.1_sv.sites.T2T.vcf.gz -Oz -o gnomad_v2.1_sv.sites.T2T.sorted.vcf.gz

# Index the sorted file
tabix -p vcf gnomad_v2.1_sv.sites.T2T.sorted.vcf.gz
```

## Understanding Liftover Output

### Expected Warnings

```
Warning: source contig chr1 has length X in the VCF and length Y in the chain file
```
- Normal due to assembly differences
- Does not affect liftover quality

### Success Metrics

```
Lines total/swapped/reference added/rejected: 387477/0/0/8065
```
- **Total**: Input variants
- **Swapped**: Alleles swapped due to strand changes
- **Reference added**: New reference alleles
- **Rejected**: Variants that couldn't be lifted (~2% is normal)

## Troubleshooting

### Plugin Not Found

If `bcftools plugin -l` doesn't show liftover:

1. Check BCFTOOLS_PLUGINS is set correctly:
   ```bash
   echo $BCFTOOLS_PLUGINS
   ```

2. Verify plugin file exists:
   ```bash
   ls -la $BCFTOOLS_PLUGINS/liftover.so
   ```

3. Ensure plugin is executable:
   ```bash
   chmod +x $BCFTOOLS_PLUGINS/liftover.so
   ```

### Compilation Failures

Common issues and solutions:

1. **Missing bzip2/lzma libraries**
   - Use `--disable-bz2 --disable-lzma` during configure

2. **pgs.c compilation error**
   - Remove the file: `rm plugins/pgs.c`

3. **Version mismatch**
   - Ensure BCFtools source version matches installed version

### Liftover Failures

1. **High rejection rate (>5%)**
   - Check chain file is correct
   - Verify reference sequences match expected assembly

2. **Unsorted output**
   - Always sort before indexing: `bcftools sort`

3. **Memory issues**
   - Use streaming: `bcftools +liftover -Ou | bcftools sort -Oz -o output.vcf.gz`

## Best Practices

1. **Always validate output**
   ```bash
   bcftools stats original.vcf.gz > original.stats
   bcftools stats lifted.vcf.gz > lifted.stats
   # Compare statistics
   ```

2. **Keep rejected variants**
   ```bash
   bcftools +liftover input.vcf.gz --reject rejected.vcf -- [options]
   ```

3. **Document versions**
   ```bash
   bcftools --version > liftover_versions.txt
   bcftools plugin -lv >> liftover_versions.txt
   ```

## Additional Resources

- BCFtools liftover paper: https://doi.org/10.1093/bioinformatics/btae038
- Plugin source: https://github.com/freeseek/score
- Chain files: https://hgwdev.gi.ucsc.edu/~markd/t2t/CHM13-fixed-chains/