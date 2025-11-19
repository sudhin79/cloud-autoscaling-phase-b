#########################################
# SNS Topic for EC2 Alarms
#########################################

resource "aws_sns_topic" "ec2_alerts" {
  name = "ec2-health-alerts-topic"
}

#########################################
# SNS Email Subscription
#########################################

resource "aws_sns_topic_subscription" "email_sub" {
  topic_arn = aws_sns_topic.ec2_alerts.arn
  protocol  = "email"
  endpoint  = "sudhinnirmalswain@gmail.com" # your email
}

#########################################
# CloudWatch Alarm: EC2 Instance Status Check Failed
#########################################

resource "aws_cloudwatch_metric_alarm" "ec2_system_alarm" {
  alarm_name          = "ec2-system-status-check-failed"
  alarm_description   = "Alarm when EC2 system status check fails"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "StatusCheckFailed_System"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "1"

  alarm_actions = [aws_sns_topic.ec2_alerts.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_asg.name
  }
}
