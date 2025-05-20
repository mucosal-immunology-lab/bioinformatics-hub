# Function to generate a curation table
make_curation_table <- function(metab_SE) {
  # Load required packages
  pkgs <- c('data.table', 'tidyverse', 'SummarizedExperiment', 'S4Vectors', 'readr')
  for (pkg in pkgs) {
    suppressPackageStartupMessages(library(pkg, character.only = TRUE))
  }
  
  df <- data.frame('Alignment_ID' = metab_SE@elementMetadata$`info.Alignment ID`,
                   'MZ' = metab_SE@elementMetadata$`info.Average Mz`,
                   'Metabolite_name' = metab_SE@elementMetadata$`info.Metabolite name`,
                   'Ionisation' = metab_SE@elementMetadata$ionisation,
                   'shortname' = metab_SE@elementMetadata$shortname,
                   'Fill' = metab_SE@elementMetadata$`info.Fill %`,
                   'S/N' = metab_SE@elementMetadata$`info.S/N average`)
}