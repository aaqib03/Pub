import boto3
import json

transfer = boto3.client('transfer')

def lambda_handler(event, context):
    sftp_url = event['sftp_details']['url']['S']
    file_path = event['file_path']
    
    response = transfer.start_file_transfer(
        ConnectorId='your-sftp-connector-id',
        SendFilePaths=[file_path]
    )
    
    return {
        'statusCode': 200,
        'transfer_id': response['TransferId']
    }
