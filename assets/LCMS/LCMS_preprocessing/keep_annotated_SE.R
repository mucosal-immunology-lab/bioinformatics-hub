# Define a function to keep only annotated features
keep_annotated_SE <- function(metab_SE, mode = NULL) {
  # Check if mode is provided and is one of the allowed options
  allowed_modes <- c('metabolomics', 'lipidomics')
  
  if (is.null(mode) || !(mode %in% allowed_modes)) {
    stop("Please specify a valid mode. Choose either 'metabolomics' or 'lipidomics'.")
  }
  
  # =================================
  #    Define Metabolomics Method   #
  # =================================
  keep_annotated_met <- function(metab_SE) {
    # Load necessary libraries with error handling
    tryCatch({
      library(stringr)
      library(dplyr)  # For case_when()
    }, error = function(e) {
      stop("One or more required packages ('stringr', 'dplyr') are not installed. 
         Please install them by running: install.packages(c('stringr', 'dplyr'))")
    })
    
    # 1. Keep only rows with valid annotations
    metab_SE <- metab_SE[
      (!is.na(rowData(metab_SE)$HMDB) | 
         (!is.na(rowData(metab_SE)$`info.Metabolite name`) & 
            rowData(metab_SE)$`info.Metabolite name` != 'Unknown')), ]
    
    # 2. Create an 'ionisation' variable from row names
    rowData(metab_SE)$ionisation <- gsub('\\d*_(pos|neg)', '\\1', rownames(metab_SE))
    
    # 3. Initialize 'shortname' with NA
    rowData(metab_SE)$shortname <- NA_character_
    
    # 4. Populate 'shortname' with priority: info.Metabolite name > HMDB > GNPS (if available)
    rowData(metab_SE)$shortname <- case_when(
      # First preference: info.Metabolite name, if valid and not 'Unknown'
      !is.na(rowData(metab_SE)$`info.Metabolite name`) & 
        rowData(metab_SE)$`info.Metabolite name` != 'Unknown' ~ 
        rowData(metab_SE)$`info.Metabolite name`,
      
      # Second preference: HMDB, if info.Metabolite name is NA or 'Unknown'
      !is.na(rowData(metab_SE)$HMDB) ~ rowData(metab_SE)$HMDB,
      
      # Default to NA if the column 'compound_name_gnps' does not exist
      TRUE ~ NA_character_
    )
    
    # 5. If 'compound_name_gnps' exists, update 'shortname' where it is still NA
    if ("compound_name_gnps" %in% colnames(rowData(metab_SE))) {
      idx <- is.na(rowData(metab_SE)$shortname) & !is.na(rowData(metab_SE)$compound_name_gnps)
      rowData(metab_SE)$shortname[idx] <- rowData(metab_SE)$compound_name_gnps[idx]
    }
    
    # 6. Define patterns to remove from 'shortname'
    patterns <- c('w/o MS2:', '; LC-ESI-QQ; MS2; CE', 'no MS2:', 'low score:')
    
    # 7. Remove unwanted patterns
    rowData(metab_SE)$shortname <- str_replace_all(
      rowData(metab_SE)$shortname, 
      setNames(rep('', length(patterns)), patterns)
    )
    
    # 8. Trim trailing whitespace
    rowData(metab_SE)$shortname <- trimws(rowData(metab_SE)$shortname)
    
    # 9. Keep only the first name if multiple names are separated by semicolons
    rowData(metab_SE)$shortname <- gsub('([^;]*);.*', '\\1', rowData(metab_SE)$shortname)
    
    # 10. Append ionisation mode and ensure unique 'shortname' values
    rowData(metab_SE)$shortname <- make.unique(
      paste0(rowData(metab_SE)$shortname, '_', rowData(metab_SE)$ionisation)
    )
    
    # 11. Return the modified SE object
    return(metab_SE)
  }
  
  # ===============================
  #    Define Lipidomics Method   #
  # ===============================
  keep_annotated_lip <- function(lipid_SE) {
    # Load necessary libraries with error handling
    tryCatch({
      library(stringr)
      library(dplyr)  # For case_when()
    }, error = function(e) {
      stop("One or more required packages ('stringr', 'dplyr') are not installed. 
         Please install them by running: install.packages(c('stringr', 'dplyr'))")
    })
    
    # 1. Keep only rows with valid LMSD or info.Metabolite name annotations (excluding 'RIKEN')
    lipid_SE <- lipid_SE[
      (!is.na(rowData(lipid_SE)$LMSD_NAME) |
         !is.na(rowData(lipid_SE)$LMSD_SYSTEMATIC_NAME) |
         !is.na(rowData(lipid_SE)$LMSD_ABBREVIATION) |
         (!is.na(rowData(lipid_SE)$`info.Metabolite name`) & 
            rowData(lipid_SE)$`info.Metabolite name` != 'Unknown' &
            !grepl('RIKEN', rowData(lipid_SE)$`info.Metabolite name`))), ]
    
    # 2. Create an 'ionisation' variable from row names
    rowData(lipid_SE)$ionisation <- gsub('\\d*_(pos|neg)', '\\1', rownames(lipid_SE))
    
    # 3. Initialize 'shortname' with NA
    rowData(lipid_SE)$shortname <- NA_character_
    
    # 4. Populate 'shortname' with priority: info.Metabolite name > LMSD > HMDB > GNPS
    rowData(lipid_SE)$shortname <- case_when(
      # First preference: info.Metabolite name, excluding 'Unknown' and 'RIKEN'
      !is.na(rowData(lipid_SE)$`info.Metabolite name`) &
        rowData(lipid_SE)$`info.Metabolite name` != 'Unknown' &
        !grepl('RIKEN', rowData(lipid_SE)$`info.Metabolite name`) ~ rowData(lipid_SE)$`info.Metabolite name`,
      
      # Second preference: LMSD annotations
      !is.na(rowData(lipid_SE)$LMSD_ABBREVIATION) ~ rowData(lipid_SE)$LMSD_ABBREVIATION,
      !is.na(rowData(lipid_SE)$LMSD_NAME) ~ rowData(lipid_SE)$LMSD_NAME,
      !is.na(rowData(lipid_SE)$LMSD_SYSTEMATIC_NAME) ~ rowData(lipid_SE)$LMSD_SYSTEMATIC_NAME,
      
      # Third preference: HMDB
      !is.na(rowData(lipid_SE)$HMDB) ~ rowData(lipid_SE)$HMDB,
      
      # Default to NA
      TRUE ~ NA_character_
    )
    
    # 5. If 'compound_name_gnps' exists, update 'shortname' where it is still NA
    if ("compound_name_gnps" %in% colnames(rowData(lipid_SE))) {
      idx <- is.na(rowData(lipid_SE)$shortname) & !is.na(rowData(lipid_SE)$compound_name_gnps)
      rowData(lipid_SE)$shortname[idx] <- rowData(lipid_SE)$compound_name_gnps[idx]
    }
    
    # 6. Define patterns to remove from 'shortname'
    patterns <- c('w/o MS2:', '; LC-ESI-QQ; MS2; CE', 'no MS2:', 'low score:')
    
    # 7. Remove unwanted patterns from 'shortname'
    for (pattern in patterns) {
      rowData(lipid_SE)$shortname <- gsub(pattern, '', rowData(lipid_SE)$shortname)
    }
    
    # 8. Trim shortname after "|" but preserve oxides
    rowData(lipid_SE)$shortname <- gsub('\\|.*', '', rowData(lipid_SE)$shortname)
    
    # 9. Remove leftover trailing whitespace
    rowData(lipid_SE)$shortname <- trimws(rowData(lipid_SE)$shortname)
    
    # 10. Add the ionisation mode, and then make names unique
    rowData(lipid_SE)$shortname <- make.unique(paste(rowData(lipid_SE)$shortname,
                                                     rowData(lipid_SE)$ionisation,
                                                     sep = '_'))
    
    # Return the updated SE object
    return(lipid_SE)
  }
  
  # ============================
  #    Run the Chosen Method   #
  # ============================
  if (mode == 'metabolomics') {
    # Call keep_annotated_met equivalent functionality
    return(keep_annotated_met(metab_SE))
    
  } else if (mode == 'lipidomics') {
    # Call keep_annotated_lip equivalent functionality
    return(keep_annotated_lip(metab_SE))
  }
}