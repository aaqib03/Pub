terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# ---------------------------------------------
# EventBridge Rule to Trigger Step Function
# ---------------------------------------------

resource "aws_s3_bucket_notification" "s3_outbound_notification" {
  bucket = "your-existing-client-bucket"

  eventbridge {
    event_bridge_enabled = true
  }
}



resource "aws_cloudwatch_event_rule" "s3_upload_rule" {
  name        = "S3FileUploadRule"
  description = "Trigger Step Function on file upload in OUTBOUND folder"
  
  event_pattern = jsonencode({
    "source": ["aws.s3"],
    "detail-type": ["Object Created"],
    "detail": {
      "bucket": {
        "name": ["your-existing-client-bucket"]
      },
      "object": {
        "key": [{
          "prefix": "OUTBOUND/"
        }]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "sfn_target" {
  rule      = aws_cloudwatch_event_rule.s3_upload_rule.name
  arn       = aws_sfn_state_machine.sftp_transfer_workflow.arn
  role_arn  = aws_iam_role.eventbridge_invoke_step_function.arn
}

resource "aws_iam_role" "eventbridge_invoke_step_function" {
  name = "EventBridgeInvokeStepFunctionRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = { Service = "events.amazonaws.com" }
    }]
  })
  inline_policy {
    name = "InvokeStepFunction"
    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [{
        Effect   = "Allow",
        Action   = "states:StartExecution",
        Resource = aws_sfn_state_machine.sftp_transfer_workflow.arn
      }]
    })
  }
}

# ---------------------------------------------
# Step Function Definition
# ---------------------------------------------
resource "aws_sfn_state_machine" "sftp_transfer_workflow" {
  name     = "SFTPTransferWorkflow"
  role_arn = aws_iam_role.step_functions_role.arn
  definition = file("${path.module}/step_function_definition.json")
}

resource "aws_iam_role" "step_functions_role" {
  name = "StepFunctionsExecutionRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = { Service = "states.amazonaws.com" }
    }]
  })
}

# ---------------------------------------------
# AWS SFTP Connector
# ---------------------------------------------
resource "aws_transfer_connector" "sftp_connector" {
  url            = "sftp://your-existing-sftp-server-hostname"
  connector_type = "SFTP"
  logging_role   = aws_iam_role.sftp_connector_role.arn
}

resource "aws_iam_role" "sftp_connector_role" {
  name = "SFTPConnectorExecutionRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = { Service = "transfer.amazonaws.com" }
    }]
  })
  inline_policy {
    name = "S3AccessPolicy"
    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [{
        Effect = "Allow",
        Action = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"],
        Resource = ["arn:aws:s3:::your-existing-client-bucket/*"]
      }]
    })
  }
}

# ---------------------------------------------
# SNS Alerts for Transfer Failures
# ---------------------------------------------
resource "aws_sns_topic" "transfer_failure_alerts" {
  name = "transfer-failure-alerts"
}

resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.transfer_failure_alerts.arn
  protocol  = "email"
  endpoint  = "admin@example.com"
}

# ---------------------------------------------
# SQS for Transfer Monitoring
# ---------------------------------------------
resource "aws_sqs_queue" "sftp_transfer_queue" {
  name                      = "sftp-transfer-queue"
  delay_seconds             = 0
  message_retention_seconds = 345600
}

# ---------------------------------------------
# Lambda Functions for Step Functions
# ---------------------------------------------
resource "aws_lambda_function" "fetch_sftp_details" {
  filename         = "fetch_sftp_details.zip"
  function_name    = "FetchSFTPDetailsLambda"
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "fetch_sftp_details.lambda_handler"
  runtime          = "python3.8"
  source_code_hash = filebase64sha256("fetch_sftp_details.zip")
}

resource "aws_lambda_function" "initiate_sftp_transfer" {
  filename         = "initiate_sftp_transfer.zip"
  function_name    = "InitiateSFTPTransferLambda"
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "initiate_sftp_transfer.lambda_handler"
  runtime          = "python3.8"
  source_code_hash = filebase64sha256("initiate_sftp_transfer.zip")
}

resource "aws_lambda_function" "delete_file" {
  filename         = "delete_file.zip"
  function_name    = "DeleteFileLambda"
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "delete_file.lambda_handler"
  runtime          = "python3.8"
  source_code_hash = filebase64sha256("delete_file.zip")
}

resource "aws_iam_role" "lambda_execution_role" {
  name = "LambdaExecutionRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}
