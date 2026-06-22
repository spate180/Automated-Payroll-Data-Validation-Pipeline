-- dim_agency
INSERT INTO final.dim_agency (agency_name)
SELECT DISTINCT agency_name
FROM stg.stg_payroll
WHERE agency_name IS NOT NULL
  AND raw_id > (SELECT last_raw_id FROM raw.etl_watermark WHERE layer_name = 'final')
ON CONFLICT (agency_name) DO NOTHING;

-- dim_title
INSERT INTO final.dim_title (title_description, pay_basis)
SELECT DISTINCT title_description, pay_basis
FROM stg.stg_payroll
WHERE title_description IS NOT NULL
  AND raw_id > (SELECT last_raw_id FROM raw.etl_watermark WHERE layer_name = 'final')
ON CONFLICT (title_description) DO NOTHING;

-- dim_location
INSERT INTO final.dim_location (work_location_boro)
SELECT DISTINCT work_location_boro
FROM stg.stg_payroll
WHERE work_location_boro IS NOT NULL
  AND raw_id > (SELECT last_raw_id FROM raw.etl_watermark WHERE layer_name = 'final')
ON CONFLICT (work_location_boro) DO NOTHING;

-- dim_employee
INSERT INTO final.dim_employee (first_name, mid_init, last_name, agency_start_date, leave_status)
SELECT DISTINCT ON (first_name, last_name, agency_start_date)
    first_name, mid_init, last_name, agency_start_date, leave_status
FROM stg.stg_payroll
WHERE first_name IS NOT NULL
  AND last_name IS NOT NULL
  AND raw_id > (SELECT last_raw_id FROM raw.etl_watermark WHERE layer_name = 'final')
ORDER BY first_name, last_name, agency_start_date, fiscal_year DESC
ON CONFLICT (first_name, last_name, agency_start_date)
DO UPDATE SET leave_status = EXCLUDED.leave_status;

-- dim_date
INSERT INTO final.dim_date (fiscal_year)
SELECT DISTINCT fiscal_year
FROM stg.stg_payroll
WHERE fiscal_year IS NOT NULL
  AND raw_id > (SELECT last_raw_id FROM raw.etl_watermark WHERE layer_name = 'final')
ON CONFLICT (fiscal_year) DO NOTHING;