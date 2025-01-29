# Secondary MS1 feature annotation

After processing LCMS data through the MS-DIAL pipeline, secondary annotations for MS1 features can be obtained by matching mass data to external databases. 

??? question "What do you mean by MS1 data?"

    * **What is MS1 data?**
        * MS1 data represents the initial scan in mass spectrometry, where ions are detected based on their mass-to-charge ratio (m/z). It provides an overview of all molecular features in a sample, including their m/z values and intensities, enabling detection and quantification of compounds.
    * **How does that differ from MS/MS (MS2) data?**
        * While MS1 provides a broad profile of ions without structural information, MS/MS involves selecting specific ions from the MS1 scan (precursor ions), fragmenting them, and analysing the resulting product ions. This fragmentation reveals structural details, enabling precise compound identification and differentiation of isomers. 

## Secondary annotation with HMDB 📘

You should currently have a `SummarizedExperiment` object that has been pre-processed with `pmp`. The next stage is to match the MS1 mass data for each feature to the Human Metabolome Database (HMDB) database file.

!!! abstract "Prepared HMDB database file"

    Download the prepared HMDB database file in RDS format [here](../assets/LCMS/LCMS_preprocessing/hmdb_metabolites_detect_quant_v5_20231102.rds).

    * Version 5.0 (November 2023) &ndash; pre-formatted and filtered to include only annotated or documented features.

### Appending HMDB annotations to `SummarizedExperiment` objects

The first step is to load the formatted HMDB `data.frame` into your R session.

```r title="Load HMDB database into your R session"
# Load HMDB dataset
hmdb_df <- readRDS(here::here('hmdb', 'hmdb_metabolites_detect_quant_v5_20231102.rds'))
```

Then, using the [`add_hmdb()`](../assets/LCMS/LCMS_preprocessing/add_hmdb.R) function, we can search the HMDB annotations in the `data.frame` and add them to our `SummarizedExperiment` objects, as shown below with an example stool metabolomics object.

??? info "Parameters for `add_hmdb()`"

    | Parameter | Description |
    | --- | --- |
    | `metab_SE` | The `SummarizedExperiment` object you want to annotate with HMDB. |
    | `hmdb` | The HMDB database object. |
    | `mass_tol` | Default: `0.002` &ndash; the mass tolerance allowed for annotation. |
    | `cores` | The number of parallel processes to use if desired. |

    !!! warning "Run time"

        Running `add_hmdb()`, especially without parallel processing, can take a very long time.

!!! question "Which `SummarizedExperiment` should I use?"

    If you are using the output of the `pmp_preprocess()` function, you should extract and annotate the `glog_results`. The standard practice is to use the glog-transformed data from here on.

```r title="Add HMDB secondary annotations"
# Extract the glog data from the pmp_preprocess output
metab_stool_glog <- metab_stool_pmp$glog_results

# Search annotations in HMDB and add to the SE objects
metab_stool_glog <- add_hmdb(metab_SE = metab_stool_glog,
                             hmdb = hmdb_df, 
                             mass_tol = 0.002,
                             cores = 6)
```

## Secondary annotation with LIPID MAPS 🧈

After processing lipidomics data through MS-DIAL, you can enhance the annotations of MS1 features by leveraging the LIPID MAPS Structure Database (LMSD). At this point, you should have a `SummarizedExperiment` object containing preliminary annotations and those from the HMDB database. The next step involves matching the MS1 mass data of each feature to the entries in the LMSD database.

!!! abstract "Prepared LMSD database file"

    Download the prepared LMSD database file in RDS format [here](../assets/LCMS/LCMS_preprocessing/LMSD_231107.rds).

    * Version 2022-02-16

!!! question "Should I run this section?"

    You should definitely run this step if you have **lipidomics** data to process.
    If you are processing metabolomics data, you can skip this section.

### Appending LIPID MAPS annotations to `SummarizedExperiment` objects

The first step is to load the formatted LMSD `data.frame` into your R session.

```r title="Load LMSD database into your R session"
# Load LMSD dataset
lmsd_df <- readRDS(here::here('lmsd', 'LMSD_231107.rds'))
```

Then, using the [`add_lmsd()`](../assets/LCMS/LCMS_preprocessing/add_lmsd.R) function, we can search the LIPID MAPS annotations in the `data.frame` and add them to our `SummarizedExperiment` objects, as shown below with an example stool metabolomics object.

??? info "Parameters for `add_lmsd()`"

    | Parameter | Description |
    | --- | --- |
    | `metab_SE` | The `SummarizedExperiment` object you want to annotate with HMDB. |
    | `lmsd` | The LMSD database object. |
    | `mass_tol` | Default: `0.002` &ndash; the mass tolerance allowed for annotation. |
    | `cores` | The number of parallel processes to use if desired. |

    !!! warning "Run time"

        Running `add_lmsd()`, especially without parallel processing, can take a very long time.

```r
# Search annotations in LMSD and add to the SE objects
# Create list for all distinct Lipid Maps matching mz in tolerance range 0.002, an aggregated df of distinct lipids and a df to replace SummarizedExperiment metadata [rowData(metab_glog)]
lmsd_ann_list <- add_lmsd(metab_SE = metab_stool_glog, 
                          lmsd = lmsd_df, 
                          mass_tol = 0.002,
                          cores = 6) 

# Use metadata_lmsd_table to replace the existing SE object metadata
rowData(metab_stool_glog) <- lmsd_ann_list$metadata_lmsd_table
```

## Comparing annotations from different databases ⚖️📚

To compare the assigned annotations from each of the methods the [compare_annotations_SE()](../assets/LCMS/LCMS_preprocessing/compare_annotations_SE.R) function. It will produce a `data.frame` containing only features with at least one annotation, and allow us see whether the annotations typically agree with each other.

??? info "Parameters for `compare_annotations_SE()`"

    | Parameter | Description |
    | --- | --- |
    | `metab_SE` | The `SummarizedExperiment` object with secondary annotations. These should include HMDB for metabolomics data, and both HMDB **and** LMSD for lipidomics data. |
    | `mode` | Either `'metabolomics'` or `'lipidomics'` depending on your dataset. |
    | `agg_lmsd_ann` | The aggregated LMSD annotations you generated using the `add_lmsd()` function, i.e. `lmsd_ann_list$agg_lmsd_df`. **Only required for `mode` = `'lipidomics'`** |

=== "Metabolomics"

    ```r title="Compare metabolite annotations"
    # Prepare data.frame with alignment IDs and annotations, and filter for at least one annotation
    anno_df_metab <- compare_annotations_SE(metab_SE = metab_stool_glog,
                                            mode = 'metabolomics')
    ```

=== "Lipidomics"

    ```r title="Compare lipid annotations"
    # Prepare data.frame with alignment IDs and annotations, and filter for at least one annotation
    anno_df_lipid <- compare_annotations_SE(metab_SE = lipid_stool_glog,
                                            mode = 'lipidomics',
                                            agg_lmsd_ann = lmsd_ann_list$agg_lmsd_df)
    ```

## Keeping only annotated features 🏷️✅

From here, we can filter our `SummarizedExperiment` object for features with at least one annotation.
While the other features likely represent interesting metabolites and lipids, without an available annotation, they won't be interpretable downstream.

We can achieve this providing our `SummarizedExperiment` object to the [`keep_annotated_SE()`](../assets/LCMS/LCMS_preprocessing/keep_annotated_SE.R) function, which will output a filtered `SummarizedExperiment` object.

??? info "Parameters for `keep_annotated_SE()`"

    | Parameter | Description |
    | --- | --- |
    | `metab_SE` | The `SummarizedExperiment` object with secondary annotations. These should include HMDB for metabolomics data, and both HMDB **and** LMSD for lipidomics data. |
    | `mode` | Either `'metabolomics'` or `'lipidomics'` depending on your dataset. |

=== "Metabolomics"

    The function will create a new `rowData` element called `shortname`, and also assign this value as the preferred row name.

    * It uses the following naming hierarchy to decide an appropriate name: HMDB > MS-DIAL.

    ```r title="Remove unannotated features"
    # Keep only annotated rows and generate shortname column
    metab_stool_glog <- keep_annotated(metab_SE = metab_stool_glog,
                                       mode = 'metabolomics')
    
    # Save the object
    saveRDS(metab_stool_glog, here('output', '01_Preprocessing', 'metab_stool_glog_anno.rds'))
    ```

    !!! question "Are the other annotations still there?"

        Yes! While the shorter names are succinct and useful for plotting, you can view the additional annotations at any time and alter as required.

        ```r
        # Get HMDB and KEGG annotations
        hmdb_annotations <- rowData(metab_stool_glog)$HMDB
        kegg_annotations <- rowData(metab_stool_glog)$KEGG
        ```

=== "Lipidomics"

    The function will create a new `rowData` element called `shortname`, and also assign this value as the preferred row name.

    * It uses the following naming hierarchy to decide an appropriate name: MS-DIAL > LMSD > HMDB.
    * MS-DIAL has its own lipid database that is effective and, because it can also utilise MS/MS data in its annotations, is preferred here.

    ```r title="Remove unannotated features"
    # Keep only annotated rows and generate shortname column
    lipid_stool_glog <- keep_annotated(metab_SE = lipid_stool_glog,
                                       mode = 'lipidomics')

    # Save the object
    saveRDS(lipid_stool_glog, here('output', '01_Preprocessing', 'lipid_stool_glog_anno.rds'))
    ```

    !!! question "Are the other annotations still there?"

        Yes! While the shorter names are succinct and useful for plotting, you can view the additional annotations at any time and alter as required.

        ```r
        # Get HMDB and KEGG annotations
        hmdb_annotations <- rowData(lipid_stool_glog)$HMDB
        kegg_annotations <- rowData(lipid_stool_glog)$KEGG
        ```

## Next steps ➡️

You now have a normalised, imputed, dataset that has undergone secondary annotation and been filtered for annotated features.
It is now time to proceed to [manual curation of the annotated spectra](./manual-peak-curation.md).

## Rights

* Copyright ©️ 2024 Mucosal Immunology lab, Monash University, Melbourne, Australia.
* [HMDB version 5.0](https://pubmed.ncbi.nlm.nih.gov/34986597/): Wishart DS, Guo A, Oler E, Wang F, Anjum A, Peters H, Dizon R, Sayeeda Z, Tian S, Lee BL, Berjanskii M. HMDB 5.0: the human metabolome database for 2022. *Nucleic acids research*. 2022 Jan 7;50(D1):D622-31.
* License: This pipeline is provided under the MIT license.
* Authors: M. Macowan and C. Pattaroni