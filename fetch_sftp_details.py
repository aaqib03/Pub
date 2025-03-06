import boto3
import json

dynamodb = boto3.client('dynamodb')

def lambda_handler(event, context):
    client_id = event.get('client_id', 'default_client')
    
    response = dynamodb.get_item(
        TableName='SFTPConnections',
        Key={'ClientID': {'S': client_id}}
    )
    
    sftp_details = response.get('Item', {})
    
    return {
        'statusCode': 200,
        'sftp_details': sftp_details
    }
