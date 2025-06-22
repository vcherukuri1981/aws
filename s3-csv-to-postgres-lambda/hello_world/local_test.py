import os
import app

# Set environment variables for local testing
os.environ["DB_HOST"] = "world2.cidu64gowey7.us-east-1.rds.amazonaws.com"
os.environ["DB_NAME"] = "postgres"
os.environ["DB_USER"] = "postgres"
os.environ["DB_PASSWORD"] = "aws1234!"

# Mock event and context (adjust as needed)
event = {}
context = None

if __name__ == "__main__":
    result = app.lambda_handler(event, context)
    print(result)