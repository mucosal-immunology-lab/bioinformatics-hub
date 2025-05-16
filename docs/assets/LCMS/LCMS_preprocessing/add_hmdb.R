add_hmdb <- function(metab_SE, hmdb, mass_tol, cores) {
  pkgs <- c('foreach', 'doSNOW', 'itertools', 'dplyr', 'SummarizedExperiment', 'S4Vectors')
  pacman::p_load(char = pkgs)
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
                   '[M-2H]2-', '[M-3H]3-', '[M]+', '[M+2NH4]2+')
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
                   0.0005486, 36.067646)
  names(adduct_mass) <- adduct_name
  # Transform everything into a vector for faster looping
  hmdb$monisotopic_molecular_weight <- as.numeric(hmdb$monisotopic_molecular_weight)
  hmdb <- hmdb[!is.na(hmdb$monisotopic_molecular_weight),]
  Mass_db <- as.vector(as.numeric(hmdb$monisotopic_molecular_weight))
  KEGG_db <- as.vector(hmdb$kegg)
  Name_db <- as.vector(hmdb$name)
  HMDB_id_db <- as.vector(hmdb$accession)
  Mass_data <- as.vector(rowData(metab_SE)$`info.Average Mz`)
  Adduct_data <- rowData(metab_SE)$`info.Adduct type`
  HMDB_data <- rep(NA, length(Mass_data))
  HMDB_id <- rep(NA, length(Mass_data))
  KEGG_data <- rep(NA, length(Mass_data))
  # Get masses corrected for ion precursors
  undefined_list <- list()
  for (m in 1:length(Mass_data)) {
    if (Adduct_data[m] %in% names(adduct_mass)) {
      mass_diff <- as.numeric(adduct_mass[Adduct_data[m]])
      Mass_data[m] <- sum(Mass_data[m], -mass_diff)
    } else {
      undefined_list[[m]] <- Adduct_data[m]
      Mass_data[m] <- Mass_data[m]
    }
  }
  undefined <- unlist(undefined_list) %>% unique()
  if (length(undefined) > 0) {
    warning(paste0('The following adducts were found without a match in the look-up table: \n',
                   '    ', paste0(undefined, collapse = ', '), '\n',
                   'Their masses have been left uncorrected for the purposes of this function.'))
  }
  
  Matrix <- matrix(nrow = length(Mass_db), ncol = length(Mass_data))
  rownames(Matrix) <- Mass_db
  colnames(Matrix) <- Mass_data
  #Setup clusters
  cores=cores
  cl <- makeSOCKcluster(cores)
  registerDoSNOW(cl)
  message("HMDB Annotation Starting - Get a Coffee While You Wait :)")
  start_time <- Sys.time()
  TF_DF <- foreach(i = isplitCols(Matrix, chunks=cores), .combine = "cbind", .packages = c("dplyr")#, .options.snow=opts
  ) %dopar% {
    for (n in 1:nrow(i)) {
      for (m in 1:ncol(i)) {
        i[n,m] <- between(as.numeric(rownames(i)[n]), as.numeric(colnames(i)[m])-mass_tol, as.numeric(colnames(i)[m])+mass_tol)
      }
    }
    i
  }
  end_time <- Sys.time()
  message("Minutes Taken: ", round(end_time - start_time,2))
  
  stopCluster(cl)
  
  #Make names
  for (i in c(1:ncol(TF_DF))) {
    if (sum(TF_DF[,i]*1) > 0) {
      index = which(TF_DF[,i] == T) %>% as.numeric()
      HMDB_data[i] <- paste0(Name_db[index], collapse = ';')
      HMDB_id[i] <- paste0(Name_db[index], collapse = ';')
      KEGG_data[i] <- paste0(Name_db[index], collapse = ';')
    }
  }
  # Add new information to SE experiment object
  rowData(metab_SE)$HMDB <- HMDB_data %>% dplyr::na_if(.,'')
  rowData(metab_SE)$KEGG <- KEGG_data %>% dplyr::na_if(.,'')
  rowData(metab_SE)$HMDB_accession <- HMDB_id %>% dplyr::na_if(.,'')
  return(metab_SE)
}