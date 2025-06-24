# These roles are created once SAM deploys the Lambda function and the buckets. These roles are expected to be created by the template, however due to a bug in SAM,
#   if the roles are not created, This is a workaround to create the roles and policies required for the Lambda function to run.

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