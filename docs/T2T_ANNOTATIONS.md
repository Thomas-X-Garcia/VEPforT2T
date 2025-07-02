# Understanding T2T-Specific Annotations

This document explains the unique aspects of VEP annotations when using the T2T-CHM13v2.0 reference genome.

## T2T-Specific Gene Identifiers

### The ENSG05220* Pattern

When running VEP on T2T-CHM13v2.0, you may encounter gene identifiers with the pattern `ENSG05220*`, such as:
- ENSG05220000130
- ENSG05220059608
- ENST05220232119 (transcript IDs)

These appear to be **cache-specific synthetic identifiers** that:
- Use a non-standard 13-digit format (standard Ensembl IDs use 11 digits)
- Are NOT found in official Ensembl databases
- Likely represent placeholder IDs in the T2T cache (v107)
- Often lack gene symbols (SYMBOL='-' in output)
- May be artifacts from cache generation rather than official gene models

### Why Do These Exist?

1. **Novel Sequence**: T2T-CHM13v2.0 includes ~200 Mb of sequence not present in GRCh38
2. **Synthetic Identifiers**: Created during T2T cache generation for novel genes
3. **Incomplete Annotation**: Gene symbols not yet assigned to all T2T-specific genes

## Interpreting VEP Output

### Example Output Line

```
chr11  24500000  rs123  A  G  ENSG05220000130  ENST05220000194  missense_variant  protein_coding  -  MODIFIER
```

Key observations:
- **Gene**: ENSG05220000130 (T2T-specific)
- **Symbol**: '-' (no assigned symbol)
- **Biotype**: protein_coding (legitimate protein-coding gene)
- **Location**: chr11:24500000 (may overlap with known genes like LUZP2)

### Cross-Referencing with Known Genes

Many T2T-specific IDs correspond to genomic regions containing known genes. To identify:

1. **Use coordinates**: Extract chr:start-end from VEP output
2. **Check GFF3**: Search RefSeq annotations for overlapping genes
3. **BEDTools intersect**: Systematically find overlapping annotations

Example:
```bash
# Extract coordinates for T2T-specific genes
grep "ENSG05220" output.txt | cut -f2,3 > t2t_coords.bed

# Find overlapping RefSeq genes
bedtools intersect -a t2t_coords.bed -b refseq_genes.bed -wa -wb
```

## Common T2T Annotation Scenarios

### 1. Centromeric Regions
- Previously unsequenced in GRCh38
- May contain novel transcripts
- Often repetitive sequences

### 2. Acrocentric Short Arms
- Chromosomes 13, 14, 15, 21, 22
- Rich in rDNA and satellite sequences
- Novel gene models possible

### 3. Segmental Duplications
- Resolved in T2T but collapsed in GRCh38
- May show multiple gene copies
- Complex annotation patterns

## Working with T2T Annotations

### Best Practices

1. **Keep Both Annotations**: Retain both Ensembl IDs and coordinate-based lookups
2. **Validate Important Variants**: Cross-check high-impact variants
3. **Document T2T-Specific Findings**: Note which variants fall in T2T-novel regions

### Filtering Strategies

```bash
# Extract variants in known genes only
grep -v "ENSG05220" vep_output.txt > known_genes_only.txt

# Extract T2T-specific annotations
grep "ENSG05220" vep_output.txt > t2t_specific.txt

# Get summary statistics
echo "Total variants: $(grep -v "^#" vep_output.txt | wc -l)"
echo "T2T-specific: $(grep -c "ENSG05220" vep_output.txt)"
echo "Known genes: $(grep -v "ENSG05220" vep_output.txt | grep -v "^#" | wc -l)"
```

## Future Updates

As T2T annotations mature:
- Gene symbols will be assigned to T2T-specific genes
- HGNC will provide official nomenclature
- RefSeq/Ensembl will integrate T2T annotations
- Cache updates will include complete annotations

## Resources

- T2T Consortium: https://github.com/marbl/CHM13
- T2T Browser: https://genome.ucsc.edu/cgi-bin/hgTracks?db=hub_3671779_hs1
- Ensembl T2T: https://useast.ensembl.org/Homo_sapiens_GCA009914755v4/Info/Index

## Frequently Asked Questions

**Q: Are ENSG05220* IDs errors?**
A: No, they are legitimate T2T-specific identifiers from the cache.

**Q: Why don't they have gene symbols?**
A: Gene nomenclature for T2T-novel regions is still being established.

**Q: Can I ignore these annotations?**
A: Not recommended - they may represent functionally important regions.

**Q: How do I validate these genes?**
A: Use coordinate-based lookups in RefSeq GFF3 or UCSC browser.