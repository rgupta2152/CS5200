# This function will basically extrapolate everything I need from the df using
# the table name and r df
buildInsert <- function(table, df) {
  
  # Get the column names for the current passed df
  cols <- names(df)
  
  # Get the number of rows of the current df
  nrows <- nrow(df)
  
  # Initialize am empty character vector for the string version of all rows in
  # the current df
  rows <- character(nrows)
  
  # For each row in the current df...
  for (i in seq_len(nrows)) {
    
    # Initialize an empty char vector for each value in the current row; this is
    # initialized with the number of cols since that is the number of values per
    # row
    cleanVals <- character(length(cols))
    
    # Iterate over each column...
    for (j in seq_along(cols)) {
      # ... and get the actual value for the current row and column
      currentVal <- df[i, j]
      
      # Convert NA values to NULL for SQL
      if (is.na(currentVal)) {
        # Input to index j, which is the col number and therefore the index in
        # the row vector
        cleanVals[j] <- "NULL"
        
        
        # If any character strings have a single quote in it, I need to make
        # sure I input that correct and break out of the double quotes with a
        # set of singles
      } else if (is.character(currentVal)) {
        # gsub() looks for the single quote and replaces it with double singles
        # to escape them within a string in the current value
        clean <- gsub("'", "''", currentVal, fixed = TRUE)
        # Wrap the current character value in single quotes, since this is what
        # Aiven requires
        cleanVals[j] <- paste0("'", clean, "'")
        
        
        # For any logical values from the R dfs, convert them into strings that
        # will be pasted into the final row string without quotes later
      } else if (is.logical(currentVal)) {
        cleanVals[j] <- if (currentVal) "TRUE" else "FALSE"
        
        
        # Wrap the date values into strings 'YYYY-MM-DD' to be pasted into the
        # final formatted row string
      } else if ("Date" %in% class(currentVal)) {
        cleanVals[j] <- paste0("'", format(currentVal, "%Y-%m-%d"), "'")
        
        # Same as above for time type values
      } else if ("POSIXt" %in% class(currentVal)) {
        cleanVals[j] <- paste0("'", format(currentVal, "%H:%M:%S"), "'")
        
        # If the current value is not a character or logical value, convert it
        # to a string as well so it can be written into the final (VALUES)
        # formatted string
      } else {
        cleanVals[j] <- as.character(currentVal)
      }
    }
    
    # At this point, cleanVals is a vector of formatted strings that need to be
    # combined into one (VALUES) string. Here, I create the final string by
    # taking every element from cleanVals, combining it into one string
    # separated by commas, and wrapping it in parentheses
    rows[i] <- paste0("(", paste(cleanVals, collapse = ", "), ")")
  }
  
  # Finally, I build the complete INSERT statement following the format I
  # mentioned before:
  finalSqlCommand <- paste0(
    "INSERT INTO ", 
    table,
    # Specify that I am inserting values into every column of the current table
    " (", paste(cols, collapse = ", "), ") VALUES\n",
    paste(rows, collapse = ",\n"),
    ";"
  )
  
  return(finalSqlCommand)
}