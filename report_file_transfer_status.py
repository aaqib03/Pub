import boto3
import json

sqs = boto3.client('sqs')
sfn = boto3.client('stepfunctions')

def lambda_handler(event, context):
    for record in event['Records']:
        message = json.loads(record['body'])
        transfer_id = message['TransferId']
        status = message['Status']
        
        task_token = message['TaskToken']
        
        if status == 'COMPLETED':
            sfn.send_task_success(
                taskToken=task_token,
                output=json.dumps({'transfer_status': 'COMPLETED'})
            )
        else:
            sfn.send_task_failure(
                taskToken=task_token,
                error="TransferFailed",
                cause="SFTP Transfer failed"
            )

    return {
        'statusCode': 200,
        'message': 'Transfer status updated'
    }
