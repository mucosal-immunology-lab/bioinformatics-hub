# Linear modelling with `bio_limma`

## Overview 📖

Here we discuss the application of a **wrapper function** around the popular `limma` linear modelling package for differential abundance and expression testing of biological datasets in R.
Our [`bio_limma()`](../../assets/CrossOmicTools/DifferentialTesting/bio_limma.R) function can neatly handle this task and enable rapid exploratory analysis of the effect of various associated sample metadata, including correcting for various potential confounders. 
Please see the [limma documentation](https://bioconductor.org/packages/release/bioc/html/limma.html) for further details regarding the main package if you have any particular limma-related queries.

## Inputs 🔢

Currently the function is suited to handle typical R data container formats related to microbiome, LCMS, and RNAseq data.

| Data format | Usage and notes |
| --- | --- |
| `phyloseq` | Classic format for microbiome data, as per our [DADA2 pipeline guide](../../Microbiome/dada2_pipeline.md). The function will use the OTU table and sample data as inputs. |
| `SummarizedExperiment` | Format used for metabolomic and lipidomic analysis, as per our [LCMS data processing guide](../../LCMS/lcms-analysis.md). The function will use the assay matrix and `@metadata$metadata` data as inputs. |
| `DGEList` | Format that we typically use for storing bulk RNAseq datasets, as per our [RNAseq data processing guide](../../RNAseq/rnaseq-nfcore.md). The function will use the assay and metadata as inputs. |
| `EList` | This is the object type resulting from an original `DGEList` object that has undergone `voom` normalisation &ndash; this is typical and means that `bio_limma()` doesn't then perform `voom` normalisation if requested. The function will use the `E` matrix and `targets` sample data table as inputs. |

!!! warning "`SummarizedExperiment` metadata is expected in a certain location"

    The `bio_limma()` function expects that the metadata for your `SummarizedExperiment` can be found in `data.frame` format at `SE_obj@metadata$metadata`, which is the case if you have followed our LCMS data processing guide.
    However, if you have created your object using a different approach, then it may be stored instead under the `colData` list element for example.
    If this is the case, then simply make a copy and place it in the correct location for use with `bio_limma()`.

    Also, your feature naming column within the `elementMetadata` is expected to be called `shortname`. This was a convention on our part when setting up the LCMS processing pipeline. You can either copy your column to a new `elementMetadata` column called `shortname`, or pass the row names to the function directly as an argument.

## Function parameters ⚙️

Because this function progressively evolved over time to handle the various tasks we wanted for our exploratory data analysis, there are a lot of different options you can set. View the pop-down window below for information on what parameters you can set.

??? info "What parameters and options can I set?"

    | Argument | Description |
    | --- | --- |
    | `input_data` | An appropriate input data format. A `phyloseq` object, a `SummarizedExperiment` object (containing metabolomics/lipidomics data and a feature naming column called `shortname`), or an RNAseq `DGEList` of `EList` object to use for differential abundance testing. |
    | `metadata_var` | OPTIONAL: the name of a **single** column from the `sample_data` to use for DA testing (e.g. `metadata_var = 'group'`). **NOT** required if providing a formula &ndash; it will be changed to `NULL` if you also provide `model_formula_as_string`. (default: `NULL`) |
    | `metadata_condition` | OPTIONAL: a conditional statement about a certain metadata value, e.g. keep a certain treatment group only. (default: `NULL`) |
    | `metadata_keep_columns` | OPTIONAL: this is typically required when you have complex metadata, and also supply your own model matrix and contrasts matrix. Choose columns from your metadata to retain using a character vector with column names. (default: `NULL`) |
    | `model_formula_as_string` | Just like it sounds &ndash; a string containing the model formula you want to use. Only works with `+` and not `*` at this stage. (default: `NULL`) |
    | `model_matrix` | OPTIONAL: although the function can create its own model matrix for simple testing, this is typically a good option for customising your comparisons. Also requires that provide a contrasts matrix. (default: `NULL`) |
    | `contrast_matrix` | OPTIONAL: the corresponding contrasts matrix to complement the custom model matrix. (default: `NULL`) |
    | `use_contrast_matrix` | A boolean selector for whether to use the contrast matrix or a selected coefficient. Best to leave this alone unless you're finding an error &ndash; the function will set this itself. (default: `TRUE`) |
    | `coefficients` | A selection of coefficients you want to be tested. This will depend on the order of variables in the formula, and you can select as many as you'd like, e.g. `coefficients = 2` or `coefficients = 3:4`. (default: `NULL`) |
    | `DGEList_slot` | Only used for RNAseq analysis when using a `DGEList` object as your input data. It tells this function which assay slot to use for analysis. Supply a string giving the name of the assay if it is not `'counts'`. (default: `'counts'`) |
    | `factor_reorder_list` | OPTIONAL: a named list containing reordered factor values, e.g. `list(Group = c('GroupHealthy', 'GroupDisease'))`. This is only needed if you don't supply your own contrasts matrix, because then the first factor level will be used as the reference group. (default: `NULL`) |
    | `continuous_modifier_list` | OPTIONAL: a named list containing functions to alter continuous metadata variables, e.g. `list(Age = function(x) x / 365)` to change ages in days to ages in years. (default: `NULL`) |
    | `adjust_method` | OPTIONAL: the method used to correct for multiple comparisons, listed [here](https://www.rdocumentation.org/packages/stats/versions/3.6.2/topics/p.adjust). (default: `'BH'`) |
    | `rownames` | OPTIONAL: a custom vector of names to be used if you don't wish the names to be automatically derived from your input data object. (default: `NULL`) |
    | `tax_id_col` | OPTIONAL: the `phyloseq` object `tax_table` column you wish to use for naming. This should match the level being tested (and should also match the deepest taxonomic level in the `phyloseq` object). If you want to test a higher level, then agglomerate the data using the `phyloseq::tax_glom()` function. If you do not provide this, then the function will automatically select the deepest level, i.e. the right-most column that isn't entirely composed on `NA` values. (default: `NULL`) |
    | `override_tax_id_check` | OPTIONAL: if you have decided to ignore the `phyloseq::tax_glom()` step, you can technically bypass the requirements for the `tax_id_col` argument by setting this to `TRUE`. You should really just go back and agglomerate your dataset though! (default: `FALSE`) |
    | `cores` | EXPERIMENTAL: I would just avoid this parameter for now - it was part of an experimental edit to allow use of multiple cores for faster generation of figures. If your code is running slowly, it is 100% just because of the individual feature plots step &ndash; setting `max_feature_plot_pages` to a lower value like `5` will solve this. You will still get your volcano plots and bar plots in either case. (default: `NULL`) |
    | `adj_pval_threshold` | The minimum level deemed statistically significant. (default: `0.05`) |
    | `logFC_threshold` | The minimum logFC threshold deemed significant &ndash; this can vary a lot depending on the scale of your metadata variable. (default: `1`) |
    | `legend_metadata_string` | OPTIONAL: a custom name for colour or fill options. (default: `NULL`) |
    | `volc_plot_title` | OPTIONAL: a custom title for the volcano plot (will be reused for the associated bar plots and individual feature plots). (default: `NULL`) |
    | `volc_plot_subtitle` | OPTIONAL: a custom subtitle for the volcano plot (will be reused for the associated bar plots and individual feature plots). (default: `NULL`) |
    | `use_groups_as_subtitle` | OPTIONAL: if set to `TRUE`, the function will use the group names (or the contrast matrix comparison names) as the volcano plot subtitle. (default: `FALSE`) |
    | `volc_plot_xlab` | OPTIONAL: a custom `x` label for the volcano plot. (default: `NULL`) |
    | `volc_plot_ylab` | OPTIONAL: a custom `y` label for the volcano plot. (default: `NULL`) |
    | `remove_low_variance_taxa` | OPTIONAL: is set to `TRUE`, the `phyloseq` OTU table will be checked for feature-wise variance, and all features with zero variance will be removed prior to downstream analysis. You may find `limma` throws an error if most of the features have no variance, so this step is sometimes required for certain datasets. (default: `FALSE`) |
    | `plot_output_folder` | OPTIONAL: a path to a folder where you would like output plots to be saved. If left blank, no plots will be saved. It will create a new folder if it does not exist at the final level &ndash; the parent folder must still exist. (default: `NULL`) |
    | `plot_file_prefix` | OPTIONAL: a string to attach to the start of the individual file names for your plots. This input is only used if the `plot_output_folder` argument is also provided. (default: `NULL`) |
    | `redo_boxplot_stats` | OPTIONAL: box plot statistics can be recalculated using `stat_compare_means()` from the `ggpubr` package. The default option will only show the `limma` statistics for the single comparison, so setting this to `TRUE` can provide more information, particularly if you have more than 2 levels for your categorical variable. (default: `FALSE`) |
    | `max_feature_plot_pages` | OPTIONAL: if an integer value is given, it will limit the number of feature plots generated &ndash; there will still be 12 plots per page. If you have a large number of significant features, setting this argument to something like 5 will dramatically improve running speed &ndash; this is the primary function bottleneck in terms of processing speed. (default: `NULL`) |
    | `use_voom` | OPTIONAL: this is used for RNAseq analysis, and will perform `voom` normalisation prior to running the `limma::fitLM()` function using the input data nd model matrix. Typically this will have been run prior to differential testing, and your input data will already be of type `EList`. (default: `FALSE`) |
    | `force_feature_table_variable` | OPTIONAL: if you provide your own model matrix and contrast matrix, `bio_limma` will attempt to determine which metadata column is being referenced when it tries to generate the feature plots. It does so using the `stringdist` pacakge, and does a pretty good job. However, if it is getting it wrong (especially if you have decided to make a nice contrast name that isn't close to the metadata column name), you can set this argument to the correct variable to ensure you get the plots you want. (default: `NULL`) |
    | `feature_plot_dot_colours` | OPTIONAL: you can colour the dots in your feature plots using a **categorical** variable identified by providing a string with the name of a metadata column. Keep in mind this column should be complete to avoid potential errors (i.e. no `NA` values). (default: `NULL`) |
    | `feature_plot_beeswarm_cex` | OPTIONAL: use this value to determine the horizontal spread of the dots. See [`ggbeeswarm`](https://www.rdocumentation.org/packages/ggbeeswarm/versions/0.7.2) documentation for more details. (default: `NULL`) |
    | `theme_pubr` | OPTIONAL: set this to `TRUE` to get cleaner, prettier plots using the `ggpubr` `theme_pubr` theme. (default: `FALSE`) |

## Function output 🎁

The function will return a list with different outputs from the analysis.

| List element | Description |
| --- | --- |
| `input_data` | The original counts table used to run the analysis. |
| `input_metadata` | A `data.frame` with the original metadata you provided. |
| `test_variables` | A `data.frame` with the subset of metadata variables used for the analysis. |
| `model_matrix` | The model matrix generated (or provided) to the function. |
| `contrast_matrix` OR `coefficients` | Either the contrast matrix used, or the coefficients selected, depending on the analysis you chose to run. |
| `limma_significant` | A list of `data.frames` containing the significant differentially abundant features determined by the `limma()` function, with the adjusted p-value and logFC threshold selected, for each comparison/coefficient. |
| `limma_all` | A list of `data.frames` containing the significance levels and logFC of all features, regardless of their significance, for each comparison/coefficient. |
| `volcano_plots` | Volcano plots for each of the comparisons/coefficients selected. |
| `bar_plots` | Bar plots combining significant features for each of the comparisons/coefficients selected. The x-axis shows the logFC values calculated by `limma`, with features names on the y-axis, ordered by the effect magnitude. |
| `feature_plots` | Individual box or scatter plots for each feature, for each of the comparisons/coefficients selected. |
| `venn_diagram` | An empty shell that originally contained the Venn diagram that showed up when running the function... This needs to be updated by using another Venn diagram function &ndash; hopefully to come in the future! |

??? info "Which plot files are saved to disk?"

    If a plot output folder path is provided, for each comparison/coefficient you have selected, three output `.pdf` files will be generated (provided there is at least 1 significant feature). All will have the calculated prefix: `{plot_file_prefix}_{test_variable + group}_`.

    | File name | Description |
    | --- | --- |
    | `volcplot.pdf` | A volcano plot showing all features, with significant features labelled. Decreased and increased features are shown in blue and red respectively. |
    | `barplot.pdf` | A bar plot showing significant features, with the logFC on the x-axis and the feature name on the y-axis. The y-axis is ordered by logFC magnitude, with negative at the bottom and positive at the top. Negative logFC features are coloured blue, while positive ones are coloured red. The top features of each direction are selected for plotting, and the plot will resize if there are fewer values than this. |
    | `featureplots.pdf` | Individual box or scatter plots for each feature. These plots are arranged with 12 features to a page (3 columns and 4 rows). Multiple pages will be combined into a single output `.pdf` files if there are more than 12 significant features. |

## Example ✨

### Microbiome data with custom model matrix 🦠

In this example, we want to find out the effect on the microbiome of two treatment options vs. sham treatment.
We decide to test for the effects of each compared to sham, and then compared the two treatment groups combined compared to sham.

```r title="Example of running bio_limma with custom comparisons"
# Load required packages
pkgs <- c('BiocGenerics', 'base', 'ggtree', 'ggplot2', 'IRanges', 'Matrix', 'S4Vectors', 'biomformat', 'plotly', 
          'dplyr', 'rstatix', 'ggpubr', 'stats', 'phyloseq', 'SummarizedExperiment', 'ggpmisc', 'ggrepel', 'ggsci', 
          'grDevices', 'here', 'limma', 'stringr', 'stringdist', 'ggbeeswarm', 'doParallel', 'openxlsx')
for (pkg in pkgs) {
    suppressPackageStartupMessages(library(pkg, character.only = TRUE))
}

# Load phyloseq data
bact_data_logCSS <- readRDS(here('output', '01_Preprocessing', 'bact_data_logCSS.rds'))

# Prepare the model matrix using the "Treatment" metadata column
model_matrix <- model.matrix(~ 0 + Treatment, data = data.frame(bact_data_logCSS@sam_data))

# Prepare the corresponding contrasts matrix
contrast_matrix <- makeContrasts('DrugA_vs_Sham' = TreatmentDrugA - TreatmentSham,
                                 'DrugB_vs_Sham' = TreatmentDrugB - TreatmentSham,
                                 'EitherDrug_vs_Sham' = (TreatmentDrugA + TreatmentDrugB) / 2 - TreatmentSham,
                                 levels = colnames(model_matrix))

# Run bio_limma
res <- bio_limma(input_data = bact_data_logCSS,
                 model_matrix = model_matrix,
                 contrast_matrix = contrast_matrix,
                 metadata_keep_columns = c('Group', 'SubjectID'),
                 logFC_threshold = 0.5,
                 adjust_method = 'BH',
                 adj_pval_threshold = 0.05,
                 redo_boxplot_stats = TRUE,
                 force_feature_table_variable = 'Treatment',
                 max_feature_plot_pages = 5,
                 plot_output_folder = here('figures', 'LimmaDA', 'ASV'),
                 plot_file_prefix = 'BH',
                 theme_pubr = TRUE)

# Save results to disk
saveRDS(res, here('figures', 'LimmaDA', 'ASV', 'limma_res.rds'))

# Write results tables to an Excel workbook
limma_sig <- foreach(i = seq_along(res$limma_significant)) %do% {
    return(res$limma_significant[[i]] %>% rownames_to_column(var = 'feature'))
}; names(limma_sig) <- names(res$limma_significant)
write.xlsx(limma_sig, here('figures', 'LimmaDA', 'ASV', 'limma_DA_significant.xlsx'))
```

## Rights

- Copyright ©️ 2024 Mucosal Immunology Lab, Monash University, Melbourne, Australia.
- Licence: This software is provided under the MIT license.
- Authors: M. Macowan

!!! info ""

    - **limma**: Ritchie ME, Phipson B, Wu D, Hu Y, Law CW, Shi W, Smyth GK (2015). "limma powers differential expression analyses for RNA-sequencing and microarray studies." Nucleic Acids Research, 43(7), e47. doi:10.1093/nar/gkv007.
    - **ggplot2**: Wickham H (2016). ggplot2: Elegant Graphics for Data Analysis. Springer-Verlag New York. ISBN 978-3-319-24277-4, https://ggplot2.tidyverse.org.
    - **ggpubr**: Kassambara A (2023). ggpubr: 'ggplot2' Based Publication Ready Plots. R package version 0.6.0, https://rpkgs.datanovia.com/ggpubr/.
    - **ggrepel**: Slowikowski K (2024). ggrepel: Automatically Position Non-Overlapping Text Labels with 'ggplot2'. https://ggrepel.slowkow.com/, https://github.com/slowkow/ggrepel.
    - **ggtree**: Yu, G., Smith, D.K., Zhu, H., Guan, Y. and Lam, T.T.-Y. (2017), ggtree: an r package for visualization and annotation of phylogenetic trees with their covariates and other associated data. Methods Ecol Evol, 8: 28-36. https://doi.org/10.1111/2041-210X.12628
    - **biomformat**: McMurdie PJ, Paulson JN (2025). biomformat: An interface package for the BIOM file format. doi:10.18129/B9.bioc.biomformat, R package version 1.36.0, https://bioconductor.org/packages/biomformat.
    - **tidyverse**: Wickham H, Averick M, Bryan J, Chang W, McGowan LD, François R, Grolemund G, Hayes A, Henry L, Hester J, Kuhn M, Pedersen TL, Miller E, Bache SM, Müller K, Ooms J, Robinson D, Seidel DP, Spinu V, Takahashi K, Vaughan D, Wilke C, Woo K, Yutani H (2019). “Welcome to the tidyverse.” Journal of Open Source Software, 4(43), 1686. doi:10.21105/joss.01686.
    - **phyloseq**: McMurdie and Holmes (2013) phyloseq: An R Package for Reproducible Interactive Analysis and Graphics of Microbiome Census Data. PLoS ONE. 8(4):e61217
    - **SummarizedExperiment**: Morgan M, Obenchain V, Hester J, Pagès H (2025). SummarizedExperiment: A container (S4 class) for matrix-like assays. doi:10.18129/B9.bioc.SummarizedExperiment, R package version 1.38.1, https://bioconductor.org/packages/SummarizedExperiment.
    - **edgeR**: Chen Y, Chen L, Lun ATL, Baldoni P, Smyth GK (2025). “edgeR v4: powerful differential analysis of sequencing data with expanded functionality and improved support for small counts and larger datasets.” Nucleic Acids Research, 53(2), gkaf018. doi:10.1093/nar/gkaf018.
    - **here**: Müller K (2025). here: A Simpler Way to Find Your Files. R package version 1.0.1, https://here.r-lib.org/.
    - **stringr**: Wickham H (2023). stringr: Simple, Consistent Wrappers for Common String Operations. R package version 1.5.1, https://github.com/tidyverse/stringr, https://stringr.tidyverse.org.
    - **stringdist**: van der Loo M (2014). “The stringdist package for approximate string matching.” The R Journal, 6, 111-122. https://CRAN.R-project.org/package=stringdist.
    - **ggbeeswarm**: Clarke, E., Sherrill-Mix, S., & Dawson, C. (2023). ggbeeswarm: Categorical Scatter (Violin Point) Plots. R package version 0.7.2. CRAN.
    - **doParallel**: Corporation M, Weston S (2022). doParallel: Foreach Parallel Adaptor for the 'parallel' Package. R package version 1.0.17. https://CRAN.R-project.org/package=doParallel