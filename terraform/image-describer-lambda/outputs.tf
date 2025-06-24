output "lambda_exec_role_arn" {
  value       = aws_iam_role.image_describer_lambda_exec.arn
  description = "ARN of the Lambda execution role for use in SAM or other tools."
}

output "lambda_basic_logs_attachment_id" {
  value       = aws_iam_role_policy_attachment.lambda_basic_logs.id
  description = "ID of the policy attachment for AWSLambdaBasicExecutionRole on the Lambda execution role."
}
