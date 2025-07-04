
# HEADER ------------------------------------------------------------------

# Script: Create the DB
# Author: Rohan Gupta
# Date: Summer Full 2025


# Notes:

# Every decision I've made in this document has been explained in Part B
# submission, where I design the database. Here, I'm simply implementing those
# design decisions and the ERD I created using CREATE TABLE calls; all the
# constraints for each attribute and their default values are explained within
# my Part B .Rmd. I reiteraet a lot of those decisions here, but just thought I
# should note this so that my more in-depth thought process can be referenced
# (mostly for me when I revisit my work).

# I've also decided to add my comments for each statement above the dbExecute()
# instead of with double-dashes within the quotes, just for easier reading.



# IMPORTANT: When populating the database, I found out that I needed to be
# careful about NA vs NULL between R and MySQL. For these table creations, I'm
# keeping in mind that certain attributes with missing values in the data (or
# sentinels that I convert to missing vals later) need to be nullable. However,
# I'm going to populate the db with an *R script*, which means I need to be wary
# of the correct missing value placeholder to use. In the R script for Part E, I
# convert the sentinels to NA to follow R practices. Then, when I write my batch
# INSERTs, I convert all those NA values into NULL values, since that is the
# equivalent missing placeholder in SQL



# References:

# [Reference for NA to NULL b/w R and SQL](https://stackoverflow.com/questions/56828818/loading-na-values-from-r-to-sql)
# [Reference for Connecting to MySQL DB](https://stackoverflow.com/questions/50544230/connecting-to-mysql-from-r)
# [Reference for Checking DB Connection](https://stackoverflow.com/questions/41848862/how-to-check-if-the-connection-to-mysql-through-rmysql-persists-or-not)



# CONNECT TO DB -----------------------------------------------------------

# This is copied and pasted directly from the sandbox I created for Part A:

# Load library
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




# IMPLEMENTING DESIGN -----------------------------------------------------

# Load library
library(DBI)


# --- Restaurants ---

# For each of the tables, I've added this DROP TABLE statement to keep the
# script reproducible
dropRestaurants <- dbExecute(dbcon, "DROP TABLE IF EXISTS Restaurants")

# RestaurantID is the autoincremented surrogate, and restaurant name can't be an
# empty field (we also know its a unique value so I've added that as well)
restaurants <- dbExecute(dbcon, "
  CREATE TABLE IF NOT EXISTS Restaurants (
    RestaurantID INTEGER PRIMARY KEY AUTO_INCREMENT,
    RestaurantName TEXT NOT NULL UNIQUE
  );
")



# --- RestaurantServers ---

dropRestaurantServers <- dbExecute(dbcon, "DROP TABLE IF EXISTS RestaurantServers")

# ServerAssignmentID is the new surrogate, and since this whole table is just a
# junction to resolve a many to many, both the attributes are foreign keys to
# other entities
restaurantServers <- dbExecute(dbcon, "
  CREATE TABLE IF NOT EXISTS RestaurantServers (
    ServerAssignmentID INTEGER PRIMARY KEY AUTO_INCREMENT,
    RestaurantID INTEGER NOT NULL,
    ServerEmpID INTEGER NOT NULL,
    
    FOREIGN KEY (RestaurantID) REFERENCES Restaurants(RestaurantID),
    FOREIGN KEY (ServerEmpID)  REFERENCES Servers(ServerEmpID)
  );
")



# --- Servers ---

dropRestaurants <- dbExecute(dbcon, "DROP TABLE IF EXISTS Restaurants")


# Here, the only constraints I'm setting for two date attributes is that they
# need to be of DATE type; in my script to populate the database, I'll identify
# and handle the sentinel values

# I'll also note here that I'm letting every attribute that has a large number
# of NULL/NA values in the data be set to NOT NULL. Those null values hold
# meaning within context, and I'm building this database to model the data, so
# keeping those attributes nullable is necessary.
servers <- dbExecute(dbcon, "
  CREATE TABLE IF NOT EXISTS Servers (
    ServerEmpID INTEGER PRIMARY KEY,
    ServerName TEXT NOT NULL,
    StartDateHired DATE NOT NULL,
    EndDateHired DATE NULL,
    HourlyRate NUMERIC NOT NULL,
    ServerBirthDate DATE NULL,
    ServerTIN INTEGER NULL
  );
")



# --- Visits ---

dropRestaurants <- dbExecute(dbcon, "DROP TABLE IF EXISTS Restaurants")

# Following my db design notes, ServerAssignmentID is nullable just to accommodate takeout orders where a server is not required/recorded
dbExecute(dbcon, "
  CREATE TABLE IF NOT EXISTS Visits (
    VisitID INTEGER PRIMARY KEY,
    RestaurantID INTEGER NOT NULL,
    ServerAssignmentID INTEGER NULL,
    CustomerID          INTEGER           NULL,
    VisitDate           DATE          NOT NULL,
    VisitTime           TIME          NULL,
    MealTypeID          INTEGER           NOT NULL,
    PartySize           INTEGER           NOT NULL,
    WaitTime            INTEGER           NOT NULL,
    LoyaltyMember       BOOLEAN       NOT NULL,
    FoodBill            DECIMAL(8,2)  NOT NULL,
    TipAmount           DECIMAL(8,2)  NOT NULL,
    DiscountApplied     DECIMAL(8,2)  NOT NULL,
    PaymentMethodID     INTEGER           NOT NULL,
    OrderedAlcohol      BOOLEAN       NOT NULL,
    AlcoholBill         DECIMAL(8,2)  NOT NULL,
    
    FOREIGN KEY (RestaurantID)       REFERENCES Restaurants(RestaurantID),
    FOREIGN KEY (ServerAssignmentID) REFERENCES RestaurantServers(ServerAssignmentID),
    FOREIGN KEY (CustomerID)         REFERENCES LoyaltyCustomers(CustomerID),
    FOREIGN KEY (MealTypeID)         REFERENCES MealTypes(MealTypeID),
    FOREIGN KEY (PaymentMethodID)    REFERENCES PaymentMethods(PaymentMethodID)
  );
")



# --- LoyaltyCustomers ---

dropRestaurants <- dbExecute(dbcon, "DROP TABLE IF EXISTS Restaurants")

# CustomerPhone is inputted as type TEXT to accommodate for the format of the
# phone values in the data (since each has character parentheses around them)
loyaltyCustomers <- dbExecute(dbcon, "
  CREATE TABLE IF NOT EXISTS LoyaltyCustomers (
    CustomerID INTEGER PRIMARY KEY AUTO_INCREMENT,
    CustomerEmail TEXT NOT NULL UNIQUE,
    CustomerPhone TEXT NOT NULL,
    CustomerName TEXT NOT NULL
  );
")



# --- MealTypes ---

dropRestaurants <- dbExecute(dbcon, "DROP TABLE IF EXISTS Restaurants")

# Checking that the meal type is as expected from the levels in the data; I'm
# using Aiven so the check values need to be in single quotes
mealTypes <- dbExecute(dbcon, "
  CREATE TABLE IF NOT EXISTS MealTypes (
    MealTypeID INTEGER PRIMARY KEY AUTO_INCREMENT,
    MealType TEXT NOT NULL UNIQUE
    
    CONSTRAINT check_mealtype
      CHECK MealType IN ('Breakfast', 'Lunch', 'Dinner', 'Take-Out')
  );
")



# --- PaymentMethods ---

dropRestaurants <- dbExecute(dbcon, "DROP TABLE IF EXISTS Restaurants")

# Same as above, adding a check constraint for the payment method categories
paymentMethods <- dbExecute(dbcon, "
  CREATE TABLE IF NOT EXISTS PaymentMethods (
    PaymentMethodID INTEGER PRIMARY KEY AUTO_INCREMENT,
    MethodType TEXT NOT NULL UNIQUE
    
    CONSTRAINT check_methodtype
      CHECK MethodType IN ('Cash', 'Credit Card', 'Mobile Payment')
  );
")



# -- PartyGenders --- 

dropRestaurants <- dbExecute(dbcon, "DROP TABLE IF EXISTS Restaurants")

# This is the only place where a categorical variable isn't being handled with a
# lookup table, so I've decided to add the categorical field constraint directly
# to the Gender attribute here
dbExecute(dbcon, "
  CREATE TABLE IF NOT EXISTS PartyGenders (
    VisitID      INTEGER       NOT NULL,
    GuestNumber  INTEGER       NOT NULL,
    Gender       CHAR(1)   NOT NULL,
    
    PRIMARY KEY (VisitID, GuestNumber),
    FOREIGN KEY (VisitID) REFERENCES Visits(VisitID)
    CONSTRAINT check_gender
      CHECK (Gender IN ('m', 'f', 'n', 'u'))
  );
")




# DISCONNECT FROM DB ------------------------------------------------------

dbDisconnect(dbcon)
