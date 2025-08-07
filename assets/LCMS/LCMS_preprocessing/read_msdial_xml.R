# Function to read MS-DIAL XML and extract peak information
read_msdial_xml <- function(curation_table = NULL, path_to_folder = NULL, 
                            experiment_name = NULL, ionisation = c("pos", "neg")) {
  
  # Load required libraries
  load_libraries <- function(packages) {
    for (pkg in packages) {
      tryCatch({
        library(pkg, character.only = TRUE)
      }, error = function(e) {
        message("The '", pkg, "' package is not installed or could not be loaded.")
        message("Please install it by running: install.packages('", pkg, "')")
        stop(e)  # Halt execution if a package fails to load
      })
    }
  }
  
  # Load necessary libraries
  load_libraries(c("xml2", "data.table", "dplyr", "stringr", "here"))
  
  combined_list <- list()  # Initialize a list to store peak data
  
  # Loop through each ionisation mode
  for (ion in ionisation) {
    tryCatch({
      xml_path <- here(path_to_folder, paste0(experiment_name, "_", ion, "_tags.xml"))
      xml_Annotated <- read_xml(xml_path)
    }, error = function(msg) {
      message("XML files are not correctly formatted.")
      message("Ensure the following transformations have been applied programmatically.")
      stop(msg)  # Halt if XML reading fails
    })
    
    rows <- xml_Annotated %>% xml_find_all('//Peaks')
    ids <- xml_contents(rows) %>% xml_attrs() %>% as.character()
    quality_peaks <- xml_contents(rows) %>% as.character() %>% as.list()
    
    peak_data <- data.frame(
      ids = paste0(ids, "_", str_to_lower(ion)),
      Anno1 = FALSE, Anno2 = FALSE, Anno3 = FALSE, Anno4 = FALSE, Anno5 = FALSE
    )
    
    for (j in seq_along(quality_peaks)) {
      temp <- quality_peaks[[j]]
      str_temp <- strsplit(temp, "  ")[[1]][-1] %>%
        gsub('[[:punct:]]', '', .) %>%
        gsub('Tag', '', .) %>%
        substr(., 1, 1) %>%
        as.numeric()
      
      vec <- rep(FALSE, 5)
      vec[str_temp] <- TRUE
      peak_data[j, 2:6] <- vec
    }
    
    combined_list[[ion]] <- peak_data
  }
  
  return(do.call('rbind', combined_list))
}