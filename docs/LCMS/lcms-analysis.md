# LCMS analysis

Here we will provide a guide for the processing of raw LCMS output files from metabolomics and lipidomics runs, how to undertake curation and annotation, and approaches for their analysis downstream.

## Overview

The MS-DIAL software we recommend provides a pipeline for untargeted metabolomics. Its outputs then require thorough quality control measures and additional annotation steps. Additional annotation with HMDB and/or LIPID MAPS supplements the annotations provided through standards and MS-DIAL to ensure we can retain and utilise the maximum number of features.

!!! info "Citation"

    If you use this workflow and end up publishing something, please consider including a reference to our work! 😎🙏

    Macowan, M., Pattaroni, C., Cardwell, B. A., Iacono, G., & Marsland, B. (2025). Mucosal Immunology Research Group - Processing metabolome and lipidome data with MS-DIAL. Zenodo. [https://doi.org/10.5281/zenodo.15701971](https://doi.org/10.5281/zenodo.15701971)

**Analysis workflow**

1. [Process raw LCMS data with MS-DIAL](./msdial-processing.md)
2. [Perform automated quality control with pmp](./pmp-quality-control.md)
3. [Secondary feature annotation with HMDB/LIPID MAPS](./secondary-feature-annotation.md)
4. [Manual curation of annotated spectra](./manual-peak-curation.md)
5. Downstream analysis