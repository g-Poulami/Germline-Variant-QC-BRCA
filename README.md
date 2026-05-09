# Germline-Variant-QC-BRCA

[![Pipeline Status](https://img.shields.io/badge/Pipeline-Passing-success?style=flat-square)](https://github.com/g-Poulami/Germline-Variant-QC-BRCA)
[![QC Status](https://img.shields.io/badge/QC-Verified-success?style=flat-square)](https://github.com/g-Poulami/Germline-Variant-QC-BRCA)
[![Snakemake](https://img.shields.io/badge/Snakemake-v7.x-blue?style=flat-square)](https://snakemake.readthedocs.io/)
[![PLINK](https://img.shields.io/badge/PLINK-v1.9-informational?style=flat-square)](https://www.cog-genomics.org/plink/)
[![License](https://img.shields.io/badge/License-Apache_2.0-yellow?style=flat-square)](LICENSE)
[![Build](https://img.shields.io/badge/Build-v1.0.2-orange?style=flat-square)](https://github.com/g-Poulami/Germline-Variant-QC-BRCA)
[![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20HPC-informational?style=flat-square&logo=linux&logoColor=white)]()

---

## Biological Question

What inherited variants predispose certain individuals to breast cancer — and how do we reliably find them in the presence of sequencing noise and ancestral diversity?

Hereditary breast cancer is driven by **germline variants**: mutations present from birth in every cell of the body, inherited from a parent, and capable of disrupting critical tumour suppressor pathways. The best-characterised examples are loss-of-function mutations in *BRCA1* and *BRCA2*, which impair homologous recombination repair and confer a lifetime breast cancer risk of up to 70%. But these high-penetrance variants explain only ~25% of hereditary cases. The remaining risk is distributed across moderate-penetrance genes (*PALB2*, *ATM*, *CHEK2*) and thousands of common low-effect variants captured by genome-wide association studies (GWAS).

Identifying genuine disease-associated variants in this landscape requires overcoming two fundamental analytical challenges:

1. **Separating biological signal from sequencing artefact.** Germline variant calls from sequencing data contain systematic errors: variants that fail Hardy-Weinberg equilibrium (likely genotyping errors), variants present in too few individuals to be informative (low MAF), and positions with high missingness across samples. Standard GWAS quality control filters address each of these before any association analysis.

2. **Controlling for population structure.** Allele frequencies differ substantially across ancestral populations — a variant common in Europeans may be rare in Africans, and vice versa. If a cohort contains individuals of mixed ancestry and ancestry is correlated with case/control status, spurious associations emerge. Principal Component Analysis (PCA) of germline variants reveals population structure, enabling its inclusion as a covariate to prevent ancestral confounding.

This pipeline implements both steps in a reproducible, scalable Snakemake workflow, producing QC-filtered variant sets, ancestry-stratified PCA, and GWAS association results with genome-wide significance visualisation. It is designed for TCGA-BRCA germline variant data but is applicable to any human cohort in VCF format.

---

## Key Finding

> **PCA of germline variants reveals clear population structure in TCGA-BRCA, stratifying samples into ancestrally distinct clusters consistent with known EUR, AFR, and EAS population composition.**

This finding has a direct and important implication: **unadjusted association analyses on this cohort would be confounded by ancestry.** Variants that differ in frequency between, say, European and African patients would generate spurious association signals if African patients are disproportionately represented in the case or control group. The PCA results validate that population stratification correction is not merely a methodological formality — it is biologically necessary for valid hereditary risk inference in this dataset.

The Q-Q plot confirms that after including PCA components as covariates, the logistic regression model is well-calibrated: observed p-values align closely with the expected null distribution, indicating that genomic inflation has been successfully controlled (λ ≈ 1).

---

## Why Germline QC Matters for Hereditary Breast Cancer Research

Understanding the germline landscape of breast cancer is central to several clinical and research priorities:

- **Risk stratification:** Identifying moderate- and high-penetrance germline variants enables population-level risk stratification — determining who should be offered enhanced screening or prophylactic intervention before cancer develops.
- **Hereditary vs sporadic distinction:** Early-onset breast cancer is enriched for germline BRCA1/2 carriers relative to late-onset disease. Reliable germline QC is a prerequisite for any analysis comparing hereditary and sporadic tumour biology.
- **Polygenic risk scores (PRS):** Beyond single high-impact variants, common germline SNPs collectively explain a substantial fraction of population-level breast cancer risk. Building valid PRS requires a clean, ancestry-corrected variant set — exactly what this pipeline produces.
- **Multi-ethnic equity:** GWAS findings derived from European-majority cohorts may not generalise to non-European populations. Ancestry-aware QC is the first step toward equitable genomic risk tools.

---

## Pipeline Overview

The workflow is automated using **Snakemake** to ensure reproducibility and scalability across HPC environments. Each step produces intermediate files that are version-controlled and inspectable.

```
VCF Input
    │
    ▼
1. VCF → PLINK binary (.bed / .bim / .fam)
    │
    ▼
2. Quality Control
   ├── MAF filtering    (remove variants with MAF < 0.05)
   ├── Missingness      (remove variants with genotype missingness > 2%)
   └── HWE filtering    (remove variants with HWE p < 1×10⁻⁶)
    │
    ▼
3. LD Pruning
   └── Window: 50 variants, step: 5, r² threshold: 0.2
    │
    ▼
4. PCA — population stratification
   └── Identifies ancestry clusters; top PCs used as covariates
    │
    ▼
5. GWAS Association
   └── Logistic regression (case/control) with PCA covariates
    │
    ▼
Outputs: PCA plot · Manhattan plot · Q-Q plot
```

---

## Pipeline Steps in Detail

### Step 1 — VCF to PLINK

Converts raw VCF genomic data into PLINK binary format (`.bed`, `.bim`, `.fam`), the standard input format for GWAS tools. Binary PLINK format encodes genotypes bit-efficiently, enabling analysis of millions of variants across thousands of samples in memory.

### Step 2 — Quality Control

Three filters are applied to remove unreliable variants before association analysis:

| Filter | Threshold | Rationale |
|--------|-----------|-----------|
| **Minor Allele Frequency (MAF)** | > 0.05 | Variants present in fewer than 5% of individuals have insufficient statistical power for association testing and are prone to genotyping error |
| **Genotype missingness** | < 0.02 | Variants missing in more than 2% of samples likely reflect systematic assay failure at that position |
| **Hardy-Weinberg Equilibrium (HWE)** | p > 1×10⁻⁶ | Significant deviation from HWE in controls is a strong indicator of genotyping error, not genuine biological signal |

These thresholds reflect standard GWAS best practice and are consistent with large-scale studies such as the UK Biobank and TCGA germline analyses.

### Step 3 — LD Pruning

Linkage disequilibrium (LD) pruning removes correlated variants, retaining a set of approximately independent markers for PCA. Nearby variants on the same chromosome are often highly correlated due to physical proximity on the chromosome — including all of them in PCA would cause nearby genomic regions to dominate the principal components, obscuring genuine population structure.

Parameters: sliding window of 50 variants, step size of 5, r² threshold of 0.2.

### Step 4 — Principal Component Analysis

PCA is performed on the LD-pruned variant set to identify population structure. Each principal component (PC) captures a dimension of ancestral variation across samples. The top PCs — typically PC1 and PC2 — separate major continental ancestry groups (EUR, AFR, EAS) into visually distinct clusters when plotted.

The top PCs are then included as covariates in the association model to prevent ancestry from confounding the case/control comparison.

### Step 5 — GWAS Association

Logistic regression is performed (case = breast cancer diagnosis, control = unaffected) with the top PCA components as covariates. The resulting p-values are visualised as a Manhattan plot (genome-wide significance at p < 5×10⁻⁸) and validated using a Q-Q plot.

---

## Data Specifications

| Property | Details |
|----------|---------|
| **Input format** | VCF (Variant Call Format) |
| **Reference genome** | GRCh38 / hg38 |
| **Target cohort** | TCGA-BRCA germline variants |
| **Environment** | Conda (`bioinformatics.yaml`) |
| **Workflow engine** | Snakemake v7.x |
| **HPC compatibility** | SLURM, SGE, PBS |

---

## Results

### 1 — Population Stratification (PCA)

PCA of QC-filtered, LD-pruned germline variants identifies ancestry clusters within the TCGA-BRCA cohort. Samples cluster into groups consistent with known EUR, AFR, and EAS population structure. This confirms that the cohort is ancestrally heterogeneous and that population stratification correction is required before association analysis.

![PCA Plot](results/pca_plot.png)

**Biological interpretation:** Each cluster on the PCA plot represents a group of patients with shared ancestral background. The separation between clusters reflects genuine differences in allele frequencies accumulated over thousands of years of population history. Including the top PCs as covariates in the association model ensures that any variant associations discovered reflect biology — not ancestry.

---

### 2 — Association Results (Manhattan Plot)

The Manhattan plot visualises the statistical significance of every tested SNP across the genome, ordered by chromosomal position. Each point is one SNP; the y-axis shows −log10(p-value). The horizontal dashed line marks the genome-wide significance threshold (p < 5×10⁻⁸).

![Manhattan Plot](results/manhattan_plot.png)

**Biological interpretation:** Peaks crossing the genome-wide significance line identify loci where germline variation is statistically associated with breast cancer case/control status. In the context of TCGA-BRCA, significant peaks in the BRCA1 (17q21), BRCA2 (13q12), or PALB2 (16p12) regions would be particularly notable, as these represent the highest-penetrance hereditary breast cancer loci. Peaks at other loci may represent novel moderate-penetrance candidates or polygenic risk score components warranting follow-up functional validation.

---

### 3 — Model Validation (Q-Q Plot)

The Q-Q plot compares the observed distribution of p-values against the expected null distribution (no association anywhere in the genome). Under the null, points should lie along the diagonal. Systematic inflation above the diagonal indicates uncontrolled population stratification or other confounders; deflation below indicates model over-correction.

![Q-Q Plot](results/qq_plot.png)

**Biological interpretation:** Alignment with the diagonal confirms that the logistic regression model is well-calibrated and that genomic inflation has been successfully controlled by including PCA components as covariates. Late departure from the diagonal (in the upper tail of significance) is expected and desirable — it reflects the genuine association signal from true disease loci rising above the null background.

---

## Repository Structure

```
Germline-Variant-QC-BRCA/
│
├── Snakefile                    # Main workflow definition
├── bioinformatics.yaml          # Conda environment specification
├── config/
│   └── config.yaml              # Pipeline parameters (thresholds, paths)
│
├── scripts/
│   ├── vcf_to_plink.sh          # VCF format conversion
│   ├── run_qc.sh                # MAF, missingness, HWE filtering
│   ├── ld_pruning.sh            # LD pruning for PCA
│   ├── run_pca.sh               # PCA execution and plot generation
│   └── run_gwas.sh              # Logistic regression association
│
├── results/
│   ├── pca_plot.png             # Population stratification PCA
│   ├── manhattan_plot.png       # GWAS association results
│   └── qq_plot.png              # Model calibration Q-Q plot
│
└── README.md
```

---

## Reproducing the Analysis

### 1. Clone the repository

```bash
git clone https://github.com/g-Poulami/Germline-Variant-QC-BRCA.git
cd Germline-Variant-QC-BRCA
```

### 2. Set up the Conda environment

```bash
conda env create -f bioinformatics.yaml
conda activate germline-qc
```

### 3. Configure input paths

Edit `config/config.yaml` to point to your input VCF file and set any parameter overrides.

### 4. Run the full pipeline

```bash
# Local execution
snakemake --cores 8

# HPC execution (SLURM)
snakemake --cluster "sbatch --mem={resources.mem_mb} --cpus-per-task={threads}" \
          --jobs 50 --cores 8
```

### 5. Inspect outputs

Results are written to `results/`. The PCA plot, Manhattan plot, and Q-Q plot are generated automatically at the end of the workflow.

---

## Limitations

- MAF threshold of 0.05 excludes rare variants (MAF < 5%), which include some of the highest-penetrance hereditary risk alleles (e.g. pathogenic BRCA1/2 variants are rare at population level). Rare variant analysis requires burden testing methods (SKAT, SKAT-O) rather than standard logistic regression
- HWE filtering is applied cohort-wide; applying it within ancestry groups separately would be more sensitive to genotyping errors in multi-ethnic cohorts
- The pipeline does not currently perform sex-chromosome QC (X-chromosome inactivation, sex mismatch checks) — recommended for full GWAS compliance
- Association results from TCGA-BRCA should be interpreted cautiously given case-only enrichment and the absence of population-matched controls in the original cohort design

---

## Connections to Broader Research

This pipeline sits at the interface of two important research directions:

- **Hereditary breast cancer genetics:** Providing a clean, stratified germline variant set is the prerequisite for downstream analyses of BRCA1/2 carrier frequency, polygenic risk score construction, and gene-environment interaction modelling in early-onset disease.
- **Multi-ethnic genomic equity:** The PCA-based ancestry correction implemented here is the first step toward ensuring that germline risk findings are valid across diverse populations — a core challenge for the field given that most GWAS discovery has been conducted in predominantly European cohorts.

See also: [GenEquityFlow](https://github.com/g-Poulami/GenEquityFlow) for a pipeline explicitly quantifying the Generalisability Gap in cancer genomics across ancestral populations.

---

## References

1. Purcell et al. (2007). PLINK: a tool set for whole-genome association and population-based linkage analyses. *American Journal of Human Genetics*, 81(3), 559–575.
2. Price et al. (2006). Principal components analysis corrects for stratification in genome-wide association studies. *Nature Genetics*, 38, 904–909.
3. Mavaddat et al. (2019). Polygenic risk scores for prediction of breast cancer and breast cancer subtypes. *American Journal of Human Genetics*, 104(1), 21–34.
4. Kuchenbaecker et al. (2017). Risks of breast, ovarian, and contralateral breast cancer for BRCA1 and BRCA2 mutation carriers. *JAMA*, 317(23), 2402–2416.
5. Anderson et al. (2010). Data quality control in genetic case-control association studies. *Nature Protocols*, 5, 1564–1573.

---

## Author

**Poulami Ghosh** — [@g-Poulami](https://github.com/g-Poulami)
[LinkedIn](https://linkedin.com/in/poulami-ghosh-879439304) · [Google Scholar](https://scholar.google.com/scholar?q=Poulami+Ghosh) · poulamighosh738@gmail.com

---

## License

This project is licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for details.
