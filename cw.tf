provider "aws" {
  region = "your-region"
}

# Data source to get the instance based on a tag filter
data "aws_instances" "filtered_instances" {
  filter {
    name   = "tag:Name"
    values = ["your-ec2-tag-name"]
  }
}

resource "aws_cloudwatch_metric_alarm" "instance_status_check_failed" {
  count               = length(data.aws_instances.filtered_instances.ids)
  alarm_name          = "InstanceStatusCheckFailed-${data.aws_instances.filtered_instances.ids[count.index]}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "StatusCheckFailed_Instance"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Minimum"
  threshold           = "1"
  alarm_description   = "Triggers if the instance status check fails"
  dimensions = {
    InstanceId = data.aws_instances.filtered_instances.ids[count.index]
  }

  alarm_actions = [aws_sns_topic.your_sns_topic.arn] # Optional, add SNS topic for notifications
}

resource "aws_cloudwatch_metric_alarm" "system_status_check_failed" {
  count               = length(data.aws_instances.filtered_instances.ids)
  alarm_name          = "SystemStatusCheckFailed-${data.aws_instances.filtered_instances.ids[count.index]}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "StatusCheckFailed_System"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Minimum"
  threshold           = "1"
  alarm_description   = "Triggers if the system status check fails"
  dimensions = {
    InstanceId = data.aws_instances.filtered_instances.ids[count.index]
  }

  alarm_actions = [aws_sns_topic.your_sns_topic.arn] # Optional, add SNS topic for notifications
}

# Optional SNS topic for alarm notifications
resource "aws_sns_topic" "your_sns_topic" {
  name = "ec2-status-check-alarm"
}

provider "aws" {
  region = "your-region"
}

# Data source to get the instance based on a tag filter
data "aws_instances" "filtered_instances" {
  filter {
    name   = "tag:Name"
    values = ["your-ec2-tag-name"]
  }
}

# Fetch details of each instance
data "aws_instance" "filtered_instance" {
  count = length(data.aws_instances.filtered_instances.ids)

  instance_id = data.aws_instances.filtered_instances.ids[count.index]
}

# Output the volume IDs of each block device attached to the instance
output "root_volume_id" {
  value = data.aws_instance.filtered_instance[count.index].root_block_device.volume_id
}

output "attached_ebs_volume_ids" {
  value = data.aws_instance.filtered_instance[count.index].ebs_block_device[*].volume_id
}

# CloudWatch alarm for EBS volume status check (example for root volume)
resource "aws_cloudwatch_metric_alarm" "root_volume_status_check" {
  alarm_name          = "RootVolumeStatusCheck-${data.aws_instance.filtered_instance[count.index].root_block_device.volume_id}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EBS"
  period              = "60"
  statistic           = "Minimum"
  threshold           = "1"
  alarm_description   = "Triggers if the root EBS volume status check fails"
  dimensions = {
    VolumeId = data.aws_instance.filtered_instance[count.index].root_block_device.volume_id
  }

  alarm_actions = [aws_sns_topic.your_sns_topic.arn] # Optional
}

# CloudWatch alarm for attached EBS volume status check
resource "aws_cloudwatch_metric_alarm" "attached_volume_status_check" {
  count               = length(data.aws_instance.filtered_instance[count.index].ebs_block_device)
  alarm_name          = "AttachedVolumeStatusCheck-${data.aws_instance.filtered_instance[count.index].ebs_block_device[count.index].volume_id}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EBS"
  period              = "60"
  statistic           = "Minimum"
  threshold           = "1"
  alarm_description   = "Triggers if the attached EBS volume status check fails"
  dimensions = {
    VolumeId = data.aws_instance.filtered_instance[count.index].ebs_block_device[count.index].volume_id
  }

  alarm_actions = [aws_sns_topic.your_sns_topic.arn] # Optional
}

# Optional SNS topic for alarm notifications
resource "aws_sns_topic" "your_sns_topic" {
  name = "ec2-volume-status-check-alarm"
}