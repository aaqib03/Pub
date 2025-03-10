import json
import logging
import boto3
import os

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS Clients
s3 = boto3.client('s3')
sns = boto3.client('sns')

# Set SNS Topic ARN (Replace with actual ARN)
SNS_TOPIC_ARN = "arn:aws:sns:eu-central-1:175565783406:transfer-failure-alerts"

def lambda_handler(event, context):
    try:
        # Retrieve the bucket and file key from the event payload
        bucket_name = event.get("bucket_name", "NO_BUCKET_NAME")
        file_key = event.get("file_key", "path/to/somefile.txt")

        # Log incoming parameters
        logger.info(f"Request to delete file '{file_key}' from bucket '{bucket_name}'")

        # Delete the file
        s3.delete_object(Bucket=bucket_name, Key=file_key)
        logger.info(f"Successfully deleted '{file_key}' from '{bucket_name}'")

        return {
            "statusCode": 200,
            "body": f"Deleted {file_key} from {bucket_name}"
        }

    except Exception as e:
        error_message = f"Failed to delete '{file_key}' from '{bucket_name}': {str(e)}"
        logger.error(error_message)

        # Send SNS notification on failure
        sns.publish(
            TopicArn=SNS_TOPIC_ARN,
            Message=json.dumps({
                "Error": "File Deletion Failed",
                "Bucket": bucket_name,
                "FileKey": file_key,
                "Reason": str(e)
            }),
            Subject="SFTP File Deletion Failure"
        )

        # Raise an exception to fail the step function execution
        raise Exception(error_message)



{
  "Comment": "SFTP File Transfer Workflow",
  "StartAt": "Retrieve SFTP Details",
  "States": {
    "Retrieve SFTP Details": {
      "Type": "Task",
      "Resource": "arn:aws:lambda:eu-central-1:175565783406:function:FetchSFTPDetailsLambda",
      "Next": "Initiate SFTP Transfer"
    },
    "Initiate SFTP Transfer": {
      "Type": "Task",
      "Resource": "arn:aws:lambda:eu-central-1:175565783406:function:InitiateSFTPTransferLambda",
      "Next": "Monitor Transfer Status"
    },
    "Monitor Transfer Status": {
      "Type": "Task",
      "Resource": "arn:aws:lambda:eu-central-1:175565783406:function:MonitorTransferStatusLambda",
      "Next": "Delete Original File"
    },
    "Delete Original File": {
      "Type": "Task",
      "Resource": "arn:aws:lambda:eu-central-1:175565783406:function:DeleteFileLambda",
      "Parameters": {
        "bucket_name.$": "$.bucket_name",
        "file_key.$": "$.file_key"
      },
      "Catch": [
        {
          "ErrorEquals": ["States.TaskFailed"],
          "Next": "Send Failure Notification"
        }
      ],
      "Next": "SuccessState"
    },
    "Send Failure Notification": {
      "Type": "Task",
      "Resource": "arn:aws:lambda:eu-central-1:175565783406:function:FailureNotificationLambda",
      "Next": "FailState"
    },
    "SuccessState": {
      "Type": "Succeed"
    },
    "FailState": {
      "Type": "Fail",
      "Cause": "File deletion failed."
    }
  }
}