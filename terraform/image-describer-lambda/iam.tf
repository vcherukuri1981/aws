# This Terraform configuration file defines the IAM role and policy attachments for the Image Describer Lambda function.
# Lambda functions require an execution role to run and to interact with other AWS services
resource "aws_iam_role" "image_describer_lambda_exec" {
  name = "image-describer-lambda-te-ImageDescriberFunctionRole"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
  
  
}

# The AWSLambdaBasicExecutionRole is an AWS managed policy that provides the minimum permissions required for a Lambda function to write logs to Amazon CloudWatch Logs. Here's what you need to know:
resource "aws_iam_role_policy_attachment" "lambda_basic_logs" {
  role       = aws_iam_role.image_describer_lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
# Lambda function’s execution custom policy role permission to read objects from the source S3 bucket.
resource "aws_iam_policy" "lambda_source_bucket_read" {
  name        = "lambda-source-bucket-read"
  description = "Allow Lambda to read from the source S3 bucket"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = "arn:aws:s3:::image-describer-lambda-terraform-sourcebucket-*/*"
      }
    ]
  })
}

