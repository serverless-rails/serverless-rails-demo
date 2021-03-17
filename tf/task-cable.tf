resource "aws_ecs_task_definition" "cable-task" {
  family = "${terraform.workspace}-cable-task"
  container_definitions = jsonencode([
    merge(
      {
        cpu         = var.service_size[terraform.workspace].web.cpu
        memory      = var.service_size[terraform.workspace].web.memory
        name        = "cable"
        stopTimeout = 60
        portMappings = [
          { containerPort = 3334 }
        ]
        command = [
          "bundle", "exec", "foreman", "start",
          "--procfile", "/conf/Procfile.cable",
          "--timeout", "60"
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
  cpu                      = var.service_size[terraform.workspace].web.cpu
  memory                   = var.service_size[terraform.workspace].web.memory
  lifecycle { create_before_destroy = true }
}

data "aws_ecs_task_definition" "cable-task" {
  task_definition = aws_ecs_task_definition.cable-task.family
  depends_on      = [aws_ecs_task_definition.cable-task]
}

resource "aws_ecs_service" "cable-service" {
  name             = "${terraform.workspace}-cable"
  cluster          = aws_ecs_cluster.cluster.id
  desired_count    = var.service_count[terraform.workspace].cable.desired
  launch_type      = "FARGATE"
  platform_version = "1.4.0"
  task_definition  = aws_ecs_task_definition.cable-task.family

  lifecycle {
    ignore_changes = [task_definition]
  }

  load_balancer {
    container_name   = "cable"
    container_port   = 3334
    target_group_arn = aws_lb_target_group.cable.arn
  }

  network_configuration {
    subnets          = aws_subnet.public.*.id
    security_groups  = [aws_security_group.ecs-sg.id]
    assign_public_ip = true
  }

  depends_on = [aws_lb_target_group.cable]
}


#
# AUTOSCALING
#

resource "aws_appautoscaling_target" "autoscale-cable" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.cluster.name}/${aws_ecs_service.cable-service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  role_arn           = aws_iam_role.ecs-autoscale-role.arn
  min_capacity       = var.service_count[terraform.workspace].cable.min
  max_capacity       = var.service_count[terraform.workspace].cable.max

  # weird cycling happens otherwise
  lifecycle {
    ignore_changes = [role_arn]
  }
}

resource "aws_appautoscaling_policy" "autoscale-cable-up" {
  name               = "${terraform.workspace}-autoscale-cable-up"
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.cluster.name}/${aws_ecs_service.cable-service.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 120
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }

  depends_on = [aws_appautoscaling_target.autoscale-cable]
}

resource "aws_appautoscaling_policy" "autoscale-cable-down" {
  name               = "${terraform.workspace}-autoscale-cable-down"
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.cluster.name}/${aws_ecs_service.cable-service.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 120
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = -1
    }
  }

  depends_on = [aws_appautoscaling_target.autoscale-cable]
}

# CloudWatch alarm that triggers the autoscaling up policy
resource "aws_cloudwatch_metric_alarm" "cable-service-cpu-high" {
  alarm_name          = "${terraform.workspace}-cable-cpu-high"
  alarm_description   = "Autoscale Up - CPU High on ${terraform.workspace}/cable"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 85

  dimensions = {
    ClusterName = aws_ecs_cluster.cluster.name
    ServiceName = aws_ecs_service.cable-service.name
  }

  alarm_actions = [aws_appautoscaling_policy.autoscale-cable-up.arn]
}

# CloudWatch alarm that triggers the autoscaling down policy
resource "aws_cloudwatch_metric_alarm" "cable-service-cpu-low" {
  alarm_name          = "${terraform.workspace}-cable-cpu-low"
  alarm_description   = "Autoscale Down - CPU Low on ${terraform.workspace}/cable"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 10

  dimensions = {
    ClusterName = aws_ecs_cluster.cluster.name
    ServiceName = aws_ecs_service.cable-service.name
  }

  alarm_actions = [aws_appautoscaling_policy.autoscale-cable-down.arn]
}
