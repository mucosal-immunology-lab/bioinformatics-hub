# Nextflow Workflows

As they are built and published, this repository will contain Nextflow workflows for processing of different data omic modalities.

Additionally, we may provide additional tools and code for further downstream processing, with the goal of standardising data analytic approaches within the Mucosal Immunology Lab.

## Single-cell RNAseq FASTQ pre-processing

[**nf-mucimmuno/scRNAseq**](./scRNAseq.md) is a bioinformatics pipeline for single-cell RNA sequencing data that can be used to run quality control steps and alignment to a host genome using STARsolo. Currently only configured for use with data resulting from BD Rhapsody library preparation.

![nfmucimmuno/scRNAseq](../assets/NextFlow/nf-mucimmuno_scRNAseq.png)

## 16S amplicon DADA2 pre-processing

[**nf-mucimmuno/dada2_16S**](./dada2_16S.md) is a pipeline for pre-processing of 16S rRNA amplicon sequencing data using the popular [DADA2](https://benjjneb.github.io/dada2/index.html) package and associated tools. It covers demultiplexing with `illumina-utils`, the DADA2 workflow, and subsequent generation of a *de novo* phylogenetic tree using RAxML.

![nfmucimmuno/dada2_16S](../assets/NextFlow/nf-mucimmuno_dada2_16S.png)