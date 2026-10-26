CREATE TABLE clinical_trial_raw (
    subject_id INTEGER,
    site_id INTEGER,
    age INTEGER,
    gender VARCHAR(20),
    enrollment_date VARCHAR(20),
    treatment_group VARCHAR(30),
    adverse_events INTEGER,
    dropout INTEGER, 
    systolic_bp INTEGER,
    diastolic_bp INTEGER,
    cholesterol_level INTEGER
);

select * 
from clinical_trial_raw;

-- total records
SELECT COUNT(*) AS total_records
FROM clinical_trial_raw;

-- Unique patients
SELECT COUNT(DISTINCT subject_id) AS unique_patients
FROM clinical_trial_raw;

-- treatment group
SELECT DISTINCT treatment_group
FROM clinical_trial_raw;

-- Based on treatment group , subjects that are randomized
select treatment_group,
COUNT (*) AS total_patients
from clinical_trial_raw 
Group by treatment_group
Order by total_patients DESC;

--- no of sites 
SELECT COUNT(DISTINCT site_id) AS total_sites
FROM clinical_trial_raw;

--- Patient Demographics 

--- AGE ANALYSIS
SELECT
    ROUND(AVG(age), 2) AS average_age,
    MIN(age) AS youngest_patient,
    MAX(age) AS oldest_patient
FROM clinical_trial_raw;

-- GENDER DISTRIBUTION
SELECT
    gender,
    COUNT(*) AS total_patients
FROM clinical_trial_raw
GROUP BY gender
ORDER BY total_patients DESC;

-- PATIENTS ABOVE 60 YEARS
SELECT
    subject_id,
    age,
    gender,
    treatment_group
FROM clinical_trial_raw
WHERE age > 60
ORDER BY age DESC;

-- PATIENTS BETWEEN 40 AND 60 YEARS
SELECT
    subject_id,
    age,
    gender
FROM clinical_trial_raw
WHERE age BETWEEN 40 AND 60;

-- PATIENTS RECEIVING ACTIVE TREATMENTS
SELECT
    subject_id,
    age,
    gender,
    treatment_group
FROM clinical_trial_raw
WHERE treatment_group IN ('Drug A', 'Drug B');

-- AVERAGE AGE IN EACH TREATMENT GROUP
SELECT
    treatment_group,
    COUNT(*) AS total_patients,
    ROUND(AVG(age), 2) AS average_age,
    MIN(age) AS minimum_age,
    MAX(age) AS maximum_age
FROM clinical_trial_raw
GROUP BY treatment_group
ORDER BY treatment_group;


-- DATA VALIDATION
SELECT
    COUNT(*) AS total_records,
    COUNT(*) FILTER (WHERE subject_id IS NULL) AS missing_subject_id,
    COUNT(*) FILTER (WHERE age IS NULL) AS missing_age,
    COUNT(*) FILTER (WHERE gender IS NULL) AS missing_gender,
    COUNT(*) FILTER (WHERE treatment_group IS NULL) AS missing_treatment,
    COUNT(*) FILTER (WHERE systolic_bp IS NULL) AS missing_systolic_bp,
    COUNT(*) FILTER (WHERE diastolic_bp IS NULL) AS missing_diastolic_bp,
    COUNT(*) FILTER (WHERE adverse_events IS NULL) AS missing_adverse_events,
    COUNT(*) FILTER (WHERE dropout IS NULL) AS missing_dropout
FROM clinical_trial_raw;

---DUP VALUES
SELECT
    subject_id,
    COUNT(*) AS duplicate_count
FROM clinical_trial_raw
GROUP BY subject_id
HAVING COUNT(*) > 1;

-- INVALID AGE
SELECT *
FROM clinical_trial_raw
WHERE age <= 0
   OR age > 120;

-- INVALID TREATMENT GROUP VALUES
SELECT *
FROM clinical_trial_raw
WHERE treatment_group NOT IN ('Drug A', 'Drug B', 'Placebo')
   OR treatment_group IS NULL;

-- INVALID CLINICAL MEASUREMENTS
SELECT *
FROM clinical_trial_raw
WHERE systolic_bp <= 0
   OR diastolic_bp <= 0
   OR cholesterol_level <= 0
   OR systolic_bp < diastolic_bp;

-- CLINICAL INDICATORS
SELECT *
FROM clinical_trial_raw
WHERE adverse_events NOT IN (0, 1)
   OR dropout NOT IN (0, 1);

--- DATA CLEANING
CREATE TABLE clinical_trial_cleaned AS
SELECT *
FROM clinical_trial_raw;

SELECT
    'Raw Data' AS table_name,
    COUNT(*) AS total_records
FROM clinical_trial_raw

UNION ALL

SELECT
    'Cleaned Working Data',
    COUNT(*)
FROM clinical_trial_cleaned;

SELECT
    subject_id,
    systolic_bp,
    diastolic_bp
FROM clinical_trial_cleaned
WHERE diastolic_bp > systolic_bp ;

SELECT
    adverse_events,
    COUNT(*) AS patient_count
FROM clinical_trial_cleaned
GROUP BY adverse_events
ORDER BY adverse_events ;

-- Blood Pressure Data Cleaning
-- 1) BP Quality Flag

ALTER TABLE clinical_trial_cleaned
ADD COLUMN bp_quality_flag VARCHAR(20);

UPDATE clinical_trial_cleaned
SET bp_quality_flag =
    CASE
        WHEN systolic_bp IS NULL
          OR diastolic_bp IS NULL
            THEN 'MISSING'

        WHEN systolic_bp <= 0
          OR diastolic_bp <= 0
          OR diastolic_bp >= systolic_bp
            THEN 'INVALID'

        ELSE 'VALID'
    END;

SELECT
    bp_quality_flag,
    COUNT(*) AS total_patients
FROM clinical_trial_cleaned
GROUP BY bp_quality_flag
ORDER BY bp_quality_flag;

-- Adverse Event Indicator
ALTER TABLE clinical_trial_cleaned
ADD COLUMN ae_indicator INTEGER;

UPDATE clinical_trial_cleaned
SET ae_indicator =
    CASE
        WHEN adverse_events IS NULL
          OR adverse_events < 0 THEN NULL
        WHEN adverse_events = 0 THEN 0
        WHEN adverse_events = 1 THEN 1
        WHEN adverse_events >= 2 THEN 2
    END;

SELECT
    ae_indicator,
    COUNT(*) AS total_patients
FROM clinical_trial_cleaned
GROUP BY ae_indicator
ORDER BY ae_indicator; 

select subject_id,adverse_events, ae_indicator from clinical_trial_cleaned;

SELECT
    CASE
        WHEN ae_indicator = 0 THEN 'No Adverse Event'
        WHEN ae_indicator = 1 THEN 'Exactly One Adverse Event'
        WHEN ae_indicator = 2 THEN 'Multiple Adverse Events'
        ELSE 'Unknown'
    END AS ae_category,
    COUNT(*) AS patient_count
FROM clinical_trial_cleaned
GROUP BY ae_indicator
ORDER BY ae_indicator;

SELECT
    COUNT(*) AS total_patients,

    COUNT(*) FILTER (
        WHERE bp_quality_flag = 'VALID'
    ) AS valid_bp_records,

    COUNT(*) FILTER (
        WHERE bp_quality_flag = 'INVALID'
    ) AS invalid_bp_records,

    COUNT(*) FILTER (
        WHERE ae_indicator = 1
    ) AS patients_with_ae,

    COUNT(*) FILTER (
        WHERE ae_indicator = 0
    ) AS patients_without_ae

FROM clinical_trial_cleaned;

-- CHECK EXISTING DATE FORMAT
SELECT
    subject_id,
    enrollment_date
FROM clinical_trial_cleaned
LIMIT 10;

-- NEW DATE COLUMN
ALTER TABLE clinical_trial_cleaned
ADD COLUMN enrollment_date_clean DATE;

UPDATE clinical_trial_cleaned
SET enrollment_date_clean =
    TO_DATE(enrollment_date, 'MM/DD/YY')
WHERE enrollment_date IS NOT NULL;

SELECT
    subject_id,
    enrollment_date,
    enrollment_date_clean
FROM clinical_trial_cleaned
LIMIT 10;

-- MISSING CONVERTED DATES
SELECT
    COUNT(*) AS total_records,
    COUNT(*) FILTER (
        WHERE enrollment_date_clean IS NULL
    ) AS missing_dates
FROM clinical_trial_cleaned;

-- ENROLLMENT DATE RANGE
SELECT
    MIN(enrollment_date_clean) AS first_enrollment,
    MAX(enrollment_date_clean) AS last_enrollment
FROM clinical_trial_cleaned;


--- CLINICAL TRIAL ANALYSIS

-- patient wise distribution AE
select 
COUNT (*) AS total_patients, 
treatment_group from clinical_trial_cleaned
GROUP BY treatment_group      
ORDER BY treatment_group DESC;

-- Patients With and Without Adverse Events
SELECT
    treatment_group,
    COUNT(*) AS total_patients,

    COUNT(*) FILTER (
        WHERE ae_indicator IN (1, 2)
    ) AS patients_with_ae,

    COUNT(*) FILTER (
        WHERE ae_indicator = 0
    ) AS patients_without_ae

FROM clinical_trial_cleaned
GROUP BY treatment_group
ORDER BY treatment_group;

-- Treatment Group-wise Adverse Event Rate (%)
SELECT
    treatment_group,

    COUNT(*) FILTER (
        WHERE ae_indicator IS NOT NULL
    ) AS evaluable_patients,

    COUNT(*) FILTER (
        WHERE ae_indicator IN (1, 2)
    ) AS patients_with_ae,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE ae_indicator IN (1, 2)
        )
        / NULLIF(
            COUNT(*) FILTER (
                WHERE ae_indicator IS NOT NULL
            ), 0
        ),
        2
    ) AS ae_rate_percentage

FROM clinical_trial_cleaned
GROUP BY treatment_group
ORDER BY ae_rate_percentage DESC ;

-- Single and Multiple Adverse Events Analysis
SELECT
    treatment_group,

    COUNT(*) FILTER (
        WHERE ae_indicator = 1
    ) AS single_ae_patients,

    COUNT(*) FILTER (
        WHERE ae_indicator = 2
    ) AS multiple_ae_patients,

    ROUND(
        AVG(adverse_events) FILTER (
            WHERE adverse_events >= 0
        )::numeric,
        2
    ) AS mean_ae_count

FROM clinical_trial_cleaned
GROUP BY treatment_group
ORDER BY treatment_group;

-- Treatment Group-wise Patient Dropout
SELECT
    treatment_group,
    COUNT(*) AS total_patients,
    COUNT(*) FILTER (WHERE dropout = 1) AS dropped_patients,
    COUNT(*) FILTER (WHERE dropout = 0) AS retained_patients
FROM clinical_trial_cleaned
GROUP BY treatment_group
ORDER BY treatment_group;

-- Treatment Group-wise Dropout Rate (%)
SELECT
    treatment_group,
    COUNT(dropout) AS total_patients,
    SUM(CASE WHEN dropout = 1 THEN 1 ELSE 0 END) AS dropouts,

    ROUND(
        100.0 * SUM(CASE WHEN dropout = 1 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(dropout), 0),
        2
    ) AS dropout_rate_percentage

FROM clinical_trial_cleaned
GROUP BY treatment_group
ORDER BY dropout_rate_percentage DESC;

-- Adverse Events vs Patient Dropout
SELECT
    treatment_group,
    ae_indicator,
    COUNT(*) AS total_patients,

    COUNT(*) FILTER (
        WHERE dropout = 1
    ) AS dropout_count,

    ROUND(
        100.0 * COUNT(*) FILTER 
		(WHERE dropout = 1)
		
		/ NULLIF(COUNT(dropout), 0),
        2
    ) AS dropout_rate_percentage

FROM clinical_trial_cleaned
WHERE ae_indicator IS NOT NULL
GROUP BY treatment_group, ae_indicator
ORDER BY treatment_group, ae_indicator;

-- Dropout Distribution by Age & Gender
SELECT
    CASE
        WHEN age < 40 THEN 'Below 40'
        WHEN age BETWEEN 40 AND 59 THEN '40-59'
        ELSE '60 and Above'
    END AS age_group,

    gender,
    COUNT(*) AS total_patients,

    COUNT(*) FILTER (
        WHERE dropout = 1
    ) AS dropout_count,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE dropout = 1
        ) / NULLIF(COUNT(dropout), 0),
        2
    ) AS dropout_rate_percentage

FROM clinical_trial_cleaned
WHERE age IS NOT NULL
GROUP BY age_group, gender
ORDER BY age_group, gender;

-- Treatment Group-wise Average Blood Pressure
SELECT
    treatment_group,
    COUNT(*) AS valid_patients,

    ROUND(AVG(systolic_bp), 2) AS avg_systolic_bp,
    ROUND(AVG(diastolic_bp), 2) AS avg_diastolic_bp

FROM clinical_trial_cleaned
WHERE bp_quality_flag = 'VALID'
GROUP BY treatment_group
ORDER BY treatment_group;

-- Treatment-wise Minimum and Maximum BP
SELECT
    treatment_group,

    MIN(systolic_bp) AS min_systolic,
    MAX(systolic_bp) AS max_systolic,

    MIN(diastolic_bp) AS min_diastolic,
    MAX(diastolic_bp) AS max_diastolic

FROM clinical_trial_cleaned
WHERE bp_quality_flag = 'VALID'
GROUP BY treatment_group
ORDER BY treatment_group;

-- Blood Pressure Category Distribution
SELECT
    treatment_group,
    COUNT(*) AS patient_count,
    CASE
        WHEN systolic_bp >= 140
          OR diastolic_bp >= 90
            THEN 'High BP (140/90 or above)'

        WHEN systolic_bp >= 130
          OR diastolic_bp >= 80
            THEN 'BP 130/80 to below 140/90'

        ELSE 'Below 130/80'
    END AS bp_category

FROM clinical_trial_cleaned
WHERE bp_quality_flag = 'VALID'

GROUP BY treatment_group, bp_category
ORDER BY treatment_group, bp_category;

-- Patients with BP ≥140/90 (%)
SELECT
    treatment_group,

    COUNT(*) AS valid_patients,

    COUNT(*) FILTER (
        WHERE systolic_bp >= 140
           OR diastolic_bp >= 90
    ) AS high_bp_patients,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE systolic_bp >= 140
               OR diastolic_bp >= 90
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS high_bp_percentage

FROM clinical_trial_cleaned
WHERE bp_quality_flag = 'VALID'
GROUP BY treatment_group
ORDER BY high_bp_percentage DESC;

-- Treatment Group-wise Invalid BP Records
SELECT
    treatment_group,

    COUNT(*) AS total_patients,

    COUNT(*) FILTER (
        WHERE bp_quality_flag = 'INVALID'
    ) AS invalid_bp_records,

    COUNT(*) FILTER (
        WHERE bp_quality_flag = 'VALID'
    ) AS valid_bp_records,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE bp_quality_flag = 'INVALID'
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS invalid_bp_percentage

FROM clinical_trial_cleaned
GROUP BY treatment_group
ORDER BY invalid_bp_percentage DESC;


-- Site-wise Patient Enrollment
SELECT
    site_id,
    COUNT(*) AS total_patients
FROM clinical_trial_cleaned
GROUP BY site_id
ORDER BY total_patients DESC;

-- Top 10 Sites by Patient Enrollment
SELECT
    site_id,
    COUNT(*) AS total_patients
FROM clinical_trial_cleaned
GROUP BY site_id
ORDER BY total_patients DESC
LIMIT 10;

--- Site-wise Adverse Event Rate (%)
SELECT
    site_id,
    COUNT(ae_indicator) AS evaluable_patients,

    COUNT(*) FILTER (
        WHERE ae_indicator IN (1, 2)
    ) AS patients_with_ae,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE ae_indicator IN (1, 2)
        ) / NULLIF(COUNT(ae_indicator), 0),
        2
    ) AS ae_rate_percentage

FROM clinical_trial_cleaned
GROUP BY site_id
ORDER BY ae_rate_percentage DESC;

-- Site-wise Dropout Rate (%)
SELECT
    site_id,
    COUNT(dropout) AS evaluable_patients,

    COUNT(*) FILTER (
        WHERE dropout = 1
    ) AS dropped_patients,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE dropout = 1
        ) / NULLIF(COUNT(dropout), 0),
        2
    ) AS dropout_rate_percentage

FROM clinical_trial_cleaned
GROUP BY site_id
ORDER BY dropout_rate_percentage DESC NULLS LAST;


-- Site-wise Data Quality Analysis
SELECT
    site_id,
    COUNT(*) AS total_patients,

    COUNT(*) FILTER (
        WHERE bp_quality_flag = 'INVALID'
    ) AS invalid_bp_records,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE bp_quality_flag = 'INVALID'
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS invalid_bp_percentage

FROM clinical_trial_cleaned
GROUP BY site_id
ORDER BY invalid_bp_percentage DESC;

-- Combined Clinical Site Performance Summary
SELECT
    site_id,
    COUNT(*) AS total_patients,

    COUNT(*) FILTER (
        WHERE ae_indicator IN (1, 2)
    ) AS patients_with_ae,

    COUNT(*) FILTER (
        WHERE dropout = 1
    ) AS dropouts,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE dropout = 1
        ) / NULLIF(COUNT(dropout), 0),
        2
    ) AS dropout_rate,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE ae_indicator IN (1, 2)
        ) / NULLIF(COUNT(ae_indicator), 0),
        2
    ) AS ae_rate

FROM clinical_trial_cleaned
GROUP BY site_id
ORDER BY total_patients DESC;

-- Monthly Patient Enrollment Trend
SELECT
    DATE_TRUNC('month', enrollment_date_clean)::DATE
        AS enrollment_month,

    COUNT(*) AS total_enrollments

FROM clinical_trial_cleaned
WHERE enrollment_date_clean IS NOT NULL

GROUP BY enrollment_month
ORDER BY enrollment_month;

-- Year-wise Patient Enrollment
SELECT
    EXTRACT(YEAR FROM enrollment_date_clean)
        AS enrollment_year,

    COUNT(*) AS total_enrollments

FROM clinical_trial_cleaned
WHERE enrollment_date_clean IS NOT NULL

GROUP BY enrollment_year
ORDER BY enrollment_year;

-- Treatment Group-wise Monthly Enrollment
SELECT
    DATE_TRUNC('month', enrollment_date_clean)::DATE
        AS enrollment_month,

    treatment_group,

    COUNT(*) AS enrolled_patients

FROM clinical_trial_cleaned
WHERE enrollment_date_clean IS NOT NULL

GROUP BY enrollment_month, treatment_group

ORDER BY enrollment_month, treatment_group;

-- Top 10 Clinical Sites by Enrollment
SELECT
    site_id,
    COUNT(*) AS total_enrollments

FROM clinical_trial_cleaned
WHERE enrollment_date_clean IS NOT NULL

GROUP BY site_id
ORDER BY total_enrollments DESC
LIMIT 10;

-- First & Last Enrollment Date by Site
SELECT
    site_id,

    MIN(enrollment_date_clean)
        AS first_enrollment_date,

    MAX(enrollment_date_clean)
        AS last_enrollment_date,

    COUNT(*) AS total_enrollments

FROM clinical_trial_cleaned
WHERE enrollment_date_clean IS NOT NULL

GROUP BY site_id
ORDER BY site_id;

-- Month-wise Enrollment by Site
SELECT
    site_id,

    DATE_TRUNC('month', enrollment_date_clean)::DATE
        AS enrollment_month,

    COUNT(*) AS enrolled_patients

FROM clinical_trial_cleaned
WHERE enrollment_date_clean IS NOT NULL

GROUP BY site_id, enrollment_month

ORDER BY site_id, enrollment_month;

--- ADVANCED SQL ANALYSIS

-- CTE: Treatment Group-wise Safety Summary
WITH treatment_safety AS (
    SELECT
        treatment_group,
        COUNT(*) AS total_patients,

        COUNT(*) FILTER (
            WHERE ae_indicator IN (1, 2)
        ) AS patients_with_ae

    FROM clinical_trial_cleaned
    GROUP BY treatment_group
)

SELECT
    treatment_group,
    total_patients,
    patients_with_ae,

    ROUND(
        100.0 * patients_with_ae
        / NULLIF(total_patients, 0),
        2
    ) AS ae_rate_percentage

FROM treatment_safety
ORDER BY ae_rate_percentage DESC;

-- Window Function: Rank Clinical Sites by Enrollment

SELECT
    site_id,
    COUNT(*) AS total_patients,

    RANK() OVER (ORDER BY COUNT(*) DESC) AS site_rank

FROM clinical_trial_cleaned
GROUP BY site_id
ORDER BY site_rank;

-- DENSE_RANK: Treatment-wise Site Ranking
SELECT
    treatment_group,
    site_id,
    COUNT(*) AS total_patients,

    DENSE_RANK() OVER (
        PARTITION BY treatment_group
        ORDER BY COUNT(*) DESC
    ) AS site_rank

FROM clinical_trial_cleaned
GROUP BY treatment_group, site_id
ORDER BY treatment_group, site_rank;

-- LAG: Month-over-Month Enrollment Change
WITH monthly_enrollment AS (
    SELECT
        DATE_TRUNC('month', enrollment_date_clean)::DATE
            AS enrollment_month,
        COUNT(*) AS total_patients
    FROM clinical_trial_cleaned
    WHERE enrollment_date_clean IS NOT NULL
    GROUP BY enrollment_month
)
SELECT
    enrollment_month,
    total_patients,
    LAG(total_patients) OVER (
        ORDER BY enrollment_month
    ) AS previous_month_patients,
    total_patients - LAG(total_patients) OVER (
        ORDER BY enrollment_month
    ) AS enrollment_change
FROM monthly_enrollment
ORDER BY enrollment_month;

-- Subquery: Sites Above Average Enrollment
SELECT
    site_id,
    COUNT(*) AS total_patients

FROM clinical_trial_cleaned
GROUP BY site_id

HAVING COUNT(*) > (
    SELECT
        AVG(patient_count)
    FROM (
        SELECT
            COUNT(*) AS patient_count
        FROM clinical_trial_cleaned
        GROUP BY site_id
    ) AS site_counts
)

ORDER BY total_patients DESC;

--ROW_NUMBER: Highest AE Count Patient in Each Treatment Group
WITH ranked_patients AS (
    SELECT
        subject_id,
        treatment_group,
        adverse_events,

        ROW_NUMBER() OVER (
		PARTITION BY treatment_group
            ORDER BY adverse_events DESC,
                     subject_id
        ) AS row_num

    FROM clinical_trial_cleaned
)

SELECT
    subject_id,
    treatment_group,
    adverse_events

FROM ranked_patients
WHERE row_num = 1;