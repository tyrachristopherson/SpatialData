/*

       Script: GridRoadIndexing.sql

       Purpose: Creates a primary key index and spatial index for the [STATE]_roads tables
				in the [TIGER_Roads] database.

       Instructions: Run script as-is. Make sure the hard-coded states are correct.
					 Needs to include all the states with tables in the TIGER_Roads database

       Author: Tyra Christopherson

       Date: 5/10/2018

       Notes: NA


*/



----------------------------------------------------------
----------------------------------------------------------
----------------------------------------------------------
-- CREATE INDEXES FOR STATE TABLES
----------------------------------------------------------
----------------------------------------------------------
----------------------------------------------------------


----------------------------------------------------------
-- SET UP FOR ITERATING THROUGH STATES
----------------------------------------------------------
-- Create memory table @states
declare @states table([id] int identity(1,1),
					  [statename] varchar(2))

insert into @states ([statename])
	select 'NC' 

-- Create @stateID and @totalstates (integers associated with each state)
declare @stateID int;
declare @totalstates int;
select @stateID = min([id]), @totalstates = max([id]) from @states;

print('State looping set up.')

----------------------------------------------------------
-- WHILE LOOP (ITERATES FOR EACH STATE)
----------------------------------------------------------
while @stateID <= @totalstates
begin -- end is at end of script

-- Create @currentstate (string of the current state)
declare @currentstate varchar(2)
select @currentstate = (select [statename] from @states where [id] = @stateID)

----------------------------------------------------------
-- PRIMARY KEY INDEX
----------------------------------------------------------

-- delete duplicate road entries
declare @DeleteDups NVARCHAR(max);
set @DeleteDups = '
with cte as (
select TLID,
	row_number() over(partition by TLID order by TLID) as [rn]
	from [TIGER_Roads].[dbo].[' + @currentstate + '_roads]
)
delete from cte where [rn] > 1';
exec sp_executesql @DeleteDups;

print('Duplicates deleted for ' + @currentstate)

-- prep for primary key (make TLID NOT NULL)
declare @NotNull NVARCHAR(max);
set @NotNull = '
ALTER TABLE [TIGER_Roads].[dbo].[' + @currentstate + '_roads]
ALTER COLUMN [TLID] varchar(200) NOT NULL';
exec sp_executesql @NotNull;

-- add primary key index
declare @PrimaryKey NVARCHAR(max);
set @PrimaryKey = '
ALTER TABLE [TIGER_Roads].[dbo].[' + @currentstate + '_roads]
ADD CONSTRAINT PK_TLID_' + @currentstate + ' PRIMARY KEY (TLID)';
exec sp_executesql @PrimaryKey;

print('Primary key created for ' + @currentstate)

----------------------------------------------------------
-- SPATIAL INDEX
----------------------------------------------------------
-- calculate bounding box

declare @minX varchar(20);
declare @maxX varchar(20);
declare @minY varchar(20);
declare @maxY varchar(20);

declare @ParamDef NVARCHAR(max);
set @ParamDef = '@minX1 varchar(20) OUTPUT, @maxX1 varchar(20) OUTPUT, @minY1 varchar(20) OUTPUT, @maxY1 varchar(20) OUTPUT'

declare @CalcBoundBox NVARCHAR(max);
set @CalcBoundBox = '
select @minX1 = geometry::EnvelopeAggregate(geom).STPointN(1).STX FROM [TIGER_Roads].[dbo].[' + @currentstate + '_roads];
select @maxX1 = geometry::EnvelopeAggregate(geom).STPointN(3).STX FROM [TIGER_Roads].[dbo].[' + @currentstate + '_roads];
select @minY1 = geometry::EnvelopeAggregate(geom).STPointN(1).STY FROM [TIGER_Roads].[dbo].[' + @currentstate + '_roads];
select @maxY1 = geometry::EnvelopeAggregate(geom).STPointN(3).STY FROM [TIGER_Roads].[dbo].[' + @currentstate + '_roads];';
exec sp_executesql @CalcBoundBox, @ParamDef, @minX1 = @minX OUTPUT, @maxX1 = @maxX OUTPUT, @minY1 = @minY OUTPUT, @maxY1 = @maxY OUTPUT

print('Bounding box calculated for ' + @currentstate)

-- Create Spatial Index
declare @SetRoadSpIndx NVARCHAR(max);
select @SetRoadSpIndx = '
CREATE SPATIAL INDEX Sindx_' + @currentstate + '_rd ON [TIGER_Roads].[dbo].[' + @currentstate + '_roads]
(
       [geom]
)USING  GEOMETRY_GRID  
WITH (

CELLS_PER_OBJECT = 24,
BOUNDING_BOX = ( ' + @minX + ', ' + @minY + ', ' + @maxX + ', ' + @maxY + ' ),  
GRIDS = (LOW, LOW, MEDIUM, HIGH)
, PAD_INDEX = ON
, STATISTICS_NORECOMPUTE = OFF
, SORT_IN_TEMPDB = OFF
, DROP_EXISTING = OFF
, ONLINE = OFF
, ALLOW_ROW_LOCKS = ON
, ALLOW_PAGE_LOCKS = ON)';
exec sp_executesql @SetRoadSpIndx;

print('Finished with ' + @currentstate)

-- Change the @stateID number and end while loop
select @stateID = @stateID + 1
end -- end while loop for states

print('Finished with all states. Script complete.')