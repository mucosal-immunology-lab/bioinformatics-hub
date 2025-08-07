# Define a function to compares annotations provided by different databases
compare_annotations_SE <- function(metab_SE, mode = NULL, agg_lmsd_ann = NULL) {
  # Check if mode is provided and is one of the allowed options
  allowed_modes <- c('metabolomics', 'lipidomics')
  
  if (is.null(mode) || !(mode %in% allowed_modes)) {
    stop("Please specify a valid mode. Choose either 'metabolomics' or 'lipidomics'.")
  }
  
  # =================================
  #    Define Metabolomics Method   #
  # =================================
  compare_metab_annotations <- function(metab_SE) {
    # Load packages
    pkgs <- c('data.table', 'tidyverse', 'SummarizedExperiment', 'S4Vectors')
    for (pkg in pkgs) {
      suppressPackageStartupMessages(library(pkg, character.only = TRUE))
    }
    
    # Prepare data.frame with alignment IDs and all four annotations and filter for at least one annotation
    msdial_hmdb <- data.frame('Alignment.ID' = rownames(metab_SE),
                                  'Retention.Time' = rowData(metab_SE)$`info.Average Rt(min)`,
                                  'Fill_percent' = rowData(metab_SE)$`info.Fill %`,
                                  'S/N_ratio' = rowData(metab_SE)$`info.S/N average`,
                                  'MSDIAL_annotation' = rowData(metab_SE)$`info.Metabolite name`,
                                  'HMDB_annotation' = rowData(metab_SE)$HMDB,
                                  'HMDB_accession' = rowData(metab_SE)$HMDB_accession,
                                  'KEGG_annotation' = rowData(metab_SE)$KEGG)
    msdial_gnps_hmdb <- msdial_gnps_hmdb %>%
      column_to_rownames(var = 'Alignment.ID') %>%
      mutate(MSDIAL_annotation = replace(MSDIAL_annotation, MSDIAL_annotation == 'Unknown', NA),
            KEGG_annotation= replace(KEGG_annotation, KEGG_annotation == '', NA)) %>%
      filter(!is.na(MSDIAL_annotation) | !is.na(HMDB_annotation) | !is.na(KEGG_annotation))   
    
    # Return the data.frame
    msdial_hmdb
  }

  # ===============================
  #    Define Lipidomics Method   #
  # ===============================
  compare_lipid_annotations <- function(metab_SE, agg_lmsd_ann) {
    # Check that the aggregated LMSD annotations are provided
    if (is.null(agg_lmsd_ann) {
      stop("Please provide the aggregated LMSD annotations using the add_lmsd_ann parameter.")
    }

    # Load packages
    pkgs <- c('data.table', 'tidyverse', 'SummarizedExperiment', 'S4Vectors')
    for (pkg in pkgs) {
      suppressPackageStartupMessages(library(pkg, character.only = TRUE))
    }
    
    
    # LMSD_annotation will prioritise use of LMSD_NAME,then LMSD_ABBREVIATION and lastly LMSD_SYSTEMATIC_NAME
    LMSD_ann <- data.frame("ann" = ifelse(is.na(agg_lmsd_ann$LMSD_NAME),
                                          ifelse(is.na(agg_lmsd_ann$LMSD_ABBREVIATION),
                                                ifelse(is.na(agg_lmsd_ann$LMSD_SYSTEMATIC_NAME), NA, agg_lmsd_ann$LMSD_SYSTEMATIC_NAME),
                                                agg_lmsd_ann$LMSD_ABBREVIATION),
                                          agg_lmsd_ann$LMSD_NAME))
    rownames(LMSD_ann) <- agg_lmsd_ann$LipidID
    
    # Prepare data.frame with alignment IDs and all four annotations and filter for at least one annotation
    msdial_lmsd_hmdb <- data.frame('LipidID' = rowData(metab_SE)$LipidID,
                                  'Mz' = rowData(metab_SE)$`info.Average Mz`,
                                  'RT' = rowData(metab_SE)$`info.Average Rt(min)`,
                                  'MSDIAL_annotation' = rowData(metab_SE)$`info.Metabolite name`,
                                  'LMSD_annotation' = LMSD_ann$ann,
                                  'HMDB_annotation' = rowData(metab_SE)$HMDB,
                                  'KEGG_annotation' = rowData(metab_SE)$KEGG) %>%
      mutate(MSDIAL_annotation = replace(MSDIAL_annotation, MSDIAL_annotation == 'Unknown', NA),
            KEGG_annotation= replace(KEGG_annotation, KEGG_annotation == '', NA)) %>%
      filter(!is.na(MSDIAL_annotation) | !is.na(HMDB_annotation) |
              !is.na(KEGG_annotation) | !is.na(LMSD_annotation))
    
    # Return the data.frame
    return(msdial_lmsd_gnps_hmdb)
  }

  # ============================
  #    Run the Chosen Method   #
  # ============================
  if (mode == 'metabolomics') {
    # Call compare_metab_annotations equivalent functionality
    return(compare_metab_annotations(metab_SE))
    
  } else if (mode == 'lipidomics') {
    # Call compare_lipid_annotations equivalent functionality
    return(compare_lipid_annotations(metab_SE, add_lmsd_ann))
  }
}
