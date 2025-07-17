# HEADER ------------------------------------------------------------------

# Script: Create the DB
# Author: Rohan Gupta
# Date: Summer Full 2025




# GET CLEAN DF ------------------------------------------------------------

# This is the same EXACT SAME CODE from loadDB (Part E) to be able to get the
# original df in a processed and clean format to match the db:


# Load the original df
df <- read.csv("https://s3.us-east-2.amazonaws.com/artificium.us/datasets/restaurant-visits-139874.csv")

# Handle empty string and incorrect NA's across the entire df
for (col in 1:ncol(df)) {
  
  # Here, I'm handling the most context-independent conversions to NA, meaning
  # that these conversions to proper NAs need to happen across the entire df,
  # not just in specific cols
  df[, col][df[, col] == "N/A"] <- NA
  df[, col][df[, col] == ""] <- NA
}

# Here, I'm looking to target just the cols where char values need to be
# converted to DATE types; since I'm modeling this script on the data, I can
# select the target cols directly
dateCols <- c("StartDateHired", "EndDateHired", "ServerBirthDate", "VisitDate")

for (col in dateCols) {
  
  df[, col][df[, col] == "0000-00-00"] <- NA
  df[, col][df[, col] == "9999-99-99"] <- NA
  
}

# The WaitTime col holds negative values, which I am going to assume are either
# misinputs or genuine zero wait placeholders. I'll replace these with NA
df$WaitTime[df$WaitTime < 0 ] <- NA

# sentinel values of 99 as a placeholder for (I assume)
# unknown party sizes. Also convert to NA
df$PartySize[df$PartySize == 99] <- NA

# The 0 values here represent servers without any information, probably that
# have been let go or removed from the db but their visit info still exists
df$HourlyRate[df$HourlyRate == 0] <- NA

# Conversion to type TIME; here, each val in the col gets parsed as an
# hour:min format and converted to one with hour:min:sec for SQL
df$VisitTime <- format(
  strptime(df$VisitTime, "%H:%M"),
  "%H:%M:%S"
)

# The orderedAclohol col needs to be converted into a BOOLEAN per my db design
df$orderedAlcohol <- ifelse(df$orderedAlcohol == "yes", TRUE, FALSE)

# Convert the date cols to DATE type
dateCols <- c("StartDateHired", "EndDateHired", "ServerBirthDate", "VisitDate")

for (col in dateCols) {
  
  df[, col] <- as.Date(df[, col], format = "%Y-%m-%d")
  
}

# I had too many issues with this hyphen, so I removed it from the col
df$MealType[df$MealType == "Take-Out" ] <- "TakeOut"



# CONNECT TO DB -----------------------------------------------------------

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




# TEST DATA LOADING WITH QUERIES ------------------------------------------


# Starting the comparisons of unique values within features for both the local
# csv and the DB:


# Here, I get all the required counts from the local csv version of the df as a
# named vector
csvCounts <- c(
  Restaurants = length(unique(df$Restaurant)),
  LoyaltyCustomers = length(unique(df$CustomerEmail[df$LoyaltyMember == TRUE])),
  Servers = length(unique(na.omit(df$ServerEmpID))),
  Visits = nrow(df)
)

# This vector contains the results of each count query; I set the count col as
# "n" to easily select the value itself instead of returning back an entire
# table
dbCounts <- c(
  Restaurants = dbGetQuery(dbcon, "SELECT COUNT(*) AS n FROM Restaurants")$n,
  LoyaltyCustomers = dbGetQuery(dbcon, "SELECT COUNT(*) AS n FROM LoyaltyCustomers")$n,
  Servers = dbGetQuery(dbcon, "SELECT COUNT(*) AS n FROM Servers")$n,
  Visits = dbGetQuery(dbcon, "SELECT COUNT(*) AS n FROM Visits")$n
)

# Everything put together to compare easily in a results df
countResults <- data.frame(
  Table = names(csvCounts),
  CSV_Count = as.integer(csvCounts),
  DB_Count = as.integer(dbCounts)
)
countResults



# Next, I'll get the totals for food, alcohol, and tips:

# NOTE: I've computed just the totals for EACH of these columns instead of
# accounting for discounts and tip amounts due to the wording of the question.
# These sums will regardless let me know if those computations would be the same
# between the db and the csv df

# Get the totals from the csv df excluding NA values as a named vector
csvTotals <- c(
  FoodBill = sum(df$FoodBill, na.rm = TRUE),
  AlcoholBill = sum(df$AlcoholBill, na.rm = TRUE),
  TipAmount = sum(df$TipAmount, na.rm = TRUE)
)

# Query to get the same totals from the db
dbTotalsQuery <- dbGetQuery(dbcon, "
  SELECT
    SUM(FoodBill) AS FoodBill,
    SUM(AlcoholBill) AS AlcoholBill,
    SUM(TipAmount) AS TipAmount
  FROM Visits
")

# The query above returns a single row dataframe, so I need to convert that into
# a named vector as well
# Get the totals as their own vector
dbTotals <- as.numeric(dbTotalsQuery[1, ])
# And name them
names(dbTotals) <- names(dbTotalsQuery)


# Put together the final table to compare
sumsResults <- data.frame(
  Table = names(csvTotals),
  CSV_Totals = csvTotals,
  DB_Totals = dbTotals
)
sumsResults



# We can see from both the result dfs from above that the DB and the local df
# resulted in the exact same values. This segment actually helped me see that
# some of the types I had set when creating the db were incorrect and were
# cutting off decimal values


# DISCONNECT FROM DB ------------------------------------------------------

# Disconnect
dbDisconnect(dbcon)
