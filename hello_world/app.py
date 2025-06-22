import json
import os
import csv
import psycopg2
import boto3


def lambda_handler(event, context):
    """Sample pure Lambda function

    Parameters
    ----------
    event: dict, required
        API Gateway Lambda Proxy Input Format

        Event doc: https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html#api-gateway-simple-proxy-for-lambda-input-format

    context: object, required
        Lambda Context runtime methods and attributes

        Context doc: https://docs.aws.amazon.com/lambda/latest/dg/python-context-object.html

    Returns
    ------
    API Gateway Lambda Proxy Output Format: dict

        Return doc: https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html
    """

    s3 = boto3.client('s3')
    bucket = 'file-processor-lambda-data-bucket-8937640'
    key = 'sample-data.csv'
    db_host = os.environ['DB_HOST']
    db_name = os.environ['DB_NAME']
    db_user = os.environ['DB_USER']
    db_password = os.environ['DB_PASSWORD']

    # Connect to PostgreSQL
    print(f"Connecting to {db_host}, database: {db_name}, user: {db_user}")
    conn = psycopg2.connect(
        host=db_host,
        dbname=db_name,
        user=db_user,
        password=db_password
    )
    cur = conn.cursor()
    #cur.execute("SET search_path TO my_data;")

    # Read CSV directly from S3 without saving locally
    s3_obj = s3.get_object(Bucket=bucket, Key=key)
    csvfile = s3_obj['Body'].read().decode('utf-8').splitlines()
    reader = csv.reader(csvfile)
    header = next(reader, None)  # Skip header row
    inserted = 0
    try:
        for row in reader:
            print(f"Inserting row: {row}")  # For debugging
            cur.execute(
                "INSERT INTO my_data (id, name, email, department, salary, hire_date) VALUES (%s, %s, %s, %s, %s, %s)",
                row
            )
            inserted += 1
        conn.commit()
        print(f"Inserted {inserted} rows.")
        
        # Count total rows in my_data
        cur.execute("SELECT COUNT(*) FROM my_data;")
        count = cur.fetchone()[0]
        print(f"Total rows in my_data: {count}")
    except Exception as e:
        print(f"Error: {e}")
        conn.rollback()
    finally:
        cur.close()
        conn.close()
    return {"status": "success", "inserted": inserted}
