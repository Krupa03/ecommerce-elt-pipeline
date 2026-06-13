from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
from datetime import datetime, timedelta
import os

default_args = {
    'owner': 'krupa',
    'depends_on_past': False,
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

dag = DAG(
    'ecommerce_elt_pipeline',
    default_args=default_args,
    description='ELT pipeline: CSV -> BigQuery -> dbt transformations',
    schedule_interval='@daily',
    start_date=datetime(2026, 6, 1),
    catchup=False,
    tags=['ecommerce', 'elt', 'bigquery', 'dbt'],
)

def load_csv_to_bigquery():
    from google.cloud import bigquery
    import pandas as pd

    os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = '/opt/airflow/dbt/service_account.json'
    client = bigquery.Client(project='ecommerce-elt-pipeline')

    dataset_id = 'ecommerce_raw'
    data_path = '/opt/airflow/data'

    tables = {
        'orders': f'{data_path}/olist_orders_dataset.csv',
        'customers': f'{data_path}/olist_customers_dataset.csv',
        'products': f'{data_path}/olist_products_dataset.csv',
        'order_items': f'{data_path}/olist_order_items_dataset.csv',
        'order_payments': f'{data_path}/olist_order_payments_dataset.csv',
        'order_reviews': f'{data_path}/olist_order_reviews_dataset.csv',
    }

    for table_name, file_path in tables.items():
        df = pd.read_csv(file_path)
        table_ref = f'ecommerce-elt-pipeline.{dataset_id}.{table_name}'
        job_config = bigquery.LoadJobConfig(
            write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
            autodetect=True,
        )
        job = client.load_table_from_dataframe(df, table_ref, job_config=job_config)
        job.result()
        print(f'Loaded {len(df)} rows into {table_ref}')

extract_load = PythonOperator(
    task_id='extract_load_to_bigquery',
    python_callable=load_csv_to_bigquery,
    dag=dag,
)

dbt_run = BashOperator(
    task_id='dbt_run',
    bash_command='cd /opt/airflow/dbt && dbt run --profiles-dir /opt/airflow/dbt',
    dag=dag,
)

dbt_test = BashOperator(
    task_id='dbt_test',
    bash_command='cd /opt/airflow/dbt && dbt test --profiles-dir /opt/airflow/dbt',
    dag=dag,
)

extract_load >> dbt_run >> dbt_test