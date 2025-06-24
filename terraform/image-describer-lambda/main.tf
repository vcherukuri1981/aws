# These roles are created once SAM deploys the Lambda function and the buckets. These roles are expected to be created by the template, however due to a bug in SAM,
#   if the roles are not created, This is a workaround to create the roles and policies required for the Lambda function to run.

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
# This policy allows the Lambda function to read objects from the source S3 bucket, which is necessary for processing images.
# Lambda function’s execution custom policy attached to the source S3 bucket.
resource "aws_iam_policy_attachment" "lambda_source_bucket_read_attach" {
  name       = "lambda-source-bucket-read-attach"
  roles      = [aws_iam_role.image_describer_lambda_exec.name]
  policy_arn = aws_iam_policy.lambda_source_bucket_read.arn
}

# Lambda function’s execution custom policy to allow Rekognition DetectLabels
resource "aws_iam_policy" "lambda_rekognition_detectlabels" {
  name        = "lambda-rekognition-detectlabels"
  description = "Allow Lambda to call rekognition:DetectLabels"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["rekognition:DetectLabels"]
        Resource = "*"
      }
    ]
  })
}

# Attach Rekognition DetectLabels policy to Lambda execution role
resource "aws_iam_policy_attachment" "lambda_rekognition_detectlabels_attach" {
  name       = "lambda-rekognition-detectlabels-attach"
  roles      = [aws_iam_role.image_describer_lambda_exec.name]
  policy_arn = aws_iam_policy.lambda_rekognition_detectlabels.arn
}


# Lambda function’s execution custom policy to allow writing to the destination S3 bucket
resource "aws_iam_policy" "lambda_destination_bucket_write" {
  name        = "lambda-destination-bucket-write"
  description = "Allow Lambda to write to the destination S3 bucket"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        Resource = "arn:aws:s3:::image-describer-lambda-terraform-destinationbucket-*/*"
      }
    ]
  })
}

# Attach destination bucket write policy to Lambda execution role
resource "aws_iam_policy_attachment" "lambda_destination_bucket_write_attach" {
  name       = "lambda-destination-bucket-write-attach"
  roles      = [aws_iam_role.image_describer_lambda_exec.name]
  policy_arn = aws_iam_policy.lambda_destination_bucket_write.arn
}
