add_lmsd <- function(metab_SE, lmsd, mass_tol = 0.002, cores = NA) {
  # Load required packages
  pkgs <- c('foreach', 'doParallel', 'data.table', 'tidyverse', 'SummarizedExperiment', 'S4Vectors', 'doSNOW')
  for (pkg in pkgs) {
    suppressPackageStartupMessages(library(pkg, character.only = TRUE))
  }
  # Define adduct masses for correction
  adduct_name <- c('[M+H]+', '[M+NH4]+', '[M+Na]+', '[M+CH3OH+H]+', '[M+K]+', '[M+Li]+', 
                   '[M+ACN+H]+', '[M+H-H2O]+', '[M+H-2H2O]+', '[M+2Na-H]+', '[M+IsoProp+H]+', 
                   '[M+ACN+Na]+', '[M+2K-H]+', '[M+DMSO+H]+', '[M+2ACN+H]+', '[M+IsoProp+Na+H]+', 
                   '[M-C6H10O4+H]+', '[M-C6H10O5+H]+', '[M-C6H8O6+H]+', '[2M+H]+', '[2M+NH4]+', 
                   '[2M+Na]+', '[2M+3H2O+2H]+', '[2M+K]+', '[2M+ACN+H]+', '[2M+ACN+Na]+', 
                   '[M+2H]2+', '[M+H+NH4]2+', '[M+H+Na]2+', '[M+H+K]2+', '[M+ACN+2H]2+', 
                   '[M+2Na]2+', '[M+2ACN+2H]2+', '[M+3ACN+2H]2+', '[M+3H]3+', '[M+2H+Na]3+', 
                   '[M+H+2Na]3+', '[M+3Na]3+', '[M-H]-', '[M-H2O-H]-', '[M+Na-2H]-', '[M+Cl]-', 
                   '[M+K-2H]-', '[M+HCOO]-', '[M+CH3COO]-', '[M+C2H3N+Na-2H]-', '[M+Br]-', 
                   '[M+TFA-H]-', '[M-C6H10O4-H]-', '[M-C6H10O5-H]-', '[M-C6H8O6-H]-', 
                   '[M+CH3COONa-H]-', '[2M-H]-', '[2M+FA-H]-', '[2M+Hac-H]-', '[3M-H]-', 
                   '[M-2H]2-', '[M-3H]3-', '[M]+', '[M+2NH4]2+', '[M-H2O+H]+', '[M-H-CO2]-')
  adduct_mass <- c(1.00782503207, 18.03437413, 22.9897692809, 33.03403978207, 38.96370668, 7.01600455, 
                   42.03437413207, -17.00273964793, -35.01330432793, 44.97171352973, 61.06533991207, 
                   64.0163183809, 76.91958832793, 79.02176103207, 83.06092323207, 84.05510919297, 
                   -145.05008376687, -161.04499838643, -175.02426294185, 1.00782503207, 18.03437413, 
                   22.9897692809, 56.04734410414, 38.96370668, 42.03437413207, 64.0163183809, 2.01565006414, 
                   19.04219916207, 23.99759431297, 39.97153171207, 43.04219916414, 45.9795385618, 
                   84.06874826414, 125.09529736414, 3.02347509621, 25.00541934504, 46.98736359387, 
                   68.9693078427, -1.00782503207, -19.01838971207, 20.97411921676, 34.96885268, 
                   36.94805661586, 44.997654, 59.013305, 62.00066831777, 78.9183371, 112.98503896793, 
                   -147.06573383101, -163.06064845057, -177.03991300599, 80.99524996793, -1.00782503207, 
                   44.99765396793, 59.01330396793, -1.00782503207, -2.01565006414, -3.02347509621,
                   0.0005486, 36.067646, -17.003289, -44.997106)
  names(adduct_mass) <- adduct_name
  # Set ion mass
  lmsd$EXACT_MASS <- as.numeric(lmsd$EXACT_MASS)
  Mass_db <- lmsd$EXACT_MASS
  Mass_data <- data.frame(msdial_mz = rowData(metab_SE)$`info.Average Mz`)
  Mass_data$msdial_mz <- as.numeric(Mass_data$msdial_mz)
  rownames(Mass_data) <- rownames(rowData(metab_SE))
  Mass_data$Adduct_data <- rowData(metab_SE)$`info.Adduct type`
  Mass_data$corrected_mz <- NA
  # Get masses corrected for ion precursors
  for (m in 1:nrow(Mass_data)) {
    mass_diff <- as.numeric(adduct_mass[Mass_data$Adduct_data[m]])
    Mass_data$corrected_mz[m] <- sum(Mass_data$msdial_mz[m], -mass_diff)
  }
  # See whether any adducts were not defined
  undefined <- Mass_data %>%
    filter(is.na(corrected_mz)) %>%
    pull(Adduct_data) %>% unique()
  if (length(undefined) > 0) {
    warning(paste0('The following adducts were found without a match in the look-up table: \n',
                   '    ', paste0(undefined, collapse = ', '), '\n',
                   'Their masses have been left uncorrected for the purposes of this function.'))
  }
  #setup parallel backend to use many processors
  if(is.na(cores) | cores > detectCores()){
    cores <- detectCores()
    cl <- makeCluster(cores[1]-1) #not to overload your computer
  } else {
    cl <- makeCluster(cores)
  }
  registerDoSNOW(cl)
  #Progress Bar
  iterations <- nrow(Mass_data)
  pb <- txtProgressBar(max = iterations, style = 3)
  progress <- function(n) setTxtProgressBar(pb, n)
  opts <- list(progress = progress)
  ## Compare masses corrected with lmsd "exact masses" to find annotations that are with tolerance range
  full_lmsd_ann <- foreach(n=1:nrow(Mass_data), .combine=rbind, .packages = "dplyr", .options.snow = opts) %dopar% {
    row_num <- c()
    for (m in 1:length(Mass_db)) {
      if(between(Mass_db[m], Mass_data$corrected_mz[n]-mass_tol, Mass_data$corrected_mz[n]+mass_tol)==TRUE)
        row_num <- c(row_num, m)
    }
    if(is.null(row_num)) { ## if no matches are found we want to add the data as NA
      temp <- data.frame(matrix(ncol = ncol(lmsd)))
      colnames(temp) <- colnames(lmsd)
      temp$LipidID <- rownames(Mass_data)[n]
      temp$corrected_mz <- Mass_data$corrected_mz[n]
      temp$delta <- 1 ## delta 1 = no match
    } else {
      temp <- lmsd[row_num,]
      temp$LipidID <- rownames(Mass_data)[n]
      temp$corrected_mz <- Mass_data$corrected_mz[n]
      temp$delta <- abs(Mass_data$corrected_mz[n] - lmsd$EXACT_MASS[row_num])
    }
    temp
  }
  close(pb)
  stopCluster(cl)
  
  # arrange smallest delta for each lipidID
  full_lmsd_ann <- full_lmsd_ann %>%
    arrange(delta, by_group = T) %>%
    arrange(factor(LipidID, levels = rownames(Mass_data))) # maintain original order
  
  # Remove duplicate matches for lipidID
  distinct_lmsd_ann <- full_lmsd_ann %>%
    distinct(LipidID, NAME, SYSTEMATIC_NAME, .keep_all=T)
  
  
  # Select columns of interest
  lmsd_ann_sub <- distinct_lmsd_ann[, c("LipidID","corrected_mz","delta",
                                        "NAME","SYSTEMATIC_NAME", "CATEGORY",
                                        "MAIN_CLASS","EXACT_MASS", "ABBREVIATION",
                                        "SYNONYMS","KEGG_ID","HMDB_ID", "SUB_CLASS",
                                        "CLASS_LEVEL4")]
  # Change column names
  colnames(lmsd_ann_sub) <- c("LipidID","corrected_mz","delta",
                              "LMSD_NAME","LMSD_SYSTEMATIC_NAME", "LMSD_CATEGORY",
                              "LMSD_MAIN_CLASS","LMSD_EXACT_MASS", "LMSD_ABBREVIATION",
                              "LMSD_SYNONYMS","LMSD_KEGG_ID","LMSD_HMDB_ID", "LMSD_SUB_CLASS",
                              "LMSD_CLASS_LEVEL4")
  
  # Create aggregate string of all lipid annotations for each LipidID
  sub_lmsd <- lmsd_ann_sub[, c("LipidID", "delta", "LMSD_NAME", "LMSD_SYSTEMATIC_NAME",
                               "LMSD_ABBREVIATION", "LMSD_SYNONYMS")]
  sub_lmsd$delta <- round(sub_lmsd$delta,6)
  agg_lmsd <- aggregate(. ~ LipidID, data = sub_lmsd, function(x) paste(unique(x), collapse = " ; "), na.action = na.pass)
  agg_lmsd[agg_lmsd == "NA"] <- NA
  rownames(agg_lmsd) <- agg_lmsd$LipidID
  agg_lmsd <- agg_lmsd[rownames(metab_SE),]
  
  # Select 1st lipid for multiple lipid matches (lowest delta should be at the top of list)
  top_LMSD_match <- lmsd_ann_sub %>%
    group_by(LipidID) %>%
    slice_head() %>%
    arrange(factor(LipidID, levels = rownames(Mass_data)))
  
  # Get the metabolite feature info data from SE object
  metab_info_temp <- data.frame(metab_SE@elementMetadata@listData, check.names = F, stringsAsFactors = T) %>% rownames_to_column(var = "LipidID")
  
  # Left join with to the main table using LipidID to get the correct ordering
  SE_metadata_added_lmsd <- metab_info_temp %>%
    left_join(top_LMSD_match, by = 'LipidID')
  rownames(SE_metadata_added_lmsd) <- SE_metadata_added_lmsd$LipidID
  
  lmsd_list <- list(
    "full_lmsd_ann" = distinct_lmsd_ann, ## full but with duplicates removed
    "agg_lmsd_df" = agg_lmsd,
    "metadata_lmsd_table" = SE_metadata_added_lmsd
  )
  
  return(lmsd_list)
}