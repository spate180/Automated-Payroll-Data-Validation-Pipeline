CREATE SCHEMA IF NOT EXISTS stg;

CREATE TABLE IF NOT EXISTS stg.stg_payroll (
    raw_id              BIGINT          NOT NULL,   -- for watermark tracking
    fiscal_year         SMALLINT        NULL,
    agency_name         VARCHAR(100)    NULL,
    last_name           VARCHAR(50)     NULL,
    first_name          VARCHAR(50)     NULL,
    mid_init            CHAR(1)         NULL,
    agency_start_date   DATE            NULL,
    work_location_boro  VARCHAR(50)     NULL,
    title_description   VARCHAR(100)    NULL,
    leave_status        VARCHAR(30)     NULL,
    base_salary         NUMERIC(14, 2)  NULL,
    pay_basis           VARCHAR(20)     NULL,
    regular_hours       NUMERIC(10, 2)  NULL,
    regular_gross_paid  NUMERIC(14, 2)  NULL,
    ot_hours            NUMERIC(10, 2)  NULL,
    total_ot_paid       NUMERIC(14, 2)  NULL,
    total_other_pay     NUMERIC(14, 2)  NULL,
    stg_loaded_at       TIMESTAMP       NOT NULL DEFAULT NOW(),
    UNIQUE (fiscal_year, agency_name, last_name, first_name, agency_start_date, title_description)
);


-- INDEXES
CREATE INDEX IF NOT EXISTS idx_stg_raw_id    ON stg.stg_payroll (raw_id);
CREATE INDEX IF NOT EXISTS idx_stg_names     ON stg.stg_payroll (first_name, last_name, agency_start_date);
CREATE INDEX IF NOT EXISTS idx_stg_agency    ON stg.stg_payroll (agency_name);
CREATE INDEX IF NOT EXISTS idx_stg_title     ON stg.stg_payroll (title_description);
CREATE INDEX IF NOT EXISTS idx_stg_location  ON stg.stg_payroll (work_location_boro);
CREATE INDEX IF NOT EXISTS idx_stg_fiscal    ON stg.stg_payroll (fiscal_year);