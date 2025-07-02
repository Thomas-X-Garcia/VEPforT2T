# Frequently Asked Questions (FAQ)

## General Questions

### Q: What is VEPforT2T?
**A:** VEPforT2T is a specialized pipeline for running Ensembl VEP on variants called against the T2T-CHM13v2.0 (Telomere-to-Telomere) complete human reference genome. It ensures proper use of T2T-specific cache and annotations.

### Q: Why do I need a special pipeline for T2T?
**A:** The T2T-CHM13v2.0 reference has unique characteristics:
- Different chromosome lengths than GRCh38
- ~200 Mb of novel sequence
- Requires specific cache (homo_sapiens_gca009914755v4)
- Needs lifted coordinate files for existing resources

### Q: Is this compatible with standard VEP?
**A:** Yes, VEPforT2T uses standard Ensembl VEP (v114+) but with T2T-specific configuration and data files.

## Installation Issues

### Q: Installation fails with "libbzip2 development files not found"
**A:** Configure without bzip2 support:
```bash
./configure --prefix=$CONDA_PREFIX --disable-bz2 --disable-lzma
```

### Q: Where do I get the T2T cache?
**A:** The T2T cache should be downloaded from:
- Official Ensembl FTP (when available)
- T2T consortium resources
- Contact the developers if unavailable

### Q: BCFtools plugin compilation fails
**A:** Common solutions:
1. Remove problematic plugins: `rm plugins/pgs.c`
2. Ensure gcc is installed: `conda install -c conda-forge gcc`
3. Check BCFtools version matches source version

## Usage Questions

### Q: What file formats are supported?
**A:** 
- Input: VCF or compressed VCF (vcf.gz)
- Output: Tab-delimited text (default) or VCF
- Must be bgzip compressed for indexing

### Q: Can I use GRCh38 VCF files?
**A:** No, input VCF must have variants called against T2T-CHM13v2.0. Coordinates must match the T2T reference.

### Q: How do I handle the chr prefix?
**A:** The T2T reference uses 'chr' prefixes (chr1, chr2, etc.). The pipeline handles this automatically.

## Output Interpretation

### Q: What are ENSG05220* identifiers?
**A:** These are T2T-specific gene identifiers:
- Represent genes in T2T-novel regions
- Use 13-digit format
- Often lack gene symbols
- Are legitimate cache entries, not errors

### Q: Why are some gene symbols missing?
**A:** Missing symbols (SYMBOL='-') occur for:
- T2T-specific genes not yet in HGNC
- Novel transcripts in resolved regions
- Genes awaiting official nomenclature

### Q: How do I filter results?
**A:** Common filtering approaches:
```bash
# High-impact variants only
grep -E "HIGH|MODERATE" output.txt

# Known genes only (exclude T2T-specific)
grep -v "ENSG05220" output.txt

# Specific consequence types
grep "missense_variant\|stop_gained" output.txt
```

## Performance and Resources

### Q: How much memory do I need?
**A:** 
- Minimum: 8GB RAM
- Recommended: 16GB+ RAM
- Large VCFs may require more

### Q: How can I speed up annotation?
**A:** 
- Increase threads: `--threads 32`
- Increase buffer size: `--buffer-size 50000`
- Use SSD storage for cache
- Process chromosomes separately

### Q: Can I run this on a cluster?
**A:** Yes, the pipeline is cluster-friendly:
- No internet required after setup
- Supports parallel processing
- Use batch script for multiple files

## Troubleshooting

### Q: "No cache found" error
**A:** Check:
1. Cache exists: `ls ~/.vep/homo_sapiens_gca009914755v4/107_T2T-CHM13v2.0/`
2. Species name is correct: `homo_sapiens_gca009914755v4`
3. Version is correct: `107`

### Q: StructuralVariantOverlap plugin fails
**A:** Ensure:
1. Plugin file exists: `~/.vep/Plugins/StructuralVariantOverlap.pm`
2. SV reference file is indexed: `tabix -p vcf file.vcf.gz`
3. File path is correct in script

### Q: Liftover rejects many variants
**A:** Normal rejection rates:
- SNVs: ~1-2%
- Indels: ~1-3%
- SVs: ~2-5%

Higher rates may indicate wrong chain file or reference mismatch.

## Advanced Usage

### Q: Can I add custom annotations?
**A:** Yes, VEP supports custom annotation files:
```bash
--custom file.bed.gz,MyAnnotation,bed,overlap,0
```

### Q: How do I annotate specific transcripts?
**A:** Use transcript-specific options:
```bash
--transcript_filter "stable_id match ENST05220"
```

### Q: Can I use CADD scores?
**A:** CADD scores for T2T are not yet available. When released, use:
```bash
--plugin CADD,T2T_CADD_whole_genome.tsv.gz
```

## Getting Help

### Q: Where can I get more help?
**A:** 
1. Check documentation in `/docs` folder
2. Submit issues: https://github.com/Thomas-X-Garcia/VEPforT2T/issues
3. VEP documentation: https://www.ensembl.org/info/docs/tools/vep/
4. T2T consortium: https://github.com/marbl/CHM13

### Q: How do I report a bug?
**A:** Include:
1. VEPforT2T version
2. Complete error message
3. Command used
4. Sample of input file
5. System information

### Q: Can I contribute?
**A:** Yes! See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines.