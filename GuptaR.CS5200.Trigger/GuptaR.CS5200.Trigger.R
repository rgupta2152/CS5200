
## HEADER ------------------------------------------------------------------

# Script Title: "ASSIGNMENT 07.1: Build Triggers in SQLite"
# Author: Rohan Gupta
# Date: June 24th, 2025


# NOTE: Technically, my comments where I write out and 'hardcode' values for the
# expected values before and after triggers will only be accurate on the first
# run, since any subsequent run will modify the already modified values for
# those rows. However, on the fresh db direclty from Canvas, those hardcoded
# values are correct.


# References: 

# [CASE WHEN Reference](https://www.w3schools.com/sql/sql_case.asp)
# [UPDATE Reference](https://www.w3schools.com/sql/sql_update.asp)
# [INSERT INTO Reference](https://www.w3schools.com/sql/sql_insert_into_select.asp)
# [EXISTS Reference](https://www.w3schools.com/sql/sql_exists.asp)

# Load libraries:
library(RSQLite)
library(DBI)


## CONNECT TO DB -----------------------------------------------------------

# Connect to the db
dbcon <- dbConnect(SQLite(), "OrdersDB.sqlitedb.db")


# Enable foreign key constraints
dbExecute(dbcon, "PRAGMA foreign_keys = ON;")



## TASK 1: CREATE TABLE ----------------------------------------------------

# Remove the table if it already exists
tblRemove <- dbExecute(dbcon, "DROP TABLE IF EXISTS SalesFacts")

# Create the new table by first adding col names, plus their types and keys. In
# order to create a unique sfID for every row, I've autoincremented values into
# this col
tblCreate <- dbExecute(dbcon, "
    CREATE TABLE IF NOT EXISTS SalesFacts (
      sfID INTEGER PRIMARY KEY AUTOINCREMENT,
      productID INTEGER NOT NULL,
      TotalUnits NUMERIC NOT NULL,
      TotalRevenue NUMERIC NOT NULL,
    
      FOREIGN KEY (productID) REFERENCES Products(ProductID)
    );
")





## TASK 2: ADD DATA --------------------------------------------------------

# Here, I need to insert values for productID, TotalUnits, and TotalRevenue; all
# these values come from tables in the original database 

# productID: 
  # These are the same productID's from the Products table
# TotalUnits:
  # In grouping by productID, I can get the total quantity of each product sold
  # with SUM(Quantity) from OrderDetails
# TotalRevenue: 
  # Again, grouping by productID lets me get the total revenue for each product 
  # by getting the sum of (price * quantity), where the price for a productID is
  # the same for each product and quantity changes per order
addVals <- dbExecute(dbcon, "
    INSERT INTO SalesFacts (productID, TotalUnits, TotalRevenue)
    SELECT
      od.productID AS productID,
      SUM(od.Quantity) AS TotalUnits,
      SUM(p.Price * od.Quantity) AS TotalRevenue
    FROM OrderDetails od
      JOIN Products p ON (od.ProductID = p.ProductID)
    GROUP BY p.ProductID;
")



# For the sake of explanation, I'll refer to SalesFacts attributes with a
# "s.attribute"




## TASK 3: INSERT TRIGGER --------------------------------------------------

# Drop the trigger if it alredy exists
dropTrig <- dbExecute(dbcon, "DROP TRIGGER IF EXISTS salesFacts_after_insert")

# Here, I'm creating a trigger called "salesFacts_after_insert" that executes
# after a new row of data is inserted into OrderDetails, and the trigger runs
# for each new row inserted.

# When the trigger is run, I update SalesFacts on the two attributes which need
# updating to match the new values in OrderDetails:

# I set TotalUnits to the same 'quantity per product' query as before (when
# adding data to SalesFacts) to get the total quantity where od.ProductID =
# the newly inserted od.ProductID 

# I also set TotalRevenue to the same query as before, where I get the total
# price per productID where the productID = the newly added productID.

# These two "SET"s just query to pull in the same data as before, just now with
# the new row of data in OrderDetails accounted for

# Finally, I'm saying that the trigger "UPDATE SalesFacts ... WHERE s.productID
# = NEW.ProductID", meaning that the trigger updates SalesFacts for the row
# where productID is the same as the product just inserted to OrderDetails


insertTrig <- dbExecute(dbcon, "
    CREATE TRIGGER salesFacts_after_insert
      AFTER INSERT ON OrderDetails
      FOR EACH ROW
      
      BEGIN
        UPDATE SalesFacts
          SET 
            TotalUnits = (SELECT 
                            SUM(Quantity)
                          FROM OrderDetails
                          WHERE ProductID = NEW.ProductID),
            TotalRevenue = (SELECT
                              SUM(p.Price * od.Quantity)
                            FROM OrderDetails od
                              JOIN Products p ON (od.ProductID = p.ProductID)
                            WHERE p.ProductID = NEW.ProductID)
        WHERE productID = NEW.ProductID;
      END;
")





## TASK 4: UPDATE TRIGGER --------------------------------------------------

# Drop the trigger if it alredy exists
dropTrig <- dbExecute(dbcon, "DROP TRIGGER IF EXISTS salesFacts_after_update")

# Here, I'm creating a new trigger that executes when any kind of update is made
# to OrderDetails. 

# IMPORTANT ASSUMPTIONS I'VE MADE: 

# My understanding of this question is that my trigger should update SalesFacts
# when some attribute for a ProductID from OrderDetails is modified. Based on
# the schema and the attributes in my SalesFacts table, the only attribute
# changes from OrderDetails that would require me to update SalesFacts would be
# modifications to Quantity or ProductID (since these are the only two
# attributes called in the queries to build the table in the first place). This
# is why I've written the WHEN to only execute the trigger when either of these
# values are modified in OrdeDetails

# I also want to note that my trigger accounts for a situation where a product
# with quantity values from just one order that can easily be modified with a
# change to a single row so that their total quantity across all orders of the
# product is zero. In this case (using CASE statements from my reference) where
# the quantity for an entire product.

# Finally, the subqueries in the SET statements account for modifications to
# ProductID by setting od.ProductID to either the OLD or NEW value of productID.
# This means that if the od.ProductID is changed from one existing productId to
# another, then both the affected product rows (the new and the old) in
# SalesFacts are recalculated


insertTrig <- dbExecute(dbcon, "
    CREATE TRIGGER salesFacts_after_update
      AFTER UPDATE ON OrderDetails
      FOR EACH ROW
      WHEN 
        OLD.ProductID != NEW.ProductId OR
        OLD.Quantity != NEW.Quantity
        
      
      BEGIN
        UPDATE SalesFacts
          SET 
            TotalUnits = CASE 
                            WHEN (SELECT 
                                    SUM(Quantity)
                                  FROM OrderDetails
                                  WHERE ProductID = SalesFacts.productID) IS NULL 
                              THEN 0
                            ELSE (SELECT 
                                    SUM(Quantity)
                                  FROM OrderDetails
                                  WHERE ProductID = SalesFacts.productID)
                          END,
              TotalRevenue = CASE 
                                WHEN (SELECT
                                        SUM(p.Price * od.Quantity)
                                      FROM OrderDetails od
                                      JOIN Products p ON (od.ProductID = p.ProductID)
                                      WHERE p.ProductID = SalesFacts.productID) IS NULL
                                  THEN 0
                                ELSE (SELECT
                                        SUM(p.Price * od.Quantity)
                                      FROM OrderDetails od
                                      JOIN Products p ON (od.ProductID = p.ProductID)
                                      WHERE p.ProductID = SalesFacts.productID)
                              END
        WHERE productID IN (OLD.ProductID, NEW.ProductID);
      END;
")





## TASK 5: DELETE TRIGGER --------------------------------------------------

# Delete the trigger if it exists:
dropTrig <- dbExecute(dbcon, "DROP TRIGGER IF EXISTS salesFacts_after_delete")

# Finally, I create a trigger that runs when an order detail is removed entirely

# The entire second half of this trigger is the exact same as the update, but
# with the WHERE statements matching ProductID to the OLD s.productID value
# instead of either new or old values. I also did not need to specify which
# modifications this trigger needs to run on with a WHEN under FOR EACH ROW.

# That being said, the segment at the top of this trigger accounts from the
# teams message from Dr. Schedlbauer saying that, "if a delete occurs such that
# the product has no order details" it should be deleted from SalesFact
# completely. 
  # To do this, I simply used an EXIST statement to see if the productID removed
  # from OrderDetails is still in my SalesFact table, and if it is, that entire
  # productID can be removed from SalesFacts

deleteTrig <- dbExecute(dbcon, "
    CREATE TRIGGER salesFacts_after_delete
      AFTER DELETE ON OrderDetails
      FOR EACH ROW
      
      BEGIN
        DELETE FROM SalesFacts
          WHERE productID = OLD.ProductID AND
          NOT EXISTS (
            SELECT *
            FROM OrderDetails
            WHERE ProductID = OLD.ProductID
          );
        
        UPDATE SalesFacts
          SET 
            TotalUnits = CASE 
                            WHEN (SELECT 
                                    SUM(Quantity)
                                  FROM OrderDetails
                                  WHERE ProductID = OLD.ProductID) IS NULL 
                              THEN 0
                            ELSE (SELECT 
                                    SUM(Quantity)
                                  FROM OrderDetails
                                  WHERE ProductID = OLD.ProductID)
                          END,
              TotalRevenue = CASE 
                                WHEN (SELECT
                                        SUM(p.Price * od.Quantity)
                                      FROM OrderDetails od
                                      JOIN Products p ON (od.ProductID = p.ProductID)
                                      WHERE p.ProductID = OLD.ProductID) IS NULL
                                  THEN 0
                                ELSE (SELECT
                                        SUM(p.Price * od.Quantity)
                                      FROM OrderDetails od
                                      JOIN Products p ON (od.ProductID = p.ProductID)
                                      WHERE p.ProductID = OLD.ProductID)
                              END
        WHERE productID = OLD.ProductID;
      END;
")





## TASK 6: TESTING ---------------------------------------------------------


# Here, I've created some test cases and printed the output of queries to check
# that my triggers work when new (fake) data is added to my table

#For the expected values I comment in, I found these by simply visually parsing
#the data loaded into R... here is what those look like (commented out for
#relevance):
##############################################################################

products <- dbGetQuery(dbcon, "SELECT * FROM Products")

orderDetails <- dbGetQuery(dbcon, "SELECT * FROM OrderDetails")

orders <- dbGetQuery(dbcon, "SELECT * FROM Orders")

p_od_joined <- dbGetQuery(dbcon, "
    SELECT
      p.ProductID,
      SUM(od.Quantity),
      SUM(p.Price * od.Quantity)
    FROM OrderDetails od
      JOIN Products p ON (od.ProductID = p.ProductID)
    GROUP BY p.ProductID
")

mytable <- dbGetQuery(dbcon, "SELECT * FROM SalesFacts") 

#############################################################################


# ------ Test Task 3: Insert Trigger ------


# --- Before Trigger ---

# Starting with a query to see the SalesFacts table for two products
before <- dbGetQuery(dbcon, "
    SELECT *
    FROM SalesFacts
    WHERE 
      productID = 3 OR
      productID = 8;
")

# Commented out so it can be printed later for easy comparison
# before


# Here are the prices for these two products from the Products table:
  # productID(3) = $10.00
  # productID(8) = $40.00


# --- Add Data for Trigger ---

# Then inserting some fake data to the OrderDetails Table. The OrderID is an
# already existing order, which I needed to select to get by the FK constraints
insert <- dbExecute(dbcon, "
    INSERT INTO OrderDetails(OrderID, ProductID, Quantity) VALUES
      (10248, 3, 5),
      (10248, 8, 2);
")



# --- After Trigger and Expected Results ---

# This is what I should expect in the SalesFacts Table after the above data is
# added to OrderDetails
  # productID(3):
    # TotalUnits = 80 + 5 = 85 
    # TotalRevenue = 800 + (5 * 10)  = $850.00
  # productID(8):
    # TotalUnits = 140 + 2 = 142 
    # TotalRevenue =  5600 + (2 * 40)  = $5680.00

after <- dbGetQuery(dbcon, "
    SELECT *
    FROM SalesFacts
    WHERE 
      productID = 3 OR
      productID = 8;
")

# --- Comparison ---

# These before and after values match my expected values from above
before
after






# ------ Test Task 4: Update Trigger ------


# --- Before Trigger ---

# Get the SalesFact row for this productID before modification
before2 <- dbGetQuery(dbcon, "
    SELECT *
    FROM SalesFacts
    WHERE 
      productID = 3;
")


# Also get a single orderDetail row where the ProductID is 3
single_orderDetail <- dbGetQuery(dbcon, "
    SELECT * 
    FROM OrderDetails 
    WHERE 
      ProductID = 3
    LIMIT 1;
") 

# The order detail I'll choose to modify quantity for is OrderDetailID = 110
# (from the output below)
single_orderDetail




# --- Modify Data for Trigger ---

# Here, I'll actually modify the quantity of product in this specific order
modifyQuantity <- dbExecute(dbcon, "
    UPDATE OrderDetails
      SET Quantity = Quantity - 15
    WHERE OrderDetailID = 110;
")


# --- After Trigger and Expected Results ---

# This is what I should expect in the SalesFacts Table after the above data is
# changed for OrderDetailID = 110
  # productID(3):
    # TotalUnits = 85 - 15 = 70 
    # TotalRevenue = 850 + (-15 * 10)  = $700.00
after2 <- dbGetQuery(dbcon, "
    SELECT *
    FROM SalesFacts
    WHERE 
      productID = 3
")



# --- Comparison ---

# These before and after values match my expected values from above
before2
after2








# ------ test Task 5: Delete Trigger ------


# --- Before Trigger ---

# The first thing I needed to do here was find an OrderDetails row for a product
# that actually contained details from just one order; using HAVING COUNT(*)
# gets a row num value for each productID
onlyOneOrder <- dbGetQuery(dbcon, "
    SELECT
      ProductID
    FROM OrderDetails
    GROUP BY ProductID
    HAVING
      COUNT(*) = 1
    LIMIT 1
")

# I'll use productID 9 from the output below
onlyOneOrder

# I'll also include a product with details from more than one order
moreThanOne <- dbGetQuery(dbcon, "
    SELECT
      ProductID
    FROM OrderDetails
    GROUP BY ProductID
    HAVING
      COUNT(*) > 1
    LIMIT 1
")

# I'll select productID 1 from this output  
moreThanOne

# Here, I get the before of this productID from SalesFact for both the single
# order product and my other multi-order product
before3 <- dbGetQuery(dbcon, "
    SELECT *
    FROM SalesFacts
    WHERE 
      productID = 9 OR
      productID = 1;
")

# Here are the prices for these two products from the Products table:
  # productID(1) = $18.00
  # productID(9) = $97.00



# --- Delete Data for Trigger ---

# Here, I'm removing data from the OrderDetails table for productID = 9 ; this
# is the only order for this product, so this also removes all its OrderDetails
  # From the Products table, I found a single OrderDetailID for productID = 1, 
  # which I've removed below
deleteID1 <- dbExecute(dbcon, "
  DELETE FROM OrderDetails
  WHERE 
    ProductID = 9;
")

deleteID9 <- dbExecute(dbcon, "
  DELETE FROM OrderDetails
  WHERE
    OrderDetailID = 100;
")

# For OrderDetailID(100) from above:
  # ProductID = 1 
  # Quantity = 45



# --- After Trigger and Expected Results ---

# This is what I should expect in the SalesFacts Table after the rows are
# deleted from productIDs 1 and 9:
  # productID(1): 
    # TotalUnits = 159 - 45 = 114 
    # TotalRevenue = 2862 + (-45 * 18)  = $2052.00
  # productID(9): 
    # Should NOT appear in the "after" table
after3 <- dbGetQuery(dbcon, "
    SELECT *
    FROM SalesFacts
    WHERE 
      productID = 9 OR
      productID = 1;
")




# --- Comparison ---

# These before and after values match my exepcted values from above
before3
after3






## DISCONNECT  -------------------------------------------------------------


# Finally, I need to disconnect and close my connection to the database 
dbDisconnect(dbcon)


