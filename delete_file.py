{
  "Comment": "SFTP File Transfer Workflow",
  "StartAt": "Retrieve SFTP Details",
  "States": {
    "Retrieve SFTP Details": {
      "Type": "Task",
      "Resource": "arn:aws:lambda:eu-central-1:175565783406:function:FetchSFTPDetailsLambda",
      "ResultPath": "$.RetrieveSFTPOutput",
      "Next": "Initiate SFTP Transfer",
      "Catch": [
        {
          "ErrorEquals": ["States.TaskFailed"],
          "Next": "Send Failure Notification"
        }
      ]
    },
    "Initiate SFTP Transfer": {
      "Type": "Task",
      "Resource": "arn:aws:lambda:eu-central-1:175565783406:function:InitiateSFTPTransferLambda",
      "Parameters": {
        "bucket_name.$": "$.RetrieveSFTPOutput.sftp_details.BucketID.S",
        "destination_path.$": "$.RetrieveSFTPOutput.sftp_details.DestinationPath.S",
        "connector_id.$": "$.RetrieveSFTPOutput.sftp_details.ConnectorID.S",
        "file_key.$": "$.detail.object.key"
      },
      "Next": "Store Transfer Details",
      "Catch": [
        {
          "ErrorEquals": ["States.TaskFailed"],
          "Next": "Send Failure Notification"
        }
      ]
    },
    "Store Transfer Details": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke.waitForTaskToken",
      "TimeoutSeconds": 100,
      "Parameters": {
        "FunctionName": "arn:aws:lambda:eu-central-1:175565783406:function:StoreTransferInfoLambda",
        "Payload": {
          "task_token.$": "$$.Task.Token",
          "transfer_id.$": "$.transfer_id",
          "bucket_name.$": "$.bucket_name",
          "file_key.$": "$.file_key"
        }
      },
      "ResultPath": "$.StoreTransferResult",
      "Next": "WaitForTransferStatus",
      "Catch": [
        {
          "ErrorEquals": ["States.TaskFailed"],
          "Next": "Send Failure Notification"
        }
      ]
    },
    "WaitForTransferStatus": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.StoreTransferResult.transfer_status",
          "StringEquals": "COMPLETED",
          "Next": "Delete Original File"
        },
        {
          "Variable": "$.StoreTransferResult.transfer_status",
          "StringEquals": "FAILED",
          "Next": "Send Failure Notification"
        }
      ],
      "Default": "Send Failure Notification"
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
      "End": true
    },
    "Send Failure Notification": {
      "Type": "Task",
      "Resource": "arn:aws:states:::sns:publish",
      "Parameters": {
        "TopicArn": "arn:aws:sns:eu-central-1:175565783406:transfer-failure-alerts",
        "Message.$": "States.JsonToString({
          \"Step Function Execution\": \"$$.Execution.Id\",
          \"Failed Step\": \"$$.State.Name\",
          \"Bucket Name\": \"$.bucket_name\",
          \"File Key\": \"$.file_key\",
          \"Error Message\": \"$$.Error.Message\"
        })"
      },
      "End": true
    }
  }
}



"Send Failure Notification": {
  "Type": "Task",
  "Resource": "arn:aws:states:::sns:publish",
  "Parameters": {
    "TopicArn": "arn:aws:sns:eu-central-1:175565783406:transfer-failure-alerts",
    "Message.$": "States.Format('Step Function Execution: {}\\nFailed Step: {}\\nBucket Name: {}\\nFile Key: {}\\nError Message: {}',
      $$Execution.Id,
      $$State.Name,
      $.bucket_name,
      $.file_key,
      $.Error.Message)"
  },
  "End": true
}



import json
import logging
import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)
s3 = boto3.client('s3')

def lambda_handler(event, context):
    bucket_name = event.get("bucket_name", "NO_BUCKET_NAME")
    file_key = event.get("file_key", "path/to/somefile.txt")

    logger.info(f"Request to delete file '{file_key}' from bucket '{bucket_name}'")

    try:
        s3.delete_object(Bucket=bucket_name, Key=file_key)
        logger.info(f"Successfully deleted '{file_key}' from '{bucket_name}'")

        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": f"Deleted {file_key} from {bucket_name}"
            })
        }

    except Exception as e:
        error_message = f"Failed to delete '{file_key}' from '{bucket_name}': {str(e)}"
        logger.error(error_message)

        return {
            "statusCode": 500,
            "error": error_message,
            "bucket_name": bucket_name,
            "file_key": file_key
        }




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
            "ResultPath": "$.DeleteError",
            "Next": "Send Failure Notification"
        }
    ],
    "End": true
},

"Send Failure Notification": {
    "Type": "Task",
    "Resource": "arn:aws:states:::sns:publish",
    "Parameters": {
        "TopicArn": "arn:aws:sns:eu-central-1:175565783406:transfer-failure-alerts",
        "Message": {
            "Transfer ID": "$.transfer_id",
            "Bucket Name": "$.bucket_name",
            "File Key": "$.file_key",
            "Error Message": "$.DeleteError.error"
        }
    },
    "End": true
}