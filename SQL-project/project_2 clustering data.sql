#.Clustering data to unveil Maji Ndogo's water crisis
/*Cleaning our data
Ok, bring up the employee table. It has info on all of our workers, but note that the email addresses have not been added. We will have to send
them reports and figures, so let's update it. Luckily the emails for our department are easy: first_name.last_name@ndogowater.gov.*/
use md_water_services;
SELECT *
FROM employee;
 /* Determine the email address for each employee by:
- selecting the employee_name column
- replacing the space with a full stop
- make it lowercase
- and stitch it all together
 */
 SELECT
       LOWER(REPLACE(employee_name, ' ','.')) 
FROM
    employee;
  # then use CONCAT() to add the rest of the email address:
  SET @sql_saff_updates = 0;
  UPDATE employee
  SET email = CONCAT(LOWER(REPLACE(employee_name, ' ', '.')),
  '@ndogowater.gov');
  
SELECT
	   LENGTH(phone_number)
FROM
	employee;
/* Use the employee table to count how many of our employees live in each town. Think carefully about what function we should use and how we
should aggregate the data*/
SELECT 
	town_name, COUNT(*) AS num_employees
FROM employee
GROUP BY town_name
ORDER BY num_employees DESC;
/* So find the correct table, figure out what function to use and how to group, order
and limit the results to only see the top 3 employee_ids with the highest number of locations visited
*/
SELECT 
      assigned_employee_id, count(visit_count) as number_of_visits
FROM visits
GROUP BY assigned_employee_id
ORDER BY number_of_visits DESC
LIMIT 3;
/* Analysing locations
Looking at the location table, let’s focus on the province_name, town_name and location_type to understand where the water sources are in
Maji Ndogo
*/
SELECT 
      town_name, COUNT(*) as record_count
FROM location
GROUP BY town_name
ORDER BY town_name;
# per province
/*i can find a way to do the following:
1. Create a result set showing:
• province_name
• town_name
• An aggregated count of records for each town (consider naming this records_per_town).
• Ensure the data is grouped by both province_name and town_name.
2.the results ordered primarily by province_name. Within each province, further sort the towns by their record counts in descending order
*/

SELECT 
    province_name, 
    town_name, 
    COUNT(*) as records_per_town
FROM location
GROUP BY province_name, town_name
ORDER BY province_name ASC, records_per_town DESC;
# using common table expresion!
WITH TownCounts AS (
    SELECT 
        province_name, 
        town_name, 
        COUNT(*) as records_per_town
    FROM location
    GROUP BY province_name, town_name
)
SELECT province_name, town_name, records_per_town
FROM TownCounts
ORDER BY province_name ASC, records_per_town DESC;
/*
CTE's--serves as a temporary, named result set that simplifies the structure and improves readability of the SQL query.
1. modularity and redability
2.The CTE acts like a temporary table that can be referenced multiple times in the main query (though in this case, it's used only once).
If you needed to join or filter the grouped results further, the CTE provides a clean way to reuse the aggregated data without repeating the GROUP BY logic.
3. Logical Separation: It breaks the query into logical steps: first, compute the counts (TownCounts), then sort and display the results. This can make debugging or modifying the query easier.
*/
# look at the number of records for each location type
SELECT 
    location_type, 
    COUNT(*) as record_count
FROM location
GROUP BY location_type
ORDER BY record_count DESC;

SELECT 23740 / (15910 + 23740) * 100;
# using Common table expression (CTE)
WITH LocationCounts AS (
    SELECT 
        location_type, 
        COUNT(*) as record_count
    FROM location
    GROUP BY location_type
),
TotalCount AS (
    SELECT SUM(record_count) as total_records
    FROM LocationCounts
)
SELECT 
    lc.location_type,
    lc.record_count,
    ROUND((lc.record_count * 100.0 / tc.total_records), 2) as percentage
FROM LocationCounts lc
CROSS JOIN TotalCount tc
ORDER BY lc.record_count DESC;
 # window functions
 SELECT 
    location_type,
    COUNT(*) as record_count,
    ROUND((COUNT(*) * 100.0 / SUM(COUNT(*)) OVER ()) , 2) as percentage
FROM location
GROUP BY location_type
ORDER BY record_count DESC;
# I can see that 60% of all water sources in the data set are in rural communities.
/* Efficiency: Window functions are often more concise and can be more efficient than subqueries or CTEs for this type of calculation, as they avoid multiple table scans.
*/
# ------ 
# water_source table
/*
Diving into the sources
Ok, water_source is a big table, with lots of stories to tell, so strap in*/
SELECT *
FROM water_source;

/*These are the questions that I am curious about.
1. How many people did we survey in total?
2. How many wells, taps and rivers are there?
3. How many people share particular types of water sources on average?
4. How many people are getting water from each type of source?
*/
#1.How many people did we survey in total?
SELECT sum(number_of_people_served) as total
FROM water_source;
# output = '27628140' =~ 28 million people 
#2.  How many wells, taps and rivers are there?
SELECT type_of_water_source, COUNT(*) as count
FROM water_source
# WHERE type_of_water_source IN ('well', 'tap', 'river')
GROUP BY type_of_water_source;
#3. How many people share particular types of water sources on average?
SELECT type_of_water_source, round(AVG(number_of_people_served),0) as avg_people_served
FROM water_source
GROUP BY type_of_water_source;
# These results are telling me that 644 people share a tap_in_home on average and 2077 shared tap!
/* the result does not make sense!
here is an average of
6 people living in a home. So 6 people actually share 1 tap (not 644).
This means that 1 tap_in_home actually represents 644 ÷ 6 = ± 100 taps. */
/*Now let’s calculate the total number of people served by each type of water source in total, to make it easier to interpret, order them so the most
people served by a source is at the top */
#4.  How many people are getting water from each type of source?
SELECT type_of_water_source, sum(number_of_people_served) as total_people_served
FROM water_source
GROUP BY type_of_water_source
ORDER BY total_people_served DESC;
# The percentage
SELECT 
    type_of_water_source, 
    sum(number_of_people_served) as total_people_served,
    round((sum(number_of_people_served) * 100.0 / (SELECT sum(number_of_people_served) FROM water_source)),0) as percentage
FROM water_source
GROUP BY type_of_water_source
ORDER BY total_people_served DESC;
# 43% of our people are using shared taps in their communities, and on average, I saw earlier, that 2000 people share one shared_tap
/* Start of a solution
At some point, I will have to fix or improve all of the infrastructure, so I should start thinking about how I can make a data-driven decision
how to do it. 
*/
# RANK() should tell me i am going to need a window function to do this
SELECT 
 type_of_water_source,
    SUM(number_of_people_served) AS total_people_served,
    RANK() OVER (ORDER BY SUM(number_of_people_served) DESC) AS rank_by_people_served
FROM 
    water_source
GROUP BY 
    type_of_water_source
ORDER BY 
    total_people_served DESC;
/* Ok, so I should fix shared taps first, then wells, and so on. But the next question is, which shared taps or wells should be fixed first? I can use
the same logic; the most used sources should really be fixed first.
    */
    /* So create a query to do this, and keep these requirements in mind:
1. The sources within each type should be assigned a rank.
2. Limit the results to only improvable sources.
3. Think about how to partition, filter and order the results set.
4. Order the results to see the top of the list
    */
    WITH RankedSources AS (
    SELECT 
        s.source_id,
        s.number_of_people_served,
        s.type_of_water_source,
       ROW_NUMBER() OVER (
            PARTITION BY s.type_of_water_source 
        ) as source_rank
    FROM 
       water_source s
)
SELECT 
    source_id,
    type_of_water_source,
    number_of_people_served,
    source_rank
FROM 
    RankedSources
WHERE 
    #source_rank <= 10
    source_id in ('AmRu14978224', 'HaDj16848224', 'HaRu19509224', 'AkRu05603224', 'AkRu04862224')
ORDER BY 
	type_of_water_source ASC,
    source_rank DESC;
    # Analysing queues
    /*Ok, this is the really big, and last table i'll look at this time. The analysis is going to be a bit tough, but the results will be worth it, so stretch out,
grab a drink, and let's go!
    # These are some of the things I think are worth looking at:
1. How long did the survey take?
2. What is the average total queue time for water?
3. What is the average queue time on different days?
4. How can we communicate this information efficiently
    */
    SELECT *
    FROM visits;
#control flow, DateTime and window functions are important to do these !
# 1. How long did the survey take?
/* we need to get the first and last dates (which functions can find the largest/smallest value), and subtract
them. Remember with DateTime data, we can't just subtract the values. We have to use a function to get the difference in days.
*/
SELECT 
    MIN(time_of_record) AS survey_start,
    MAX(time_of_record) AS survey_end,
    DATEDIFF(MAX(time_of_record), MIN(time_of_record)) AS survey_duration_days
FROM 
    visits;
    # When I do it, I get 924 days which is about 2 and a half years!
   #change to two and half years
   SELECT 
	DATEDIFF(MAX(time_of_record), MIN(time_of_record))/365 as results
FROM 
    md_water_services.visits;
# 2. What is the average total queue time for water?
/* Keep in mind that many sources like taps_in_home have no queues. These
are just recorded as 0 in the time_in_queue column, so when I calculate averages, I need to exclude those rows. using NULLIF() do to
this.
*/
SELECT
	 avg(time_in_queue) as results
FROM 
    md_water_services.visits
    WHERE time_in_queue > 0;
# Using NULLIF() Function!
SELECT
	AVG(NULLIF(time_in_queue, 0)) AS avg_queue_time_minutes
FROM 
    md_water_services.visits;
    
#let's look at the queue times aggregated across the different days of the week
# 3. What is the average queue time on different days?
SELECT 
    dayname(time_of_record) as day_of_week,
    ROUND(avg(time_in_queue)) as avg_queue_time
FROM 
    md_water_services.visits
    WHERE time_in_queue > 0
    group by day_of_week;
# Wow, ok Saturdays have much longer queue times compared to the other days!
# 4. How can we communicate this information efficiently
# I can also look at what time during the day people collect water.
SELECT 
	  hour(time_of_record) as hour_of_day,
      ROUND(avg(time_in_queue)) as avg_queue_time
FROM 
    md_water_services.visits
    WHERE time_in_queue > 0
    group by hour_of_day
    order by hour_of_day ASC;
#  A format like 06:00 will be easier to read, so let's use that
SELECT 
	  TIME_FORMAT(TIME(time_of_record), '%H:00') AS hour_of_day,
      ROUND(avg(time_in_queue)) as avg_queue_time
FROM 
    md_water_services.visits
    WHERE time_in_queue > 0
    group by hour_of_day
    order by hour_of_day ASC;
# use the hour of the day in that nice format, and then make each column a different day!
SELECT
TIME_FORMAT(TIME(time_of_record), '%H:00') AS hour_of_day,
-- Sunday
ROUND(AVG(
CASE
WHEN DAYNAME(time_of_record) = 'Sunday' THEN time_in_queue
ELSE NULL
END
),0) AS Sunday,
-- Monday
ROUND(AVG(
CASE
WHEN DAYNAME(time_of_record) = 'Monday' THEN time_in_queue
ELSE NULL
END
),0) AS Monday,
-- Tuesday
-- Wednesday
ROUND(AVG(
CASE
WHEN DAYNAME(time_of_record) = 'Tuesday' THEN time_in_queue
ELSE NULL
END
),0) AS Tuesday,
ROUND(AVG(
CASE
WHEN DAYNAME(time_of_record) = 'Wednesday' THEN time_in_queue
ELSE NULL
END
),0) AS Wednesday,
ROUND(AVG(
CASE
WHEN DAYNAME(time_of_record) = 'Thursday' THEN time_in_queue
ELSE NULL
END
),0) AS Thursday,
ROUND(AVG(
CASE
WHEN DAYNAME(time_of_record) = 'Friday' THEN time_in_queue
ELSE NULL
END
),0) AS Friday,
ROUND(AVG(
CASE
WHEN DAYNAME(time_of_record) = 'Saturday' THEN time_in_queue
ELSE NULL
END
),0) AS Saturday
FROM
md_water_services.visits
WHERE
time_in_queue != 0 -- this excludes other sources with 0 queue times
GROUP BY
hour_of_day
ORDER BY
hour_of_day; 
# In the bar gragh, The colors represent the hours of the day, and each bar is the average queue time, for that specific hour and day