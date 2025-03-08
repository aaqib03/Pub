{
  "Comment": "Step Function to initiate SFTP transfer and wait for completion",
  "StartAt": "InitiateSFTPTransfer",
  "States": {
    "InitiateSFTPTransfer": {
      "Type": "Task",
      "Resource": "arn:aws:states:::aws-sdk:s3:putObject",
      "Parameters": {
        "Bucket": "your-outbound-bucket",
        "Key": "your-file-path"
      },
      "Next": "StoreTaskToken"
    },
    "StoreTaskToken": {
      "Type": "Task",
      "Resource": "arn:aws:lambda:your-store-task-token-lambda",
      "Parameters": {
        "taskToken.$": "$$.Task.Token",
        "transferId.$": "$.transferId"
      },
      "Next": "WaitForFileTransferCompletion"
    },
    "WaitForFileTransferCompletion": {
      "Type": "WaitForTaskToken",
      "Next": "CheckTransferStatus"
    },
    "CheckTransferStatus": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.status",
          "StringEquals": "SUCCESS",
          "Next": "ProcessCompletedFile"
        },
        {
          "Variable": "$.status",
          "StringEquals": "FAILURE",
          "Next": "HandleFailure"
        }
      ]
    },
    "ProcessCompletedFile": {
      "Type": "Task",
      "Resource": "arn:aws:lambda:your-process-file-lambda",
      "End": true
    },
    "HandleFailure": {
      "Type": "Fail",
      "Error": "FileTransferFailed",
      "Cause": "The file transfer did not complete successfully."
    }
  }
}