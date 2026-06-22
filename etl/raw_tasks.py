import hashlib
import os
from src.sql_utils import read_sql_file, get_sql_path
from src.watermark import get_watermark, update_watermark


def initialize_raw_layer(cur):
    raw_ddl_query = read_sql_file(get_sql_path("sql/ddl/01_create_raw_tables.sql"))
    cur.execute(raw_ddl_query)
    print("  RAW initialized")


def get_file_hash(filepath: str) -> str:
    hasher = hashlib.md5()
    with open(filepath, "rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            hasher.update(chunk)
    return hasher.hexdigest()


def is_file_already_loaded(cur, file_hash: str) -> bool:
    cur.execute(
        "SELECT 1 FROM raw.loaded_files WHERE file_hash = %s",
        (file_hash,)
    )
    return cur.fetchone() is not None


def register_loaded_file(cur, file_hash: str, file_name: str, row_count: int):
    cur.execute(
        """
        INSERT INTO raw.loaded_files (file_hash, file_name, row_count)
        VALUES (%s, %s, %s)
        ON CONFLICT (file_hash) DO NOTHING
        """,
        (file_hash, file_name, row_count)
    )


def load_raw_layer(cur, data_path: str = "data/new/payroll.csv") -> int:

    current_wm = get_watermark(cur, "raw")
    print(f"  RAW current watermark = raw_id {current_wm}")

    csv_path = os.path.abspath(os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
        data_path
    ))
    file_name = os.path.basename(csv_path)

    # skip already processed file
    print(f"  RAW checking file hash for {file_name}")
    file_hash = get_file_hash(csv_path)

    if is_file_already_loaded(cur, file_hash):
        print(f"  RAW'{file_name}' already loaded (hash: {file_hash[:8]}...) so skipping")
        return current_wm

    print(f"  RAW new file detected (hash: {file_hash[:8]}...) so loading...")

    # COPYING
    raw_dml_sql = read_sql_file(get_sql_path("sql/dml/01_load_raw_payroll.sql"))
    cur.execute(raw_dml_sql, (csv_path,))

    # MAX row count and rawID
    cur.execute("SELECT COUNT(*), MAX(raw_id) FROM raw.raw_payroll WHERE raw_id > %s", (current_wm,))
    result = cur.fetchone()
    rows_inserted = result[0] if result else 0
    max_raw_id = result[1] if result and result[1] is not None else current_wm

    print(f"  RAW COPY complete | {rows_inserted} rows | max raw_id = {max_raw_id}")

    # FIle tracking and update watermark
    register_loaded_file(cur, file_hash, file_name, rows_inserted)
    update_watermark(cur, "raw", max_raw_id)

    return max_raw_id