from src.sql_utils import read_sql_file, get_sql_path
from src.watermark import get_watermark, update_watermark

BATCH_SIZE = 100_000


def initialize_stg_layer(cur):
    initialize_stg_layer = read_sql_file(get_sql_path("sql/ddl/02_create_stg_tables.sql"))
    cur.execute(initialize_stg_layer)
    print("STG initialized")


def load_stg_layer(cur):

    wm_before = get_watermark(cur, "stg")
    print(f"  STG current watermark = raw_id {wm_before}")

    cur.execute("SELECT MAX(raw_id) FROM raw.raw_payroll;")
    row = cur.fetchone()
    raw_max = row[0] if row and row[0] is not None else wm_before

    if raw_max <= wm_before:
        print("  STG no new rows to process, skipping")
        return

    stg_dml_query = read_sql_file(get_sql_path("sql/dml/02_load_stg_payroll.sql"))

    batch_start = wm_before
    total_batches = 0

    while batch_start < raw_max:
        batch_end = batch_start + BATCH_SIZE
        print(f"  STG processing raw_id {batch_start} → {batch_end}")

        cur.execute(stg_dml_query, {
            "batch_start": batch_start,
            "batch_end": batch_end
        })

        # Change stg watermark to the highest raw_id now present in stg
        cur.execute("SELECT MAX(raw_id) FROM stg.stg_payroll WHERE raw_id > %(wm)s", {"wm": wm_before})
        row = cur.fetchone()
        new_max = row[0] if row and row[0] is not None else batch_start

        if new_max > wm_before:
            update_watermark(cur, "stg", new_max)

        batch_start = batch_end
        total_batches += 1

    print(f"  STG batch load complete | {total_batches} batches | max raw_id = {new_max}")