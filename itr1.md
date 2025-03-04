# Lambda SFTP Transfer - Step 1: Basic File Processing Pipeline

## Overview
This document outlines the **basic implementation** of an automated file transfer pipeline using **AWS Lambda, SQS FIFO, and SFTP Connector**. This is the **first step** in building a robust solution that we will enhance incrementally.

---

## Step 1: Basic File Processing Pipeline (No Retries Yet)

### **Goal:**
- **Trigger Lambda from S3 events** and push messages to **SQS FIFO Queue**.
- **Lambda reads messages from SQS** and calls **SFTP Connector API** to transfer files.

---

## **🚀 Terraform Code (Step 1: Base Infrastructure)**

### **1️⃣ SQS FIFO Queue & Dead Letter Queue (DLQ)**
```hcl
resource "aws_sqs_queue" "file_transfer_fifo" {
  name                        = "file-transfer-queue.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  visibility_timeout_seconds  = 180  # Time before message is reprocessed

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.file_transfer_dlq.arn
    maxReceiveCount     = 3  # Retry failed messages 3 times before moving to DLQ
  })
}

resource "aws_sqs_queue" "file_transfer_dlq" {
  name       = "file-transfer-dlq.fifo"
  fifo_queue = true
}
```

---

### **2️⃣ S3 Event Notification → Pushes Messages to SQS**
```hcl
resource "aws_s3_bucket_notification" "s3_event" {
  bucket = "client-outbound-bucket"

  queue {
    queue_arn     = aws_sqs_queue.file_transfer_fifo.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "outbound/"
  }
}
```

---

### **3️⃣ Lambda Function for Processing Messages from SQS**
```hcl
resource "aws_lambda_function" "sftp_push_lambda" {
  function_name = "SFTPPushLambda"
  role          = aws_iam_role.connector_automation_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.8"
  filename      = "lambda_function.zip"
  timeout       = 180  # 3-minute timeout

  environment {
    variables = {
      SQS_QUEUE_URL      = aws_sqs_queue.file_transfer_fifo.url
      SFTP_CONNECTOR_ID  = "sftp-connector-id"
      DYNAMODB_TABLE     = aws_dynamodb_table.sftp_client_details.name
    }
  }
}

resource "aws_lambda_event_source_mapping" "sqs_lambda_trigger" {
  event_source_arn  = aws_sqs_queue.file_transfer_fifo.arn
  function_name     = aws_lambda_function.sftp_push_lambda.arn
  batch_size        = 5  # Process 5 files per Lambda execution
}
```

---

## **📌 Step 1: Basic Python Code for Lambda (No Retries Yet)**
```python
import boto3
import json
import os

# Initialize AWS Clients
sqs = boto3.client("sqs")
transfer = boto3.client("transfer")
dynamodb = boto3.resource("dynamodb")

# Environment Variables
SQS_QUEUE_URL = os.getenv("SQS_QUEUE_URL")
SFTP_CONNECTOR_ID = os.getenv("SFTP_CONNECTOR_ID")
DYNAMODB_TABLE = os.getenv("DYNAMODB_TABLE")

def get_sftp_details(client_id):
    """
    Fetch SFTP details (URL, user, directory) from DynamoDB using client_id.
    """
    table = dynamodb.Table(DYNAMODB_TABLE)
    response = table.get_item(Key={"client_id": client_id})
    return response.get("Item")

def initiate_sftp_transfer(file_path, bucket, client_id, sftp_details):
    """
    Calls AWS Transfer Family's SFTP Connector API to start a file transfer.
    """
    try:
        print(f"Initiating SFTP transfer for {file_path} to {sftp_details['sftp_url']}...")

        response = transfer.send_file(
            ConnectorId=SFTP_CONNECTOR_ID,
            FileLocation={"S3FileLocation": {"Bucket": bucket, "Key": file_path}},
            RemoteTarget={"RemotePath": f"{sftp_details['remote_directory']}/{file_path}"}
        )

        print(f"File {file_path} successfully transferred.")

    except Exception as e:
        print(f"File {file_path} failed to transfer: {e}")

def lambda_handler(event, context):
    """
    Main Lambda handler triggered by SQS.
    Processes batch file transfers.
    """
    for record in event["Records"]:
        try:
            message_body = json.loads(record["body"])
            file_path = message_body["Records"][0]["s3"]["object"]["key"]
            bucket = message_body["Records"][0]["s3"]["bucket"]["name"]
            client_id = bucket  # Using bucket name as client_id

            sftp_details = get_sftp_details(client_id)

            if not sftp_details:
                print(f"No SFTP details found for {client_id}. Skipping...")
                continue

            initiate_sftp_transfer(file_path, bucket, client_id, sftp_details)

        except Exception as e:
            print(f"Error processing record: {e}")
```

---

## **🚀 What’s Next? (Incremental Feature Addition)**

| **Step** | **Feature to Add** | **Why?** |
|---------|----------------|----------|
| ✅ Step 1 (Current) | **Basic flow: S3 → SQS → Lambda → SFTP** | Ensures basic file transfers |
| ⏭️ Step 2 | **Add Exponential Backoff Retries** | Handle **AWS API throttling & network failures** |
| ⏭️ Step 3 | **Circuit Breaker for Persistent Failures** | Prevent unnecessary retries when **SFTP server is down** |
| ⏭️ Step 4 | **Monitoring (EventBridge & SNS Alerts)** | Notify **Ops Team for failed transfers** |
| ⏭️ Step 5 | **Dead Letter Queue (DLQ) Processing & Auto-Recovery** | Ensure **no file is permanently lost** |

---

🚀 **Would you like to test this base implementation before adding retries?** 🚀

