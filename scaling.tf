resource "aws_autoscaling_policy" "cpu_target" {
  name                   = "cpu-policy"
  autoscaling_group_name = aws_autoscaling_group.app_asg.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    # Assignment requirement: CPU > 30%
    target_value = 30
  }
}

resource "aws_autoscaling_policy" "memory_target" {
  name                   = "memory-policy"
  autoscaling_group_name = aws_autoscaling_group.app_asg.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    customized_metric_specification {
      metric_name = "mem_used_percent"
      namespace   = "CWAgent"
      statistic   = "Average"
    }

    # Assignment requirement: Memory > 5%
    target_value = 5
  }
}
