# Changelog

All notable changes to VEPforT2T will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-06-26

### Added
- Initial release of VEPforT2T
- Main execution script for T2T-CHM13v2.0 variant annotation
- Automated installation script with dependency management
- BCFtools liftover plugin integration for SV reference conversion
- Support for gnomAD SV annotations lifted to T2T coordinates
- Batch processing capabilities for multiple VCF files
- Comprehensive documentation including:
  - Detailed installation guide
  - T2T-specific annotation explanations
  - Liftover setup instructions
  - FAQ section
- Example test data
- Configuration management system
- Robust error handling and logging

### Features
- Pure T2T annotation without GRCh38 contamination
- Automatic handling of T2T-specific gene identifiers (ENSG05220*)
- StructuralVariantOverlap plugin support with lifted coordinates
- Parallel processing support
- Configurable threading and buffer sizes

### Known Limitations
- T2T-specific gene symbols not yet available for all genes
- Some structural variants may fail liftover (~2-5%)
- Requires manual download of T2T cache files

## Future Releases

### [Planned]
- Support for T2T-specific CADD scores when available
- Integration with T2T-specific constraint scores
- Automated cache download functionality
- Docker/Singularity container support
- Support for additional output formats
- Web interface for result visualization