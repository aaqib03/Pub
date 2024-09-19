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

# Fetching all volumes attached to each instance
data "aws_ebs_volume" "all_volumes" {
  count = length(data.aws_instances.filtered_instances.ids)

  most_recent = true
  filter {
    name   = "attachment.instance-id"
    values = [data.aws_instances.filtered_instances.ids[count.index]]
  }
}

# Output to verify instance IDs and volume IDs (for debugging)
output "filtered_instance_ids" {
  value = data.aws_instances.filtered_instances.ids
}

output "attached_volume_ids" {
  value = [for vol in data.aws_ebs_volume.all_volumes : vol.id]
}

# CloudWatch Alarms for each volume (both root and external EBS)
resource "aws_cloudwatch_metric_alarm" "volume_status_check" {
  count = length(data.aws_instances.filtered_instances.ids)

  alarm_name          = "volume_status_check_${count.index}_${data.aws_ebs_volume.all_volumes[count.index].id}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "VolumeStatusCheckFailed"
  namespace           = "AWS/EBS"
  period              = "300"
  statistic           = "Maximum"
  threshold           = "1"
  alarm_description   = "Alarm for volume status check on instance ${data.aws_instances.filtered_instances.ids[count.index]}"
  dimensions = {
    VolumeId = data.aws_ebs_volume.all_volumes[count.index].id
  }
  alarm_actions = [aws_sns_topic.example.arn]  # Replace with your SNS topic ARN
}

# SNS topic for alarm notifications
resource "aws_sns_topic" "example" {
  name = "my-sns-topic"  # Replace with your existing SNS topic
}