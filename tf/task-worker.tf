resource "aws_ecs_task_definition" "worker-task" {
  family = "${terraform.workspace}-worker-task"
  container_definitions = jsonencode([
    merge(
      {
        cpu         = var.service_size[terraform.workspace].worker.cpu
        memory      = var.service_size[terraform.workspace].worker.memory
        name        = "worker"
        stopTimeout = 120
        command = [
          "bundle", "exec", "foreman", "start",
          "--procfile", "/conf/Procfile.worker",
          "--formation", "all=2",
          "--timeout", "600"
        ]
      },
      jsondecode(templatefile(
        "${path.module}/data/task-container-definition-common.json.tmpl",
        {
          region     = data.aws_region.current.name
          account_id = data.aws_caller_identity.current.account_id
          env        = terraform.workspace
          log_group  = aws_cloudwatch_log_group.logs.name
          repo_url   = aws_ecr_repository.repo.repository_url
        }
      ))
    )
  ])
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs-task-execution-role.arn
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.service_size[terraform.workspace].worker.cpu
  memory                   = var.service_size[terraform.workspace].worker.memory
  lifecycle { create_before_destroy = true }
}

data "aws_ecs_task_definition" "worker-task" {
  task_definition = aws_ecs_task_definition.worker-task.family
  depends_on      = [aws_ecs_task_definition.worker-task]
}

resource "aws_ecs_service" "worker-service" {
  name             = "${terraform.workspace}-worker"
  cluster          = aws_ecs_cluster.cluster.id
  desired_count    = var.service_count[terraform.workspace].worker.desired
  launch_type      = "FARGATE"
  platform_version = "1.4.0"
  task_definition  = aws_ecs_task_definition.worker-task.family

  lifecycle {
    ignore_changes = [task_definition]
  }

  network_configuration {
    subnets         = aws_subnet.public.*.id
    security_groups = [aws_security_group.ecs-sg.id]
  }
}


#
# AUTOSCALING
#

resource "aws_appautoscaling_target" "autoscale-worker" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.cluster.name}/${aws_ecs_service.worker-service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  role_arn           = aws_iam_role.ecs-autoscale-role.arn
  min_capacity       = var.service_count[terraform.workspace].worker.min
  max_capacity       = var.service_count[terraform.workspace].worker.max

  # weird cycling happens otherwise
  lifecycle {
    ignore_changes = [role_arn]
  }
}

resource "aws_appautoscaling_policy" "autoscale-worker-up" {
  name               = "${terraform.workspace}-autoscale-worker-up"
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.cluster.name}/${aws_ecs_service.worker-service.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 300
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }

  depends_on = [aws_appautoscaling_target.autoscale-worker]
}

resource "aws_appautoscaling_policy" "autoscale-worker-down" {
  name               = "${terraform.workspace}-autoscale-worker-down"
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.cluster.name}/${aws_ecs_service.worker-service.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = -1
    }
  }

  depends_on = [aws_appautoscaling_target.autoscale-worker]
}

resource "aws_cloudwatch_metric_alarm" "worker-service-cpu-high" {
  alarm_name          = "${terraform.workspace}-worker-cpu-high"
  alarm_description   = "Autoscale Up - CPU High on ${terraform.workspace}/worker"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 85

  dimensions = {
    ClusterName = aws_ecs_cluster.cluster.name
    ServiceName = aws_ecs_service.worker-service.name
  }

  alarm_actions = [aws_appautoscaling_policy.autoscale-worker-up.arn]
}

resource "aws_cloudwatch_metric_alarm" "worker-service-cpu-low" {
  alarm_name          = "${terraform.workspace}-worker-cpu-low"
  alarm_description   = "Autoscale Down - CPU Low on ${terraform.workspace}/worker"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 10

  dimensions = {
    ClusterName = aws_ecs_cluster.cluster.name
    ServiceName = aws_ecs_service.worker-service.name
  }

  alarm_actions = [aws_appautoscaling_policy.autoscale-worker-down.arn]
}
