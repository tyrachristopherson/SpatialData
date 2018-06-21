#

#  Script: EQ_datatoSQL.R

#  Purpose: This R script automates the movement of historical earthquake data from a csv file to SQL.

#  Instructions: 

#  Author: Tyra Christopherson

#  Date: 4/13/2018

#  Notes: 

#


#Load in libraries
library(RODBC)

setwd("C:/Work")

#Create a character vector of the file names
temp <- list.files(pattern = "*.csv")

#Create a list of the dataframes
mycsvfiles <- lapply(temp, read.csv)


#Set up SQL connection
dbhandle <- odbcDriverConnect('driver={SQL Server};server=MyServer;trusted_connection=true;database=Earthquake_Historical')

#Save the table
sqlSave(dbhandle,
        dat = mycsvfiles[[1]],
        tablename = "HistoricalEQ_AllStates",
        rownames = FALSE)

#Close SQL connection
odbcClose(dbhandle)

print(paste("1 /", length(temp), "CSV files transferred. Last transfer was", temp[1]))

for(i in 2:length(temp)){
  
  #Set up SQL connection
  dbhandle <- odbcDriverConnect('driver={SQL Server};server=MyServer;trusted_connection=true;database=Earthquake_Historical')
  
  #Save the table
  sqlSave(dbhandle,
          dat = mycsvfiles[[i]],
          tablename = "HistoricalEQ_AllStates",
          append = TRUE,
          rownames = FALSE)
  
  #Close SQL connection
  odbcClose(dbhandle)
  
  print(paste(i, "/", length(temp), "CSV files transferred. Last transfer was", temp[i]))
  
}

