import boto3
import json
import time

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('TransferMetadata')

def lambda_handler(event, context):
    transfer_id = event['transfer_id']
    
    item_data = {
        'TransferID': transfer_id,
        'Timestamp': int(time.time()),
        'Status': 'IN_PROGRESS'
    }
    
    table.put_item(Item=item_data)
    
    return {
        'statusCode': 200,
        'message': 'Record inserted'
    }
