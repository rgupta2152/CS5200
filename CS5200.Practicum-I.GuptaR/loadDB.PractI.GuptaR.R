# HEADER ------------------------------------------------------------------

# Script: Create the DB
# Author: Rohan Gupta
# Date: Summer Full 2025

# Notes: 


# References:

# [Reference for Batch INSERTS](https://stackoverflow.com/questions/5526917/how-to-do-a-batch-insert-in-mysql)







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



# I'm more or less going to follow this order of operations in the sections
# below, separated by headers




# LOAD DATA -----------------------------------------------

# ***************CHANGE TO ONLINE CV *********!!!!!!!!!!!

# Load the original df
df.orig <- read.csv("restaurant-visits.csv")

# Practice on a smaller subset
df.test <- df.orig[1:5000, ]




# HANDLE GENERAL NAs ------------------------------------------------------


# Handle empty string and incorrect NA's across the entire df
for (col in 1:ncol(df.test)) {
  
  # Here, I'm handling the most context-independent conversions to NA, meaning
  # that these conversions to proper NAs need to happen across the entire df,
  # not just in specific cols
  df.test[, col][df.test[, col] == "N/A"] <- NA
  df.test[, col][df.test[, col] == ""] <- NA
}



# IDENTIFY & HANDLE SENTINELS ---------------------------------------------


# 

# Here, I'm looking to target just the cols where char values need to be
# converted to DATE types; since I'm modeling this script on the data, I can
# select the target cols directly
dateCols <- c("StartDateHired", "EndDateHired", "ServerBirthDate", "VisitDate")

for (col in dateCols) {
  
  # Current col as a vector
  currCol <- df.test[, col]

  df.test[, col][df.test[, col] == "0000-00-00"] <- NA
  df.test[, col][df.test[, col] == "9999-99-99"] <- NA
  
  
}


# Same for conversion to type TIME
df.test$VisitTime <- as.POSIXct(df.test$VisitTime)



as.vector(df.test[1, ])


# HANDLE SPECIFIC VALS ----------------------------------------------------


# The WaitTime col holds negative values, which I am going to assume are either
# misinputs or genuine zero wait placeholders. I'll replace these with NA

df.test$WaitTime[df.test$WaitTime > 0 ] <- NA


# The orderedAclohol col 






class(Sys.time())



currCol <- colnames(df.test)[4]

test <- (df.test[, 4] == "N/A")


vec <- c("0000-00-00", "2009-12-12")

vec[vec == "0000-00-00"] = NA

vec

vecasdate <- as.Date(vec)

class(vecasdate)

-   ServerEmpID
-   EndDateHired
-   ServerBirthDate
-   ServerTIN
-   CustomerName
-   CustomerPhone
-   CustomerEmail
-   ServerName
-   StartDateHired
-   HourlyRate
-   WaitTime












