import boto3
import json
import os

# Initialize clients for EC2 and SNS
ec2 = boto3.client('ec2')
sns = boto3.client('sns')

# Fetch environment variables
SNS_TOPIC_ARN = os.environ['SNS_TOPIC_ARN']
TAG_KEY = os.environ['TAG_KEY']
TAG_VALUES = os.environ['TAG_VALUES'].split(',')  # Split comma-separated values into a list

def lambda_handler(event, context):
    # Get all instances with the specific tags
    instances = get_instances_with_tag(TAG_KEY, TAG_VALUES)
    
    for instance in instances:
        instance_id = instance['InstanceId']
        
        # Check EC2 Instance Status
        ec2_health = check_ec2_health(instance_id)
        
        # Check EBS Volume Status
        ebs_health = check_ebs_health(instance_id)
        
        # Send notification if any issues are found
        if ec2_health['status'] != 'ok' or ebs_health['status'] != 'ok':
            send_notification(instance_id, ec2_health, ebs_health)
    
    return {
        'statusCode': 200,
        'body': json.dumps('Health Check Complete!')
    }

def get_instances_with_tag(tag_key, tag_values):
    """Retrieve instances filtered by a specific tag."""
    response = ec2.describe_instances(
        Filters=[
            {
                'Name': f'tag:{tag_key}',
                'Values': tag_values
            }
        ]
    )
    
    instances = []
    
    # Extract all instances from the response
    for reservation in response['Reservations']:
        for instance in reservation['Instances']:
            instances.append(instance)
    
    return instances

def check_ec2_health(instance_id):
    """Check the EC2 instance's status."""
    ec2_status = ec2.describe_instance_status(InstanceIds=[instance_id])
    
    if len(ec2_status['InstanceStatuses']) == 0:
        # Instance is likely stopped, treat this as healthy
        return {'status': 'stopped', 'message': 'Instance is stopped.'}
    
    instance_status = ec2_status['InstanceStatuses'][0]
    
    system_status = instance_status['SystemStatus']['Status']
    instance_status = instance_status['InstanceStatus']['Status']
    
    # Check if instance or system status is impaired
    if system_status != 'ok' or instance_status != 'ok':
        return {'status': 'unhealthy', 'message': f'Instance {instance_id} is unhealthy. System Status: {system_status}, Instance Status: {instance_status}'}
    
    return {'status': 'ok', 'message': f'Instance {instance_id} is healthy.'}

def check_ebs_health(instance_id):
    """Check the health of all EBS volumes attached to the EC2 instance."""
    volumes = ec2.describe_volumes(
        Filters=[
            {'Name': 'attachment.instance-id', 'Values': [instance_id]}
        ]
    )
    
    unhealthy_volumes = []
    
    for volume in volumes['Volumes']:
        volume_id = volume['VolumeId']
        
        # Check volume status
        volume_status = ec2.describe_volume_status(VolumeIds=[volume_id])
        
        for status in volume_status['VolumeStatuses']:
            vol_status = status['VolumeStatus']['Status']
            if vol_status != 'ok':
                unhealthy_volumes.append({
                    'volume_id': volume_id,
                    'status': vol_status
                })
    
    if len(unhealthy_volumes) > 0:
        return {'status': 'unhealthy', 'message': f'EBS volumes unhealthy: {unhealthy_volumes}'}
    
    return {'status': 'ok', 'message': 'All EBS volumes are healthy.'}

def send_notification(instance_id, ec2_health, ebs_health):
    """Send SNS notification if EC2 or EBS volumes are unhealthy."""
    message = f"Instance ID: {instance_id}\n"
    
    if ec2_health['status'] != 'ok':
        message += f"EC2 Health Issue: {ec2_health['message']}\n"
    
    if ebs_health['status'] != 'ok':
        message += f"EBS Health Issue: {ebs_health['message']}\n"
    
    sns.publish(
        TopicArn=SNS_TOPIC_ARN,
        Message=message,
        Subject=f'EC2/EBS Health Check Alert for {instance_id}'
    )
