INSERT INTO stg.stg_payroll (
    raw_id,
    fiscal_year, agency_name, last_name, first_name, mid_init,
    agency_start_date, work_location_boro, title_description,
    leave_status, base_salary, pay_basis, regular_hours,
    regular_gross_paid, ot_hours, total_ot_paid, total_other_pay
)
SELECT DISTINCT ON (
    NULLIF(TRIM(fiscal_year), '')::SMALLINT,
    INITCAP(TRIM(agency_name)),
    NULLIF(TRIM(last_name), ''),
    NULLIF(TRIM(first_name), ''),
    TO_DATE(NULLIF(TRIM(agency_start_date), ''), 'MM/DD/YYYY'),
    NULLIF(TRIM(title_description), '')
)
    raw_id,
    NULLIF(TRIM(fiscal_year), '')::SMALLINT,
    INITCAP(TRIM(agency_name)),
    NULLIF(TRIM(last_name), ''),
    NULLIF(TRIM(first_name), ''),
    NULLIF(TRIM(mid_init), ''),
    TO_DATE(NULLIF(TRIM(agency_start_date), ''), 'MM/DD/YYYY'),
    INITCAP(TRIM(work_location_boro)),
    NULLIF(TRIM(title_description), ''),
    NULLIF(TRIM(leave_status), ''),
    NULLIF(REGEXP_REPLACE(TRIM(base_salary), '[$,]', '', 'g'), '')::NUMERIC(14, 2),
    NULLIF(TRIM(pay_basis), ''),
    NULLIF(TRIM(regular_hours), '')::NUMERIC(10, 2),
    NULLIF(REGEXP_REPLACE(TRIM(regular_gross_paid), '[$,]', '', 'g'), '')::NUMERIC(14, 2),
    NULLIF(TRIM(ot_hours), '')::NUMERIC(10, 2),
    NULLIF(REGEXP_REPLACE(TRIM(total_ot_paid), '[$,]', '', 'g'), '')::NUMERIC(14, 2),
    NULLIF(REGEXP_REPLACE(TRIM(total_other_pay), '[$,]', '', 'g'), '')::NUMERIC(14, 2)

FROM raw.raw_payroll
WHERE
    raw_id > %(batch_start)s
    AND raw_id <= %(batch_end)s
    AND NULLIF(TRIM(fiscal_year), '') IS NOT NULL
    AND NULLIF(TRIM(first_name), '') IS NOT NULL
    AND NULLIF(TRIM(last_name), '') IS NOT NULL
    AND NULLIF(TRIM(title_description), '') IS NOT NULL

ORDER BY
    NULLIF(TRIM(fiscal_year), '')::SMALLINT,
    INITCAP(TRIM(agency_name)),
    NULLIF(TRIM(last_name), ''),
    NULLIF(TRIM(first_name), ''),
    TO_DATE(NULLIF(TRIM(agency_start_date), ''), 'MM/DD/YYYY'),
    NULLIF(TRIM(title_description), ''),
    raw_id DESC

ON CONFLICT (fiscal_year, agency_name, last_name, first_name, agency_start_date, title_description)
DO UPDATE SET
    raw_id             = EXCLUDED.raw_id,
    leave_status       = EXCLUDED.leave_status,
    base_salary        = EXCLUDED.base_salary,
    regular_hours      = EXCLUDED.regular_hours,
    regular_gross_paid = EXCLUDED.regular_gross_paid,
    ot_hours           = EXCLUDED.ot_hours,
    total_ot_paid      = EXCLUDED.total_ot_paid,
    total_other_pay    = EXCLUDED.total_other_pay,
    stg_loaded_at      = NOW();