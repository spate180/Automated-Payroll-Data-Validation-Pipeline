CREATE SCHEMA IF NOT EXISTS raw;

CREATE TABLE IF NOT EXISTS raw.raw_payroll (
    raw_id              BIGSERIAL PRIMARY KEY,
    fiscal_year         TEXT NULL,
    agency_name         TEXT NULL,
    last_name           TEXT NULL,
    first_name          TEXT NULL,
    mid_init            TEXT NULL,
    agency_start_date   TEXT NULL,
    work_location_boro  TEXT NULL,
    title_description   TEXT NULL,
    leave_status        TEXT NULL,
    base_salary         TEXT NULL,
    pay_basis           TEXT NULL,
    regular_hours       TEXT NULL,
    regular_gross_paid  TEXT NULL,
    ot_hours            TEXT NULL,
    total_ot_paid       TEXT NULL,
    total_other_pay     TEXT NULL,
    raw_loaded_at       TIMESTAMP NOT NULL DEFAULT NOW()
);


-- WATERMARK TABLE
CREATE TABLE IF NOT EXISTS raw.etl_watermark (
    layer_name   TEXT PRIMARY KEY,
    last_raw_id  BIGINT NOT NULL DEFAULT 0,
    updated_at   TIMESTAMP NOT NULL DEFAULT NOW()
);

INSERT INTO raw.etl_watermark (layer_name, last_raw_id)
VALUES ('raw',   0),
       ('stg',   0),
       ('final', 0)
ON CONFLICT (layer_name) DO NOTHING;

-- FILE TRACKING TABLE
CREATE TABLE IF NOT EXISTS raw.loaded_files (
    file_hash   TEXT PRIMARY KEY,       
    file_name   TEXT NOT NULL,          
    row_count   INTEGER,                
    loaded_at   TIMESTAMP DEFAULT NOW()
);