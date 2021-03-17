resource "aws_ecs_task_definition" "migrate-task" {
  family = "${terraform.workspace}-migrate-task"
  container_definitions = jsonencode([
    merge(
      {
        cpu         = var.service_size[terraform.workspace].job.cpu
        memory      = var.service_size[terraform.workspace].job.memory
        name        = "migrate"
        stopTimeout = 120
        command = [
          "bundle", "exec", "rake", "db:migrate"
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
  cpu                      = var.service_size[terraform.workspace].job.cpu
  memory                   = var.service_size[terraform.workspace].job.memory
}
