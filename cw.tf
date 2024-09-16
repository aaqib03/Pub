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