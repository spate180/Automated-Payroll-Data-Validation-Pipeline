TRUNCATE TABLE raw.raw_payroll;
TRUNCATE TABLE raw.loaded_files;
TRUNCATE TABLE stg.stg_payroll;
TRUNCATE raw.raw_payroll RESTART IDENTITY;


TRUNCATE TABLE
    final.fact_payroll,
    final.dim_employee,
    final.dim_agency,
    final.dim_title,
    final.dim_location,
    final.dim_date
RESTART IDENTITY CASCADE;

UPDATE raw.etl_watermark SET last_raw_id = 0, updated_at = NOW();