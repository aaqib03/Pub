9provider "aws" {
  region = "ap-south-1"  # Adjust this to your AWS region
}

# Data source to get EC2 instances based on the instance name tag
data "aws_instances" "filtered_instances" {
  filter {
    name   = "tag:Name"
    values = [var.instance_name]  # Replace with the instance name tag
  }

  instance_state_names = ["running", "stopped"]
}

# Fetch instance details to get the attached volumes
data "aws_instance" "filtered_instance_details" {
  count       = length(data.aws_instances.filtered_instances.ids)
  instance_id = data.aws_instances.filtered_instances.ids[count.index]
}

# CloudWatch Alarms for each volume attached to each instance
resource "aws_cloudwatch_metric_alarm" "volume_status_check" {
  count = length(data.aws_instances.filtered_instances.ids) * length(data.aws_instance.filtered_instance_details[count.index].ebs_block_device)

  alarm_name          = "volume_status_check_${count.index}_${data.aws_instance.filtered_instance_details[count.index].ebs_block_device[count.index].volume_id}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "VolumeStatusCheckFailed"
  namespace           = "AWS/EBS"
  period              = "300"
  statistic           = "Maximum"
  threshold           = "1"
  alarm_description   = "Alarm for volume status check on instance ${data.aws_instances.filtered_instances.ids[count.index]}"
  dimensions = {
    VolumeId = data.aws_instance.filtered_instance_details[count.index].ebs_block_device[count.index].volume_id
  }
  alarm_actions = [aws_sns_topic.example.arn]  # Replace with your SNS topic ARN
}

# SNS Topic for notification
resource "aws_sns_topic" "example" {
  name = "my-sns-topic"  # Replace with your SNS topic
}

# Outputs for debugging (to see which instance and volumes are fetched)
output "filtered_instance_ids" {
  value = data.aws_instances.filtered_instances.ids
}

# Updated output for attached volume IDs from all instances and all volumes
output "attached_volume_ids" {
  value = flatten([for instance in data.aws_instance.filtered_instance_details : instance.ebs_block_device[*].volume_id])
}


provider "aws" {
  region = "ap-south-1"  # Adjust this to your AWS region
}

# Data source to get EC2 instances based on the instance name tag
data "aws_instances" "filtered_instances" {
  filter {
    name   = "tag:Name"
    values = [var.instance_name]  # Replace with the instance name tag
  }

  instance_state_names = ["running", "stopped"]
}

# Fetch instance details to get the root volumes
data "aws_instance" "filtered_instance_details" {
  count       = length(data.aws_instances.filtered_instances.ids)
  instance_id = data.aws_instances.filtered_instances.ids[count.index]
}

# Output to display root volume IDs
output "root_volume_ids" {
  value = [for instance in data.aws_instance.filtered_instance_details : instance.root_block_device[0].volume_id]
}