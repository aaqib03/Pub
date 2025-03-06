import boto3
import json
import os

secrets_manager = boto3.client('secretsmanager')

def lambda_handler(event, context):
    secret_name = "SSHPrivateKey"
    
    response = secrets_manager.get_secret_value(SecretId=secret_name)
    ssh_key = response['SecretString']
    
    return {
        'statusCode': 200,
        'ssh_key': ssh_key
    }
