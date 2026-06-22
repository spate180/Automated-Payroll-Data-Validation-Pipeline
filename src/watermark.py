def get_watermark(cur, layer_name: str) -> int:
    cur.execute(
        "SELECT last_raw_id FROM raw.etl_watermark WHERE layer_name = %s",
        (layer_name,)
    )
    row = cur.fetchone()
    return row[0] if row else 0


def update_watermark(cur, layer_name: str, new_value: int):
    cur.execute(
        """
        UPDATE raw.etl_watermark
           SET last_raw_id = %s,
               updated_at  = NOW()
         WHERE layer_name = %s
        """,
        (new_value, layer_name)
    )
    print(f"  {layer_name} watermark updated : raw_id {new_value}")
