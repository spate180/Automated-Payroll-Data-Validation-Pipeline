from database.connection import get_connection
from src.watermark import get_watermark
from etl.raw_tasks import initialize_raw_layer, load_raw_layer
from etl.stg_tasks import initialize_stg_layer, load_stg_layer
from etl.final_tasks import initialize_final_layer, load_dim_layer, load_fact_layer


def run_pipeline(data_path: str = "data/new/payroll.csv"):
    conn = get_connection()
    cur = conn.cursor()

    # here we are initializing raw schemas frist so watermark is set
    initialize_raw_layer(cur)
    conn.commit()

    print("NYC PAYROLL PIPELINE STARTED")
    print("Watermarks at start:")
    for layer in ("raw", "stg", "final"):
        print(f"  {layer}: raw_id = {get_watermark(cur, layer)}")

    try:
                                            #  RAW LAYER 
        print("\n\nRAW LAYER")
        load_raw_layer(cur, data_path)
        conn.commit()
        print("RAW layer complete.\n")

                                            # STAGING LAYER
        print("STAGING LAYER")
        initialize_stg_layer(cur)
        load_stg_layer(cur)
        conn.commit()
        print("STAGING layer complete.\n")

                                            # FINAL LAYER
        print("FINAL LAYER")
        initialize_final_layer(cur)
        load_dim_layer(cur)
        load_fact_layer(cur)
        conn.commit()
        print("FINAL(fact/dim) layer complete.\n")

    except Exception as e:
        conn.rollback()
        print(f"\nPIPELINE FAILED: {e}")
        raise

    finally:
        print("Watermarks status at end:")
        for layer in ("raw", "stg", "final"):
            print(f"  {layer}: raw_id = {get_watermark(cur, layer)}")

        conn.close()


if __name__ == "__main__":
    run_pipeline()