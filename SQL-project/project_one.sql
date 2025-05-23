#1.  Let's use location so we can use that killer query, SELECT * but remember to limit it and tell it which table we are looking at.
use  md_water_services;
SELECT * 
   FROM location
   LIMIT 5;
#2. Visits table
SELECT * 
   FROM visits
   LIMIT 5;
#3. let's look at the water_source table to see what a 'source' is. Normally "_id" columns are related to another table.
SELECT * 
   FROM water_source
   LIMIT 5;
   # Water sources are where people get their water from!
   #A data dictionary has been embedded into the database. If you query the data_dictionary table, an explanation of each column is given there.
#4. write a SQL query to find all the unique types of water sources
SELECT DISTINCT type_of_water_source
   FROM
     md_water_services.water_source;
#1.  River - People collect drinking water along a river
#2. Well - These sources draw water from underground sources, and are commonly shared by communities.
#3. Shared tap - This is a tap in a public area shared by communities.
#4. Tap in home - These are taps that are inside the homes of our citizens.
#5. Broken tap in home - These are taps that have been installed in a citizen’s home, but 
-- the infrastructure connected to that tap is notfunctional.
#5.Write an SQL query that retrieves all records from this table where the time_in_queue is more than some crazy time, say 500 min. How
SELECT * 
   FROM md_water_services.visits
  WHERE time_in_queue > 500 ;

-- would it feel to queue 8 hours for water? --
-- I am wondering what type of water sources take this long to queue for. We will have to find that information in another table that lists
-- the types of water sources. 
#####
use md_water_services;
 SELECT *
     FROM
     water_source
     where source_id in('AkKi00881224','SoRu37635224', 'SoRu36096224','AkRu05234224' ,'HaZa21742224') ;
####
use md_water_services;
/*So please write a query to find records where the subject_quality_score is 10 -- only looking for home taps -- and where the source
was visited a second time. What will this tell us? */
###
SELECT *
   FROM water_quality
   WHERE subjective_quality_score = 10
  -- AND source_type = 'home tap'
  AND visit_count = 2;
#. 218 rows of data are there in this query! So, write a query that checks if the results is Clean but the biological column is > 0.01.

use md_water_services;
SELECT *
FROM well_pollution
where results = 'Clean' 
  AND biological > 0.01;
# 64 rows
# To find these descriptions, search for the word Clean with additional characters after it. As this is what separates incorrect descriptions from the records that should have "Clean".
use md_water_services;
SELECT *
  FROM well_pollution
   where description LIKE 'Clean_%' 
   AND biological > 0.01;

#  38 rows returned
/*The CREATE TABLE new_table AS (query) approach is a neat trick that allows you to create a new table from the results set of a query.
This method is especially useful for creating backup tables or subsets without the need for a separate CREATE TABLE and INSERT INTO
statement */

CREATE TABLE
md_water_services.well_pollution_copy
AS (
SELECT *
FROM md_water_services.well_pollution
);
SET @sql_saff_updates = 0;
USE md_water_services;
UPDATE well_pollution_copy
SET description = 'Bacteria: E. coli'
WHERE description = 'Clean Bacteria: E. coli';
UPDATE well_pollution_copy
SET description = 'Bacteria: Giardia Lamblia'
WHERE description = 'Clean Bacteria: Giardia Lamblia';
UPDATE well_pollution_copy
SET results = 'Contaminated: Biological'
WHERE biological > 0.01 AND results = 'Clean';
# We can then check if our errors are fixed using a SELECT query on the well_pollution_copy table:
SELECT *
   FROM
   well_pollution_copy
   WHERE
   description LIKE "Clean_%"
   OR (results = "Clean" AND biological > 0.01);
# Then if we're sure it works as intended, we can change the table back to the well_pollution and delete the well_pollution_copy table.
UPDATE
well_pollution_copy
SET
description = 'Bacteria: E. coli'
WHERE
description = 'Clean Bacteria: E. coli';
UPDATE
well_pollution_copy
SET
description = 'Bacteria: Giardia Lamblia'
WHERE
description = 'Clean Bacteria: Giardia Lamblia';
UPDATE
well_pollution_copy
SET
results = 'Contaminated: Biological'
WHERE
biological > 0.01 AND results = 'Clean';
DROP TABLE
md_water_services.well_pollution_copy;