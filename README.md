![Pipeline Status](https://img.shields.io/badge/Pipeline-Passing-success)
![QC Status](https://img.shields.io/badge/QC-Verified-success)
![Platform](https://img.shields.io/badge/Snakemake-v7.x-blue)
![License](https://img.shields.io/badge/License-MIT-yellow)

# Germline-Variant-QC-BRCA

This repository contains a reproducible Snakemake pipeline for Quality Control (QC) and population stratification (PCA) of germline variants in Breast Cancer (BRCA).

## Overview
Large-scale genomic studies are often confounded by population structure and technical artifacts. This pipeline automates the transition from raw VCF files to ancestry-aware association testing.

## Workflow
1. **Format Conversion:** VCF to PLINK binary (.bed/.bim/.fam).
2. **Genomic QC:** Filtering by MAF (>0.05), Missingness (<0.02), and Hardy-Weinberg Equilibrium.
3. **Ancestry Stratification:** LD pruning followed by PCA to identify population clusters.
4. **Association:** Logistic regression split by age at diagnosis.

## Prerequisites
- Conda or Mamba
- Snakemake
- PLINK 1.9

## Usage
1. Clone the repository:
   git clone https://github.com/YOUR_USERNAME/Germline-Variant-QC-BRCA.git
2. Install dependencies:
   conda env create -f envs/bioinformatics.yaml
3. Run the pipeline:
   snakemake --cores 4
