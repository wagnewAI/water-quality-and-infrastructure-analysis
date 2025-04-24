-- Charting the course for Maji Ndogo's water future
		/* Things that spring to mind for me:
		1. Are there any specific provinces, or towns where some sources are more abundant?
		2. I identified that tap_in_home_broken taps are easy wins.Are there any towns where this is a particular problem?
		*/
	use md_water_services;
SELECT 
	location.province_name,
	location.town_name,
	visits.visit_count,
	location.location_id
FROM 
	visits
	join location
	on location.location_id = visits.location_id;
-- Now, I can join the water_source table on the key shared between water_source and visits
SELECT 
	location.province_name,
	location.town_name,
	visits.visit_count,
	location.location_id,
	water_source.type_of_water_source,
	water_source.number_of_people_served
FROM 
		visits
		join location
		on location.location_id = visits.location_id
		join water_source
		on water_source.source_id = visits.source_id
		WHERE visits.visit_count = 1;
        # WHERE visits.location_id = 'AkHa00103'
SELECT 
	location.province_name,
	location.town_name,
	visits.visit_count,
	location.location_id,
	water_source.type_of_water_source,
	water_source.number_of_people_served
FROM 
		visits
		join location
		on location.location_id = visits.location_id
		join water_source
		on water_source.source_id = visits.source_id
		WHERE visits.location_id = 'AkHa00103';
	
-- ## Ok, now that I verified that the table is joined correctly,I can remove the location_id and visit_count columns.
-- Add the location_type column from location and time_in_queue from visits to my results set
SELECT 
	location.province_name,
	location.town_name,
	water_source.type_of_water_source,
	location.location_type,
	water_source.number_of_people_served,
	visits.time_in_queue
FROM
	visits
	join location
	on location.location_id = visits.location_id
	join water_source
	on water_source.source_id = visits.source_id
	where visits.visit_count = 1;
-- Last one! Now I need to grab the results from the well_pollution table.
/*This one is a bit trickier. The well_pollution table contained only data for well. If I just use JOIN, I will do an inner join, so that only records
that are in well_pollution AND visits will be joined. I have to use a LEFT JOIN to join theresults from the well_pollution table for well
sources, and will be NULL for all of the rest. Play around with the different JOIN operations to make sure I understand why I used LEFT JOIN.*/
SELECT
	water_source.type_of_water_source,
	location.town_name,
	location.province_name,
	location.location_type,
	water_source.number_of_people_served,
	visits.time_in_queue,
	well_pollution.results
FROM
	visits
	LEFT JOIN
	well_pollution
	ON well_pollution.source_id = visits.source_id
	INNER JOIN
	location
	ON location.location_id = visits.location_id
	INNER JOIN
	water_source
	ON water_source.source_id = visits.source_id
	WHERE
	visits.visit_count = 1;
/*So this table contains the data I need for this analysis. Now I want to analyse the data in the results set. I can either create a CTE, and then
query it, or in my case, I'll make it a VIEW so it is easier to share with you. I'll call it the combined_analysis_table */
CREATE VIEW combined_analysis_table AS  -- This view assembles data from different tables into one to simplify analysis
	SELECT
			water_source.type_of_water_source AS source_type,
			location.town_name,
			location.province_name,
			location.location_type,
			water_source.number_of_people_served AS people_served,
			visits.time_in_queue,
			well_pollution.results
	FROM
		visits
		LEFT JOIN
		well_pollution
		ON well_pollution.source_id = visits.source_id
		INNER JOIN
		location
		ON location.location_id = visits.location_id
		INNER JOIN
		water_source
		ON water_source.source_id = visits.source_id
		WHERE
		visits.visit_count = 1;
SELECT *
	FROM combined_analysis_table; 
		/* The last analysis
		I'm building another pivot table! This time, I want to break down our data into provinces or towns and source types. If I understand where
		the problems are, and what I need to improve at those locations, I can make an informed decision on where to send our repair teams
		*/
 use md_water_services;
WITH province_totals AS (-- This CTE calculates the population of each province
		SELECT
			town_name,
			SUM(people_served) AS total_ppl_serv
			FROM
			combined_analysis_table
			GROUP BY
			province_name
		)
		SELECT
			ct.province_name,  -- These case statements create columns for each type of source.
			                   -- The results are aggregated and percentages are calculated
			ROUND((SUM(CASE WHEN source_type = 'river'
			THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS river,
			ROUND((SUM(CASE WHEN source_type = 'shared_tap'
			THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS shared_tap,
			ROUND((SUM(CASE WHEN source_type = 'tap_in_home'
			THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS tap_in_home,
			ROUND((SUM(CASE WHEN source_type = 'tap_in_home_broken'
			THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS tap_in_home_broken,
			ROUND((SUM(CASE WHEN source_type = 'well'
			THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS well
			FROM
			combined_analysis_table ct
			JOIN
			province_totals pt ON ct.province_name = pt.province_name
			GROUP BY
		    ct.province_name
			ORDER BY
			ct.province_name;
						 SELECT
							*
						FROM
						province_totals; 
						-- ###
						/* Let's aggregate the data per town now. You might think this is simple, but one little town makes this hard. Recall that there are two towns in Maji
						Ndogo called Harare. One is in Akatsi, and one is in Kilimani. Amina is another example. So when we just aggregate by town, SQL doesn't distinguish between the different Harare's,
						 so it combines their results.
						 To get around that, we have to group by province first, then by town, 
						 so that the duplicate towns are distinct because they are in different towns.
						*/
WITH town_totals AS (-- This CTE calculates the population of each town
	-- Since there are two Harare towns, we have to group by province_name and town_name
	SELECT province_name, town_name, SUM(people_served) AS total_ppl_serv
	FROM combined_analysis_table
	GROUP BY province_name,town_name
	)
SELECT
	ct.province_name,
	ct.town_name,
	ROUND((SUM(CASE WHEN source_type = 'river'
	THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS river,
	ROUND((SUM(CASE WHEN source_type = 'shared_tap'
	THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS shared_tap,
	ROUND((SUM(CASE WHEN source_type = 'tap_in_home'
	THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home,
	ROUND((SUM(CASE WHEN source_type = 'tap_in_home_broken'
	THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home_broken,
	ROUND((SUM(CASE WHEN source_type = 'well'
	THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS well
	FROM
	combined_analysis_table ct
	JOIN   -- Since the town names are not unique, we have to join on a composite key
	town_totals tt ON ct.province_name = tt.province_name AND ct.town_name = tt.town_name
	GROUP BY  -- We group by province first, then by town.
	ct.province_name,
	ct.town_name
	ORDER BY
	ct.town_name;
				/*
				Temporary tables in SQL are a nice way to store the results of a complex query. We run the query once, and the results are stored as a table. The
				catch? If you close the database connection, it deletes the table, so you have to run it again each time you start working in MySQL. The benefit is
				that we can use the table to do more calculations, without running the whole query each time.
				*/
CREATE TEMPORARY TABLE town_aggregated_water_access
	WITH town_totals AS (-- This CTE calculates the population of each town
						-- Since there are two Harare towns, we have to group by province_name and town_name
	SELECT province_name, town_name, SUM(people_served) AS total_ppl_serv
	FROM combined_analysis_table
	GROUP BY province_name,town_name
)
SELECT
	ct.province_name,
	ct.town_name,
	ROUND((SUM(CASE WHEN source_type = 'river'
	THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS river,
	ROUND((SUM(CASE WHEN source_type = 'shared_tap'
	THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS shared_tap,
	ROUND((SUM(CASE WHEN source_type = 'tap_in_home'
	THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home,
	ROUND((SUM(CASE WHEN source_type = 'tap_in_home_broken'
	THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home_broken,
	ROUND((SUM(CASE WHEN source_type = 'well'
	THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS well
	FROM
	combined_analysis_table ct
	JOIN   -- Since the town names are not unique, we have to join on a composite key
	town_totals tt ON ct.province_name = tt.province_name AND ct.town_name = tt.town_name
	GROUP BY  -- We group by province first, then by town.
	ct.province_name,
	ct.town_name
	ORDER BY
	ct.town_name;
	SELECT
	province_name,
	town_name,
	ROUND(tap_in_home_broken / (tap_in_home_broken + tap_in_home) * 100,0) AS Pct_broken_taps,
	ROUND(tap_in_home / (tap_in_home_broken + tap_in_home) * 100,0) as pct_home
	FROM
	town_aggregated_water_access
	;
	/*## There are still many gems hidden in this table. For example, which town has the highest ratio of people who have taps, but have no running water?
	Running this: */
			/* Our final goal is to implement our plan in the database.
			We have a plan to improve the water access in Maji Ndogo, so we need to think it through, and as our final task, create a table where our teams
			have the information they need to fix, upgrade and repair water sources
			## This query creates the Project_progress table:
			*/
use md_water_services;
	CREATE TABLE Project_progress ( -- Project_id SERIAL PRIMARY KEY,
	address VARCHAR(50),
	town_name VARCHAR(30),
	province_name VARCHAR(30),
	source_id VARCHAR(20) NOT NULL REFERENCES water_source(source_id) ON DELETE CASCADE ON UPDATE CASCADE,
	type_of_water_source VARCHAR(50),
	Improvement CHAR(50),
	Source_status VARCHAR(50) DEFAULT 'Backlog' CHECK (Source_status IN ('Backlog', 'In progress', 'Complete')),
	Date_of_completion DATE,
	Comments TEXT
	); -- Run this query, and then we are going to build the query we need to add the data in there.
USE md_water_services;  -- Insert query for the Project_progress_query table
INSERT INTO project_progress (
			address,
			town_name,
			province_name,
			source_id,
			type_of_water_source,
			Improvement,
			Source_status,
			Date_of_completion,
			Comments
		)
		SELECT
			location.address,
			location.town_name,
			location.province_name,
			water_source.source_id,
			water_source.type_of_water_source,
			-- well_pollution.results,
			CASE 
				WHEN well_pollution.results = 'Contaminated: Chemical' THEN 'Install RO filter'
				WHEN well_pollution.results = 'Contaminated: Biological' THEN 'Install UV filter'
				WHEN water_source.type_of_water_source = 'river' THEN 'Drill well'
				WHEN water_source.type_of_water_source = 'shared_tap' AND visits.time_in_queue >= 30 THEN 
					CONCAT("Install ", FLOOR(visits.time_in_queue / 30), " taps nearby")
				WHEN water_source.type_of_water_source = 'tap_in_home_broken' THEN 'Diagnose infrastructure' 
				ELSE 'Null'
			END AS Improvement,
			-- well_pollution.results AS Source_status,
			CASE 
				WHEN well_pollution.results IN ('Contaminated: Chemical', 'Contaminated: Biological') THEN 'In progress'
				ELSE 'Backlog'
				END AS Source_status,
			CURDATE() AS Date_of_completion, -- Capturing current date
			'Monitoring required' AS Comments -- Optional comment based on business logic
		FROM
			water_source
		LEFT JOIN
			well_pollution ON water_source.source_id = well_pollution.source_id
		INNER JOIN
			visits ON water_source.source_id = visits.source_id
		INNER JOIN
			location ON location.location_id = visits.location_id
		WHERE
			visits.visit_count = 1  
			AND (
				well_pollution.results != 'Clean' 
				OR water_source.type_of_water_source IN ('tap_in_home_broken', 'river') 
				OR (water_source.type_of_water_source = 'shared_tap' AND visits.time_in_queue >= 30)
			);
/*
It seems that the Source_status column in the project_progress table has a CHECK constraint that limits its possible values to:
'Backlog'
'In progress'
'Complete'
The issue arises because the well_pollution.results column may contain values outside of this set (e.g., 'Contaminated: Chemical', 'Contaminated: Biological', etc.), which would cause a mismatch with the constraint when you try to insert those values into the Source_status column.
Fix:
You need to modify the value you're inserting into the Source_status column to match one of the allowed values in the CHECK constraint. For instance, you can modify the query so that:
If the result from well_pollution.results is Contaminated: Biological or Contaminated: Chemical, you can update the Source_status to 'In progress' (or whichever status you deem appropriate).
For the default value, if well_pollution.results is NULL or doesn't match the allowed values, you can set the Source_status to 'Backlog'.
Key Changes:
Removed well_pollution.results AS Improvement from the SELECT part. Instead, we rely solely on the CASE statement to define the value of the Improvement column.
This ensures that the number of columns returned in the SELECT statement matches the number of columns you're inserting into (9 columns).
Summary:
The mismatch occurs because you were returning well_pollution.results twice—once for Improvement and again in the Source_status column. After fixing that, the query should now run without errors.
Let me know if this resolves the issue or if you need further help!
*/
    
