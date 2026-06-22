# NYC Citywide Payroll Data Warehouse

A 3-layer ETL pipeline that ingests NYC Citywide Payroll data into a PostgreSQL star schema, orchestrated with Apache Airflow.

---

## What This Project Does

This project builds a data warehouse for the [NYC Citywide Payroll dataset](https://www.kaggle.com/datasets/new-york-city/nyc-citywide-payroll-data) (~2.19M rows). It:

- Lands raw CSV data into PostgreSQL with zero transformation
- Cleans, types, and deduplicates the data in a staging layer
- Loads a star schema (1 fact table + 5 dimension tables) for analytical queries
- Tracks incremental loads via a watermark system so only new data is processed on each run
- Orchestrates the full pipeline as an Airflow DAG on a daily schedule

---

## Project Structure

```
nyc_payroll/
│
├── dags/
│   └── nyc_payroll_dag.py          # Airflow DAG - 5 tasks, daily schedule
│
├── database/
│   └── connection.py               # psycopg2 connection using env variables
│
├── etl/
│   ├── raw_tasks.py                # COPY from CSV, MD5 hash check, file tracking
│   ├── stg_tasks.py                # Batch processing (100k rows), type casting, dedup
│   └── final_tasks.py             # Dimension + fact load, watermark update
│
├── src/
│   ├── sql_utils.py                # read_sql_file helper
│   └── watermark.py                # get/update watermark per layer
│
├── sql/
│   ├── ddl/
│   │   ├── 01_create_raw_tables.sql      # raw schema + watermark + file tracking tables
│   │   ├── 02_create_stg_tables.sql      # stg schema + UNIQUE key + indexes
│   │   └── 03_create_final_tables.sql    # star schema + indexes
│   └── dml/
│       ├── 00_full_reset.sql             # truncate all tables, reset watermarks
│       ├── 01_load_raw_payroll.sql       # COPY FROM FILE
│       ├── 02_load_stg_payroll.sql       # DISTINCT ON + batch params + ON CONFLICT
│       ├── 03_load_final_dimensions.sql  # load all 5 dims
│       ├── 04_load_final_fact_payroll.sql# join dims + insert fact
│       ├── 05_analysis_queries.sql       # 7 KPI and analytical queries
│       └── 06_data_profiling.sql         # 10 data profiling queries
│
├── data/
│   └── new/
│       └── payroll.csv                   # source CSV (not committed to git)
│
├── main.py                         # manual pipeline entry point
├── docker-compose.yml              # Airflow + its Postgres via Docker
└── README.md
```

---

## Why Star Schema?

The dataset is a payroll ledger : one record per employee per fiscal year per agency. This maps naturally to a **star schema**:

- **Fact table** (`fact_payroll`) holds measurable payroll figures: base salary, OT hours, gross pay, total compensation
- **Dimension tables** hold descriptive context: who (`dim_employee`), where (`dim_agency`, `dim_location`), what role (`dim_title`), when (`dim_date`)

Star schema was chosen over snowflake because:
- The dimensions are flat - no hierarchy that needs further normalization (e.g. borough does not break into city → borough → district)
- Analytical queries are simpler -single JOIN per dimension, no chained lookups
- Query performance is better for aggregations across large fact tables

---

## ETL Architecture

```
CSV File
   │
   ▼
raw.raw_payroll          ← all TEXT, BIGSERIAL raw_id, no transforms
   │
   ▼
stg.stg_payroll          ← typed, cleaned, deduplicated, SCD Type 1
   │
   ▼
final.fact_payroll       ← star schema, surrogate keys, derived columns
final.dim_employee
final.dim_agency
final.dim_title
final.dim_location
final.dim_date
```

Each layer tracks progress independently via `raw.etl_watermark`. Only rows with `raw_id` greater than the last processed watermark are loaded on each run.

---

## Prerequisites

- Python 3.9+
- PostgreSQL 14+ running locally
- Docker Desktop (for Airflow)
- pip packages: `psycopg2-binary`

---

## Setup & Running

### 1. Clone and set up Python environment

```bash
git clone https://github.com/kirtanshrestha/nyc_payroll
cd nyc_payroll
python -m venv venv
venv\Scripts\activate
pip install psycopg2-binary
```

### 2. Place the dataset

Download the CSV from [Kaggle](https://www.kaggle.com/datasets/new-york-city/nyc-citywide-payroll-data) and place it at:

```
nyc_payroll/data/new/payroll.csv
```

### 3. Set up PostgreSQL

Create the database:

```sql
CREATE DATABASE nyc_payroll_dw;
```

Then run the DDL files in order to create all schemas and tables:

```bash
psql -U postgres -d nyc_payroll_dw -f sql/ddl/01_create_raw_tables.sql
psql -U postgres -d nyc_payroll_dw -f sql/ddl/02_create_stg_tables.sql
psql -U postgres -d nyc_payroll_dw -f sql/ddl/03_create_final_tables.sql
```

### 4. Run manually

```bash
python main.py
```

This runs the full pipeline: raw → stg → final. On subsequent runs with the same file, raw and stg are skipped automatically.

### 5. Run via Airflow (Docker)

Start Airflow:

```bash
docker compose up airflow-init   # first time only — creates DB + admin user
docker compose up
```

Open `http://localhost:8080` in your browser.
- Username: `admin`
- Password: `admin`

Find the `nyc_payroll_pipeline` DAG, unpause it, and trigger it manually or let it run on its daily schedule.

### 6. Reset everything (optional)

To wipe all data and start fresh:

```bash
psql -U postgres -d nyc_payroll_dw -f sql/dml/00_full_reset.sql
```

---

## Environment Variables

The pipeline reads database credentials from environment variables. Defaults work for a standard local PostgreSQL setup:

| Variable | Default | Description |
|---|---|---|
| `DB_HOST` | `localhost` | Postgres host (`host.docker.internal` inside Docker) |
| `DB_PORT` | `5432` | Postgres port |
| `DB_NAME` | `nyc_payroll_dw` | Database name |
| `DB_USER` | `postgres` | Postgres user |
| `DB_PASSWORD` | `postgres` | Postgres password |

---

## Incremental Load Strategy

| Check | Mechanism | Purpose |
|---|---|---|
| File hash | MD5 of CSV stored in `raw.loaded_files` | Skip raw load if same file reprocessed |
| Watermark | `raw_id` per layer in `raw.etl_watermark` | Each layer only processes new rows |
| Deduplication | `DISTINCT ON` in STG SQL | Prevent duplicate inserts within a batch |
| Conflict handling | `ON CONFLICT DO UPDATE / DO NOTHING` | Safe reruns at STG and final layer |

---

## Analysis Queries

Run `sql/dml/05_analysis_queries.sql` against the loaded warehouse for:

1. Total compensation per agency per fiscal year
2. Overtime analysis by agency
3. Year-over-year salary trend
4. Compensation by borough
5. Top 10 highest paid job titles
6. Leave status breakdown per agency
7. Pay basis distribution

Run `sql/dml/06_data_profiling.sql` for data quality profiling across all three layers.