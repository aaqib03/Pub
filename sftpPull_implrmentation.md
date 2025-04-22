SFTP Pull Workflow Deployment (Terraform + AWS SDK Integrations)

This implementation:

Reuses a single Step Function to pull files for all clients

Uses EventBridge for scheduled triggering

Stores client config in sftp_connection_detail DynamoDB table

Uses no Lambda (all AWS SDK integrations)



---

1. IAM Role for Step Function

resource "aws_iam_role" "step_function_sftp_pull" {
  name = "StepFunctionSFTPPullRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "states.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "step_function_sftp_pull_policy" {
  name = "StepFunctionSFTPPullPolicy"
  role = aws_iam_role.step_function_sftp_pull.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = ["dynamodb:GetItem"],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "awstransfer:StartDirectoryListing",
          "awstransfer:GetDirectoryListingResult",
          "awstransfer:StartInboundFileTransfer",
          "awstransfer:DeleteFile",
          "awstransfer:MoveFile"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = ["s3:PutObject", "s3:GetObject", "s3:ListBucket"],
        Resource = "*"
      }
    ]
  })
}


---

2. Step Function Template File

Save this as sftp_pull_step_function.tpl:

{
  "Comment": "SFTP Pull Workflow",
  "StartAt": "GetPartnerConfig",
  "States": {
    "GetPartnerConfig": {
      "Type": "Task",
      "Resource": "arn:aws:states:::aws-sdk:dynamodb:getItem",
      "Parameters": {
        "TableName": "${dynamodb_table_name}",
        "Key": {
          "bucket_name": {
            "S": "$.bucket_name"
          }
        }
      },
      "ResultPath": "$.PartnerConfig",
      "Next": "StartDirectoryListing"
    },
    "StartDirectoryListing": {
      "Type": "Task",
      "Resource": "arn:aws:states:::aws-sdk:transfer:startDirectoryListing",
      "Parameters": {
        "ConnectorId": "$.PartnerConfig.Item.sftp_connector_id.S",
        "Path": "$.PartnerConfig.Item.sftp_host_path.S"
      },
      "ResultPath": "$.DirectoryListingJob",
      "Next": "WaitForListing"
    },
    "WaitForListing": {
      "Type": "Wait",
      "Seconds": 10,
      "Next": "GetDirectoryListingResult"
    },
    "GetDirectoryListingResult": {
      "Type": "Task",
      "Resource": "arn:aws:states:::aws-sdk:transfer:getDirectoryListingResult",
      "Parameters": {
        "ConnectorId": "$.PartnerConfig.Item.sftp_connector_id.S",
        "JobId": "$.DirectoryListingJob.JobId"
      },
      "ResultPath": "$.FileList",
      "Next": "MapTransferFiles"
    },
    "MapTransferFiles": {
      "Type": "Map",
      "ItemsPath": "$.FileList.Files",
      "Parameters": {
        "file.$": "$$.Map.Item.Value",
        "connectorId.$": "$.PartnerConfig.Item.sftp_connector_id.S",
        "s3Bucket.$": "$.PartnerConfig.Item.bucket_name.S",
        "s3Prefix.$": "$.PartnerConfig.Item.s3_target_prefix.S"
      },
      "Iterator": {
        "StartAt": "TransferSingleFile",
        "States": {
          "TransferSingleFile": {
            "Type": "Task",
            "Resource": "arn:aws:states:::aws-sdk:transfer:startInboundFileTransfer",
            "Parameters": {
              "ConnectorId": "$.connectorId",
              "RemoteFilePath": "$.file",
              "LocalFilePath": {
                "BucketName": "$.s3Bucket",
                "Key": {
                  "S3Key": {
                    "Prefix": "$.s3Prefix",
                    "FileName": "$.file"
                  }
                }
              }
            },
            "End": true
          }
        }
      },
      "End": true
    }
  }
}


---

3. Step Function Resource (Terraform)

data "template_file" "step_function_def" {
  template = file("${path.module}/sftp_pull_step_function.tpl")

  vars = {
    dynamodb_table_name = "sftp_connection_detail"
  }
}

resource "aws_sfn_state_machine" "sftp_pull" {
  name     = "SFTPPullStateMachine"
  role_arn = aws_iam_role.step_function_sftp_pull.arn
  type     = "STANDARD"
  definition = data.template_file.step_function_def.rendered
}


---

4. EventBridge Rule (per client)

resource "aws_cloudwatch_event_rule" "trigger_client_a" {
  name                = "TriggerSFTPPullClientA"
  schedule_expression = "rate(15 minutes)"
}

resource "aws_cloudwatch_event_target" "target_client_a" {
  rule      = aws_cloudwatch_event_rule.trigger_client_a.name
  target_id = "ClientATrigger"
  arn       = aws_sfn_state_machine.sftp_pull.arn
  role_arn  = aws_iam_role.step_function_sftp_pull.arn
  input     = jsonencode({ bucket_name = "client-a-bucket" })
}


---

5. Update DynamoDB Table (sftp_connection_detail)

Manually add/update items:

{
  "bucket_name": { "S": "client-a-bucket" },
  "sftp_connector_id": { "S": "abc123-xyz" },
  "sftp_host_path": { "S": "/inbound/client-a" },
  "s3_target_prefix": { "S": "incoming/client-a/" },
  "move_on_success": { "BOOL": true },
  "enable_pull": { "BOOL": true }
}


---

✅ You’re Done!

You now have:

A reusable pull mechanism

One Step Function for all clients

Per-client EventBridge schedule

Scalable and Lambda-free!


You can now extend this with retry handling, file move/delete support, and logging!

