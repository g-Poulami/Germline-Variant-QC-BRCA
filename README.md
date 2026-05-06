# Germline-Variant-QC-BRCA

![Pipeline Status](https://img.shields.io/badge/Pipeline-Passing-success)
![QC Status](https://img.shields.io/badge/QC-Verified-success)
![Platform](https://img.shields.io/badge/Snakemake-v7.x-blue)
![License](https://img.shields.io/badge/License-MIT-yellow)
![Build](https://img.shields.io/badge/Build-v1.0.2-orange)

## Project Overview
This repository contains a reproducible Snakemake pipeline designed for Quality Control (QC), population stratification, and Genome-Wide Association Studies (GWAS) of germline variants in Breast Cancer (BRCA).

## Pipeline Details
The workflow is automated using **Snakemake** to ensure reproducibility and scalability across High-Performance Computing (HPC) environments. 

1. **VCF to PLINK**: Converts raw VCF genomic data into binary PLINK format (.bed, .bim, .fam).
2. **Quality Control**: Filters variants based on:
    * **MAF > 0.05**: Minor Allele Frequency to remove rare variants.
    * **Geno < 0.02**: Genotype missingness threshold.
    * **HWE < 1e-6**: Hardy-Weinberg Equilibrium to filter out genotyping errors.
3. **LD Pruning**: Performed using a 50-variant window, shifting by 5, with an ^2$ threshold of 0.2 to ensure marker independence.
4. **PCA**: Principal Component Analysis for population structure identification.
5. **Association**: Logistic regression analysis using case/control phenotypes.

## Data Specifications
* **Format**: Input is raw VCF (Variant Call Format).
* **Reference**: Designed for human genomic variants (GRCh38/hg38).
* **Environment**: Managed via Conda (see `bioinformatics.yaml`).

## Results & Analysis

### 1. Population Stratification (PCA)
PCA identified ancestry clusters to prevent population structure from confounding association results.

![PCA Plot](results/pca_plot.png)

### 2. Association Results (Manhattan Plot)
The Manhattan plot visualizes the statistical significance of SNPs across the genome.

![Manhattan Plot](results/manhattan_plot.png)

**Interpretation**: Peaks crossing the genome-wide significance line identify potential risk loci for BRCA.

### 3. Model Validation (Q-Q Plot)
The Q-Q plot compares observed p-values against the expected null distribution.

![Q-Q Plot](results/qq_plot.png)

**Interpretation**: The alignment with the diagonal line confirms that the model is well-calibrated and population inflation has been controlled.

---
*Developed for research in translational computational genomics.*
