COPY raw.raw_payroll (
    fiscal_year, agency_name, last_name, first_name, mid_init,
    agency_start_date, work_location_boro, title_description,
    leave_status, base_salary, pay_basis, regular_hours,
    regular_gross_paid, ot_hours, total_ot_paid, total_other_pay
)
FROM %s
WITH (FORMAT csv, HEADER true, NULL '')