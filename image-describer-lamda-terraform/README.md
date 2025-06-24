<<<<<<< HEAD
# Image Describer Lambda (AWS SAM)

This project provides an AWS Lambda function (deployed with AWS SAM) that automatically generates a JSON description for any image uploaded to a source S3 bucket, using AWS Rekognition. The JSON is stored in a destination S3 bucket with the same base name as the image.

---

## Project Structure

```
image-describer-lambda/
├── src/
│   ├── app.py
│   └── requirements.txt
├── template.yaml
├── events/
│   └── s3_event.json
├── notification.json
└── README.md
```

---

## Setup Steps

### 1. Create Project Structure
```
mkdir image-describer-lambda
cd image-describer-lambda
mkdir src events
```

### 2. Add Lambda Function Code
- Place your `app.py` in `src/` (see this repo for the latest version).
- Add `requirements.txt` in `src/`:
  ```
  boto3
  botocore
  Pillow
  ```

### 3. Add AWS SAM Template
- See `template.yaml` for the Lambda resource definition.
- Reference your existing S3 buckets by name (do not create them in the template).

### 4. Build and Test Locally
```
sam build
# Place a test image (e.g., yellowparrot.jpeg) in src/
sam local invoke ImageDescriberFunction --event events/s3_event.json
```

### 5. Deploy to AWS
```
sam deploy --guided
```
- Follow the prompts and use your existing S3 buckets.

### 6. Add S3 Event Notification (CLI)
- Get your Lambda ARN:
  ```
  aws lambda get-function --function-name <your-lambda-name> --query 'Configuration.FunctionArn' --output text
  ```
- Create `notification.json`:
  ```json
  {
    "LambdaFunctionConfigurations": [
      {
        "LambdaFunctionArn": "<your-lambda-arn>",
        "Events": ["s3:ObjectCreated:*"]
      }
    ]
  }
  ```
- Add invoke permission:
  ```
  aws lambda add-permission \
    --function-name <your-lambda-name> \
    --action lambda:InvokeFunction \
    --principal s3.amazonaws.com \
    --source-arn arn:aws:s3:::<your-source-bucket> \
    --statement-id s3invoke
  ```
- Apply the notification:
  ```
  aws s3api put-bucket-notification-configuration \
    --bucket <your-source-bucket> \
    --notification-configuration file://notification.json
  ```

---

## IAM Permissions Required
- Lambda execution role must allow:
  - `s3:GetObject` on the source bucket
  - `s3:PutObject` on the destination bucket
  - `rekognition:DetectLabels`
  - Logging permissions for CloudWatch

**Example policy:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    { "Effect": "Allow", "Action": ["s3:GetObject"], "Resource": "arn:aws:s3:::<source-bucket>/*" },
    { "Effect": "Allow", "Action": ["s3:PutObject"], "Resource": "arn:aws:s3:::<destination-bucket>/*" },
    { "Effect": "Allow", "Action": ["rekognition:DetectLabels"], "Resource": "*" },
    { "Effect": "Allow", "Action": ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], "Resource": "*" }
  ]
}
```

---

## Troubleshooting

- **S3 AccessDenied:**
  - Ensure Lambda role has `s3:GetObject` (source) and `s3:PutObject` (destination) permissions.
- **Rekognition errors:**
  - Ensure Lambda role has `rekognition:DetectLabels` permission.
- **No JSON in destination bucket:**
  - Check CloudWatch logs for errors.
  - Ensure S3 event notification is set up and Lambda has invoke permission from S3.
- **Stack CREATE_FAILED:**
  - Remove S3 bucket resources from template if using existing buckets.
  - Delete failed stack and redeploy.
- **Local test image not found:**
  - Place test image in `src/` before `sam build`.
- **Read-only file system error in local invoke:**
  - Only use `print()` for output in local test mode, do not write files.

---

## Useful Commands

- Build: `sam build`
- Local test: `sam local invoke ImageDescriberFunction --event events/s3_event.json`
- Deploy: `sam deploy --guided`
- Get Lambda ARN: `aws lambda get-function --function-name <your-lambda-name> --query 'Configuration.FunctionArn' --output text`
- Add S3 notification: `aws s3api put-bucket-notification-configuration --bucket <your-source-bucket> --notification-configuration file://notification.json`
- Add Lambda invoke permission: `aws lambda add-permission --function-name <your-lambda-name> --action lambda:InvokeFunction --principal s3.amazonaws.com --source-arn arn:aws:s3:::<your-source-bucket> --statement-id s3invoke`

---

## Deleting the Lambda Stack and All Resources

To delete the Lambda function and all resources created by the stack (except for existing S3 buckets):

```
sam delete --stack-name image-describer-lambda
```

- This command will remove the CloudFormation stack, Lambda function, IAM roles, and any other resources created by the stack.
- It will **not** delete your existing S3 buckets if they were not created by the stack.

If you want to delete the Lambda function only (not the stack):

```
aws lambda delete-function --function-name <your-lambda-name>
```

If you want to manually clean up IAM roles or policies:

```
aws iam delete-role --role-name <your-lambda-role-name>
```

---

## Notes
- Always check CloudWatch logs for debugging Lambda issues.
- S3 event notifications for existing buckets must be set up manually (not in SAM template).
- Bucket names must be globally unique.

---

## Developer Notes and References

### 1. Create IAM Role for Lambda (Managed in Terraform)

Lambda functions require an execution role to interact with AWS services. Create a role with the following trust policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "lambda.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

### 2. Attach AWS Managed Policy (Managed in Terraform)

Attach the AWS managed policy for basic Lambda execution (CloudWatch logging):

```
policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
```

### 3. S3 Buckets in SAM Template

If you want SAM to create the source and destination buckets, add to `template.yaml`:

```yaml
Resources:
  SourceBucket:
    Type: AWS::S3::Bucket
    DeletionPolicy: Delete
  DestinationBucket:
    Type: AWS::S3::Bucket
```

> **Note:**  Ensure S3 create, Event and access policies are defined in the template, Terraform generated roles are managed externally due to current limitations in SAM.

### 4. Local Event Simulation

Create `events/s3_event.json` to simulate an S3 event for local testing:

```json
{
  "Records": [
    {
      "s3": {
        "bucket": { "name": "image-dest-improved-mako" },
        "object": { "key": "yellowparrot.jpeg" }
      }
    }
  ]
}
```

### 5. Build the Project

```
sam build
```

### 6. Local Testing

Run the Lambda function locally:

```
sam local invoke ImageDescriberFunction --event events/s3_event.json --env-vars env.json
```

- `env.json` simulates environment variables (e.g., bucket names) as in AWS Lambda.
- The local logic in `app.py` may use a local image for simulation.

### 7. Deploy with Predefined Role

If using a role created by Terraform, deploy with parameter override:

```sh
# Get the role ARN from Terraform output
cd c:\git\aws\terraform\image-describer-lambda
$roleArn = (terraform output -raw lambda_exec_role_arn).Trim()

# Deploy from SAM project directory
cd c:\git\aws\image-describer-lamda-terraform
sam deploy --parameter-overrides LambdaExecRoleArn="$roleArn"
```

### 8. Custom IAM Policies

Attach custom policies (lamda_iamroles.tf) to the Lambda execution role for:

- Reading from the source S3 bucket
- Writing to the destination S3 bucket
- Using Rekognition `DetectLabels`
- - Apply the notification if the template fails to create the event notification to the lambda function:
  ```
  aws s3api put-bucket-notification-configuration \
    --bucket <your-source-bucket> \
    --notification-configuration file://notification.json
  ```

These policies should be managed in Terraform and attached to the Lambda execution role.
### 9. Delete the SAM Stack and Resources

**Important:** Before deleting the SAM stack, manually remove all objects from both the source and destination S3 buckets. If the buckets contain objects, the stack deletion may fail.

To list all S3 buckets:

```
aws s3 ls
```

To delete all files, objects, and folders in an S3 bucket (including all subfolders):

```
aws s3 rm s3://your-bucket-name --recursive
```

To delete the stack and associated resources:

```
sam delete --stack-name image-describer-lambda-terraform
```

### 10. Run Terraform Destroy.
