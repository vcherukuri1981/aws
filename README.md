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

**Project complete!**
=======
## AWS Repository
>>>>>>> 8e7fd8e26d0d3163e10ac3458cc618dde72022d4
