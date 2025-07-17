# HEADER ------------------------------------------------------------------

# Script: Load to the DB
# Author: Rohan Gupta
# Date: Summer Full 2025


# References:

# [Reference for Batch INSERTS](https://stackoverflow.com/questions/5526917/how-to-do-a-batch-insert-in-mysql)
# [Reference for Converting Char to Time in base r](https://www.r-bloggers.com/2024/05/convert-characters-to-time-in-r/)
# [Reference Confirming that I can specify explicity values for an autoincrement col](https://docs.starrocks.io/docs/sql-reference/sql-statements/table_bucket_part_index/auto_increment/#:~:text=You%20need%20to%20specify%20an,1%20for%20each%20new%20row.)
# [Reference for Changing Col Order](https://stackoverflow.com/questions/5620885/how-does-one-reorder-columns-in-a-data-frame)
# [Reference for transmute() to combine select() and mutate()](https://stackoverflow.com/questions/43375156/combine-select-and-mutate)
# [Reference for splitting Genders() values into individual elements](https://stackoverflow.com/questions/23028885/split-a-character-vector-into-individual-characters-opposite-of-paste-or-strin)



# CHECKLIST ---------------------------------------------------------------

# Since all the I've spread out the changes I need to make as the data populates
# the db between the previous files, I've created this checklist to make sure I
# don't miss any processing steps:


# 1. Identify and replace empty strings and "N/A" character strings to real NA
# values

# 2. Identify and set sentinel values to NA in R, then write them to NULL when
# being populated to the db

# 3. Take care of the types for each column; ex. change the date cols to type
# date, time to time

# 4. Change the yes/no char values from orderedAlcohol to boolean vals

# 5. When making the PartyGenders entity, focus on separating out the current
# format of the gender vals which breaks 1NF into the structure I described in
# my design (separate to atomize vals and assign to guest index from each party)

# 6. Create the columns/attributes that I've defined in the CREATE statements as
# separate R dfs which I'll use to populate the SQL db; this means for every
# table/entity in my schema, I need to create an R df
  # Here, I need to use joins carefully to make sure that I'm maintaining the
  # correct ID values for some of the entity PKs

# 7. I'm going to create a function to write an INSERT statement for each R df,
# since I can't use dbWriteTable(). This means I need to change the column names
# from the current data to the one's I've set in the schema 

# 8. dbExecute() each insert statement and make sure to change NAs from the dfs
# to NULLs






# LOAD DATA -----------------------------------------------

# Load the original df (changed to df.test once I was done testing)
df.test <- read.csv("https://s3.us-east-2.amazonaws.com/artificium.us/datasets/restaurant-visits-139874.csv",
                    stringsAsFactors = FALSE)

# Practice on a smaller subset
# df.test <- df.orig[1:5000, ]




# HANDLE GENERAL NAs ------------------------------------------------------


# Handle empty string and incorrect NA's across the entire df
for (col in 1:ncol(df.test)) {
  
  # Here, I'm handling the most context-independent conversions to NA, meaning
  # that these conversions to proper NAs need to happen across the entire df,
  # not just in specific cols
  df.test[, col][df.test[, col] == "N/A"] <- NA
  df.test[, col][df.test[, col] == ""] <- NA
}



# IDENTIFY & HANDLE SENTINELS/NAs -----------------------------------------



# --- Date Time Cols ---

# Here, I'm looking to target just the cols where char values need to be
# converted to DATE types; since I'm modeling this script on the data, I can
# select the target cols directly
dateCols <- c("StartDateHired", "EndDateHired", "ServerBirthDate", "VisitDate")

for (col in dateCols) {
  
  df.test[, col][df.test[, col] == "0000-00-00"] <- NA
  df.test[, col][df.test[, col] == "9999-99-99"] <- NA

}



# --- WaitTime ---

# The WaitTime col holds negative values, which I am going to assume are either
# misinputs or genuine zero wait placeholders. I'll replace these with NA

df.test$WaitTime[df.test$WaitTime < 0 ] <- NA




# --- PartySize ---

# The PartySize col has sentinel values of 99 as a placeholder for (I assume)
# unknown party sizes. Also convert to NA

df.test$PartySize[df.test$PartySize == 99] <- NA




# --- HourlyRate --- 

# The 0 values here represent servers without any information, probably that
# have been let go or removed from the db but their visit info still exists

df.test$HourlyRate[df.test$HourlyRate == 0] <- NA






# CONVERT TYPES -----------------------------------------------------------


# --- VisitTime --- 

# Conversion to type TIME; here, each val in the col gets parsed as an
# hour:min format and converted to one with hour:min:sec for SQL
df.test$VisitTime <- format(
  strptime(df.test$VisitTime, "%H:%M"),
  "%H:%M:%S"
)



# --- orderedAlcohol ---

# The orderedAclohol col needs to be converted into a BOOLEAN per my db design

df.test$orderedAlcohol <- ifelse(df.test$orderedAlcohol == "yes", TRUE, FALSE)



# --- Date Cols ---

# Convert the date cols to DATE type

dateCols <- c("StartDateHired", "EndDateHired", "ServerBirthDate", "VisitDate")

for (col in dateCols) {
  
  df.test[, col] <- as.Date(df.test[, col], format = "%Y-%m-%d")

}


# --- MealTypes --- 

# I had too many issues with this hyphen, so I removed it from the col
df.test$MealType[df.test$MealType == "Take-Out" ] <- "TakeOut"


# PREPARE DFs FOR INSERTION -----------------------------------------------

# At this point, the original df has been processed and is ready to be formatted
# so that it can be inserted into the db with batch inserts of values from each
# of these dfs.

# NOTES FOR AUTOINCREMENT: One of the problems I spent some time trying to
# figure out was that, since I have played AUTO-INCREMENT constraints on several
# of the surrogate ID PKs, should I handle the creation of these values within R
# or within the DB? I decided that it would be more efficient and
# straightforward to use row numbers within the dfs I create for each table in R
# and carefully join using these ID values. This means that, within R, I have
# every column preprocessed and ready to be injected into the DB. I've also kept
# the autoincrement constraint on these tables for the DB design so that when a
# new row of data is added to the table, it will be automatically assigned the
# next correct ID value.


# I also need to be deliberate in the order that I create this R dfs, since I
# need to be careful with the ID PKs and preserving the correct values across
# joins. I'll start with the tables that have no foreign keys, which are all the
# lookup tables. Then, I'll add the standalone parent tables without FKs,
# followed by the one junction and fact table, and finally the PartyGenders
# child table. This is what the entire order of operations will look like:

# Parent Lookups:
  # Restaurants
  # MealTypes
  # PaymentMethods
# Parents:
  # Servers
  # LoyaltyCustomers
# Junction:
  # RestaurantServers
# Fact:
  # Visits
# Child:
  # PartyGenders



# I'll be using the dplyr() functions to create the R dfs:



# --- Restaurants ---  

# Assigning the mutate() function to this var creates a new df, where I've
# created the ID PK by row num and renamed the Restaurant col to follow my db
# design
restaurantsdf <- df.test %>% 
  distinct(Restaurant) %>% 
  rename(RestaurantName = Restaurant) %>% 
  mutate(RestaurantID = row_number())
# Just to flip the columns so that the ID PK is the first columns
restaurantsdf <- restaurantsdf[ , c(2, 1)]


# --- MealTypes ---

# Start by getting the exact meal type characters from the df
mealTypes <- unique(df.test$MealType)

mealTypesdf <- data.frame(MealType = mealTypes) %>% 
  # Add the ID col, keep existing col
  mutate(MealTypeID = row_number())
# Flip the cols again so the PK is at the front; I'll do this for all the rest
# of the dfs
mealTypesdf <- mealTypesdf[ , c(2, 1)]



# --- PaymentMethods ---

paymentMethods <- unique(df.test$PaymentMethod)

paymentMethodsdf <- data.frame(MethodType = paymentMethods) %>% 
  mutate(PaymentMethodID = row_number())
paymentMethodsdf <- paymentMethodsdf[, c(2, 1)]





# --- Servers ---

# This is the first of the standalone parent tables I need to create (parent for
# RestaurantServers); here, the ServerEmpID is the PK and NOT NULL, so I need to
# grab all the distinct values for every attribute where a ServerEmpID exists
serversdf <- df.test %>%
  # Filter to keep rows with ServerEmpIDs
  filter(!is.na(ServerEmpID)) %>% 
  # Get all the associated attributes for these rows as groups first; this means
  # that every unique ServerEmpID has its own set of non-key attributes
  group_by(ServerEmpID) %>%
  # Then get the max hourly rate for each combination (this is to resolve an
  # instance where an employee had two different salaries)
  slice_max(HourlyRate, n = 1, with_ties = FALSE) %>% 
  # Dropping the groups returns the df into it's dataframe format
  ungroup() %>% 
  # Select just the columns of interest based on the db design
  select(ServerEmpID, ServerName, StartDateHired, EndDateHired,
         HourlyRate, ServerBirthDate, ServerTIN)




# --- LoyaltyCustomers ---

# This is the standalone parent table (no FKs) providing values for the
# customerID FK in the Visits table. Similar format as above...
loyaltyCustdf <- df.test %>%
  # Start by filtering to keep rows where the customer does have attribute data
  filter(LoyaltyMember == TRUE) %>% 
  # Then get those unique attributes
  distinct(CustomerEmail, CustomerPhone, CustomerName) %>% 
  # Add ID PK
  mutate(CustomerID = row_number())
loyaltyCustdf <- loyaltyCustdf[, c(4, 3, 2, 1)]




# --- RestaurantServers --- 

# This is the junction connecting Restaurants to Severs; this is the first place
# I need to use a join...
restaurantServersdf <- df.test %>% 
  # I first need to filter by rows where ServerEmpID exists (since this is the
  # junction connecting the two entities, meaning the FKs need to be NOT NULL)
  filter(!is.na(ServerEmpID)) %>% 
  # Select the two attribute rows...
  select(Restaurant, ServerEmpID) %>% 
  # ...and just their unique vals
  distinct() %>% 
  # Here, I'm  joining the current selection to the Restaurants df on
  # RestaurantName so I get the correct and corresponding RestaurantID values
  # for each RestaurantName
  left_join(restaurantsdf, by = c("Restaurant" = "RestaurantName")) %>% 
  # At this point, I have all the columns from both the current selection and
  # the Restaurants entity; to complete this junction, I just want to select the
  # two attributes of interest from my design
  select(RestaurantID, ServerEmpID) %>%
  # And add an ID for each combination of RestaurantID and ServerEmpID
  mutate(ServerAssignmentID = row_number())
restaurantServersdf <- restaurantServersdf[, c(3, 1, 2)]





# --- Visits --- 

# This is the main fact table, which is heavily reliant on data both from the
# original df as well as the dfs I've created to this point. I've explained what
# each of the joins actually pulls into the resulting df here, and by the end of
# the joins all the required attributes from my db design have been pulled in:

# NOTE: For the joins where I join on several columns (for restaurantServersdf
# and loyaltyCustdf), I need to do this because, when looking at the reverse
# relationship between the parent/junction, the the non-key attributes for these
# entities are really the composite key for the PK. For example, each single
# combination of customer email, phone, and id point to the one CustomerID value
# that I'm really trying to bring into this fact table


visitsdf <- df.test %>%
  # Get RestaurantsID FK from Restaurants entity
  left_join(restaurantsdf,
            by = c("Restaurant" = "RestaurantName")) %>% 
  # Get the junction table to assign data to the FK ServerAssignmentID; here, I
  # need to join on all the columns that make up the attributes for
  # ServerAssignmentID, so that this combination correctly and fully corresponds
  # to its PK ServerAssignmentID
  left_join(restaurantServersdf, 
            by = c("RestaurantID", "ServerEmpID")) %>% 
  # Get loyalty customer data for FK CustomerID; same as above, I need to join
  # on the exact combinations of non-key attributes from the LoyaltyCustomers df
  # to get complete and accurate CustomerID
  left_join(loyaltyCustdf, 
            by = c("CustomerEmail", "CustomerPhone", "CustomerName")) %>% 
  # Get mealTypeID values
  left_join(mealTypesdf, 
            by = c("MealType" = "MealType")) %>% 
  # Get PaymentMethodID values
  left_join(paymentMethodsdf, 
            by = c("PaymentMethod" = "MethodType")) %>% 
  # Select just the cols for the Visit entity
  select(
    VisitID,
    RestaurantID,
    ServerAssignmentID,
    CustomerID,
    MealTypeID,
    PaymentMethodID,
    VisitDate,
    VisitTime,
    PartySize,
    WaitTime,
    LoyaltyMember,
    FoodBill,
    TipAmount,
    DiscountApplied,
    # Also renamed this to match my db design
    OrderedAlcohol = orderedAlcohol,
    AlcoholBill
  )



# I kept running into issues with formatting in my INSERT builder, so I've
# manually converted these problematic date and time types to text types
# visitsdf$VisitDate <- as.character(visitsdf$VisitDate)
# visitsdf$VisitTime <- as.character(visitsdf$VisitTime)



# --- PartyGenders --- 

# Finally, I need to create the PartyGenders entity. This consists of three
# components I need to first get then put together in one table:
  # Individual genders per party and an assigned index
  # Number of guests per party
  # VisitID for each party

# To do this, I'll first start by splitting each of the character strings from
# the original Genders column
partyGenders <- strsplit(df.test$Genders, split = "")
# Since strsplit returns a list for each party, I can get the count for each of
# these parties in order and use them to assign guest index values for each
# gender
counts <- lengths(partyGenders)

# Now I can construct the final df...
partyGenderdf <- data.frame(
  # Here, each VisitID gets a number of rows equal to the number of
  # genders/guests in the party
  VisitID = rep(df.test$VisitID, times = counts),
  # The guest index is just a number assigned to each gender starting from 1 and
  # ending at the number of guests
  GuestNumber = sequence(counts),
  # The entire list from the strsplit() output gets converted into a single long
  # vector of strings, which is already in order corresponding to VisitID and
  # GuestNumber
  Gender = unlist(partyGenders),
  stringsAsFactors = FALSE
)

# This above method works because every attribute is NOT NULL, so the indexes
# across the three columns all line up




# CONNECT TO DB -----------------------------------------------------------

# This is copied and pasted directly from the sandbox I created for Part A:

# Load library
library(RMySQL)


# Parameters for dbconnection
db_user <- "avnadmin"
db_password <- "AVNS_t3n1vp1Ph95m4pJ3qcH"
db_name <- "defaultdb"
db_host <- "mysql-cs5200-practicum1-cs5200-practicum1-rgupta.c.aivencloud.com"
db_port <- 27986


# Connect to the db 
dbcon <-  dbConnect(drv = MySQL(), 
                    user = db_user, 
                    password = db_password, 
                    dbname = db_name, 
                    host = db_host, 
                    port = db_port)

# Check for valid connection
dbIsValid(dbcon)








# BUILD INSERT FUNCTION ---------------------------------------------------

# At this point, I have every df from my db design processed and complete. The
# next step would be to actually insert each of these dfs into the db. Since
# Aiven does not allow for dbWriteTable() functions, I'll need insert the values
# from each df individually, almost as if it is row by row. I've decided to
# implement the "batch" aspect of this process by creating a reusable function
# that takes each row of the given df, turns them into the VALUES format that
# SQL requires, and  the full SQL INSERT statement.
# Essentially, each row turns into the following format:
  # INSERT INTO [SQL table] ([Column names]) VALUES 
    # (row1col1, row1col2, etc) 
    # (row2col1, row2col2, etc)


# I'll start by building this conversion function:
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
      currentVal <- df[i, j, drop = TRUE]
      
      # Convert NA values to NULL for SQL
      if (is.na(currentVal)) {
        # Input to index j, which is the col number and therefore the index in
        # the row vector
        cleanVals[j] <- "NULL"
        
        
        # If any character strings have a single quote in it, I need to make
        # sure I input that correct and break out of the double quotes with a
        # set of singles
      } else if (is.character(currentVal) || is.factor(currentVal)) {
        # gsub() looks for the single quote and replaces it with double singles
        # to escape them within a string in the current value
        clean <- gsub("'", "''", as.character(currentVal), fixed = TRUE)
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


# POPULATE DB -------------------------------------------------------------

# Using the above function, I'll loop over each combination of SQL table name
# and R dataframe to pass into my SQL INSERT builder function, which will then
# be executed to the db

rDfs <- list(
  Restaurants = restaurantsdf,
  MealTypes = mealTypesdf,
  PaymentMethods = paymentMethodsdf,
  Servers = serversdf,
  LoyaltyCustomers = loyaltyCustdf,
  RestaurantServers = restaurantServersdf,
  Visits = visitsdf,
  PartyGenders = partyGenderdf)


# Iterate over the elements of the above named list
for (tbl in names(rDfs)) {
  
  # Get the current table name for SQL and the current full df to insert
  df <- rDfs[[tbl]] 
  
  # Added this to log which tables I was getting errors at
  message("Inserting into ", tbl, " (", nrow(df), " rows)…")
  
  # Build the sql statement
  sql <- buildInsert(tbl, df)
  
  # Execute to db 
  dbExecute(dbcon, sql)
  
}




# DISCONNECT FROM DB ------------------------------------------------------

dbDisconnect(dbcon)



