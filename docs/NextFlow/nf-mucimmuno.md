# Nextflow Workflows

As they are built and published, this repository will contain Nextflow workflows for processing of different data omic modalities.

Additionally, we may provide additional tools and code for further downstream processing, with the goal of standardising data analytic approaches within the Mucosal Immunology Lab.

## Single-cell RNAseq FASTQ pre-processing

[**nf-mucimmuno/scRNAseq**](./scRNAseq.md) is a bioinformatics pipeline for single-cell RNA sequencing data that can be used to run quality control steps and alignment to a host genome using STARsolo. Currently only configured for use with data resulting from BD Rhapsody library preparation.

![nfmucimmuno/scRNAseq](../assets/NextFlow/nf-mucimmuno_scRNAseq.png)