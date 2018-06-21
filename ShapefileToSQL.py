#----------------------------------------------------------------------------------------------------------

#       Script: ShapefileToSQL.py

#       Purpose: Function to load shapefiles into SQL Server.

#       Instructions: At the very bottom of the script, call the LoadSpatialData function, enter required
#                     parameters, then run code as-is.

#       Author: Tyra Christopherson

#       Date: 6/5/2018

#       Notes: Requires Python 3 and the libraries listed below.

#----------------------------------------------------------------------------------------------------------

#Required Libraries
import os, sys, re
import fiona
from fiona.crs import from_epsg
from shapely.geometry import mapping, Point, LineString, shape
import pyodbc
import datetime

#Define the function LoadSpatialData()
def LoadSpatialData(file_location, naming, skip = [], SRID = '4269', instance, outputDB, bulk_location):
    r"""Load shapefiles into SQL Server.
    
    Function parameters:
         - Required:
              - file_location (list of the paths to folders with the shapefiles to be loaded)
              - naming (dictionary that links the original shapefile names to the output SQL table names. The
                keys are the shapefile names WITHOUT the '.shp', and the values are the SQL table names)
              - instance (string of the SQL Server instance for the output tables. )
              - outputDB (string of the SQL Server database for the output tables. )
              - bulk_location (string of the bulk load folder location. )
         - Optional:
              - skip (list of the shapefile names WITHOUT the '.shp' within the folder file_location to be
                skipped over, if any. Default value is empty list: [])
              - SRID (string of the spatial reference system identifier, or EPSG. Default value is: '4269')
    
    Author: Tyra Christopherson
    
    Date Written: 6/5/2018
    
    """
    #time started
    ts = datetime.datetime.now()
    
    try:
        #Loop through the file paths in file_location list
        for file_path in file_location:
            
            #Loop through every shapefile in current file_path
            for inputSHP in os.listdir(file_path):
                
                #Only proceed with the .shp files
                if inputSHP.endswith('.shp'):
                    
                    #Only proceed if not designated as completed
                    if inputSHP[:-4] not in skip:
                        
                        #Obtain output table name
                        outputTable = naming[inputSHP[:-4]]
                        
                        print("Starting process for " + inputSHP + " to SQL table " + outputTable)
                        
                        with fiona.open(file_path + '\\' + inputSHP) as c:
                            ###############################################################
                            # Create .txt output files to store .shp data to load into SQL
                            ###############################################################
                            
                            #List of field names
                            field_names = c.schema['properties'].keys()
                            
                            #Opens file with write permissions
                            #Keeps the original shapefile name, but as .txt not .shp
                            f = open(bulk_location + '\\' + inputSHP[:-4] + '.txt', 'w', encoding = 'utf-8')
                            
                            #Loop through each row(?) in current shapefile
                            for feature in c:
                                #Create empty list for values of property for each field name
                                fieldList = []
                                
                                #Loop through every field name to pull the data
                                for fieldName in field_names:
                                    #Add the data to the fieldList
                                    fieldList.append(feature['properties'][fieldName])
                                    
                                    #Create a WKT geometry column
                                    geom = str(shape(feature['geometry']))
                                    
                                #Create formatted text string of data values by joining the list with tab
                                #This is done for the current row, and prepares the row to load into .txt
                                fieldListstr = '\t'.join(str(e) for e in fieldList)
                                
                                #Write the row to .txt and start a new line
                                f.write(fieldListstr + '\t' + geom + '\n')
                                
                            #Close the file after it has finished writing
                            f.close()
                            
                            print(".txt file written from " + inputSHP)
                            
                            ###############################################################
                            # Create SQL command to create table
                            ###############################################################
                            
                            #Start string of SQL command to create table -- is concatenated with more later on
                            createTable = 'BEGIN TRANSACTION; Create Table ' + outputDB + '.dbo.' + outputTable + ' ('
                            
                            #Set empty variable names to be assigned in the field type look-up    
                            finalFieldType = ''
                            fieldNameChar = []
                            
                            #Loop through every field name to build string to generate the fields in SQL   
                            for fieldName in field_names:
                                #Obtain the field type and length details
                                fieldAttr = c.schema['properties'][fieldName]
                                
                                #split the fieldAttr list by the colon (this splits into type and length)
                                fieldTypeList = fieldAttr.split(":")
                                
                                #Set field type
                                fieldType = fieldTypeList[0]        
                                
                                #Set field length
                                fieldTypeLength = fieldTypeList[1]        
                                
                                #Look-up to convert shapefile data types into SQL data types
                                #B/c issues w/ Bulk Insert & data types, default to varchar(200) for most
                                if fieldType == 'int' or fieldType == 'time' or fieldType == 'date' or fieldType == 'datetime' or fieldType == 'float':
                                    finalFieldType = 'varchar(200)'
                                elif fieldType == 'str':
                                    if int(fieldTypeLength) >= 4:
                                        finalFieldType = 'varchar' + '(' + fieldTypeLength + ')'
                                    else:
                                        finalFieldType = 'varchar(4)'
                                else:
                                    finalFieldType = 'varchar(4000)'
                                
                                #Build a string for the current field name and type (can be used to create SQL table)
                                fieldChar = '[' + fieldName + '] ' + finalFieldType + ','
                                
                                #Update string for SQL table generation
                                createTable = createTable + fieldChar
                                
                            #Update string for SQL table generation w/ a geometry column and final parenthesis
                            createTable = createTable + '[geomWKT]varchar(max)' + ')'
                            
                            ###############################################################
                            # Set SQL connection
                            ###############################################################
                            
                            conn = pyodbc.connect('driver={SQL Server};server=' + instance + ';database=' + outputDB +';trusted_connection=true')
                            cursor = conn.cursor()
                            
                            ###############################################################
                            # Create table and insert data
                            ###############################################################
                            
                            #check to see if table already exists
                            checkTable = "DECLARE @existcheck int; IF OBJECT_ID('" + outputDB + ".dbo." + outputTable + "', 'U') IS NOT NULL SET @existcheck = 1; ELSE SET @existcheck = 0; SELECT 'EXISTS' = @existcheck;"
                            cursor.execute(checkTable)
                            Exist = cursor.fetchone()[0]
                            
                            if Exist == 1:
                                answer = input(outputTable + ' already exists in SQL! Should it be deleted and replaced? [y/n]')
                                if answer == 'y':
                                    #drop the table if it exists in the database
                                    dropExistTable = "IF OBJECT_ID('" + outputDB + ".dbo." + outputTable + "', 'U') IS NOT NULL DROP TABLE " + outputDB + '.dbo.' + outputTable + ";"
                                    cursor.execute(dropExistTable)
                                    
                                    print(outputTable + ' was deleted and will be replaced.')
                                    
                                else:
                                    print(outputTable + ' was NOT deleted or replaced. Moving on to the next shapefile.\n')
                                    break
                            
                            #create a new table
                            cursor.execute(createTable)
                            conn.commit()
                            
                            print("SQL table " + outputTable + "created from " + inputSHP)
                            
                            #Insert data into table
                            blkInsrt = "BULK INSERT " + outputDB + ".dbo." + outputTable + " FROM '" + bulk_location + "\\" + inputSHP[:-4] + ".txt'" + " WITH (FIELDTERMINATOR = '\t', ROWTERMINATOR = '\n')"
                            cursor.execute(blkInsrt)
                            conn.commit()
                            
                            print(inputSHP + " data loaded into SQL table " + outputTable)
                            
                            #add geometry column
                            addGeomColumn = 'Alter Table ' + outputDB + '.dbo.' + outputTable + ' add geom geometry'
                            cursor.execute(addGeomColumn)
                            
                            #update the geometry from WKT
                            updateGeom = 'update ' + outputDB + '.dbo.' + outputTable + ' set geom = geometry::STGeomFromText(geomWKT, ' + SRID + ')'
                            cursor.execute(updateGeom)
                            conn.commit()
                            
                            print("Geometry added to SQL table " + outputTable)
                            
                            ###############################################################
                            # Perform a check on .txt file and SQL table
                            ###############################################################
                            #Get number of rows from SQL table
                            rowcount = "SELECT COUNT(*) FROM " + outputDB + ".dbo." + outputTable
                            cursor.execute(rowcount)
                            SQL_rows = cursor.fetchone()[0]
                            
                            #Opens file with read permissions & get number of rows from .txt
                            f = open(bulk_location + '\\' + inputSHP[:-4] + '.txt', 'r')
                            txt_rows = len(f.readlines())
                            f.close()
                            
                            #Compare number of rows
                            if SQL_rows == txt_rows:
                                print("Check! SQL table and .txt rows match for " + outputTable + " and " + inputSHP[:-4] + ".txt")
                                print("SQL rows: "+ str(SQL_rows))
                                print("txt rows: " + str(txt_rows) + "\n")
                                
                                #commit the transaction to SQL
                                commitTransaction = "COMMIT TRANSACTION;"
                                cursor.execute(commitTransaction)
                                conn.commit()
                                conn.close()
                            else:
                                print("WARNING! SQL table and .txt rows DO NOT match for " + outputTable + " and " + inputSHP[:-4] + ".txt")
                                print("SQL rows: " + str(SQL_rows))
                                print("txt rows: " + str(txt_rows))
                                
                                #rollback the SQL transaction
                                rollbackTransaction = "ROLLBACK TRANSACTION;"
                                cursor.execute(rollbackTransaction)
                                conn.commit()
                                conn.close()
                                
                                print("The transaction was rolled back. The data is NOT in SQL.\n")
                    else:
                        print(inputSHP + " was skipped!\n")
            
        #Print statement to acknowledge script completion
        print("Script complete. All shapefiles loaded to SQL.")
        
    except Exception as e:
        print("Error has occurred", e)
        f.close()
        conn.close()
        sys.exit()
        
    #time finished
    tf = datetime.datetime.now()
    
    #time elapsed
    te = tf - ts
    print('Total elapsed time: ' + str(te))

#----------------------------------------------------------------------------------------------------------

#Call LoadSpatialData function
LoadSpatialData()
