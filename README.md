# SpatialData

This repository contains various code I wrote that involves spatial data in some way or another.
All of the separate code segments are distinct and unrelated.
Much of this code is relevant to my time working as a co-op/intern at Homesite Insurance.

A brief summary of each script can be found below.

## SatelliteViewer.R

This is an R Shiny app, representing a toned-down, smaller-scale version of part of an interactive web app I built for Homesite.
The app pulls satellite imagery of various latitudes/longitudes, using Bing.

## ShapefileToSQL.py

This Python 3.0 script loads shapefiles to datatables within a SQL Server database, by first converting the shapefile to a text file,
then loading the text file data into SQL. This is all done by defining and calling a funtion, LoadSpatialData().

### Function Parameters
#### Required
1. file_location
   -	List of strings
   -	The strings specify paths to folders with the shapefiles to be loaded
   -	Example: [r'C:\MainShapefiles', r'C:\OtherShapefiles']
2. naming
   -	Dictionary with strings as both keys and values
   -	The keys specify the shapefile names WITHOUT the '.shp',
   and the values specify the SQL table names, linking the original shapefile names to the corresponding output SQL table names
   -	Example: {'lowerstate01': 'Alabama', 'lowerstate02': 'Arizona', 'lowerstate03': 'Arkansas', 'otherstate01': 'Alaska'}
3.	instance
     -	String
     -	Specifies the SQL Server instance for the output tables.
     -	Example: 'MyServer'
4.	outputDB
     -	string
     -	Specifies the SQL Server database for the output tables.
     -	Example: 'StatesStartWithA'
5.	bulk_location
     -	String
     -	Specifies the bulk load folder location.
     -	Example: r'C:\BulkInsertFolder'

#### Optional
1.	skip
     -	List of strings
     -	The strings specify the shapefiles within the folders specified by file_location to be skipped over, if any.
     The shapefile names are written WITHOUT the ‘.shp’ file extension.
     -	Default value is empty list: []
     -	Example: skip = ['lowerstate04', 'otherstate02']
2.	SRID
     -	String
     -	Specifies the spatial reference system identifier, or EPSG. This should rarely have to be changed from the default.
     -	Default value is: '4269'

## EQ_datatoSQL.R

This R script loads CSV files into datatables within a SQL Server database.

### Data Source

Real-world earthquake data was used with this project.
All data was from the USGS Earthquake Hazards Program, and can be found here: https://earthquake.usgs.gov/earthquakes/search/

## RoadIndexing.sql

This SQL query deletes any duplicate data entries, then creates a primary key index and spatial index for datatables
within a SQL Server database.

### Data Source

Real-world road data was used with this project.
All data was from the US Census Bureau TIGER (Topologically Integrated Geographic Encoding and Referencing) products,
and can be found here:
https://www.census.gov/geo/maps-data/data/tiger-line.html
