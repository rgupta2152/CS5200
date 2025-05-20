## HEADER ------------------------------------------------------------------

# Script Name: "DocDB-Gupta.R"
# Author: "Rohan Gupta"
# Date: May 20th, 2025

# Note: I've used similar header formats for the entire script as well as for
# each function as I learned to do in my BINF6200 course. I used ctrl+shift+R to
# create section separators

# [R Script Header Reference](https://bookdown.org/yih_huynh/Guide-to-R-Book/r-conventions.html)
# [Function Documentation Reference](https://r-pkgs.org/man.html)

# Install testing library for later in main() if not installed, then load lib
if (!requireNamespace("testthat", quietly = TRUE)) {
  install.packages("testthat")}
library(testthat)


## GLOBAL VARIABLES --------------------------------------------------------

# Create global variables for root, intake, and rejected folders
rootDir <- "orderDB" # root doc store
intakeDir <- "docTemp" # intake folder
rejectDir <- "rejected" # rejected files folder 

# I created the above folders in the console using dir.create()




## CONSTRUCT ALL FUNCTIONS -------------------------------------------------

# Create the checkFile function

#' This function checks the current file against certain conditions, making sure
#' that there are only two period separators, a correct date format, and a 
#' valid extension
#' 
#' @param fileName Name of current file
#' @return TRUE if fileName contains 2 period separators, valid date and ext
checkFile <- function(fileName) {
  
  # Correct file example for my own reference: "BristolAutomative.24-03-25.xml"
  
  # Here, since I already know the correct format for each file, I decided to
  # break each filename into the three tokens it should be checked on, split
  # by periods. 
    # I use [[1]] to return the actual character value of the first vector index
  fileComponents <- strsplit(fileName, split = "\\.")[[1]] 
  
  # Check that there are three components and therefore two period separators
  if (length(fileComponents) != 3) {
    return(FALSE)
  }
  
  # Next, I need to assign vars to each fileName component
  orderDate <- fileComponents[2]
  ext <- fileComponents[3]
  
  # Now I need to check the conditions for each component
  
  # Check that the date is valid and follows DD-MM-YY format
    # [as.Date format reference](https://campus.datacamp.com/courses/intermediate-r/chapter-5-utilities?ex=14) 
  # as.Date() attempts to format the orderDate and returns NA if date is invalid
    # is.na() returns TRUE if as.Date returns an NA, meaning invalid date
    # is.na() returns FALSE if as.Date returns a valid date
  if (is.na(as.Date(orderDate, format = "%d-%m-%y"))) {
    return(FALSE)
  }
  
  # Check that the extension is correct
    # If ext is not in the vector of correct exts, return FALSE
  if (!(ext %in% c("xml", "json", "csv"))) {
    return(FALSE)
  }
  
  # If the above conditions pass, we can return TRUE for the current file
  return(TRUE)
}




# Create customer name function

#' Get the customer name from a file
#' @param fileName Name of current file
#' @return Character string of the customer/client name
getCustomerName <- function(fileName) {
  
  # Repeat the component separation for this function, since the arg is
  # specified as fileName on Canvas
  fileComponents <- strsplit(fileName, split = "\\.")[[1]]
  
  # Select the client name
  customerName <- fileComponents[1]
}




# Create order date function

#' Get the order date from file
#' @param fileName: Name of current file
#' @return Character string of the order date
getOrderDate <- function(fileName) {
  # Again, repeat separation of components
  fileComponents <- strsplit(fileName, split = "\\.")[[1]]
  
  # Select the date
  orderDate <- fileComponents[2]
}




# Create the extension function
#' Get the extension type from a file
#' @param fileName: Name of current file
#' @return Character string of the file extension
getExtension <- function(fileName) {
  fileComponents <- strsplit(fileName, split = "\\.")[[1]]
  
  # Select the extension; using the same var name from checkFile func
  ext <- fileComponents[3]
}




# Create order path function

#' Generate a path to the document folder
#' @param root: Root folder for doc store 
#' @param fileName: Name of current file
#' @return Character string of the path to document folder
genOrderPath <- function(root, fileName) {
  
  # Use my previous functions to get the date and ext
  orderDate <- getOrderDate(fileName)
  ext <- getExtension(fileName)
  
  # Use file.path() to create the complete path
  orderPath <- file.path(root, orderDate, ext)
  
  # Ex: "KlainerIndustries.26-11-24.xml" -> "orderDB/26-11-24/xml"
  return(orderPath)
}




# Create store order file function 

#' Copy current file from intake dir to correct dir in docFolder
#' @param intakeFolder: Intake folder where files are being copied from
#' @param file: Name of file to be copied from intake to doc store 
#' @param docFolder: Root folder of doc store
#' @return TRUE if file has been successfully copied and checked
storeOrderFile <- function(intakeFolder, file, docFolder = "orderDB") {
  
  # Start by getting the directory path for the target dir docFolder
  # Ex: "orderDB/26-11-24/xml"
  targetFolder <- genOrderPath(docFolder, file)
  
  # Next, I need to check if the above target path exists; If the folder does
  # not exist yet, I need to create a new folder for it
  if (!dir.exists(targetFolder)) {
    # Recursively build all subdirectories for targetFolder
    dir.create(targetFolder, recursive = TRUE) 
  }
  
  # At this point, all components of the target directory have been built

  # I now need to get the file to be copied on its own
  customerName <- getCustomerName(file)
  ext <- getExtension(file)
    # Ex: "KlainerIndustries.xml"
  sourceFile <- paste0(customerName, ".", ext)
  
  # I also need the complete path of the file from the source intakeFolder
    # This is what is being copied to the target docFolder
    # Ex: "docTemp/KlainerIndustries.26-11-24.xml"
  sourcePathFull <- file.path(intakeFolder, file)
  
  # Now I need to create the full target path for docFolder, where the file
  # needs to be copied to *including the file name*
    # Ex: "orderDB/26-11-24/xml/KlainerIndustries.xml"
  targetPathFull <- file.path(targetFolder, sourceFile)
  
  # Finally, I need to copy the file from the source to the target using the
  # full paths I've just built above
  copyAttempt <- file.copy(from = sourcePathFull,
                           to = targetPathFull,
                           overwrite = TRUE)
  
  # Here, I check that the file exists, and that the size of the original source
  # file matches the size value of the copied target file
    # If...
  if (copyAttempt &&  # Copy was attempted and ...
      file.exists(targetPathFull) &&  # Target file exists and ...
      # Source file size matches target file size ...
      file.info(sourcePathFull)$size == file.info(targetPathFull)$size) {
    # ...Then, return TRUE
    return(TRUE)
  } else {
    # If the above conditions are not met, return FALSE
    return(FALSE)
  }
}




# Create store all orders function

#' Copy all files from the folder intakeFolder to the correct folder in 
#' rootFolder
#' @param intakeFolder: Intake folder where files are being copied from
#' @param rootFolder Root folder for doc store
#' @return Copies or rejects files and prints a summary of the results
storeAllOrders <- function(intakeFolder, rootFolder) {
  # In order to complete requirements 8-11 in Canvas, I need to count the
  # number of successfully copied files as well as rejected files
    # Here, I initialize a counter for the number of successes and an empty 
    # vector for the names of the rejected files
  successCount <- 0 
  rejectedFileNames <- c()
  
  
  # Next, I need to get all the files from the source folder
  sourceFiles <- list.files(intakeFolder)
  
  
  # Iterate through every file from the source
  for (file in sourceFiles) {
    # Start by getting the full source (intakeFolder) path for the current file
    sourcePathFull <- file.path(intakeFolder, file)
    
    # Check the file for correct period seps, date format, and extension
    if (checkFile(file) == TRUE) {
      # If file passes check, file can be copied to correct target directory
        # This will create the target dir if it does not yet exist
      successfulCopy <- storeOrderFile(intakeFolder,
                                       file,
                                       docFolder = rootFolder) # Returns T or F
      
      # If storeOrderFile() returns TRUE, I need to remove the source file
      if (successfulCopy == TRUE) {
        file.remove(sourcePathFull)
        # Here, I just add the successful copy to the counter
        successCount <- successCount + 1
      
        # If storeOrderfile() returns FALSE, the file did not pass the 
        # size/existence check needs to be added to the reject folder  
      } else {
        # Here I print an error about the file
        cat("Error: ", file, " failed to copy and store correctly from ", intakeDir, "to ", rootFolder, "- moved to reject folder.\n\n")
        
        # Create the reject folder if it does not yet exist
        if (!dir.exists(rejectDir)) {
          dir.create(rejectDir)
        }
        
        # Here I actually move the rejected file to the reject folder 
        file.copy(sourcePathFull, file.path(rejectDir, file), overwrite = TRUE)
        file.remove(sourcePathFull)
        # Log the rejected filename
          # c(rejectedFileNames, file) appends the current file to the current 
          # state of the vector
        rejectedFileNames <- c(rejectedFileNames, file)
      }
      
      # If checkFile fails, file was initially invalid and needs to be rejected
    } else {
      # Print the error
      cat("Error: ", file, "is invalid - moved to reject folder.\n\n")
      
      # Create the reject folder if it does not yet exist
      if (!dir.exists(rejectDir)) {
        dir.create(rejectDir)
      }
      
      # Move the file to the reject folder and delete it from the intake
      file.copy(sourcePathFull, file.path(rejectDir, file), overwrite = TRUE)
      file.remove(sourcePathFull)
      # Add to the counter 
      rejectedFileNames <- c(rejectedFileNames, file)
    }
  }

  # At this point all files from intake folder have been iterated over
  # I print the number of files that were successfully copied
  cat("Successfully processed", successCount, "files.\n\n")
  # Also print the files that were rejected/not copied
  cat("These files were not processed: \n")
  cat(paste0(rejectedFileNames, collapse = "\n")) # Just for readability
  cat("\n\n")  
}



# Create the resetDB function

#' Function to reset the root folder without deleting the folder itself
#' 
#' @param root Root folder for doc store
#' @return None, prints log that root folder has been reset
resetDB <- function(root) {
  # Assign var to all subdirs and files in the root folder
  rootToDelete <- list.files(root, 
                             full.names = TRUE, 
                             recursive = TRUE)
  
  # Remove all the above selected files
  unlink(rootToDelete, recursive = TRUE)
  # Print a message that the reset has been completed
  cat(root, "document store has reinitialized.\n\n")
}



## MAIN --------------------------------------------------------------------

# Create the main() function

#' Main function for the script.
#' 
#' First, the main runs several test cases to ensure each function works as 
#' expected. (I used the same examples given in some of the task instructions on 
#' Canvas)
#' 
#' The function then checks that the intake and root directories exist in the 
#' current location.
#' 
#' It then checks that the reject folder exists, and creates it if it does not.
#' 
#' It reinitializes the root folder before running the functions defined in 
#' the rest of the script to clear the plate completely.
#' 
#' Then, it checks and attempts to copy the files from the intake to the root
#' directory. Any file that doesn't satisfy the file conditions gets logged and
#' moved to the reject folder.
#' 
#' Finally, it lets the user know that the script is done running.
main <- function(){
  
  # I cover test cases for every function in my script before main here:
  # Starting with checkFile
    # For every test, I print to the console what the test is doing
  cat("Testing that checkFile() accepts valid and rejects invalid filenames: ")
  test_that("checkFile() accepts valid and rejects invalid filenames", {
    expect_true(checkFile("KlainerIndustries.26-11-24.xml"))
    # Incorrect number of periods 
    expect_false(checkFile("KlainerIndustries26-11-24xml"))
    # Invalid date format
    expect_false(checkFile("KlainerIndustries.2614-24.xml"))
    # Extension not in allowed list
    expect_false( checkFile("KlainerIndustries.26-11-24.pdf"))
  })
  
  
  # Test component selection functions
  cat("Testing that getCustomerName(), getOrderDate(), getExtension() correctly split filenames and select individual components: ")
  test_that("getCustomerName(), getOrderDate(), getExtension() correctly split filenames and select individual components", {
    testFileName <- "KlainerIndustries.26-11-24.xml"
    # Test customer name
    expect_equal(getCustomerName(testFileName), "KlainerIndustries")
    # Test order date
    expect_equal(getOrderDate(testFileName), "26-11-24")
    # Test extension
    expect_equal(getExtension(testFileName), "xml")
  })
  
  
  # Test genOrderPath() function
  cat("Test that genOrderPath() generates the correct doc folder path: ")
  test_that("genOrderPath() generates the correct doc folder path", {
    # I know what the expected path should be, so that is defined here
    expectedDocPath <- file.path("orderDB", "26-11-24", "xml")
    # Test the function
    resultPath <- genOrderPath("orderDB", "KlainerIndustries.26-11-24.xml")
    # Check that the expected and results are the same
    expect_equal(resultPath, expectedDocPath)
  })
  
  
  # Test storeOrderFile function
  cat("Test that storeOrderFile() correctly copies intake file into ordered folder/subfolder: ")
  test_that("storeOrderFile() correctly copies intake file into ordered folder/subfolder", {
    # Create temporary directories
    tempIntakeDir <- tempfile("intake"); dir.create(tempIntakeDir)
    tempRoot <- tempfile("root"); dir.create(tempRoot)
    
    # Create a test file in the tempIntake directory
    testfilename <- "TestFileRohan.02-15-02.xml"
    # Write some random test stuff into it
    writeLines("Test; this assignment took a long time", 
               file.path(tempIntakeDir, testfilename))
    # Run the function given the test file and directories
    trueResult <- storeOrderFile(tempIntakeDir, 
                         testfilename, 
                         docFolder = tempRoot)
    expect_true(trueResult)
    # Make sure the file exists in the correct directory and subdirectory
    expectedPath <- file.path(tempRoot, "02-15-02", "xml", "TestFileRohan.xml")
    expect_true(file.exists(expectedPath))
  })
  

  # Check that intake folder exists
  if (!dir.exists(intakeDir)) {
    stop("Error: Intake folder '", intakeDir, "' does not exist.\n")
  }
  
  # Check that root document store folder exists
  if (!dir.exists(rootDir)) {
    stop("Error: Root/document store folder '", rootDir, "' does not exist.\n")
  }
  
  # Check that the reject folder exists
  if (!dir.exists(rejectDir)) {
    # Create the reject folder if it doesn't exist
      # **I know I did this a couple times within the storeAllOrders function 
      # too, but kept that in to fulfill explicit Canvas instructions**
    dir.create(rejectDir)
    cat("Created '", rejectDir, "' folder for rejected files.\n")
  }
  
  # Reinitialized the root/document store folder without deleting it
  cat("\n\nReinitializing root before running script.\n")
  resetDB(rootDir)
  
  # Run the primary storeAllOrders() function to copy and order files
  cat("Attempting to copy files from intake folder to root document store folder:\n")
  storeAllOrders(intakeDir, rootDir)
  
  # Just a quick confirmation that the script is done copying files.
  cat("Script complete, all intake directory files iterated through.\n")
}


# Final call to main
main()