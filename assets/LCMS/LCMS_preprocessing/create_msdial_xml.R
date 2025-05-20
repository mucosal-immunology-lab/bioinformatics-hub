# Function to create MS-DIAL XML with automatic text transformations
create_msdial_xml <- function(curation_table = NULL, path_to_folder = NULL, 
                              experiment_name = NULL, peak_id_column = 1, 
                              ionisation = c("pos", "neg"), force_proceed = FALSE) {
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
  
  # Loop through each ionisation mode
  for (ion in ionisation) {
    message("Creating XML for: ", experiment_name, " --- Ionisation: ", ion)
    
    # Check if a backup XML exists, halt if found and force_proceed is FALSE
    backup_path <- here(path_to_folder, paste0(experiment_name, "_", ion, "_tags_BACKUP.xml"))
    if (file.exists(backup_path) & !force_proceed) {
      stop("XML already created! DO NOT PROCEED! - See folder for edited and backup files.")
    }
    
    # Filter the curation table for the current ionisation mode
    to_check <- curation_table %>%
      filter(Ionisation == str_to_lower(ion)) %>%
      pull(peak_id_column) %>%
      gsub(paste0("_", str_to_lower(ion)), "", .) %>%
      as.numeric()
    
    # Read the original XML file
    xml_path <- here(path_to_folder, paste0(experiment_name, "_", ion, "_tags.xml"))
    xml_real <- read_xml(xml_path)
    
    # Create a backup of the original XML
    write_xml(xml_real, file = backup_path, encoding = "utf-8")
    
    # Add child nodes for each Peak ID in 'to_check'
    xml <- xml_real
    for (j in to_check) {
      parent_node <- xml_find_first(xml, "//Peaks")  # Locate parent node
      
      # Create a new 'Peak' child node with the correct 'Id' attribute
      new_child <- xml_add_child(parent_node, "Peak")
      xml_set_attr(new_child, "Id", as.character(j))  # Set the 'Id' attribute correctly
      
      # Add a 'Tag' child node with text content "1"
      tag_node <- xml_add_child(new_child, "Tag")
      xml_text(tag_node) <- "1"
    }
    
    # Convert XML to a string for text manipulation
    modified_xml <- as.character(xml)
    
    # 1. Properly escape and replace '/Peak Id.*' with '/Peak>'
    modified_xml <- gsub('/Peak\\s+Id=.*?>', '/Peak>', modified_xml, perl = TRUE)
    
    # 2. Replace '\n' with '\r\n' for correct line endings
    modified_xml <- gsub('\n', '\r\n', modified_xml, fixed = TRUE)
    
    # 3. Remove the last line break (if present)
    modified_xml <- sub('\r\n$', '', modified_xml)
    
    # Write the transformed XML back to the original file
    write(modified_xml, file = xml_path)
  }
  
  message("XML files created and transformed successfully.")
}