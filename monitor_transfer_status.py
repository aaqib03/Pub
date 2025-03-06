import boto3
import json

transfer = boto3.client('transfer')

def lambda_handler(event, context):
    transfer_id = event['transfer_id']
    
    response = transfer.describe_transfer(
        TransferId=transfer_id
    )
    
    return {
        'statusCode': 200,
        'transfer_status': response['Status']
    }
