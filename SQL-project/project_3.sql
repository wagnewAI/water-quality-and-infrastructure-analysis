#Auditing the Maji Ndogo water project
# Integrating the Auditor's report
SELECT location_id, true_water_source_score
FROM
    md_water_services.auditor_report;
# join the visits table to the auditor_report table. Make sure to grab subjective_quality_score, record_id and location_id.
SELECT
auditor_report.location_id AS audit_location,
auditor_report.true_water_source_score,
visits.location_id AS visit_location,
visits.record_id
FROM
auditor_report
JOIN
visits
ON auditor_report.location_id = visits.location_id;
#--- 
# JOIN the visits table and the water_quality table, using the
-- record_id as the connecting key.
-- subjective_quality_score
SELECT
auditor_report.location_id AS audit_location,
auditor_report.true_water_source_score,
visits.location_id AS visit_location,
visits.record_id,
water_quality.subjective_quality_score
FROM
auditor_report
JOIN
visits
ON auditor_report.location_id = visits.location_id
JOIN
 water_quality
 ON visits.record_id = water_quality.record_id;
/* Now I can drop one of
the location_id columns. Let's leave record_id and rename the scores to surveyor_score and auditor_score to make it clear which scores
we're looking at in the results set.
*/
SELECT
auditor_report.location_id AS location_id,
visits.record_id,
auditor_report.true_water_source_score as auditor_score,
water_quality.subjective_quality_score as surveyor_score
FROM
auditor_report
JOIN
visits
ON auditor_report.location_id = visits.location_id
JOIN
 water_quality
 ON visits.record_id = water_quality.record_id;
 #check if surveyor_score = auditor_score, or we can subtract the two scores and check if the result is 0
 SELECT
auditor_report.location_id AS location_id,
visits.record_id,
auditor_report.true_water_source_score as auditor_score,
water_quality.subjective_quality_score as surveyor_score
FROM
auditor_report
JOIN
visits
ON auditor_report.location_id = visits.location_id
JOIN
 water_quality
 ON visits.record_id = water_quality.record_id
 where auditor_report.true_water_source_score = water_quality.subjective_quality_score ;
 # 2505 rows returned!
 /*  so Some of the locations were visited multiple times, so these records are duplicated here. To fix it, we set visits.visit_count
= 1 in the WHERE clause. Make sure you reference the alias you used for visits in the join
 */ 
 SELECT
auditor_report.location_id AS location_id,
visits.record_id,
auditor_report.true_water_source_score as auditor_score,
water_quality.subjective_quality_score as surveyor_score
FROM
auditor_report
JOIN
visits
ON auditor_report.location_id = visits.location_id
JOIN
 water_quality
 ON visits.record_id = water_quality.record_id
 where auditor_report.true_water_source_score = water_quality.subjective_quality_score 
  AND visits.visit_count = 1;
# 1518 r0ws returned! With the duplicates removed I now get 1518. What does this mean considering the auditor visited 1620 sites?
# I think that is an excellent result. 1518/1620 = 94% of the records the auditor checked were correct!!
# But that means that 102 records are incorrect. So let's look at those. You can do it by adding one character in the last query
use md_water_services;
SELECT
  auditor_report.location_id AS location_id,
  auditor_report.type_of_water_source AS auditor_source,
  visits.record_id,
  auditor_report.true_water_source_score AS auditor_score,
  water_quality.subjective_quality_score AS surveyor_score
FROM
  auditor_report
JOIN
  visits
  ON auditor_report.location_id = visits.location_id
JOIN
  water_quality
  ON water_quality.record_id = visits.record_id
WHERE
  auditor_report.true_water_source_score != water_quality.subjective_quality_score 
   AND visits.visit_count = 1;
# 102 incorrect rows are returned!

use md_water_services;
SELECT
  auditor_report.location_id AS location_id,
  auditor_report.type_of_water_source AS auditor_source,
  water_source.type_of_water_source as survey_source,
  visits.record_id,
  auditor_report.true_water_source_score AS auditor_score,
  water_quality.subjective_quality_score AS surveyor_score
FROM
  auditor_report
JOIN
  visits
  ON auditor_report.location_id = visits.location_id
JOIN
  water_quality
  ON water_quality.record_id = visits.record_id
  JOIN 
  water_source
  ON water_source.source_id = visits.source_id
WHERE
  auditor_report.true_water_source_score != water_quality.subjective_quality_score 
   AND visits.visit_count = 1;
# Once you're done, remove the columns and JOIN statement for water_sources again
----- 
# NOW Linking records to employees!
/* Next up, let's look at where these errors may have come from. At some of the locations, employees assigned scores incorrectly, and those records
ended up in this results set.
I think there are two reasons this can happen.
1. These workers are all humans and make mistakes so this is expected.
2. Unfortunately, the alternative is that someone assigned scores incorrectly on purpose!
*/
use md_water_services;
SELECT
  auditor_report.location_id AS location_id,
  visits.record_id,
 assigned_employee_id,
  auditor_report.true_water_source_score AS auditor_score,
  water_quality.subjective_quality_score AS surveyor_score
FROM
  auditor_report
JOIN
  visits
  ON auditor_report.location_id = visits.location_id
JOIN
  water_quality
  ON water_quality.record_id = visits.record_id
WHERE
  auditor_report.true_water_source_score != water_quality.subjective_quality_score 
   AND visits.visit_count = 1;
/* So now we can link the incorrect records to the employees who recorded them. The ID's don't help us to identify them. We have employees' names
stored along with their IDs, so let's fetch their names from the employees table instead of the ID's.
*/
use md_water_services;
SELECT  
  auditor_report.location_id AS location_id,
  visits.record_id,
  employee_name,
  auditor_report.true_water_source_score AS auditor_score,
  water_quality.subjective_quality_score AS surveyor_score
FROM
  auditor_report
JOIN
  visits
  ON auditor_report.location_id = visits.location_id
JOIN
  water_quality
  ON water_quality.record_id = visits.record_id
  JOIN 
  employee
  ON employee.assigned_employee_id = visits.assigned_employee_id
WHERE
  auditor_report.true_water_source_score != water_quality.subjective_quality_score 
   AND visits.visit_count = 1; 
# make it unique names! using the following query
SELECT DISTINCT
  employee_name
FROM
  auditor_report
JOIN
  visits
  ON auditor_report.location_id = visits.location_id
JOIN
  water_quality
  ON water_quality.record_id = visits.record_id
JOIN 
  employee
  ON employee.assigned_employee_id = visits.assigned_employee_id
WHERE
  auditor_report.true_water_source_score != water_quality.subjective_quality_score 
  AND visits.visit_count = 1;
# output 17 rows returned!
/* Well this query is massive and complex, so maybe it is a good idea to save this as a CTE, so when we do more analysis, we can just call that CTE
like it was a table. Call it something like Incorrect_records. Once you are done, check if this query SELECT * FROM Incorrect_records, gets
the same table back
let's try to calculate how many mistakes each employee made. So basically we want to count how many times their name is in
Incorrect_records list, and then group them by name, right?
*/
use md_water_services;
WITH Incorrect_records AS (
  SELECT
    auditor_report.location_id AS location_id,
    auditor_report.type_of_water_source AS auditor_source,
    visits.record_id,
	assigned_employee_id,
    auditor_report.true_water_source_score AS auditor_score,
    water_quality.subjective_quality_score AS surveyor_score
  FROM
    auditor_report
  JOIN
    visits ON auditor_report.location_id = visits.location_id
  JOIN
    water_quality ON water_quality.record_id = visits.record_id
  WHERE
    auditor_report.true_water_source_score != water_quality.subjective_quality_score
    AND visits.visit_count = 1
)
SELECT 
  e.employee_name,
  count(e.employee_name) as number_of_mistakes
FROM 
  Incorrect_records ir
  JOIN 
  employee e ON ir.assigned_employee_id = e.assigned_employee_id
  group by e.employee_name
  order by number_of_mistakes DESC
  ;
  # Gathering some evidence
  #Ok, so thinking about this a bit. How would we go about finding out if any of our employees are corrupt?
  /* Let's say all employees make mistakes, if someone is corrupt, they will be making a lot of "mistakes", more than average, for example. But someone
could just be clumsy, so we should try to get more evidence...
So let's try to find all of the employees who have an above-average number of mistakes. 
  */
use md_water_services;
WITH Incorrect_records AS (
  SELECT
    auditor_report.location_id AS location_id,
    auditor_report.type_of_water_source AS auditor_source,
    visits.record_id,
    assigned_employee_id,
    auditor_report.true_water_source_score AS auditor_score,
    water_quality.subjective_quality_score AS surveyor_score
  FROM
    auditor_report
  JOIN
    visits ON auditor_report.location_id = visits.location_id
  JOIN
    water_quality ON water_quality.record_id = visits.record_id
  WHERE
    auditor_report.true_water_source_score != water_quality.subjective_quality_score
    AND visits.visit_count = 1
),
Error_Count AS (
  SELECT 
    e.employee_name,
    COUNT(e.employee_name) AS number_of_mistakes
  FROM 
    Incorrect_records ir
  JOIN 
    employee e ON ir.assigned_employee_id = e.assigned_employee_id
  GROUP BY 
    e.employee_name
)
SELECT
  AVG(number_of_mistakes) AS avg_error_count_per_empl
FROM 
  Error_Count;
# output is  avg_error_count_per_empl = 6.00
-- View
CREATE VIEW Incorrect_records AS (
SELECT
auditor_report.location_id,
visits.record_id,
employee.employee_name,
auditor_report.true_water_source_score AS auditor_score,
wq.subjective_quality_score AS surveyor_score,
auditor_report.statements AS statements
FROM
auditor_report
JOIN
visits
ON auditor_report.location_id = visits.location_id
JOIN
water_quality AS wq
ON visits.record_id = wq.record_id
JOIN
employee
ON employee.assigned_employee_id = visits.assigned_employee_id
WHERE
visits.visit_count =1
AND auditor_report.true_water_source_score != wq.subjective_quality_score);
SELECT * FROM Incorrect_records;
-- 
-- 
USE md_water_services;

WITH Incorrect_records AS (
  SELECT
    auditor_report.location_id AS location_id,
    auditor_report.type_of_water_source AS auditor_source,
    visits.record_id,
    employee.assigned_employee_id,
    employee.employee_name,
    auditor_report.true_water_source_score AS auditor_score,
    water_quality.subjective_quality_score AS surveyor_score,
    auditor_report.statements AS statements
  FROM
    auditor_report
  JOIN
    visits ON auditor_report.location_id = visits.location_id
  JOIN
    water_quality ON water_quality.record_id = visits.record_id
  JOIN
    employee ON visits.assigned_employee_id = employee.assigned_employee_id
  WHERE
    auditor_report.true_water_source_score != water_quality.subjective_quality_score
    AND visits.visit_count = 1
),
error_count AS (
  SELECT
    employee_name,
    COUNT(employee_name) AS number_of_mistakes
  FROM
    Incorrect_records
  GROUP BY
    employee_name
),
suspect_list AS (
  SELECT
    employee_name,
    number_of_mistakes
  FROM
    error_count
  WHERE
    number_of_mistakes > (SELECT AVG(number_of_mistakes) FROM error_count)
)
SELECT
  employee_name,
  location_id,
  statements
FROM
  Incorrect_records
WHERE
  employee_name IN (SELECT employee_name FROM suspect_list)
   AND LOWER(statements) LIKE '%cash%';
   -- AND location_id not IN ('AkRu04508', 'AkRu07310', 'KiRu29639', 'AmAm09607');
-- 
--

USE md_water_services;

WITH Incorrect_records AS (
  SELECT
    auditor_report.location_id AS location_id,
    auditor_report.type_of_water_source AS auditor_source,
    visits.record_id,
    employee.assigned_employee_id,
    employee.employee_name,
    auditor_report.true_water_source_score AS auditor_score,
    water_quality.subjective_quality_score AS surveyor_score,
    auditor_report.statements AS statements
  FROM
    auditor_report
  JOIN
    visits ON auditor_report.location_id = visits.location_id
  JOIN
    water_quality ON water_quality.record_id = visits.record_id
  JOIN
    employee ON visits.assigned_employee_id = employee.assigned_employee_id
  WHERE
    auditor_report.true_water_source_score != water_quality.subjective_quality_score
    AND visits.visit_count = 1
),
error_count AS (
  SELECT
    employee_name,
    COUNT(employee_name) AS number_of_mistakes
  FROM
    Incorrect_records
  GROUP BY
    employee_name
),
suspect_list AS (
  SELECT
    employee_name,
    number_of_mistakes
  FROM
    error_count
  WHERE
    number_of_mistakes > (SELECT AVG(number_of_mistakes) FROM error_count)
)
SELECT
  employee_name,
  location_id,
  statements
FROM
  Incorrect_records
WHERE
  employee_name NOT IN (SELECT employee_name FROM suspect_list)
   AND LOWER(statements) LIKE '%cash%';
-- AND location_id IN ('AkRu04508', 'AkRu07310', 'KiRu29639', 'AmAm09607');  -- Case-insensitive match for "cash"
    # The output is zero 
  /* So we can sum up the evidence we have for Zuriel Matembo, Malachi Mavuso, Bello Azibo and Lalitha Kaburi:
1. They all made more mistakes than their peers on average.
2. They all have incriminating statements made against them, and only them.
Keep in mind, that this is not decisive proof, but it is concerning enough that we should flag it. Pres. Naledi has worked hard to stamp out
corruption, so she would urge us to report this.;
   -- AND location_id IN ('AkRu04508', 'AkRu07310', 'KiRu29639', 'AmAm09607');  -- Case-insensitive match for "cash"
*/
