## Test MySQL DB Connection
## Rohan Gupta
## June 30th, 2025

## Does not need to be submitted


library(RMySQL)


# Parameters for dbconnection
db_user <- 
db_password <- 
db_name <- 
db_host <- 
db_port <- 


# Connect to the db 
dbcon <-  dbConnect(drv = MySQL(), 
                    user = db_user, 
                    password = db_password, 
                    dbname = db_name, 
                    host = db_host, 
                    port = db_port)

# Check for valid connection
dbIsValid(dbcon)

# Disconnect
dbDisconnect(dbcon)





# References:

# [Reference for Connecting to MySQL DB](https://stackoverflow.com/questions/50544230/connecting-to-mysql-from-r)
# [Reference for Checking DB Connection](https://stackoverflow.com/questions/41848862/how-to-check-if-the-connection-to-mysql-through-rmysql-persists-or-not)