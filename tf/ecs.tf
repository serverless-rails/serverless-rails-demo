resource "aws_ecs_cluster" "cluster" {
  name               = terraform.workspace
  capacity_providers = ["FARGATE"]

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}
