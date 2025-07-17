# HEADER ------------------------------------------------------------------

# Script: Delete DB
# Author: Rohan Gupta
# Date: Summer Full 2025


# Load library
library(RMySQL)



# CONNECT TO DB -----------------------------------------------------------

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






# DELETE DB ---------------------------------------------------------------


# Start by disabling the FK checks so the Tables can be deleted without
# following a certain order
dbExecute(dbcon, "SET FOREIGN_KEY_CHECKS = 0;")


# Get the table names from the db
dbTables <- dbListTables(dbcon)

# Iterate over the table  names
for (tbl in dbTables) {
  # Create the DROP TABLE statement with the current table name
  deleteTable <- paste0("DROP TABLE IF EXISTS `", tbl, "`;")
  dbExecute(dbcon, deleteTable)
}


# Reenable the FK constraints for when I need to repopulate the table next
dbExecute(dbcon, "SET FOREIGN_KEY_CHECKS = 1;")




# DISCONNECT FROM DB ------------------------------------------------------

# Get all the currently open connections
allCons <- dbListConnections(drv = MySQL())
allCons

# Disconnect from each one
lapply(allCons, dbDisconnect)



