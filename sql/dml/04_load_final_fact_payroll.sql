INSERT INTO final.fact_payroll (
    fiscal_year, employee_id, agency_id, title_id, location_id, date_id,
    base_salary, regular_hours, regular_gross_paid,
    ot_hours, total_ot_paid, total_other_pay, total_compensation
)
SELECT
    s.fiscal_year,
    e.employee_id,
    a.agency_id,
    t.title_id,
    l.location_id,
    d.date_id,
    s.base_salary,
    s.regular_hours,
    s.regular_gross_paid,
    s.ot_hours,
    s.total_ot_paid,
    s.total_other_pay,
      ROUND(
        COALESCE(s.regular_gross_paid, 0) + 
        COALESCE(s.total_ot_paid, 0) +
        COALESCE(s.total_other_pay, 0),
    2) AS total_compensation

FROM stg.stg_payroll s

JOIN final.dim_employee e
    ON  e.first_name        = s.first_name
    AND e.last_name         = s.last_name
    AND e.agency_start_date = s.agency_start_date

JOIN final.dim_agency a
    ON a.agency_name = s.agency_name

JOIN final.dim_title t
    ON t.title_description = s.title_description

JOIN final.dim_location l
    ON l.work_location_boro = s.work_location_boro

JOIN final.dim_date d
    ON d.fiscal_year = s.fiscal_year

WHERE
    s.raw_id > (SELECT last_raw_id FROM raw.etl_watermark WHERE layer_name = 'final')

    AND s.fiscal_year          IS NOT NULL
    AND s.regular_gross_paid   IS NOT NULL
    AND s.base_salary          IS NOT NULL

ON CONFLICT (fiscal_year, employee_id, agency_id, title_id)
DO NOTHING;  
