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