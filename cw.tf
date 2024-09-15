provider "aws" {
  region = "us-east-1"  # Change to your desired region
}

# Create SNS topic for notifications
resource "aws_sns_topic" "alarm_notifications" {
  name = "ec2_ebs_health_alarms"
}

# Create an SNS subscription for notifications (email or SMS)
resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.alarm_notifications.arn
  protocol  = "email"  # Or "sms"
  endpoint  = "your_email@example.com"  # Replace with your email
}

# Variable for tag key and value to filter resources
variable "tag_key" {
  description = "Tag key to identify resources to be monitored"
  default     = "MonitoringGroup"
}

variable "tag_value" {
  description = "Tag value for the above key"
  default     = "Production"
}

# Data source to get EC2 instances by tag
data "aws_instance" "tagged_instances" {
  filter {
    name   = "tag:${var.tag_key}"
    values = [var.tag_value]
  }
}

# Data source to get EBS volumes by tag
data "aws_ebs_volume" "tagged_volumes" {
  filter {
    name   = "tag:${var.tag_key}"
    values = [var.tag_value]
  }
}

# CloudWatch Alarm for EC2 Instance Status Check Failure (Instance-level)
resource "aws_cloudwatch_metric_alarm" "instance_status_check_failed" {
  count                     = length(data.aws_instance.tagged_instances.ids)
  alarm_name                = "EC2_Instance_Status_Check_Failed_${count.index}"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 1
  metric_name               = "StatusCheckFailed_Instance"
  namespace                 = "AWS/EC2"
  period                    = 300
  statistic                 = "Average"
  threshold                 = 1
  alarm_description         = "Triggers if the EC2 instance fails the instance status check."
  dimensions = {
    InstanceId = element(data.aws_instance.tagged_instances.ids, count.index)
  }
  alarm_actions             = [aws_sns_topic.alarm_notifications.arn]
  ok_actions                = [aws_sns_topic.alarm_notifications.arn]
  insufficient_data_actions = [aws_sns_topic.alarm_notifications.arn]
}

# CloudWatch Alarm for EBS Volume Status Check Failure (one per volume)
resource "aws_cloudwatch_metric_alarm" "ebs_volume_status_check_failed" {
  count                     = length(data.aws_ebs_volume.tagged_volumes.ids)
  alarm_name                = "EBS_Volume_Status_Check_Failed_${count.index}"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 1
  metric_name               = "VolumeStatusCheckFailed"
  namespace                 = "AWS/EBS"
  period                    = 300
  statistic                 = "Average"
  threshold                 = 1
  alarm_description         = "Triggers if the EBS volume status check fails."
  dimensions = {
    VolumeId = element(data.aws_ebs_volume.tagged_volumes.ids, count.index)
  }
  alarm_actions             = [aws_sns_topic.alarm_notifications.arn]
  ok_actions                = [aws_sns_topic.alarm_notifications.arn]
  insufficient_data_actions = [aws_sns_topic.alarm_notifications.arn]
}