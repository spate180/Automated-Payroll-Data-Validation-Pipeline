from src.sql_utils import read_sql_file, get_sql_path
from src.watermark import get_watermark, update_watermark


def initialize_final_layer(cur):
    final_ddl_query = read_sql_file(get_sql_path("sql/ddl/03_create_final_tables.sql"))
    cur.execute(final_ddl_query)
    print(" final  initialized")


def load_dim_layer(cur):
    final_wm = get_watermark(cur, "final")
    stg_wm = get_watermark(cur, "stg")
    print(f"  FINAL-DIM loading dims for raw_id > {final_wm} (stg has up to raw_id {stg_wm})")

    dim_dml_query = read_sql_file(get_sql_path("sql/dml/03_load_final_dimensions.sql"))
    cur.execute(dim_dml_query)
    print("  FINAL-DIM dimension tables loaded")


def load_fact_layer(cur):
    wm_before = get_watermark(cur, "final")
    print(f"  FINAL-FACT current watermark = raw_id {wm_before}")

    fact_dml_query = read_sql_file(get_sql_path("sql/dml/04_load_final_fact_payroll.sql"))
    cur.execute(fact_dml_query)

    cur.execute("""
        SELECT MAX(raw_id)
        FROM stg.stg_payroll
        WHERE raw_id > %(wm)s
          AND fiscal_year        IS NOT NULL
          AND regular_gross_paid IS NOT NULL
          AND base_salary        IS NOT NULL
    """, {"wm": wm_before})

    row = cur.fetchone()
    new_max = row[0] if row and row[0] is not None else wm_before

    print(f"  FINAL-FACT new max raw_id = {new_max}")
    if new_max > wm_before:
        update_watermark(cur, "final", new_max)