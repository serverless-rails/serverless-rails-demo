resource "aws_cloudwatch_log_group" "logs" {
  name              = terraform.workspace
  retention_in_days = 30

  tags = {
    Name        = terraform.workspace
    Environment = terraform.workspace
  }
}

resource "aws_cloudwatch_log_stream" "log-stream" {
  name           = "${terraform.workspace}-stream"
  log_group_name = aws_cloudwatch_log_group.logs.name
}

resource "aws_cloudwatch_event_rule" "every-1-hour" {
  name                = "${terraform.workspace}-scheduled-every-1-hour"
  schedule_expression = "rate(1 hour)"
}

# JOBS

resource "aws_cloudwatch_event_target" "notifications" {
  target_id = "${terraform.workspace}-notifications-job"
  arn       = aws_ecs_cluster.cluster.arn
  rule      = aws_cloudwatch_event_rule.every-1-hour.name
  role_arn  = aws_iam_role.ecs-events-role.arn

  lifecycle {
    ignore_changes = [ecs_target.0.task_definition_arn]
  }

  ecs_target {
    task_count          = 1
    launch_type         = "FARGATE"
    platform_version    = "1.4.0"
    task_definition_arn = aws_ecs_task_definition.job-task.arn

    network_configuration {
      subnets          = aws_subnet.public.*.id
      security_groups  = [aws_security_group.ecs-sg.id]
      assign_public_ip = true
    }
  }

  input = <<INPUT
    {
      "containerOverrides": [
        {
          "name": "job",
          "command": ["bundle", "exec", "rake", "notify:publish_watches"]
        }
      ]
    }
  INPUT
}


#
# ALARMS
#

resource "aws_cloudwatch_metric_alarm" "rds-cpu" {
  alarm_name          = "${terraform.workspace}-rds-cpu"
  alarm_description   = "CPU Usage on ${terraform.workspace}/${aws_rds_cluster.db.cluster_identifier}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "breaching"
  evaluation_periods  = 3
  datapoints_to_alarm = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Maximum"
  threshold           = 75

  dimensions = {
    DBClusterIdentifier = aws_rds_cluster.db.cluster_identifier
  }

  alarm_actions = [aws_sns_topic.alerts-topic.arn]
  ok_actions    = [aws_sns_topic.alerts-topic.arn]
}

resource "aws_cloudwatch_metric_alarm" "elevated-5xx" {
  alarm_name          = "${terraform.workspace}-elevated-5xx"
  alarm_description   = "Elevated 5xx Error Rate on ${terraform.workspace}"
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  evaluation_periods  = 2
  datapoints_to_alarm = 1
  metric_name         = "5xx"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Maximum"
  threshold           = 5

  dimensions = {
    LoadBalancer = aws_lb.lb.arn_suffix
  }

  alarm_actions = [aws_sns_topic.alerts-topic.arn]
  ok_actions    = [aws_sns_topic.alerts-topic.arn]
}

resource "aws_cloudwatch_metric_alarm" "new-content-notification-jobs-missed" {
  alarm_name          = "${terraform.workspace}-public-watch-jobs-missed"
  alarm_description   = "Job Missed for ${terraform.workspace} / notify:publish_watches"
  comparison_operator = "LessThanOrEqualToThreshold"
  treat_missing_data  = "breaching"
  evaluation_periods  = 4
  datapoints_to_alarm = 2
  metric_name         = "JobRunSuccess"
  namespace           = "Jobs"
  period              = 21600
  statistic           = "Sum"
  threshold           = 0

  dimensions = {
    (terraform.workspace) = "NotifyPublishWatches"
  }

  alarm_actions = [aws_sns_topic.alerts-topic.arn]
  ok_actions    = [aws_sns_topic.alerts-topic.arn]
}
