-- FINAL LAYER- Star Schema
--   Fact: fact_payroll
--   Dims: dim_employee, dim_agency, dim_title, dim_date, dim_location

CREATE SCHEMA IF NOT EXISTS final;

-- DIM:Agency
CREATE TABLE IF NOT EXISTS final.dim_agency (
    agency_id   SERIAL PRIMARY KEY,
    agency_name TEXT UNIQUE NOT NULL
);

-- DIM: Job Title
CREATE TABLE IF NOT EXISTS final.dim_title (
    title_id          SERIAL PRIMARY KEY,
    title_description TEXT UNIQUE NOT NULL,
    pay_basis         VARCHAR(20) NULL
);

-- DIM: Work Location
CREATE TABLE IF NOT EXISTS final.dim_location (
    location_id        SERIAL PRIMARY KEY,
    work_location_boro TEXT UNIQUE NOT NULL
);

-- DIM: Employee
CREATE TABLE IF NOT EXISTS final.dim_employee (
    employee_id       SERIAL PRIMARY KEY,
    first_name        VARCHAR(50)  NULL,
    mid_init          CHAR(1)      NULL,
    last_name         VARCHAR(50)  NULL,
    agency_start_date DATE         NULL,
    leave_status      VARCHAR(30)  NULL,
    UNIQUE (first_name, last_name, agency_start_date)
);

-- DIM: Date
CREATE TABLE IF NOT EXISTS final.dim_date (
    date_id     SERIAL PRIMARY KEY,
    fiscal_year SMALLINT UNIQUE NOT NULL
);

-- FACT: Payroll
CREATE TABLE IF NOT EXISTS final.fact_payroll (
    payroll_id          SERIAL          PRIMARY KEY,
    fiscal_year         SMALLINT        NOT NULL,
    employee_id         BIGINT          REFERENCES final.dim_employee(employee_id),
    agency_id           BIGINT          REFERENCES final.dim_agency(agency_id),
    title_id            BIGINT          REFERENCES final.dim_title(title_id),
    location_id         BIGINT          REFERENCES final.dim_location(location_id),
    date_id             BIGINT          REFERENCES final.dim_date(date_id),
    base_salary         NUMERIC(14, 2)  NULL,
    regular_hours       NUMERIC(10, 2)  NULL,
    regular_gross_paid  NUMERIC(14, 2)  NULL,
    ot_hours            NUMERIC(10, 2)  NULL,
    total_ot_paid       NUMERIC(14, 2)  NULL,
    total_other_pay     NUMERIC(14, 2)  NULL,
    total_compensation  NUMERIC(14, 2)  NULL,
    fact_loaded_at      TIMESTAMP       DEFAULT NOW(),
    UNIQUE (fiscal_year, employee_id, agency_id, title_id) 
);


-- INDEXES
CREATE INDEX IF NOT EXISTS idx_emp_names      ON final.dim_employee (first_name, last_name, agency_start_date);
CREATE INDEX IF NOT EXISTS idx_agency_name    ON final.dim_agency (agency_name);
CREATE INDEX IF NOT EXISTS idx_title_desc     ON final.dim_title (title_description);
CREATE INDEX IF NOT EXISTS idx_location_boro  ON final.dim_location (work_location_boro);
CREATE INDEX IF NOT EXISTS idx_fact_fiscal    ON final.fact_payroll (fiscal_year);
CREATE INDEX IF NOT EXISTS idx_fact_employee  ON final.fact_payroll (employee_id);
CREATE INDEX IF NOT EXISTS idx_fact_agency    ON final.fact_payroll (agency_id);