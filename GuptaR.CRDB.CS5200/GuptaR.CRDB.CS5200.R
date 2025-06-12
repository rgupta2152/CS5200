## HEADER ------------------------------------------------------------------

# Script Name: "GuptaR.CRDB.CS5200.R"
# Author: "Rohan Gupta"
# Date: June 10th, 2025


# Load the two required libraries
library(RSQLite)
library(DBI)



## CREATE DATABASE ---------------------------------------------------------

# I'm starting by simply creating the database and establishing a connection
dbcon <- dbConnect(SQLite(), dbname = "assignmentDB-GuptaR.sqlitedb")

# Now that I've established a connection, I need to enable foreign key
# constraints, which helps me make sure I don't create a db where PKs and FKs
# are misaligned or incorrectly inserted
dbExecute(dbcon, "PRAGMA foreign_keys = ON;")



## MENTAL MODEL ------------------------------------------------------------

# This is just a separate area of text where I wanted to work out the schema in
# plain writing before implementing it programmatically into a SQL database:


# Office: 
  # oID: INT
    # PK Office ID; This is fine as is, makes sense that this is the PK here
  # name: TEXT
    # NOT NULL
  # perDiemRate: NUMERIC
    # NOT NULL
  # amenities: INT (as new attribute)
    # Since this is a categorical attribute, I need to create a new lookup table 
    # for this attribute. Since I am also creating a junction between the Office
    # and Amenity entities, I can remove this attribute completely and allow the 
    # OfficeAmenities table to dictate which amenities are in an office


# Amenity: Lookup table for amenitiesID
  # amenityID: INT
    # PK for this lookup
  # amenityType: TEXT
    # NOT NULL, since it needs to contain amenity type for each ID
    # This will consist of the different categories for amenities from the 
    # original schema (desk, printer, etc.)


# OfficeAmenities: Junction for Many-to-Many b/w Office and Amenity 
  # oID: INT
    # PK & FK; This references the Office entity
  # amenityID: INT
    # PK & FK Nullable; This FK references the Amenity entity
# Essentially, this resolves the many-to-many between office and amenity from 
# the note in the original schema. With this junction and the associated Amenity
# lookup, I have one table with the amenity values and their ID, then 
# another table stating which amenities each office has (without a NOT NULL, so
# that an office can have zero or many amenities, and an amenity type can belong
# to zero or many offices) 


# EmployeeOffice: Junction for Many-to-Many b/w Employee and Office
  # employeeOfficeID: INT
    # Since I have more than just the office and employee ID attributes in this
    # entity, I've decided to use a surrogate key instead of a composite one. 
    # Needs to be NOT NULL UNIQUE
  # oID: INT
    # FK pointing to Office
  # eID: INT
    # FK pointing to Employee
  # officeApproved: BOOLEAN 
    # NOT NULL showing that this employee's office assignment approval status 
  # approvalDate: DATE
    # Nullable if employee hasn't been approved - Date of approval
# Reference for deciding between composite key and surrogate key for junction 
# tables: https://stackoverflow.com/questions/28843953/in-a-junction-table-should-i-use-a-primary-key-and-a-unique-constraint-or-a-co 


# Employee:
  # eID: INT
    # Just changing this PK into an integer type as it is an ID. UNIQUE NOT NULL
  # name: TEXT
    # Fine as is, NOT NULL
  # title: TEXT
    # Fine as is, NOT NULL
  # type: INT
    # This is another multi-valued categorical attribute, which will need a 
    # lookup table (where I'll implement the default 'internal' value). New 
    # attribute name will be typeID. This needs to be the FK 
  # managerID: INT
    # Here, I'm going to implement managerId as a FK referencing back to the eID
    # attribute in this same table. This is because managers are internal, so 
    # they're still employees, so their ID will be their eID.
      # READ NOTE UNDER SUPERVISOR IMPLEMENTATION IN NEXT SECTION
# Reference for self referencing foreign keys: https://dba.stackexchange.com/questions/81311/why-would-a-table-use-its-primary-key-as-a-foreign-key-to-itself


# Type: Lookup Table for typeID
  # typeID: INT
    # PK referring to typeID from the Employee Table, UNIQUE NOT NULL 
  # typeVal: TEXT
    # This will contain the values 'internal' and 'external', where internal is 
    # 1 and the DEFAULT value


# Supervisor: Junction table to allow zero-to-many b/w employee and supervisor
  # This just shows which supervisors are assigned to which employees
  # eId: INT
    # This is part of the composite PK here, and is also the FK referring to eID 
    # from the Employee entity. Has to be nullable
  # supervisorID: INT
    # This is the FK referencing eID from the Employee entity, also PK (another 
    # self reference)
# Again, READ NOTE UNDER SUPERVISOR IMPLEMENTATION IN NEXT SECTION



## BUILDING DATABASE -------------------------------------------------------

# I've decided against using the paste0() function to execute SQL commands given
# that, when I initially used them, manually inputting commas for spacers broke
# my focus/flow


# ----- Office -----
# Start with the Office table, following my mental model above
# Remove the table if it already exists
dropOffice <- dbExecute(dbcon, "DROP TABLE IF EXISTS Office")

# oID is given constraint AUTOINCREMENT to let the db create unique values; for
# AUTOINCREMENT, the PK needs to be defined at the attribute, not in a later
# constraint
officeTable <- dbExecute(dbcon, "
    CREATE TABLE IF NOT EXISTS Office (
      oID INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      perDiemRate NUMERIC NOT NULL
    );                         
")
# Add some example office data
addOffice <- dbExecute(dbcon, "
    INSERT INTO Office (name, perDiemRate) VALUES
      ('Merck', 150),
      ('Meta', 400),
      ('Apple', 300),
      ('Nvidia', 200)
")



# ----- Amenity -----
# Now the amenity lookup table to resolve the multi-valued attribute
dropAmenity <- dbExecute(dbcon, "DROP TABLE IF EXISTS Amenity")

amenityTable <- dbExecute(dbcon, "
    CREATE TABLE IF NOT EXISTS Amenity (
      amenityID INTEGER PRIMARY KEY AUTOINCREMENT,
      amenityType TEXT NOT NULL
    );
")
# Add the amenity from the original schema
addAmenities <- dbExecute(dbcon, "
    INSERT INTO Amenity (amenityType) VALUES
      ('desk'),
      ('printer'),
      ('monitor'),
      ('whiteboard')
")



# ----- OfficeAmenities -----
# Now the junction to show which amenities are in which office
dropOfficeAmenities <- dbExecute(dbcon, "DROP TABLE IF EXISTS OfficeAmenities")

# The composite PK are the two FK attributes, and amenityID is nullable
officeAmenitiesTable <- dbExecute(dbcon, "
    CREATE TABLE IF NOT EXISTS officeAmenities (
      oID INTEGER, 
      amenityID INTEGER,
      PRIMARY KEY (oID, amenityID),
      FOREIGN KEY (oID) REFERENCES Office(oID),
      FOREIGN KEY (amenityID) REFERENCES Amenity(amenityID)
    );
")
# Add some example amenities
addOfficeAmenities <- dbExecute(dbcon, "
    INSERT INTO OfficeAmenities (oID, amenityID) VALUES
      (1, 1), 
      (1, 3), 
      (2, 1), 
      (3, 2), 
      (3, 4)
")



# ----- Employee -----
dropEmployee <- dbExecute(dbcon, "DROP TABLE IF EXISTS Employee")

# I've made managerID nullable just so I can accommodate when an employee is
# the highest level and has no manager.
employeeTable <- dbExecute(dbcon, "
    CREATE TABLE IF NOT EXISTS Employee (
      eID INTEGER NOT NULL,
      name TEXT NOT NULL,
      title TEXT NOT NULL,
      typeID INTEGER NOT NULL,
      managerID INTEGER,
      
      PRIMARY KEY (eID),
      FOREIGN KEY (managerID) REFERENCES Employee(eID)
    );
")
# Add employee data; I'm testing a couple of cases here:
  # internal employees with a manager but no supervisor
  # internal employees without a manager (highest level employees)
  # external employees with a supervisor
  # external employees without a supervisor
addEmployees <- dbExecute(dbcon, "
    INSERT INTO Employee (eID, name, title, typeID, managerID) VALUES
      (1, 'Rohan', 'JuniorEng', 1, 10),
      (2, 'Jeff', 'JuniorSWE', 1, 20),
      (3, 'Sam', 'ContractDS', 2, NULL),
      (4, 'John', 'ContractMLE', 2, NULL),
      (10, 'Matt', 'Manager', 1, NULL),
      (20, 'Kevin', 'Manager', 1, NULL),
      (40, 'Nick', 'Supervisor', 1, NULL)
")



# ----- Type -----
# This is the simple lookup table for the Type categorical
dropType <- dbExecute(dbcon, "DROP TABLE IF EXISTS Type")

# I added a simple check to make sure the type values are correct
typeTable <- dbExecute(dbcon, "
    CREATE TABLE IF NOT EXISTS Type (
      typeID INTEGER PRIMARY KEY AUTOINCREMENT,
      typeVal TEXT NOT NULL DEFAULT 'internal',
      CHECK (typeVal IN ('internal', 'external')) 
    );
")
# Add the internal and external type data; 1 means internal and 2 mean external
addType <- dbExecute(dbcon, "
    INSERT INTO Type (typeVal) VALUES
      ('internal'),
      ('external')
")



# ----- Supervisor ----- 
dropSupervisor <- dbExecute(dbcon, "DROP TABLE IF EXISTS Supervisor")

# NOTE FOR GRADER This is where I had a lot of difficulty; without using
# something like a Trigger, I just could not figure out how to ensure that
# supervisors are only assigned to external employees (typeID = 2) using just
# lookup/junction tables and/or check constraints. In the same respect, I could
# not figure out how to ensure that a manager only corresponds to internal
# employees. I'm able to input correct information into the database, but it
# doesn't feel as if incorrect information will be stopped from being inputted
# either. 

# I thought about adding something like:

# CHECK (
#   (typeID = 1 AND managerID IS NOT NULL) OR
#   (typeID = 2)
# )

# to the Employee entity, but this wouldn't allow for highest level employees
# without any managers to exist.

supervisorTable <- dbExecute(dbcon, "
    CREATE TABLE IF NOT EXISTS Supervisor (
      eID INTEGER,
      supervisorID INTEGER,
      
      PRIMARY KEY (eID, supervisorID),
      FOREIGN KEY (eID) REFERENCES Employee(eID),
      FOREIGN KEY (supervisorID) REFERENCES Employee(eID)
    )                             
")
# Add some example supervisors; I'll just be manually adding values based on the
# assignment constraints.
addSupervisors <- dbExecute(dbcon,"
    INSERT INTO Supervisor (eID, supervisorID) VALUES (3, 40)")



# ----- EmployeeOffice -----
dropEmployeeOffice <- dbExecute(dbcon, "DROP TABLE IF EXISTS EmployeeOffice")

employeeOfficeTable <- dbExecute(dbcon, "
    CREATE TABLE IF NOT EXISTS EmployeeOffice (
      employeeOfficeID INTEGER NOT NULL,
      eID INTEGER NOT NULL,
      oID INTEGER NOT NULL,
      officeApproval BOOLEAN NOT NULL, 
      approvalDate DATE,
      
      PRIMARY KEY (employeeOfficeID),
      FOREIGN KEY (eID) REFERENCES Employee(eID),
      FOREIGN KEY (oID) REFERENCES Office(oID)
    );
")
# Add some example data; the single digit values are lower level and the double
# are higher level
addEmployeeOffice <- dbExecute(dbcon, "
    INSERT INTO EmployeeOffice (eID, oID, officeApproval, approvalDate) VALUES
      (1, 2, TRUE, '2025-03-12'),
      (2, 1, TRUE, '2024-09-04') ,
      (3, 3, FALSE, '2022-03-04'),
      (4, 1, TRUE, '2019-01-02'),
      (10, 2, FALSE, NULL),
      (20, 1, TRUE, '2025-06-06'),
      (40, 1, FALSE, NULL)
")



# Load and print the tables in my database
officeView <- dbGetQuery(dbcon, "
    SELECT * FROM Office
")

amenityView <- dbGetQuery(dbcon, "
    SELECT * FROM Amenity                          
")

officeAmenitiesView <- dbGetQuery(dbcon, "
    SELECT * FROM OfficeAmenities                          
")

employeeView <- dbGetQuery(dbcon, "
    SELECT * FROM Employee                          
")

typeView <- dbGetQuery(dbcon, "
    SELECT * FROM Type                          
")

supervisorView <- dbGetQuery(dbcon, "
    SELECT * FROM Supervisor                          
")

employeeOfficeView <- dbGetQuery(dbcon, "
    SELECT * FROM EmployeeOffice                          
")


print(officeView)
print(amenityView)
print(officeAmenitiesView)
print(employeeView)
print(typeView)
print(supervisorView)
print(employeeOfficeView)



## CLOSE CONNECTION --------------------------------------------------------

# Finally, I need to disconnect and close my connection to the database 
dbDisconnect(dbcon)


# Delete the db from my system in case I need to rerun
unlink("assignmentDB-GuptaR.sqlitedb")











