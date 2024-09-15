provider "aws" {
  region = "us-east-1"  # Set your region
}

# Create SNS topic for sending alarm notifications
resource "aws_sns_topic" "alarm_notifications" {
  name = "ec2_ebs_health_alarms"
}

# Create an SNS subscription for notifications (email or SMS)
resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.alarm_notifications.arn
  protocol  = "email"
  endpoint  = "your_email@example.com"  # Replace with your email
}

# CloudWatch Alarm for Instance Status Check Failure (Instance-level)
resource "aws_cloudwatch_metric_alarm" "instance_status_check_failed" {
  alarm_name                = "EC2_Instance_Status_Check_Failed"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 1
  metric_name               = "StatusCheckFailed_Instance"
  namespace                 = "AWS/EC2"
  period                    = 60
  statistic                 = "Average"
  threshold                 = 1
  alarm_description         = "Triggers if the EC2 instance fails the instance status check."
  dimensions = {
    InstanceId = "i-xxxxxxxxxx"  # Replace with your instance ID
  }
  alarm_actions             = [aws_sns_topic.alarm_notifications.arn]
  ok_actions                = [aws_sns_topic.alarm_notifications.arn]
  insufficient_data_actions = [aws_sns_topic.alarm_notifications.arn]
}

# CloudWatch Alarm for System Status Check Failure (System-level)
resource "aws_cloudwatch_metric_alarm" "system_status_check_failed" {
  alarm_name                = "EC2_System_Status_Check_Failed"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 1
  metric_name               = "StatusCheckFailed_System"
  namespace                 = "AWS/EC2"
  period                    = 60
  statistic                 = "Average"
  threshold                 = 1
  alarm_description         = "Triggers if the EC2 instance fails the system status check."
  dimensions = {
    InstanceId = "i-xxxxxxxxxx"  # Replace with your instance ID
  }
  alarm_actions             = [aws_sns_topic.alarm_notifications.arn]
  ok_actions                = [aws_sns_topic.alarm_notifications.arn]
  insufficient_data_actions = [aws_sns_topic.alarm_notifications.arn]
}

# CloudWatch Alarm for Attached EBS Status Check Failure
resource "aws_cloudwatch_metric_alarm" "attached_ebs_status_check_failed" {
  alarm_name                = "EBS_Attached_Status_Check_Failed"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 1
  metric_name               = "StatusCheckFailed_AttachedEBS"
  namespace                 = "AWS/EC2"
  period                    = 60
  statistic                 = "Average"
  threshold                 = 1
  alarm_description         = "Triggers if the attached EBS volume fails the status check."
  dimensions = {
    InstanceId = "i-xxxxxxxxxx"  # Replace with your instance ID
  }
  alarm_actions             = [aws_sns_topic.alarm_notifications.arn]
  ok_actions                = [aws_sns_topic.alarm_notifications.arn]
  insufficient_data_actions = [aws_sns_topic.alarm_notifications.arn]
}