
# HEADER ------------------------------------------------------------------

# Script: Create the DB
# Author: Rohan Gupta
# Date: Summer Full 2025


# Notes:

# Every decision I've made in this document has been explained in Part B
# submission, where I design the database. Here, I'm simply implementing those
# design decisions and the ERD I created using CREATE TABLE calls; all the
# constraints for each attribute and their default values are explained within
# my Part B .Rmd. I reiterate a lot of those decisions here, but just thought I
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




# IMPLEMENTING DESIGN -----------------------------------------------------


# IMPORTANT NOTE: I needed to convert all the TEXT types from my ERD into
# VARCHAR types with some legnth after encountering the following error:
  # could not run statement: BLOB/TEXT column '...' used in key specification
  # without a key length

# I also reordered the below statements after deciding on the correct order the
# loadDB file and encountering FK constraint errors


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
    RestaurantName VARCHAR(150) NOT NULL UNIQUE
  );
")



# --- MealTypes ---

dropMealTypes <- dbExecute(dbcon, "DROP TABLE IF EXISTS MealTypes")

# Checking that the meal type is as expected from the levels in the data; I'm
# using Aiven so the check values need to be in single quotes
mealTypes <- dbExecute(dbcon, "
  CREATE TABLE IF NOT EXISTS MealTypes (
    MealTypeID INTEGER PRIMARY KEY AUTO_INCREMENT,
    MealType VARCHAR(150) NOT NULL UNIQUE,
    
    CONSTRAINT check_mealtype
      CHECK (MealType IN ('Breakfast', 'Lunch', 'Dinner', 'TakeOut'))
  );
")



# --- PaymentMethods ---

dropPayment <- dbExecute(dbcon, "DROP TABLE IF EXISTS PaymentMethods")

# Same as above, adding a check constraint for the payment method categories
paymentMethods <- dbExecute(dbcon, "
  CREATE TABLE IF NOT EXISTS PaymentMethods (
    PaymentMethodID INTEGER PRIMARY KEY AUTO_INCREMENT,
    MethodType VARCHAR(150) NOT NULL UNIQUE,
    
    CONSTRAINT check_methodtype
      CHECK (MethodType IN ('Cash', 'Credit Card', 'Mobile Payment'))
  );
")



# --- Servers ---

dropServers <- dbExecute(dbcon, "DROP TABLE IF EXISTS Servers")


# Here, the only constraints I'm setting for two date attributes is that they
# need to be of DATE type; in my script to populate the database, I'll identify
# and handle the sentinel values

# I'll also note here that I'm letting every attribute that has a large number
# of NULL/NA values in the data be set to NOT NULL. Those null values hold
# meaning within context, and I'm building this database to model the data, so
# keeping those attributes nullable is necessary.

# Numeric values from the original df with a certain number of decimals need to
# be set to type DECIMAL with that number of trailing digits specified
servers <- dbExecute(dbcon, "
  CREATE TABLE IF NOT EXISTS Servers (
    ServerEmpID INTEGER PRIMARY KEY,
    ServerName VARCHAR(150) NOT NULL,
    StartDateHired DATE NOT NULL,
    EndDateHired DATE NULL,
    HourlyRate DECIMAL(12, 2) NOT NULL,
    ServerBirthDate DATE NULL,
    ServerTIN VARCHAR(150) NULL
  );
")



# --- LoyaltyCustomers ---

dropLoyalCust <- dbExecute(dbcon, "DROP TABLE IF EXISTS LoyaltyCustomers")

# CustomerPhone is inputted as type TEXT to accommodate for the format of the
# phone values in the data (since each has character parentheses around them).
# Email is unique just based on business context

# This whole entity is for loytaly customers only, so each row needs to contain
# values for all cols; everything is set to NOT NULL
loyaltyCustomers <- dbExecute(dbcon, "
  CREATE TABLE IF NOT EXISTS LoyaltyCustomers (
    CustomerID INTEGER PRIMARY KEY AUTO_INCREMENT,
    CustomerEmail VARCHAR(150) NOT NULL UNIQUE,
    CustomerPhone VARCHAR(150) NOT NULL,
    CustomerName VARCHAR(150) NOT NULL
  );
")



# --- RestaurantServers ---

dropRestaurantServers <- dbExecute(dbcon, "DROP TABLE IF EXISTS RestaurantServers")

# ServerAssignmentID is the new surrogate, and since this whole table is just a
# junction to resolve a many to many, both the attributes are foreign keys to
# other entities
  # ServerEmpID can be NOT NULL here since its the lookup and requires a value to
  # connect the two tables; this attribute is set as NOT NULL in visits to account
  # for NA server info
restaurantServers <- dbExecute(dbcon, "
  CREATE TABLE IF NOT EXISTS RestaurantServers (
    ServerAssignmentID INTEGER PRIMARY KEY AUTO_INCREMENT,
    RestaurantID INTEGER NOT NULL,
    ServerEmpID INTEGER NOT NULL,
    
    FOREIGN KEY (RestaurantID) REFERENCES Restaurants(RestaurantID),
    FOREIGN KEY (ServerEmpID)  REFERENCES Servers(ServerEmpID)
  );
")



# --- Visits ---

dropVisits <- dbExecute(dbcon, "DROP TABLE IF EXISTS Visits")

# Following my db design notes, ServerAssignmentID is nullable just to
# accommodate takeout orders where a server is not required/recorded (and for
# other cases where a server value is missing); essentially any columns where
# values are missing in the data are nullable
dbExecute(dbcon, "
  CREATE TABLE IF NOT EXISTS Visits (
    VisitID INTEGER PRIMARY KEY,
    RestaurantID INTEGER NOT NULL,
    ServerAssignmentID INTEGER NULL,
    CustomerID INTEGER NULL,
    MealTypeID INTEGER NOT NULL,
    PaymentMethodID INTEGER NOT NULL,
    VisitDate DATE NOT NULL,
    VisitTime TIME NULL,
    PartySize INTEGER NULL,
    WaitTime INTEGER NULL,
    LoyaltyMember BOOLEAN NOT NULL,
    FoodBill DECIMAL(12, 2) NOT NULL,
    TipAmount DECIMAL(12, 2) NOT NULL,
    DiscountApplied DECIMAL(12, 2) NOT NULL,
    OrderedAlcohol BOOLEAN NOT NULL,
    AlcoholBill DECIMAL(12, 4) NOT NULL,
    
    FOREIGN KEY (RestaurantID) REFERENCES Restaurants(RestaurantID),
    FOREIGN KEY (ServerAssignmentID) REFERENCES RestaurantServers(ServerAssignmentID),
    FOREIGN KEY (CustomerID) REFERENCES LoyaltyCustomers(CustomerID),
    FOREIGN KEY (MealTypeID) REFERENCES MealTypes(MealTypeID),
    FOREIGN KEY (PaymentMethodID) REFERENCES PaymentMethods(PaymentMethodID)
  );
")



# -- PartyGenders --- 

dropGenders <- dbExecute(dbcon, "DROP TABLE IF EXISTS PartyGenders")

# This is the only place where a categorical variable isn't being handled with a
# lookup table; same format as above for the check to add the categorical field
# constraint directly to the Gender attribute
dbExecute(dbcon, "
  CREATE TABLE IF NOT EXISTS PartyGenders (
    VisitID INTEGER NOT NULL,
    GuestNumber INTEGER NOT NULL,
    Gender VARCHAR(150) NOT NULL,
    
    PRIMARY KEY (VisitID, GuestNumber),
    FOREIGN KEY (VisitID) REFERENCES Visits(VisitID),
    
    CONSTRAINT check_gender
      CHECK (Gender IN ('m', 'f', 'n', 'u'))
  );
")




# DISCONNECT FROM DB ------------------------------------------------------

dbDisconnect(dbcon)
