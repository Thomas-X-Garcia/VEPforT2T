# VEPforT2T

A specialized pipeline for running Ensembl Variant Effect Predictor (VEP) on the complete T2T-CHM13v2.0 human reference genome.

**Author:** Thomas X. Garcia, PhD, HCLD  
**License:** MIT  
**Version:** 1.0.0

## Overview

VEPforT2T provides optimized scripts and comprehensive documentation for annotating variants called against the T2T-CHM13v2.0 (Telomere-to-Telomere) human reference genome using Ensembl Variant Effect Predictor (VEP). This pipeline addresses the unique challenges of using VEP with the newly released T2T reference genome, namely the lack of plugin support and cache files. This pipeline addresses those problems by providing detailed instructions for obtaining and configuring the T2T-specific cache (homo_sapiens_gca009914755v4), implementing a complete BCFtools liftover workflow to convert existing structural variant databases to T2T coordinates, and ensuring pure T2T annotations without contamination from GRCh38 data. The pipeline provides a streamlined solution for running VEP on T2T-aligned variants with proper cache configuration and structural variant support.

## Key Features

- **T2T-Optimized**: Configured specifically for T2T-CHM13v2.0 reference genome
- **No GRCh38 Contamination**: Ensures pure T2T annotations without mixing GRCh38 data
- **Structural Variant Support**: Includes lifted gnomAD SV annotations for T2T coordinates
- **Comprehensive Documentation**: Step-by-step setup and usage instructions
- **Production Ready**: Robust error handling and extensive logging

## Table of Contents

1. [Requirements](#requirements)
2. [Installation](#installation)
3. [Quick Start](#quick-start)
4. [Detailed Setup](#detailed-setup)
5. [Usage](#usage)
6. [Understanding the Output](#understanding-the-output)
7. [Troubleshooting](#troubleshooting)
8. [Advanced Configuration](#advanced-configuration)
9. [Citation](#citation)
10. [Contributing](#contributing)

## Requirements

- Linux operating system (tested on Ubuntu 20.04+)
- Miniconda or Anaconda
- At least 50GB free disk space
- Internet connection for downloads
- 8GB+ RAM recommended

## Installation

### Quick Installation

```bash
# Clone the repository
git clone https://github.com/Thomas-X-Garcia/VEPforT2T.git
cd VEPforT2T

# Run the installation script
bash scripts/install_vep_t2t.sh
```

### Manual Installation

See [docs/INSTALLATION.md](docs/INSTALLATION.md) for detailed manual installation instructions.

## Quick Start

After installation, annotate your VCF file:

```bash
# Activate the VEP environment
conda activate vep

# Run VEP for T2T
bash scripts/run_vep_t2t.sh /path/to/your/variants.vcf.gz
```

The output will be saved in the same directory as your input file with the suffix `_vep_t2t_only.txt`.

## Detailed Setup

### 1. VEP Installation

The pipeline requires Ensembl VEP v114+ with the following components:

- VEP core software
- T2T-CHM13v2.0 cache (v107)
- RefSeq GFF3 annotations
- StructuralVariantOverlap plugin

### 2. T2T Cache Configuration

```bash
# Download T2T-specific cache
cd ~/.vep
wget https://[cache-url]/homo_sapiens_gca009914755v4_107.tar.gz
tar -xzf homo_sapiens_gca009914755v4_107.tar.gz
```

### 3. Reference Files

Required reference files:
- T2T-CHM13v2.0 FASTA: `chm13v2.0.fa`
- RefSeq GFF3: `chm13v2.0_RefSeq_Liftoff_v5.2.sorted.gff3.gz`
- gnomAD SV (lifted to T2T): `gnomad_v2.1_sv.sites.T2T.sorted.vcf.gz`

### 4. BCFtools Liftover Setup

For creating T2T-compatible SV reference files, see [docs/LIFTOVER_SETUP.md](docs/LIFTOVER_SETUP.md).

## Usage

### Basic Usage

```bash
bash scripts/run_vep_t2t.sh input.vcf.gz
```

### Advanced Usage

```bash
# With custom output location
bash scripts/run_vep_t2t.sh input.vcf.gz --output-dir /custom/path/

# With additional VEP options
bash scripts/run_vep_t2t.sh input.vcf.gz --vep-options "--sift b --polyphen b"
```

### Batch Processing

```bash
# Process multiple VCF files
bash scripts/batch_vep_t2t.sh /path/to/vcf/directory/
```

## Understanding the Output

### Standard Output Format

The pipeline produces tab-delimited output with the following key fields:

- **Location**: Genomic position on T2T-CHM13v2.0
- **Gene**: Gene identifier (may include T2T-specific IDs like ENSG05220*)
- **Feature**: Transcript identifier
- **Consequence**: Variant consequence (e.g., missense_variant)
- **SYMBOL**: Gene symbol (may be empty for T2T-specific genes)

### T2T-Specific Annotations

Some annotations may show T2T-specific gene IDs (ENSG05220* pattern) without gene symbols. These represent:
- Novel genes in T2T assembly
- Genes in previously unresolved regions
- Synthetic identifiers from the T2T cache

See [docs/T2T_ANNOTATIONS.md](docs/T2T_ANNOTATIONS.md) for detailed information about T2T-specific annotations.

## Troubleshooting

### Common Issues

1. **Missing cache error**
   ```
   ERROR: No cache found for homo_sapiens_gca009914755v4
   ```
   Solution: Ensure T2T cache is properly installed in `~/.vep/`

2. **StructuralVariantOverlap plugin error**
   ```
   WARNING: Failed to instantiate plugin StructuralVariantOverlap
   ```
   Solution: Create T2T-lifted SV reference file (see [docs/LIFTOVER_SETUP.md](docs/LIFTOVER_SETUP.md))

3. **Chromosome naming issues**
   ```
   WARNING: Chromosome chr1 not found in cache
   ```
   Solution: T2T cache expects "chr" prefixes; this is handled automatically by the script

### Getting Help

- Check [docs/FAQ.md](docs/FAQ.md) for frequently asked questions
- Submit issues at: https://github.com/Thomas-X-Garcia/VEPforT2T/issues
- See VEP documentation: https://www.ensembl.org/info/docs/tools/vep/

## Advanced Configuration

### Custom Configuration File

Create a custom configuration file at `config/vep_custom.ini`:

```ini
# Custom VEP parameters
buffer_size = 50000
fork = 16
# Add your custom parameters here
```

### Environment Variables

```bash
# Set custom cache directory
export VEP_CACHE_DIR=/custom/cache/path

# Set custom plugin directory
export VEP_PLUGIN_DIR=/custom/plugin/path
```

## Citation

If you use VEPforT2T in your research, please cite:

1. **This pipeline:**
   ```
   Garcia, T.X. (2024). VEPforT2T: Variant Effect Prediction for T2T-CHM13v2.0. 
   Available at: https://github.com/Thomas-X-Garcia/VEPforT2T
   ```

2. **Ensembl VEP:**
   ```
   McLaren et al. (2016) The Ensembl Variant Effect Predictor. 
   Genome Biology 17:122. doi:10.1186/s13059-016-0974-4
   ```

3. **T2T-CHM13v2.0:**
   ```
   Nurk et al. (2022) The complete sequence of a human genome. 
   Science 376:44-53. doi:10.1126/science.abj6987
   ```

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file for details.

## Acknowledgments

- The T2T Consortium for the complete human reference genome
- The Ensembl team for VEP
- The Broad Institute for gnomAD structural variant data
- All contributors to the BCFtools project