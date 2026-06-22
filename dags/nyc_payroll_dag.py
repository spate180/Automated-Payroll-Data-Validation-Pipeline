from datetime import datetime, timedelta

from airflow import DAG
from airflow.operators.python import PythonOperator

from database.connection import get_connection
from src.watermark import get_watermark
from etl.raw_tasks import initialize_raw_layer, load_raw_layer
from etl.stg_tasks import initialize_stg_layer, load_stg_layer
from etl.final_tasks import initialize_final_layer, load_dim_layer, load_fact_layer

DATA_PATH = "data/new/payroll.csv"

default_args = {
    "owner": "airflow",
    "retries": 1,
    "retry_delay": timedelta(minutes=2),
}


def _init_layers():
    conn = get_connection()
    cur = conn.cursor()
    try:
        initialize_raw_layer(cur)
        initialize_stg_layer(cur)
        initialize_final_layer(cur)
        conn.commit()
        print("All schemas and tables initialized")
    except Exception as e:
        conn.rollback()
        raise e
    finally:
        conn.close()


def _load_raw():
    conn = get_connection()
    cur = conn.cursor()
    try:
        print(f"  RAW watermark before: {get_watermark(cur, 'raw')}")
        load_raw_layer(cur, DATA_PATH)
        conn.commit()
        print("RAW layer complete")
    except Exception as e:
        conn.rollback()
        raise e
    finally:
        conn.close()


def _load_stg():
    conn = get_connection()
    cur = conn.cursor()
    try:
        print(f"  STG watermark before: {get_watermark(cur, 'stg')}")
        load_stg_layer(cur)
        conn.commit()
        print("STG layer complete")
    except Exception as e:
        conn.rollback()
        raise e
    finally:
        conn.close()


def _load_dims():
    conn = get_connection()
    cur = conn.cursor()
    try:
        print(f"  FINAL watermark before: {get_watermark(cur, 'final')}")
        load_dim_layer(cur)
        conn.commit()
        print("Dimension tables loaded")
    except Exception as e:
        conn.rollback()
        raise e
    finally:
        conn.close()


def _load_fact():
    conn = get_connection()
    cur = conn.cursor()
    try:
        load_fact_layer(cur)
        conn.commit()
        print("Fact table loaded")
    except Exception as e:
        conn.rollback()
        raise e
    finally:
        conn.close()


with DAG(
    dag_id="nyc_payroll_pipeline",
    default_args=default_args,
    description="NYC Citywide Payroll : 3-layer ETL (raw → stg → final)",
    schedule_interval="@daily",       #schedule_interval="*/5 * * * *", "* * * * *"
    start_date=datetime(2026, 5, 5),
    catchup=False,
    tags=["nyc_payroll"],
) as dag:

    init_layers = PythonOperator(
        task_id="init_layers",
        python_callable=_init_layers,
    )

    load_raw = PythonOperator(
        task_id="load_raw",
        python_callable=_load_raw,
    )

    load_stg = PythonOperator(
        task_id="load_stg",
        python_callable=_load_stg,
    )

    load_dims = PythonOperator(
        task_id="load_dims",
        python_callable=_load_dims,
    )

    load_fact = PythonOperator(
        task_id="load_fact",
        python_callable=_load_fact,
    )

    init_layers >> load_raw >> load_stg >> load_dims >> load_fact