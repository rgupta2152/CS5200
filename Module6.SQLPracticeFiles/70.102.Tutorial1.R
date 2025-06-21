## HEADER ------------------------------------------------------------------

# Script Name: "Module 6: Tutorial 1"
# Author: "Rohan Gupta"
# Date: June 10th, 2025



## CONNECT TO DB AND QUERY -------------------------------------------------

library(DBI)
library(RSQLite)


dbcon <- dbConnect(SQLite(), dbname = "AssetDB.db")