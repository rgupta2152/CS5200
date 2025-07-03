
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


# References:

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

dbExecute(dbcon, "
  CREATE TABLE IF NOT EXISTS Visits (
    VisitID             INTEGER           PRIMARY KEY,
    RestaurantID        INTEGER           NOT NULL,
    ServerAssignmentID  INTEGER           NULL,
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

# CustomerPhone is inputted as a 

dropRestaurants <- dbExecute(dbcon, "DROP TABLE IF EXISTS Restaurants")

loyaltyCustomers <- dbExecute(dbcon, "
  CREATE TABLE IF NOT EXISTS LoyaltyCustomers (
    CustomerID INTEGER PRIMARY KEY AUTO_INCREMENT,
    CustomerEmail TEXT NOT NULL UNIQUE,
    CustomerPhone TEXT NOT NULL,
    CustomerName     VARCHAR(100)  NOT NULL
  );
")



# --- MealTypes ---

dropRestaurants <- dbExecute(dbcon, "DROP TABLE IF EXISTS Restaurants")

mealTypes <- dbExecute(dbcon, "
  CREATE TABLE IF NOT EXISTS MealTypes (
    MealTypeID       INTEGER           AUTO_INCREMENT PRIMARY KEY,
    MealType         VARCHAR(20)   NOT NULL UNIQUE
  );
")



# --- PaymentMethods ---

dropRestaurants <- dbExecute(dbcon, "DROP TABLE IF EXISTS Restaurants")

paymentMethods <- dbExecute(dbcon, "
  CREATE TABLE IF NOT EXISTS PaymentMethods (
    PaymentMethodID  INTEGER           AUTO_INCREMENT PRIMARY KEY,
    MethodType       VARCHAR(50)   NOT NULL UNIQUE
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
    CONSTRAINT gender_check
      CHECK (Gender IN ('m', 'f', 'n', 'u'))
  );
")




# DISCONNECT FROM DB ------------------------------------------------------

dbDisconnect(dbcon)
