resource "aws_ecs_task_definition" "shell-task" {
  family = "${terraform.workspace}-shell-task"
  container_definitions = jsonencode([
    merge(
      {
        cpu         = var.service_size[terraform.workspace].job.cpu
        memory      = var.service_size[terraform.workspace].job.memory
        name        = "shell"
        stopTimeout = 120
        portMappings = [
          { containerPort = 2222 }
        ]
        command = [
          "bundle", "exec", "foreman", "start",
          "--procfile", "/conf/Procfile.shell",
          "--timeout", "120"
        ]
      },
      jsondecode(templatefile(
        "${path.module}/data/task-container-definition-common.json.tmpl",
        {
          region     = data.aws_region.current.name
          account_id = data.aws_caller_identity.current.account_id
          env        = terraform.workspace
          log_group  = false
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
