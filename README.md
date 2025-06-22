# file-processor-lambda

This project demonstrates a serverless AWS Lambda application using AWS SAM that reads a CSV file from S3 and inserts its records into a PostgreSQL table. The Lambda is written in Python and can be tested locally or deployed to AWS.

---

## Prerequisites

- AWS CLI configured
- AWS SAM CLI installed ([Install Guide](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install.html))
- Docker installed ([Install Guide](https://docs.docker.com/get-docker/))
- Python 3.9+ installed ([Download](https://www.python.org/downloads/))
- Access to an AWS S3 bucket and a PostgreSQL database (RDS or local)

---

## Project Structure

- `hello_world/` - Lambda function code
- `events/` - Sample event files for local testing
- `template.yaml` - AWS SAM template defining resources and environment variables
- `README.md` - This documentation
- `.gitignore` - Excludes build, credentials, and environment files from Git

---

## Step 1: Clone and Set Up the Project

```powershell
# Clone the repository or copy the files to your workspace
cd file-processor-lambda
```

---

## Step 2: Configure Environment Variables

The Lambda function expects the following environment variables (set in `template.yaml` for deployment, or in your shell for local testing):

- `DB_HOST`: PostgreSQL host (e.g., `world2.cidu64gowey7.us-east-1.rds.amazonaws.com`)
- `DB_NAME`: Database name (e.g., `my_data`)
- `DB_USER`: Database user
- `DB_PASSWORD`: Database password

For local testing, you can set these in PowerShell:

```powershell
$env:DB_HOST="your-db-host"
$env:DB_NAME="your-db-name"
$env:DB_USER="your-db-user"
$env:DB_PASSWORD="your-db-password"
```

---

## Step 3: Install Python Dependencies

Navigate to the `hello_world` directory and install dependencies:

```powershell
cd hello_world
pip install -r requirements.txt
cd ..
```

---

## Step 4: Local Testing (Direct Python)

You can test the Lambda handler directly using `local_test.py`:

```powershell
python hello_world/local_test.py
```
- This script sets environment variables and invokes the Lambda handler for quick local testing.
- The script uses your local AWS credentials for S3 access.

---

## Step 5: Local Testing with AWS SAM (Simulate S3 Event)

1. **Create a sample S3 event file:**
   - `events/s3_event.json` (already provided)
2. **Ensure the test file exists in your S3 bucket.**
3. **Build the SAM application:**
   ```powershell
   sam build
   ```
4. **Invoke the Lambda locally:**
   ```powershell
   sam local invoke HelloWorldFunction --event events/s3_event.json
   ```
   - This simulates an S3 event and runs your Lambda in a Docker container using your local AWS credentials.

---

## Step 6: Prepare for AWS Deployment

- Ensure your `template.yaml` does NOT try to create an existing S3 bucket.
- Remove any S3 event triggers from the template if the bucket already exists (add the trigger manually in AWS Console after deployment).
- Add the following to your Lambda's properties to allow S3 read access:

```yaml
      Policies:
        - S3ReadPolicy:
            BucketName: file-processor-lambda-data-bucket-8937640
```

---

## Step 7: Deploy to AWS

1. **Build and deploy:**
   ```powershell
   sam build
   sam deploy --guided
   ```
   - Follow the prompts for stack name, region, and S3 bucket for deployment artifacts.

2. **Add the S3 trigger manually:**
   - Go to AWS S3 Console > your bucket > Properties > Event notifications.
   - Add a new notification for `All object create events` and select your Lambda function as the destination.

---

## Step 8: Test in AWS

- Upload a new `sample-data.csv` to your S3 bucket.
- The Lambda will be triggered and process the file into your PostgreSQL table.
- Check CloudWatch Logs for Lambda output and errors:

```powershell
sam logs -n HelloWorldFunction --stack-name file-processor-lambda --tail
```

---

## Step 9: Troubleshooting

- **Permission Errors:**
  - Ensure the Lambda IAM role has the correct S3 and RDS permissions (see `Policies` in `template.yaml`).
- **S3 Event Not Triggering:**
  - Make sure the S3 event notification is set up in the AWS Console.
- **Database/Table Not Found:**
  - Ensure your database and table exist and the Lambda has network access to RDS.
- **Windows Permission Errors:**
  - If you get access denied errors during `sam build`, close all programs using `.aws-sam/build` and delete the folder manually:
    ```powershell
    Remove-Item -Recurse -Force .aws-sam\build
    ```
  - Run PowerShell as Administrator if needed.

---

## Explanation of Key Commands

- `sam build`: Packages your Lambda and dependencies for local testing or deployment.
- `sam local invoke`: Runs your Lambda locally in a Docker container.
- `sam deploy --guided`: Deploys your application to AWS, prompting for configuration.
- `sam logs`: View Lambda logs in CloudWatch.
- `Remove-Item -Recurse -Force .aws-sam\build`: Deletes the build directory to resolve permission issues on Windows.

---

## Additional Resources

- [AWS SAM Developer Guide](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/what-is-sam.html)
- [AWS Lambda Python Documentation](https://docs.aws.amazon.com/lambda/latest/dg/lambda-python.html)
- [Boto3 S3 Documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/s3.html)
- [psycopg2 PostgreSQL Adapter](https://www.psycopg.org/docs/)

---

## Additional Notes

- Make sure the Lambda has network access to your RDS (VPC config if needed).
- The S3 bucket and RDS instance must exist.
- Adjust IAM permissions as needed for S3 and RDS access.

---

This README provides a step-by-step guide for users to understand, test, and deploy the Lambda application from scratch, including all troubleshooting and configuration steps used in this project.


## Commands used in this project:
sam build
sam local invoke HelloWorldFunction --event events/event.json
sam deploy --guided
sam delete --stack-name file-processor-lambda

## Alternative Step-by-Step Guide

## 1. Prerequisites

- AWS CLI configured
- AWS SAM CLI installed
- Docker installed (for local testing)
- Python 3.9+ installed
- PostgreSQL client (for local DB testing, optional)

---

## 2. Create a New AWS SAM Project

Open a terminal in your workspace folder and run:

```powershell
sam init --runtime python3.9 --name file-processor-lambda --app-template hello-world
```

Choose the "Hello World Example" template when prompted.

---

## 3. Project Structure

Your project will look like:

```
file-processor-lambda/
  ├── README.md
  ├── events/
  ├── hello_world/
  │   ├── __init__.py
  │   ├── app.py
  │   └── requirements.txt
  ├── template.yaml
  └── tests/
```

---

## 4. Update Lambda Handler

Edit `hello_world/app.py` to:

- Read the CSV from S3
- Insert records into PostgreSQL

```python
import os
import csv
import psycopg2
import boto3

def lambda_handler(event, context):
    s3 = boto3.client('s3')
    bucket = 'file-processor-lambda-data-bucket-8937640'
    key = 'sample-data.csv'
    db_host = os.environ['DB_HOST']
    db_name = os.environ['DB_NAME']
    db_user = os.environ['DB_USER']
    db_password = os.environ['DB_PASSWORD']

    # Download CSV from S3
    s3.download_file(bucket, key, '/tmp/sample-data.csv')

    # Connect to PostgreSQL
    conn = psycopg2.connect(
        host=db_host,
        dbname=db_name,
        user=db_user,
        password=db_password
    )
    cur = conn.cursor()

    # Read and insert CSV rows
    with open('/tmp/sample-data.csv', newline='') as csvfile:
        reader = csv.reader(csvfile)
        for row in reader:
            cur.execute(
                "INSERT INTO my_data (col1, col2, col3) VALUES (%s, %s, %s)",
                row
            )
    conn.commit()
    cur.close()
    conn.close()
    return {"status": "success"}
```

- Replace `col1, col2, col3` with your actual table columns.

---

## 5. Add Dependencies

Edit `hello_world/requirements.txt`:

```
boto3
psycopg2-binary
```

---

## 6. Update SAM Template

Edit `template.yaml` to:

- Add environment variables
- Set S3 trigger

```yaml
Resources:
  FileProcessorFunction:
    Type: AWS::Serverless::Function
    Properties:
      Handler: hello_world.app.lambda_handler
      Runtime: python3.9
      CodeUri: hello_world/
      Timeout: 60
      Environment:
        Variables:
          DB_HOST: xxxxxxxx
          DB_NAME: postgres
          DB_USER: postgres
          DB_PASSWORD: 
      Events:
        S3Event:
          Type: S3
          Properties:
            Bucket: file-processor-lambda-data-bucket-8937640
            Events: s3:ObjectCreated:*
```

---

## 7. Build the Project

```powershell
sam build
```

---

## 8. Test Locally

Simulate an S3 event locally:

```powershell
sam local invoke FileProcessorFunction --event events/event.json
```

- Create `events/event.json` with a sample S3 event (SAM provides examples).

To test with a local PostgreSQL, set the environment variables in `template.yaml` to point to your local DB.

---

## 9. Deploy to AWS

```powershell
sam deploy --guided
```

Follow the prompts to deploy.

---

## 10. Notes

- Make sure the Lambda has network access to your RDS (VPC config if needed).
- The S3 bucket and RDS instance must exist.
- Adjust IAM permissions as needed for S3 and RDS access.