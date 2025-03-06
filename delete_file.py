import boto3
import json

s3 = boto3.client('s3')

def lambda_handler(event, context):
    bucket = event['file_bucket']
    file_key = event['file_key']
    
    response = s3.delete_object(
        Bucket=bucket,
        Key=file_key
    )
    
    return {
        'statusCode': 200,
        'message': 'File deleted'
    }
