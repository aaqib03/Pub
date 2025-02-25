######################################################################
# Terraform Code for SFTP Connector & Supporting Services
######################################################################

provider "aws" {
  region = "us-east-1"
}

######################################################################
# IAM Role for SFTP Connector, Lambda & Logging (Combined Role)
######################################################################
resource "aws_iam_role" "connector_automation_role" {
  name = "ConnectorAutomationRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = { "Service": "transfer.amazonaws.com" },
        Action = "sts:AssumeRole"
      },
      {
        Effect = "Allow",
        Principal = { "Service": "lambda.amazonaws.com" },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "connector_automation_policy" {
  name        = "ConnectorAutomationPolicy"
  description = "Policy for SFTP Connector, Lambda, and Logging"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = ["s3:GetObject", "s3:ListBucket"],
        Resource = ["arn:aws:s3:::client-outbound-bucket", "arn:aws:s3:::client-outbound-bucket/*"]
      },
      {
        Effect = "Allow",
        Action = ["transfer:SendFile", "transfer:DescribeServer", "transfer:ListUsers"],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "connector_automation_policy_attach" {
  role       = aws_iam_role.connector_automation_role.name
  policy_arn = aws_iam_policy.connector_automation_policy.arn
}

######################################################################
# AWS Transfer Family SFTP Connector Configuration
######################################################################
resource "aws_transfer_connector" "sftp_connector" {
  name      = "SFTPConnector"
  protocol  = "SFTP"
  role_arn  = aws_iam_role.connector_automation_role.arn
  url       = "sftp://client-remote-sftp-server.com"

  logging_configuration {
    log_group_name = "/aws/transfer/SFTPConnectorLogs"
  }
}

######################################################################
# SQS FIFO Queue for Sequential Processing & Retry Mechanism
######################################################################
resource "aws_sqs_queue" "file_processing_fifo" {
  name                      = "FileProcessingQueue.fifo"
  fifo_queue                = true
  content_based_deduplication = true
}

######################################################################
# AWS Lambda Function for File Transfer Automation
######################################################################
resource "aws_lambda_function" "sftp_push_lambda" {
  function_name = "SFTPPushLambda"
  role          = aws_iam_role.connector_automation_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.8"
  filename      = "lambda_function.zip"
}

######################################################################
# AWS Step Functions for Retry Mechanism
######################################################################
resource "aws_sfn_state_machine" "sftp_transfer_workflow" {
  name       = "SFTPTransferWorkflow"
  role_arn   = aws_iam_role.connector_automation_role.arn
  definition = file("step_function_definition.json")
}

######################################################################
# EventBridge Rule to Trigger Lambda on File Upload
######################################################################
resource "aws_cloudwatch_event_rule" "s3_event_rule" {
  name        = "S3FileUploadedRule"
  event_pattern = jsonencode({
    source = ["aws.s3"],
    detail-type = ["Object Created"]
  })
}

resource "aws_cloudwatch_event_target" "invoke_lambda" {
  rule      = aws_cloudwatch_event_rule.s3_event_rule.name
  target_id = "SFTPPushLambdaTrigger"
  arn       = aws_lambda_function.sftp_push_lambda.arn
}

######################################################################
# CloudWatch Logging Configuration
######################################################################
resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/SFTPPushLambda"
  retention_in_days = 7
}

######################################################################
# SNS Topic for Failure Alerts
######################################################################
resource "aws_sns_topic" "sftp_transfer_failures" {
  name = "SFTPTransferFailures"
}

resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.sftp_transfer_failures.arn
  protocol  = "email"
  endpoint  = "admin@example.com"
}

######################################################################
# Dead Letter Queue for Failed Transfers
######################################################################
resource "aws_sqs_queue" "dlq_queue" {
  name = "DLQFileProcessingQueue"
}

######################################################################
# Attach DLQ to Lambda
######################################################################
resource "aws_lambda_event_source_mapping" "lambda_sqs_trigger" {
  event_source_arn = aws_sqs_queue.file_processing_fifo.arn
  function_name    = aws_lambda_function.sftp_push_lambda.arn
  batch_size       = 1
  maximum_retry_attempts = 3
  destination_config {
    on_failure {
      destination = aws_sqs_queue.dlq_queue.arn
    }
  }
}

######################################################################
# Output Variables to Display Created Resources
######################################################################
output "sftp_connector_name" {
  description = "Name of the created SFTP Connector"
  value       = aws_transfer_connector.sftp_connector.name
}

output "sqs_fifo_queue_name" {
  description = "Name of the created SQS FIFO Queue"
  value       = aws_sqs_queue.file_processing_fifo.name
}

output "lambda_function_name" {
  description = "Name of the created Lambda Function"
  value       = aws_lambda_function.sftp_push_lambda.function_name
}

output "sfn_workflow_name" {
  description = "Name of the Step Function Workflow"
  value       = aws_sfn_state_machine.sftp_transfer_workflow.name
}

output "sns_topic_name" {
  description = "Name of the SNS Topic for Failure Alerts"
  value       = aws_sns_topic.sftp_transfer_failures.name
}

output "cloudwatch_log_group" {
  description = "CloudWatch Log Group for Lambda"
  value       = aws_cloudwatch_log_group.lambda_log_group.name
}
