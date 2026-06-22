-- ANALYSIS QUERIES for NYC Payroll Data

-- 1. Total compensation per agency per fiscal year
SELECT
    d.fiscal_year,
    a.agency_name,
    COUNT(*)                            AS employee_count,
    ROUND(SUM(f.base_salary), 2)        AS total_base_salary,
    ROUND(SUM(f.total_ot_paid), 2)      AS total_ot_paid,
    ROUND(SUM(f.total_compensation), 2) AS total_compensation
FROM final.fact_payroll f
JOIN final.dim_agency   a ON a.agency_id   = f.agency_id
JOIN final.dim_date     d ON d.date_id     = f.date_id
GROUP BY d.fiscal_year, a.agency_name
ORDER BY d.fiscal_year, total_compensation DESC;

-- 2. Overtime analysis : top OT earners by agency
SELECT
    d.fiscal_year,
    a.agency_name,
    ROUND(AVG(f.ot_hours), 2)           AS avg_ot_hours,
    ROUND(SUM(f.ot_hours), 2)           AS total_ot_hours,
    ROUND(SUM(f.total_ot_paid), 2)      AS total_ot_paid,
    ROUND(AVG(f.total_ot_paid), 2)      AS avg_ot_paid_per_employee
FROM final.fact_payroll f
JOIN final.dim_agency a ON a.agency_id = f.agency_id
JOIN final.dim_date   d ON d.date_id   = f.date_id
WHERE f.ot_hours > 0
GROUP BY d.fiscal_year, a.agency_name
ORDER BY total_ot_paid DESC;

-- 3. Year-over-year salary trend
SELECT
    d.fiscal_year,
    COUNT(*)                                    AS total_employees,
    ROUND(AVG(f.base_salary), 2)                AS avg_base_salary,
    ROUND(AVG(f.total_compensation), 2)          AS avg_total_compensation,
    ROUND(SUM(f.total_compensation), 2)          AS total_payroll_spend
FROM final.fact_payroll f
JOIN final.dim_date d ON d.date_id = f.date_id
GROUP BY d.fiscal_year
ORDER BY d.fiscal_year;

-- 4. Compensation by borough
SELECT
    l.work_location_boro,
    COUNT(*)                                    AS employee_count,
    ROUND(AVG(f.base_salary), 2)                AS avg_base_salary,
    ROUND(AVG(f.total_compensation), 2)          AS avg_total_compensation
FROM final.fact_payroll f
JOIN final.dim_location l ON l.location_id = f.location_id
GROUP BY l.work_location_boro
ORDER BY avg_total_compensation DESC;

-- 5. Top 10 highest paid job titles
SELECT
    t.title_description,
    t.pay_basis,
    COUNT(*)                                    AS employee_count,
    ROUND(AVG(f.base_salary), 2)                AS avg_base_salary,
    ROUND(MAX(f.base_salary), 2)                AS max_base_salary,
    ROUND(AVG(f.total_compensation), 2)          AS avg_total_compensation
FROM final.fact_payroll f
JOIN final.dim_title t ON t.title_id = f.title_id
GROUP BY t.title_description, t.pay_basis
ORDER BY avg_total_compensation DESC
LIMIT 10;

-- 6. Leave status breakdown per agency
SELECT
    a.agency_name,
    e.leave_status,
    COUNT(*) AS employee_count,
    ROUND(AVG(f.base_salary), 2) AS avg_base_salary
FROM final.fact_payroll f
JOIN final.dim_employee e ON e.employee_id = f.employee_id
JOIN final.dim_agency   a ON a.agency_id   = f.agency_id
GROUP BY a.agency_name, e.leave_status
ORDER BY a.agency_name, employee_count DESC;

-- 7. Pay basis distribution (per Annum vs per Day vs per Hour)
SELECT
    t.pay_basis,
    COUNT(*)                                    AS employee_count,
    ROUND(AVG(f.base_salary), 2)                AS avg_base_salary,
    ROUND(SUM(f.total_compensation), 2)          AS total_compensation
FROM final.fact_payroll f
JOIN final.dim_title t ON t.title_id = f.title_id
GROUP BY t.pay_basis
ORDER BY employee_count DESC;