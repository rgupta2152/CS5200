# HEADER ------------------------------------------------------------------

# Script: Configure Business Logic
# Author: Rohan Gupta
# Date: Summer Full 2025

# [Stored Procedure Argument Parameters Reference](https://www.mysqltutorial.org/mysql-stored-procedure/stored-procedures-parameters-in-mysql/)
# [Stored Procudure Input Naming Reference](https://stackoverflow.com/questions/5039324/creating-a-procedure-in-mysql-with-parameters)
# [MySQL Continue an AutoIncrement for a new value](https://www.w3schools.com/sql/func_mysql_last_insert_id.asp)

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





# storeVisit STORED PROCEDURE ---------------------------------------------


# Start by dropping the procedure from the db if it already exists
dbExecute(dbcon, "DROP PROCEDURE IF EXISTS storeVisit;")


# For this procedure, the goal is to take in several arguments to fill in as
# values in their corresponding attributes within the db. The first part of this
# procedure is to assign parameters for the arguments in the procedure: 
  # This means that, for every input value, I need to specify a name for the input
  # value (which I've kept the same as the col it needs to go into, plus a 1 
  # added to the end) and a type constraint for that input arg

  # I've basically just copied the same exact type constraints from my createDB
  # file to these arguments to make sure everything is kept uniform and there are
  # no type confusions

# The next part of the procedure is taking this input values and actually
# storing them into their respective attributes in the db; this is all handled
# by an INSERT statement, which takes the cols for values to be stored in and
# the actual values
dbExecute(dbcon, "
  CREATE PROCEDURE storeVisit(
    IN VisitID1 INTEGER,
    IN RestaurantID1 INTEGER,
    IN ServerAssignmentID1 INTEGER,
    IN CustomerID1 INTEGER,
    IN VisitDate1 DATE,
    IN VisitTime1 TIME,
    IN MealTypeID1 INTEGER,
    IN PartySize1 INTEGER,
    IN WaitTime1 INTEGER,
    IN LoyaltyMember1 BOOLEAN,
    IN FoodBill1 DECIMAL(12, 2),
    IN TipAmount1 DECIMAL(12, 2),
    IN DiscountApplied1 DECIMAL(12, 2),
    IN PaymentMethodID1 INTEGER,
    IN OrderedAlcohol1 BOOLEAN,
    IN AlcoholBill1 DECIMAL(12, 4)
  )
  
  BEGIN
  
    INSERT INTO Visits (VisitID, RestaurantID, ServerAssignmentID, CustomerID, 
    VisitDate, VisitTime, MealTypeID, PartySize, WaitTime, LoyaltyMember, 
    FoodBill, TipAmount, DiscountApplied, PaymentMethodID, OrderedAlcohol, 
    AlcoholBill)
    
    VALUES (VisitID1, RestaurantID1, ServerAssignmentID1, CustomerID1, 
    VisitDate1, VisitTime1, MealTypeID1, PartySize1, WaitTime1, LoyaltyMember1, 
    FoodBill1, TipAmount1, DiscountApplied1, PaymentMethodID1, OrderedAlcohol1, 
    AlcoholBill1);
  END
")



# Here, I use the above stored procedure...
dbExecute(dbcon, "
  CALL storeVisit(
    1234567, 3, 2, 3, '2025-06-01', '18:30:00', 1, 4, 15, TRUE, 75.00, 12.00, 
    5.00, 2, TRUE, 20.00
  );
")

# These are some random values I've stored to the db. Next, I'll check that
# these values did actually get inputted to the Visits entity via the procedure
# by selecting rows where the VisitID is 1234567, RestaurantID value is 3, etc. 
dbGetQuery(dbcon, "
  SELECT * FROM Visits
  WHERE VisitID = 1234567;
")

# This stored procedure successfully added the inputted data to the db with the
# correct types





# storeNewVisit STORED PROCEDURE ------------------------------------------

# Drop the procedure if it exists
dbExecute(dbcon, "DROP PROCEDURE IF EXISTS storeNewVisit;")


# The first step of this procedure is exactly the same as before, but now with
# the addition of the non-key/dependent attributes for the three missing FKs for
# the Visits table.

# I can't simply pass a random PK value for server, customer, or restaurant,
# which means that I now need the stored procedure to accept the input arguments
# that will allow me to actually get OR create the PK's for these three tables.

# So, per my ERD:
  # For the RestaurantID FK in Visits, I need to be given RestaurantName
  
  # For the ServerAssignmentID FK, I need RestaurantID (which will be collected
  # from the RestaurantName input) and ServerEmpID
  
  # For the CustomerID FK, I need to be given the name email and phone attributes

dbExecute(dbcon, "
  CREATE PROCEDURE storeNewVisit(
    IN VisitID1 INT,
    IN RestaurantName1 TEXT,
    IN ServerEmpID1 INT,
    IN ServerName1 TEXT,
    IN CustomerEmail1 TEXT,
    IN CustomerName1 TEXT,
    IN CustomerPhone1 TEXT,
    IN VisitDate1 DATE,
    IN VisitTime1 TIME,
    IN MealTypeID1 INT,
    IN PartySize1 INT,
    IN WaitTime1 INT,
    IN LoyaltyMember1 BOOLEAN,
    IN FoodBill1 DECIMAL(12, 2),
    IN TipAmount1 DECIMAL(12, 2),
    IN DiscountApplied1 DECIMAL(12, 2),
    IN PaymentMethodID1 INT,
    IN OrderedAlcohol1 BOOLEAN,
    IN AlcoholBill1 DECIMAL(12, 4),
    IN HourlyRate1 DECIMAL(12, 2)
  )
  
  BEGIN

    -- Create the placeholder vars for the values of the three missing FKs from 
    -- Visits
    DECLARE varRestaurantID INT;
    DECLARE varCustomerID INT;
    DECLARE varServerAssignmentID INT;


    -- RestaurantID

      -- Get the RestaurantID value from its nonkey attribute RestaurantName
    SELECT 
      RestaurantID INTO varRestaurantID
    FROM Restaurants
    WHERE RestaurantName = RestaurantName1
    LIMIT 1;

      -- If there is no value for RestaurantID already in the db, I need to add 
      -- RestaurantName into the db and select the new autoincremented key for it 
    IF varRestaurantID IS NULL THEN
      INSERT INTO Restaurants (RestaurantName)
      VALUES (RestaurantName1);

      SET varRestaurantID = LAST_INSERT_ID();
    END IF;
    
    
    
    
    -- ServerEmpID
    
      -- Get ServerEmpID if it doesn't exist yet
    IF NOT EXISTS (
      SELECT 1 
      FROM Servers 
      WHERE ServerEmpID = ServerEmpID1
    ) 
      -- If it doesn't exist yet, used the passed args to create the new value 
      -- for ServerEmpID (and the current date for the HireDate val)
    THEN
      INSERT INTO Servers (ServerEmpID, ServerName, StartDateHired, HourlyRate)
      VALUES (ServerEmpID1, ServerName1, CURDATE(), HourlyRate1);
    END IF;




    -- RestaurantServers Value
    
      -- I need to use the whole composite key to get the correct 
      -- ServerAssignmentID from the junction
    SELECT 
      ServerAssignmentID INTO varServerAssignmentID
    FROM RestaurantServers
    WHERE RestaurantID = varRestaurantID AND ServerEmpID = ServerEmpID1
    LIMIT 1;

      -- And if it does not exist, I need to insert a the new vals from the user 
      -- args as well as the now selected (or created) RestaurantID
    IF varServerAssignmentID IS NULL THEN
      INSERT INTO RestaurantServers (RestaurantID, ServerEmpID)
      VALUES (varRestaurantID, ServerEmpID1);
      
      -- Create the new value for ServerAssignmentID from the autoincrement if
      -- it doesn't exist yet
      SET varServerAssignmentID = LAST_INSERT_ID();
    END IF;




    -- Customer Value
    
      -- Same format as above, I'm using the LoyaltyCustomer nonkey attributes 
      -- to either get the correct CustomerID value or create a new one if it 
      -- doesn't exist yet  
    SELECT 
      CustomerID INTO varCustomerID
    FROM LoyaltyCustomers
    WHERE CustomerEmail = CustomerEmail1
    LIMIT 1;

    IF varCustomerID IS NULL THEN
      INSERT INTO LoyaltyCustomers (CustomerEmail, CustomerPhone, CustomerName)
      VALUES (CustomerEmail1, CustomerPhone1, CustomerName1);

      SET varCustomerID = LAST_INSERT_ID();
    END IF;


    -- Select all the columns in the db to add my values to 
    INSERT INTO Visits (VisitID, RestaurantID, ServerAssignmentID, CustomerID,
      VisitDate, VisitTime, MealTypeID, PartySize, WaitTime, LoyaltyMember,
      FoodBill, TipAmount, DiscountApplied, PaymentMethodID, OrderedAlcohol, 
      AlcoholBill)
    
    -- Here, either the direct input argument or the new value that has been 
    -- collected using all the nonkey attributes for the parent table for that 
    -- attribute (or created if those attributes did not exist yet) are passed to
    -- the db
    VALUES (VisitID1, varRestaurantID, varServerAssignmentID, varCustomerID,
      VisitDate1, VisitTime1, MealTypeID1, PartySize1, WaitTime1, 
      LoyaltyMember1, FoodBill1, TipAmount1, DiscountApplied1, PaymentMethodID1,
      OrderedAlcohol1, AlcoholBill1);

  END
")


# I've added this so I can see that the ServerAssignmentID for my server below
# that does not exist yet actually does get the next value via autoincrement;
# here, the last value is 50. Following the insertion via the stored procedure
# in the next line, that value should be 51
dbGetQuery(dbcon, "
  SELECT 
    MAX(ServerAssignmentID)
  FROM Visits;
")

# Here, I'll create another check for this stored procedure with a bunch of
# random variables. I've used input values that are nowhere else in the db so
# that the "SET var..." segments are triggered to create new data for each
# missing FK in the Visits table
dbExecute(dbcon, "
  CALL storeNewVisit(
    999999, 'Rohans Kitchen', 88888, 'Rohan Gupta', 'rohan@gmail.com',
    'Rohans Customer', '(123) 111-1111', '2025-06-01', '12:30:00', 1, 2, 10, 
    TRUE, 55.00, 8.00, 5.00, 1, FALSE, 0.00, 99.90);
")

# Check that the stored procedure added the new values
dbGetQuery(dbcon, "
  SELECT * FROM Visits
  WHERE VisitID = 999999;
")



# DISCONNECT FROM DB ------------------------------------------------------

# Disconnect
dbDisconnect(dbcon)

