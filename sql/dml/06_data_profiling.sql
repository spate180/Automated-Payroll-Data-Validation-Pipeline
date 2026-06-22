-- DATA PROFILING QUERIES :NYC Payroll Data Warehouse

-- 1. Row count and basic size
SELECT
    COUNT(*)                        AS total_rows,
    COUNT(DISTINCT fiscal_year)     AS distinct_fiscal_years,
    MIN(fiscal_year::INT)           AS earliest_year,
    MAX(fiscal_year::INT)           AS latest_year
FROM raw.raw_payroll;


-- 2. Column-level null counts
SELECT
    COUNT(*) FILTER (WHERE fiscal_year        IS NULL OR TRIM(fiscal_year) = '')        AS null_fiscal_year,
    COUNT(*) FILTER (WHERE agency_name        IS NULL OR TRIM(agency_name) = '')        AS null_agency_name,
    COUNT(*) FILTER (WHERE last_name          IS NULL OR TRIM(last_name) = '')          AS null_last_name,
    COUNT(*) FILTER (WHERE first_name         IS NULL OR TRIM(first_name) = '')         AS null_first_name,
    COUNT(*) FILTER (WHERE mid_init           IS NULL OR TRIM(mid_init) = '')           AS null_mid_init,
    COUNT(*) FILTER (WHERE agency_start_date  IS NULL OR TRIM(agency_start_date) = '')  AS null_agency_start_date,
    COUNT(*) FILTER (WHERE work_location_boro IS NULL OR TRIM(work_location_boro) = '') AS null_work_location_boro,
    COUNT(*) FILTER (WHERE title_description  IS NULL OR TRIM(title_description) = '')  AS null_title_description,
    COUNT(*) FILTER (WHERE leave_status       IS NULL OR TRIM(leave_status) = '')       AS null_leave_status,
    COUNT(*) FILTER (WHERE base_salary        IS NULL OR TRIM(base_salary) = '')        AS null_base_salary,
    COUNT(*) FILTER (WHERE pay_basis          IS NULL OR TRIM(pay_basis) = '')          AS null_pay_basis,
    COUNT(*) FILTER (WHERE regular_hours      IS NULL OR TRIM(regular_hours) = '')      AS null_regular_hours,
    COUNT(*) FILTER (WHERE regular_gross_paid IS NULL OR TRIM(regular_gross_paid) = '') AS null_regular_gross_paid,
    COUNT(*) FILTER (WHERE ot_hours           IS NULL OR TRIM(ot_hours) = '')           AS null_ot_hours,
    COUNT(*) FILTER (WHERE total_ot_paid      IS NULL OR TRIM(total_ot_paid) = '')      AS null_total_ot_paid,
    COUNT(*) FILTER (WHERE total_other_pay    IS NULL OR TRIM(total_other_pay) = '')    AS null_total_other_pay
FROM raw.raw_payroll;

-- 3. Duplicate detection : exact duplicates in raw
SELECT
    fiscal_year, agency_name, last_name, first_name,
    agency_start_date, title_description,
    COUNT(*) AS duplicate_count
FROM raw.raw_payroll
GROUP BY
    fiscal_year, agency_name, last_name, first_name,
    agency_start_date, title_description
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC
LIMIT 20;


-- 4. Total duplicate row count
SELECT
    SUM(duplicate_count - 1) AS total_duplicate_rows,
    COUNT(*)                 AS duplicate_groups
FROM (
    SELECT
        fiscal_year, agency_name, last_name, first_name,
        agency_start_date, title_description,
        COUNT(*) AS duplicate_count
    FROM raw.raw_payroll
    GROUP BY
        fiscal_year, agency_name, last_name, first_name,
        agency_start_date, title_description
    HAVING COUNT(*) > 1
) dupes;


-- 5. Data type validation : non-numeric values in salary fields
SELECT
    COUNT(*) FILTER (
        WHERE base_salary IS NOT NULL
          AND base_salary !~ '^-?[$]?[0-9,]*\.?[0-9]*$'
          AND TRIM(base_salary) != ''
    ) AS invalid_base_salary,
    COUNT(*) FILTER (
        WHERE regular_gross_paid IS NOT NULL
          AND regular_gross_paid !~ '^-?[$]?[0-9,]*\.?[0-9]*$'
          AND TRIM(regular_gross_paid) != ''
    ) AS invalid_regular_gross_paid,
    COUNT(*) FILTER (
        WHERE total_ot_paid IS NOT NULL
          AND total_ot_paid !~ '^-?[$]?[0-9,]*\.?[0-9]*$'
          AND TRIM(total_ot_paid) != ''
    ) AS invalid_total_ot_paid
FROM raw.raw_payroll;


-- 6. Invalid date formats in agency_start_date
SELECT COUNT(*) AS invalid_dates
FROM raw.raw_payroll
WHERE
    TRIM(agency_start_date) != ''
    AND agency_start_date IS NOT NULL
    AND agency_start_date !~ '^\d{2}/\d{2}/\d{4}$';


-- 7. Salary range and outlier check (post-transform on STG)
SELECT
    MIN(base_salary)                                    AS min_salary,
    MAX(base_salary)                                    AS max_salary,
    ROUND(AVG(base_salary), 2)                          AS avg_salary,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY base_salary) AS p25,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY base_salary) AS median,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY base_salary) AS p75,
    COUNT(*) FILTER (WHERE base_salary < 0)             AS negative_salaries,
    COUNT(*) FILTER (WHERE base_salary = 0)             AS zero_salaries,
    COUNT(*) FILTER (WHERE base_salary > 500000)        AS extreme_high_salaries
FROM stg.stg_payroll;


-- 8. Row counts across all three layers (pipeline validation)
SELECT 'raw'   AS layer, COUNT(*) AS row_count FROM raw.raw_payroll
UNION ALL
SELECT 'stg',                             COUNT(*) FROM stg.stg_payroll
UNION ALL
SELECT 'fact',                            COUNT(*) FROM final.fact_payroll;


-- 9. Records lost between raw and stg (null filtering)
SELECT
    (SELECT COUNT(*) FROM raw.raw_payroll)                          AS raw_count,
    (SELECT COUNT(*) FROM stg.stg_payroll)                          AS stg_count,
    (SELECT COUNT(*) FROM raw.raw_payroll) -
    (SELECT COUNT(*) FROM stg.stg_payroll)                          AS rows_dropped,
    ROUND(
        100.0 * (
            (SELECT COUNT(*) FROM raw.raw_payroll) -
            (SELECT COUNT(*) FROM stg.stg_payroll)
        ) / NULLIF((SELECT COUNT(*) FROM raw.raw_payroll), 0),
    2)                                                               AS pct_dropped;